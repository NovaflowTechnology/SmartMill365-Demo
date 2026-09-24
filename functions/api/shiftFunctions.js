const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Shifts
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {userId} = req.query;
    const snapshot = await queryWithFallback(clientId, "shifts", (col) =>
      userId ? col.where("userId", "==", userId) : col
    );
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching shifts:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add a Shift
router.post("/add", async (req, res) => {
  try {
    const {code, name, startWorkTime, finishWorkTime, valid, restTimes, userId} = req.body;

    if (!code || !code.trim()) return res.status(400).json({error: "Shift code is required."});
    if (!name || !name.trim()) return res.status(400).json({error: "Shift name is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("shifts");

      const dupQuery = await col.where("code", "==", code.trim()).get();
      if (!dupQuery.empty) return {error: "Shift with the same code already exists."};

      const snapshot = await col.get();
      const newId = generateNextShiftId(snapshot.docs.map((d) => d.id));

      const newShift = {
        code: code.trim(), name: name.trim(),
        startWorkTime: startWorkTime || "",
        finishWorkTime: finishWorkTime || "",
        valid: valid !== false,
        restTimes: Array.isArray(restTimes) ? restTimes : [],
        ...(userId ? {userId} : {}),
      };
      await col.doc(newId).set(newShift);
      return {success: true, id: newId, ...newShift};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    console.error("Error adding shift:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Update Shift by ID
router.put("/:id", async (req, res) => {
  const shiftId = req.params.id;
  try {
    const {code, name, startWorkTime, finishWorkTime, valid, restTimes} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("shifts");
      const docRef = col.doc(shiftId);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      if (code && code.trim()) {
        const nameConflict = await col.where("code", "==", code.trim()).get();
        const conflict = nameConflict.docs.find((d) => d.id !== shiftId);
        if (conflict) return {error: "Shift with the same code already exists."};
      }

      const updateData = {};
      if (code !== undefined) updateData.code = code.trim();
      if (name !== undefined) updateData.name = name.trim();
      if (startWorkTime !== undefined) updateData.startWorkTime = startWorkTime;
      if (finishWorkTime !== undefined) updateData.finishWorkTime = finishWorkTime;
      if (valid !== undefined) updateData.valid = valid;
      if (restTimes !== undefined) updateData.restTimes = Array.isArray(restTimes) ? restTimes : [];

      await docRef.update(updateData);
      const currentData = doc.data();
      return {success: true, id: shiftId, ...currentData, ...updateData};
    });

    if (result.notFound) return res.status(404).json({error: "Shift not found."});
    if (result.error) return res.status(400).json({error: result.error});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating shift:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Shift by ID
router.delete("/:id", async (req, res) => {
  const shiftId = req.params.id;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("shifts");
      const docRef = col.doc(shiftId);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {success: true, message: "Shift deleted successfully.", id: shiftId};
    });

    if (result.notFound) return res.status(404).json({error: "Shift not found."});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting shift:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextShiftId(existingIds) {
  const pattern = /^SH(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `SH${(maxNum + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
