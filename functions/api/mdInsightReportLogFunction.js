const express = require("express");
const { getMysqlPoolSafe } = require("../helpers/dbConnections");
const { runMonthlyRollup } = require("../helpers/mdInsightMonthlyRollup");

// eslint-disable-next-line new-cap
const router = express.Router();

const TABLE = "md_insight_report_log";

// `payload_json` may come back as a JSON string (TEXT/LONGTEXT column) or
// already parsed into an object/array (native JSON column — mysql2 decodes
// those automatically), depending on how the table was created.
function parsePayload(value) {
  if (value == null) return null;
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch (e) {
    return null;
  }
}

/**
 * GET /md-insight-report-log
 * Lists past report generations, most recent first — backs the report
 * page's "View Logs" menu, and also the period dropdown's locked-snapshot
 * lookup (source=auto&limit=1) so a closed month renders from this frozen
 * record instead of recomputing against today's live settings. Optional
 * filters narrow it to one plant/period/source; `limit` is capped at 200 so
 * a missing filter can't pull the whole table.
 *
 * Query params (all optional):
 *   plant_code, period, source ('auto' | 'manual'), limit (default 50, max 200)
 */
router.get("/", async (req, res) => {
  const { plant_code: plantCode, period, source, limit } = req.query;
  const clientId = req.headers["x-client-id"] || null;
  const max = Math.min(Math.max(Number(limit) || 50, 1), 200);

  const conditions = [];
  const params = [];
  if (plantCode) { conditions.push("plant_code = ?"); params.push(String(plantCode).trim()); }
  if (period) { conditions.push("period = ?"); params.push(String(period).trim()); }
  if (source) { conditions.push("source = ?"); params.push(String(source).trim()); }
  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  try {
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const [rows] = await pool.query(
      `SELECT report_id, plant_code, period, generated_at, generated_by, report_state, source, payload_json
       FROM ${TABLE}
       ${where}
       ORDER BY generated_at DESC
       LIMIT ?`,
      [...params, max]
    );
    return res.status(200).json({
      logs: rows.map((r) => ({
        report_id: r.report_id,
        plant_code: r.plant_code,
        period: r.period,
        generated_at: r.generated_at instanceof Date ? r.generated_at.toISOString() : r.generated_at,
        generated_by: r.generated_by,
        report_state: r.report_state,
        source: r.source || "manual",
        payload_json: parsePayload(r.payload_json),
      })),
    });
  } catch (error) {
    console.error("Error fetching MD Insight report logs:", error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * POST /md-insight-report-log
 * Logs one MD Insight Report generation (called by the web app right after
 * the "Generate Report" download succeeds). Same tenant resolution
 * (x-client-id -> getMysqlPoolSafe) as GET /md-insight-rules, so the log
 * lands in the same database the report's own figures were read from.
 *
 * Body:
 *   plant_code    (required) — TNB meter/plant code the report was generated for
 *   period        (required) — 'YYYY-MM' billing period covered by the report
 *   generated_by  (required) — email/uid of the user who generated the report
 *   report_state  (required) — the report's MD status at generation time
 *                              (e.g. 'breach' | 'within' | 'unknown')
 *   payload_json  (optional) — snapshot of the report's key figures
 *
 * report_id is not accepted from the caller — it's the table's own
 * AUTO_INCREMENT primary key, assigned by MySQL on insert.
 */
router.post("/", async (req, res) => {
  const {
    plant_code: plantCode, period, generated_by: generatedBy, report_state: reportState,
    payload_json: payload, source,
  } = req.body || {};

  if (!plantCode) return res.status(400).json({ error: "Missing plant_code" });
  if (!period) return res.status(400).json({ error: "Missing period" });
  if (!generatedBy) return res.status(400).json({ error: "Missing generated_by" });
  if (!reportState) return res.status(400).json({ error: "Missing report_state" });

  const clientId = req.headers["x-client-id"] || null;

  try {
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const [result] = await pool.query(
      `INSERT INTO ${TABLE}
        (plant_code, period, generated_at, generated_by, report_state, source, payload_json)
       VALUES (?, ?, NOW(), ?, ?, ?, ?)`,
      [
        String(plantCode).trim(),
        String(period).trim(),
        String(generatedBy).trim(),
        String(reportState).trim(),
        source ? String(source).trim() : "manual",
        payload ? JSON.stringify(payload) : null,
      ]
    );
    return res.status(201).json({ success: true, report_id: result.insertId });
  } catch (error) {
    console.error("Error logging MD Insight report generation:", error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * POST /md-insight-report-log/backfill?period=YYYY-MM&client_id=...
 * Manually runs the same canonical monthly snapshot the scheduled rollup
 * (mdInsightMonthlyRollup.js) writes at month-end, for one tenant and one
 * already-closed period — used once per gap to backfill months that closed
 * before the scheduled job existed (see functions/helpers/
 * mdInsightMonthlyRollup.js for what each snapshot contains and why cc/
 * mdRate resolve the way they do). `client_id` is required (not "all
 * tenants") to keep this manual entry point narrowly scoped; the real
 * all-tenant run only happens via the scheduled trigger.
 */
router.post("/backfill", async (req, res) => {
  const period = req.query.period || req.body?.period;
  const clientId = req.query.client_id || req.body?.client_id;

  if (!/^\d{4}-\d{2}$/.test(period || "")) {
    return res.status(400).json({ error: "period is required, format 'YYYY-MM'" });
  }
  if (!clientId) {
    return res.status(400).json({ error: "client_id is required" });
  }

  try {
    const results = await runMonthlyRollup({ period, onlyClientId: clientId });
    return res.status(200).json({ success: true, period, client_id: clientId, results });
  } catch (error) {
    console.error("Error running MD Insight report backfill:", error);
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
