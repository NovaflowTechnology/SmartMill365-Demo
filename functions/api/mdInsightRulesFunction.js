const express = require("express");
const { getMysqlPoolSafe } = require("../helpers/dbConnections");
const { buildDeviceReport, getTemplates } = require("../helpers/mdInsightReportBuilder");

// eslint-disable-next-line new-cap
const router = express.Router();

/**
 * GET /md-insight-rules
 * Query params:
 *   device_id             (required) — Overall_*_energy_consumption device_id / TNB meter tag
 *   period                (optional) — 'YYYY-MM', defaults to the current month
 *   cc                    (required) — contract capacity in kW (resolved by the caller, same
 *                                      source as energy-settings/contractCapacity)
 *   md_rate               (required) — RM/kW MD tariff rate (resolved by the caller, same source
 *                                      as masterBillingConfig mdCapacityCharge + mdNetworkCharge)
 *   equipment_device_ids  (optional) — comma-separated Overall_hourly_energy_consumption
 *                                      device_ids for equipment attribution (MD401-404); omitted
 *                                      -> insufficient_data for those four rules (spec §5,
 *                                      "empty equipment set")
 *   peak_start, peak_end  (optional) — site's Peak Hour ToU window (HH:mm), same source as
 *                                      contractCapacity.peakHourToU; restricts MD301's "first
 *                                      exceeded" scan to peak-hour readings when supplied
 *   peak_days             (optional) — comma-separated weekdays (1=Mon…7=Sun) the ToU window
 *                                      applies to; omitted -> every day
 *
 * The actual computation (SQL reads, rule engine, response assembly) lives in
 * ../helpers/mdInsightReportBuilder.js, shared with the scheduled monthly
 * rollup (helpers/mdInsightMonthlyRollup.js) so a live request and an
 * auto-logged snapshot for the same inputs render identically.
 */
router.get("/", async (req, res) => {
  const deviceId = req.query.device_id;
  const equipIdsRaw = req.query.equipment_device_ids;
  const cc = req.query.cc !== undefined ? Number(req.query.cc) : null;
  const mdRate = req.query.md_rate !== undefined ? Number(req.query.md_rate) : null;
  const period = /^\d{4}-\d{2}$/.test(req.query.period || "")
    ? req.query.period
    : new Date().toISOString().slice(0, 7);
  const peakStart = /^\d{1,2}:\d{2}$/.test(req.query.peak_start || "") ? req.query.peak_start : null;
  const peakEnd = /^\d{1,2}:\d{2}$/.test(req.query.peak_end || "") ? req.query.peak_end : null;
  const peakDays = (req.query.peak_days || "")
    .split(",")
    .map((d) => parseInt(d, 10))
    .filter((d) => d >= 1 && d <= 7);
  const equipmentIds = (equipIdsRaw || "").split(",").map((s) => s.trim()).filter(Boolean);

  if (!deviceId) return res.status(400).json({ error: "Missing device_id" });
  if (cc === null || Number.isNaN(cc)) return res.status(400).json({ error: "Missing/invalid cc" });

  const clientId = req.headers["x-client-id"] || null;

  try {
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const templates = await getTemplates(pool, clientId);
    const responseBody = await buildDeviceReport({
      pool, clientId, deviceId, period, cc, mdRate, equipmentIds, peakStart, peakEnd, peakDays, templates,
    });
    return res.status(200).json(responseBody);
  } catch (error) {
    console.error("Error computing MD Insight report:", error);
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
