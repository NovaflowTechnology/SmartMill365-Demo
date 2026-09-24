const express = require("express");
const { getMysqlPoolSafe } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

function mapRow(row) {
  return {
    id: row.id,
    date: row.date instanceof Date ? row.date.toISOString().slice(0, 10) : row.date,
    machine_id:      row.machine_id,
    product_type:    row.product_type,
    factory_id:      row.factory_id,
    plant_id:        row.plant_id,
    zone_id:         row.zone_id,
    kWh_consumed:    row.kWh_consumed,
    tonnes_produced: row.tonnes_produced,
    variance:        row.variance,
    cost:            row.cost,
    status:          row.status,
    created_at:      row.created_at,
    updated_at:      row.updated_at,
  };
}

// ── GET all entries (optional filters) ──────────────────────────────────────
router.get("/", async (req, res) => {
  const { factory_id, plant_id, zone_id, machine_id, from_date, to_date } = req.query;
  const clientId = req.headers["x-client-id"] || null;

  const conditions = [];
  const params = [];

  if (factory_id) { conditions.push("factory_id = ?");  params.push(factory_id); }
  if (plant_id)   { conditions.push("plant_id = ?");    params.push(plant_id); }
  if (zone_id)    { conditions.push("zone_id = ?");     params.push(zone_id); }
  if (machine_id) { conditions.push("machine_id = ?");  params.push(machine_id); }
  if (from_date)  { conditions.push("`date` >= ?");     params.push(from_date); }
  if (to_date)    { conditions.push("`date` <= ?");     params.push(to_date); }

  const whereClause = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
  const query = `SELECT * FROM kWh_per_tonne_data_log ${whereClause} ORDER BY \`date\` DESC, id DESC`;

  try {
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const [results] = await pool.query(query, params);
    return res.json(results.map(mapRow));
  } catch (err) {
    return res.status(500).json({ error: "Database error", message: err.message });
  }
});

// ── GET single entry ─────────────────────────────────────────────────────────
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const [results] = await pool.query("SELECT * FROM kWh_per_tonne_data_log WHERE id = ?", [req.params.id]);
    if (results.length === 0) return res.status(404).json({ error: "Entry not found." });
    return res.json(mapRow(results[0]));
  } catch (err) {
    return res.status(500).json({ error: "Database error", message: err.message });
  }
});

// Inserts one row and returns the mapped entry. Shared by the POST route
// below and by productionOutputLogFunctions, which mirrors an entry into
// this table without going through HTTP — the caller passes its own
// clientId so the mirror lands in the same per-client database the source
// entry was saved to, instead of always landing on the shared default DB.
async function insertEntry({
  date, machine_id, product_type,
  factory_id, plant_id, zone_id,
  kWh_consumed, tonnes_produced,
  variance, cost, status,
}, clientId) {
  if (!date || !String(date).trim()) throw new Error("date is required.");
  if (!machine_id || !String(machine_id).trim()) throw new Error("machine_id is required.");
  if (kWh_consumed === undefined || kWh_consumed === null) throw new Error("kWh_consumed is required.");
  if (tonnes_produced === undefined || tonnes_produced === null) throw new Error("tonnes_produced is required.");

  const insertQuery = `
    INSERT INTO kWh_per_tonne_data_log
      (\`date\`, machine_id, product_type, factory_id, plant_id, zone_id,
       kWh_consumed, tonnes_produced, variance, cost, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;
  const values = [
    String(date).trim(),
    String(machine_id).trim(),
    product_type ? String(product_type).trim() : "",
    factory_id   ? String(factory_id).trim()   : "",
    plant_id     ? String(plant_id).trim()     : "",
    zone_id      ? String(zone_id).trim()      : "",
    Number(kWh_consumed),
    Number(tonnes_produced),
    variance !== undefined && variance !== null ? Number(variance) : 0,
    cost     !== undefined && cost     !== null ? Number(cost)     : 0,
    status   ? String(status).trim() : "On target",
  ];

  const pool = await getMysqlPoolSafe(clientId, undefined);
  const [result] = await pool.query(insertQuery, values);
  const [rows] = await pool.query("SELECT * FROM kWh_per_tonne_data_log WHERE id = ?", [result.insertId]);
  return rows.length ? mapRow(rows[0]) : { id: result.insertId };
}

// ── POST create ──────────────────────────────────────────────────────────────
router.post("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const row = await insertEntry(req.body, clientId);
    return res.status(201).json(row);
  } catch (err) {
    const isValidationError = /required\.$/.test(err.message);
    return res.status(isValidationError ? 400 : 500).json({ error: isValidationError ? err.message : "Database error", message: err.message });
  }
});

// ── PUT update ───────────────────────────────────────────────────────────────
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const clientId = req.headers["x-client-id"] || null;
  const setClauses = [];
  const params = [];

  ["machine_id", "product_type", "factory_id", "plant_id", "zone_id", "status"].forEach((f) => {
    if (req.body[f] !== undefined) { setClauses.push(`${f} = ?`); params.push(String(req.body[f]).trim()); }
  });
  ["kWh_consumed", "tonnes_produced", "variance", "cost"].forEach((f) => {
    if (req.body[f] !== undefined) { setClauses.push(`${f} = ?`); params.push(Number(req.body[f])); }
  });
  if (req.body["date"] !== undefined) { setClauses.push("`date` = ?"); params.push(String(req.body["date"]).trim()); }

  if (setClauses.length === 0) return res.status(400).json({ error: "No fields to update." });

  params.push(id);
  try {
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const [result] = await pool.query(`UPDATE kWh_per_tonne_data_log SET ${setClauses.join(", ")} WHERE id = ?`, params);
    if (result.affectedRows === 0) return res.status(404).json({ error: "Entry not found." });
    const [rows] = await pool.query("SELECT * FROM kWh_per_tonne_data_log WHERE id = ?", [id]);
    return res.json(rows.length ? mapRow(rows[0]) : { success: true, id: Number(id) });
  } catch (err) {
    return res.status(500).json({ error: "Database error", message: err.message });
  }
});

// ── DELETE ───────────────────────────────────────────────────────────────────
router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const clientId = req.headers["x-client-id"] || null;
    const pool = await getMysqlPoolSafe(clientId, undefined, req);
    const [rows] = await pool.query("SELECT id FROM kWh_per_tonne_data_log WHERE id = ?", [id]);
    if (rows.length === 0) return res.status(404).json({ error: "Entry not found." });
    await pool.query("DELETE FROM kWh_per_tonne_data_log WHERE id = ?", [id]);
    return res.json({ success: true, message: "Entry deleted.", id: Number(id) });
  } catch (err) {
    return res.status(500).json({ error: "Database error", message: err.message });
  }
});

module.exports = router;
module.exports.insertEntry = insertEntry;
