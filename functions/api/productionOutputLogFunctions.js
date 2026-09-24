const express = require("express");
const { getMysqlPoolSafe } = require("../helpers/dbConnections");
const { insertEntry: insertKwhPerTonneLogEntry } = require("./kwhPerTonneDataLog");

// eslint-disable-next-line new-cap
const router = express.Router();

const TABLE = "production_output_log";

// Source of record is per-client MySQL (see functions/sql/production_output_log.sql) —
// getMysqlPoolSafe resolves the caller's own database via x-client-id (integration_config),
// falling back to the shared default (Danapac) database when the header is absent or the
// client has no MySQL config, same tenant resolution as md_insight_report_log and friends.
function poolFor(req) {
  const clientId = req.headers["x-client-id"] || null;
  return getMysqlPoolSafe(clientId, undefined, req);
}

function mapRow(row) {
  return {
    id: row.id,
    date: row.date instanceof Date ? row.date.toISOString().slice(0, 10) : row.date,
    time: row.time || "",
    machine: row.machine_id,
    workOrderNumber: row.work_order_number || "",
    product: row.product || "",
    processDepartment: row.process_department || "",
    shift: row.shift || "",
    shiftStartTime: row.shift_start_time || "",
    ...(row.previous_reading !== null && row.previous_reading !== undefined ? {previousReading: Number(row.previous_reading)} : {}),
    ...(row.meter_reading_now !== null && row.meter_reading_now !== undefined ? {meterReadingNow: Number(row.meter_reading_now)} : {}),
    kwh: Number(row.kwh),
    tonnes: Number(row.tonnes),
    reportBy: row.report_by || "",
    ...(row.user_id ? {userId: row.user_id} : {}),
    createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
    updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
  };
}

// ✅ GET all entries (optionally filtered by userId)
router.get("/", async (req, res) => {
  try {
    const {userId} = req.query;
    const conditions = [];
    const params = [];
    if (userId) { conditions.push("user_id = ?"); params.push(userId); }
    const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

    const pool = await poolFor(req);
    const [rows] = await pool.query(
      `SELECT * FROM ${TABLE} ${where} ORDER BY \`date\` DESC, id DESC`,
      params,
    );
    res.status(200).json(rows.map(mapRow));
  } catch (error) {
    console.error("Error fetching production output log:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ GET single entry by ID
router.get("/:id", async (req, res) => {
  try {
    const pool = await poolFor(req);
    const [rows] = await pool.query(`SELECT * FROM ${TABLE} WHERE id = ?`, [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({error: "Entry not found."});
    }
    res.status(200).json(mapRow(rows[0]));
  } catch (error) {
    console.error("Error fetching entry:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ POST create new entry
router.post("/", async (req, res) => {
  try {
    const {
      date, time, machine, workOrderNumber, product,
      processDepartment, shift, shiftStartTime, previousReading, meterReadingNow,
      kwh, tonnes, reportBy, userId,
    } = req.body;

    if (!date || !date.trim()) {
      return res.status(400).json({error: "Date is required."});
    }
    if (!machine || !machine.trim()) {
      return res.status(400).json({error: "Machine is required."});
    }
    if (kwh === undefined || kwh === null) {
      return res.status(400).json({error: "kWh value is required."});
    }
    if (tonnes === undefined || tonnes === null) {
      return res.status(400).json({error: "Tonnes value is required."});
    }

    // Callers (e.g. the kWh/Tonne Add Data form) send their own editable
    // "time" — a live/current-time field the user can adjust. Fall back to
    // the server clock only when the caller doesn't provide one.
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes().toString().padStart(2, "0");
    const seconds = now.getSeconds().toString().padStart(2, "0");
    const ampm = hours < 12 ? "AM" : "PM";
    const displayHour = hours.toString().padStart(2, "0");
    const serverTimeStr = `${displayHour}:${minutes}:${seconds} ${ampm}`;

    const pool = await poolFor(req);
    const [result] = await pool.query(
      `INSERT INTO ${TABLE}
        (\`date\`, \`time\`, machine_id, work_order_number, product, process_department,
         shift, shift_start_time, previous_reading, meter_reading_now, kwh, tonnes, report_by, user_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        date.trim(),
        time && time.trim() ? time.trim() : serverTimeStr,
        machine.trim(),
        workOrderNumber ? workOrderNumber.trim() : "",
        product ? product.trim() : "",
        processDepartment ? processDepartment.trim() : "",
        shift ? shift.trim() : "",
        shiftStartTime ? shiftStartTime.trim() : "",
        previousReading !== undefined && previousReading !== null ? Number(previousReading) : null,
        meterReadingNow !== undefined && meterReadingNow !== null ? Number(meterReadingNow) : null,
        Number(kwh),
        Number(tonnes),
        reportBy ? reportBy.trim() : "",
        userId || null,
      ],
    );

    const [rows] = await pool.query(`SELECT * FROM ${TABLE} WHERE id = ?`, [result.insertId]);
    const entry = mapRow(rows[0]);

    // Mirror into the MySQL kWh_per_tonne_data_log table that backs the
    // kWh/Tonne module's reporting — same clientId as the entry above, so
    // the mirror lands in that client's own database. A failure here is
    // logged but doesn't fail the request.
    try {
      await insertKwhPerTonneLogEntry({
        date: entry.date,
        machine_id: entry.machine,
        product_type: entry.product,
        kWh_consumed: entry.kwh,
        tonnes_produced: entry.tonnes,
      }, req.headers["x-client-id"] || null);
    } catch (mysqlError) {
      console.warn("Failed to mirror production output entry to kWh_per_tonne_data_log:", mysqlError.message);
    }

    res.status(201).json(entry);
  } catch (error) {
    console.error("Error creating production output entry:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ PUT update entry by ID
router.put("/:id", async (req, res) => {
  const entryId = req.params.id;
  try {
    const pool = await poolFor(req);
    const [existing] = await pool.query(`SELECT id FROM ${TABLE} WHERE id = ?`, [entryId]);
    if (existing.length === 0) {
      return res.status(404).json({error: "Entry not found."});
    }

    const {
      date, time, machine, workOrderNumber, product,
      processDepartment, shift, shiftStartTime, previousReading, meterReadingNow,
      kwh, tonnes, reportBy,
    } = req.body;

    const setClauses = [];
    const params = [];
    if (date !== undefined) { setClauses.push("`date` = ?"); params.push(date.trim()); }
    if (time !== undefined) { setClauses.push("`time` = ?"); params.push(time.trim()); }
    if (machine !== undefined) { setClauses.push("machine_id = ?"); params.push(machine.trim()); }
    if (workOrderNumber !== undefined) { setClauses.push("work_order_number = ?"); params.push(workOrderNumber.trim()); }
    if (product !== undefined) { setClauses.push("product = ?"); params.push(product.trim()); }
    if (processDepartment !== undefined) { setClauses.push("process_department = ?"); params.push(processDepartment.trim()); }
    if (shift !== undefined) { setClauses.push("shift = ?"); params.push(shift.trim()); }
    if (shiftStartTime !== undefined) { setClauses.push("shift_start_time = ?"); params.push(shiftStartTime.trim()); }
    if (previousReading !== undefined && previousReading !== null) { setClauses.push("previous_reading = ?"); params.push(Number(previousReading)); }
    if (meterReadingNow !== undefined && meterReadingNow !== null) { setClauses.push("meter_reading_now = ?"); params.push(Number(meterReadingNow)); }
    if (kwh !== undefined) { setClauses.push("kwh = ?"); params.push(Number(kwh)); }
    if (tonnes !== undefined) { setClauses.push("tonnes = ?"); params.push(Number(tonnes)); }
    if (reportBy !== undefined) { setClauses.push("report_by = ?"); params.push(reportBy.trim()); }

    if (setClauses.length === 0) {
      return res.status(400).json({error: "No fields to update."});
    }

    params.push(entryId);
    await pool.query(`UPDATE ${TABLE} SET ${setClauses.join(", ")} WHERE id = ?`, params);

    const [rows] = await pool.query(`SELECT * FROM ${TABLE} WHERE id = ?`, [entryId]);
    res.status(200).json({success: true, ...mapRow(rows[0])});
  } catch (error) {
    console.error("Error updating production output entry:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ DELETE entry by ID
router.delete("/:id", async (req, res) => {
  const entryId = req.params.id;
  try {
    const pool = await poolFor(req);
    const [existing] = await pool.query(`SELECT id FROM ${TABLE} WHERE id = ?`, [entryId]);
    if (existing.length === 0) {
      return res.status(404).json({error: "Entry not found."});
    }
    await pool.query(`DELETE FROM ${TABLE} WHERE id = ?`, [entryId]);
    res.status(200).json({success: true, message: "Entry deleted successfully.", id: entryId});
  } catch (error) {
    console.error("Error deleting production output entry:", error);
    res.status(500).json({error: error.message});
  }
});

module.exports = router;
