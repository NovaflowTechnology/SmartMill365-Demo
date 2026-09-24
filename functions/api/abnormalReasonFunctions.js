const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Abnormal Reasons
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {userId} = req.query;
    const snapshot = await queryWithFallback(clientId, "abnormalReasons", (col) =>
      userId ? col.where("userId", "==", userId) : col
    );
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching abnormal reasons:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Fetch Single Abnormal Reason by ID
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "abnormalReasons", null);
    const doc = snapshot.docs.find((d) => d.id === req.params.id);
    if (!doc) return res.status(404).json({error: "Abnormal reason not found"});
    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching abnormal reason:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add an Abnormal Reason
router.post("/add", async (req, res) => {
  try {
    const {reasonNo, reasonDescription, type, productionArea, equipmentModel, userId} = req.body;

    if (!reasonNo || !reasonDescription) {
      return res.status(400).json({error: "reasonNo and reasonDescription are required."});
    }

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("abnormalReasons");

      let dupQuery = col.where("reasonNo", "==", reasonNo);
      if (userId) dupQuery = dupQuery.where("userId", "==", userId);
      const existing = await dupQuery.get();
      if (!existing.empty) return {error: "Abnormal reason with same No. already exists."};

      let idQuery = col;
      if (userId) idQuery = idQuery.where("userId", "==", userId);
      const snapshot = await idQuery.get();
      const newId = generateNextAbnormalReasonId(snapshot.docs.map((d) => d.id));

      const newReason = {
        reasonNo, reasonDescription,
        type: type || "",
        productionArea: productionArea || [],
        equipmentModel: equipmentModel && equipmentModel.length > 0 ? equipmentModel : ["*"],
        userId: userId || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await col.doc(newId).set(newReason);
      return {success: true, id: newId, ...newReason};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    console.error("Error adding abnormal reason:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Update an Abnormal Reason by ID
router.put("/:id", async (req, res) => {
  try {
    const {reasonNo, reasonDescription, type, productionArea, equipmentModel} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("abnormalReasons");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      const updates = {};
      if (reasonNo !== undefined) updates.reasonNo = reasonNo;
      if (reasonDescription !== undefined) updates.reasonDescription = reasonDescription;
      if (type !== undefined) updates.type = type;
      if (productionArea !== undefined) updates.productionArea = productionArea;
      if (equipmentModel !== undefined) updates.equipmentModel = equipmentModel;
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      await docRef.update(updates);
      return {success: true, id: req.params.id, ...updates};
    });

    if (result.notFound) return res.status(404).json({error: "Abnormal reason not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating abnormal reason:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Abnormal Reason by ID
router.delete("/:id", async (req, res) => {
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("abnormalReasons");
      const docRef = col.doc(req.params.id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {message: "Abnormal reason deleted successfully", id: req.params.id};
    });

    if (result.notFound) return res.status(404).json({error: "Abnormal reason not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting abnormal reason:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextAbnormalReasonId(existingIds) {
  const pattern = /^AR(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `AR${(maxNum + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
