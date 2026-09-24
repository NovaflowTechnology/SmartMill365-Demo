const express = require("express");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// Fetch All Alarms
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const { company_id } = req.query;
    const snapshot = await queryWithFallback(clientId, "alarms", (col) =>
      company_id ? col.where("company_id", "==", company_id) : col
    );
    res.status(200).json(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
  } catch (error) {
    console.error("Error fetching alarms:", error);
    res.status(500).json({ error: error.message });
  }
});

// Add Alarm
router.post("/add", async (req, res) => {
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("alarms");

      const { name, device_id, message, threshold_minimum, threshold_maximum, pic, esop, status, company_id } = req.body;

      const nameCheck = await col.where("name", "==", name).get();
      if (!nameCheck.empty) return { error: "An alarm with the same name already exists." };

      const snapshot = await col.get();
      const existingIds = snapshot.docs.map((d) => d.id);
      const nextId = generateNextAlarmId(existingIds);

      const data = { name, device_id, message, threshold_minimum, threshold_maximum, pic, esop, status: status !== undefined ? status : true, company_id };
      await col.doc(nextId).set(data);
      return { success: true, id: nextId, ...data };
    });

    if (result.error) return res.status(400).json({ error: result.error });
    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Edit Alarm
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("alarms").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return { notFound: true };

      const { name, device_id, message, threshold_minimum, threshold_maximum, pic, esop } = req.body;
      const update = { name, device_id, message, threshold_minimum, threshold_maximum, pic };
      if (esop !== undefined) update.esop = esop;

      await docRef.update(update);
      return { message: "Alarm updated successfully", id };
    });

    if (result.notFound) return res.status(404).json({ error: "Alarm not found" });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete Alarm
router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("alarms").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return { notFound: true };
      await docRef.delete();
      return { message: "Alarm deleted successfully", id };
    });

    if (result.notFound) return res.status(404).json({ error: "Alarm not found" });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

function generateNextAlarmId(existingIds) {
  if (existingIds.length === 0) return "A0001";
  existingIds.sort();
  const lastId = existingIds[existingIds.length - 1];
  const numericPart = parseInt(lastId.substring(1));
  return `A${(numericPart + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
