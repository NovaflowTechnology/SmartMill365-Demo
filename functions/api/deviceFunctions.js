const express = require("express");
const { queryWithFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// Fetch All Devices
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "devices", null);
    res.status(200).json(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
  } catch (error) {
    console.error("Error fetching devices:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
