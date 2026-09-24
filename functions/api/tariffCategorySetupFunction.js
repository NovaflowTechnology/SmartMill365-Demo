// tariff_category.js
//
// Changes from v1:
//  • Added DELETE /delete/:id with a "safe delete" guard.
//    If a masterBillingConfig sub-doc exists for this category, the endpoint
//    refuses deletion and explains that the user must choose:
//      (a) forceDelete=true  — cascade-deletes billing config too
//      (b) deactivate instead (PUT /edit/:id with status: "Inactive")

const express = require("express");
const admin = require("firebase-admin");
const { getClientFirestore, isStrictClient } = require("../helpers/dbConnections");
const router = express.Router();

// Per-client Firestore — resolves to the client's own project when
// x-client-id is set and has a Firebase secret configured, otherwise
// falls back to the default Firestore (unchanged single-tenant behaviour).
function _dbFor(req) {
  return getClientFirestore(req.headers["x-client-id"]);
}

// CENTRAL Firestore — tariff categories are government spec (TNB), so ONE
// global list lives in the default Firestore and is shared by every client.
function _centralDb() {
  return admin.firestore();
}

// The tariff list a request reads and edits: the central list for every
// client, except a strict client, which keeps its own copy so nothing it does
// can change the list other clients bill from.
async function _categoryDb(req) {
  const clientId = req && req.headers && req.headers["x-client-id"];
  return isStrictClient(clientId) ? getClientFirestore(clientId) : admin.firestore();
}

// ── GET /central-clients (inspection) ─────────────────────────────────────────
// Lists configured client ids from integration_config (id + name only).
router.get("/central-clients", async (req, res) => {
  try {
    const snap = await _centralDb().collection("integration_config").get();
    const data = snap.docs.map((doc) => ({
      id: doc.id,
      name: doc.data().name ?? doc.data().clientName ?? null,
      hasFirebase: !!doc.data().firebase,
    }));
    return res.json({ success: true, data });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── GET /central-list (inspection) ────────────────────────────────────────────
// Read-only dump of the central tariffCategory collection.
router.get("/central-list", async (req, res) => {
  try {
    const snap = await (await _categoryDb(req)).collection("tariffCategory").get();
    const data = snap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        tariffCategory: d.tariffCategory ?? null,
        tariffName: d.tariffName ?? null,
        voltageLevel: d.voltageLevel ?? null,
        voltageName: d.voltageName ?? null,
        status: d.status ?? null,
        userId: d.userId ?? null,
      };
    });
    return res.json({ success: true, count: data.length, data });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── POST /centralize-migrate ──────────────────────────────────────────────────
// One-off, idempotent migration for centralizing tariff categories:
//  1. Copies this client's tariffCategory docs into the CENTRAL list
//     (deduped by name, newest wins, PRESERVING the source doc id when the
//     name is new centrally — so existing billing-config keys keep working).
//  2. Re-keys every user's masterBillingConfig categories sub-docs and
//     appliedCategory pointer in this client's DB from old copy-ids to the
//     central ids (matched by category name).
// Run once per tenant (with/without x-client-id), then reads can be switched
// to the central list with zero visible data loss.
router.post("/centralize-migrate", async (req, res) => {
  try {
    // A strict client keeps its own tariff list; migrating it would write its
    // categories into the central list every other client bills from.
    if (isStrictClient(req.headers["x-client-id"])) {
      return res.status(403).json({
        success: false,
        message: "This client keeps its own tariff list and cannot be merged into the central one.",
      });
    }
    const central = _centralDb();
    const client = await _dbFor(req);

    const nameOf = (d) => (d.tariffCategory ?? "").toString().trim().toLowerCase();
    const tsOf = (d) => d.updatedAt?._seconds ?? d.createdAt?._seconds ?? 0;

    // Existing central docs by name
    const centralSnap = await central.collection("tariffCategory").get();
    const centralByName = new Map();
    centralSnap.docs.forEach((doc) => {
      const name = nameOf(doc.data());
      if (name && !centralByName.has(name)) centralByName.set(name, doc.id);
    });

    // Source docs (this client's copies), newest per name
    const srcSnap = await client.collection("tariffCategory").get();
    const srcByName = new Map();
    for (const doc of srcSnap.docs) {
      const row = { id: doc.id, ...doc.data() };
      const name = nameOf(row);
      if (!name) continue;
      const prev = srcByName.get(name);
      if (!prev || tsOf(row) > tsOf(prev)) srcByName.set(name, row);
    }

    // Ensure every source name exists centrally (preserve doc id when new)
    let centralCreated = 0;
    for (const [name, row] of srcByName) {
      if (!centralByName.has(name)) {
        const { id, ...payload } = row;
        await central.collection("tariffCategory").doc(id).set(payload);
        centralByName.set(name, id);
        centralCreated++;
      }
    }

    // Old client doc id -> central id (matched by name, covers ALL copies)
    const idMap = {};
    for (const doc of srcSnap.docs) {
      const name = nameOf(doc.data());
      const centralId = centralByName.get(name);
      if (centralId) idMap[doc.id] = centralId;
    }

    // Re-key billing configs + applied pointer for every user in this client
    let rekeyed = 0;
    const usersTouched = [];
    const usersSnap = await client.collection("masterBillingConfig").get();
    for (const userDoc of usersSnap.docs) {
      let touched = false;
      const catsSnap = await userDoc.ref.collection("categories").get();
      for (const catDoc of catsSnap.docs) {
        const newId = idMap[catDoc.id];
        if (newId && newId !== catDoc.id) {
          await userDoc.ref.collection("categories").doc(newId)
            .set({ ...catDoc.data(), categoryId: newId }, { merge: true });
          await catDoc.ref.delete();
          rekeyed++;
          touched = true;
        }
      }
      const applied = userDoc.data().appliedCategory;
      if (applied && idMap[applied] && idMap[applied] !== applied) {
        await userDoc.ref.update({ appliedCategory: idMap[applied] });
        touched = true;
      }
      if (touched) usersTouched.push(userDoc.id);
    }

    return res.json({
      success: true,
      sourceDocs: srcSnap.size,
      uniqueNames: srcByName.size,
      centralCreated,
      billingRekeyed: rekeyed,
      usersTouched,
    });
  } catch (error) {
    console.error("POST /centralize-migrate error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

const validatePayload = ({ voltageLevel, voltageName, tariffCategory, tariffName }) => {
  const missing = [];
  if (!voltageLevel) missing.push("voltageLevel");
  if (!voltageName) missing.push("voltageName");
  if (!tariffCategory) missing.push("tariffCategory");
  if (!tariffName) missing.push("tariffName");
  return missing;
};

const VALID_VOLTAGE_LEVELS = ["LV", "MV", "MV TOU", "HV"];

// ── GET /list ─────────────────────────────────────────────────────────────────

router.get("/list", async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId)
      return res.status(400).json({ success: false, message: "userId query param is required." });

    // Categories: CENTRAL government-spec list (same for every client/user).
    // Billing info: merged from the requesting client's own Firestore.
    const snapshot = await (await _categoryDb(req)).collection("tariffCategory").get();
    const db = await _dbFor(req);

    let data = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => (b.createdAt?._seconds ?? 0) - (a.createdAt?._seconds ?? 0));

    // ── Merge in Master Billing Config info per category ──────────────────
    // Lets the table list show whether each category has a saved billing
    // config and whether it's the currently applied one, without a second
    // round-trip from the frontend.
    const userBillingDoc = await db.collection("masterBillingConfig").doc(userId).get();
    const appliedCategory = userBillingDoc.exists ? (userBillingDoc.data().appliedCategory ?? null) : null;

    const categoriesSnap = await db.collection("masterBillingConfig").doc(userId).collection("categories").get();
    const billingById = {};
    categoriesSnap.forEach((doc) => { billingById[doc.id] = doc.data(); });

    data = data.map((row) => {
      const billing = billingById[row.id];
      return {
        ...row,
        billingConfigured: !!billing,
        isAppliedBillingConfig: appliedCategory === row.id,
        baseEnergyRate: billing?.baseEnergyRate ?? null,
        mdCapacityCharge: billing?.mdCapacityCharge ?? null,
        currentAFA: billing?.currentAFA ?? null,
      };
    });

    return res.status(200).json({ success: true, data });
  } catch (error) {
    console.error("GET /list error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── GET /list/active ──────────────────────────────────────────────────────────

router.get("/list/active", async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId)
      return res.status(400).json({ success: false, message: "userId query param is required." });

    // CENTRAL government-spec list — identical for every client and user.
    const snapshot = await (await _categoryDb(req)).collection("tariffCategory")
      .where("status", "==", "Active")
      .get();

    // Include tariffCategory/tariffName — Master Billing Config's category
    // dropdown reads them; returning only the voltage fields crashed that
    // page into a permanent loading spinner. Sorted identically to GET /list
    // (createdAt desc) so the dropdown order matches the Tariff Category
    // Setup table for the same client (e.g. Thong Guan) instead of looking
    // like a different (Danapac) dataset.
    const data = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => (b.createdAt?._seconds ?? 0) - (a.createdAt?._seconds ?? 0))
      .map((row) => ({
        id: row.id,
        voltageLevel: row.voltageLevel,
        voltageName: row.voltageName,
        tariffCategory: row.tariffCategory ?? row.voltageName ?? row.id,
        tariffName: row.tariffName ?? null,
      }));

    return res.status(200).json({ success: true, data });
  } catch (error) {
    console.error("GET /list/active error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── POST /create ──────────────────────────────────────────────────────────────

router.post("/create", async (req, res) => {
  try {
    const {
      userId,
      voltageLevel,
      voltageName,
      tariffCategory,
      tariffName,
      typicalUser = "",
      status = "Active",
    } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required." });
    }

    const missing = validatePayload({ voltageLevel, voltageName, tariffCategory, tariffName });
    if (missing.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missing.join(", ")}.`,
      });
    }

    if (!VALID_VOLTAGE_LEVELS.includes(voltageLevel)) {
      return res.status(400).json({
        success: false,
        message: `voltageLevel must be one of: ${VALID_VOLTAGE_LEVELS.join(", ")}.`,
      });
    }

    if (!["Active", "Inactive"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'status must be "Active" or "Inactive".',
      });
    }

    const db = await _categoryDb(req);

    // Central list — block duplicate category names globally.
    const dupSnap = await db.collection("tariffCategory")
      .where("tariffCategory", "==", tariffCategory.trim())
      .limit(1)
      .get();
    if (!dupSnap.empty) {
      return res.status(409).json({
        success: false,
        message: `Tariff category '${tariffCategory.trim()}' already exists.`,
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const newDoc = {
      userId,
      voltageLevel,
      voltageName: voltageName.trim(),
      tariffCategory: tariffCategory.trim(),
      tariffName: tariffName.trim(),
      typicalUser: typicalUser.trim(),
      status,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection("tariffCategory").add(newDoc);

    return res.status(201).json({
      success: true,
      message: "Tariff category created successfully.",
      data: { id: docRef.id, ...newDoc },
    });
  } catch (error) {
    console.error("POST /create error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── PUT /edit/:id ─────────────────────────────────────────────────────────────

router.put("/edit/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, voltageLevel, voltageName, tariffCategory, tariffName, typicalUser, status } =
      req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required." });
    }

    const missing = validatePayload({ voltageLevel, voltageName, tariffCategory, tariffName });
    if (missing.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missing.join(", ")}.`,
      });
    }

    if (!VALID_VOLTAGE_LEVELS.includes(voltageLevel)) {
      return res.status(400).json({
        success: false,
        message: `voltageLevel must be one of: ${VALID_VOLTAGE_LEVELS.join(", ")}.`,
      });
    }

    if (status && !["Active", "Inactive"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'status must be "Active" or "Inactive".',
      });
    }

    const db = await _categoryDb(req);
    const docRef = db.collection("tariffCategory").doc(id);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({ success: false, message: "Tariff category not found." });
    }

    // Central government-spec list — amending here updates every client.

    const updates = {
      voltageLevel,
      voltageName: voltageName.trim(),
      tariffCategory: tariffCategory.trim(),
      tariffName: tariffName.trim(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (typicalUser !== undefined) updates.typicalUser = typicalUser.trim();
    if (status !== undefined) updates.status = status;

    await docRef.update(updates);
    const updated = (await docRef.get()).data();

    return res.status(200).json({
      success: true,
      message: "Tariff category updated successfully.",
      data: { id, ...updated },
    });
  } catch (error) {
    console.error("PUT /edit/:id error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ── DELETE /delete/:id ────────────────────────────────────────────────────────
/**
 * Safe delete with billing-config guard.
 *
 * Query params:
 *   userId      (required)
 *   forceDelete (optional, "true") — cascade-deletes billing config too
 *
 * Flow:
 *  1. Verify the document exists and belongs to the user.
 *  2. Check if ANY masterBillingConfig sub-doc exists for this category id.
 *  3a. If billing config exists AND forceDelete !== "true":
 *       → 409 Conflict with a clear explanation.
 *  3b. If billing config exists AND forceDelete === "true":
 *       → Delete billing config sub-doc (and clear appliedCategory if set).
 *       → Then delete the tariffCategory doc.
 *  4. If no billing config: just delete the tariffCategory doc.
 */
router.delete("/delete/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, forceDelete } = req.query;

    if (!userId) {
      return res.status(400).json({ success: false, message: "userId query param is required." });
    }

    // Category doc lives in the CENTRAL list; the billing-config guard and
    // cascade run against the requesting client's own Firestore.
    const db = await _dbFor(req);
    const docRef = (await _categoryDb(req)).collection("tariffCategory").doc(id);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({ success: false, message: "Tariff category not found." });
    }

    // ── Check for linked billing configs across ALL user docs ─────────────
    // A tariffCategory doc-id can appear as a sub-doc key in any user's
    // masterBillingConfig/categories sub-collection.  For a single-user app
    // (same userId for both), we only need to check that user's doc.
    const billingCatRef = db.collection("masterBillingConfig")
      .doc(userId)
      .collection("categories")
      .doc(id);

    const billingSnap = await billingCatRef.get();
    const hasBillingData = billingSnap.exists;

    if (hasBillingData && forceDelete !== "true") {
      // Block deletion — inform the caller of their options
      return res.status(409).json({
        success: false,
        message:
          `Cannot delete: billing configuration data exists for category '${id}'. ` +
          `Either (a) deactivate the category instead via PUT /edit/${id}, or ` +
          `(b) confirm cascade deletion by adding ?forceDelete=true to this request.`,
        categoryId: id,
        hasBillingData: true,
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    if (hasBillingData) {
      // Cascade in the client's DB: delete the billing config sub-doc and
      // clear appliedCategory if it pointed at this category.
      const batch = db.batch();
      batch.delete(billingCatRef);

      const userBillingDoc = await db.collection("masterBillingConfig").doc(userId).get();
      if (userBillingDoc.exists && userBillingDoc.data().appliedCategory === id) {
        batch.update(db.collection("masterBillingConfig").doc(userId), {
          appliedCategory: null,
          updatedAt: now,
        });
      }
      await batch.commit();
    }

    // Delete the tariffCategory document itself (central list — separate
    // Firestore instance, so it cannot share a batch with the client's DB).
    await docRef.delete();

    return res.status(200).json({
      success: true,
      message: hasBillingData
        ? `Tariff category and its linked billing config deleted (force).`
        : `Tariff category deleted.`,
      id,
      billingConfigAlsoDeleted: hasBillingData,
    });
  } catch (error) {
    console.error("DELETE /delete/:id error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;