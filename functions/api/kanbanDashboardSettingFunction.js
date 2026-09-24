const express = require("express");
const admin   = require("firebase-admin");
const { getClientFirestore, isStrictDb } = require("../helpers/dbConnections");
const router  = express.Router();

const COLLECTION = "kanbanDashboardSettings";

// ─────────────────────────────────────────────────────────────────────────────
// Multi-tenant resolver
// ─────────────────────────────────────────────────────────────────────────────
// Resolve the Firestore doc ref for a user's kanban-settings, preferring the
// client's own Firestore (selected per x-client-id through integration_config)
// but keeping the user's data wherever it already lives so nothing goes missing
// during a partial migration:
//   1. client db already has the doc  → use client db
//   2. else default db has it         → use default db (don't split the data)
//   3. else (brand-new user)          → use client db
// Clients without their own Firestore (no x-client-id / no firebase secret)
// transparently resolve to the default project — identical to the old behaviour.
async function resolveUserRef(req, uid) {
  const clientId  = req.headers["x-client-id"] || null;
  const clientDb  = await getClientFirestore(clientId);
  const defaultDb = admin.firestore();

  const clientRef  = clientDb.collection(COLLECTION).doc(uid);

  // No dedicated client db → behave exactly like before (default only).
  // A strict client stays on its own db and never looks in the default.
  if (clientDb === defaultDb || isStrictDb(clientDb)) {
    const snap = await clientRef.get();
    return { ref: clientRef, snap };
  }

  const clientSnap = await clientRef.get();
  if (clientSnap.exists) return { ref: clientRef, snap: clientSnap };

  // Fall back to default so pre-migration data is never hidden.
  const defaultRef  = defaultDb.collection(COLLECTION).doc(uid);
  const defaultSnap = await defaultRef.get();
  if (defaultSnap.exists) return { ref: defaultRef, snap: defaultSnap };

  // Brand-new user → prefer the client db.
  return { ref: clientRef, snap: clientSnap };
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
function sanitiseCell(cell) {
  return {
    cellIndex:  parseInt(cell.cellIndex) ?? 0,
    widgetType: cell.widgetType  || "",
    widgetName: cell.widgetName  || "",
    size: ["1x1","1x2","2x1","2x2"].includes(cell.size) ? cell.size : "1x1",
    config: sanitiseCellConfig(cell.widgetType, cell.config || {}),
  };
}

function sanitiseCellConfig(_type, cfg) {
  const base = {
    factory:        cfg.factory        || "",
    productionArea: cfg.productionArea || "",
    statisticRange: cfg.statisticRange || "ALL",
    displayMsg:     Array.isArray(cfg.displayMsg) ? cfg.displayMsg : [],
    sortConditions: Array.isArray(cfg.sortConditions)
      ? cfg.sortConditions.map(s => ({
          field:     s.field     || "",
          direction: ["ASC","DESC"].includes(s.direction) ? s.direction : "DESC",
        }))
      : [],
  };
  return base;
}

function buildTemplate(data, existingId) {
  return {
    id:                  existingId || admin.firestore().collection("_").doc().id,
    kanbanDesc:          (data.kanbanDesc || "").trim(),
    layout:              data.layout      || "VERTICAL_4X3",
    remark:              data.remark      || "",
    title:               data.title       || "",
    left:                data.left        || "NONE",
    right:               data.right       || "TIME",
    display:             data.display     || "SCROLL",
    interval:            parseInt(data.interval) || 20,
    chartValue:          Boolean(data.chartValue),
    footer:              Boolean(data.footer),
    headerRows:          parseInt(data.headerRows)  || 0,
    footerRows:          parseInt(data.footerRows)  || 0,
    displayDefaultTitle: Boolean(data.displayDefaultTitle),
    showGrid:            data.showGrid !== false,
    interfaceType:       data.interfaceType || "KANBAN_GRID",
    ecConfig:            data.ecConfig || null,
    // cells array — always present
    cells:               Array.isArray(data.cells) ? data.cells.map(sanitiseCell) : [],
    createdAt:           existingId ? undefined : new Date().toISOString(),
    userId:              data.userId || "",
  };
}

// ═════════════════════════════════════════════════════════════════════════════
// POST /:uid  — Create template
// ═════════════════════════════════════════════════════════════════════════════
router.post("/:uid", async (req, res) => {
  try {
    const { uid } = req.params;
    if (!uid?.trim()) return res.status(400).json({ error: "User ID is required" });
    if (!req.body.kanbanDesc?.trim()) return res.status(400).json({ error: "Kanban description is required" });

    const { ref: userRef, snap: userSnap } = await resolveUserRef(req, uid);
    const tmpl = buildTemplate({ ...req.body, userId: uid });

    await userRef.set({
      uid,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      templates: userSnap.exists
        ? admin.firestore.FieldValue.arrayUnion(tmpl)
        : [tmpl],
      ...(!userSnap.exists && { created_at: admin.firestore.FieldValue.serverTimestamp() }),
    }, { merge: true });

    return res.status(200).json({ success: true, message: "Kanban template saved successfully", templateId: tmpl.id, template: tmpl });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to save template", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// PUT /:uid/template/:templateId  — Update template fields (and cells)
// ═════════════════════════════════════════════════════════════════════════════
router.put("/:uid/template/:templateId", async (req, res) => {
  try {
    const { uid, templateId } = req.params;
    const { ref: userRef, snap: userSnap } = await resolveUserRef(req, uid);
    if (!userSnap.exists) return res.status(404).json({ error: "User not found" });

    const templates = userSnap.data().templates || [];
    const idx       = templates.findIndex(t => t.id === templateId);
    if (idx === -1) return res.status(404).json({ error: "Template not found" });

    const existing = templates[idx];
    const d        = req.body;

    const updated = {
      ...existing,
      ...(d.kanbanDesc              && { kanbanDesc:          d.kanbanDesc.trim() }),
      ...(d.layout                  && { layout:              d.layout }),
      ...(d.remark   !== undefined  && { remark:              d.remark }),
      ...(d.title    !== undefined  && { title:               d.title }),
      ...(d.left                    && { left:                d.left }),
      ...(d.right                   && { right:               d.right }),
      ...(d.display                 && { display:             d.display }),
      ...(d.interval !== undefined  && { interval:            parseInt(d.interval) || 20 }),
      ...(d.chartValue !== undefined && { chartValue:         Boolean(d.chartValue) }),
      ...(d.footer   !== undefined  && { footer:              Boolean(d.footer) }),
      ...(d.headerRows !== undefined && { headerRows:         parseInt(d.headerRows) || 0 }),
      ...(d.footerRows !== undefined && { footerRows:         parseInt(d.footerRows) || 0 }),
      ...(d.displayDefaultTitle !== undefined && { displayDefaultTitle: Boolean(d.displayDefaultTitle) }),
      ...(d.showGrid !== undefined  && { showGrid:            Boolean(d.showGrid) }),
      ...(d.interfaceType !== undefined && { interfaceType:   d.interfaceType }),
      ...(d.ecConfig !== undefined  && { ecConfig:            d.ecConfig }),
      // Replace cells when explicitly sent
      ...(Array.isArray(d.cells)    && { cells:               d.cells.map(sanitiseCell) }),
      updatedAt: new Date().toISOString(),
    };

    templates[idx] = updated;
    await userRef.update({ templates, updated_at: admin.firestore.FieldValue.serverTimestamp() });

    return res.status(200).json({ success: true, message: "Template updated successfully", templateId, template: updated });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to update template", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// DELETE /:uid/template/:templateId  — Delete a template
// ═════════════════════════════════════════════════════════════════════════════
router.delete("/:uid/template/:templateId", async (req, res) => {
  try {
    const { uid, templateId } = req.params;
    if (!uid?.trim())        return res.status(400).json({ error: "User ID is required" });
    if (!templateId?.trim()) return res.status(400).json({ error: "Template ID is required" });

    const { ref: userRef, snap: userSnap } = await resolveUserRef(req, uid);
    if (!userSnap.exists) return res.status(404).json({ error: "User not found" });

    const templates = userSnap.data().templates || [];
    const idx       = templates.findIndex(t => t.id === templateId);
    if (idx === -1) return res.status(404).json({ error: "Template not found" });

    const updatedTemplates = templates.filter(t => t.id !== templateId);
    await userRef.update({ templates: updatedTemplates, updated_at: admin.firestore.FieldValue.serverTimestamp() });

    const data = userSnap.data();
    if (data.activeTemplate === templateId) {
      await userRef.update({
        activeTemplate: admin.firestore.FieldValue.delete(),
        activeSettings: admin.firestore.FieldValue.delete(),
        lastAppliedAt:  admin.firestore.FieldValue.delete(),
      });
    }

    return res.status(200).json({ success: true, message: "Template deleted", templateId });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to delete template", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// PUT /:uid/template/:templateId/cell  — Upsert a single cell
// ═════════════════════════════════════════════════════════════════════════════
router.put("/:uid/template/:templateId/cell", async (req, res) => {
  try {
    const { uid, templateId } = req.params;
    const cellPayload = req.body;

    if (cellPayload.cellIndex === undefined) return res.status(400).json({ error: "cellIndex is required" });
    if (!cellPayload.widgetType)             return res.status(400).json({ error: "widgetType is required" });

    const { ref: userRef, snap: userSnap } = await resolveUserRef(req, uid);
    if (!userSnap.exists) return res.status(404).json({ error: "User not found" });

    const templates = userSnap.data().templates || [];
    const tIdx      = templates.findIndex(t => t.id === templateId);
    if (tIdx === -1) return res.status(404).json({ error: "Template not found" });

    const template  = templates[tIdx];
    const cells     = Array.isArray(template.cells) ? [...template.cells] : [];
    const cellIndex = parseInt(cellPayload.cellIndex);
    const sanitised = sanitiseCell(cellPayload);
    const cIdx      = cells.findIndex(c => c.cellIndex === cellIndex);

    if (cIdx >= 0) cells[cIdx] = sanitised;
    else           cells.push(sanitised);

    templates[tIdx] = { ...template, cells, updatedAt: new Date().toISOString() };
    await userRef.update({ templates, updated_at: admin.firestore.FieldValue.serverTimestamp() });

    return res.status(200).json({ success: true, message: "Cell saved", templateId, cell: sanitised, totalCells: cells.length });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to save cell", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// DELETE /:uid/template/:templateId/cell/:cellIndex  — Remove a cell
// ═════════════════════════════════════════════════════════════════════════════
router.delete("/:uid/template/:templateId/cell/:cellIndex", async (req, res) => {
  try {
    const { uid, templateId, cellIndex } = req.params;
    const { ref: userRef, snap: userSnap } = await resolveUserRef(req, uid);
    if (!userSnap.exists) return res.status(404).json({ error: "User not found" });

    const templates = userSnap.data().templates || [];
    const tIdx      = templates.findIndex(t => t.id === templateId);
    if (tIdx === -1) return res.status(404).json({ error: "Template not found" });

    const template = templates[tIdx];
    const cells    = (template.cells || []).filter(c => c.cellIndex !== parseInt(cellIndex));
    templates[tIdx] = { ...template, cells, updatedAt: new Date().toISOString() };
    await userRef.update({ templates, updated_at: admin.firestore.FieldValue.serverTimestamp() });

    return res.status(200).json({ success: true, message: "Cell removed", templateId, cellIndex: parseInt(cellIndex) });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to remove cell", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// POST /:uid/apply/:templateId  — Apply a template → copy to activeSettings
// ═════════════════════════════════════════════════════════════════════════════
router.post("/:uid/apply/:templateId", async (req, res) => {
  try {
    const { uid, templateId } = req.params;
    const { ref: userRef, snap: userSnap } = await resolveUserRef(req, uid);
    if (!userSnap.exists) return res.status(404).json({ error: "User not found" });

    const template = (userSnap.data().templates || []).find(t => t.id === templateId);
    if (!template) return res.status(404).json({ error: "Template not found" });

    const appId           = `applied_${uid}`;
    const appliedAt       = new Date().toISOString();
    const appliedSettings = { ...template };

    // Write the applied snapshot to the SAME Firestore the user doc lives in.
    await userRef.firestore.collection("appliedKanbanSettings").doc(appId).set({
      id: appId, templateId, userId: uid,
      appliedTemplate: appliedSettings,
      appliedAt,
      appliedTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "APPLIED",
    }, { merge: false });

    await userRef.update({
      activeTemplate:  templateId,
      activeSettings:  appliedSettings,
      lastAppliedAt:   admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({
      success: true,
      message: "Template applied successfully",
      appliedSettings: {
        templateId,
        title:   template.title,
        cells:   template.cells || [],
        settings: {
          kanbanDesc:          template.kanbanDesc,
          layout:              template.layout,
          remark:              template.remark,
          headerRows:          template.headerRows,
          footerRows:          template.footerRows,
          displayDefaultTitle: template.displayDefaultTitle,
          showGrid:            template.showGrid,
          left:                template.left,
          right:               template.right,
          display:             template.display,
          interval:            template.interval,
          chartValue:          template.chartValue,
          interfaceType:       template.interfaceType || "KANBAN_GRID",
          ecConfig:            template.ecConfig || null,
          appliedAt,
        },
        appliedAt,
      },
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to apply template", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// GET /:uid/active  — Return applied settings + cells for the dashboard
// ═════════════════════════════════════════════════════════════════════════════
router.get("/:uid/active", async (req, res) => {
  try {
    const { uid } = req.params;
    if (!uid?.trim()) return res.status(400).json({ error: "User ID is required" });

    const { snap: userSnap } = await resolveUserRef(req, uid);
    if (!userSnap.exists) return res.status(404).json({ success: false, error: "User not found" });

    const data           = userSnap.data();
    const activeSettings = data.activeSettings || null;

    if (!activeSettings) {
      return res.status(200).json({ success: true, message: "No active settings", settings: null, cells: [], activeTemplate: null });
    }

    return res.status(200).json({
      success: true,
      message: "Active settings retrieved",
      activeTemplate: data.activeTemplate || null,
      lastAppliedAt:  data.lastAppliedAt  || null,
      appliedSettings: {
        settings: activeSettings,
        cells: activeSettings.cells || [],
      },
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to fetch active settings", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// GET /list  — All templates across all users (merges client + default dbs)
// ═════════════════════════════════════════════════════════════════════════════
router.get("/list", async (req, res) => {
  try {
    const clientId  = req.headers["x-client-id"] || null;
    const clientDb  = await getClientFirestore(clientId);
    const defaultDb = admin.firestore();

    // Merge by doc id so partially-migrated clients still see every user's
    // templates regardless of which project a given doc physically lives in
    // right now — Thong Guan's own admin doc, for example, still lives in
    // the shared default project even though Thong Guan also has its own
    // dedicated one. A strict client lists its own templates only.
    const merged = new Map();
    if (!isStrictDb(clientDb)) {
      const defSnap = await defaultDb.collection(COLLECTION).get();
      defSnap.docs.forEach(d => merged.set(d.id, d));
    }
    if (clientDb !== defaultDb) {
      const cliSnap = await clientDb.collection(COLLECTION).get();
      cliSnap.docs.forEach(d => merged.set(d.id, d));
    }

    let all = [];
    merged.forEach(doc => (doc.data().templates || []).forEach(t => all.push({ ...t, userId: doc.id })));
    // Where a client is known, filter out templates whose OWN ecConfig
    // says they belong to a DIFFERENT client — a doc's clientId field is a
    // reliable signal regardless of which project it physically lives in
    // (unlike "which database it came from", which a partially-migrated
    // client makes unreliable). A template with no ecConfig at all (a plain
    // kanban grid, not a PECC-linked one) carries no client signal, so it
    // stays eligible rather than being dropped on a false negative.
    if (clientId) {
      all = all.filter((t) => !t.ecConfig || !t.ecConfig.clientId || t.ecConfig.clientId === clientId);
    }
    all.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    return res.status(200).json({ success: true, data: all, count: all.length });
  } catch (e) {
    return res.status(500).json({ error: "Failed to fetch templates", details: e.message });
  }
});

// ═════════════════════════════════════════════════════════════════════════════
// GET /:uid  — All templates for a user (includes cells)
// ═════════════════════════════════════════════════════════════════════════════
router.get("/:uid", async (req, res) => {
  try {
    const { uid } = req.params;
    if (!uid?.trim()) return res.status(400).json({ error: "User ID is required" });

    const { snap } = await resolveUserRef(req, uid);
    if (!snap.exists) return res.status(404).json({ success: false, message: "User not found", data: { templates: [] } });
    return res.status(200).json({ success: true, data: snap.data() });
  } catch (e) {
    return res.status(500).json({ error: "Failed to fetch user templates", details: e.message });
  }
});

module.exports = router;
