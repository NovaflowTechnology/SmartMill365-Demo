import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/app_config.dart';
import 'air_compressor_dashboard_config.dart';

/// Live telemetry resolved from [AirCompressorDashboardConfig]'s mapped
/// Device IDs — the counterpart of `PeccDataService`/`CarbonEmissionDataService`
/// for Air Compressor Monitoring.
///
/// Only Total Power / AC1 / AC2 — as Active Power (kW), Total Energy (kWh),
/// or Max Demand (kW), whichever METRIC FIELD is mapped — are backed by a
/// live fetch today. Max Demand (kW) reads a trailing 30-minute rolling
/// average of Active Power (TNB's own demand definition) via
/// `demand-load/current` — it's a live "current demand" snapshot, not the
/// true monthly billing peak (see `max_demand_monitoring`, which reads that
/// from MySQL rollup tables instead). Power Factor / Reactive Power /
/// Current stay unsupported (null) regardless of mapping — the shared
/// `energyDetailsInfluxDb` backend has no per-device live endpoint for
/// them yet. Header Flow, Header Pressure, and Demand Side flow aren't
/// power values and the backend has no field category for them yet, so
/// `headerFlowValue` stays null (and Specific Energy = Total Power ÷
/// Header Flow renders "N/A") until that's added.
class AcLiveData {
  final double? totalPowerValue;
  final String totalPowerUnit;
  final bool totalPowerFieldSupported;
  final double? ac1Value;
  final String ac1Unit;
  final bool ac1FieldSupported;
  final double? ac2Value;
  final String ac2Unit;
  final bool ac2FieldSupported;
  // Header Flow (m³/min) — no live backend field category exists yet, so
  // this is always null until one does.
  final double? headerFlowValue;

  const AcLiveData({
    this.totalPowerValue,
    this.totalPowerUnit = 'kW',
    this.totalPowerFieldSupported = true,
    this.ac1Value,
    this.ac1Unit = 'kW',
    this.ac1FieldSupported = true,
    this.ac2Value,
    this.ac2Unit = 'kW',
    this.ac2FieldSupported = true,
    this.headerFlowValue,
  });

  static const empty = AcLiveData();
}

class AirCompressorDataService {
  static String get _powerLoadCurrentBase => '${AppConfig.dataApiBaseSafe}/energyDetailsInfluxDb/power-load/current';
  static String get _energyLoadCurrentBase => '${AppConfig.dataApiBaseSafe}/energyDetailsInfluxDb/energy-load/current';
  static String get _demandLoadCurrentBase => '${AppConfig.dataApiBaseSafe}/energyDetailsInfluxDb/demand-load/current';

  /// 'Active Power (kW)' (or no field selected yet, which defaults to it),
  /// 'Total Energy (kWh)', and 'Max Demand (kW)' are the METRIC FIELDs
  /// backed by a live fetch — Power Factor / Reactive Power / Current have
  /// no live endpoint yet.
  static bool _hasLiveSource(String? field) =>
      field == null || field == 'Active Power (kW)' || field == 'Total Energy (kWh)' || field == 'Max Demand (kW)';

  static String _unitFor(String? field) => field == 'Total Energy (kWh)' ? 'kWh' : 'kW';

  static Future<double?> _fetchByField(String deviceId, String? field) {
    if (field == 'Total Energy (kWh)') return _fetchEnergyKwh(deviceId);
    if (field == 'Max Demand (kW)') return _fetchDemandKw(deviceId);
    return _fetchPowerKw(deviceId);
  }

  static Future<AcLiveData> resolve(AirCompressorDashboardConfig config) async {
    final results = await Future.wait([
      _hasLiveSource(config.totalPowerField) && config.totalPowerDeviceIds.isNotEmpty
          ? _fetchByField(config.totalPowerDeviceIds.join(','), config.totalPowerField)
          : Future.value(null),
      _hasLiveSource(config.ac1Field) && config.ac1DeviceId != null
          ? _fetchByField(config.ac1DeviceId!, config.ac1Field)
          : Future.value(null),
      _hasLiveSource(config.ac2Field) && config.ac2DeviceId != null
          ? _fetchByField(config.ac2DeviceId!, config.ac2Field)
          : Future.value(null),
    ]);

    return AcLiveData(
      totalPowerValue: results[0],
      totalPowerUnit: _unitFor(config.totalPowerField),
      totalPowerFieldSupported: _hasLiveSource(config.totalPowerField),
      ac1Value: results[1],
      ac1Unit: _unitFor(config.ac1Field),
      ac1FieldSupported: _hasLiveSource(config.ac1Field),
      ac2Value: results[2],
      ac2Unit: _unitFor(config.ac2Field),
      ac2FieldSupported: _hasLiveSource(config.ac2Field),
      // headerFlowValue stays null — no live backend field category exists.
    );
  }

  static Future<double?> _fetchPowerKw(String deviceId) async {
    if (deviceId.isEmpty) return null;
    try {
      final uri = Uri.parse(_powerLoadCurrentBase).replace(queryParameters: {'deviceId': deviceId});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final v = body['power_kw'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    } catch (e) {
      debugPrint('[AirCompressorDataService._fetchPowerKw] error for deviceId=$deviceId: $e');
      return null;
    }
  }

  static Future<double?> _fetchEnergyKwh(String deviceId) async {
    if (deviceId.isEmpty) return null;
    try {
      final uri = Uri.parse(_energyLoadCurrentBase).replace(queryParameters: {'deviceId': deviceId});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final v = body['energy_kwh'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    } catch (e) {
      debugPrint('[AirCompressorDataService._fetchEnergyKwh] error for deviceId=$deviceId: $e');
      return null;
    }
  }

  static Future<double?> _fetchDemandKw(String deviceId) async {
    if (deviceId.isEmpty) return null;
    try {
      final uri = Uri.parse(_demandLoadCurrentBase).replace(queryParameters: {'deviceId': deviceId});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final v = body['demand_kw'];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    } catch (e) {
      debugPrint('[AirCompressorDataService._fetchDemandKw] error for deviceId=$deviceId: $e');
      return null;
    }
  }
}
