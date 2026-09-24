const express = require("express");
const admin = require("firebase-admin");
const {getClientFirestore, isStrictDb} = require("../helpers/dbConnections");
// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "mdInsightReportConfigs";

// Per-tenant MD Insight Report settings. String fields are the report's
// dynamic images (plant-status background photo + footer brand logo);
// `excludedEquipmentByPlant` (handled separately, see sanitizeExcludedMap)
// is which equipment each plant's Equipment Analysis ranking should skip.
// Mirrors MdInsightReportImageConfig.toJson() in
// lib/web_app_template/md_insight_report/md_insight_report_image_config.dart.
const STRING_FIELDS = [
  "plantBackgroundImageUrl",
  "footerLogoImageUrl",
];

function defaultConfig() {
  const config = {};
  for (const key of STRING_FIELDS) config[key] = null;
  config.excludedEquipmentByPlant = {};
  return config;
}

// Per-plant Equipment Analysis ranking exclusions — { [meterCode]: [deviceTag, ...] }.
// A plant whose exclusion list ends up empty (everything re-included) is
// dropped from the map entirely rather than stored as `[]`, so the doc
// doesn't accumulate stale empty entries as plants get reset over time.
function sanitizeExcludedMap(value) {
  if (!value || typeof value !== "object") return {};
  const clean = {};
  for (const [plantCode, tags] of Object.entries(value)) {
    const key = String(plantCode || "").trim();
    if (!key || !Array.isArray(tags)) continue;
    const list = tags.map((t) => String(t || "").trim()).filter(Boolean);
    if (list.length) clean[key] = list;
  }
  return clean;
}

// ── Multi-tenant resolver ───────────────────────────────────────────────────
// Same resolution order as carbonDashboardConfigFunction.js: prefer the
// client's own Firestore (via x-client-id), but keep data wherever it
// already lives so nothing is hidden mid-migration.
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
  for (const key of STRING_FIELDS) {
    const value = body[key];
    clean[key] = typeof value === "string" && value.trim() !== "" ? value.trim() : null;
  }
  clean.excludedEquipmentByPlant = sanitizeExcludedMap(body.excludedEquipmentByPlant);
  return clean;
}

// Must match AppConfig.sharedConfigOwnerId in lib/services/app_config.dart.
const SHARED_CONFIG_OWNER_ID = "shared";

/**
 * POST /api/md-insight-report-config/migrate-to-shared
 * Body: { sourceUid }
 *
 * One-off migration: this config used to be scoped per individual
 * Firebase-Auth login (mdInsightReportConfigs/{uid}); every page now reads/
 * writes a single client-wide doc instead (mdInsightReportConfigs/shared).
 * Non-destructive — the source doc is left untouched. No auth, matching
 * this codebase's other one-off migration routes — delete once run.
 */
router.post("/migrate-to-shared", async (req, res) => {
  try {
    const sourceUid = (req.body && req.body.sourceUid) || req.query.sourceUid;
    if (!sourceUid) return res.status(400).json({ error: "sourceUid is required" });
    if (sourceUid === SHARED_CONFIG_OWNER_ID) {
      return res.status(400).json({ error: "sourceUid is already the shared owner id" });
    }

    const { snap: sourceSnap } = await resolveConfigRef(req, sourceUid);
    if (!sourceSnap.exists) {
      return res.status(404).json({ error: "No config found for sourceUid", sourceUid });
    }

    const { ref: sharedRef } = await resolveConfigRef(req, SHARED_CONFIG_OWNER_ID);
    const clean = sanitizeConfig(sourceSnap.data());
    await sharedRef.set(
      { uid: SHARED_CONFIG_OWNER_ID, ...clean, updated_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );

    return res.status(200).json({ message: "Migrated to shared MD Insight Report config.", sourceUid });
  } catch (error) {
    console.error("Error migrating MD Insight Report image config:", error);
    return res.status(500).json({ error: "Failed to migrate MD Insight Report image config" });
  }
});

/**
 * GET /api/md-insight-report-config/:uid
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const {snap: doc} = await resolveConfigRef(req, uid);
    if (!doc.exists) {
      return res.status(200).json({exists: false, ...defaultConfig()});
    }

    const data = doc.data();
    return res.status(200).json({exists: true, ...defaultConfig(), ...sanitizeConfig(data)});
  } catch (error) {
    console.error("Error fetching MD Insight Report image config:", error);
    return res.status(500).json({error: "Failed to fetch MD Insight Report image config"});
  }
});

/**
 * POST /api/md-insight-report-config/:uid
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

    return res.status(200).json({success: true, message: "MD Insight Report image config saved successfully"});
  } catch (error) {
    console.error("Error saving MD Insight Report image config:", error);
    return res.status(500).json({error: "Failed to save MD Insight Report image config"});
  }
});

module.exports = router;
