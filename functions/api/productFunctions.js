const express = require("express");
const { queryWithFallback, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

// Fetch All Products
router.get("/", async (req, res) => {
  try {
    const clientId = req.headers["x-client-id"] || null;
    const snapshot = await queryWithFallback(clientId, "products", null);
    const products = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.status(200).json(products);
  } catch (error) {
    console.error("Error fetching products:", error);
    res.status(500).json({ error: error.message });
  }
});

// Add Product
router.post("/add", async (req, res) => {
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const col = cdb.collection("products");
      const snapshot = await col.get();
      const existingIds = snapshot.docs.map((d) => d.id);
      const nextId = generateNextProductId(existingIds);

      const { number, name, specification, description, batchQuantity, packingQuantity, classification, category, equipment, processRoute } = req.body;

      const data = { number, name, specification, description, batchQuantity, packingQuantity, classification, category, equipment, processRoute };
      await col.doc(nextId).set(data);

      if (equipment && equipment !== "0") {
        try { await cdb.collection("equipments").doc(equipment).update({ product: nextId }); } catch (_) {}
      }

      return { success: true, id: nextId, ...data };
    });

    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Edit Product
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("products").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return { notFound: true };

      const { number, name, specification, description, batchQuantity, packingQuantity, classification, category, equipment, processRoute, previousEquipment } = req.body;

      await docRef.update({ number, name, specification, description, batchQuantity, packingQuantity, classification, category, equipment, processRoute });

      if (equipment && equipment !== "0") {
        try { await cdb.collection("equipments").doc(equipment).update({ product: id }); } catch (_) {}
      } else if (previousEquipment && previousEquipment !== "0") {
        try { await cdb.collection("equipments").doc(previousEquipment).update({ product: "0" }); } catch (_) {}
      }

      return { message: "Product updated successfully", id };
    });

    if (result.notFound) return res.status(404).json({ error: "Product not found" });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete Product
router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await withDbFallback(req, async (cdb) => {
      const docRef = cdb.collection("products").doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return { notFound: true };
      await docRef.delete();
      return { message: "Product deleted successfully", id };
    });

    if (result.notFound) return res.status(404).json({ error: "Product not found" });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

function generateNextProductId(existingIds) {
  if (existingIds.length === 0) return "PROD0001";
  existingIds.sort();
  const lastId = existingIds[existingIds.length - 1];
  const numericPart = parseInt(lastId.substring(4));
  return `PROD${(numericPart + 1).toString().padStart(4, "0")}`;
}

module.exports = router;
