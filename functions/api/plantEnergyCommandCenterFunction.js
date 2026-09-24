const express = require("express");
const admin = require("firebase-admin");
const {withDbFallback} = require("../helpers/dbConnections");
const {autoProvisionPecc} = require("../helpers/peccAutoConfig");

// eslint-disable-next-line new-cap
const router = express.Router();
const COLLECTION = "plantEnergyCommandCenterSettings";

// Config is stored per user AND per plant. The document id is:
//   "<uid>"              → the "All plants" / group config (backward compatible)
//   "<uid>__<plantId>"   → a specific plant's config (e.g. Lot 237)
// so each plant keeps its own independent dashboard configuration.
function docIdFor(uid, plantId) {
  // Keep original casing — production docs use e.g. "uid__Lot 237 Block B".
  const pid = (plantId || "").toString().trim();
  return pid ? `${uid}__${pid}` : uid;
}

// The distinct, non-empty pin display names on a group doc (or {} — GET's
// notFound shape has no .pins). Used to diff a save's pins[] against what
// was there before, so a pin's own dashboard is created or torn down with it.
function previousPinNames(doc) {
  const pins = (doc && Array.isArray(doc.pins)) ? doc.pins : [];
  const names = pins
    .map((p) => (p && p.displayName ? p.displayName.toString().trim() : ""))
    .filter((n) => n.length > 0);
  return [...new Set(names)];
}

// ── GET /:uid ─ Load settings for a user (optionally scoped to ?plantId=) ──────
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    const plantId = (req.query.plantId || "").toString().trim();

    if (!uid || uid.trim() === "") {
      return res.status(400).json({success: false, error: "User ID is required"});
    }

    const docId = docIdFor(uid, plantId);
    const result = await withDbFallback(req, async (db) => {
      const snap = await db.collection(COLLECTION).doc(docId).get();
      if (snap.exists) return {settings: {id: snap.id, ...snap.data()}};

      // The doc id embeds the plant NAME exactly as the settings page saw it in
      // the /factory list, while the viewer only knows the name from its nav
      // link. If those differ only by case or spacing (e.g. "LOT 48" saved vs
      // "Lot 48" requested) the exact-id read misses and the dashboard renders
      // completely blank. Fall back to matching the stored plantId loosely.
      if (plantId) {
        const norm = (s) => (s || "").toString().trim().toLowerCase().replace(/\s+/g, " ");
        const wanted = norm(plantId);
        const candidates = await db.collection(COLLECTION).where("uid", "==", uid).get();
        const hit = candidates.docs.find((d) => norm(d.data().plantId) === wanted);
        if (hit) return {settings: {id: hit.id, ...hit.data()}};
      }
      return {notFound: true};
    });

    if (!result || result.notFound) {
      return res.status(200).json({success: true, exists: false, settings: null});
    }

    return res.status(200).json({success: true, exists: true, settings: result.settings});
  } catch (error) {
    console.error("[plantEnergyCommandCenter] GET error:", error.message);
    return res.status(500).json({success: false, error: error.message});
  }
});

// ── POST /:uid ─ Save / update settings for a user ────────────────────────────
router.post("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    const clientId = req.headers["x-client-id"] || null;

    if (!uid || uid.trim() === "") {
      return res.status(400).json({success: false, error: "User ID is required"});
    }

    const {sections, pins, branding, plantId, cards, groups} = req.body;
    const pid = (plantId || "").toString().trim();

    if (!sections || !Array.isArray(sections)) {
      return res.status(400).json({success: false, error: "sections array is required"});
    }

    const docId = docIdFor(uid, pid);
    await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection(COLLECTION).doc(docId);

      const dataToSave = {
        uid,
        plantId: pid,
        clientId: clientId || "",
        sections,
        pins: pins || [],
        branding: branding || {},
        // Factory Overview (Block B) card filters — lot237_dashboard_v6
        cards: cards || {},
        groups: groups || [],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const existing = await docRef.get();
      if (!existing.exists) {
        dataToSave.createdAt = admin.firestore.FieldValue.serverTimestamp();
      }

      // A pin IS a lot: only the group doc's own pins (plantId empty) carry
      // this meaning, so this only ever runs there. Diffing before/after
      // save is how creating or removing a pin creates or removes that
      // pin's own independent dashboard — nothing else on this page has to
      // change for that to happen.
      const oldPinNames = pid ? [] : previousPinNames(existing.exists ? existing.data() : null);

      await docRef.set(dataToSave, {merge: true});

      if (!pid) {
        const newPinNames = previousPinNames(dataToSave);
        const added = newPinNames.filter((n) => !oldPinNames.includes(n));
        const removed = oldPinNames.filter((n) => !newPinNames.includes(n));

        for (const name of added) {
          try {
            await autoProvisionPecc({clientId, factoryId: "", factoryName: name, ownerUid: uid});
          } catch (err) {
            console.warn(`[plantEnergyCommandCenter] auto-provision for new pin "${name}" failed:`, err.message);
          }
        }
        for (const name of removed) {
          try {
            await cdb.collection(COLLECTION).doc(docIdFor(uid, name)).delete();
          } catch (err) {
            console.warn(`[plantEnergyCommandCenter] cleanup for removed pin "${name}" failed:`, err.message);
          }
        }
      }
    });

    return res.status(200).json({
      success: true,
      message: "Plant Energy Command Center settings saved successfully",
      uid,
      plantId: pid,
    });
  } catch (error) {
    console.error("[plantEnergyCommandCenter] POST error:", error.message);
    return res.status(500).json({success: false, error: error.message});
  }
});

module.exports = router;
