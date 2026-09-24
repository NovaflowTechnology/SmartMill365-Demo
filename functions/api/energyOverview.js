const express = require("express");

// eslint-disable-next-line new-cap
const router = express.Router();
const { getInfluxClient, getInfluxSchema, deviceFilter, ENERGY_FIELD_NAMES, getMysqlPoolSafe } = require("../helpers/dbConnections");

// ── Per-request MySQL pool ────────────────────────────────────────────────────
// Resolves the client's MySQL pool from integration_config (host/port/username/
// database). If the client has no MySQL config, falls back to the default
// (Danapac) pool so existing single-tenant behaviour keeps working.
async function getMysql(req) {
  const clientId = req.clientId || req.headers["x-client-id"];
  return getMysqlPoolSafe(clientId, undefined, req);
}

function runInfluxQuery(queryApi, flux) {
  return new Promise((resolve, reject) => {
    const rows = [];
    queryApi.queryRows(flux, {
      next(row, meta) { rows.push(meta.toObject(row)); },
      error: reject,
      complete() { resolve(rows); },
    });
  });
}

async function influxEnergyFallback(period, req) {
  let rangeStart = "-1d";
  if (period === "monthly") rangeStart = "-30d";
  if (period === "yearly") rangeStart = "-365d";

  // No x-client-id → getInfluxClient/getInfluxSchema fall back to the
  // default (Danapac) connection, so untagged requests keep working.
  const clientId = req.headers["x-client-id"];
  const { queryApi, bucket } = await getInfluxClient(clientId, req);
  const schema = await getInfluxSchema(clientId);
  const tag = schema.deviceIdTag;
  const energyFieldFilter = ENERGY_FIELD_NAMES
    .map((f) => `r._field == "${f}"`)
    .join(" or ");

  // Get first and last cumulative energy reading per device to compute consumption
  const firstQ = `
    from(bucket: "${bucket}")
      |> range(start: ${rangeStart})
      |> filter(fn: (r) => r._measurement == "${schema.measurement}" and (${energyFieldFilter}))
      ${deviceFilter(schema, null)}
      |> first()
      |> group(columns: ["${tag}"])
  `;
  const lastQ = `
    from(bucket: "${bucket}")
      |> range(start: ${rangeStart})
      |> filter(fn: (r) => r._measurement == "${schema.measurement}" and (${energyFieldFilter}))
      ${deviceFilter(schema, null)}
      |> last()
      |> group(columns: ["${tag}"])
  `;
  const [firstRows, lastRows] = await Promise.all([
    runInfluxQuery(queryApi, firstQ),
    runInfluxQuery(queryApi, lastQ),
  ]);
  const firstMap = {};
  firstRows.forEach((r) => { if (r[tag]) firstMap[r[tag]] = r._value ?? 0; });
  const result = [];
  lastRows.forEach((r) => {
    const device = r[tag];
    if (!device) return;
    const first = firstMap[device] ?? 0;
    const last  = r._value ?? 0;
    const energy = Math.max(0, last - first);
    result.push({ device, total_energy: parseFloat(energy.toFixed(3)), energy1: last, energy2: first });
  });
  return result;
}

router.get("/data/:period", async (req, res) => {
  const { period } = req.params;

  let setQuery = `SET @today_myt := DATE(CONVERT_TZ(NOW(), '+00:00', '+08:00'));`;
  let referenceDateSQL = "";
  let mainQuery = "";

  if (period === "monthly") {
    referenceDateSQL = `SET @ref_date := LAST_DAY(DATE_SUB(@today_myt, INTERVAL 1 MONTH));`;
  } else if (period === "yearly") {
    referenceDateSQL = `SET @ref_date := DATE(CONCAT(YEAR(@today_myt) - 1, '-12-31'));`;
  } else {
    referenceDateSQL = `SET @ref_date := DATE_SUB(@today_myt, INTERVAL 1 DAY);`;
  }

  if (period === "daily") {
    mainQuery = `
      WITH today_max AS (
        SELECT device_id, MAX(energy_edel) AS energy1
        FROM energy_data
        WHERE timestamp >= @today_myt
          AND timestamp < DATE_ADD(@today_myt, INTERVAL 1 DAY)
        GROUP BY device_id
      ),
      summary_max AS (
        SELECT dds.device_id, dds.energy_edel AS energy2
        FROM daily_device_summary dds
        WHERE DATE(dds.timestamp) = @ref_date
      )
    SELECT 
      COALESCE(t.device_id, s.device_id) AS device,
      COALESCE(NULLIF(t.energy1, 0), s.energy2, 0) AS energy1,
      COALESCE(s.energy2, 0) AS energy2,
      COALESCE(NULLIF(t.energy1, 0), s.energy2, 0) - COALESCE(s.energy2, 0) AS total_energy
    FROM today_max t
    LEFT JOIN summary_max s ON t.device_id = s.device_id

    UNION

    SELECT 
      COALESCE(t.device_id, s.device_id) AS device,
      COALESCE(NULLIF(t.energy1, 0), s.energy2, 0) AS energy1,
      COALESCE(s.energy2, 0) AS energy2,
      COALESCE(NULLIF(t.energy1, 0), s.energy2, 0) - COALESCE(s.energy2, 0) AS total_energy
    FROM summary_max s
    LEFT JOIN today_max t ON s.device_id = t.device_id
    WHERE t.device_id IS NULL;
    `;
  } else {
    mainQuery = `
      WITH raw_today AS (
        SELECT device_id, MAX(energy_edel) AS energy1
        FROM energy_data
        WHERE timestamp >= @today_myt
          AND timestamp < DATE_ADD(@today_myt, INTERVAL 1 DAY)
        GROUP BY device_id
      ),
      all_devices AS (
        SELECT device_id FROM energy_data
        UNION
        SELECT device_id FROM daily_device_summary
      ),
      today_max AS (
        SELECT 
          d.device_id,
          COALESCE(NULLIF(r.energy1, 0), fallback.energy_edel, 0) AS energy1
        FROM all_devices d
        LEFT JOIN raw_today r ON d.device_id = r.device_id
        LEFT JOIN LATERAL (
          SELECT energy_edel
          FROM daily_device_summary
          WHERE device_id = d.device_id AND energy_edel != 0
          ORDER BY timestamp DESC
          LIMIT 1
        ) fallback ON TRUE
      ),
      summary_max AS (
        SELECT d.device_id,
              COALESCE(dds.energy_edel, 0) AS energy2
        FROM all_devices d
        LEFT JOIN daily_device_summary dds
          ON d.device_id = dds.device_id AND dds.timestamp = @ref_date
      )
      SELECT 
        d.device_id AS device,
        COALESCE(NULLIF(t.energy1, 0), s.energy2, 0) AS energy1,
        COALESCE(s.energy2, 0) AS energy2,
        COALESCE(NULLIF(t.energy1, 0), s.energy2, 0) - COALESCE(s.energy2, 0) AS total_energy
      FROM all_devices d
      LEFT JOIN today_max t ON d.device_id = t.device_id
      LEFT JOIN summary_max s ON d.device_id = s.device_id;
    `;
  }

  let conn;
  try {
    const clientPool = await getMysql(req);
    // SET @today_myt / @ref_date are session variables — they must run on the
    // SAME connection, otherwise the pool may hand the next query a different
    // connection and silently lose them. Acquire one connection for all three.
    conn = await clientPool.getConnection();
    await conn.query(setQuery);
    await conn.query(referenceDateSQL);
    const [results] = await conn.query(mainQuery);

    // If MySQL has no data, fallback to InfluxDB
    if (!results || results.length === 0) {
      try {
        const influxData = await influxEnergyFallback(period, req);
        return res.json(influxData);
      } catch (e) {
        console.error("influxEnergyFallback error:", e);
        return res.json([]);
      }
    }
    return res.json(results);
  } catch (error) {
    // MySQL unreachable / connection-exhausted — fall back to InfluxDB instead
    // of surfacing a 500 so the dashboard doesn't go blank.
    console.error("energyOverview MySQL error:", error.message);
    try {
      const influxData = await influxEnergyFallback(period, req);
      return res.json(influxData);
    } catch (e) {
      console.error("influxEnergyFallback error:", e);
      return res
        .status(500)
        .json({ error: "Main query error", message: error.message });
    }
  } finally {
    if (conn) conn.release();
  }
});

module.exports = router;
