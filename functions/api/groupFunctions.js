const express = require("express");
const admin = require("firebase-admin");

// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();

const groupCollection = db.collection("groups");

// ✅ Fetch All Groups
router.get("/", async (req, res) => {
  try {
    const snapshot = await groupCollection.get();
    const groups = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
      };
    });
    res.status(200).json(groups);
  } catch (error) {
    console.error("Error fetching groups:", error);
    res.status(500).json({error: error.message});
  }
});

// ✅ Add a Group
router.post("/add", async (req, res) => {
  try {
    const {name, description, assignby} = req.body;

    // Check if the group already exists
    const existingGroup = await groupCollection
        .where("name", "==", name)
        .where("assignby", "==", assignby)
        .get();

    if (!existingGroup.empty) {
      return res.status(400).json({error: "Group name already exists."});
    }

    // Retrieve existing group IDs
    const snapshot = await groupCollection.get();
    const existingIds = snapshot.docs.map((doc) => doc.id);

    // Generate next group ID
    const newGroupId = generateNextGroupId(existingIds);
    const createdAt = new Date().toISOString().slice(0, 23);

    // Group object
    const newGroup = {
      name,
      description,
      assignby,
      created_at: createdAt,
    };

    // Save to Firestore
    await groupCollection.doc(newGroupId).set(newGroup);

    res.status(201).json({success: true, id: newGroupId, ...newGroup});
  } catch (error) {
    res.status(500).json({error: error.message});
  }
});

/**
 * Generates the next group ID based on existing IDs.
 *
 * @param {string[]} existingIds - An array of existing group IDs.
 * @return {string} The newly generated group ID.
 */
function generateNextGroupId(existingIds) {
  if (existingIds.length === 0) {
    return "G0001";
  }
  existingIds.sort();
  const lastId = existingIds[existingIds.length - 1];
  const numericPart = parseInt(lastId.substring(1));
  return `G${(numericPart + 1).toString().padStart(4, "0")}`;
}

// ✅ Delete a Group and Update Customers
router.delete("/delete/:id", async (req, res) => {
  try {
    const {id} = req.params;
    await groupCollection.doc(id).delete();

    const customersSnapshot = await db
        .collection("customers")
        .where("group_id", "array-contains", id)
        .get();

    const batch = db.batch();
    customersSnapshot.forEach((doc) => {
      const updatedGroups =
        doc.data().group_id.filter((groupId) => groupId !== id);
      batch.update(doc.ref, {group_id: updatedGroups});
    });

    await batch.commit();
    res.status(200).json({
      success: true, message: "Group deleted and customers updated.",
    });
  } catch (error) {
    res.status(500).json({error: error.message});
  }
});

// ✅ Edit a Group
router.put("/edit/:id", async (req, res) => {
  try {
    const {name, description, assignby, initialName} = req.body;
    const groupId = req.params.id;

    if (!name || !description || !assignby || !initialName) {
      return res.status(400).json({error: "Missing required fields."});
    }

    if (initialName !== name) {
      const querySnapshot = await groupCollection
          .where("name", "==", name)
          .where("assignby", "==", assignby)
          .get();

      if (!querySnapshot.empty) {
        return res.status(400).json({
          error: `A group with the same name already exists for ${assignby}.`,
        });
      }
    }

    await groupCollection.doc(groupId).update({
      name,
      description,
    });

    return res.status(200).json({
      success: true, message: "Group updated successfully.",
    });
  } catch (error) {
    return res.status(500).json({
      error: `Error editing group: ${error.message}`,
    });
  }
});

// ✅ Fetch Group Size
router.get("/size/:groupId", async (req, res) => {
  try {
    const groupId = req.params.groupId;

    if (!groupId) {
      return res.status(400).json({error: "Missing group ID."});
    }

    const querySnapshot = await db.collection("customers")
        .where("group_id", "array-contains", groupId)
        .get();

    return res.status(200).json({success: true, groupSize: querySnapshot.size});
  } catch (error) {
    return res.status(500).json({
      error: `Error fetching group size: ${error.message}`,
    });
  }
});

module.exports = router;
