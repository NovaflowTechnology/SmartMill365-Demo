const express = require("express");
const {queryWithFallback, withDbFallback, getClientFirestore} = require("../helpers/dbConnections");
const {autoProvisionPecc, findParentByBlockName} = require("../helpers/peccAutoConfig");

// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "tnb_meters";

// A meter is how autoProvisionPecc finds a device for a plant's cards, so
// saving one is when real numbers actually become available — refresh that
// plant's PECC doc, and its parent's too when this plant is itself a
// "<parent> Block A/B/C" (its flow diagram reads the block's own meter).
// Best-effort: a failure here must never fail the meter save itself.
async function refreshPeccForPlant(clientId, factoryId) {
  if (!factoryId) return;
  try {
    const clientDb = await getClientFirestore(clientId || null);
    const factoryDoc = await clientDb.collection("factories").doc(factoryId).get();
    if (!factoryDoc.exists) return;
    const factoryName = (factoryDoc.data().name || "").toString().trim();
    if (!factoryName) return;

    await autoProvisionPecc({clientId, factoryId, factoryName});

    const parent = await findParentByBlockName(clientDb, factoryName);
    if (parent) {
      await autoProvisionPecc({clientId, factoryId: parent.id, factoryName: (parent.name || "").toString().trim()});
    }
  } catch (err) {
    console.warn("[tnbMeters] auto-provision PECC refresh failed:", err.message);
  }
}

// GET /tnbMeters — list all meters for this client (shared across every
// user of the client — not filtered by userId; optionally filtered by
// plantId)
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const {plantId} = req.query;

    const snapshot = await queryWithFallback(clientId, COLLECTION, (col) => {
      let q = col;
      if (plantId) q = q.where("plantId", "==", plantId);
      return q;
    });

    const meters = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.status(200).json(meters);
  } catch (error) {
    console.error("Error fetching TNB meters:", error);
    res.status(500).json({error: error.message});
  }
});

// GET /tnbMeters/:id — fetch single meter
router.get("/:id", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, COLLECTION, null);
    const doc = snapshot.docs.find((d) => d.id === req.params.id);
    if (!doc) return res.status(404).json({error: "Meter not found"});
    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching TNB meter:", error);
    res.status(500).json({error: error.message});
  }
});

// POST /tnbMeters — create a new meter
router.post("/", async (req, res) => {
  try {
    const {
      plantId, meterCode, meterLabel, tnbAccountNo, influxDbTag, solarDeviceId,
      tariffCategoryId, tariffType, contractMdKw, effectiveFrom,
      effectiveTo, boundAreaIds, isActive, userId, dashboardConfig,
    } = req.body;

    if (!meterCode || !meterCode.trim()) {
      return res.status(400).json({error: "Meter code is required."});
    }
    if (!plantId || !plantId.trim()) {
      return res.status(400).json({error: "Plant is required."});
    }

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection(COLLECTION);

      // Meter codes must be unique client-wide — meters are shared across
      // every user of this client, not scoped per-login.
      const existing = await col.where("meterCode", "==", meterCode.trim()).get();
      if (!existing.empty) return {conflict: "A meter with this code already exists."};

      const data = {
        plantId: plantId.trim(),
        meterCode: meterCode.trim(),
        meterLabel: (meterLabel || "").trim(),
        tnbAccountNo: (tnbAccountNo || "").trim(),
        influxDbTag: (influxDbTag || "").trim(),
        solarDeviceId: (solarDeviceId || "").trim(),
        tariffCategoryId: (tariffCategoryId || "").trim(),
        tariffType: (tariffType || "").trim(),
        contractMdKw: Number(contractMdKw) || 0,
        effectiveFrom: effectiveFrom || new Date().toISOString(),
        ...(effectiveTo ? {effectiveTo} : {}),
        boundAreaIds: boundAreaIds || [],
        isActive: isActive !== false,
        ...(dashboardConfig ? {dashboardConfig} : {}),
        ...(userId ? {userId} : {}),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      const docRef = await col.add(data);
      return {id: docRef.id, ...data};
    });

    if (result.conflict) return res.status(400).json({error: result.conflict});

    await refreshPeccForPlant(req.headers["x-client-id"] || null, result.plantId);

    res.status(201).json(result);
  } catch (error) {
    console.error("Error creating TNB meter:", error);
    res.status(500).json({error: error.message});
  }
});

// PUT /tnbMeters/:id — update a meter
router.put("/:id", async (req, res) => {
  try {
    const meterId = req.params.id;
    const {
      plantId, meterCode, meterLabel, tnbAccountNo, influxDbTag, solarDeviceId,
      tariffCategoryId, tariffType, contractMdKw, effectiveFrom,
      effectiveTo, boundAreaIds, isActive, userId, dashboardConfig,
    } = req.body;

    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection(COLLECTION);
      const docRef = col.doc(meterId);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      if (meterCode && meterCode.trim()) {
        const nameCheck = await col.where("meterCode", "==", meterCode.trim()).get();
        const dup = nameCheck.docs.find((d) => d.id !== meterId);
        if (dup) return {conflict: "A meter with this code already exists."};
      }

      const updateData = {
        ...(plantId !== undefined ? {plantId: plantId.trim()} : {}),
        ...(meterCode ? {meterCode: meterCode.trim()} : {}),
        ...(meterLabel !== undefined ? {meterLabel: (meterLabel || "").trim()} : {}),
        ...(tnbAccountNo !== undefined ? {tnbAccountNo: (tnbAccountNo || "").trim()} : {}),
        ...(influxDbTag !== undefined ? {influxDbTag: (influxDbTag || "").trim()} : {}),
        ...(solarDeviceId !== undefined ? {solarDeviceId: (solarDeviceId || "").trim()} : {}),
        ...(tariffCategoryId !== undefined ? {tariffCategoryId: (tariffCategoryId || "").trim()} : {}),
        ...(tariffType !== undefined ? {tariffType: (tariffType || "").trim()} : {}),
        ...(contractMdKw !== undefined ? {contractMdKw: Number(contractMdKw) || 0} : {}),
        ...(effectiveFrom !== undefined ? {effectiveFrom} : {}),
        ...(effectiveTo !== undefined ? {effectiveTo: effectiveTo || null} : {}),
        ...(boundAreaIds !== undefined ? {boundAreaIds} : {}),
        ...(isActive !== undefined ? {isActive} : {}),
        ...(dashboardConfig !== undefined ? {dashboardConfig} : {}),
        ...(userId ? {userId} : {}),
        updatedAt: new Date().toISOString(),
      };

      await docRef.update(updateData);
      return {id: meterId, ...doc.data(), ...updateData};
    });

    if (result.notFound) return res.status(404).json({error: "Meter not found."});
    if (result.conflict) return res.status(400).json({error: result.conflict});

    await refreshPeccForPlant(req.headers["x-client-id"] || null, result.plantId);

    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating TNB meter:", error);
    res.status(500).json({error: error.message});
  }
});

// DELETE /tnbMeters/:id — delete a meter
router.delete("/:id", async (req, res) => {
  try {
    const meterId = req.params.id;

    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection(COLLECTION).doc(meterId);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {deleted: true};
    });

    if (result.notFound) return res.status(404).json({error: "Meter not found."});
    res.status(200).json({message: "Meter deleted successfully."});
  } catch (error) {
    console.error("Error deleting TNB meter:", error);
    res.status(500).json({error: error.message});
  }
});

module.exports = router;
