const express = require("express");
const admin = require("firebase-admin");
const {getClientFirestore, isStrictDb} = require("../helpers/dbConnections");
// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "maxDemandChartConfigs";

// Per-tenant Max Demand Monitoring chart selection — which Master-Facilities
// device ids each equipment-level chart should skip. Mirrors
// MaxDemandChartConfig.toJson() in
// lib/web_app_template/max_demand_monitoring/max_demand_chart_config.dart.
const LIST_FIELDS = ["excludedCorrelationDeviceIds", "excludedMdRankingDeviceIds"];

function defaultConfig() {
  const config = {};
  for (const key of LIST_FIELDS) config[key] = [];
  return config;
}

// ── Multi-tenant resolver ───────────────────────────────────────────────────
// Same resolution order as mdInsightReportConfigFunction.js / carbonDashboardConfigFunction.js:
// prefer the client's own Firestore (via x-client-id), but keep data wherever
// it already lives so nothing is hidden mid-migration.
async function resolveConfigRef(req, uid) {
  const clientId = req.headers["x-client-id"] || null;
  const clientDb = await getClientFirestore(clientId);
  const defaultDb = admin.firestore();

  const clientRef = clientDb.collection(COLLECTION).doc(uid);
  // A strict client reads and writes its own db only, never the default.
  if (clientDb === defaultDb || isStrictDb(clientDb)) {
    const snap = await clientRef.get();
    return {ref: clientRef, snap};
  }

  const clientSnap = await clientRef.get();
  if (clientSnap.exists) return {ref: clientRef, snap: clientSnap};

  const defaultRef = defaultDb.collection(COLLECTION).doc(uid);
  const defaultSnap = await defaultRef.get();
  if (defaultSnap.exists) return {ref: defaultRef, snap: defaultSnap};

  return {ref: clientRef, snap: clientSnap};
}

function sanitizeConfig(body) {
  const clean = {};
  for (const key of LIST_FIELDS) {
    const value = body[key];
    clean[key] = Array.isArray(value) ?
      value.map((v) => String(v || "").trim()).filter(Boolean) :
      [];
  }
  return clean;
}

/**
 * GET /api/max-demand-chart-config/:uid
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const {snap: doc} = await resolveConfigRef(req, uid);
    if (!doc.exists) {
      return res.status(200).json({exists: false, ...defaultConfig()});
    }

    return res.status(200).json({exists: true, ...defaultConfig(), ...sanitizeConfig(doc.data())});
  } catch (error) {
    console.error("Error fetching Max Demand chart config:", error);
    return res.status(500).json({error: "Failed to fetch Max Demand chart config"});
  }
});

/**
 * POST /api/max-demand-chart-config/:uid
 */
router.post("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const {ref: configRef, snap: existing} = await resolveConfigRef(req, uid);
    const clean = sanitizeConfig(req.body || {});

    const dataToSave = {
      uid,
      ...clean,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      ...(!existing.exists && {created_at: admin.firestore.FieldValue.serverTimestamp()}),
    };

    await configRef.set(dataToSave, {merge: true});

    return res.status(200).json({success: true, message: "Max Demand chart config saved successfully"});
  } catch (error) {
    console.error("Error saving Max Demand chart config:", error);
    return res.status(500).json({error: "Failed to save Max Demand chart config"});
  }
});

module.exports = router;
