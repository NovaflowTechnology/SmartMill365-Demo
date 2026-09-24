const express = require("express");
const admin = require("firebase-admin");
const { getInfluxClient, getMysqlPool, invalidateCache } = require("../helpers/dbConnections");

const router = express.Router();

// ── GET /integrationConfig/me ─────────────────────────────────────────────────
// Returns current client config based on x-client-id header
router.get("/me", async (req, res) => {
  const clientId = req.clientId || req.headers["x-client-id"];
  if (!clientId) {
    return res.status(400).json({ error: "Missing x-client-id header" });
  }
  try {
    const db = admin.firestore();
    const doc = await db.collection("integration_config").doc(clientId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: `Client not found: ${clientId}` });
    }
    return res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /integrationConfig/debug ─────────────────────────────────────────────
// Returns which Firebase project this Functions instance is reading from
router.get("/debug", async (req, res) => {
  try {
    const db = admin.firestore();
    const projectId = admin.app().options.projectId || process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "unknown";
    const snap = await db.collection("integration_config").get();
    const docs = snap.docs.map((d) => d.id);
    return res.json({ projectId, integrationConfigDocs: docs });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /integrationConfig/activeClient ──────────────────────────────────────
// Returns the active clientId and basic info from app_config/active_integration
router.get("/activeClient", async (req, res) => {
  try {
    const db = admin.firestore();
    const doc = await db.collection("app_config").doc("active_integration").get();
    if (!doc.exists) {
      return res.status(404).json({ error: "No active_integration found in app_config" });
    }
    return res.json(doc.data());
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /integrationConfig/clients ───────────────────────────────────────────
// Returns all available client IDs from integration_config collection
router.get("/clients", async (req, res) => {
  try {
    const db = admin.firestore();
    const snap = await db.collection("integration_config").get();
    const clients = snap.docs
      .filter((d) => d.id !== "app_config_active")
      .map((d) => ({ id: d.id, ...d.data() }));
    return res.json(clients);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── POST /integrationConfig/test ──────────────────────────────────────────────
// Body: { clientId: string, type: 'influx' | 'mysql', database?: string }
// Returns: { ok, latencyMs, message }
router.post("/test", async (req, res) => {
  const { clientId, type, database } = req.body;
  if (!clientId || !type) {
    return res.status(400).json({ error: "Missing clientId or type" });
  }

  const start = Date.now();
  try {
    if (type === "influx") {
      const { queryApi, bucket } = await getInfluxClient(clientId, req);
      const query = `from(bucket: "${bucket}") |> range(start: -1h) |> limit(n: 1)`;
      await new Promise((resolve, reject) => {
        queryApi.queryRows(query, {
          next() {},
          error: reject,
          complete: resolve,
        });
      });
    } else if (type === "mysql") {
      const pool = await getMysqlPool(clientId, database, req);
      await pool.query("SELECT 1");
    } else {
      return res.status(400).json({ error: "type must be influx or mysql" });
    }

    const latencyMs = Date.now() - start;

    // Persist connected status + latency back to Firestore
    const field = type === "influx" ? "influx" : "mysql";
    const now = new Date().toISOString().slice(0, 16).replace("T", " ");
    await admin.firestore().collection("integration_config").doc(clientId).update({
      [`${field}.connected`]: true,
      [`${field}.latencyMs`]: latencyMs,
      [`${field}.lastCheck`]: now,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ ok: true, latencyMs, message: `${type === "influx" ? "InfluxDB" : "MySQL"} connected — ${latencyMs}ms` });
  } catch (err) {
    const field = type === "influx" ? "influx" : "mysql";
    const now = new Date().toISOString().slice(0, 16).replace("T", " ");
    await admin.firestore().collection("integration_config").doc(clientId).update({
      [`${field}.connected`]: false,
      [`${field}.lastCheck`]: now,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch(() => {});

    // Evict bad cache entry so next save re-creates pool with fresh credentials
    invalidateCache(clientId);

    return res.status(500).json({ ok: false, message: err.message });
  }
});

// ── POST /integrationConfig/invalidateCache ───────────────────────────────────
// Call this after saving new credentials so the old connection pool is evicted.
// Body: { clientId: string }
router.post("/invalidateCache", (req, res) => {
  const { clientId } = req.body;
  invalidateCache(clientId);
  res.json({ ok: true });
});

// ── POST /integrationConfig/saveConfig ────────────────────────────────────────
// Body: { clientId: string, data: object }
router.post("/saveConfig", async (req, res) => {
  const { clientId, data } = req.body;
  if (!clientId || !data) {
    return res.status(400).json({ error: "Missing clientId or data" });
  }
  try {
    const db = admin.firestore();
    await db.collection("integration_config").doc(clientId).set(data, { merge: true });
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── POST /integrationConfig/saveSecret ───────────────────────────────────────
// Body: { clientId, type: 'influx'|'mysql'|'firebase', secret: object }
// For type='firebase': stores full service account JSON in Secret Manager.
// For type='influx'|'mysql': stores in Firestore secrets subcollection (unchanged).
router.post("/saveSecret", async (req, res) => {
  const { clientId, type, secret } = req.body;
  if (!clientId || !type || !secret) {
    return res.status(400).json({ error: "Missing clientId, type, or secret" });
  }
  try {
    if (type === "firebase") {
      // Extract fields from full service account JSON and store in Firestore subcollection
      const privateKey = secret.private_key || secret.privateKey || "";
      const clientEmail = secret.client_email || secret.clientEmail || "";
      const fbProjectId = secret.project_id || secret.projectId || "";
      if (!privateKey || !clientEmail) {
        return res.status(400).json({ error: "JSON tidak lengkap. Pastikan berisi private_key dan client_email." });
      }
      const db = admin.firestore();
      await db.collection("integration_config").doc(clientId)
        .collection("secrets").doc("firebase")
        .set({ privateKey, clientEmail, projectId: fbProjectId, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
      await db.collection("integration_config").doc(clientId).set(
        { firebase: { secretSet: true, updatedAt: new Date().toISOString() } },
        { merge: true }
      );
      invalidateCache(clientId);
      return res.json({ ok: true, method: "firestore" });
    }

    // influx / mysql → Firestore subcollection (unchanged)
    const db = admin.firestore();
    await db.collection("integration_config").doc(clientId)
      .collection("secrets").doc(type)
      .set({ ...secret, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return res.json({ ok: true, method: "firestore" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /integrationConfig/loadConfigs ───────────────────────────────────────
// Returns all client configs
router.get("/loadConfigs", async (req, res) => {
  try {
    const db = admin.firestore();
    const snap = await db.collection("integration_config").get();
    const clients = snap.docs
      .filter((d) => d.id !== "app_config_active")
      .map((d) => ({ id: d.id, ...d.data() }));
    return res.json(clients);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /integrationConfig/loadSecret/:clientId/:type ────────────────────────
// Returns secret (token or password) for a client
router.get("/loadSecret/:clientId/:type", async (req, res) => {
  const { clientId, type } = req.params;
  try {
    const db = admin.firestore();
    const doc = await db.collection("integration_config").doc(clientId)
      .collection("secrets").doc(type).get();
    return res.json(doc.exists ? doc.data() : {});
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── POST /integrationConfig/setActive ────────────────────────────────────────
// Body: { clientId, clientName, siteTags }
router.post("/setActive", async (req, res) => {
  const { clientId, clientName, siteTags } = req.body;
  if (!clientId) return res.status(400).json({ error: "Missing clientId" });
  try {
    const db = admin.firestore();
    await db.collection("app_config").doc("active_integration").set({
      clientId,
      clientName: clientName || clientId,
      siteTags: siteTags || [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── DELETE /integrationConfig/deleteConfig/:clientId ─────────────────────────
router.delete("/deleteConfig/:clientId", async (req, res) => {
  const { clientId } = req.params;
  try {
    const db = admin.firestore();
    await db.collection("integration_config").doc(clientId).delete();

    // Clear active_integration if it points to this client
    const activeRef = db.collection("app_config").doc("active_integration");
    const activeSnap = await activeRef.get();
    if (activeSnap.exists && activeSnap.data()?.clientId === clientId) {
      await activeRef.delete();
    }

    // Delete secrets subcollection
    const secretTypes = ["influx", "mysql", "firebase"];
    await Promise.all(
      secretTypes.map((t) =>
        db.collection("integration_config").doc(clientId).collection("secrets").doc(t).delete()
      )
    );

    invalidateCache(clientId);
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Client Registry ───────────────────────────────────────────────────────────
// A small, manually-maintained list of {id, name} pairs that haven't been
// promoted to a full integration_config doc yet. The "Add Client" dialog
// picks from here instead of auto-generating an ID or reusing General
// Factory Setting's unrelated /factory list.

// ── GET /integrationConfig/registry ───────────────────────────────────────────
router.get("/registry", async (req, res) => {
  try {
    const db = admin.firestore();
    const snap = await db.collection("client_registry").get();
    const entries = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return res.json(entries);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── POST /integrationConfig/registry ──────────────────────────────────────────
// Body: { id: string, name: string }
router.post("/registry", async (req, res) => {
  const { id, name } = req.body;
  if (!id || !name) return res.status(400).json({ error: "Missing id or name" });
  try {
    const db = admin.firestore();
    const existing = await db.collection("integration_config").doc(id).get();
    if (existing.exists) {
      return res.status(409).json({ error: `Client ID ${id} already exists as a real client` });
    }
    await db.collection("client_registry").doc(id).set({
      name,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── DELETE /integrationConfig/registry/:id ────────────────────────────────────
router.delete("/registry/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const db = admin.firestore();
    await db.collection("client_registry").doc(id).delete();
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── POST /integrationConfig/testWrite/:clientId ──────────────────────────────
router.post("/testWrite/:clientId", async (req, res) => {
  const { clientId } = req.params;
  try {
    const { getClientFirestore } = require("../helpers/dbConnections");
    const clientDb = await getClientFirestore(clientId);
    const defaultDb = admin.firestore();
    const isClientDb = clientDb !== defaultDb;
    await clientDb.collection("factories").doc("TEST_WRITE").set({ test: true, ts: new Date().toISOString() });
    return res.json({ ok: true, isClientDb, message: isClientDb ? "Wrote to CLIENT db" : "Wrote to DEFAULT db" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /integrationConfig/debugFirebase/:clientId ───────────────────────────
router.get("/debugFirebase/:clientId", async (req, res) => {
  const { clientId } = req.params;
  try {
    const db = admin.firestore();
    const secretDoc = await db.collection("integration_config").doc(clientId)
      .collection("secrets").doc("firebase").get();
    const secret = secretDoc.exists ? secretDoc.data() : null;
    const hasPrivateKey = !!(secret && secret.privateKey);
    const hasClientEmail = !!(secret && secret.clientEmail);
    const privateKeyStart = hasPrivateKey ? secret.privateKey.substring(0, 50) : null;
    const privateKeyHasNewlines = hasPrivateKey ? secret.privateKey.includes("\n") : false;

    const { getClientFirestore } = require("../helpers/dbConnections");
    let firestoreResult = "unknown";
    try {
      const clientDb = await getClientFirestore(clientId);
      firestoreResult = clientDb === db ? "DEFAULT (fallback)" : "CLIENT DB ✓";
    } catch (e) {
      firestoreResult = `ERROR: ${e.message}`;
    }

    return res.json({ secretExists: secretDoc.exists, hasPrivateKey, hasClientEmail, privateKeyStart, privateKeyHasNewlines, firestoreResult });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
