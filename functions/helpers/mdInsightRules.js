"use strict";

// MD Insight Report rule engine — 21 rules across 5 sections, matching the
// live md_insight_rules table exactly (rule_id/category/output_template are
// authoritative there, not derived from a spec doc). Pure/no I/O: given a
// normalized ctx of inputs, computes each rule's {status, values} and renders
// `text` from the output_template(_else) rows (fetched by the caller).
//
// status semantics (spec §5):
//   ok                 condition met, value computed        -> render output_template
//   else               condition not met, data valid         -> render output_template_else
//   insufficient_data  inputs missing/unusable                -> omit line, log a warning

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

// ── Number & date formatting (spec §6) — applied only at render time ─────────

function fmtCurrency(n) {
  return Math.round(Number(n) || 0).toLocaleString("en-US");
}
function fmtKw(n) {
  return Math.round(Number(n) || 0).toLocaleString("en-US");
}
function fmtPct1(n) {
  return (Number(n) || 0).toFixed(1);
}
function fmtDuration1(n) {
  return (Number(n) || 0).toFixed(1);
}
function fmtInt(n) {
  return String(Math.round(Number(n) || 0));
}
function fmtDate(dateStr) {
  const [y, m, d] = String(dateStr).split("-").map(Number);
  return `${d} ${MONTHS[m - 1]} ${y}`;
}
function fmtMonthYear(year, month) {
  return `${MONTHS[month - 1]} ${year}`;
}
function fmtList(names) {
  return (names || []).join(", ");
}

// Maps a rule's `values` key to how it's rendered into the template string.
// Keys not listed here (shift, trend, direction, name, month, ...) are
// already plain display strings and pass through unformatted.
const FORMATTERS = {
  excess_pct: fmtPct1,
  surcharge: fmtCurrency,
  potential_saving: fmtCurrency,
  shift_pct: fmtPct1,
  utilization: fmtPct1,
  remaining: fmtKw,
  excess: fmtKw,
  hours: fmtDuration1,
  value: fmtKw,
  mom_pct: fmtPct1,
  days: fmtInt,
  top3_pct: fmtPct1,
  top10_pct: fmtPct1,
  n: fmtInt,
  date: fmtDate,
  list: fmtList,
};

function formatValues(values) {
  const out = {};
  for (const [key, val] of Object.entries(values || {})) {
    if (val === null || val === undefined) {
      out[key] = "";
      continue;
    }
    const fmt = FORMATTERS[key];
    out[key] = fmt ? fmt(val) : String(val);
  }
  return out;
}

function interpolate(template, formatted) {
  return template.replace(/\{(\w+)\}/g, (_, key) => (key in formatted ? formatted[key] : `{${key}}`));
}

// ── Small stats helpers ───────────────────────────────────────────────────────

function minutesOfDay(hhmm) {
  const [h, m] = String(hhmm || "0:0").split(":").map(Number);
  return (h || 0) * 60 + (m || 0);
}

// Handles overnight shifts (e.g. Night 22:00-06:00) the same way the peak-hour
// window filter in energyDetails.js does.
function inShiftWindow(timeHHmm, start, end) {
  const t = minutesOfDay(timeHHmm);
  const s = minutesOfDay(start);
  const e = minutesOfDay(end);
  return s < e ? (t >= s && t < e) : (t >= s || t < e);
}

// Dart DateTime.weekday convention (1=Mon…7=Sun) — matches the `days` array
// stored in the site's Peak Hour ToU setting (contractCapacity.peakHourToU).
function isoWeekday(dateStr) {
  const [y, m, d] = String(dateStr).split("-").map(Number);
  const jsDay = new Date(Date.UTC(y, m - 1, d)).getUTCDay(); // 0=Sun…6=Sat
  return jsDay === 0 ? 7 : jsDay;
}

// Shared by MD003 and the /md-insight-rules route's load_analysis stats, so
// both report the exact same dominant-shift figure.
function computeShiftBreakdown(blockMd, shiftDef, md) {
  return shiftDef.map((s) => {
    const peak = blockMd
      .filter((b) => inShiftWindow(b.time, s.start, s.end))
      .reduce((m, b) => Math.max(m, b.value), 0);
    return { name: s.name, peak, pct: md > 0 ? (peak / md) * 100 : 0 };
  });
}

// ── Rule registry ─────────────────────────────────────────────────────────────

const RULES = [];

function addRule(id, category, section, fn, depends = []) {
  RULES.push({ id, category, section, fn, depends });
}

// 4.1 Executive Summary
addRule("MD001", "EXECUTIVE SUMMARY", "executive_summary", (ctx) => {
  const { cc, md } = ctx;
  if (cc == null || md == null) return { status: "insufficient_data" };
  if (md > cc) return { status: "ok", values: { excess_pct: ((md - cc) / cc) * 100 } };
  return { status: "else", values: {} };
});

addRule("MD002", "EXECUTIVE SUMMARY", "executive_summary", (ctx, results) => {
  const src = results.MD201;
  if (!src || src.status === "insufficient_data") return { status: "insufficient_data" };
  return { status: src.status, values: { surcharge: src.values.surcharge || 0 } };
}, ["MD201"]);

addRule("MD003", "EXECUTIVE SUMMARY", "executive_summary", (ctx) => {
  const { blockMd, shiftDef, md } = ctx;
  if (!blockMd || !blockMd.length || !shiftDef || !shiftDef.length || !md) {
    return { status: "insufficient_data" };
  }
  const withPct = computeShiftBreakdown(blockMd, shiftDef, md);
  const dominant = withPct.reduce((best, s) => (s.pct > best.pct ? s : best), withPct[0]);
  if (dominant.pct >= 40) return { status: "ok", values: { shift: dominant.name, shift_pct: dominant.pct } };
  return { status: "else", values: {} };
});

// Same dominant-shift figure as MD003, but unconditional (no >=40% gate —
// MD003's gate exists to decide between "dominant shift" vs "evenly
// distributed" wording; MD004 always states whichever shift is largest).
// No output_template_else in md_insight_rules for this rule, so it only
// ever resolves to "ok" or "insufficient_data", never "else".
addRule("MD004", "EXECUTIVE SUMMARY", "executive_summary", (ctx) => {
  const { blockMd, shiftDef, md } = ctx;
  if (!blockMd || !blockMd.length || !shiftDef || !shiftDef.length || !md) {
    return { status: "insufficient_data" };
  }
  const withPct = computeShiftBreakdown(blockMd, shiftDef, md);
  const dominant = withPct.reduce((best, s) => (s.pct > best.pct ? s : best), withPct[0]);
  return { status: "ok", values: { shift: dominant.name, shift_pct: dominant.pct } };
});

// Same value as MD301 — no recompute (same "no recompute" pattern as
// MD002 -> MD201).
addRule("MD005", "EXECUTIVE SUMMARY", "executive_summary", (ctx, results) => {
  const src = results.MD301;
  if (!src || src.status === "insufficient_data") return { status: "insufficient_data" };
  return { status: src.status, values: { ...src.values } };
}, ["MD301"]);

// Top-10 contribution % — same figure the Equipment Analysis ranking table
// totals to (top10_total_kw / md * 100); computed independently here since
// MD401 (the equipment list rule) doesn't expose the percentage itself.
// No output_template_else, so only "ok" or "insufficient_data".
addRule("MD006", "EXECUTIVE SUMMARY", "executive_summary", (ctx) => {
  const { equipKw, md } = ctx;
  if (!equipKw || !equipKw.length || !md) return { status: "insufficient_data" };
  const top10 = [...equipKw].sort((a, b) => b.value - a.value).slice(0, 10);
  const top10_pct = (top10.reduce((s, e) => s + e.value, 0) / md) * 100;
  return { status: "ok", values: { top10_pct } };
});

// Plant-status headline — same breach condition as MD001. Fixed wording (no
// interpolated values); kept out of the rendered bullet list client-side
// since its text duplicates the report's separate Plant Status panel.
addRule("MD007", "EXECUTIVE SUMMARY", "executive_summary", (ctx) => {
  const { cc, md } = ctx;
  if (cc == null || md == null) return { status: "insufficient_data" };
  return { status: md > cc ? "ok" : "else", values: {} };
});

// 4.2 Capacity Analysis
addRule("MD101", "CAPACITY ANALYSIS", "capacity_analysis", (ctx) => {
  const { cc, md } = ctx;
  if (!cc) return { status: "insufficient_data" };
  return { status: "ok", values: { utilization: (md / cc) * 100 } };
});

addRule("MD102", "CAPACITY ANALYSIS", "capacity_analysis", (ctx) => {
  const { cc, md } = ctx;
  if (!cc) return { status: "insufficient_data" };
  const remaining = cc - md;
  if (remaining >= 0) return { status: "ok", values: { remaining } };
  return { status: "else", values: { excess: -remaining } };
});

addRule("MD103", "CAPACITY ANALYSIS", "capacity_analysis", (ctx) => {
  const { blockMd, cc } = ctx;
  if (!blockMd || !blockMd.length || cc == null) return { status: "insufficient_data" };
  const hours = blockMd.filter((b) => b.value > cc).length * 0.5;
  if (hours > 0) return { status: "ok", values: { hours } };
  return { status: "else", values: {} };
});

addRule("MD104", "CAPACITY ANALYSIS", "capacity_analysis", (ctx) => {
  const { historyMaxDaily } = ctx;
  if (!historyMaxDaily) return { status: "else", values: {} };
  return { status: "ok", values: { value: historyMaxDaily.value, date: historyMaxDaily.date } };
});

// 4.3 Cost Analysis
addRule("MD201", "COST ANALYSIS", "cost_analysis", (ctx) => {
  const { cc, md, mdRate } = ctx;
  if (mdRate == null) return { status: "insufficient_data" };
  const surcharge = Math.max(0, md - cc) * mdRate;
  if (surcharge > 0) return { status: "ok", values: { surcharge } };
  return { status: "else", values: {} };
});

addRule("MD203", "COST ANALYSIS", "cost_analysis", (ctx, results) => {
  const src = results.MD201;
  if (!src || src.status === "insufficient_data") return { status: "insufficient_data" };
  return { status: src.status, values: { potential_saving: src.values.surcharge || 0 } };
}, ["MD201"]);

// 4.4 Trend Analysis
addRule("MD301", "TREND ANALYSIS", "trend_analysis", (ctx) => {
  const { dailyMd, cc, blockMdAll, peakStart, peakEnd, peakDays } = ctx;
  if (!dailyMd || !dailyMd.length || cc == null) return { status: "insufficient_data" };

  // When the site's Peak Hour ToU window is configured, only readings inside
  // it count as an "exceed" — matching how MD is actually billed instead of
  // flagging a day whose peak happened off-peak. blockMdAll is already in
  // chronological order (ORDER BY timestamp ASC), so the first match here is
  // the first time it was ever exceeded during peak hours, not just the
  // start of the most recent breach streak.
  let breachDate = null;
  if (peakStart && peakEnd && blockMdAll && blockMdAll.length) {
    const days = peakDays && peakDays.length ? new Set(peakDays) : null;
    const hit = blockMdAll.find((b) =>
      b.value > cc &&
      inShiftWindow(b.time, peakStart, peakEnd) &&
      (!days || days.has(isoWeekday(b.date)))
    );
    breachDate = hit ? hit.date : null;
  } else {
    const hit = dailyMd.find((d) => d.value > cc);
    breachDate = hit ? hit.date : null;
  }

  if (breachDate) return { status: "ok", values: { date: breachDate } };
  return { status: "else", values: {} };
});

addRule("MD302", "TREND ANALYSIS", "trend_analysis", (ctx) => {
  const { md, prevMonthMd } = ctx;
  if (!prevMonthMd) return { status: "insufficient_data" };
  const mom = ((md - prevMonthMd) / prevMonthMd) * 100;
  return { status: "ok", values: { mom_pct: Math.abs(mom), direction: mom >= 0 ? "up" : "down" } };
});

addRule("MD303", "TREND ANALYSIS", "trend_analysis", (ctx) => {
  const { monthlyMd } = ctx;
  if (!monthlyMd || !monthlyMd.length) return { status: "else", values: {} };
  const best = monthlyMd.reduce((m, r) => (r.value > m.value ? r : m), monthlyMd[0]);
  return { status: "ok", values: { value: best.value, month: fmtMonthYear(best.year, best.month) } };
});

addRule("MD304", "TREND ANALYSIS", "trend_analysis", (ctx) => {
  const { dailyMd, cc } = ctx;
  if (!dailyMd || !dailyMd.length || cc == null) return { status: "insufficient_data" };
  const days = dailyMd.filter((d) => d.value > cc).length;
  if (days > 0) return { status: "ok", values: { days } };
  return { status: "else", values: {} };
});

// 4.5 Equipment Analysis — peak-block snapshot only (scope locked, spec §4.5)
addRule("MD401", "EQUIPMENT ANALYSIS", "equipment_analysis", (ctx) => {
  const { equipKw } = ctx;
  if (!equipKw || !equipKw.length) return { status: "insufficient_data" };
  const top10 = [...equipKw].sort((a, b) => b.value - a.value).slice(0, 10);
  return { status: "ok", values: { list: top10.map((e) => e.name) } };
});

addRule("MD402", "EQUIPMENT ANALYSIS", "equipment_analysis", (ctx) => {
  const { equipKw, md } = ctx;
  if (!equipKw || !equipKw.length || !md) return { status: "insufficient_data" };
  const top3 = [...equipKw].sort((a, b) => b.value - a.value).slice(0, 3);
  const top3_pct = (top3.reduce((s, e) => s + e.value, 0) / md) * 100;
  return { status: "ok", values: { top3_pct } };
});

addRule("MD403", "EQUIPMENT ANALYSIS", "equipment_analysis", (ctx) => {
  const { equipKw } = ctx;
  if (!equipKw || !equipKw.length) return { status: "insufficient_data" };
  const top = equipKw.reduce((m, e) => (e.value > m.value ? e : m), equipKw[0]);
  return { status: "ok", values: { name: top.name, value: top.value } };
});

addRule("MD404", "EQUIPMENT ANALYSIS", "equipment_analysis", (ctx) => {
  const { equipKw, md } = ctx;
  if (!equipKw || !equipKw.length || !md) return { status: "insufficient_data" };
  const sorted = [...equipKw].sort((a, b) => b.value - a.value);
  let cum = 0;
  let n = 0;
  for (const e of sorted) {
    cum += e.value;
    n++;
    if ((cum / md) * 100 >= 80) break;
  }
  return { status: "ok", values: { n } };
});

const SECTION_ORDER = [
  "executive_summary", "capacity_analysis", "cost_analysis", "trend_analysis", "equipment_analysis",
];

/**
 * Runs all 18 rules against ctx and renders each with the templates fetched
 * from the md_insight_rules table (map keyed by rule_id, each row shaped
 * {rule_id, category, output_template, output_template_else}).
 */
function computeReport(ctx, templates) {
  const results = {};
  const warnings = [];

  // MD002/MD203 depend on MD201 — running lower-dependency rules first is
  // enough ordering since no rule depends on more than one other rule.
  const ordered = [...RULES].sort((a, b) => a.depends.length - b.depends.length);

  for (const rule of ordered) {
    let outcome;
    try {
      outcome = rule.fn(ctx, results) || { status: "insufficient_data" };
    } catch (err) {
      outcome = { status: "insufficient_data", reason: `compute error: ${err.message}` };
    }
    if (outcome.status === "insufficient_data") {
      warnings.push({ rule_id: rule.id, reason: outcome.reason || "insufficient_data" });
    }
    results[rule.id] = outcome;
  }

  const sections = {};
  for (const key of SECTION_ORDER) sections[key] = [];

  for (const rule of RULES) {
    const r = results[rule.id];
    if (r.status === "insufficient_data") continue; // omit line, warning already logged
    const tpl = templates[rule.id] || {};
    const template = r.status === "ok" ? tpl.output_template : tpl.output_template_else;
    const text = template ? interpolate(template, formatValues(r.values)) : null;
    sections[rule.section].push({
      rule_id: rule.id,
      category: rule.category,
      status: r.status,
      values: r.values || {},
      text,
    });
  }

  const md001 = results.MD001;
  const report_state = !md001 || md001.status === "insufficient_data"
    ? "unknown"
    : md001.status === "ok" ? "breach" : "within";

  return { report_state, sections, warnings };
}

module.exports = {
  computeReport,
  formatValues,
  interpolate,
  computeShiftBreakdown,
  fmtDate,
  fmtMonthYear,
  fmtList,
};
