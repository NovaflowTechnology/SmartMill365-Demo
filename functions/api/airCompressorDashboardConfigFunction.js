const express = require("express");
const admin = require("firebase-admin");
const {getClientFirestore, isStrictDb} = require("../helpers/dbConnections");
// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "airCompressorDashboardConfigs";

// Fields persisted for the Air Compressor Monitoring dashboard "Configure
// Dashboard" card → Device ID mapping. Mirrors
// AirCompressorDashboardConfig.toJson() in
// lib/web_app_template/air_compressor_monitoring/air_compressor_dashboard_config.dart.
const STRING_FIELDS = [
  "totalPowerField",
  "headerFlowDeviceId",
  "headerFlowField",
  "headerPressureDeviceId",
  "headerPressureField",
  "ac1DeviceId",
  "ac1Field",
  "ac2DeviceId",
  "ac2Field",
  "nightWindowStart",
  "nightWindowEnd",
  "nextMaintenanceLabel",
  "availabilityDeviceId",
  "downtimeDeviceId",
  "dewPointDeviceId",
  "ac1RoleOverride",
  "ac2RoleOverride",
];
const LIST_FIELDS = ["totalPowerDeviceIds"];
const NUMBER_FIELDS = ["seBandLow", "seBandHigh", "minFlowThreshold"];
const BOOLEAN_FIELDS = {roleAssignmentAuto: true};
// Demand Side load rows — one per CAST/consumer, each a manual
// pressure/flow requirement plus an optional live-flow Device ID + field.
const DEMAND_LOAD_STRING_FIELDS = ["label", "deviceId", "field"];
const DEMAND_LOAD_NUMBER_FIELDS = ["reqPressure", "reqFlow"];

function sanitizeDemandLoad(item) {
  if (!item || typeof item !== "object") return null;
  const clean = {};
  for (const key of DEMAND_LOAD_STRING_FIELDS) {
    const value = item[key];
    clean[key] = typeof value === "string" && value.trim() !== "" ? value.trim() : (key === "label" ? "" : null);
  }
  for (const key of DEMAND_LOAD_NUMBER_FIELDS) {
    const value = item[key];
    clean[key] = typeof value === "number" && !Number.isNaN(value) ? value : null;
  }
  return clean;
}

function defaultConfig() {
  const config = {};
  for (const key of STRING_FIELDS) config[key] = null;
  for (const key of LIST_FIELDS) config[key] = [];
  for (const key of NUMBER_FIELDS) config[key] = null;
  for (const key of Object.keys(BOOLEAN_FIELDS)) config[key] = BOOLEAN_FIELDS[key];
  config.demandLoads = [];
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
// Resolve a doc ref under `airCompressorDashboardConfigs`, preferring the
// client's own Firestore (selected per x-client-id via integration_config)
// but keeping the user's data wherever it already lives so nothing is
// hidden mid-migration:
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
  for (const key of NUMBER_FIELDS) {
    const value = body[key];
    clean[key] = typeof value === "number" && !Number.isNaN(value) ? value : null;
  }
  for (const key of Object.keys(BOOLEAN_FIELDS)) {
    const value = body[key];
    clean[key] = typeof value === "boolean" ? value : BOOLEAN_FIELDS[key];
  }
  clean.demandLoads = Array.isArray(body.demandLoads) ?
    body.demandLoads.map(sanitizeDemandLoad).filter((d) => d && d.label !== "") :
    [];
  return clean;
}

/**
 * GET /api/air-compressor-dashboard-config/:uid?plant=Lot+237
 *
 * `plant` is required. If the plant has no saved config yet, all fields
 * come back null/empty and the client falls back to its own defaults.
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const plantId = plantDocId(req.query.plant);
    if (!plantId) return res.status(400).json({error: "plant is required"});

    const {snap: plantDoc} = await resolvePlantConfigRef(req, uid, plantId);
    if (plantDoc.exists) {
      return res.status(200).json({exists: true, ...defaultConfig(), ...sanitizeConfig(plantDoc.data())});
    }

    return res.status(200).json({exists: false, ...defaultConfig()});
  } catch (error) {
    console.error("Error fetching air compressor dashboard config:", error);
    return res.status(500).json({error: "Failed to fetch air compressor dashboard config"});
  }
});

/**
 * POST /api/air-compressor-dashboard-config/:uid?plant=Lot+237
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

    return res.status(200).json({success: true, message: "Air compressor dashboard config saved successfully"});
  } catch (error) {
    console.error("Error saving air compressor dashboard config:", error);
    return res.status(500).json({error: "Failed to save air compressor dashboard config"});
  }
});

module.exports = router;
