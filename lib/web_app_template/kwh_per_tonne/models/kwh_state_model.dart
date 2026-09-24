import '../../master_facility_setting/models/facility_data.dart';

/// Immutable snapshot of computed KWH state — passed to all tab widgets.
/// Built once per [build()] call in the parent; tabs are stateless consumers.
class KwhStateModel {
  // ── Raw data ──────────────────────────────────────────────────────────────
  final List<FacilityData> filteredFacilities;
  final List<FacilityData> topConsumers;
  final List<Map<String, dynamic>> enriched;
  final Map<String, Map<String, dynamic>> polAgg;

  /// Machine names with at least one kWh/Tonne log entry dated today —
  /// distinct from [polAgg], which aggregates all-time entries.
  final Set<String> machinesWithDataToday;
  final Map<String, double> facilityEnergy;
  final Map<String, bool> facilityLoaded;

  // ── Options / lists ───────────────────────────────────────────────────────
  final List<String> machineOptions; // includes 'All'
  final List<String> typeOptions;
  final List<String> deptOptions;
  final List<String> machineNames;   // machine-only (no 'All')
  final List<String> productNames;

  // ── Thresholds & settings ─────────────────────────────────────────────────
  final double targetKwh;
  final double warningPct;
  final double criticalPct;
  final double rate;
  final String currency;

  // ── Pre-computed fleet KPIs ───────────────────────────────────────────────
  final double fleetAvgKwhT;
  final double fleetVariance;
  final int onTargetCount;
  final double totalCost;

  const KwhStateModel({
    required this.filteredFacilities,
    required this.topConsumers,
    required this.enriched,
    required this.polAgg,
    required this.machinesWithDataToday,
    required this.facilityEnergy,
    required this.facilityLoaded,
    required this.machineOptions,
    required this.typeOptions,
    required this.deptOptions,
    required this.machineNames,
    required this.productNames,
    required this.targetKwh,
    required this.warningPct,
    required this.criticalPct,
    required this.rate,
    required this.currency,
    required this.fleetAvgKwhT,
    required this.fleetVariance,
    required this.onTargetCount,
    required this.totalCost,
  });

  // ── Helpers used by tabs ──────────────────────────────────────────────────

  // Real SEC only: kWh ÷ tonnes from logged production entries. Machines
  // without log data return 0 — the daily meter kWh total is not a per-tonne
  // figure and must not stand in for one.
  double secFor(FacilityData f) {
    final name = f.meterName.isNotEmpty ? f.meterName : f.meterId;
    final match = polAgg[name];
    if (match != null && (match['kwhT'] as double) > 0) return match['kwhT'] as double;
    return 0.0;
  }

  bool hasDataToday(FacilityData f) {
    final name = f.meterName.isNotEmpty ? f.meterName : f.meterId;
    return machinesWithDataToday.contains(name);
  }

  String statusLabel(double variancePct) {
    if (variancePct > criticalPct) return 'Critical';
    if (variancePct > warningPct) return 'Warning';
    return 'On target';
  }

  List<Map<String, dynamic>> monthlyAgg(List<Map<String, dynamic>> src) {
    final map = <String, Map<String, dynamic>>{};
    for (final e in src) {
      final date = e['date']?.toString() ?? '';
      if (date.length < 7) continue;
      final mo = date.substring(0, 7);
      map.putIfAbsent(mo, () => {'month': mo, 'sumKwh': 0.0, 'sumTonnes': 0.0});
      map[mo]!['sumKwh']    = (map[mo]!['sumKwh']    as double) + ((e['kwh']    as num?)?.toDouble() ?? 0);
      map[mo]!['sumTonnes'] = (map[mo]!['sumTonnes'] as double) + ((e['tonnes'] as num?)?.toDouble() ?? 0);
    }
    final list = map.values.toList()..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
    return list.map((d) {
      final kwhT = (d['sumTonnes'] as double) > 0
          ? (d['sumKwh'] as double) / (d['sumTonnes'] as double)
          : 0.0;
      return {...d, 'kwhT': kwhT};
    }).toList();
  }

  List<Map<String, dynamic>> machineAggList() {
    final map = <String, Map<String, dynamic>>{};
    for (final e in enriched) {
      final m = e['machine']?.toString() ?? '';
      if (m.isEmpty) continue;
      map.putIfAbsent(m, () => {'machine': m, 'sumKwh': 0.0, 'sumTonnes': 0.0});
      map[m]!['sumKwh']    = (map[m]!['sumKwh']    as double) + ((e['kwh']    as num?)?.toDouble() ?? 0);
      map[m]!['sumTonnes'] = (map[m]!['sumTonnes'] as double) + ((e['tonnes'] as num?)?.toDouble() ?? 0);
    }
    return map.values.map((d) {
      final kwhT = (d['sumTonnes'] as double) > 0
          ? (d['sumKwh'] as double) / (d['sumTonnes'] as double)
          : 0.0;
      return {
        ...d,
        'kwhT': kwhT,
        'variancePct': targetKwh > 0 ? (kwhT - targetKwh) / targetKwh * 100 : 0.0,
        'cost': (d['sumKwh'] as double) * rate,
      };
    }).toList()..sort((a, b) => (a['kwhT'] as double).compareTo(b['kwhT'] as double));
  }

  List<Map<String, dynamic>> productAggList() {
    final map = <String, Map<String, dynamic>>{};
    for (final e in enriched) {
      final t = e['product']?.toString() ?? '';
      if (t.isEmpty) continue;
      map.putIfAbsent(t, () => {'label': t, 'sumKwh': 0.0, 'sumTonnes': 0.0});
      map[t]!['sumKwh']    = (map[t]!['sumKwh']    as double) + ((e['kwh']    as num?)?.toDouble() ?? 0);
      map[t]!['sumTonnes'] = (map[t]!['sumTonnes'] as double) + ((e['tonnes'] as num?)?.toDouble() ?? 0);
    }
    return map.values.map((d) {
      final kwhT = (d['sumTonnes'] as double) > 0
          ? (d['sumKwh'] as double) / (d['sumTonnes'] as double)
          : 0.0;
      return {
        ...d,
        'machine': d['label'],
        'kwhT': kwhT,
        'variancePct': targetKwh > 0 ? (kwhT - targetKwh) / targetKwh * 100 : 0.0,
        'cost': (d['sumKwh'] as double) * rate,
      };
    }).toList()..sort((a, b) => (a['kwhT'] as double).compareTo(b['kwhT'] as double));
  }
}
