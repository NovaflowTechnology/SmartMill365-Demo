const express = require("express");
const { getInfluxClient, getInfluxSchema, sanitize, deviceFilter } = require("../helpers/dbConnections");

const router = express.Router();

// ── Per-request InfluxDB client + schema ──────────────────────────────────────
// No x-client-id → getInfluxClient/getInfluxSchema fall back to the
// default (Danapac) connection, so untagged requests keep working.
async function getClient(req) {
  const clientId = req.clientId || req.headers["x-client-id"];
  const { queryApi, bucket, org } = await getInfluxClient(clientId, req);
  const schema = await getInfluxSchema(clientId);
  return { queryApi, bucket, org, schema };
}

function executeQuery(queryApi, fluxQuery) {
  return new Promise((resolve, reject) => {
    const results = [];
    queryApi.queryRows(fluxQuery, {
      next(row, tableMeta) { results.push(tableMeta.toObject(row)); },
      error(err)           { reject(err); },
      complete()           { resolve(results); },
    });
  });
}

// ── Field name translation ─────────────────────────────────────────────────────
// Normalise Thong Guan's field names to the aliases the frontend already expects.
// Danapac uses P_kW / P / PF / Edel; Thong Guan uses Active_Power_kW / Power_Factor / Accum_Energy_Consumption etc.
const FIELD_ALIAS = {
  // power
  "P_kW":                        "P(kW)",
  "P":                           "P(kW)",
  "Active_Power_kW":             "P(kW)",
  // reactive
  "Q_kVAr":                      "Q(VAR)",
  "Q":                           "Q(VAR)",
  "Reactive_Power_kVAr":         "Q(VAR)",
  "Reactive_Power_kVAr_Export":  "Q(VAR)",
  // apparent
  "S_kVA":                       "S(VA)",
  "S":                           "S(VA)",
  "Apparent_Power_kVA":          "S(VA)",
  // PF
  "PF":                          "PF",
  "Power_Factor":                "PF",
  // current
  "Current_A":                   "IA",
  "Current_B":                   "IB",
  "Current_C":                   "IC",
  "Current_Avg":                 "Iavg",
  "Current_Average":             "Iavg",
  // voltage (line-to-line → UAB/UBC/UCA as expected by voltage card widget)
  "Voltage_AB":                  "UAB",
  "Voltage_BC":                  "UBC",
  "Voltage_CA":                  "UCA",
  "Voltage_Avg":                 "Uavg",
  "Voltage_Average":             "Uavg",
  // line-to-neutral — kept separate, not shown in card
  "Voltage_AN":                  "Van",
  "Voltage_BN":                  "Vbn",
  "Voltage_CN":                  "Vcn",
  // energy
  "Edel":                            "Edel",
  "Accum_Energy_Consumption":        "Edel",
  "Accum_Energy_Consumption_kWh":    "Edel",
  "Accum_Energy_Generate":           "Erec",
  "Accum_Energy_Generated_kWh":      "Erec",
  "Accum_Energy_Generated":          "Erec",
  // freq / demand
  "Freq":                        "Freq",
  "Frequency_Hz":                "Freq",
  "Max_Demand_kW":               "PeakDemand",
  "Peak_Demand_kW":              "PeakDemand",
};

const FIELD_CATEGORY = {
  "P(kW)": "POWER", "Q(kVAr)": "POWER", "Q(VAR)": "POWER",
  "S(kVA)": "POWER", "S(VA)": "POWER",
  "PF": "POWER", "Freq": "POWER", "PeakDemand": "POWER",
  "IA": "CURRENT", "IB": "CURRENT", "IC": "CURRENT", "Iavg": "CURRENT",
  "UAB": "VOLTAGE", "UBC": "VOLTAGE", "UCA": "VOLTAGE", "Uavg": "VOLTAGE",
  "Vab": "VOLTAGE", "Vbc": "VOLTAGE", "Vca": "VOLTAGE", "Vavg": "VOLTAGE",
  "Edel": "ENERGY", "Erec": "ENERGY", "Eapp": "ENERGY",
};

function aliasField(f) { return FIELD_ALIAS[f] || f; }
function categoryOf(f) { return FIELD_CATEGORY[f] || FIELD_CATEGORY[aliasField(f)] || "OTHER"; }

// ── GET /energyDetailsInfluxDb/devices ────────────────────────────────────────
router.get("/devices", async (req, res) => {
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const tag = schema.deviceIdTag;
    let fluxQuery = `
      import "influxdata/influxdb/schema"
      schema.tagValues(bucket: "${bucket}", tag: "${tag}")
    `;
    // For Thong Guan: filter by device_type if configured. Use schema.tagValues'
    // predicate (metadata-index lookup) instead of scanning 30 days of raw
    // points — the old range-scan version was slow enough to occasionally
    // exceed the frontend's 10s timeout.
    if (schema.deviceTypeTag && schema.deviceTypeVal) {
      fluxQuery = `
        import "influxdata/influxdb/schema"
        schema.tagValues(
          bucket: "${bucket}",
          tag: "${tag}",
          predicate: (r) => r._measurement == "${schema.measurement}" and r["${schema.deviceTypeTag}"] == "${sanitize(schema.deviceTypeVal)}",
          start: -15m
        )
      `;
    }
    const rows = await executeQuery(queryApi, fluxQuery);
    const devices = [...new Set(rows.map(r => r._value || r[tag]).filter(Boolean))];
    return res.json(devices.map(d => ({ device_id: d })));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/realtime/:topic ────────────────────────────────
router.get("/realtime/:topic", async (req, res) => {
  const topic = sanitize(req.params.topic);
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -5m)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, topic)}
        |> last()
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    if (!rows.length) return res.json([]);

    const result = rows.map((r) => {
      const field = r._field;
      const category = categoryOf(field);
      const mappedField = aliasField(field);
      return { measurement: category, field: mappedField, value: r._value };
    }).filter((r) => r.measurement !== "OTHER");

    return res.json(result);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/data/:topic/hourly ─────────────────────────────
router.get("/data/:topic/hourly", async (req, res) => {
  const topic    = sanitize(req.params.topic);
  const date     = req.query.date || new Date().toISOString().slice(0, 10);
  // Interval accepts seconds/minutes/hours (e.g. "5s", "15m", "1h") to match
  // the frontend's duration dropdown, which doubles as the aggregation window.
  const duration = /^\d+[smh]$/.test(req.query.duration || "") ? req.query.duration : "1h";

  // Malaysia time (UTC+8, no DST) — day boundaries are anchored to MYT
  // midnight, not UTC midnight, so "today" matches the user's local day.
  const currentStart  = `${date}T00:00:00+08:00`;
  const currentStop   = `${date}T23:59:59+08:00`;
  const prevDate      = new Date(new Date(date).getTime() - 86400000).toISOString().slice(0, 10);
  const previousStart = `${prevDate}T00:00:00+08:00`;
  const previousStop  = `${prevDate}T23:59:59+08:00`;

  try {
    const { queryApi, bucket, schema } = await getClient(req);
    // Accept both Danapac (P_kW/P) and Thong Guan (Active_Power_kW) power fields + energy fields
    const makeQuery = (start, stop) => `
      from(bucket: "${bucket}")
        |> range(start: ${start}, stop: ${stop})
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, topic)}
        |> filter(fn: (r) => r._field == "Edel" or r._field == "P" or r._field == "P_kW"
             or r._field == "Active_Power_kW" or r._field == "Accum_Energy_Consumption")
        |> aggregateWindow(every: ${duration}, fn: last, createEmpty: false)
        |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
    `;

    function formatRows(rows) {
      return rows.map((r) => {
        const t = new Date(r._time);
        // Shift to Malaysia wall-clock time (UTC+8, no DST) before reading
        // hour/minute/second so axis labels match the local day, regardless
        // of the server's own timezone.
        const myt = new Date(t.getTime() + 8 * 60 * 60 * 1000);
        const hh = String(myt.getUTCHours()).padStart(2, "0");
        const mm = String(myt.getUTCMinutes()).padStart(2, "0");
        const ss = String(myt.getUTCSeconds()).padStart(2, "0");
        // Sub-minute windows need seconds in the label or every point would
        // look identical on the axis/tooltip.
        const label = duration.endsWith("s") ? `${hh}:${mm}:${ss}` : `${hh}:${mm}`;
        const value = r.Active_Power_kW ?? r.P_kW ?? r.P ?? 0;
        const energy = r.Accum_Energy_Consumption ?? r.Edel ?? null;
        return { label, value, time: r._time, Edel: energy };
      });
    }

    const [curr, prev] = await Promise.all([
      executeQuery(queryApi, makeQuery(currentStart, currentStop)),
      executeQuery(queryApi, makeQuery(previousStart, previousStop)),
    ]);
    return res.json({ data: { current: formatRows(curr), previous: formatRows(prev) } });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/timeseries/:period ─────────────────────────────
router.get("/timeseries/:period", async (req, res) => {
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const powerField = schema.measurement === "power_meter" ? "P_kW" : "Active_Power_kW";
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -5m)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, null)}
        |> filter(fn: (r) => r._field == "${powerField}" or r._field == "P_kW" or r._field == "P")
        |> last()
        |> group(columns: ["${schema.deviceIdTag}"])
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    const result = rows.map((r) => ({
      machine_id: r[schema.deviceIdTag] || r.device_name,
      data: { power_kw: r._value ?? 0 },
    }));
    return res.json(result);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/power-load/current ────────────────────────────
// deviceId accepts a single id or a comma-separated list (e.g. "DPM046,DPM047,DPM048,DPM052")
// — the response is always the summed power across whichever devices are passed.
router.get("/power-load/current", async (req, res) => {
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const deviceId = req.query.deviceId || null;
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -5m)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, deviceId)}
        |> filter(fn: (r) => r._field == "P" or r._field == "P_kW" or r._field == "Active_Power_kW")
        |> group(columns: ["_field", "${schema.deviceIdTag}"])
        |> last()
        |> group()
        |> sum()
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    const total = rows.reduce((s, r) => s + (r._value || 0), 0);
    return res.json({ power_kw: parseFloat(total.toFixed(2)) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/energy-load/current ───────────────────────────
// deviceId accepts a single id or a comma-separated list — same shape as
// /power-load/current, but sums the cumulative energy counter (kWh) instead
// of instantaneous power.
router.get("/energy-load/current", async (req, res) => {
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const deviceId = req.query.deviceId || null;
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -5m)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, deviceId)}
        |> filter(fn: (r) => r._field == "Edel" or r._field == "Accum_Energy_Consumption" or r._field == "Accum_Energy_Consumption_kWh")
        |> group(columns: ["_field", "${schema.deviceIdTag}"])
        |> last()
        |> group()
        |> sum()
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    const total = rows.reduce((s, r) => s + (r._value || 0), 0);
    return res.json({ energy_kwh: parseFloat(total.toFixed(2)) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/demand-load/current ────────────────────────────
// deviceId accepts a single id or a comma-separated list — same shape as
// /power-load/current. Demand (per TNB's own definition) is the average
// power over a rolling 30-minute integration period, not an instantaneous
// reading — this is a live "current demand" snapshot from that trailing
// window, not the true monthly billing peak (see max_demand_monitoring,
// which reads that from the MySQL rollup tables instead).
router.get("/demand-load/current", async (req, res) => {
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const deviceId = req.query.deviceId || null;
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -30m)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, deviceId)}
        |> filter(fn: (r) => r._field == "P" or r._field == "P_kW" or r._field == "Active_Power_kW")
        |> group(columns: ["_field", "${schema.deviceIdTag}"])
        |> mean()
        |> group()
        |> sum()
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    const total = rows.reduce((s, r) => s + (r._value || 0), 0);
    return res.json({ demand_kw: parseFloat(total.toFixed(2)) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/equipment-load-correlation ────────────────────
router.get("/equipment-load-correlation", async (req, res) => {
  const eventStart = req.query.event_start ? req.query.event_start.replace(" ", "T") + "Z" : null;
  const eventEnd   = req.query.event_end   ? req.query.event_end.replace(" ", "T") + "Z"   : null;
  const eventDate  = req.query.event_date  || new Date().toISOString().slice(0, 10);
  const interval   = /^\d+[mh]$/.test(req.query.interval || "") ? req.query.interval : "30m";
  const start = eventStart || `${eventDate}T00:00:00Z`;
  const stop  = eventEnd   || `${eventDate}T23:59:59Z`;

  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: ${start}, stop: ${stop})
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, null)}
        |> filter(fn: (r) => r._field == "P_kW" or r._field == "P" or r._field == "Active_Power_kW")
        |> aggregateWindow(every: ${interval}, fn: max, createEmpty: false)
        |> group(columns: ["${schema.deviceIdTag}"])
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    let systemPeak = 0;
    const data = rows.map((r) => {
      const v = r._value || 0;
      if (v > systemPeak) systemPeak = v;
      const t = new Date(r._time);
      const hh = String(t.getUTCHours()).padStart(2, "0");
      const mm = String(t.getUTCMinutes()).padStart(2, "0");
      return { device_id: r[schema.deviceIdTag] || r.device_name, time_label: `${hh}:${mm}`, power_kW: parseFloat(v.toFixed(2)) };
    }).filter((r) => r.device_id);
    return res.json({ data, system_peak_kW: parseFloat(systemPeak.toFixed(2)) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/equipment-pf-correlation ──────────────────────
router.get("/equipment-pf-correlation", async (req, res) => {
  const eventStart = req.query.event_start ? req.query.event_start.replace(" ", "T") + "Z" : null;
  const eventEnd   = req.query.event_end   ? req.query.event_end.replace(" ", "T") + "Z"   : null;
  const eventDate  = req.query.event_date  || new Date().toISOString().slice(0, 10);
  const interval   = /^\d+[smh]$/.test(req.query.interval || "") ? req.query.interval : "30m";
  const start = eventStart || `${eventDate}T00:00:00Z`;
  const stop  = eventEnd   || `${eventDate}T23:59:59Z`;

  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const pfField = schema.measurement === "power_meter" ? "PF" : "Power_Factor";
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: ${start}, stop: ${stop})
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, null)}
        |> filter(fn: (r) => r._field == "${pfField}" or r._field == "PF" or r._field == "Power_Factor")
        |> aggregateWindow(every: ${interval}, fn: mean, createEmpty: false)
        |> group(columns: ["${schema.deviceIdTag}"])
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    let systemAvgPF = 0; let count = 0;
    const data = rows.map((r) => {
      const v = r._value || 0;
      systemAvgPF += v; count++;
      const t = new Date(r._time);
      const hh = String(t.getUTCHours()).padStart(2, "0");
      const mm = String(t.getUTCMinutes()).padStart(2, "0");
      return { device_id: r[schema.deviceIdTag] || r.device_name, time_label: `${hh}:${mm}`, power_factor: parseFloat(v.toFixed(4)) };
    }).filter((r) => r.device_id);
    return res.json({ data, power_factor: count ? parseFloat((systemAvgPF / count).toFixed(4)) : 0 });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/power-factor ───────────────────────────────────
router.get("/power-factor", async (req, res) => {
  const machineIds = (req.query.machine_id || "").split(",").map((s) => sanitize(s.trim())).filter(Boolean);
  const duration = /^\d+[smhd]$/.test(req.query.duration || "") ? req.query.duration : "1h";
  if (!machineIds.length) return res.json([]);

  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -${duration})
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, null)}
        |> filter(fn: (r) => r._field == "PF" or r._field == "Power_Factor")
        |> last()
        |> group(columns: ["${schema.deviceIdTag}"])
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    const result = rows
      .filter((r) => {
        const id = r[schema.deviceIdTag] || r.device_name;
        return id && machineIds.includes(id);
      })
      .map((r) => {
        const id = r[schema.deviceIdTag] || r.device_name;
        return { id, device_id: id, pf: parseFloat((r._value || 0).toFixed(4)), timestamp: r._time };
      });

    // Latest active power (kW) for the same devices — used by PF culprits filter.
    let kwById = {};
    try {
      const kwFlux = `
        from(bucket: "${bucket}")
          |> range(start: -${duration})
          |> filter(fn: (r) => r._measurement == "${schema.measurement}")
          ${deviceFilter(schema, null)}
          |> filter(fn: (r) => r._field == "P_kW" or r._field == "P" or r._field == "Active_Power_kW")
          |> last()
          |> group(columns: ["${schema.deviceIdTag}"])
      `;
      const kwRows = await executeQuery(queryApi, kwFlux);
      for (const r of kwRows) {
        const id = r[schema.deviceIdTag] || r.device_name;
        if (!id || !machineIds.includes(id)) continue;
        kwById[id] = parseFloat(Math.abs(r._value || 0).toFixed(3));
      }
    } catch (_) {}

    const withKw = result.map((row) => ({
      ...row,
      power_kw: kwById[row.id] ?? kwById[row.device_id] ?? 0,
    }));
    return res.json(withKw);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/stats/:deviceId ───────────────────────────────
router.get("/stats/:deviceId", async (req, res) => {
  const deviceId = sanitize(req.params.deviceId);
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -24h)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, deviceId)}
        |> last()
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    const result = {};
    rows.forEach((r) => { result[aliasField(r._field)] = r._value; });
    return res.json(result);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/timeseries/custom ─────────────────────────────
router.get("/timeseries/custom", async (req, res) => {
  const start         = req.query.start || "-1h";
  const stop          = req.query.stop  || "now()";
  const windowPeriod  = /^\d+[smhd]$/.test(req.query.window_period || "") ? req.query.window_period : "1m";
  const machineIds    = (req.query.machine_ids || "").split(",").map((s) => sanitize(s.trim())).filter(Boolean);
  const fields        = (req.query.fields || "").split(",").map((s) => sanitize(s.trim())).filter(Boolean);

  if (!machineIds.length) return res.json([]);

  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const tag = schema.deviceIdTag;
    const deviceOr = machineIds.map((id) => `r["${tag}"] == "${id}"`).join(" or ");
    const fieldOr  = fields.length
      ? fields.map((f) => `r._field == "${f}"`).join(" or ")
      : `r._field == "P_kW" or r._field == "P" or r._field == "Active_Power_kW"`;

    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: ${start}, stop: ${stop})
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${schema.deviceTypeTag && schema.deviceTypeVal
          ? `|> filter(fn: (r) => r["${schema.deviceTypeTag}"] == "${sanitize(schema.deviceTypeVal)}")`
          : ""}
        |> filter(fn: (r) => ${deviceOr})
        |> filter(fn: (r) => ${fieldOr})
        |> aggregateWindow(every: ${windowPeriod}, fn: mean, createEmpty: false)
        |> group(columns: ["${tag}", "_field"])
    `;
    const rows = await executeQuery(queryApi, fluxQuery);
    return res.json(rows.map((r) => ({
      machine_id: r[tag] || r.device_name,
      field: aliasField(r._field),
      time: r._time,
      value: r._value,
    })));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── GET /energyDetailsInfluxDb/reactive-apparent/:topic ──────────────────────
// Returns Q_VAR (reactive power) and S_VA (apparent power) directly from InfluxDB.
router.get("/reactive-apparent/:topic", async (req, res) => {
  const topic = sanitize(req.params.topic);
  try {
    const { queryApi, bucket, schema } = await getClient(req);
    const fluxQuery = `
      from(bucket: "${bucket}")
        |> range(start: -5m)
        |> filter(fn: (r) => r._measurement == "${schema.measurement}")
        ${deviceFilter(schema, topic)}
        |> filter(fn: (r) => r._field == "Q_VAR" or r._field == "S_VA")
        |> last()
    `;
    const rows = await executeQuery(queryApi, fluxQuery);

    let Q_VAR = 0;
    let S_VA = 0;
    for (const r of rows) {
      if (r._field === "Q_VAR") Q_VAR = r._value;
      if (r._field === "S_VA") S_VA = r._value;
    }

    return res.json({ Q_VAR, S_VA });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
