const express = require("express");
const admin = require("firebase-admin");

// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();

const customerCollection = db.collection("customers");

// ✅ Fetch Customer Role by UID
router.get("/role/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) {
      return res.status(400).json({error: "UID is required"});
    }

    const snapshot = await
    customerCollection.where("UID", "==", uid).limit(1).get();
    if (snapshot.empty) {
      return res.status(404).json({error: "Customer not found"});
    }

    const doc = snapshot.docs[0];
    res.json({role: doc.data().roles || ""});
  } catch (error) {
    console.error("Error fetching customer role:", error);
    res.status(500).json({error: "Internal server error"});
  }
});

// ✅ Fetch Customer Name by UID
router.get("/name/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) {
      return res.status(400).json({error: "UID is required"});
    }

    const snapshot = await
    customerCollection.where("UID", "==", uid).limit(1).get();
    if (snapshot.empty) {
      return res.status(404).json({error: "Customer not found"});
    }

    const doc = snapshot.docs[0];
    res.json({name: doc.data().name || "", email: doc.data().email || ""});
  } catch (error) {
    console.error("Error fetching customer name:", error);
    res.status(500).json({error: "Internal server error"});
  }
});

// ✅ Fetch Customer Factory ID by UID
router.get("/factory/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    if (!uid) {
      return res.status(400).json({error: "UID is required"});
    }

    const snapshot = await
    customerCollection.where("UID", "==", uid).limit(1).get();
    if (snapshot.empty) {
      return res.status(404).json({error: "Customer not found"});
    }

    const doc = snapshot.docs[0];
    res.json({factory_id: doc.data().factory_id || ""});
  } catch (error) {
    console.error("Error fetching customer factory:", error);
    res.status(500).json({error: "Internal server error"});
  }
});

module.exports = router;
