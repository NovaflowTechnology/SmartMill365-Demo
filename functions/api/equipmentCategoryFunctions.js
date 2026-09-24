const express = require("express");
const admin = require("firebase-admin");
const { getClientFirestore, withDbFallback } = require("../helpers/dbConnections");

// eslint-disable-next-line new-cap
const router = express.Router();

const COLLECTION = "equipmentCategories";

const col = (cdb, factoryId) =>
  cdb.collection("factories").doc(factoryId).collection(COLLECTION);

const SEED_DATA = [
  { device_type: "Main Switch Board (MSB)",      device_code: "MSB",  equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "None (root incomer)",       oee_module: "No",       energy_module: "Yes" },
  { device_type: "Sub Distribution Board",        device_code: "SDB",  equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "MSB",                      oee_module: "No",       energy_module: "Yes" },
  { device_type: "Final Distribution Board",      device_code: "FDB",  equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "Sub DB",                   oee_module: "No",       energy_module: "Yes" },
  { device_type: "Transformer",                   device_code: "XFMR", equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "None (upstream of MSB)",   oee_module: "No",       energy_module: "Yes" },
  { device_type: "VFD / Inverter",                device_code: "VFD",  equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "Sub DB or Final DB",       oee_module: "No",       energy_module: "Yes" },
  { device_type: "Genset / Generator",            device_code: "GEN",  equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "None (backup source)",     oee_module: "No",       energy_module: "Yes" },
  { device_type: "Power Factor Correction (PFC)", device_code: "PFC",  equipment_category: "Electrical Infrastructure", category_code: "ELEC", electrical_parent: "MSB or Sub DB",            oee_module: "No",       energy_module: "Yes" },
  { device_type: "Cast Film Machine",             device_code: "CAST", equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB",                   oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "Blown Film Machine",            device_code: "BLOW", equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB",                   oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "CNC Machine",                   device_code: "CNC",  equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB or Final DB",       oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "Extruder",                      device_code: "EXT",  equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB",                   oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "Slitter / Rewinder",            device_code: "SLIT", equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB",                   oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "Printing Machine",              device_code: "PRNT", equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB",                   oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "Laminator",                     device_code: "LAM",  equipment_category: "Production Machine",        category_code: "PROD", electrical_parent: "Sub DB",                   oee_module: "Yes",      energy_module: "Yes" },
  { device_type: "Air Compressor",                device_code: "COMP", equipment_category: "Utility Equipment",         category_code: "UTIL", electrical_parent: "Sub DB",                   oee_module: "Optional", energy_module: "Yes" },
  { device_type: "Vacuum Pump",                   device_code: "VACP", equipment_category: "Utility Equipment",         category_code: "UTIL", electrical_parent: "Sub DB or Final DB",       oee_module: "Optional", energy_module: "Yes" },
  { device_type: "Process Water Pump",            device_code: "PUMP", equipment_category: "Utility Equipment",         category_code: "UTIL", electrical_parent: "Sub DB",                   oee_module: "Optional", energy_module: "Yes" },
  { device_type: "Hydraulic Power Unit",          device_code: "HPU",  equipment_category: "Utility Equipment",         category_code: "UTIL", electrical_parent: "Sub DB or Final DB",       oee_module: "Optional", energy_module: "Yes" },
  { device_type: "Boiler",                        device_code: "BOLR", equipment_category: "Utility Equipment",         category_code: "UTIL", electrical_parent: "Sub DB",                   oee_module: "No",       energy_module: "Yes" },
  { device_type: "Cooling Tower",                 device_code: "CT",   equipment_category: "Utility Equipment",         category_code: "UTIL", electrical_parent: "Sub DB",                   oee_module: "Optional", energy_module: "Yes" },
  { device_type: "Chiller Unit",                  device_code: "CHIL", equipment_category: "HVAC & Cooling",            category_code: "HVAC", electrical_parent: "Sub DB",                   oee_module: "Optional", energy_module: "Yes" },
  { device_type: "Cooling Tower Fan",             device_code: "CTF",  equipment_category: "HVAC & Cooling",            category_code: "HVAC", electrical_parent: "Sub DB or Final DB",       oee_module: "No",       energy_module: "Yes" },
  { device_type: "Air Handling Unit (AHU)",       device_code: "AHU",  equipment_category: "HVAC & Cooling",            category_code: "HVAC", electrical_parent: "Final DB",                 oee_module: "No",       energy_module: "Yes" },
  { device_type: "Fan Coil Unit (FCU)",           device_code: "FCU",  equipment_category: "HVAC & Cooling",            category_code: "HVAC", electrical_parent: "Final DB",                 oee_module: "No",       energy_module: "Yes" },
  { device_type: "Condenser Unit",                device_code: "COND", equipment_category: "HVAC & Cooling",            category_code: "HVAC", electrical_parent: "Sub DB or Final DB",       oee_module: "No",       energy_module: "Yes" },
  { device_type: "Power Meter",                   device_code: "PM",   equipment_category: "Sensor / Instrument",       category_code: "SENS", electrical_parent: "Mounted on any equipment", oee_module: "No",       energy_module: "Yes" },
  { device_type: "Temperature Sensor / PT100",    device_code: "TEMP", equipment_category: "Sensor / Instrument",       category_code: "SENS", electrical_parent: "Mounted on any equipment", oee_module: "No",       energy_module: "Yes" },
  { device_type: "Pressure Transmitter",          device_code: "PRES", equipment_category: "Sensor / Instrument",       category_code: "SENS", electrical_parent: "Mounted on any equipment", oee_module: "No",       energy_module: "Yes" },
  { device_type: "Flow Meter",                    device_code: "FLOW", equipment_category: "Sensor / Instrument",       category_code: "SENS", electrical_parent: "Mounted on any equipment", oee_module: "No",       energy_module: "Yes" },
  { device_type: "PLC I/O Point",                 device_code: "PLC",  equipment_category: "Sensor / Instrument",       category_code: "SENS", electrical_parent: "Linked to production machine", oee_module: "No",  energy_module: "No"  },
  { device_type: "Level Sensor",                  device_code: "LVL",  equipment_category: "Sensor / Instrument",       category_code: "SENS", electrical_parent: "Mounted on tank / vessel", oee_module: "No",      energy_module: "Yes" },
];

async function seedFactory(cdb, factoryId) {
  const batch = cdb.batch();
  const c = col(cdb, factoryId);
  for (const entry of SEED_DATA) {
    const ref = c.doc();
    batch.set(ref, {...entry, factory_id: factoryId, created_at: admin.firestore.FieldValue.serverTimestamp()});
  }
  await batch.commit();
  console.log(`Seeded ${SEED_DATA.length} records for factory: ${factoryId}`);
}

// ── GET /equipmentCategory?factory_id=xxx ─────────────────────────────────────
router.get("/", async (req, res) => {
  try {
    const {factory_id} = req.query;
    if (!factory_id) return res.status(400).json({error: "factory_id is required."});

    const clientId = req.headers["x-client-id"] || null;
    const cdb = await getClientFirestore(clientId);

    const snapshot = await col(cdb, factory_id).orderBy("created_at").get();

    if (snapshot.empty) {
      await seedFactory(cdb, factory_id);
      const seeded = await col(cdb, factory_id).orderBy("created_at").get();
      return res.status(200).json(seeded.docs.map((d) => ({id: d.id, ...d.data()})));
    }

    res.status(200).json(snapshot.docs.map((d) => ({id: d.id, ...d.data()})));
  } catch (error) {
    console.error("Error fetching equipment categories:", error);
    res.status(500).json({error: error.message});
  }
});

// ── POST /equipmentCategory ───────────────────────────────────────────────────
router.post("/", async (req, res) => {
  try {
    const {factory_id, device_type, device_code, equipment_category, category_code, electrical_parent, oee_module, energy_module} = req.body;
    if (!factory_id) return res.status(400).json({error: "factory_id is required."});
    if (!device_type || !device_type.trim()) return res.status(400).json({error: "device_type is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const data = {
        factory_id,
        device_type: device_type.trim(),
        device_code: (device_code || "").trim(),
        equipment_category: (equipment_category || "").trim(),
        category_code: (category_code || "").trim(),
        electrical_parent: (electrical_parent || "").trim(),
        oee_module: oee_module || "No",
        energy_module: energy_module || "No",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      const ref = await col(cdb, factory_id).add(data);
      return {success: true, id: ref.id, ...data};
    });

    res.status(201).json(result);
  } catch (error) {
    console.error("Error creating equipment category:", error);
    res.status(500).json({error: error.message});
  }
});

// ── PUT /equipmentCategory/:id ────────────────────────────────────────────────
router.put("/:id", async (req, res) => {
  try {
    const {id} = req.params;
    const {factory_id, device_type, device_code, equipment_category, category_code, electrical_parent, oee_module, energy_module} = req.body;
    if (!factory_id) return res.status(400).json({error: "factory_id is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const docRef = col(cdb, factory_id).doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};

      const updateData = {
        factory_id,
        device_type: (device_type || "").trim(),
        device_code: (device_code || "").trim(),
        equipment_category: (equipment_category || "").trim(),
        category_code: (category_code || "").trim(),
        electrical_parent: (electrical_parent || "").trim(),
        oee_module: oee_module || "No",
        energy_module: energy_module || "No",
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      await docRef.update(updateData);
      return {success: true, id, ...updateData};
    });

    if (result.notFound) return res.status(404).json({error: "Equipment category not found."});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error updating equipment category:", error);
    res.status(500).json({error: error.message});
  }
});

// ── DELETE /equipmentCategory/:id ─────────────────────────────────────────────
router.delete("/:id", async (req, res) => {
  try {
    const {id} = req.params;
    const {factory_id} = req.query;
    if (!factory_id) return res.status(400).json({error: "factory_id is required."});

    const result = await withDbFallback(req, async (cdb) => {
      const docRef = col(cdb, factory_id).doc(id);
      const doc = await docRef.get();
      if (!doc.exists) return {notFound: true};
      await docRef.delete();
      return {success: true, id};
    });

    if (result.notFound) return res.status(404).json({error: "Equipment category not found."});
    res.status(200).json(result);
  } catch (error) {
    console.error("Error deleting equipment category:", error);
    res.status(500).json({error: error.message});
  }
});

module.exports = router;
