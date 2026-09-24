const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Production Lines
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {userId, factory_id} = req.query;
    const snapshot = await queryWithFallback(clientId, "productionLines", (col) => {
      let q = col;
      if (userId) q = q.where("userId", "==", userId);
      if (factory_id) q = q.where("factory_id", "==", factory_id);
      return q;
    });
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching production lines:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Fetch Single Production Line by ID
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "productionLines", null);
    const doc = snapshot.docs.find((d) => d.id === req.params.id);
    if (!doc) return res.status(404).json({error: "Production line not found"});
    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching production line:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add a Production Line
router.post("/add", async (req, res) => {
  try {
    const {lineNo, name, productionArea, factory_id, description, valid, userId} = req.body;

    if (!lineNo || !name) {
      return res.status(400).json({error: "lineNo and name are required."});
    }

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("productionLines");

      let dupQuery = col.where("lineNo", "==", lineNo);
      if (userId) dupQuery = dupQuery.where("userId", "==", userId);
      const existing = await dupQuery.get();
      if (!existing.empty) return {error: "Production line with same No. already exists."};

      let idQuery = col;
      if (userId) idQuery = idQuery.where("userId", "==", userId);
      const snapshot = await idQuery.get();
      const newId = generateNextProductionLineId(snapshot.docs.map((d) => d.id));

      const newLine = {
        lineNo, name,
        productionArea: productionArea || "",
        factory_id: factory_id || "",
        description: description || "",
        valid: valid !== undefined ? valid : true,
        userId: userId || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await col.doc(newId).set(newLine);
      return {success: true, id: newId, ...newLine};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    console.error("Error adding production line:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Update a Production Line by ID
router.put("/:id", async (req, res) => {
  try {
    const {lineNo, name, productionArea, factory_id, description, valid} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("productionLines");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      const updates = {};
      if (lineNo !== undefined) updates.lineNo = lineNo;
      if (name !== undefined) updates.name = name;
      if (productionArea !== undefined) updates.productionArea = productionArea;
      if (factory_id !== undefined) updates.factory_id = factory_id;
      if (description !== undefined) updates.description = description;
      if (valid !== undefined) updates.valid = valid;
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      await docRef.update(updates);
      return {success: true, id: req.params.id, ...updates};
    });

    if (result.notFound) return res.status(404).json({error: "Production line not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating production line:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Production Line by ID
router.delete("/:id", async (req, res) => {
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("productionLines");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {message: "Production line deleted successfully", id: req.params.id};
    });

    if (result.notFound) return res.status(404).json({error: "Production line not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting production line:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextProductionLineId(existingIds) {
  const pattern = /^PL(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `PL${(maxNum + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
