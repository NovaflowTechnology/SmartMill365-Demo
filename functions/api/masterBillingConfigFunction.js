// master_billing_config.js
//
// Changes from v1:
//  • VALID_CATEGORIES constant removed — category is now a tariffCategory doc-id
//    (any non-empty slug accepted at the router level).
//  • validateCategory now only checks the string is non-empty & safe.
//  • Added DELETE /:userId/:categoryId so Flutter can clean up orphaned configs.
//  • Added cross-check helper _categoryExists() used by the /apply route to
//    verify the tariffCategory is still active before applying.
//  • Added GET/POST /:userId/electricityTariff for electricity tariff settings.

const express = require("express");
const admin = require("firebase-admin");
const { getClientFirestore, isStrictDb } = require("../helpers/dbConnections");

const router = express.Router();

// Per-client Firestore — resolves to the client's own project when
// x-client-id is set and has a Firebase secret configured, otherwise
// falls back to the default Firestore (unchanged single-tenant behaviour).
function _dbFor(req) {
  return getClientFirestore(req.headers["x-client-id"]);
}

// ── Field list ────────────────────────────────────────────────────────────────

const REQUIRED_FIELDS = [
  "mdCapacityCharge",
  "mdCapacityUnit",
  "mdNetworkCharge",
  "mdNetworkUnit",
  "retailCharge",
  "baseEnergyRate",
  "currentAFA",
  "minMonthlyCharge",
  "targetThreshold",
  "tier1Rate",
  "tier2Trigger",
  "tier2Rate",
  "kwtbb",
  "sst",
  "cycleEffectiveDate",
];

// ── Electricity Tariff Fields ─────────────────────────────────────────────────

const ELECTRICITY_TARIFF_FIELDS = [
  "peakRate",
  "normalRate",
  "offPeakRate",
  "capacityRate",
];

// ── Validation ────────────────────────────────────────────────────────────────

function validateCategory(req, res, next) {
  const { category } = req.params;
  if (!category || typeof category !== "string" || category.trim().length === 0) {
    return res.status(400).json({ error: "Invalid category id." });
  }
  if (!/^[\w-]+$/.test(category)) {
    return res.status(400).json({
      error: "Category id may only contain letters, numbers, underscores and hyphens.",
    });
  }
  next();
}

function validateTariffBody(req, res, next) {
  const missing = REQUIRED_FIELDS.filter((f) => req.body[f] === undefined);
  if (missing.length > 0) {
    return res.status(400).json({ error: "Missing required fields", missing });
  }
  next();
}

function sanitizeTariff(body) {
  const config = {};
  REQUIRED_FIELDS.forEach((f) => {
    config[f] = String(body[f]).trim();
  });
  return config;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const userDocRef = (db, userId) => db.collection("masterBillingConfig").doc(userId);
const categoryRef = (db, userId, category) =>
  userDocRef(db, userId).collection("categories").doc(category);

// Tariff categories are a CENTRAL government-spec list in the default
// Firestore (shared by all clients) — always check existence/status there.
async function _categoryStatus(db, categoryId) {
  try {
    // A strict client validates against its own tariff list, never the central one.
    const listDb = isStrictDb(db) ? db : admin.firestore();
    const snap = await listDb.collection("tariffCategory").doc(categoryId).get();
    if (!snap.exists) return { exists: false, isActive: false };
    const status = snap.data().status ?? "Active";
    return { exists: true, isActive: status === "Active" };
  } catch (_) {
    return { exists: true, isActive: true };
  }
}

// ── Routes ────────────────────────────────────────────────────────────────────

// Must match AppConfig.sharedConfigOwnerId in lib/services/app_config.dart.
const SHARED_CONFIG_OWNER_ID = "shared";

/**
 * POST /masterBillingConfig/migrate-to-shared
 * Body: { sourceUserId }
 *
 * One-off migration: billing config used to be scoped per individual
 * Firebase-Auth login (masterBillingConfig/{uid}); every page now reads/
 * writes a single client-wide doc instead (masterBillingConfig/shared —
 * see AppConfig.sharedConfigOwnerId). This copies one source account's
 * existing categories + electricityTariff + appliedCategory into that
 * shared doc. Non-destructive — the source doc is left untouched, so it's
 * safe to re-run. No auth, matching this codebase's other one-off
 * migration/backfill routes (e.g. tariffCategorySetupFunction.js's
 * /centralize-migrate) — delete this route once you've run it.
 */
router.post("/migrate-to-shared", async (req, res) => {
  try {
    const sourceUserId = (req.body && req.body.sourceUserId) || req.query.sourceUserId;
    if (!sourceUserId) {
      return res.status(400).json({ error: "sourceUserId is required." });
    }
    if (sourceUserId === SHARED_CONFIG_OWNER_ID) {
      return res.status(400).json({ error: "sourceUserId is already the shared owner id." });
    }

    const db = await _dbFor(req);
    const sourceRef = userDocRef(db, sourceUserId);
    const sharedRef = userDocRef(db, SHARED_CONFIG_OWNER_ID);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const summary = { categoriesCopied: 0, electricityTariffCopied: false, appliedCategoryCopied: false };

    // Categories
    const categoriesSnap = await sourceRef.collection("categories").get();
    for (const doc of categoriesSnap.docs) {
      await sharedRef.collection("categories").doc(doc.id).set(doc.data(), { merge: true });
      summary.categoriesCopied += 1;
    }

    // Electricity tariff
    const tariffDoc = await sourceRef.collection("settings").doc("electricityTariff").get();
    if (tariffDoc.exists) {
      await sharedRef.collection("settings").doc("electricityTariff").set(tariffDoc.data(), { merge: true });
      summary.electricityTariffCopied = true;
    }

    // Applied category marker
    const sourceDoc = await sourceRef.get();
    const appliedCategory = sourceDoc.exists ? sourceDoc.data().appliedCategory : null;
    if (appliedCategory) {
      await sharedRef.set({ appliedCategory, updatedAt: now }, { merge: true });
      summary.appliedCategoryCopied = true;
    } else {
      await sharedRef.set({ updatedAt: now }, { merge: true });
    }

    res.status(200).json({ message: "Migrated to shared billing config.", sourceUserId, ...summary });
  } catch (err) {
    console.error("POST /migrate-to-shared error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /masterBillingConfig/:userId
 * Returns all saved category configs for a user.
 */
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const db = await _dbFor(req);
    const snapshot = await userDocRef(db, userId).collection("categories").get();

    if (snapshot.empty) {
      return res.status(404).json({
        error: "No billing config found for this user",
        userId,
      });
    }

    const result = {};
    snapshot.forEach((doc) => {
      result[doc.id] = doc.data();
    });

    res.json({ userId, categories: result });
  } catch (err) {
    console.error("GET /:userId error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ── Electricity Tariff Routes (registered BEFORE /:userId/:category) ──────────

/**
 * GET /masterBillingConfig/:userId/electricityTariff
 */
router.get("/:userId/electricityTariff", async (req, res) => {
  try {
    const { userId } = req.params;
    const db = await _dbFor(req);
    const doc = await userDocRef(db, userId)
      .collection("settings")
      .doc("electricityTariff")
      .get();

    if (!doc.exists) {
      return res.status(404).json({
        error: "No electricity tariff settings found",
        userId,
      });
    }

    res.json(doc.data());
  } catch (err) {
    console.error("GET /:userId/electricityTariff error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * POST /masterBillingConfig/:userId/electricityTariff
 * Body: { peakRate, normalRate, offPeakRate, capacityRate }
 */
router.post("/:userId/electricityTariff", async (req, res) => {
  try {
    const { userId } = req.params;
    const db = await _dbFor(req);

    const provided = ELECTRICITY_TARIFF_FIELDS.filter(
      (f) => req.body[f] !== undefined
    );
    if (provided.length === 0) {
      return res.status(400).json({
        error: "At least one tariff field is required",
        validFields: ELECTRICITY_TARIFF_FIELDS,
      });
    }

    const config = {};
    for (const f of provided) {
      const val = parseFloat(req.body[f]);
      if (isNaN(val) || val < 0) {
        return res.status(400).json({
          error: `'${f}' must be a non-negative number`,
          received: req.body[f],
        });
      }
      config[f] = val;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();

    batch.set(userDocRef(db, userId), { updatedAt: now }, { merge: true });
    batch.set(
      userDocRef(db, userId).collection("settings").doc("electricityTariff"),
      { ...config, updatedAt: now },
      { merge: true }
    );

    await batch.commit();

    res.status(201).json({
      message: "Electricity tariff settings saved successfully",
      userId,
      config,
    });
  } catch (err) {
    console.error("POST /:userId/electricityTariff error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ── Applied Category Routes (registered BEFORE /:userId/:category) ────────────

/**
 * GET /masterBillingConfig/:userId/applied
 */
router.get("/:userId/applied", async (req, res) => {
  try {
    const { userId } = req.params;
    const db = await _dbFor(req);
    const userDoc = await userDocRef(db, userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        error: "No billing config found for this user",
        userId,
        appliedCategory: null,
        config: null,
      });
    }

    const appliedCategory = userDoc.data().appliedCategory ?? null;
    if (!appliedCategory) {
      return res.json({ userId, appliedCategory: null, config: null });
    }

    const catDoc = await categoryRef(db, userId, appliedCategory).get();
    if (!catDoc.exists) {
      return res.status(404).json({
        error: `Applied category '${appliedCategory}' config no longer exists`,
        userId,
        appliedCategory,
        config: null,
      });
    }

    res.json({ userId, appliedCategory, config: catDoc.data() });
  } catch (err) {
    console.error("GET /:userId/applied error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * DELETE /masterBillingConfig/:userId/applied
 * Clears the applied category.
 */
router.delete("/:userId/applied", async (req, res) => {
  try {
    const { userId } = req.params;
    const db = await _dbFor(req);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await userDocRef(db, userId).set(
      { appliedCategory: null, updatedAt: now },
      { merge: true }
    );

    res.json({ message: "Applied category cleared", userId, appliedCategory: null });
  } catch (err) {
    console.error("DELETE /:userId/applied error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /masterBillingConfig/:userId/active
 */
router.get("/:userId/active", async (req, res) => {
  try {
    const { userId } = req.params;
    const db = await _dbFor(req);
    const userDoc = await userDocRef(db, userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        error: "No billing config found for this user",
        userId,
        appliedCategory: null,
        appliedCategoryName: null,
        config: null,
      });
    }

    const appliedCategory = userDoc.data().appliedCategory ?? null;

    if (!appliedCategory) {
      return res.json({
        userId,
        appliedCategory: null,
        appliedCategoryName: null,
        config: null,
      });
    }

    const [catDoc, tariffCatSnap] = await Promise.all([
      categoryRef(db, userId, appliedCategory).get(),
      // Category names come from the central government-spec list.
      (isStrictDb(db) ? db : admin.firestore()).collection("tariffCategory").doc(appliedCategory).get(),
    ]);

    if (!catDoc.exists) {
      return res.status(404).json({
        error: `Applied category '${appliedCategory}' config no longer exists`,
        userId,
        appliedCategory,
        appliedCategoryName: null,
        config: null,
      });
    }

    const appliedCategoryName = tariffCatSnap.exists
      ? (tariffCatSnap.data().tariffCategory ?? appliedCategory)
      : appliedCategory;

    res.json({
      userId,
      appliedCategory,
      appliedCategoryName,
      config: catDoc.data(),
    });
  } catch (err) {
    console.error("GET /:userId/active error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ── Category-param Routes ─────────────────────────────────────────────────────

/**
 * GET /masterBillingConfig/:userId/:category
 */
router.get("/:userId/:category", validateCategory, async (req, res) => {
  try {
    const { userId, category } = req.params;
    const db = await _dbFor(req);
    const doc = await categoryRef(db, userId, category).get();

    if (!doc.exists) {
      return res.status(404).json({
        error: `No config found for category '${category}'`,
        userId,
        category,
      });
    }

    res.json({ userId, category, config: doc.data() });
  } catch (err) {
    console.error("GET /:userId/:category error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * POST /masterBillingConfig/:userId/:category
 * Creates or fully overwrites one category config.
 */
router.post(
  "/:userId/:category",
  validateCategory,
  validateTariffBody,
  async (req, res) => {
    try {
      const { userId, category } = req.params;
      const db = await _dbFor(req);

      const catStatus = await _categoryStatus(db, category);
      if (!catStatus.exists) {
        return res.status(404).json({
          error: `Tariff category '${category}' does not exist. Create it first.`,
        });
      }
      if (!catStatus.isActive) {
        return res.status(409).json({
          error: `Tariff category '${category}' is inactive. Re-activate it before saving a billing config.`,
        });
      }

      const config = sanitizeTariff(req.body);
      const now = admin.firestore.FieldValue.serverTimestamp();

      const batch = db.batch();
      batch.set(userDocRef(db, userId), { updatedAt: now }, { merge: true });
      batch.set(categoryRef(db, userId, category), {
        ...config,
        categoryId: category,
        createdAt: now,
        updatedAt: now,
      });
      await batch.commit();

      res.status(201).json({
        message: `Config for '${category}' created successfully`,
        userId,
        category,
        config,
      });
    } catch (err) {
      console.error("POST /:userId/:category error:", err);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

/**
 * PUT /masterBillingConfig/:userId/:category
 * Partial update.
 */
router.put("/:userId/:category", validateCategory, async (req, res) => {
  try {
    const { userId, category } = req.params;
    const db = await _dbFor(req);
    const ref = categoryRef(db, userId, category);

    const existing = await ref.get();
    if (!existing.exists) {
      return res.status(404).json({
        error: `No config found for category '${category}'. Use POST to create it first.`,
        userId,
        category,
      });
    }

    const updates = {};
    REQUIRED_FIELDS.forEach((f) => {
      if (req.body[f] !== undefined) {
        updates[f] = String(req.body[f]).trim();
      }
    });

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        error: "No valid fields provided for update",
        validFields: REQUIRED_FIELDS,
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    updates.updatedAt = now;

    const batch = db.batch();
    batch.update(userDocRef(db, userId), { updatedAt: now });
    batch.update(ref, updates);
    await batch.commit();

    res.json({
      message: `Config for '${category}' updated successfully`,
      userId,
      category,
      updatedFields: Object.keys(updates).filter((k) => k !== "updatedAt"),
    });
  } catch (err) {
    console.error("PUT /:userId/:category error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * DELETE /masterBillingConfig/:userId/:category
 * Removes billing config for one category.
 * If this category is currently applied, also clears appliedCategory.
 */
router.delete("/:userId/:category", validateCategory, async (req, res) => {
  try {
    const { userId, category } = req.params;
    const db = await _dbFor(req);
    const ref = categoryRef(db, userId, category);

    const existing = await ref.get();
    if (!existing.exists) {
      return res.status(404).json({
        error: `No config found for category '${category}'`,
        userId,
        category,
      });
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();
    batch.delete(ref);

    const userDoc = await userDocRef(db, userId).get();
    if (userDoc.exists && userDoc.data().appliedCategory === category) {
      batch.update(userDocRef(db, userId), {
        appliedCategory: null,
        updatedAt: now,
      });
    } else {
      batch.set(userDocRef(db, userId), { updatedAt: now }, { merge: true });
    }

    await batch.commit();

    res.json({
      message: `Config for '${category}' deleted`,
      userId,
      category,
    });
  } catch (err) {
    console.error("DELETE /:userId/:category error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * POST /masterBillingConfig/:userId/:category/apply
 * Marks one category as the active billing config.
 */
router.post("/:userId/:category/apply", validateCategory, async (req, res) => {
  try {
    const { userId, category } = req.params;
    const db = await _dbFor(req);

    const catDoc = await categoryRef(db, userId, category).get();
    if (!catDoc.exists) {
      return res.status(404).json({
        error: `No saved config found for '${category}'. Save it first before applying.`,
        userId,
        category,
      });
    }

    const catStatus = await _categoryStatus(db, category);
    if (!catStatus.exists) {
      return res.status(409).json({
        error: `Tariff category '${category}' has been deleted and cannot be applied.`,
        userId,
        category,
      });
    }
    if (!catStatus.isActive) {
      return res.status(409).json({
        error: `Tariff category '${category}' is inactive and cannot be applied.`,
        userId,
        category,
      });
    }

    const userDoc = await userDocRef(db, userId).get();
    const previousCategory = userDoc.exists
      ? (userDoc.data().appliedCategory ?? null)
      : null;

    const now = admin.firestore.FieldValue.serverTimestamp();
    await userDocRef(db, userId).set(
      { appliedCategory: category, updatedAt: now },
      { merge: true }
    );

    res.json({
      message: `Category '${category}' is now the active billing config`,
      userId,
      appliedCategory: category,
      previousCategory,
    });
  } catch (err) {
    console.error("POST /:userId/:category/apply error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;