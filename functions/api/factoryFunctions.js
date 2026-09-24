const express = require("express");
const admin = require("firebase-admin");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");
const { autoProvisionPecc } = require("../helpers/peccAutoConfig");

// eslint-disable-next-line new-cap
const router = express.Router();

// ✅ Fetch All Factories
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "factories", null);
    const factorys = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    res.status(200).json(factorys);
  } catch (error) {
    console.error("Error fetching factories:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add a Factory
router.post("/add", async (req, res) => {
  try {
    const {name, id: customId, customer_id, discovery_plant_id} = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({error: "Plant name is required."});
    }

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("factories");

      const existingFactories = await col.where("name", "==", name.trim()).get();
      if (!existingFactories.empty) return {conflict: "Factory with the same name already exists."};

      let newFactoryId;
      if (customId && customId.trim()) {
        const customIdTrimmed = customId.trim();
        const existingDoc = await col.doc(customIdTrimmed).get();
        if (existingDoc.exists) return {conflict: `Factory with ID "${customIdTrimmed}" already exists.`};
        newFactoryId = customIdTrimmed;
      } else {
        const snapshot = await col.get();
        newFactoryId = generateNextFactoryId(snapshot.docs.map((d) => d.id));
      }

      const newFactory = {
        name: name.trim(),
        ...(customer_id ? {customer_id} : {}),
        ...(discovery_plant_id ? {discovery_plant_id} : {}),
      };
      await col.doc(newFactoryId).set(newFactory);
      return {id: newFactoryId, ...newFactory};
    });

    if (result.conflict) return res.status(400).json({error: result.conflict});

    // Best-effort — a new plant's own Energy Command Center (settings +
    // dashboard) should exist right away instead of starting blank, but
    // this must never block the plant itself from being created.
    try {
      await autoProvisionPecc({
        clientId: req.headers["x-client-id"] || null,
        factoryId: result.id,
        factoryName: result.name,
      });
    } catch (peccErr) {
      console.warn("[factory/add] auto-provision PECC failed:", peccErr.message);
    }

    res.status(201).json({success: true, ...result});
  } catch (error) {
    res.status(500).json({error: error.message});
  }
});

// ✅ Update Factory by ID
router.put("/:id", async (req, res) => {
  const factoryId = req.params.id;
  try {
    const {name, customer_id, discovery_plant_id, id: newId} = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("factories");
      const docRef = col.doc(factoryId);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      if (name && name.trim()) {
        const nameConflict = await col.where("name", "==", name.trim()).get();
        if (nameConflict.docs.find((d) => d.id !== factoryId)) return {conflict: "Factory with the same name already exists."};
      }

      const updateData = {};
      if (name && name.trim()) updateData.name = name.trim();
      if (customer_id !== undefined) updateData.customer_id = customer_id;
      if (discovery_plant_id !== undefined) updateData.discovery_plant_id = discovery_plant_id;

      const newIdTrimmed = newId ? newId.trim() : "";
      if (newIdTrimmed && newIdTrimmed !== factoryId) {
        const newDoc = await col.doc(newIdTrimmed).get();
        if (newDoc.exists) return {conflict: `Factory with ID "${newIdTrimmed}" already exists.`};
        const mergedData = {...doc.data(), ...updateData};
        const batch = cdb.batch();
        batch.set(col.doc(newIdTrimmed), mergedData);
        batch.delete(docRef);
        const equipSnap = await cdb.collection("equipments").where("factory_id", "==", factoryId).get();
        for (const equipDoc of equipSnap.docs) batch.update(equipDoc.ref, {factory_id: newIdTrimmed});
        await batch.commit();
        return {id: newIdTrimmed, ...mergedData};
      }

      await docRef.update(updateData);
      return {id: factoryId, ...doc.data(), ...updateData};
    });

    if (result.notFound) return res.status(404).json({error: "Factory not found."});
    if (result.conflict) return res.status(400).json({error: result.conflict});
    res.status(200).json({success: true, ...result});
  } catch (error) {
    console.error("Error updating factory:", error);
    res.status(500).json({error: error.message});
  }
});

/**
 * Generates the next factory ID based on existing IDs.
 *
 * @param {string[]} existingIds - An array of existing factory IDs.
 * @return {string} The newly generated factory ID.
 */
function generateNextFactoryId(existingIds) {
  const pattern = /^F(\d+)$/i;
  let maxNum = 0;
  for (const id of existingIds) {
    const match = id.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) maxNum = num;
    }
  }
  return `F${(maxNum + 1).toString().padStart(4, "0")}`;
}

// ✅ Fetch Single Factory by ID
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const clientDb = await getClientFirestore(clientId).catch(() => db);
    let doc = await clientDb.collection("factories").doc(req.params.id).get();
    // Fallback to default if not found in client Firestore
    if (!doc.exists && clientDb !== db) {
      doc = await factoryCollection.doc(req.params.id).get();
    }
    if (!doc.exists) {
      return res.status(404).json({error: "Factory not found"});
    }
    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching factory:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Delete Factory by Name
router.delete("/:name", async (req, res) => {
  const factoryName = req.params.name;

  try {
    const deletedIds = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("factories");
      const factorySnapshot = await col.where("name", "==", factoryName).get();
      if (factorySnapshot.empty) return {notFound: true};

      const ids = [];
      for (const doc of factorySnapshot.docs) {
        await doc.ref.delete();
        const equipSnap = await cdb.collection("equipments").where("factory_id", "==", doc.id).get();
        for (const equipDoc of equipSnap.docs) await equipDoc.ref.update({factory_id: "0"});
        ids.push(doc.id);
      }
      return ids;
    });

    if (deletedIds && deletedIds.notFound) return res.status(404).json({error: `No factory found with the name "${factoryName}".`});
    res.status(200).json({message: "Factory deleted successfully", deletedIds});
  } catch (error) {
    console.error("Error deleting factory:", error);
    res.status(500).json({error: error.message});
  }
});

module.exports = router;
