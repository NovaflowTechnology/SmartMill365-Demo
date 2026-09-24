const express = require("express");
const admin = require("firebase-admin");
const {getClientFirestore, isStrictDb} = require("../helpers/dbConnections");
// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "sankeyFlowSettings";

// ── Multi-tenant resolver ───────────────────────────────────────────────────
// Resolve the sankeyFlowSettings doc ref, preferring the client's own Firestore
// (selected per x-client-id via integration_config) but keeping the user's data
// wherever it already lives so nothing is hidden during a partial migration:
//   1. client db already has the doc → use client db
//   2. else default db has it        → use default db
//   3. else (brand-new user)         → use client db
// Clients without a dedicated Firestore resolve to default = old behaviour.
async function resolveSankeyRef(req, uid) {
  const clientId = req.headers["x-client-id"] || null;
  const clientDb = await getClientFirestore(clientId);
  const defaultDb = admin.firestore();

  const clientRef = clientDb.collection(COLLECTION).doc(uid);
  // A strict client reads and writes its own db only, never the default.
  if (clientDb === defaultDb || isStrictDb(clientDb)) {
    const snap = await clientRef.get();
    return {ref: clientRef, snap, db: clientDb};
  }

  const clientSnap = await clientRef.get();
  if (clientSnap.exists) return {ref: clientRef, snap: clientSnap, db: clientDb};

  const defaultRef = defaultDb.collection(COLLECTION).doc(uid);
  const defaultSnap = await defaultRef.get();
  if (defaultSnap.exists) return {ref: defaultRef, snap: defaultSnap, db: defaultDb};

  return {ref: clientRef, snap: clientSnap, db: clientDb};
}

function pickFlowTag(node) {
  if (node.flow_value_tag) return String(node.flow_value_tag);
  if (node.flowValueTag) return String(node.flowValueTag);
  if (Array.isArray(node.fields)) {
    const first = node.fields.find((field) => String(field || "").trim() !== "");
    if (first) return String(first);
  }
  if (node.field) return String(node.field);
  if (node.dataMapping) return String(node.dataMapping);
  return "";
}

function nodeFacilityId(node) {
  return String(
      node.master_facility_id ||
      node.masterFacilityId ||
      node.facilityId ||
      node.id ||
      "",
  );
}

function normalizeFlowLinks(nodes, flowLinks) {
  if (Array.isArray(flowLinks) && flowLinks.length > 0) {
    return flowLinks.map((link) => ({
      master_facility_id: String(link.master_facility_id || "").trim(),
      source_node_id: String(link.source_node_id || "").trim(),
      destination_node_id: String(link.destination_node_id || "").trim(),
      flow_value_tag: String(link.flow_value_tag || "").trim(),
    }));
  }

  const nodeById = {};
  for (const node of nodes) nodeById[String(node.id || "")] = node;
  const links = [];
  for (const sourceNode of nodes) {
    const sourceNodeId = String(sourceNode.id || "").trim();
    if (!sourceNodeId) continue;
    const sourceFacilityId = nodeFacilityId(sourceNode).trim();
    const flowValueTag = pickFlowTag(sourceNode).trim();
    for (const destinationNodeIdRaw of sourceNode.targetIds || []) {
      const destinationNodeId = String(destinationNodeIdRaw || "").trim();
      if (!destinationNodeId || !nodeById[destinationNodeId]) continue;
      links.push({
        master_facility_id: sourceFacilityId,
        source_node_id: sourceNodeId,
        destination_node_id: destinationNodeId,
        flow_value_tag: flowValueTag,
      });
    }
  }
  return links;
}

function detectCircularLinkage(links) {
  const adjacency = new Map();
  for (const link of links) {
    const from = link.source_node_id;
    const to = link.destination_node_id;
    if (!from || !to) continue;
    if (!adjacency.has(from)) adjacency.set(from, new Set());
    adjacency.get(from).add(to);
  }

  const visiting = new Set();
  const visited = new Set();

  const dfs = (node) => {
    if (visiting.has(node)) return true;
    if (visited.has(node)) return false;
    visiting.add(node);
    for (const next of adjacency.get(node) || []) {
      if (dfs(next)) return true;
    }
    visiting.delete(node);
    visited.add(node);
    return false;
  };

  for (const node of adjacency.keys()) {
    if (dfs(node)) return true;
  }
  return false;
}

function bestFacilityLabel(facility) {
  const candidates = [
    facility.equipmentNameId,
    facility.meterName,
    facility.equipmentType,
    facility.plant,
    facility.id,
  ];
  for (const candidate of candidates) {
    const text = String(candidate || "").trim();
    if (text) return text;
  }
  return "";
}

async function loadFacilityMaps(uid, primaryDb) {
  const defaultDb = admin.firestore();
  const facilityCol = (d) =>
    d.collection("master_facilities").doc(uid).collection("facilities");

  // Read facility labels from the same Firestore the sankey doc resolved to;
  // fall back to the default project if the client copy is empty so labels and
  // link validation keep working during a partial migration.
  let snapshot = await facilityCol(primaryDb).get();
  if (snapshot.empty && primaryDb !== defaultDb && !isStrictDb(primaryDb)) {
    snapshot = await facilityCol(defaultDb).get();
  }

  const byId = new Map();
  const labelById = new Map();
  for (const doc of snapshot.docs) {
    const facility = {id: doc.id, ...doc.data()};
    byId.set(doc.id, facility);
    labelById.set(doc.id, bestFacilityLabel(facility));
  }
  return {byId, labelById};
}

function syncNodeLabels(nodes, facilityLabelById) {
  return nodes.map((node) => {
    const facilityId = nodeFacilityId(node).trim();
    const syncedLabel = facilityLabelById.get(facilityId);
    if (!syncedLabel) return node;
    return {
      ...node,
      label: syncedLabel,
      master_facility_id: facilityId,
    };
  });
}

function validateFlowLinks(flowLinks, facilityMap) {
  const errors = [];
  for (let i = 0; i < flowLinks.length; i++) {
    const row = flowLinks[i];
    const rowLabel = `flowLinks[${i}]`;
    if (!row.master_facility_id) {
      errors.push(`${rowLabel}.master_facility_id is required`);
    } else if (!facilityMap.has(row.master_facility_id)) {
      errors.push(
          `${rowLabel}.master_facility_id "${row.master_facility_id}" is not registered in Master Facility`,
      );
    }
    if (!row.source_node_id) {
      errors.push(`${rowLabel}.source_node_id is required`);
    }
    if (!row.destination_node_id) {
      errors.push(`${rowLabel}.destination_node_id is required`);
    }
    if (!row.flow_value_tag) {
      errors.push(`${rowLabel}.flow_value_tag is required`);
    }
  }
  return errors;
}

/**
 * GET /api/sankey-setting/:uid
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const {snap: doc, db} = await resolveSankeyRef(req, uid);
    if (!doc.exists) {
      return res.status(200).json({exists: false, tiers: [], nodes: []});
    }

    const data = doc.data();
    const nodes = Array.isArray(data.nodes) ? data.nodes : [];
    const {labelById} = await loadFacilityMaps(uid, db);
    const syncedNodes = syncNodeLabels(nodes, labelById);
    const flowLinks = normalizeFlowLinks(syncedNodes, data.flowLinks);

    return res.status(200).json({
      exists: true,
      ...data,
      nodes: syncedNodes,
      flowLinks,
    });
  } catch (error) {
    console.error("Error fetching sankey setting:", error);
    return res.status(500).json({error: "Failed to fetch sankey setting"});
  }
});

/**
 * POST /api/sankey-setting/:uid
 */
router.post("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    const {tiers, nodes, flowLinks} = req.body;

    if (!uid) return res.status(400).json({error: "User ID is required"});
    if (!Array.isArray(tiers)) return res.status(400).json({error: "tiers must be an array"});
    if (!Array.isArray(nodes)) return res.status(400).json({error: "nodes must be an array"});

    const {ref: sankeyRef, snap: existing, db} = await resolveSankeyRef(req, uid);
    const {byId: facilityMap, labelById} = await loadFacilityMaps(uid, db);
    const syncedNodes = syncNodeLabels(nodes, labelById);
    const normalizedFlowLinks = normalizeFlowLinks(syncedNodes, flowLinks);
    const linkErrors = validateFlowLinks(normalizedFlowLinks, facilityMap);
    if (linkErrors.length > 0) {
      return res.status(400).json({
        error: "Invalid Sankey link schema",
        details: linkErrors,
      });
    }
    if (detectCircularLinkage(normalizedFlowLinks)) {
      return res.status(400).json({
        error: "Circular linkage detected in Sankey Flow graph",
      });
    }

    const dataToSave = {
      uid,
      tiers,
      nodes: syncedNodes,
      flowLinks: normalizedFlowLinks,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      ...(!existing.exists && {created_at: admin.firestore.FieldValue.serverTimestamp()}),
    };

    await sankeyRef.set(dataToSave, {merge: true});

    return res.status(200).json({success: true, message: "Sankey setting saved successfully"});
  } catch (error) {
    console.error("Error saving sankey setting:", error);
    return res.status(500).json({error: "Failed to save sankey setting"});
  }
});

/**
 * GET /api/sankey-setting/:uid/compiled
 *
 * Returns config pre-compiled into Sankey-ready format:
 *
 *  sankeyNodes  — flat list of all nodes, ordered by tier (left → right)
 *  sankeyLinks  — directed edges: one link per parent→child pair
 *
 * Each sankeyNode:
 *  {
 *    id,           — unique node id (use as key in chart)
 *    label,        — display name shown on the Sankey node
 *    tierOrder,    — 0 = leftmost (source), 1 = next level, etc.
 *    tierLabel,    — human-readable tier name (e.g. "Sources (Left)")
 *    deviceId,     — meter/device to read live value from
 *    dataMapping,  — channel to read (e.g. "kWh", "kW")
 *  }
 *
 * Each sankeyLink:
 *  {
 *    sourceNodeId,       — id of the parent node
 *    targetNodeId,       — id of the child node
 *    sourceDeviceId,     — deviceId of parent  (for value fetch)
 *    targetDeviceId,     — deviceId of child   (for value fetch)
 *    sourceDataMapping,  — dataMapping of parent
 *    targetDataMapping,  — dataMapping of child
 *    sourceLabel,        — label of parent node
 *    targetLabel,        — label of child node
 *  }
 *
 * NOTE: "value" (actual kWh reading) is NOT included here — the chart page
 * fetches live values per deviceId+dataMapping from the InfluxDB API
 * (GET /energyDetailsInfluxDb/stats/:deviceId) and maps them onto the nodes.
 */
router.get("/:uid/compiled", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) return res.status(400).json({error: "User ID is required"});

    const {snap: doc, db} = await resolveSankeyRef(req, uid);
    if (!doc.exists) {
      return res.status(200).json({exists: false, sankeyNodes: [], sankeyLinks: []});
    }

    const data = doc.data();
    const tiers = data.tiers || [];
    const {labelById} = await loadFacilityMaps(uid, db);
    const nodes = syncNodeLabels(data.nodes || [], labelById);

    // Build tier lookup: id → { label, order }
    const tierMap = {};
    for (const t of tiers) tierMap[t.id] = t;

    // Build sankeyNodes — sorted by tier order then by label
    const sankeyNodes = nodes
      .map((n) => ({
        id:          n.id,
        label:       n.label || n.deviceId || n.id,
        tierOrder:   tierMap[n.tierId]?.order ?? 0,
        tierLabel:   tierMap[n.tierId]?.label ?? "",
        deviceId:    n.deviceId || "",
        dataMapping: n.dataMapping || "",
      }))
      .sort((a, b) => a.tierOrder - b.tierOrder || a.label.localeCompare(b.label));

    // Build nodeId → node lookup for link resolution
    const nodeMap = {};
    for (const n of nodes) nodeMap[n.id] = n;

    // Build sankeyLinks — one per parent→child pair
    const normalizedFlowLinks = normalizeFlowLinks(nodes, data.flowLinks);
    const sankeyLinks = normalizedFlowLinks
      .filter((link) => nodeMap[link.source_node_id] && nodeMap[link.destination_node_id])
      .map((link) => {
        const parent = nodeMap[link.source_node_id];
        const child = nodeMap[link.destination_node_id];
        return {
          sourceNodeId: parent.id,
          targetNodeId: child.id,
          sourceDeviceId: parent.deviceId || "",
          targetDeviceId: child.deviceId || "",
          sourceDataMapping: pickFlowTag(parent),
          targetDataMapping: pickFlowTag(child),
          sourceLabel: parent.label || parent.deviceId || parent.id,
          targetLabel: child.label || child.deviceId || child.id,
        };
      });
    const fallbackLinks = nodes
      .filter((n) => n.parentId && nodeMap[n.parentId])
      .map((n) => {
        const parent = nodeMap[n.parentId];
        return {
          sourceNodeId:      parent.id,
          targetNodeId:      n.id,
          sourceDeviceId:    parent.deviceId || "",
          targetDeviceId:    n.deviceId || "",
          sourceDataMapping: parent.dataMapping || "",
          targetDataMapping: n.dataMapping || "",
          sourceLabel:       parent.label || parent.deviceId || parent.id,
          targetLabel:       n.label || n.deviceId || n.id,
        };
      });
    const finalSankeyLinks = sankeyLinks.length > 0 ? sankeyLinks : fallbackLinks;

    return res.status(200).json({
      exists: true,
      sankeyNodes,
      sankeyLinks: finalSankeyLinks,
    });
  } catch (error) {
    console.error("Error compiling sankey setting:", error);
    return res.status(500).json({error: "Failed to compile sankey setting"});
  }
});

module.exports = router;
