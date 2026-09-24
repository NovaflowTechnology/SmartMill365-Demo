import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/app_config.dart';
import '../master_facility_setting/models/facility_data.dart';
import '../master_facility_setting/services/facility_service.dart';
import 'carbon_dashboard_config.dart';
import 'carbon_emission_model.dart';

/// A labeled numeric series (e.g. daily or monthly kWh) fetched from
/// `GET /energyDetails/data/:device/:period`, used both to derive
/// KPI-card sparklines and period-over-period trend deltas.
class CarbonEmissionSeries {
  const CarbonEmissionSeries({this.labels = const [], this.values = const []});

  final List<String> labels;
  final List<double> values;

  bool get isEmpty => values.isEmpty;

  double get last => values.isEmpty ? 0 : values.last;
  double get previous => values.length > 1 ? values[values.length - 2] : 0;

  /// Last [take] points normalized to 0..1 for sparkline rendering.
  List<double> normalized({int take = 12}) {
    if (values.isEmpty) return const [];
    final slice = values.length > take ? values.sublist(values.length - take) : values;
    final max = slice.fold<double>(0, (m, v) => v > m ? v : m);
    if (max <= 0) return List.filled(slice.length, 0);
    return slice.map((v) => v / max).toList();
  }

  /// "+3.2%" style delta between the last two points, or null when not computable.
  double? get deltaPercent {
    if (last <= 0 || previous <= 0) return null;
    return (last - previous) / previous * 100;
  }

  /// Value for a given month label (e.g. "Jan"), or null when absent.
  double? valueForLabel(String label) {
    final i = labels.indexOf(label);
    return i >= 0 ? values[i] : null;
  }
}

class _EnergyTotals {
  double dailyKwh = 0;
  double monthlyKwh = 0;
}

class CarbonProductionLineLive {
  const CarbonProductionLineLive({
    required this.line,
    required this.productionTon,
    required this.intensityKgPerTon,
    required this.targetKgPerTon,
  });

  final String line;
  final double productionTon;
  final double intensityKgPerTon;
  final double targetKgPerTon;

  double get vsTargetPercent =>
      targetKgPerTon > 0 ? (intensityKgPerTon - targetKgPerTon) / targetKgPerTon * 100 : 0;
}

/// Resolved, config-driven live data for the Carbon Intelligence Dashboard.
/// Every field traces back to a configured Device ID (Master Facility /
/// Equipment Settings meter) or the active Emission Factor — never mock
/// constants. Fields are null/empty when the corresponding card has no
/// Device ID configured yet, or the live fetch failed.
class CarbonEmissionLiveData {
  const CarbonEmissionLiveData({
    this.emissionFactorKgPerKwh = 0,
    this.netEmissionTco2e,
    this.netEmissionDeltaPercent,
    this.netEmissionSpark = const [],
    this.carbonIntensityKgPerTon,
    this.carbonIntensityDeltaPercent,
    this.carbonIntensitySpark = const [],
    this.siteTonnesProduced = 0,
    this.totalConsumptionKwh,
    this.totalConsumptionDeltaPercent,
    this.totalConsumptionSpark = const [],
    this.solarKwh,
    this.solarAvoidedTco2e,
    this.solarDeltaPercent,
    this.solarSpark = const [],
    this.carbonCostPerTco2e,
    this.gridImportMwh,
    this.blocks = const [],
    this.breakdownProductionLinesTco2e = 0,
    this.breakdownUtilitiesTco2e = 0,
    this.contributors = const [],
    this.trendPoints = const [],
    this.productionLineRows = const [],
  });

  static const empty = CarbonEmissionLiveData();

  final double emissionFactorKgPerKwh;

  final double? netEmissionTco2e;
  final double? netEmissionDeltaPercent;
  final List<double> netEmissionSpark;

  final double? carbonIntensityKgPerTon;
  final double? carbonIntensityDeltaPercent;
  final List<double> carbonIntensitySpark;
  final double siteTonnesProduced;

  final double? totalConsumptionKwh;
  final double? totalConsumptionDeltaPercent;
  final List<double> totalConsumptionSpark;

  final double? solarKwh;
  final double? solarAvoidedTco2e;
  final double? solarDeltaPercent;
  final List<double> solarSpark;

  /// Carbon Cost (RM/tCO2e) from the active fiscal year's Emission Factor
  /// Management record. The Emission Cost KPI card uses the Carbon Price
  /// from [CarbonDashboardConfig] instead; this stays available as reference.
  final double? carbonCostPerTco2e;

  final double? gridImportMwh;
  final List<CarbonFlowBlock> blocks;

  final double breakdownProductionLinesTco2e;
  final double breakdownUtilitiesTco2e;

  final List<CarbonContributor> contributors;
  final List<EmissionTrendPoint> trendPoints;
  final List<CarbonProductionLineLive> productionLineRows;
}

/// Resolves [CarbonDashboardConfig] Device IDs into live readings by
/// combining `energyDetails` (kWh, MySQL/InfluxDB), the active Emission
/// Factor (Firestore), and `kwhPerTonneDataLog` (production tonnage, MySQL)
/// — the same backend surface `PeccDataService` and the kWh/Tonne module
/// already use, so no new endpoints were needed.
class CarbonEmissionDataService {
  static String get _base => AppConfig.dataApiBaseSafe;

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<_EnergyTotals> _fetchEnergyTotals(String deviceId) async {
    final out = _EnergyTotals();
    if (deviceId.isEmpty) return out;
    try {
      final uri = Uri.parse('$_base/energyDetails/total/${Uri.encodeComponent(deviceId)}');
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      debugPrint('[CarbonEmissionDataService._fetchEnergyTotals] GET $uri -> ${res.statusCode} ${res.body}');
      if (res.statusCode != 200) return out;
      final body = jsonDecode(res.body);
      if (body is! List) return out;
      for (final row in body) {
        if (row is! Map) continue;
        final period = row['period']?.toString() ?? '';
        final val = _toDouble(row['total_energy']);
        if (period == 'daily') out.dailyKwh = val;
        if (period == 'monthly') out.monthlyKwh = val;
      }
    } catch (e) {
      debugPrint('[CarbonEmissionDataService._fetchEnergyTotals] error for device=$deviceId: $e');
    }
    return out;
  }

  // A single Configure Dashboard config (especially a plant that's still
  // inheriting the pre-per-plant legacy default, which can list dozens of
  // Top Contributors) can name a lot of devices. Firing one request per
  // device all at once has been seen to overwhelm the backend's MySQL pool
  // — some requests come back 500, others fail outright as a connection
  // error — so totals are fetched in small batches instead.
  static const _totalsBatchSize = 6;

  static Future<Map<String, _EnergyTotals>> _fetchEnergyTotalsBatched(Set<String> deviceIds) async {
    final result = <String, _EnergyTotals>{};
    final ids = deviceIds.toList();
    for (var i = 0; i < ids.length; i += _totalsBatchSize) {
      final batch = ids.sublist(i, i + _totalsBatchSize > ids.length ? ids.length : i + _totalsBatchSize);
      final batchTotals = await Future.wait(batch.map(_fetchEnergyTotals));
      for (var j = 0; j < batch.length; j++) {
        result[batch[j]] = batchTotals[j];
      }
    }
    return result;
  }

  static Future<CarbonEmissionSeries> _fetchSeries(String deviceId, String period) async {
    if (deviceId.isEmpty) return const CarbonEmissionSeries();
    try {
      final uri = Uri.parse('$_base/energyDetails/data/${Uri.encodeComponent(deviceId)}/$period');
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const CarbonEmissionSeries();
      final rows = jsonDecode(res.body);
      if (rows is! List) return const CarbonEmissionSeries();
      final labels = <String>[];
      final values = <double>[];
      for (final r in rows) {
        if (r is! Map) continue;
        labels.add(r['label']?.toString() ?? '');
        values.add(_toDouble(r['value']));
      }
      return CarbonEmissionSeries(labels: labels, values: values);
    } catch (_) {
      return const CarbonEmissionSeries();
    }
  }

  static double? _cachedFactor;
  static double? _cachedCarbonCost;
  static DateTime? _cachedFactorAt;

  /// Carbon Cost (RM/tCO2e) of the active fiscal year's Emission Factor
  /// record, populated as a side effect of [fetchActiveEmissionFactor].
  static double? get cachedCarbonCostPerTco2e => _cachedCarbonCost;

  /// Active Emission Factor (kgCO2e/kWh) from Emission Factor Management,
  /// cached for 10 minutes — mirrors `PeccDataService._fetchActiveEmissionFactor`.
  static Future<double> fetchActiveEmissionFactor() async {
    final at = _cachedFactorAt;
    if (_cachedFactor != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 10)) {
      return _cachedFactor!;
    }
    try {
      final uri = Uri.parse('$_base/emission-factors?status=active');
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return _cachedFactor ?? 0;
      final list = jsonDecode(res.body);
      if (list is! List || list.isEmpty) return _cachedFactor ?? 0;
      final first = list.first;
      if (first is! Map) return _cachedFactor ?? 0;
      final factor = _toDouble(first['factor']);
      if (factor > 0) {
        _cachedFactor = factor;
        _cachedFactorAt = DateTime.now();
      }
      _cachedCarbonCost = first['carbon_cost'] != null ? _toDouble(first['carbon_cost']) : null;
      return factor;
    } catch (_) {
      return _cachedFactor ?? 0;
    }
  }

  static Future<({double kwhConsumed, double tonnesProduced})> _fetchKwhPerTonne({
    String? machineId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final qp = <String, String>{
        'from_date': _fmtDate(from),
        'to_date': _fmtDate(to),
        if (machineId != null && machineId.isNotEmpty) 'machine_id': machineId,
      };
      final uri = Uri.parse('$_base/kwhPerTonneDataLog').replace(queryParameters: qp);
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return (kwhConsumed: 0.0, tonnesProduced: 0.0);
      final rows = jsonDecode(res.body);
      if (rows is! List) return (kwhConsumed: 0.0, tonnesProduced: 0.0);
      var kwh = 0.0;
      var tonnes = 0.0;
      for (final r in rows) {
        if (r is! Map) continue;
        kwh += _toDouble(r['kWh_consumed']);
        tonnes += _toDouble(r['tonnes_produced']);
      }
      return (kwhConsumed: kwh, tonnesProduced: tonnes);
    } catch (_) {
      return (kwhConsumed: 0.0, tonnesProduced: 0.0);
    }
  }

  /// Unique, sorted `FacilityData.plant` values across every registered
  /// facility — powers the dashboard's Plant filter dropdown. Empty plant
  /// strings are excluded.
  static Future<List<String>> fetchPlantOptions() async {
    try {
      final facilities = await FacilityService.getFacilities();
      final plants = facilities.map((f) => f.plant.trim()).where((p) => p.isNotEmpty).toSet().toList();
      plants.sort();
      return plants;
    } catch (_) {
      return const [];
    }
  }

  /// Resolves every card on the dashboard from [config]'s Device IDs.
  /// Cards left unconfigured resolve to null/empty fields — callers must
  /// render a "not configured" state rather than substituting mock data.
  /// [period] is 'daily' (today) or 'monthly' (month to date) — both totals
  /// come back from the same `/energyDetails/total/:device` call, so the
  /// toggle needs no extra endpoint.
  /// [plantFilter], when non-null, restricts Top Contributors and Intensity
  /// by Production Line to devices/equipment registered under that plant
  /// (`FacilityData.plant` / `EquipmentItem.factory`) — the other KPI cards
  /// are single configured Device IDs and are not plant-scoped.
  static Future<CarbonEmissionLiveData> resolve(
    CarbonDashboardConfig config, {
    String period = 'monthly',
    String? plantFilter,
  }) async {
    debugPrint('[CarbonEmissionDataService.resolve] period=$period plantFilter=$plantFilter '
        'config=${config.toJson()}');
    if (!config.isConfigured) {
      debugPrint('[CarbonEmissionDataService.resolve] config not configured, returning empty');
      return CarbonEmissionLiveData.empty;
    }

    final daily = period == 'daily';
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final periodStart = daily ? DateTime(now.year, now.month, now.day) : monthStart;

    final allDeviceIds = <String>{
      if (config.netEmissionDeviceId != null) config.netEmissionDeviceId!,
      if (config.carbonIntensityDeviceId != null) config.carbonIntensityDeviceId!,
      if (config.totalConsumptionDeviceId != null) config.totalConsumptionDeviceId!,
      if (config.solarDeviceId != null) config.solarDeviceId!,
      if (config.blockADeviceId != null) config.blockADeviceId!,
      if (config.blockBDeviceId != null) config.blockBDeviceId!,
      if (config.blockCDeviceId != null) config.blockCDeviceId!,
      ...config.topContributorDeviceIds,
    };

    final factorFuture = fetchActiveEmissionFactor();
    final totalsFuture = _fetchEnergyTotalsBatched(allDeviceIds);
    final monthlySeriesFuture = config.netEmissionDeviceId != null
        ? _fetchSeries(config.netEmissionDeviceId!, 'monthly')
        : Future.value(const CarbonEmissionSeries());
    final dailySpark = <String, Future<CarbonEmissionSeries>>{
      for (final d in {
        if (config.netEmissionDeviceId != null) config.netEmissionDeviceId!,
        if (config.carbonIntensityDeviceId != null) config.carbonIntensityDeviceId!,
        if (config.totalConsumptionDeviceId != null) config.totalConsumptionDeviceId!,
        if (config.solarDeviceId != null) config.solarDeviceId!,
      })
        d: _fetchSeries(d, 'daily'),
    };
    final siteTonnageFuture = config.carbonIntensityDeviceId != null
        ? _fetchKwhPerTonne(from: periodStart, to: now)
        : Future.value((kwhConsumed: 0.0, tonnesProduced: 0.0));
    final facilitiesFuture = FacilityService.getFacilities().catchError((_) => <FacilityData>[]);
    final equipmentsFuture = config.productionLineEquipmentIds.isNotEmpty
        ? FacilityService.getEquipments().catchError((_) => <EquipmentItem>[])
        : Future.value(<EquipmentItem>[]);

    final factor = await factorFuture;
    final totals = await totalsFuture;
    final monthlySeries = await monthlySeriesFuture;
    final spark = <String, CarbonEmissionSeries>{};
    for (final entry in dailySpark.entries) {
      spark[entry.key] = await entry.value;
    }
    final siteTonnage = await siteTonnageFuture;
    final facilities = await facilitiesFuture;
    final equipments = await equipmentsFuture;

    double periodKwh(String? deviceId) {
      final t = deviceId != null ? totals[deviceId] : null;
      if (t == null) return 0;
      return daily ? t.dailyKwh : t.monthlyKwh;
    }

    double? kwhToTco2e(String? deviceId) {
      if (deviceId == null) return null;
      return periodKwh(deviceId) * factor / 1000;
    }

    // ── Net Carbon Emission ──────────────────────────────────────────────
    final netEmissionTco2e = kwhToTco2e(config.netEmissionDeviceId);
    final netSpark = config.netEmissionDeviceId != null ? spark[config.netEmissionDeviceId] : null;

    // ── Carbon Intensity = live emission (kg) ÷ site tonnage (period) ────
    double? carbonIntensityKgPerTon;
    if (config.carbonIntensityDeviceId != null) {
      final kwh = periodKwh(config.carbonIntensityDeviceId);
      final kg = kwh * factor;
      carbonIntensityKgPerTon = siteTonnage.tonnesProduced > 0 ? kg / siteTonnage.tonnesProduced : null;
    }
    final intensitySpark = config.carbonIntensityDeviceId != null ? spark[config.carbonIntensityDeviceId] : null;

    // ── Total Energy Consumption ─────────────────────────────────────────
    final totalConsumptionKwh =
        config.totalConsumptionDeviceId != null ? periodKwh(config.totalConsumptionDeviceId) : null;
    final consumptionSpark = config.totalConsumptionDeviceId != null ? spark[config.totalConsumptionDeviceId] : null;

    // ── Solar Avoided Emission ───────────────────────────────────────────
    final solarKwh = config.solarDeviceId != null ? periodKwh(config.solarDeviceId) : null;
    final solarAvoidedTco2e = kwhToTco2e(config.solarDeviceId);
    final solarSpark = config.solarDeviceId != null ? spark[config.solarDeviceId] : null;

    // ── Carbon Flow blocks (A/B/C) — grid import per block Device ID ×
    // Emission Factor · tCO2e.
    final blockDefs = [
      (label: 'Block A', color: kCarbonFlowBlocks[0].color, deviceId: config.blockADeviceId),
      (label: 'Block B', color: kCarbonFlowBlocks[1].color, deviceId: config.blockBDeviceId),
      (label: 'Block C', color: kCarbonFlowBlocks[2].color, deviceId: config.blockCDeviceId),
    ];
    final blockTco2e = [
      for (final b in blockDefs) kwhToTco2e(b.deviceId) ?? 0.0,
    ];
    final blockTco2eTotal = blockTco2e.fold<double>(0, (s, v) => s + v);
    final blocks = [
      for (var i = 0; i < blockDefs.length; i++)
        CarbonFlowBlock(
          label: blockDefs[i].label,
          percent: blockTco2eTotal > 0 ? blockTco2e[i] / blockTco2eTotal * 100 : 0,
          tco2e: blockTco2e[i],
          color: blockDefs[i].color,
          deviceId: blockDefs[i].deviceId,
        ),
    ];

    // ── Top Carbon Contributors ──────────────────────────────────────────
    String areaLabel(String deviceId) {
      for (final f in facilities) {
        if (f.meterId == deviceId) {
          if (f.productionArea.isNotEmpty) return f.productionArea;
          if (f.meterName.isNotEmpty) return f.meterName;
        }
      }
      return deviceId;
    }

    bool matchesPlant(String deviceId) {
      if (plantFilter == null || plantFilter.isEmpty) return true;
      for (final f in facilities) {
        if (f.meterId == deviceId) return f.plant == plantFilter;
      }
      // Device not found in Master Facility Setting — can't confirm plant
      // membership, so exclude it rather than showing it under every plant.
      return false;
    }

    final contributorEntries = [
      for (final deviceId in config.topContributorDeviceIds)
        if (matchesPlant(deviceId)) (deviceId: deviceId, tco2e: kwhToTco2e(deviceId) ?? 0),
    ]..sort((a, b) => b.tco2e.compareTo(a.tco2e));
    final contributorTotal = contributorEntries.fold<double>(0, (s, e) => s + e.tco2e);
    // Share is measured against total (net) emission when the Net Carbon
    // Emission device is configured — not against the ticked devices' own sum,
    // which would always add up to 100%.
    final shareBase = (netEmissionTco2e != null && netEmissionTco2e > 0) ? netEmissionTco2e : contributorTotal;
    final contributors = [
      for (var i = 0; i < contributorEntries.length; i++)
        CarbonContributor(
          rank: i + 1,
          area: areaLabel(contributorEntries[i].deviceId),
          tco2e: contributorEntries[i].tco2e,
          sharePercent: shareBase > 0 ? contributorEntries[i].tco2e / shareBase * 100 : 0,
          deviceId: contributorEntries[i].deviceId,
        ),
    ];

    // ── Emission Breakdown — production-line contributors vs. remainder ─
    final breakdownProductionLines = contributorTotal;
    final breakdownUtilities =
        netEmissionTco2e != null ? (netEmissionTco2e - contributorTotal).clamp(0.0, double.infinity) : 0.0;

    // ── Emission Trend (Actual) — live monthly series × Emission Factor ──
    final trendPoints = [
      for (final base in kEmissionTrend)
        EmissionTrendPoint(
          month: base.month,
          actual: monthlySeries.valueForLabel(base.month) != null
              ? monthlySeries.valueForLabel(base.month)! * factor / 1000
              : null,
          target: base.target,
          forecast: base.forecast,
        ),
    ];

    // ── Intensity by Production Line — configured equipment's own meter ──
    final productionLineRows = <CarbonProductionLineLive>[];
    if (config.productionLineEquipmentIds.isNotEmpty && equipments.isNotEmpty) {
      for (final id in config.productionLineEquipmentIds) {
        EquipmentItem? eq;
        for (final e in equipments) {
          if (e.equipmentId == id || e.id == id) {
            eq = e;
            break;
          }
        }
        if (eq == null) continue;
        if (plantFilter != null && plantFilter.isNotEmpty && eq.factory != plantFilter) continue;
        final log = await _fetchKwhPerTonne(machineId: eq.name, from: monthStart, to: now);
        if (log.tonnesProduced <= 0) continue;
        final intensityKg = log.kwhConsumed * factor / log.tonnesProduced;
        final targetKg = eq.targetKwhPerTonne * factor;
        productionLineRows.add(CarbonProductionLineLive(
          line: eq.productionLine.isNotEmpty ? eq.productionLine : eq.name,
          productionTon: log.tonnesProduced,
          intensityKgPerTon: intensityKg,
          targetKgPerTon: targetKg,
        ));
      }
    }

    final resolved = CarbonEmissionLiveData(
      emissionFactorKgPerKwh: factor,
      netEmissionTco2e: netEmissionTco2e,
      netEmissionDeltaPercent: netSpark?.deltaPercent,
      netEmissionSpark: netSpark?.normalized() ?? const [],
      carbonIntensityKgPerTon: carbonIntensityKgPerTon,
      carbonIntensityDeltaPercent: intensitySpark?.deltaPercent,
      carbonIntensitySpark: intensitySpark?.normalized() ?? const [],
      siteTonnesProduced: siteTonnage.tonnesProduced,
      totalConsumptionKwh: totalConsumptionKwh,
      totalConsumptionDeltaPercent: consumptionSpark?.deltaPercent,
      totalConsumptionSpark: consumptionSpark?.normalized() ?? const [],
      solarKwh: solarKwh,
      solarAvoidedTco2e: solarAvoidedTco2e,
      solarDeltaPercent: solarSpark?.deltaPercent,
      solarSpark: solarSpark?.normalized() ?? const [],
      carbonCostPerTco2e: _cachedCarbonCost,
      gridImportMwh: totalConsumptionKwh != null ? totalConsumptionKwh / 1000 : null,
      blocks: blocks,
      breakdownProductionLinesTco2e: breakdownProductionLines,
      breakdownUtilitiesTco2e: breakdownUtilities,
      contributors: contributors,
      trendPoints: trendPoints,
      productionLineRows: productionLineRows,
    );
    debugPrint('[CarbonEmissionDataService.resolve] result: '
        'factor=$factor netEmissionTco2e=$netEmissionTco2e '
        'carbonIntensityKgPerTon=$carbonIntensityKgPerTon '
        'totalConsumptionKwh=$totalConsumptionKwh solarKwh=$solarKwh '
        'solarAvoidedTco2e=$solarAvoidedTco2e blocksTco2e=$blockTco2e '
        'contributors=${contributors.length} productionLineRows=${productionLineRows.length} '
        'deviceTotals=${totals.map((k, v) => MapEntry(k, {'daily': v.dailyKwh, 'monthly': v.monthlyKwh}))}');
    return resolved;
  }
}
