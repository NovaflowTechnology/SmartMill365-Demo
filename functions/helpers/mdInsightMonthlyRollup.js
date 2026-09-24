const admin = require("firebase-admin");
const { getMysqlPoolSafe, queryWithFallback, getClientFirestore } = require("./dbConnections");
const { buildDeviceReport, getTemplates } = require("./mdInsightReportBuilder");
const { resolveEquipmentDeviceIds, SHARED_CONFIG_OWNER_ID } = require("./mdInsightEquipmentResolver");

const LOG_TABLE = "md_insight_report_log";
const GENERATED_BY = "system:monthly-rollup";

// Same defaults the report page falls back to when energySystemSettings
// hasn't been loaded (md_insight_report_widget.dart:94-96) — used here
// because the risk-level thresholds and Peak Hour ToU window are only
// resolvable per Firebase-Auth uid (energySystemSettings/{uid}), and there's
// no tenant-level source for them yet (unlike masterBillingConfig/TNB
// meters/mdInsightReportConfigs, which are now shared per-client — see
// AppConfig.sharedConfigOwnerId — this collection wasn't part of that fix).
const DEFAULT_RISK_THRESHOLDS = { highRiskMin: 80, mediumRiskMin: 60, lowRiskMin: 0 };

/**
 * Resolves the real MD capacity/network charge from the shared
 * masterBillingConfig doc, mirroring md_insight_report_widget.dart's
 * `_fetchBillingConfig` fallback order: the meter's own tariff category
 * first, falling back to whichever category is globally "active" when the
 * meter has none / that category has no saved config. mdCapacityCharge
 * falls back to the shared electricityTariff's capacityRate (same as the
 * live page); mdNetworkCharge has no such fallback.
 */
async function resolveBillingRate(clientId, meterCategoryId) {
  try {
    const db = await getClientFirestore(clientId);
    const ownerRef = db.collection("masterBillingConfig").doc(SHARED_CONFIG_OWNER_ID);

    let categoryConfig = null;
    if (meterCategoryId) {
      const snap = await ownerRef.collection("categories").doc(meterCategoryId).get();
      if (snap.exists) categoryConfig = snap.data();
    }
    if (!categoryConfig) {
      const ownerSnap = await ownerRef.get();
      const appliedCategory = ownerSnap.exists ? ownerSnap.data().appliedCategory : null;
      if (appliedCategory) {
        const snap = await ownerRef.collection("categories").doc(appliedCategory).get();
        if (snap.exists) categoryConfig = snap.data();
      }
    }
    if (!categoryConfig) return { mdCapacityCharge: 0, mdNetworkCharge: 0 };

    const tariffSnap = await ownerRef.collection("settings").doc("electricityTariff").get();
    const capacityRate =
      tariffSnap.exists && tariffSnap.data().capacityRate !== undefined
        ? Number(tariffSnap.data().capacityRate) || null
        : null;

    const mdCapacityCharge =
      categoryConfig.mdCapacityCharge !== undefined
        ? Number(categoryConfig.mdCapacityCharge) || 0
        : capacityRate || 0;
    const mdNetworkCharge =
      categoryConfig.mdNetworkCharge !== undefined ? Number(categoryConfig.mdNetworkCharge) || 0 : 0;

    return { mdCapacityCharge, mdNetworkCharge };
  } catch (e) {
    console.warn("[mdInsightMonthlyRollup] billing rate resolution failed:", e.message);
    return { mdCapacityCharge: 0, mdNetworkCharge: 0 };
  }
}

function mdStatusLabel(monthlyPct, thresholds) {
  if (monthlyPct >= 100) return "CRITICAL";
  if (monthlyPct >= thresholds.highRiskMin) return "HIGH";
  if (monthlyPct >= thresholds.mediumRiskMin) return "MEDIUM";
  if (monthlyPct >= thresholds.lowRiskMin) return "LOW";
  return "NORMAL";
}

/**
 * 'YYYY-MM' for the calendar month immediately before `now`, evaluated in
 * Asia/Kuala_Lumpur local time (UTC+8, no DST). The scheduled trigger fires
 * at 00:00 MYT on the 1st, which is still 16:00 UTC on the last day of the
 * previous month — naive UTC month arithmetic on `now` would read that as
 * still being in the month that just ended, and resolve one month too far
 * back.
 */
function previousPeriod(now = new Date()) {
  const myt = new Date(now.getTime() + 8 * 60 * 60 * 1000);
  const y = myt.getUTCFullYear();
  const m = myt.getUTCMonth(); // 0-based
  const prevDate = new Date(Date.UTC(y, m - 1, 1));
  return `${prevDate.getUTCFullYear()}-${String(prevDate.getUTCMonth() + 1).padStart(2, "0")}`;
}

/** All tenant ids from the master registry (skips the one non-tenant doc). */
async function listClientIds() {
  const snap = await admin.firestore().collection("integration_config").get();
  return snap.docs.map((d) => d.id).filter((id) => id !== "app_config_active");
}

/**
 * Runs one plant/meter's snapshot: resolves inputs, computes the report via
 * the same builder the live page uses, and delete-then-inserts the
 * canonical 'auto' row for (plant_code, period).
 *
 * cc comes from the meter's own contractMdKw (tenant-scoped, no signed-in
 * user needed — same as the live page's dominant source,
 * md_insight_report_widget.dart:179). Plants without a positive contractMdKw
 * are skipped — MD001/MD101 etc. treat cc=0 as "always breached", so a
 * fabricated cc would produce wrong data, not just incomplete data.
 *
 * mdRate (masterBillingConfig) and equipment attribution (equipment ->
 * production area -> master_facilities matching) are resolved for real
 * below, via the shared client-wide config (see resolveBillingRate and
 * mdInsightEquipmentResolver.js) — neither needs a signed-in user anymore.
 * The Peak Hour ToU window and risk thresholds (energySystemSettings) still
 * do — that collection wasn't part of the shared-config fix, so those two
 * stay on their documented defaults below.
 */
async function rollupOnePlant({ clientId, meter, period }) {
  const plantCode = (meter.meterCode || "").trim();
  const deviceId = (meter.influxDbTag || "").trim();
  const cc = Number(meter.contractMdKw) || 0;

  if (!plantCode || !deviceId) {
    console.warn(`[mdInsightMonthlyRollup] skip client=${clientId} meter=${meter.id}: missing meterCode/influxDbTag`);
    return { skipped: true, reason: "missing meterCode/influxDbTag" };
  }
  if (cc <= 0) {
    console.warn(`[mdInsightMonthlyRollup] skip client=${clientId} plant=${plantCode}: no contractMdKw configured`);
    return { skipped: true, reason: "no contractMdKw" };
  }

  const [{ mdCapacityCharge, mdNetworkCharge }, equipmentIds] = await Promise.all([
    resolveBillingRate(clientId, (meter.tariffCategoryId || "").trim()),
    resolveEquipmentDeviceIds({ clientId, meter, plantCode }),
  ]);
  const mdRate = mdCapacityCharge + mdNetworkCharge;

  const pool = await getMysqlPoolSafe(clientId, undefined);
  const templates = await getTemplates(pool, clientId);

  const report = await buildDeviceReport({
    pool, clientId, deviceId, period, cc, mdRate,
    equipmentIds, peakStart: null, peakEnd: null, peakDays: [], templates,
  });

  const monthlyMaxDemandKw = report.monthly_max_demand_kw || 0;
  const monthlyPct = cc > 0 ? (monthlyMaxDemandKw / cc) * 100 : 0;

  const inputs = {
    contract_capacity_kw: cc,
    md_capacity_charge: mdCapacityCharge,
    md_network_charge: mdNetworkCharge,
    peak_start: null,
    peak_end: null,
    peak_days: [],
    high_risk_min: DEFAULT_RISK_THRESHOLDS.highRiskMin,
    medium_risk_min: DEFAULT_RISK_THRESHOLDS.mediumRiskMin,
    low_risk_min: DEFAULT_RISK_THRESHOLDS.lowRiskMin,
    monthly_max_demand_kw: monthlyMaxDemandKw,
    md_status_label: mdStatusLabel(monthlyPct, DEFAULT_RISK_THRESHOLDS),
    equipment_device_ids: equipmentIds,
  };

  const payload = { report, inputs };

  await pool.query(
    `DELETE FROM ${LOG_TABLE} WHERE plant_code = ? AND period = ? AND source = 'auto'`,
    [plantCode, period]
  );
  await pool.query(
    `INSERT INTO ${LOG_TABLE}
      (plant_code, period, generated_at, generated_by, report_state, source, payload_json)
     VALUES (?, ?, NOW(), ?, ?, 'auto', ?)`,
    [plantCode, period, GENERATED_BY, report.report_state, JSON.stringify(payload)]
  );

  return { skipped: false, plantCode, period, reportState: report.report_state };
}

/**
 * Runs the monthly snapshot for every active TNB meter across every tenant
 * (or just [onlyClientId] when supplied — used by the backfill route).
 * Never throws for a single tenant/plant failure — logs and continues, so
 * one bad plant/tenant can't block the rest of the batch.
 */
async function runMonthlyRollup({ period, onlyClientId } = {}) {
  if (!/^\d{4}-\d{2}$/.test(period || "")) {
    throw new Error(`runMonthlyRollup: invalid period '${period}', expected 'YYYY-MM'`);
  }

  const clientIds = onlyClientId ? [onlyClientId] : await listClientIds();
  const results = [];

  for (const clientId of clientIds) {
    let meters = [];
    try {
      const snapshot = await queryWithFallback(clientId, "tnb_meters", null);
      meters = snapshot.docs
        .map((d) => ({ id: d.id, ...d.data() }))
        .filter((m) => m.isActive !== false);
    } catch (e) {
      console.error(`[mdInsightMonthlyRollup] failed listing meters for client=${clientId}:`, e.message);
      continue;
    }

    for (const meter of meters) {
      try {
        const result = await rollupOnePlant({ clientId, meter, period });
        results.push({ clientId, meterId: meter.id, ...result });
      } catch (e) {
        console.error(`[mdInsightMonthlyRollup] failed client=${clientId} meter=${meter.id}:`, e.message);
        results.push({ clientId, meterId: meter.id, skipped: true, reason: e.message });
      }
    }
  }

  const logged = results.filter((r) => !r.skipped).length;
  console.log(`[mdInsightMonthlyRollup] period=${period} tenants=${clientIds.length} logged=${logged}/${results.length}`);
  return results;
}

module.exports = { runMonthlyRollup, previousPeriod, listClientIds };
