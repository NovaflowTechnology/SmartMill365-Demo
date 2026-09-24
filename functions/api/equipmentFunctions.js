const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback, getClientFirestore } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Equipments
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {userId, factory_id} = req.query;

    const snapshot = await queryWithFallback(clientId, "equipments", (col) =>
      factory_id ? col.where("factory_id", "==", factory_id) : col
    );

    const cdb = await getClientFirestore(clientId);

    const equipments = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const data = doc.data();
        let imageUrl = data.imageUrl || null;

        if (userId) {
          const userImageDoc = await cdb.collection("equipments")
            .doc(doc.id)
            .collection("userImages")
            .doc(userId)
            .get();
          if (userImageDoc.exists) {
            imageUrl = userImageDoc.data().imageUrl;
          }
        }

        return {
          id: doc.id,
          ...data,
          imageUrl,
          purchaseDate: typeof data.purchaseDate?.toDate === "function" ? data.purchaseDate.toDate().toISOString() : null,
          warrantyDate: typeof data.warrantyDate?.toDate === "function" ? data.warrantyDate.toDate().toISOString() : null,
        };
      })
    );

    res.status(200).json(equipments);
  } catch (error) {
    console.error("Error fetching equipments:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add Equipment
router.post("/add", async (req, res) => {
  try {
    const {name, equipment_id, serialNo, modelType, equipmentProcess, productionArea, purchaseDate, warrantyDate, PIC, factory, workOrder, product, imageUrl} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("equipments");

      const existingSerial = await col.where("serialNo", "==", serialNo).get();
      if (!existingSerial.empty) return {error: "Equipment with the same serial number already exists."};

      const existingName = await col.where("name", "==", name).get();
      if (!existingName.empty) return {error: "Equipment with the same name already exists."};

      const snapshot = await col.get();
      const newEquipmentId = generateNextEquipmentId(snapshot.docs.map((d) => d.id));

      const toTimestamp = (dateStr) => new admin.firestore.Timestamp(Math.floor(new Date(dateStr).getTime() / 1000), 0);

      const newEquipment = {
        name, equipment_id, serialNo, modelType, productionArea,
        purchaseDate: toTimestamp(purchaseDate),
        warrantyDate: toTimestamp(warrantyDate),
        PIC, factory_id: factory, work_id: workOrder, product,
      };
      if (equipmentProcess !== undefined && equipmentProcess !== null) newEquipment.work_id = equipmentProcess;
      if (imageUrl !== undefined && imageUrl !== null) newEquipment.imageUrl = imageUrl;

      // Classification fields
      const classFields = ["equipment_type","equipmentType","device_type","type","device_type_id","equipment_category","equipmentCategory","device_category","category","category_id","production_line","productionLine","line","production_line_id","enableOEE","enableEnergy","dpmId","factory","plant","targetKwhPerTonne","warningPct","criticalPct","ratePerKwh","currency"];
      for (const f of classFields) {
        if (req.body[f] !== undefined) newEquipment[f] = req.body[f];
      }

      await col.doc(newEquipmentId).set(newEquipment);
      return {success: true, id: newEquipmentId, ...newEquipment};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({error: error.message});
  }
});

// ✅ Edit Equipment
router.put("/:id", async (req, res) => {
  const {id} = req.params;
  const {name, equipment_id, initialSerialNo, serialNo, modelType, equipmentProcess, productionArea, purchaseDate, warrantyDate, PIC, factory, workOrder, imageUrl} = req.body;

  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("equipments");
      const docRef = col.doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      if (serialNo !== initialSerialNo) {
        const serialCheck = await col.where("serialNo", "==", serialNo).get();
        if (!serialCheck.empty) return {error: "An equipment with the same serial number already exists."};
      }

      const toTimestamp = (dateStr) => new admin.firestore.Timestamp(Math.floor(new Date(dateStr).getTime() / 1000), 0);

      const updateData = {
        name, serialNo, modelType, productionArea,
        purchaseDate: toTimestamp(purchaseDate),
        warrantyDate: toTimestamp(warrantyDate),
        PIC, factory_id: factory, work_id: workOrder,
      };
      if (equipmentProcess !== undefined && equipmentProcess !== null) updateData.work_id = equipmentProcess;
      if (imageUrl !== undefined && imageUrl !== null) updateData.imageUrl = imageUrl;
      // Equipment ID is now editable — persist it when provided (non-empty).
      if (equipment_id !== undefined && equipment_id !== null && `${equipment_id}`.trim() !== "") {
        updateData.equipment_id = `${equipment_id}`.trim();
      }

      // Classification fields, plus OEE / Energy module toggles, thresholds & rate
      const classFields = ["equipment_type","equipmentType","device_type","type","device_type_id","equipment_category","equipmentCategory","device_category","category","category_id","production_line","productionLine","line","production_line_id","enableOEE","enableEnergy","dpmId","factory","plant","targetKwhPerTonne","warningPct","criticalPct","ratePerKwh","currency"];
      for (const f of classFields) {
        if (req.body[f] !== undefined) updateData[f] = req.body[f];
      }

      await docRef.update(updateData);
      return {message: "Equipment updated successfully", id, name, imageUrl: imageUrl || null};
    });

    if (result.notFound) return res.status(404).json({error: "Equipment not found"});
    if (result.error) return res.status(400).json({error: result.error});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error editing equipment:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Equipment by ID
router.delete("/:id", async (req, res) => {
  const {id} = req.params;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("equipments").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {message: "Equipment deleted successfully", id};
    });

    if (result.notFound) return res.status(404).json({error: "Equipment not found"});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting equipment:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Upsert User-Specific Equipment Image
router.put("/:id/image", async (req, res) => {
  const {id} = req.params;
  const {userId, imageUrl} = req.body;
  if (!userId || !imageUrl) return res.status(400).json({error: "userId and imageUrl are required."});

  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("equipments").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.collection("userImages").doc(userId).set({imageUrl});
      return {message: "User image updated successfully.", id, userId, imageUrl};
    });

    if (result.notFound) return res.status(404).json({error: "Equipment not found."});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating user image:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete User-Specific Equipment Image
router.delete("/:id/image/:userId", async (req, res) => {
  const {id, userId} = req.params;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("equipments").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.collection("userImages").doc(userId).delete();
      return {message: "User image removed successfully.", id, userId};
    });

    if (result.notFound) return res.status(404).json({error: "Equipment not found."});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting user image:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Fetch All Statuses
router.get("/statuses", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "equipmentStatuses", null);
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching statuses:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextEquipmentId(existingIds) {
  if (existingIds.length === 0) return "E0001";
  existingIds.sort();
  const lastId = existingIds[existingIds.length - 1];
  const numericPart = parseInt(lastId.substring(1));
  return `E${(numericPart + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
