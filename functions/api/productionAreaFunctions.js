const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Production Areas (optionally filtered by factory_id)
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {factory_id} = req.query;
    const snapshot = await queryWithFallback(clientId, "productionAreas", (col) =>
      factory_id ? col.where("factory_id", "==", factory_id) : col
    );
    res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching Production Areas:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Fetch Equipment by Production Area
router.get("/equipment/:productionAreaId", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {productionAreaId} = req.params;
    const snapshot = await queryWithFallback(clientId, "equipments", (col) =>
      productionAreaId !== "all" ? col.where("productionArea", "==", productionAreaId) : col
    );
    return res.status(200).json(snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()})));
  } catch (error) {
    console.error("Error fetching equipment:", error);
    return res.status(500).json({error: error.message});
  }
});

// ✅ Add a Production Area
router.post("/add", async (req, res) => {
  try {
    const {name, factory_id, id: customId} = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({error: "Production area name is required."});
    }

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("productionAreas");

      let dupQuery = col.where("name", "==", name.trim());
      if (factory_id) dupQuery = dupQuery.where("factory_id", "==", factory_id);
      const existingAreas = await dupQuery.get();
      if (!existingAreas.empty) return {error: "Production Area with the same name already exists."};

      let newAreaId;
      if (customId && customId.trim()) {
        const customIdTrimmed = customId.trim();
        const existingDoc = await col.doc(customIdTrimmed).get();
        if (existingDoc.exists) return {error: `Production area with ID "${customIdTrimmed}" already exists.`};
        newAreaId = customIdTrimmed;
      } else {
        let idQuery = col;
        if (factory_id) idQuery = idQuery.where("factory_id", "==", factory_id);
        const snapshot = await idQuery.get();
        newAreaId = generateNextProductionAreaId(snapshot.docs.map((d) => d.id));
      }

      const newProductionArea = {name: name.trim(), ...(factory_id ? {factory_id} : {})};
      await col.doc(newAreaId).set(newProductionArea);
      return {success: true, id: newAreaId, ...newProductionArea};
    });

    if (result.error) return res.status(400).json({error: result.error});
    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({error: error.message});
  }
});

// ✅ Update Production Area by ID
router.put("/:id", async (req, res) => {
  const areaId = req.params.id;
  try {
    const {name, factory_id, id: newId} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("productionAreas");
      const docRef = col.doc(areaId);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      const currentData = doc.data();

      if (name && name.trim()) {
        const effectiveFactoryId = factory_id !== undefined ? factory_id : currentData.factory_id;
        let nameQuery = col.where("name", "==", name.trim());
        if (effectiveFactoryId) nameQuery = nameQuery.where("factory_id", "==", effectiveFactoryId);
        const nameConflict = await nameQuery.get();
        const conflict = nameConflict.docs.find((d) => d.id !== areaId);
        if (conflict) return {error: "Production Area with the same name already exists."};
      }

      const updateData = {};
      if (name && name.trim()) updateData.name = name.trim();
      if (factory_id !== undefined) updateData.factory_id = factory_id;

      const newIdTrimmed = newId ? newId.trim() : "";
      if (newIdTrimmed && newIdTrimmed !== areaId) {
        const newDocRef = col.doc(newIdTrimmed);
        if ((await newDocRef.get()).exists) return {error: `Production area with ID "${newIdTrimmed}" already exists.`};

        const mergedData = {...currentData, ...updateData};
        const batch = cdb.batch();
        batch.set(newDocRef, mergedData);
        batch.delete(docRef);

        const equipmentSnapshot = await cdb.collection("equipments").where("productionArea", "==", areaId).get();
        for (const equipDoc of equipmentSnapshot.docs) {
          batch.update(equipDoc.ref, {productionArea: newIdTrimmed});
        }
        await batch.commit();
        return {success: true, id: newIdTrimmed, ...mergedData};
      }

      await docRef.update(updateData);
      return {success: true, id: areaId, ...currentData, ...updateData};
    });

    if (result.notFound) return res.status(404).json({error: "Production area not found."});
    if (result.error) return res.status(400).json({error: result.error});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating production area:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Production Area by Name
router.delete("/:name", async (req, res) => {
  const productionAreaName = req.params.name;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("productionAreas");
      const snapshot = await col.where("name", "==", productionAreaName).get();
      if (snapshot.empty) return {notFound: true};

      const deletedIds = [];
      for (const doc of snapshot.docs) {
        const productionAreaId = doc.id;
        await doc.ref.delete();
        deletedIds.push(productionAreaId);

        const equipmentSnapshot = await cdb.collection("equipments").where("productionArea", "==", productionAreaId).get();
        for (const equipmentDoc of equipmentSnapshot.docs) {
          await equipmentDoc.ref.update({productionArea: "0"});
        }
      }
      return {message: "Production area(s) deleted successfully", deletedIds};
    });

    if (result.notFound) return res.status(404).json({error: `No production area found with the name "${productionAreaName}".`});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting production area:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Fetch All Production Areas, Equipments, Work Orders
router.get("/equipments/workOrders", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {factory_id} = req.query;

    const [areaSnap, equipSnap, woSnap] = await Promise.all([
      queryWithFallback(clientId, "productionAreas", (col) =>
        factory_id ? col.where("factory_id", "==", factory_id) : col
      ),
      queryWithFallback(clientId, "equipments", (col) =>
        factory_id ? col.where("factory_id", "==", factory_id) : col
      ),
      queryWithFallback(clientId, "workOrders", null),
    ]);

    const productionAreas = areaSnap.docs.map((doc) => ({id: doc.id, name: doc.data()["name"]}));
    const equipments = equipSnap.docs.map((doc) => ({
      id: doc.id, name: doc.data()["name"],
      productionArea: doc.data()["productionArea"],
      work_id: doc.data()["work_id"],
    }));
    const workOrderMap = {};
    woSnap.docs.forEach((doc) => { workOrderMap[doc.id] = {id: doc.id, ...doc.data()}; });

    const equipmentWithWorkOrders = equipments.map((eq) => ({
      ...eq,
      workOrders: (eq.work_id || []).map((id) => workOrderMap[id]).filter(Boolean),
    }));

    const result = productionAreas.map((area) => ({
      ...area,
      equipments: equipmentWithWorkOrders.filter((eq) => eq.productionArea === area.id),
    }));

    res.status(200).json(result);
  } catch (error) {
    console.error("Error fetching Production Areas, Equipments, Work Orders:", error);
    res.status(500).json({error: error.message});
  }
});

function generateNextProductionAreaId(existingIds) {
  const pattern = /^P(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `P${(maxNum + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
