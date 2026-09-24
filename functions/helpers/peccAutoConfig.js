const admin = require("firebase-admin");
const {getClientFirestore} = require("./dbConnections");

const PECC_COLLECTION = "plantEnergyCommandCenterSettings";
const TNB_COLLECTION = "tnb_meters";
const FACTORY_COLLECTION = "factories";
const KANBAN_COLLECTION = "kanbanDashboardSettings";

// Mirrors plantEnergyCommandCenterFunction.js's own docIdFor — kept identical
// so a doc created here is the exact same one the frontend reads and saves.
function docIdFor(uid, plantId) {
  const pid = (plantId || "").toString().trim();
  return pid ? `${uid}__${pid}` : uid;
}

/**
 * Same rule kanban_dashboard_widget.dart's _findFallbackAdminUid() uses when
 * a viewer has no dashboard template of their own: whichever user most
 * recently created/applied any kanban template becomes "the admin" every
 * unconfigured account inherits from. A PECC doc auto-created here has to be
 * written under that same uid, or _loadPlantPecc's own fallback (which reads
 * kanban-settings the same way) will never find it for anyone but its creator.
 */
async function resolveOwnerUid(clientDb, clientId) {
  const defaultDb = admin.firestore();
  const merged = new Map();
  // Merge both projects — a partially-migrated client's admin doc may still
  // live in the shared default project even though the client also has its
  // own dedicated one (Thong Guan is exactly this case today).
  const defSnap = await defaultDb.collection(KANBAN_COLLECTION).get();
  defSnap.docs.forEach((d) => merged.set(d.id, d));
  if (clientDb !== defaultDb) {
    const cliSnap = await clientDb.collection(KANBAN_COLLECTION).get();
    cliSnap.docs.forEach((d) => merged.set(d.id, d));
  }
  let bestUid = null;
  let bestTime = -Infinity;
  merged.forEach((doc, uid) => {
    (doc.data().templates || []).forEach((t) => {
      // A template whose own ecConfig names a DIFFERENT client is never a
      // candidate — this is the actual cross-tenant guard (checking doc
      // content, not which project the doc happens to live in, since
      // partial migration makes the latter an unreliable signal). A
      // template with no ecConfig carries no client signal and stays
      // eligible, same as kanbanDashboardSettingFunction.js's GET /list.
      if (clientId && t.ecConfig && t.ecConfig.clientId && t.ecConfig.clientId !== clientId) return;
      const time = new Date(t.createdAt || 0).getTime();
      if (time > bestTime) {
        bestTime = time;
        bestUid = uid;
      }
    });
  });
  return bestUid;
}

/** The active TNB meter for one factory id, or null if it has none yet. */
async function findActiveMeter(clientDb, factoryId) {
  if (!factoryId) return null;
  const snap = await clientDb.collection(TNB_COLLECTION)
      .where("plantId", "==", factoryId)
      .where("isActive", "==", true)
      .get();
  if (snap.empty) return null;
  const docs = snap.docs.map((d) => d.data());
  // More than one active meter on a plant shouldn't happen, but if it does,
  // the most recently touched one wins rather than an arbitrary query order.
  docs.sort((a, b) =>
    new Date(b.updatedAt || b.createdAt || 0) -
    new Date(a.updatedAt || a.createdAt || 0));
  return docs[0];
}

/**
 * Factories named "<factoryName> Block A/B/C" — the real, consistent
 * convention Lot 237's own blocks already follow (SITE001/002/003 under
 * SITE004 "Lot 237"). Sorted so block A/B/C line up with flow.blockA/B/C in
 * that order regardless of Firestore's own document order.
 */
async function findBlockChildren(clientDb, factoryName) {
  if (!factoryName) return [];
  const prefix = `${factoryName} Block `;
  const snap = await clientDb.collection(FACTORY_COLLECTION).get();
  return snap.docs
      .map((d) => ({id: d.id, ...d.data()}))
      .filter((f) => (f.name || "").startsWith(prefix))
      .sort((a, b) => (a.name || "").localeCompare(b.name || ""));
}

/**
 * The reverse of findBlockChildren: if this factory's own name matches
 * "<something> Block A/B/C", returns that parent factory's {id, name}, else
 * null. Used so saving a block's own TNB meter also refreshes its parent's
 * flow.blockA/B/C card, not just the block's own dashboard.
 */
async function findParentByBlockName(clientDb, factoryName) {
  const match = /^(.*) Block [A-Za-z]$/.exec((factoryName || "").trim());
  if (!match) return null;
  const parentName = match[1].trim();
  if (!parentName) return null;
  const snap = await clientDb.collection(FACTORY_COLLECTION)
      .where("name", "==", parentName)
      .limit(1)
      .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return {id: doc.id, ...doc.data()};
}

/**
 * The flexi dashboard's card keys this helper knows how to self-map, each
 * with the device it resolves to for this one plant (blank when that role
 * has no active TNB meter yet — never a guessed/invented device id).
 */
async function buildFlexiWidgets(clientDb, factoryId, factoryName) {
  const mainMeter = await findActiveMeter(clientDb, factoryId);
  const mainDevice = mainMeter ? (mainMeter.influxDbTag || "") : "";
  const solarDevice = mainMeter ? (mainMeter.solarDeviceId || "") : "";

  const children = await findBlockChildren(clientDb, factoryName);
  const blockLetters = ["A", "B", "C"];
  const blockDevice = {};
  for (let i = 0; i < Math.min(children.length, 3); i++) {
    const meter = await findActiveMeter(clientDb, children[i].id);
    blockDevice[blockLetters[i]] = meter ? (meter.influxDbTag || "") : "";
  }

  const energyField = "Total Energy (kWh)";
  const powerField = "Current Power (kW)";

  // Grouped the same way Lot 237's own hand-built config is — so a new
  // plant's settings page reads like every other plant's, not like a flat
  // dump of unrelated cards.
  return [
    {key: "hero[0]", label: "GRID IMPORT METER", device: mainDevice, field: energyField, section: "Hero Summary (Top Banner)"},
    {key: "hero[1]", label: "TOTAL SOLAR GENERATION", device: solarDevice, field: energyField, section: "Hero Summary (Top Banner)"},
    {key: "flow.plantTotal", label: "Plant Total", device: mainDevice, field: energyField, section: "Energy Flow Map"},
    {key: "flow.solar", label: "Solar Plant", device: solarDevice, field: energyField, section: "Energy Flow Map"},
    {key: "flow.blockA", label: "Block A", device: blockDevice.A || "", field: energyField, section: "Energy Flow Map"},
    {key: "flow.blockB", label: "Block B", device: blockDevice.B || "", field: energyField, section: "Energy Flow Map"},
    {key: "flow.blockC", label: "Block C", device: blockDevice.C || "", field: energyField, section: "Energy Flow Map"},
    {key: "sidebar[1]", label: "CURRENT LOAD", device: mainDevice, field: powerField, section: "Plant Health Sidebar"},
    {key: "sidebar[4]", label: "SOLAR CONTRIBUTION", device: solarDevice, field: powerField, section: "Plant Health Sidebar"},
    {key: "chart.loadProfile", label: "Actual Power", device: mainDevice, field: powerField, section: "Charts"},
    {key: "chart.solar", label: "Solar Generation", device: solarDevice, field: powerField, section: "Charts"},
    {key: "trend.grid", label: "Grid Trend", device: mainDevice, field: energyField, section: "Charts"},
    {key: "trend.solar", label: "Solar Trend", device: solarDevice, field: energyField, section: "Charts"},
  ];
}

/**
 * Creates a plant's PECC document if it doesn't exist yet (so the settings
 * page and dashboard are never blank), and fills in whichever of the flexi
 * card keys above currently have no device — using this plant's own active
 * TNB meter, and each "<name> Block A/B/C" child's own meter for the flow
 * diagram. A key an admin has already mapped is never touched, and nothing
 * is invented for a role with no meter yet — that card just stays blank,
 * same as today.
 *
 * Safe to call repeatedly (on factory creation and on every TNB meter
 * save) — each call only ever adds what is still missing.
 *
 * [ownerUid], when given, is used as-is instead of being resolved — the
 * pin-cascade caller already knows exactly which uid is saving (the admin
 * currently editing the group map), and that has to be the SAME uid used to
 * both create and later delete a pin's doc, and the same uid the settings
 * page's own plain (no-fallback) lookup will check. Left null for the
 * factory/TNB-meter triggers, which have no "current editor" to reuse and
 * fall back to the same admin-resolution _findFallbackAdminUid() uses.
 */
async function autoProvisionPecc({clientId, factoryId, factoryName, ownerUid: givenOwnerUid}) {
  const name = (factoryName || "").toString().trim();
  if (!name) return {skipped: true, reason: "no plant name"};

  const clientDb = await getClientFirestore(clientId || null);
  const ownerUid = givenOwnerUid || await resolveOwnerUid(clientDb, clientId || null);
  if (!ownerUid) return {skipped: true, reason: "no owner uid resolved"};

  const docId = docIdFor(ownerUid, name);
  const docRef = clientDb.collection(PECC_COLLECTION).doc(docId);
  const existing = await docRef.get();
  const data = existing.exists ? existing.data() : {};
  const savedSections = Array.isArray(data.sections) ? data.sections : [];

  const built = await buildFlexiWidgets(clientDb, factoryId, name);

  const seenKeys = new Set();
  const patchedSections = savedSections.map((sec) => ({
    ...sec,
    widgets: (sec.widgets || []).map((w) => {
      seenKeys.add(w.key);
      const match = built.find((b) => b.key === w.key);
      const alreadyMapped = (w.selectedDevice || "").toString().trim();
      if (match && match.device && !alreadyMapped) {
        return {...w, selectedDevice: match.device, selectedField: match.field};
      }
      return w;
    }),
  }));

  // New keys are grouped by their own section (Hero Summary, Energy Flow
  // Map, ...) rather than dumped into one bucket — same layout an admin
  // hand-building this plant's config would end up with.
  const newWidgets = built.filter((b) => !seenKeys.has(b.key));
  const newSectionTitles = [...new Set(newWidgets.map((b) => b.section))];
  const newSections = newSectionTitles.map((title) => ({
    title,
    widgets: newWidgets
      .filter((b) => b.section === title)
      .map((b) => ({
        key: b.key,
        label: b.label,
        selectedDevice: b.device || "",
        selectedField: b.device ? b.field : "",
      })),
  }));
  const sections = [...patchedSections, ...newSections];

  await docRef.set({
    uid: ownerUid,
    plantId: name,
    clientId: clientId || "",
    sections,
    pins: data.pins || [],
    branding: data.branding || {},
    cards: data.cards || {},
    groups: data.groups || [],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(existing.exists ? {} : {createdAt: admin.firestore.FieldValue.serverTimestamp()}),
  }, {merge: true});

  return {
    ownerUid,
    docId,
    created: !existing.exists,
    filledCount: built.filter((b) => b.device).length,
  };
}

module.exports = {autoProvisionPecc, findParentByBlockName, docIdFor};
