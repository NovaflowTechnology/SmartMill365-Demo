const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Processes
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {userId} = req.query;
    const snapshot = await queryWithFallback(clientId, "processes", (col) =>
      userId ? col.where("userId", "==", userId) : col
    );
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching processes:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Fetch Single Process by ID
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "processes", null);
    const doc = snapshot.docs.find((d) => d.id === req.params.id);
    if (!doc) return res.status(404).json({error: "Process not found"});
    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching process:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add a Process
router.post("/add", async (req, res) => {
  try {
    const {name, description, valid, userId} = req.body;

    if (!name) return res.status(400).json({error: "name is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("processes");

      let dupQuery = col.where("name", "==", name);
      if (userId) dupQuery = dupQuery.where("userId", "==", userId);
      const existing = await dupQuery.get();
      if (!existing.empty) return {error: "Process with same name already exists."};

      let idQuery = col;
      if (userId) idQuery = idQuery.where("userId", "==", userId);
      const snapshot = await idQuery.get();
      const newId = generateNextProcessId(snapshot.docs.map((d) => d.id));

      const newProcess = {
        name, description: description || "",
        valid: valid !== undefined ? valid : true,
        userId: userId || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await col.doc(newId).set(newProcess);
      return {success: true, id: newId, ...newProcess};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    console.error("Error adding process:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Update a Process by ID
router.put("/:id", async (req, res) => {
  try {
    const {name, description, valid} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("processes");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      const updates = {};
      if (name !== undefined) updates.name = name;
      if (description !== undefined) updates.description = description;
      if (valid !== undefined) updates.valid = valid;
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      await docRef.update(updates);
      return {success: true, id: req.params.id, ...updates};
    });

    if (result.notFound) return res.status(404).json({error: "Process not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating process:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Process by ID
router.delete("/:id", async (req, res) => {
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("processes");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {message: "Process deleted successfully", id: req.params.id};
    });

    if (result.notFound) return res.status(404).json({error: "Process not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting process:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextProcessId(existingIds) {
  const pattern = /^PR(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `PR${(maxNum + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
