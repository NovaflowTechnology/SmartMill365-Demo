const express = require("express");
const admin = require("firebase-admin");

// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();

const customerCollection = db.collection("customers");

// ✅ Fetch All Customers
router.get("/", async (req, res) => {
  try {
    const snapshot = await customerCollection.get();
    const customers = snapshot.docs.map((doc) => {
      const data = doc.data();
      return { id: doc.id, ...data };
    });
    res.status(200).json(customers);
  } catch (error) {
    console.error("Error fetching customers:", error);
    res.status(500).json({ error: error.message });
  }
});

// ✅ Fetch Customers by Role
router.get("/role/:role", async (req, res) => {
  try {
    const { role } = req.params;

    let query = customerCollection;
    if (role.toLowerCase() === "client") {
      query = query.where("roles", "==", "Client");
    } else if (role.toLowerCase() === "admin") {
      query = query.where("roles", "in", ["Admin", "Client"]);
    }

    const snapshot = await query.get();
    const customers = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.status(200).json(customers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ Fetch Customer by id
router.get("/id/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const customerDoc = await customerCollection.doc(id).get();
    if (!customerDoc.exists) {
      return res.status(404).json({ error: "Customer not found." });
    }
    const customerData = customerDoc.data();
    res.status(200).json({ id: customerDoc.id, ...customerData });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ Add a Customer
router.post("/add", async (req, res) => {
  try {
    const { name, phone, email, groupIds, role, uid, factory_id } = req.body;

    const existingCustomer = await customerCollection.where("email", "==", email).get();
    if (!existingCustomer.empty) {
      return res.status(400).json({ error: "Customer email already exists." });
    }

    const snapshot = await customerCollection.get();
    const existingIds = snapshot.docs.map((doc) => doc.id);
    const newCustomerId = generateNextCustomerId(existingIds);
    const createdAt = new Date().toISOString().slice(0, 23);

    const newCustomer = {
      name,
      email,
      phone,
      group_id: groupIds,
      roles: role,
      status: true,
      created_at: createdAt,
      UID: uid,
      factory_id: factory_id || "",
    };

    await customerCollection.doc(newCustomerId).set(newCustomer);
    res.status(201).json({ success: true, id: newCustomerId, ...newCustomer });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Generates the next customer ID based on existing IDs.
 * @param {string[]} existingIds
 * @return {string}
 */
function generateNextCustomerId(existingIds) {
  if (existingIds.length === 0) return "U0001";
  existingIds.sort();
  const lastId = existingIds[existingIds.length - 1];
  const numericPart = parseInt(lastId.substring(1));
  return `U${(numericPart + 1).toString().padStart(4, "0")}`;
}

// ✅ Create a new Firebase Auth user
router.post("/create", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  try {
    const user = await admin.auth().createUser({ email, password });
    res.status(200).json({ success: true, uid: user.uid });
  } catch (error) {
    if (error.code === "auth/email-already-in-use") {
      return res.status(400).json({ error: "Email is already in use." });
    } else if (error.code === "auth/weak-password") {
      return res.status(400).json({ error: "Weak password. Use at least 6 characters." });
    }
    res.status(500).json({ error: error.message });
  }
});

// ✅ Delete Customer record
router.delete("/delete/:id", async (req, res) => {
  try {
    const { id } = req.params;

    await db.runTransaction(async (transaction) => {
      const customerRef = customerCollection.doc(id);
      const customerSnapshot = await transaction.get(customerRef);

      if (!customerSnapshot.exists) {
        return res.status(404).json({ error: "Customer not found" });
      }

      transaction.delete(customerRef);
    });

    res.status(200).json({ success: true, message: "Customer deleted." });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ Delete Firebase Auth user
router.delete("/delete", async (req, res) => {
  const { uid } = req.body;

  if (!uid) {
    return res.status(400).json({ error: "UID is required" });
  }

  try {
    await admin.auth().deleteUser(uid);
    res.status(200).json({ success: true, message: `User with UID ${uid} deleted` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ Edit Customer
router.put("/edit/:id", async (req, res) => {
  try {
    const customerId = req.params.id;
    const { name, phone, initialEmail, email, groupIds, role, factory_id } = req.body;

    if (email !== initialEmail) {
      const querySnapshot = await customerCollection.where("email", "==", email).get();
      if (!querySnapshot.empty) {
        return res.status(400).json({ error: "A customer with the same email already exists." });
      }
    }

    const updateData = {
      name,
      email,
      phone,
      group_id: groupIds,
      roles: role,
    };
    if (factory_id !== undefined) updateData.factory_id = factory_id;

    await customerCollection.doc(customerId).update(updateData);

    return res.status(200).json({ success: true, message: "Customer updated successfully." });
  } catch (error) {
    return res.status(500).json({ error: `Error editing customer: ${error.message}` });
  }
});

// ✅ Update Password
router.put("/updateUserPassword", async (req, res) => {
  try {
    const { userUid, newPassword } = req.body;

    await admin.auth().updateUser(userUid, { password: newPassword });
    return res.status(200).json({ message: "User password updated successfully." });
  } catch (error) {
    console.error("Error updating password:", error);
    return res.status(500).json({ error: "Internal server error." });
  }
});

// ✅ Fix UID mismatch (called automatically on login when UID doesn't match)
router.put("/fixUid/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { uid } = req.body;
    if (!uid) return res.status(400).json({ error: "uid is required" });
    await customerCollection.doc(id).update({ UID: uid });
    return res.status(200).json({ success: true });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
