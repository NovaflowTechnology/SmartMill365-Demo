const express = require("express");
const admin = require("firebase-admin");
const { getClientFirestore } = require("../helpers/dbConnections");
// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();

// ── Legacy: per-user collection (backward compat) ─────────────────────────────
const getUserCollection = (uid) =>
  db.collection("master_facilities").doc(uid).collection("facilities");

// ── GET /facilities — list all for active client ──────────────────────────────
router.get("/", async (req, res) => {
  try {
    const clientId = req.clientId || req.headers["x-client-id"] || null;
    const cdb = await getClientFirestore(clientId);
    const snapshot = await cdb.collection("master_facilities").get();
    const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return res.status(200).json(data);
  } catch (err) {
    console.error("Error fetching facilities:", err);
    return res.status(500).json({ error: err.message });
  }
});

// ── POST /facilities — create new facility for active client ──────────────────
router.post("/", async (req, res) => {
  try {
    const clientId = req.clientId || req.headers["x-client-id"] || null;
    const cdb = await getClientFirestore(clientId);
    const body = req.body;
    const docId = body.id || Date.now().toString();
    const payload = buildPayload(body);
    payload.id        = docId;
    payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
    payload.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await cdb.collection("master_facilities").doc(docId).set(payload);
    return res.status(201).json({ id: docId, message: "Facility created successfully" });
  } catch (err) {
    console.error("Error creating facility:", err);
    return res.status(500).json({ error: err.message });
  }
});

// ── PATCH /facilities/:id — partial update for active client ──────────────────
router.patch("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) return res.status(400).json({ error: "Facility ID is required" });
    const clientId = req.clientId || req.headers["x-client-id"] || null;
    const cdb = await getClientFirestore(clientId);
    await cdb.collection("master_facilities").doc(id).set(
      { ...req.body, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    return res.status(200).json({ id, message: "Facility patched successfully" });
  } catch (err) {
    console.error("Error patching facility:", err);
    return res.status(500).json({ error: err.message });
  }
});

// ── DELETE /facilities/:id — delete for active client ────────────────────────
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) return res.status(400).json({ error: "Facility ID is required" });
    const clientId = req.clientId || req.headers["x-client-id"] || null;
    const cdb = await getClientFirestore(clientId);
    await cdb.collection("master_facilities").doc(id).delete();
    return res.status(200).json({ id, message: "Facility deleted successfully" });
  } catch (err) {
    console.error("Error deleting facility:", err);
    return res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/facilities/:uid
 * Retrieve all facilities for a specific user
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;

    if (!uid) {
      return res.status(400).json({error: "User ID is required"});
    }

    const snapshot = await getUserCollection(uid).get();
    const data = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    return res.status(200).json(data);
  } catch (error) {
    console.error("Error fetching facilities:", error);
    return res.status(500).json({error: "Failed to fetch facilities"});
  }
});

/**
 * GET /api/facilities/:uid/:id
 * Retrieve a single facility by ID for a specific user
 */
router.get("/:uid/:id", async (req, res) => {
  try {
    const {uid, id} = req.params;

    if (!uid) return res.status(400).json({error: "User ID is required"});
    if (!id)  return res.status(400).json({error: "Facility ID is required"});

    const doc = await getUserCollection(uid).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({error: "Facility not found"});
    }

    return res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    console.error("Error fetching facility:", error);
    return res.status(500).json({error: "Failed to fetch facility"});
  }
});

/**
 * POST /api/facilities/:uid
 * Create a new facility for a specific user
 * id dikirim dari Flutter (millisecondsSinceEpoch) sebagai doc ID
 */
router.post("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    const body = req.body;

    if (!uid) {
      return res.status(400).json({error: "User ID is required"});
    }

    const validationError = validateFacility(body);
    if (validationError) {
      return res.status(400).json({error: validationError});
    }

    // ✅ id dari Flutter millisecondsSinceEpoch
    const docId = body.id || Date.now().toString();

    const payload = buildPayload(body);
    payload.id        = docId;
    payload.uid       = uid; // ✅ simpan uid di dokumen
    payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
    payload.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await getUserCollection(uid).doc(docId).set(payload);
    return res.status(201).json({
      id: docId,
      message: "Facility created successfully",
    });
  } catch (error) {
    console.error("Error creating facility:", error);
    return res.status(500).json({error: "Failed to create facility"});
  }
});

/**
 * POST /api/facilities/:uid/:id
 * Update (full replace) a facility by ID for a specific user
 */
router.post("/:uid/:id", async (req, res) => {
  try {
    const {uid, id} = req.params;
    const body = req.body;

    if (!uid) return res.status(400).json({error: "User ID is required"});
    if (!id)  return res.status(400).json({error: "Facility ID is required"});

    const docRef = getUserCollection(uid).doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({error: "Facility not found"});
    }

    const validationError = validateFacility(body);
    if (validationError) {
      return res.status(400).json({error: validationError});
    }

    const payload = buildPayload(body);
    payload.id        = id;
    payload.uid       = uid;
    payload.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    payload.createdAt = doc.data().createdAt; // ✅ pertahankan createdAt

    await docRef.set(payload, {merge: false});
    return res.status(200).json({
      id,
      message: "Facility updated successfully",
    });
  } catch (error) {
    console.error("Error updating facility:", error);
    return res.status(500).json({error: "Failed to update facility"});
  }
});

/**
 * PATCH /api/facilities/:uid/:id
 * Partially update a facility by ID for a specific user
 */
router.patch("/:uid/:id", async (req, res) => {
  try {
    const {uid, id} = req.params;

    if (!uid) return res.status(400).json({error: "User ID is required"});
    if (!id)  return res.status(400).json({error: "Facility ID is required"});

    const docRef = getUserCollection(uid).doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({error: "Facility not found"});
    }

    await docRef.set({
      ...req.body,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return res.status(200).json({
      id,
      message: "Facility patched successfully",
    });
  } catch (error) {
    console.error("Error patching facility:", error);
    return res.status(500).json({error: "Failed to patch facility"});
  }
});

/**
 * DELETE /api/facilities/:uid/:id
 * Delete a facility by ID for a specific user
 */
router.delete("/:uid/:id", async (req, res) => {
  try {
    const {uid, id} = req.params;

    if (!uid) return res.status(400).json({error: "User ID is required"});
    if (!id)  return res.status(400).json({error: "Facility ID is required"});

    const docRef = getUserCollection(uid).doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({error: "Facility not found"});
    }

    await docRef.delete();
    return res.status(200).json({
      id,
      message: "Facility deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting facility:", error);
    return res.status(500).json({error: "Failed to delete facility"});
  }
});

/**
 * Validate required facility fields
 */
function validateFacility(data) {
  const required = [
    "plant",
    "factory",
    "zone",
    "productionArea",
    "equipmentType",
    "equipmentNameId",
  ];

  const missing = required.filter((f) => !data[f] || data[f].toString().trim() === "");
  if (missing.length > 0) {
    return `Missing required fields: ${missing.join(", ")}`;
  }

  if (data.status && !["Active", "Inactive"].includes(data.status)) {
    return "Status must be either 'Active' or 'Inactive'";
  }

  return null;
}

/**
 * Build clean Firestore payload from request body
 */
function buildPayload(body) {
  return {
    plant:               body.plant               || "",
    factory:             body.factory             || "",
    zone:                body.zone                || "",
    productionArea:      body.productionArea      || "",
    equipmentType:       body.equipmentType       || "",
    equipmentNameId:     body.equipmentNameId     || "",
    meterName:           body.meterName           || "",
    meterId:             body.meterId             || "",
    gatewayId:           body.gatewayId           || "",
    status:              body.status              || "Active",
    gridType:            body.gridType            || "",
    maintenanceDate:     body.maintenanceDate     || "",
    lastMaintenanceDate: body.lastMaintenanceDate || "",
    nextMaintenanceDate: body.nextMaintenanceDate || "",
    registrationDate:    body.registrationDate    || "",
    registrationTime:    body.registrationTime    || "",
    impactCategory:      body.impactCategory      || "PRODUCTION",
    // MySQL enrichment fields
    siteId:              body.siteId              || "",
    machineId:           body.machineId           || "",
    machineName:         body.machineName         || "",
    lineId:              body.lineId              || "",
    lineName:            body.lineName            || "",
    zoneId:              body.zoneId              || "",
    zoneName:            body.zoneName            || "",
    parentId:            body.parentId            || "",
    parentName:          body.parentName          || "",
    // Analytics inclusion flags — default PF/Carbon on, MD ranking opt-in.
    includePfAnalytics:  body.includePfAnalytics  !== false,
    includeMdRanking:    body.includeMdRanking    === true,
    includeCarbonCalc:   body.includeCarbonCalc   !== false,
  };
}

module.exports = router;