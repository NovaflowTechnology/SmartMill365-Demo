const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// Fetch All Device Types
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "deviceTypes", null);
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching device types:", error);
    res.status(500).json({error: error.message});
  }
});

// Fetch Single Device Type by ID
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "deviceTypes", null);
    const doc = snapshot.docs.find((d) => d.id === req.params.id);
    if (!doc) return res.status(404).json({error: "Device type not found"});
    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching device type:", error);
    res.status(500).json({error: error.message});
  }
});

// Add a Device Type
router.post("/add", async (req, res) => {
  try {
    const {name} = req.body;
    if (!name || !name.trim()) return res.status(400).json({error: "Device type name is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("deviceTypes");
      const trimmedName = name.trim();

      const existing = await col.where("name", "==", trimmedName).get();
      if (!existing.empty) return {error: "Device type with the same name already exists."};

      const snapshot = await col.get();
      const newId = generateNextDeviceTypeId(snapshot.docs.map((d) => d.id));

      const newDeviceType = {name: trimmedName, createdAt: admin.firestore.FieldValue.serverTimestamp()};
      await col.doc(newId).set(newDeviceType);
      return {success: true, id: newId, ...newDeviceType};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    console.error("Error adding device type:", error);
    res.status(500).json({error: error.message});
  }
});

// Update a Device Type by ID
router.put("/:id", async (req, res) => {
  try {
    const {name} = req.body;
    if (!name || !name.trim()) return res.status(400).json({error: "Device type name is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("deviceTypes");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      const trimmedName = name.trim();
      const duplicate = await col.where("name", "==", trimmedName).get();
      if (duplicate.docs.some((d) => d.id !== req.params.id)) return {error: "Device type with the same name already exists."};

      const updates = {name: trimmedName, updatedAt: admin.firestore.FieldValue.serverTimestamp()};
      await docRef.update(updates);
      return {success: true, id: req.params.id, ...updates};
    });

    if (result.notFound) return res.status(404).json({error: "Device type not found"});
    if (result.error) return res.status(400).json({error: result.error});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating device type:", error);
    res.status(500).json({error: error.message});
  }
});

// Delete Device Type by ID
router.delete("/:id", async (req, res) => {
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("deviceTypes");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {message: "Device type deleted successfully", id: req.params.id};
    });

    if (result.notFound) return res.status(404).json({error: "Device type not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting device type:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextDeviceTypeId(existingIds) {
  const pattern = /^DT(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `DT${(maxNum + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
