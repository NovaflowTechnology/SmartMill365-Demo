import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'air_compressor_monitoring_widget.dart' show AirCompressorMonitoringWidget;

// ── Data Models ───────────────────────────────────────────────────────────────
// Typed shapes for the Air Compressor Monitoring dashboard. Every reading is
// nullable: null means no live source is wired up yet (or a mapped device
// hasn't reported), and the view layer renders that as "N/A" rather than
// falling back to a fabricated value.

class AcKpiDef {
  final String label;
  final String unit;
  final String subtitle;

  const AcKpiDef({required this.label, required this.unit, this.subtitle = ''});
}

class AcCompressor {
  final String id;
  final double? powerValue;
  // 'kW' or 'kWh' depending on the METRIC FIELD mapped in Air Compressor
  // Dashboard Setting — see `AirCompressorDataService`.
  final String unit;
  // True once a Device ID is mapped but the mapped METRIC FIELD has no live
  // source yet (e.g. Max Demand, Power Factor) — distinguishes "not mapped"
  // from "mapped, but this metric isn't wired up yet".
  final bool fieldSupported;
  // Header-flow ribbon split — purely a visual proportion (no live flow
  // source exists yet), so both compressors get an even 50/50 share.
  final double flowSharePercent;

  const AcCompressor({
    required this.id,
    this.powerValue,
    this.unit = 'kW',
    this.fieldSupported = true,
    this.flowSharePercent = 50,
  });

  // Swaps in a live-fetched reading (see `AirCompressorDataService`).
  AcCompressor copyWith({double? powerValue, String? unit, bool? fieldSupported}) => AcCompressor(
        id: id,
        powerValue: powerValue ?? this.powerValue,
        unit: unit ?? this.unit,
        fieldSupported: fieldSupported ?? this.fieldSupported,
        flowSharePercent: flowSharePercent,
      );
}

enum AcInsightKind { positive, warning, info }

class AcInsight {
  final AcInsightKind kind;
  final String message;
  final String time;

  const AcInsight({required this.kind, required this.message, required this.time});
}

class AcCastPoint {
  final String label;
  final double? value;
  // Manual requirement spec set in Air Compressor Dashboard Setting — shown
  // alongside the live reading, independent of whether a device is mapped.
  final double? reqPressure;
  final double? reqFlow;

  const AcCastPoint({required this.label, this.value, this.reqPressure, this.reqFlow});

  bool get hasData => value != null;
}

class AcSystemStatus {
  final String? systemStatus;
  final bool systemStatusGood;
  final String? leakageStatus;
  final bool leakageDetected;
  final double? availabilityPercent;
  final double? totalDowntimeHr;
  final double? dewPointC;
  final String nextMaintenance;

  const AcSystemStatus({
    this.systemStatus,
    this.systemStatusGood = true,
    this.leakageStatus,
    this.leakageDetected = false,
    this.availabilityPercent,
    this.totalDowntimeHr,
    this.dewPointC,
    required this.nextMaintenance,
  });
}

class AcTrendPoint {
  final String time;
  final double specificEnergy;

  const AcTrendPoint({required this.time, required this.specificEnergy});
}

class AcFlowTrendPoint {
  final String time;
  final double flowM3Min;

  const AcFlowTrendPoint({required this.time, required this.flowM3Min});
}

// ── Static definitions ──────────────────────────────────────────────────────
// Labels/units only — no fabricated readings live here. Actual values come
// from live data (see AirCompressorDataService) or stay null → "N/A".

const List<AcKpiDef> kAcKpiDefs = [
  // Specific Energy = Total Power ÷ Header Flow. Header Flow has no live
  // backend yet, so this always renders "N/A" until that telemetry exists —
  // never fall back to an unrelated reading (e.g. cumulative kWh) just
  // because one side of the formula is missing.
  AcKpiDef(label: 'SPECIFIC ENERGY', unit: 'kW/(m³/min)'),
  AcKpiDef(label: 'TOTAL POWER', unit: 'kW'),
  AcKpiDef(label: 'TOTAL FLOW', unit: 'm³/min'),
  AcKpiDef(label: 'HEADER PRESSURE', unit: 'bar'),
  AcKpiDef(label: 'SYSTEM HEALTH', unit: '/100', subtitle: 'Health Index'),
];

const AcCompressor kAc1 = AcCompressor(id: 'AC1');
const AcCompressor kAc2 = AcCompressor(id: 'AC2');
const List<AcCompressor> kAcCompressors = [kAc1, kAc2];

// Demand Side cast/consumer labels — the flow reading itself has no live
// source yet, so `value` stays null (shown as "N/A") until one exists.
const List<AcCastPoint> kAcCastPoints = [
  AcCastPoint(label: 'Cast 1'),
  AcCastPoint(label: 'Cast 2'),
  AcCastPoint(label: 'Cast 3'),
  AcCastPoint(label: 'Cast 4'),
  AcCastPoint(label: 'Cast 5'),
  AcCastPoint(label: 'Cast 6'),
  AcCastPoint(label: 'NGR 3'),
];

// ── FlutterFlow-style model wrapper (page state bookkeeping only) ──────────────

class AirCompressorMonitoringModel extends FlutterFlowModel<AirCompressorMonitoringWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
