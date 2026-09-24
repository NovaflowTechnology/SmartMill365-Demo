const express = require("express");
const admin = require("firebase-admin");
const { getClientFirestore } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// ── Helpers ────────────────────────────────────────────────────────────────────

const IC7_BASE = "https://api-ic7ypg6ukq-uc.a.run.app";

/**
 * Serialize a Firestore document into a plain JSON-safe object.
 * Converts Timestamps to ISO strings so the Flutter client can parse them.
 */
function serializeFactor(id, data) {
  return {
    id,
    fiscal_year: data.fiscal_year,
    factor: data.factor ?? null,
    source: data.source ?? "",
    carbon_cost: data.carbon_cost ?? null,
    source_chip_label: data.source_chip_label ?? null,
    published_date: data.published_date
      ? data.published_date.toDate().toISOString()
      : null,
    effective_from: data.effective_from
      ? data.effective_from.toDate().toISOString()
      : null,
    status: data.status ?? "draft",
    is_restated: data.is_restated ?? false,
    is_pending: data.is_pending ?? false,
    document_reference: data.document_reference ?? null,
    notes: data.notes ?? null,
    created_at: data.created_at ? data.created_at.toDate().toISOString() : null,
    updated_at: data.updated_at ? data.updated_at.toDate().toISOString() : null,
    created_by: data.created_by ?? "",
  };
}

function serializeAudit(id, data) {
  return {
    id,
    timestamp: data.timestamp ? data.timestamp.toDate().toISOString() : null,
    action: data.action ?? "",
    fiscal_year: data.fiscal_year,
    from_value: data.from_value ?? null,
    to_value: data.to_value ?? null,
    actor: data.actor ?? "",
  };
}

/**
 * Write a single audit log entry to emission_factor_audits.
 */
async function writeAuditTo(auditCollection, { action, fiscalYear, fromValue, toValue, actor, timestamp }) {
  const entry = {
    timestamp: timestamp
      ? admin.firestore.Timestamp.fromDate(new Date(timestamp))
      : admin.firestore.FieldValue.serverTimestamp(),
    action,
    fiscal_year: fiscalYear,
    actor,
  };
  if (fromValue !== undefined && fromValue !== null) entry.from_value = fromValue;
  if (toValue !== undefined && toValue !== null) entry.to_value = toValue;
  await auditCollection.add(entry);
}

/**
 * If UI7 Firestore has no emission factors yet, fall back to IC7 API
 * (where Emission Factor Management currently writes).
 * Note: IC7's ?status=active may require a Firestore composite index, so we
 * always fetch the full list and filter in memory.
 */
async function fetchFromIc7({ status }) {
  try {
    const res = await fetch(`${IC7_BASE}/emission-factors`, { method: "GET" });
    if (!res.ok) return [];
    const list = await res.json();
    if (!Array.isArray(list)) return [];
    const filtered = status ? list.filter((x) => x && x.status === status) : list;
    return filtered
      .slice()
      .sort((a, b) => (Number(b.fiscal_year) || 0) - (Number(a.fiscal_year) || 0));
  } catch (_) {
    return [];
  }
}

// ── GET /emission-factors ──────────────────────────────────────────────────────
// Query params: ?status=draft|active|locked
router.get("/", async (req, res) => {
  try {
    const { status } = req.query;
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");

    // Avoid Firestore composite index requirement on (status + fiscal_year).
    // When filtering by status, query without orderBy and sort in memory.
    const snapshot = status
      ? await emissionFactorCollection.where("status", "==", status).get()
      : await emissionFactorCollection.orderBy("fiscal_year", "desc").get();
    const factors = snapshot.docs
      .map((doc) => serializeFactor(doc.id, doc.data()))
      .sort((a, b) => (Number(b.fiscal_year) || 0) - (Number(a.fiscal_year) || 0));

    if (factors.length === 0) {
      const ic7 = await fetchFromIc7({ status });
      return res.status(200).json(ic7);
    }

    return res.status(200).json(factors);
  } catch (error) {
    console.error("Error fetching emission factors:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── GET /emission-factors/audits ───────────────────────────────────────────────
// Must be defined before /:id to avoid route shadowing.
// Query params: ?limit=50
router.get("/audits", async (req, res) => {
  try {
    const limitVal = parseInt(req.query.limit) || 100;
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const auditCollection = clientDb.collection("emission_factor_audits");
    const snapshot = await auditCollection
      .orderBy("timestamp", "desc")
      .limit(limitVal)
      .get();
    const entries = snapshot.docs.map((doc) => serializeAudit(doc.id, doc.data()));
    res.status(200).json(entries);
  } catch (error) {
    console.error("Error fetching audit log:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── GET /emission-factors/:id ──────────────────────────────────────────────────
router.get("/:id", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const doc = await emissionFactorCollection.doc(req.params.id).get();
    if (!doc.exists) {
      // If not found in UI7 tenant/default, try IC7 (legacy store)
      const ic7 = await fetchFromIc7({ status: null });
      const found = ic7.find((x) => x && x.id === req.params.id);
      if (found) return res.status(200).json(found);
      return res.status(404).json({ error: "Emission factor not found" });
    }
    res.status(200).json(serializeFactor(doc.id, doc.data()));
  } catch (error) {
    console.error("Error fetching emission factor:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── POST /emission-factors/add ─────────────────────────────────────────────────
// Body: { fiscal_year, factor, source, source_chip_label?, published_date,
//         effective_from, status, document_reference, notes?, actor }
router.post("/add", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const auditCollection = clientDb.collection("emission_factor_audits");

    const {
      fiscal_year,
      factor,
      source,
      carbon_cost,
      source_chip_label,
      published_date,
      effective_from,
      status,
      document_reference,
      notes,
      actor,
    } = req.body;

    if (!fiscal_year || factor === undefined || !source || !document_reference) {
      return res.status(400).json({
        error: "fiscal_year, factor, source, and document_reference are required.",
      });
    }

    const docId = `fy${fiscal_year}`;
    const existing = await emissionFactorCollection.doc(docId).get();
    if (existing.exists) {
      return res.status(400).json({
        error: `Emission factor for FY${fiscal_year} already exists. Use PUT /${docId} to update.`,
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const newFactor = {
      fiscal_year,
      factor,
      source,
      carbon_cost: carbon_cost !== undefined ? carbon_cost : null,
      source_chip_label: source_chip_label || `ST Malaysia ${fiscal_year}`,
      published_date: published_date
        ? admin.firestore.Timestamp.fromDate(new Date(published_date))
        : null,
      effective_from: effective_from
        ? admin.firestore.Timestamp.fromDate(new Date(effective_from))
        : admin.firestore.Timestamp.fromDate(new Date(`${fiscal_year}-01-01`)),
      status: status || "draft",
      is_restated: false,
      is_pending: false,
      document_reference,
      notes: notes || null,
      created_at: now,
      updated_at: now,
      created_by: actor || "",
    };

    // If activating, lock any currently active factor first.
    if (status === "active") {
      await _lockCurrentActive(emissionFactorCollection, fiscal_year, null);
    }

    await emissionFactorCollection.doc(docId).set(newFactor);

    await writeAuditTo(auditCollection, {
      action: status === "active" ? "activated" : "created",
      fiscalYear: fiscal_year,
      toValue: factor,
      actor: actor || "",
    });

    res.status(201).json({ success: true, id: docId });
  } catch (error) {
    console.error("Error adding emission factor:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── PUT /emission-factors/:id ──────────────────────────────────────────────────
// Partial update. Body fields are optional except where noted.
router.put("/:id", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const auditCollection = clientDb.collection("emission_factor_audits");

    const docRef = emissionFactorCollection.doc(req.params.id);
    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: "Emission factor not found" });
    }

    const {
      factor,
      source,
      carbon_cost,
      source_chip_label,
      published_date,
      effective_from,
      document_reference,
      notes,
      actor,
    } = req.body;

    const prevData = doc.data();
    const updates = { updated_at: admin.firestore.FieldValue.serverTimestamp() };

    if (factor !== undefined) updates.factor = factor;
    if (source !== undefined) updates.source = source;
    if (carbon_cost !== undefined) updates.carbon_cost = carbon_cost;
    if (source_chip_label !== undefined) updates.source_chip_label = source_chip_label;
    if (published_date !== undefined) {
      updates.published_date = admin.firestore.Timestamp.fromDate(new Date(published_date));
    }
    if (effective_from !== undefined) {
      updates.effective_from = admin.firestore.Timestamp.fromDate(new Date(effective_from));
    }
    if (document_reference !== undefined) updates.document_reference = document_reference;
    if (notes !== undefined) updates.notes = notes;

    // Mark as restated if an active factor's value is being changed.
    if (prevData.status === "active" && factor !== undefined && factor !== prevData.factor) {
      updates.is_restated = true;
    }

    await docRef.update(updates);

    await writeAuditTo(auditCollection, {
      action: "updated",
      fiscalYear: prevData.fiscal_year,
      fromValue: prevData.factor,
      toValue: factor !== undefined ? factor : prevData.factor,
      actor: actor || "",
    });

    res.status(200).json({ success: true, id: req.params.id });
  } catch (error) {
    console.error("Error updating emission factor:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── PUT /emission-factors/:id/activate ────────────────────────────────────────
// Atomically locks any current active factor, then activates the target draft.
// Body: { actor }
router.put("/:id/activate", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const auditCollection = clientDb.collection("emission_factor_audits");

    const { actor } = req.body;
    const docRef = emissionFactorCollection.doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: "Emission factor not found" });
    }

    const data = doc.data();
    if (data.status !== "draft") {
      return res.status(400).json({
        error: `Only draft factors can be activated. Current status: ${data.status}`,
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    await clientDb.runTransaction(async (tx) => {
      // Lock all currently active factors.
      const activeSnap = await emissionFactorCollection
        .where("status", "==", "active")
        .get();

      for (const activeDoc of activeSnap.docs) {
        tx.update(activeDoc.ref, {
          status: "locked",
          is_restated: true,
          updated_at: now,
        });
      }

      // Activate the target draft.
      tx.update(docRef, { status: "active", updated_at: now });
    });

    // Write auto-lock audit entries for displaced active factors.
    const lockedSnap = await emissionFactorCollection
      .where("status", "==", "locked")
      .where("fiscal_year", "!=", data.fiscal_year)
      .orderBy("fiscal_year", "desc")
      .limit(1)
      .get();

    if (!lockedSnap.empty) {
      const lockedData = lockedSnap.docs[0].data();
      await writeAuditTo(auditCollection, {
        action: "autoLocked",
        fiscalYear: lockedData.fiscal_year,
        actor: "System",
      });
    }

    await writeAuditTo(auditCollection, {
      action: "activated",
      fiscalYear: data.fiscal_year,
      toValue: data.factor,
      actor: actor || "",
    });

    res.status(200).json({ success: true, id: req.params.id });
  } catch (error) {
    console.error("Error activating emission factor:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── DELETE /emission-factors/:id ───────────────────────────────────────────────
router.delete("/:id", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const auditCollection = clientDb.collection("emission_factor_audits");

    const { actor } = req.body;
    const docRef = emissionFactorCollection.doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: "Emission factor not found" });
    }

    const data = doc.data();
    await docRef.delete();

    await writeAuditTo(auditCollection, {
      action: "deactivated",
      fiscalYear: data.fiscal_year,
      fromValue: data.factor,
      actor: actor || "",
    });

    res.status(200).json({
      message: "Emission factor deleted successfully",
      id: req.params.id,
    });
  } catch (error) {
    console.error("Error deleting emission factor:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── DELETE /emission-factors/clear-all ────────────────────────────────────────
// Deletes every document in emission_factors and emission_factor_audits.
// Protected: only allowed when the request body contains { confirm: "CLEAR_ALL" }.
router.delete("/clear-all", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const auditCollection = clientDb.collection("emission_factor_audits");

    if (req.body?.confirm !== "CLEAR_ALL") {
      return res
        .status(400)
        .json({ error: 'Body must contain { "confirm": "CLEAR_ALL" }.' });
    }

    const deleteCollection = async (colRef) => {
      const snap = await colRef.get();
      const batch = clientDb.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      if (snap.size > 0) await batch.commit();
      return snap.size;
    };

    const [factorCount, auditCount] = await Promise.all([
      deleteCollection(emissionFactorCollection),
      deleteCollection(auditCollection),
    ]);

    res.status(200).json({
      success: true,
      deleted: { factors: factorCount, auditEntries: auditCount },
    });
  } catch (error) {
    console.error("Error clearing emission factor data:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── POST /emission-factors/seed ────────────────────────────────────────────────
// Seeds initial mock data if the collection is empty.
// Body: { actor, factors: [...], auditEntries: [...] }
router.post("/seed", async (req, res) => {
  try {
    const clientDb = await getClientFirestore(req.headers["x-client-id"] || null);
    const emissionFactorCollection = clientDb.collection("emission_factors");
    const auditCollection = clientDb.collection("emission_factor_audits");

    const count = (await emissionFactorCollection.count().get()).data().count;
    if (count > 0) {
      return res.status(200).json({ message: "Already seeded — no action taken.", count });
    }

    const { actor = "system", factors = [], auditEntries = [] } = req.body;

    if (factors.length === 0) {
      return res.status(400).json({ error: "factors array is required." });
    }

    const batch = clientDb.batch();
    const now = admin.firestore.Timestamp.now();

    for (const f of factors) {
      const docRef = emissionFactorCollection.doc(`fy${f.fiscal_year}`);
      batch.set(docRef, {
        fiscal_year: f.fiscal_year,
        factor: f.factor ?? null,
        source: f.source ?? "",
        carbon_cost: f.carbon_cost ?? null,
        source_chip_label: f.source_chip_label ?? null,
        published_date: f.published_date
          ? admin.firestore.Timestamp.fromDate(new Date(f.published_date))
          : null,
        effective_from: f.effective_from
          ? admin.firestore.Timestamp.fromDate(new Date(f.effective_from))
          : admin.firestore.Timestamp.fromDate(new Date(`${f.fiscal_year}-01-01`)),
        status: f.status ?? "draft",
        is_restated: f.is_restated ?? false,
        is_pending: f.is_pending ?? false,
        document_reference: f.document_reference ?? null,
        notes: f.notes ?? null,
        created_at: now,
        updated_at: now,
        created_by: actor,
      });
    }
    await batch.commit();

    for (const entry of auditEntries) {
      await writeAuditTo(auditCollection, {
        action: entry.action,
        fiscalYear: entry.fiscal_year,
        fromValue: entry.from_value,
        toValue: entry.to_value,
        actor: entry.actor,
        timestamp: entry.timestamp,
      });
    }

    res.status(201).json({ success: true, seeded: factors.length });
  } catch (error) {
    console.error("Error seeding emission factors:", error);
    res.status(500).json({ error: error.message });
  }
});

// ── Private helpers ────────────────────────────────────────────────────────────

/**
 * Lock all currently active factors (excluding the one being activated).
 */
async function _lockCurrentActive(emissionFactorCollection, excludingFiscalYear, tx) {
  const activeSnap = await emissionFactorCollection
    .where("status", "==", "active")
    .get();
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const activeDoc of activeSnap.docs) {
    if (activeDoc.data().fiscal_year !== excludingFiscalYear) {
      if (tx) {
        tx.update(activeDoc.ref, { status: "locked", is_restated: true, updated_at: now });
      } else {
        await activeDoc.ref.update({ status: "locked", is_restated: true, updated_at: now });
      }
    }
  }
}

module.exports = router;
