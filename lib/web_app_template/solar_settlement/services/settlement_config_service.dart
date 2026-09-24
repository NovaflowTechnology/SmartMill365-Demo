import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_models.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';

import '../models/settlement_config.dart';
import '../models/settlement_masters.dart';

class ConfigLoadResult {
  const ConfigLoadResult({
    required this.config,
    this.saved = false,
    this.failed = false,
  });

  final SettlementConfig config;

  /// A config has been saved before. False means the defaults are showing.
  final bool saved;

  /// The store could not be read. Distinct from "never saved": saving over a
  /// config that merely failed to load would silently replace it.
  final bool failed;
}

/// Where the settlement's terms are kept, and the master lists they refer to.
///
/// The terms are one document shared by every user of the client. They sit in
/// the Plant Energy Command Center settings collection under their own key
/// (`shared__solar-settlement`) because that is the one deployed store that is
/// isolated per client by `x-client-id` and keeps a free-form map as written.
/// No dashboard reads that key, so nothing else sees it. A dedicated endpoint
/// can replace this without touching any caller.
class SettlementConfigService {
  const SettlementConfigService._();

  static const _storeKey = 'solar-settlement';

  static Uri get _storeUri => Uri.parse(
      '${AppConfig.dataApiBaseSafe}/plant-energy-command-center/'
      '${AppConfig.sharedConfigOwnerId}');

  static Future<ConfigLoadResult> load() async {
    try {
      final res = await http
          .get(
            _storeUri.replace(queryParameters: {'plantId': _storeKey}),
            headers: AppConfig.headers,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return const ConfigLoadResult(config: SettlementConfig(), failed: true);
      }
      final body = jsonDecode(res.body);
      final settings = body is Map ? body['settings'] : null;
      final branding = settings is Map ? settings['branding'] : null;
      final raw = branding is Map ? branding['solarSettlement'] : null;
      if (body is Map && body['exists'] == true && raw is Map) {
        return ConfigLoadResult(
            config: SettlementConfig.fromJson(raw), saved: true);
      }
      return const ConfigLoadResult(config: SettlementConfig());
    } catch (_) {
      return const ConfigLoadResult(config: SettlementConfig(), failed: true);
    }
  }

  /// Returns false when the write did not land, so the page can say so
  /// instead of showing a change that was lost.
  static Future<bool> save(SettlementConfig config) async {
    try {
      final res = await http
          .post(
            _storeUri,
            headers: {...AppConfig.headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'plantId': _storeKey,
              // Required by the endpoint; this document has no dashboard
              // sections of its own.
              'sections': const [],
              'branding': {'solarSettlement': config.toJson()},
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Plants, TNB meters and tariff category names, plus Master Facilities
  /// meters when [withDevices] — the dashboard does not need the device list,
  /// and it is the largest of the four.
  static Future<SettlementMasters> loadMasters({bool withDevices = false}) async {
    final results = await Future.wait<Object>([
      TnbMeterService.fetchPlants(),
      TnbMeterService.fetchMeters(),
      TnbMeterService.fetchTariffCategories(),
      withDevices
          ? FacilityService.getFacilities().catchError((_) => <FacilityData>[])
          : Future.value(<FacilityData>[]),
    ]);

    final plants = <PlantRef>[
      for (final p in results[0] as List<Map<String, dynamic>>)
        if ((p['id']?.toString() ?? '').isNotEmpty &&
            (p['name']?.toString().trim() ?? '').isNotEmpty)
          PlantRef(id: p['id'].toString(), name: p['name'].toString().trim()),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final categoryNames = <String, String>{
      for (final c in results[2] as List<Map<String, dynamic>>)
        if ((c['id']?.toString() ?? '').isNotEmpty)
          c['id'].toString():
              (c['tariffCategory'] ?? c['tariffName'] ?? c['id']).toString(),
    };

    final devices = <String, DeviceRef>{};
    for (final f in results[3] as List<FacilityData>) {
      final id = f.meterId.trim();
      if (id.isEmpty || id == '-' || devices.containsKey(id)) continue;
      String clean(String s) => s.trim() == '-' ? '' : s.trim();
      devices[id] = DeviceRef(
        id: id,
        name: clean(f.meterName).isNotEmpty
            ? clean(f.meterName)
            : clean(f.equipmentNameId),
        plant: clean(f.plant),
        zone: clean(f.zone),
        type: clean(f.equipmentType),
      );
    }
    final deviceList = devices.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return SettlementMasters(
      plants: plants,
      meters: results[1] as List<TnbMeter>,
      categoryNames: categoryNames,
      devices: deviceList,
    );
  }

  /// TNB peak and off-peak rates for a tariff category, from Master Billing.
  ///
  /// The category's own billing config is read first. Categories saved so far
  /// carry no energy rates of their own, so the shared electricity tariff that
  /// Master Billing deploys — and displays for every category — is the
  /// fallback, and the result says which one answered.
  static Future<TnbRates> tnbRates(String categoryId) async {
    // No category means the chain is broken at the meter. Answering with the
    // shared tariff anyway would price a comparison nobody linked.
    if (categoryId.isEmpty) return const TnbRates();
    const owner = AppConfig.sharedConfigOwnerId;
    final base = '${AppConfig.dataApiBaseSafe}/masterBillingConfig/$owner';
    try {
      final results = await Future.wait([
        http
            .get(Uri.parse('$base/$categoryId'), headers: AppConfig.headers)
            .timeout(const Duration(seconds: 15)),
        http
            .get(Uri.parse('$base/electricityTariff'),
                headers: AppConfig.headers)
            .timeout(const Duration(seconds: 15)),
      ]);

      if (results[0].statusCode == 200) {
        final body = jsonDecode(results[0].body);
        final cfg = body is Map ? body['config'] : null;
        if (cfg is Map) {
          final peak = _toDouble(cfg['peakRate']);
          final offPeak = _toDouble(cfg['offPeakRate']);
          if (peak > 0 || offPeak > 0) {
            return TnbRates(
                peak: peak, offPeak: offPeak, source: TnbRateSource.category);
          }
        }
      }

      if (results[1].statusCode == 200) {
        final t = jsonDecode(results[1].body);
        if (t is Map) {
          final peak = _toDouble(t['peakRate']);
          final offPeak = _toDouble(t['offPeakRate']);
          if (peak > 0 || offPeak > 0) {
            return TnbRates(
                peak: peak,
                offPeak: offPeak,
                source: TnbRateSource.electricityTariff);
          }
        }
      }
    } catch (_) {}
    return const TnbRates();
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
