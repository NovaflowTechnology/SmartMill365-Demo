const express = require("express");
const admin = require("firebase-admin");
const {getClientFirestore, isStrictDb} = require("../helpers/dbConnections");
// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "carbonDashboardConfigs";

// Fields persisted for the Carbon Intelligence Dashboard "Configure Dashboard"
// card → Device ID mapping. Mirrors CarbonDashboardConfig.toJson() in
// lib/web_app_template/carbon_emission/carbon_dashboard_config.dart.
const STRING_FIELDS = [
  "netEmissionDeviceId",
  "carbonIntensityDeviceId",
  "totalConsumptionDeviceId",
  "solarDeviceId",
  "blockADeviceId",
  "blockBDeviceId",
  "blockCDeviceId",
];
const LIST_FIELDS = ["topContributorDeviceIds", "productionLineEquipmentIds"];

function defaultConfig() {
  const config = {carbonPricePerTco2e: null};
  for (const key of STRING_FIELDS) config[key] = null;
  for (const key of LIST_FIELDS) config[key] = [];
  return config;
}

// Each plant/facility gets its own saved config (`FacilityData.plant` is
// free text, so it's normalized into a safe Firestore doc id here — `/` and
// `.` are the only characters that need escaping for a doc id).
function plantDocId(plant) {
  const trimmed = (plant || "").trim();
  if (!trimmed) return null;
  return trimmed.replace(/[/.]/g, "_").slice(0, 300);
}

// ── Multi-tenant resolver ───────────────────────────────────────────────────
// Resolve a doc ref under `carbonDashboardConfigs`, preferring the client's
// own Firestore (selected per x-client-id via integration_config) but
// keeping the user's data wherever it already lives so nothing is hidden
// mid-migration:
//   1. client db already has the doc → use client db
//   2. else default db has it        → use default db
//   3. else (brand-new doc)          → use client db
// Clients without a dedicated Firestore resolve to default = old behaviour.
async function resolveDocRef(req, ref) {
  const clientId = req.headers["x-client-id"] || null;
  const clientDb = await getClientFirestore(clientId);
  const defaultDb = admin.firestore();

  const clientRef = ref(clientDb);
  // A strict client reads and writes its own db only, never the default.
  if (clientDb === defaultDb || isStrictDb(clientDb)) {
    const snap = await clientRef.get();
    return {ref: clientRef, snap};
  }

  const clientSnap = await clientRef.get();
  if (clientSnap.exists) return {ref: clientRef, snap: clientSnap};

  const defaultRef = ref(defaultDb);
  const defaultSnap = await defaultRef.get();
  if (defaultSnap.exists) return {ref: defaultRef, snap: defaultSnap};

  return {ref: clientRef, snap: clientSnap};
}

// Legacy single doc per uid, from before per-plant configs. Still read
// (never written) as the fallback default for any plant that hasn't been
// saved individually yet.
function resolveLegacyConfigRef(req, uid) {
  return resolveDocRef(req, (db) => db.collection(COLLECTION).doc(uid));
}

// Per-plant config, nested under the same uid doc so a listing query could
// later enumerate every plant a tenant has configured.
function resolvePlantConfigRef(req, uid, plantId) {
  return resolveDocRef(req, (db) => db.collection(COLLECTION).doc(uid).collection("plants").doc(plantId));
}

function sanitizeConfig(body) {
  const clean = {};
  for (const key of STRING_FIELDS) {
    const value = body[key];
    clean[key] = typeof value === "string" && value.trim() !== "" ? value.trim() : null;
  }
  for (const key of LIST_FIELDS) {
    const value = body[key];
    clean[key] = Array.isArray(value) ?
      value.filter((v) => typeof v === "string" && v.trim() !== "") :
      [];
  }
  const price = body.carbonPricePerTco2e;
  clean.carbonPricePerTco2e = typeof price === "number" && !Number.isNaN(price) ? price : null;
  return clean;
}

/**
 * GET /api/carbon-dashboard-config/:uid?plant=Plant+A
 *
 * `plant` is required for the current (per-plant) client. If the plant has
 * no config of its own yet, the legacy pre-per-plant doc (if any) is served
 * as its starting default — `inherited: true` tells the caller it hasn't
 * been saved for this specific plant yet.
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const plantId = plantDocId(req.query.plant);
    if (!plantId) return res.status(400).json({error: "plant is required"});

    const {snap: plantDoc} = await resolvePlantConfigRef(req, uid, plantId);
    if (plantDoc.exists) {
      return res.status(200).json({exists: true, inherited: false, ...defaultConfig(), ...sanitizeConfig(plantDoc.data())});
    }

    const {snap: legacyDoc} = await resolveLegacyConfigRef(req, uid);
    if (legacyDoc.exists) {
      return res.status(200).json({exists: true, inherited: true, ...defaultConfig(), ...sanitizeConfig(legacyDoc.data())});
    }

    return res.status(200).json({exists: false, inherited: false, ...defaultConfig()});
  } catch (error) {
    console.error("Error fetching carbon dashboard config:", error);
    return res.status(500).json({error: "Failed to fetch carbon dashboard config"});
  }
});

/**
 * POST /api/carbon-dashboard-config/:uid?plant=Plant+A
 *
 * Always writes to the plant-scoped doc; the legacy global doc is never
 * written again, only read as a fallback default (see GET above).
 */
router.post("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const plantId = plantDocId(req.query.plant);
    if (!plantId) return res.status(400).json({error: "plant is required"});

    const {ref: configRef, snap: existing} = await resolvePlantConfigRef(req, uid, plantId);
    const clean = sanitizeConfig(req.body || {});

    const dataToSave = {
      uid,
      plant: String(req.query.plant).trim(),
      ...clean,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      ...(!existing.exists && {created_at: admin.firestore.FieldValue.serverTimestamp()}),
    };

    await configRef.set(dataToSave, {merge: true});

    return res.status(200).json({success: true, message: "Carbon dashboard config saved successfully"});
  } catch (error) {
    console.error("Error saving carbon dashboard config:", error);
    return res.status(500).json({error: "Failed to save carbon dashboard config"});
  }
});

module.exports = router;
