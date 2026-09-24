const express = require("express");
const admin = require("firebase-admin");

// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();

const workOrderCollection = db.collection("workOrders");
const productCollection = db.collection('products');

router.get("/product/:productId", async (req, res) => {
  const { productId } = req.params;

  try {
    // 1) Fetch the document
    const docSnap = await productCollection.doc(productId).get();

    // 2) Handle “not found”
    if (!docSnap.exists) {
      return res.status(404).json({ error: "Product not found" });
    }

    // 3) Extract data and return only the name
    const data = docSnap.data();
    return res.json({ name: data.name });
  } catch (err) {
    console.error("Error fetching product:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Fetch All Work Orders
router.get("/", async (req, res) => {
  try {
    const snapshot = await workOrderCollection.get();
    const workOrders = snapshot.docs.map((doc) => {
      const data = doc.data();

      return {
        id: doc.id,
        ...data,
      };
    });

    res.status(200).json(workOrders);
  } catch (error) {
    console.error("Error fetching work orders:", error);
    res.status(500).json({ error: error.message });
  }
});

//Fetch Specific Work Order with ID
router.get("/:id", async (req, res) => {
  try {
    const workOrderId = req.params.id;
    const doc = await workOrderCollection.doc(workOrderId).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Work order not found' });
    }

    res.status(200).json({ id: doc.id, ...doc.data() });
  } catch (error) {
    console.error("Error fetching work order:", error);
    res.status(500).json({ error: error.message });
  }
});


module.exports = router;
