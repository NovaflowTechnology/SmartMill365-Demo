const { getClientFirestore, queryWithFallback } = require("./dbConnections");
const { computeReport, computeShiftBreakdown, fmtDate } = require("./mdInsightRules");

// Shared by GET /md-insight-rules (mdInsightRulesFunction.js — live,
// user-triggered) and mdInsightMonthlyRollup.js (scheduled, one canonical
// snapshot per plant/period) so both places compute and render the exact
// same report for a given device/period/inputs.

const RULES_TABLE = "md_insight_rules";

// Templates rarely change (ops-edited copy), so cache them for a few
// minutes instead of re-querying md_insight_rules on every report request.
// Keyed by clientId (not one shared value) — a job that loops every tenant
// back-to-back would otherwise leak tenant A's templates into tenant B's
// report within the TTL window.
const _templateCache = new Map(); // key: clientId||'__default__' -> { map, at }
const TEMPLATE_CACHE_TTL_MS = 5 * 60 * 1000;

async function getTemplates(pool, clientId) {
  const cacheKey = clientId || "__default__";
  const now = Date.now();
  const cached = _templateCache.get(cacheKey);
  if (cached && now - cached.at < TEMPLATE_CACHE_TTL_MS) return cached.map;
  const [rows] = await pool.query(
    `SELECT rule_id, category, output_template, output_template_else FROM ${RULES_TABLE}`
  );
  const map = {};
  rows.forEach((r) => { map[r.rule_id] = r; });
  _templateCache.set(cacheKey, { map, at: now });
  return map;
}

function monthBounds(period) {
  const [year, month] = period.split("-").map(Number);
  const start = `${period}-01`;
  return { year, month, start };
}

/**
 * Runs the full MD Insight Report computation for one device/period and
 * returns the exact JSON shape MdInsightReport.fromJson (Flutter) expects.
 *
 * @param {object} opts
 * @param {object} opts.pool         mysql2 pool (already resolved for the tenant)
 * @param {string} opts.clientId     tenant id, for Firestore lookups (master_facilities)
 * @param {string} opts.deviceId     Overall_*_energy_consumption device_id
 * @param {string} opts.period       'YYYY-MM'
 * @param {number} opts.cc           contract capacity (kW) — required, must be > 0
 * @param {number} opts.mdRate       RM/kW MD tariff rate — 0 is valid (renders cost rules as "else")
 * @param {string[]} [opts.equipmentIds]
 * @param {string|null} [opts.peakStart]
 * @param {string|null} [opts.peakEnd]
 * @param {number[]} [opts.peakDays]
 * @param {object} opts.templates    from getTemplates()
 */
async function buildDeviceReport({
  pool, clientId, deviceId, period, cc, mdRate,
  equipmentIds = [], peakStart = null, peakEnd = null, peakDays = [], templates,
}) {
  const { year, month, start } = monthBounds(period);
  const prevMonthParams = month === 1 ? [deviceId, year - 1, 12] : [deviceId, year, month - 1];

  const [
    [monthlyRows],
    [dailyRows],
    [blockRows],
    [historyMaxRows],
    [prevMonthRows],
    [yearRows],
  ] = await Promise.all([
    pool.query(
      `SELECT max_demand_kW FROM Overall_monthly_energy_consumption
       WHERE device_id = ? AND year = ? AND month = ? LIMIT 1`,
      [deviceId, year, month]
    ),
    pool.query(
      // YEAR()/MONTH() rather than `date BETWEEN start AND end`: if `date`
      // is a DATETIME/TIMESTAMP column (not a bare DATE), a bare-date upper
      // bound like '2026-07-31' is read as midnight, silently excluding
      // every row later that day.
      `SELECT DATE_FORMAT(date, '%Y-%m-%d') AS date, max_demand_kW AS value
       FROM Overall_daily_energy_consumption
       WHERE device_id = ? AND YEAR(date) = ? AND MONTH(date) = ?
       ORDER BY date ASC`,
      [deviceId, year, month]
    ),
    pool.query(
      `SELECT DATE_FORMAT(timestamp, '%Y-%m-%d') AS date, DATE_FORMAT(timestamp, '%H:%i') AS time, max_demand_kW AS value
       FROM Overall_hourly_energy_consumption
       WHERE device_id = ? AND YEAR(timestamp) = ? AND MONTH(timestamp) = ?
       ORDER BY timestamp ASC`,
      [deviceId, year, month]
    ),
    pool.query(
      `SELECT DATE_FORMAT(date, '%Y-%m-%d') AS date, max_demand_kW AS value
       FROM Overall_daily_energy_consumption
       WHERE device_id = ?
       ORDER BY max_demand_kW DESC LIMIT 1`,
      [deviceId]
    ),
    pool.query(
      `SELECT max_demand_kW FROM Overall_monthly_energy_consumption
       WHERE device_id = ? AND year = ? AND month = ? LIMIT 1`,
      prevMonthParams
    ),
    pool.query(
      `SELECT year, month, max_demand_kW AS value
       FROM Overall_monthly_energy_consumption
       WHERE device_id = ? AND year = ?`,
      [deviceId, year]
    ),
  ]);

  const md = monthlyRows[0] ? Number(monthlyRows[0].max_demand_kW) || 0 : 0;
  const dailyMd = dailyRows.map((r) => ({ date: r.date, value: Number(r.value) || 0 }));
  // blockMdAll keeps `date` (needed to slice out the peak day for the load
  // chart below); the rule engine's blockMd only needs time-of-day.
  const blockMdAll = blockRows.map((r) => ({ date: r.date, time: r.time, value: Number(r.value) || 0 }));
  const blockMd = blockMdAll.map(({ time, value }) => ({ time, value }));
  const historyMaxDaily = historyMaxRows[0]
    ? { value: Number(historyMaxRows[0].value) || 0, date: historyMaxRows[0].date }
    : null;
  const prevMonthMd = prevMonthRows[0] ? Number(prevMonthRows[0].max_demand_kW) || 0 : null;
  const monthlyMd = yearRows.map((r) => ({ year: r.year, month: r.month, value: Number(r.value) || 0 }));

  // ── Shifts (Firestore, per-tenant — same collection as /shifts) ─────────
  let shiftDef = [];
  try {
    const snapshot = await queryWithFallback(clientId, "shifts", null);
    shiftDef = snapshot.docs
      .map((d) => d.data())
      .filter((s) => s.valid !== false && s.startWorkTime && s.finishWorkTime)
      .map((s) => ({ name: s.name, start: s.startWorkTime, end: s.finishWorkTime }));
  } catch (e) {
    console.warn("[mdInsightReportBuilder] shifts fetch failed:", e.message);
  }

  // ── Peak day/block — the single 30-min interval the plant-wide MD peak
  // occurred in. Shared by Load Analysis (peak-day curve) and Equipment
  // Analysis, which per spec §4.5 is locked to attribution "at the peak
  // block only" — a single 30-minute snapshot, not a whole-day or
  // whole-month aggregate. Do not widen this window without a spec revision.
  let peakBlock = null; // { date, time, value }
  let dayBlocks = [];
  if (dailyMd.length) {
    const peakDay = dailyMd.reduce((m, d) => (d.value > m.value ? d : m), dailyMd[0]).date;
    dayBlocks = blockMdAll.filter((b) => b.date === peakDay).sort((a, b) => a.time.localeCompare(b.time));
    if (dayBlocks.length) {
      const peakLoadKw = Math.max(...dayBlocks.map((b) => b.value));
      const peakIdx = dayBlocks.findIndex((b) => b.value === peakLoadKw);
      peakBlock = { date: peakDay, time: dayBlocks[peakIdx].time, value: peakLoadKw };
    }
  }

  // ── Load Analysis chart: peak day's own 30-min curve + summary stats ────
  let loadAnalysis = null;
  if (peakBlock) {
    const threshold = peakBlock.value * 0.95;
    const peakIdx = dayBlocks.findIndex((b) => b.time === peakBlock.time);
    let lo = peakIdx;
    let hi = peakIdx;
    while (lo > 0 && dayBlocks[lo - 1].value >= threshold) lo--;
    while (hi < dayBlocks.length - 1 && dayBlocks[hi + 1].value >= threshold) hi++;
    const window = dayBlocks.slice(lo, hi + 1);
    const avgDuringPeakKw = window.reduce((s, b) => s + b.value, 0) / window.length;
    const shiftBreakdown = shiftDef.length ? computeShiftBreakdown(blockMd, shiftDef, md) : [];
    const dominantShift = shiftBreakdown.length
      ? shiftBreakdown.reduce((best, s) => (s.pct > best.pct ? s : best), shiftBreakdown[0])
      : null;
    loadAnalysis = {
      date: peakBlock.date,
      hourly: dayBlocks.map((b) => ({ time: b.time, value: b.value })),
      stats: {
        peak_period: `${window[0].time} - ${window[window.length - 1].time}`,
        peak_load_kw: peakBlock.value,
        peak_duration_hours: window.length * 0.5,
        avg_during_peak_kw: avgDuringPeakKw,
        dominant_shift_name: dominantShift ? dominantShift.name : null,
        dominant_shift_pct: dominantShift ? dominantShift.pct : null,
      },
    };
  }

  // ── Equipment kW at the exact peak block, from MySQL (MD401-404) ────────
  let equipKw = [];
  if (equipmentIds.length && peakBlock) {
    try {
      const [rows] = await pool.query(
        `SELECT device_id, max_demand_kW AS value
         FROM Overall_hourly_energy_consumption
         WHERE device_id IN (?) AND DATE_FORMAT(timestamp, '%Y-%m-%d') = ? AND DATE_FORMAT(timestamp, '%H:%i') = ?`,
        [equipmentIds, peakBlock.date, peakBlock.time]
      );

      // Relabel raw device_ids to their Master Facility display name
      // (meterName) — same collection/field GET /facilities reads. Falls
      // back to the raw device_id for any meter with no facility record.
      let displayNameByDeviceId = {};
      try {
        const cdb = await getClientFirestore(clientId);
        const snapshot = await cdb.collection("master_facilities").get();
        displayNameByDeviceId = Object.fromEntries(
          snapshot.docs
            .map((d) => d.data())
            .filter((f) => f.meterId && f.meterName)
            .map((f) => [f.meterId, f.meterName])
        );
      } catch (e) {
        console.warn("[mdInsightReportBuilder] master_facilities lookup failed:", e.message);
      }

      equipKw = rows.map((r) => ({
        name: displayNameByDeviceId[r.device_id] || r.device_id,
        value: Number(r.value) || 0,
      }));
    } catch (e) {
      console.warn("[mdInsightReportBuilder] equipment kW fetch failed:", e.message);
    }
  }

  // Top-10 equipment ranking table (supports the report's Equipment
  // Analysis table/donut; MD401-404 in `report` cover the required rule text).
  let equipmentRanking = null;
  if (equipKw.length && md > 0) {
    const top10 = [...equipKw]
      .sort((a, b) => b.value - a.value)
      .slice(0, 10)
      .map((e) => ({ name: e.name, value: e.value, pct: (e.value / md) * 100 }));
    const totalKw = top10.reduce((s, e) => s + e.value, 0);
    equipmentRanking = { rows: top10, total_kw: totalKw, total_pct: (totalKw / md) * 100 };
  }

  const ctx = {
    cc, md, mdRate, blockMd, dailyMd, monthlyMd, prevMonthMd, historyMaxDaily, equipKw, shiftDef,
    blockMdAll, peakStart, peakEnd, peakDays,
  };
  const report = computeReport(ctx, templates);

  const today = new Date().toISOString().slice(0, 10);
  const lastDailyDate = dailyMd.length ? dailyMd[dailyMd.length - 1].date : start;

  return {
    device_id: deviceId,
    period,
    report_date_label: fmtDate(today),
    period_label: start === lastDailyDate ? fmtDate(start) : `${fmtDate(start)} - ${fmtDate(lastDailyDate)}`,
    generated_at: fmtDate(today),
    // Not part of MdInsightReport.fromJson's shape (Flutter reads monthly
    // max demand from a separate tnb-bill-simulator call on the live path)
    // — included so callers building their own payload (the monthly
    // rollup) don't need a second query to get the same figure.
    monthly_max_demand_kw: md,
    daily_series: dailyMd,
    load_analysis: loadAnalysis,
    equipment_ranking: equipmentRanking,
    ...report,
  };
}

module.exports = { buildDeviceReport, getTemplates, monthBounds };
