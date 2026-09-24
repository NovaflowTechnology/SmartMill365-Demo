const express = require("express");
const admin = require("firebase-admin");
// eslint-disable-next-line new-cap
const router = express.Router();
const db = admin.firestore();
const energySystemSettingsCollection = db.collection("energySystemSettings");

/**
 * GET /api/energy-settings/:uid
 * Retrieve energy system settings for a specific user
 */
router.get("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;

    if (!uid) {
      return res.status(400).json({error: "User ID is required"});
    }

    const settingsDoc = await energySystemSettingsCollection.doc(uid).get();

    if (!settingsDoc.exists) {
      // Return default settings if none exist
      return res.status(200).json({
        exists: false,
        settings: getDefaultSettings(),
      });
    }

    return res.status(200).json({
      exists: true,
      settings: settingsDoc.data(),
    });
  } catch (error) {
    console.error("Error fetching energy settings:", error);
    return res.status(500).json({error: "Failed to fetch settings"});
  }
});

/**
 * POST /api/energy-settings/:uid
 * Create or update energy system settings for a user
 */
router.post("/:uid", async (req, res) => {
  try {
    const {uid} = req.params;
    const settingsData = req.body;

    if (!uid) {
      return res.status(400).json({error: "User ID is required"});
    }

    // Validate the settings data
    const validationError = validateSettings(settingsData);
    if (validationError) {
      return res.status(400).json({error: validationError});
    }

    // Prepare the data to be saved
    const dataToSave = {
      uid: uid,
      contractCapacity: settingsData.contractCapacity || {},
      electricityTariff: settingsData.electricityTariff || {},
      notification: settingsData.notification || {},
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Check if document exists
    const settingsDoc = await energySystemSettingsCollection.doc(uid).get();

    if (!settingsDoc.exists) {
      // Create new document with created_at timestamp
      dataToSave.created_at = admin.firestore.FieldValue.serverTimestamp();
    }

    // Save or update the settings
    await energySystemSettingsCollection.doc(uid).set(dataToSave, {merge: true});

    return res.status(200).json({
      success: true,
      message: "Settings saved successfully",
    });
  } catch (error) {
    console.error("Error saving energy settings:", error);
    return res.status(500).json({error: "Failed to save settings"});
  }
});

/**
 * PATCH /api/energy-settings/:uid/:settingType
 * Update a specific setting type (contractCapacity, electricityTariff, or notification)
 */
router.patch("/:uid/:settingType", async (req, res) => {
  try {
    const {uid, settingType} = req.params;
    const settingData = req.body;

    if (!uid) {
      return res.status(400).json({error: "User ID is required"});
    }

    const validSettingTypes = ["contractCapacity", "electricityTariff", "notification"];
    if (!validSettingTypes.includes(settingType)) {
      return res.status(400).json({error: "Invalid setting type"});
    }

    const updateData = {
      [settingType]: settingData,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await energySystemSettingsCollection.doc(uid).set(updateData, {merge: true});

    return res.status(200).json({
      success: true,
      message: `${settingType} updated successfully`,
    });
  } catch (error) {
    console.error(`Error updating ${req.params.settingType}:`, error);
    return res.status(500).json({error: "Failed to update setting"});
  }
});
/**
 * Validate settings data structure
 */
function validateSettings(settings) {
  // Validate Contract Capacity Settings
  if (settings.contractCapacity) {
    const {contractCapacity, warningThreshold, emergencyThreshold} = settings.contractCapacity;
    
    if (contractCapacity !== undefined && (typeof contractCapacity !== "number" || contractCapacity <= 0)) {
      return "Contract capacity must be a positive number";
    }
    
    if (warningThreshold !== undefined && (typeof warningThreshold !== "number" || warningThreshold < 0 || warningThreshold > 100)) {
      return "Warning threshold must be between 0 and 100";
    }
    
    if (emergencyThreshold !== undefined && (typeof emergencyThreshold !== "number" || emergencyThreshold < 0 || emergencyThreshold > 100)) {
      return "Emergency threshold must be between 0 and 100";
    }

    if (warningThreshold && emergencyThreshold && warningThreshold >= emergencyThreshold) {
      return "Warning threshold must be less than emergency threshold";
    }

    // Validate peakHourToU
    const {peakHourToU} = settings.contractCapacity;
    if (peakHourToU !== undefined) {
      if (typeof peakHourToU !== "object" || peakHourToU === null) {
        return "peakHourToU must be an object";
      }

      const {startTime, endTime, days} = peakHourToU;
      const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;

      if (startTime !== undefined && (typeof startTime !== "string" || !timeRegex.test(startTime))) {
        return "peakHourToU.startTime must be a valid time string in HH:MM format";
      }

      if (endTime !== undefined && (typeof endTime !== "string" || !timeRegex.test(endTime))) {
        return "peakHourToU.endTime must be a valid time string in HH:MM format";
      }

      if (days !== undefined) {
        if (!Array.isArray(days) || days.some((d) => !Number.isInteger(d) || d < 1 || d > 7)) {
          return "peakHourToU.days must be an array of integers between 1 (Mon) and 7 (Sun)";
        }
      }
    }
  }

  // Validate Electricity Tariff Settings
  if (settings.electricityTariff) {
    const {peakRate, normalRate, offPeakRate, capacityRate} = settings.electricityTariff;
    
    if (peakRate !== undefined && (typeof peakRate !== "number" || peakRate < 0)) {
      return "Peak rate must be a non-negative number";
    }
    
    if (normalRate !== undefined && (typeof normalRate !== "number" || normalRate < 0)) {
      return "Normal rate must be a non-negative number";
    }
    
    if (offPeakRate !== undefined && (typeof offPeakRate !== "number" || offPeakRate < 0)) {
      return "Off-peak rate must be a non-negative number";
    }
    
    if (capacityRate !== undefined && (typeof capacityRate !== "number" || capacityRate < 0)) {
      return "Capacity rate must be a non-negative number";
    }
  }

  // Validate Notification Settings
  if (settings.notification) {
    const {email, phone, emailEnabled, smsEnabled} = settings.notification;
    
    if (email !== undefined && typeof email !== "string") {
      return "Email must be a string";
    }
    
    if (phone !== undefined && typeof phone !== "string") {
      return "Phone must be a string";
    }
    
    if (emailEnabled !== undefined && typeof emailEnabled !== "boolean") {
      return "Email enabled must be a boolean";
    }
    
    if (smsEnabled !== undefined && typeof smsEnabled !== "boolean") {
      return "SMS enabled must be a boolean";
    }
  }

  return null; // No validation errors
}

/**
 * Get default settings
 */
function getDefaultSettings() {
  return {
    contractCapacity: {
      contractCapacity: 0,
      warningThreshold: 0,
      emergencyThreshold: 0,
      peakHourToU: {
        startTime: "08:00",
        endTime: "12:00",
        days: [1, 2, 3, 4, 5],
      },
    },
    electricityTariff: {
      peakRate: 0.0,
      normalRate: 0.0,
      offPeakRate: 0.0,
      capacityRate: 0.0,
    },
    notification: {
      email: "",
      phone: "",
      emailEnabled: false,
      smsEnabled: false,
    },
  };
}

module.exports = router;