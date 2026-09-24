const admin = require("firebase-admin");
const { queryWithFallback, getClientFirestore, isStrictDb } = require("./dbConnections");

// Must match AppConfig.sharedConfigOwnerId in
// lib/services/app_config.dart — the fixed doc id every client-shared
// config collection (masterBillingConfig, mdInsightReportConfigs, ...) is
// keyed by, instead of an individual Firebase-Auth uid.
const SHARED_CONFIG_OWNER_ID = "shared";

const REPORT_CONFIG_COLLECTION = "mdInsightReportConfigs";

/**
 * Per-plant Equipment Analysis exclusion list, from the same shared
 * mdInsightReportConfigs/{shared} doc the "Configure Images" dialog reads/
 * writes (see functions/api/mdInsightReportConfigFunction.js). Returns a
 * Set of excluded device tags for [plantCode], empty on any failure.
 */
async function _fetchExcludedTags(clientId, plantCode) {
  if (!plantCode) return new Set();
  try {
    const clientDb = await getClientFirestore(clientId);
    const defaultDb = admin.firestore();

    let snap = await clientDb
      .collection(REPORT_CONFIG_COLLECTION)
      .doc(SHARED_CONFIG_OWNER_ID)
      .get();
    // A strict client never reads another client's shared default copy.
    if (!snap.exists && clientDb !== defaultDb && !isStrictDb(clientDb)) {
      snap = await defaultDb
        .collection(REPORT_CONFIG_COLLECTION)
        .doc(SHARED_CONFIG_OWNER_ID)
        .get();
    }
    if (!snap.exists) return new Set();

    const map = snap.data().excludedEquipmentByPlant || {};
    const tags = map[plantCode];
    return new Set(Array.isArray(tags) ? tags.map((t) => String(t || "").trim()) : []);
  } catch (e) {
    console.warn("[mdInsightEquipmentResolver] excluded-tags lookup failed:", e.message);
    return new Set();
  }
}

/**
 * Node port of md_insight_report_widget.dart's
 * `_resolveEquipmentCandidates()` — resolves every candidate Influx device
 * tag that counts as "equipment" for [meter]'s plant, for MD401-404's
 * equipment attribution.
 *
 * Primary source: master_facilities rows registered directly against one of
 * the meter's bound production areas — every device registered for this
 * plant, regardless of whether it also has a matching `equipments` record.
 * Fallback: `equipments` bound to the same areas, cross-referenced to their
 * master_facilities record by equipmentId/name/displayLabel — catches
 * facilities whose own `productionArea` is blank/stale but whose linked
 * equipment record still carries the right area.
 *
 * `meter.boundAreaIds` actually stores each production area's `factory_id`
 * (e.g. "SITE001" — a plant/site code), NOT the production area's own `id`
 * (e.g. "ZONE001"). Equipment's `productionArea` field (and
 * master_facilities' own `productionArea` field) stores the area's display
 * `name` (e.g. "Block A Production Area"). So the real chain is:
 * boundAreaIds (factory_id) -> productionAreas whose factory_id matches ->
 * those areas' `name` -> compare against productionArea. Raw ids and direct
 * id->name are also folded in as fallbacks for records that already match
 * one of those simpler forms — mirrors the Dart doc comment on
 * `_resolveEquipmentCandidates` exactly; keep both in sync.
 */
async function _resolveEquipmentCandidates(clientId, meter) {
  const boundAreaIds = Array.isArray(meter && meter.boundAreaIds) ? meter.boundAreaIds : [];
  if (!boundAreaIds.length) return [];

  const [equipSnap, areaSnap] = await Promise.all([
    queryWithFallback(clientId, "equipments", null),
    queryWithFallback(clientId, "productionAreas", null),
  ]);
  const equipments = equipSnap.docs.map((d) => d.data());
  const productionAreas = areaSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  // master_facilities isn't reachable via queryWithFallback (no per-doc
  // dedup semantics needed here) — same direct getClientFirestore read
  // mdInsightReportBuilder.js already uses for this collection.
  const cdb = await getClientFirestore(clientId);
  const facilitySnap = await cdb.collection("master_facilities").get();
  const facilities = facilitySnap.docs.map((d) => d.data());

  const facilityByKey = {};
  for (const f of facilities) {
    for (const key of [
      String(f.meterId || "").trim(),
      String(f.meterName || "").trim(),
      String(f.equipmentNameId || "").trim(),
    ]) {
      if (key) facilityByKey[key] = f; // last wins, same as the Dart loop
    }
  }

  const areaNameById = {};
  const namesByFactoryId = {};
  for (const a of productionAreas) {
    const id = String(a.id || "");
    const name = String(a.name || "").trim();
    const factoryId = String(a.factory_id || "").trim();
    if (id) areaNameById[id] = name;
    if (factoryId && name) {
      if (!namesByFactoryId[factoryId]) namesByFactoryId[factoryId] = new Set();
      namesByFactoryId[factoryId].add(name);
    }
  }

  const boundAreas = new Set(boundAreaIds.map((id) => String(id)));
  const boundAreaMatchSet = new Set(boundAreas);
  for (const id of boundAreas) {
    if (areaNameById[id]) boundAreaMatchSet.add(areaNameById[id]);
    for (const name of namesByFactoryId[id] || []) boundAreaMatchSet.add(name);
  }

  const scopedEquipments = equipments.filter((e) =>
    boundAreaMatchSet.has(String(e.productionArea || ""))
  );

  const candidatesByTag = new Map(); // tag -> true (dedup, first wins)

  // Primary: master_facilities rows registered directly for this plant's
  // production areas.
  for (const f of facilities) {
    if (!boundAreaMatchSet.has(String(f.productionArea || ""))) continue;
    const tag = String(f.meterId || "").trim();
    if (tag) candidatesByTag.set(tag, true);
  }

  // Fallback: equipment bound to the same areas, resolved to its
  // master_facilities record.
  for (const e of scopedEquipments) {
    const equipmentId = String(e.equipment_id || "").trim();
    const name = String(e.name || "").trim();
    const displayLabel = equipmentId ? `${name} (${equipmentId})` : name;
    const match =
      facilityByKey[equipmentId] || facilityByKey[name] || facilityByKey[displayLabel.trim()];
    const tag = match ? String(match.meterId || "").trim() : "";
    if (!tag) continue;
    if (!candidatesByTag.has(tag)) candidatesByTag.set(tag, true);
  }
  return [...candidatesByTag.keys()];
}

/**
 * Node port of md_insight_report_widget.dart's `_resolveEquipmentDeviceIds()`
 * — every candidate from `_resolveEquipmentCandidates`, minus whatever's
 * excluded for this plant in the shared "Configure Images" exclusion list.
 * Used by the monthly rollup job (functions/helpers/mdInsightMonthlyRollup.js),
 * which has no signed-in user to resolve this client-side.
 */
async function resolveEquipmentDeviceIds({ clientId, meter, plantCode }) {
  try {
    const [candidates, excluded] = await Promise.all([
      _resolveEquipmentCandidates(clientId, meter),
      _fetchExcludedTags(clientId, plantCode),
    ]);
    if (!excluded.size) return candidates;
    return candidates.filter((tag) => !excluded.has(tag));
  } catch (e) {
    console.warn("[mdInsightEquipmentResolver] resolution failed:", e.message);
    return [];
  }
}

module.exports = { resolveEquipmentDeviceIds, SHARED_CONFIG_OWNER_ID };
