import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_config.dart';

/// Config scope key used when no facility/equipment has a Plant name
/// assigned yet (`FacilityData.plant` / `EquipmentItem.factory` are free
/// text and commonly left blank). Keeps the dashboard and its settings page
/// fully usable for single-plant/untagged deployments instead of requiring
/// Plant tagging before anything can be configured.
const String kUnassignedPlantKey = 'Unassigned';

/// Card → Device ID mapping for the Carbon Intelligence Dashboard.
///
/// Every field here points at a `meterId` from Master Facility Setting
/// (digital power meters flagged `includeCarbonCalc`) or an equipment id
/// from Equipment Settings (`enableEnergy` devices), matching the card ↔
/// source-of-truth annotations agreed for the dashboard.
class CarbonDashboardConfig {
  // Net Carbon Emission = Device ID × Emission Factor (tCO2e, daily/monthly)
  final String? netEmissionDeviceId;
  // Carbon Intensity = Device ID ÷ Production Output (kgCO2e/ton, daily/monthly)
  final String? carbonIntensityDeviceId;
  // Total Energy Consumption (Grid) = Device ID (kWh, daily/monthly)
  final String? totalConsumptionDeviceId;
  // Solar Avoided Emission = Device ID × Emission Factor (tCO2e, daily/monthly)
  final String? solarDeviceId;
  // Emission Cost = Net Carbon Emission × Carbon Price (RM/tCO2e)
  final double? carbonPricePerTco2e;
  // Carbon Flow — Grid Import per block, used when Production Area filter is selected
  final String? blockADeviceId;
  final String? blockBDeviceId;
  final String? blockCDeviceId;
  // Top 5 Carbon Contributors — selected Device IDs (Master Facility Setting)
  final List<String> topContributorDeviceIds;
  // Intensity by Production Line — equipment ids with Energy module enabled
  final List<String> productionLineEquipmentIds;

  const CarbonDashboardConfig({
    this.netEmissionDeviceId,
    this.carbonIntensityDeviceId,
    this.totalConsumptionDeviceId,
    this.solarDeviceId,
    this.carbonPricePerTco2e,
    this.blockADeviceId,
    this.blockBDeviceId,
    this.blockCDeviceId,
    this.topContributorDeviceIds = const [],
    this.productionLineEquipmentIds = const [],
  });

  factory CarbonDashboardConfig.empty() => const CarbonDashboardConfig();

  bool get isConfigured =>
      netEmissionDeviceId != null ||
      carbonIntensityDeviceId != null ||
      totalConsumptionDeviceId != null ||
      solarDeviceId != null ||
      carbonPricePerTco2e != null ||
      blockADeviceId != null ||
      blockBDeviceId != null ||
      blockCDeviceId != null ||
      topContributorDeviceIds.isNotEmpty ||
      productionLineEquipmentIds.isNotEmpty;

  CarbonDashboardConfig copyWith({
    String? netEmissionDeviceId,
    String? carbonIntensityDeviceId,
    String? totalConsumptionDeviceId,
    String? solarDeviceId,
    double? carbonPricePerTco2e,
    String? blockADeviceId,
    String? blockBDeviceId,
    String? blockCDeviceId,
    List<String>? topContributorDeviceIds,
    List<String>? productionLineEquipmentIds,
  }) {
    return CarbonDashboardConfig(
      netEmissionDeviceId: netEmissionDeviceId ?? this.netEmissionDeviceId,
      carbonIntensityDeviceId: carbonIntensityDeviceId ?? this.carbonIntensityDeviceId,
      totalConsumptionDeviceId: totalConsumptionDeviceId ?? this.totalConsumptionDeviceId,
      solarDeviceId: solarDeviceId ?? this.solarDeviceId,
      carbonPricePerTco2e: carbonPricePerTco2e ?? this.carbonPricePerTco2e,
      blockADeviceId: blockADeviceId ?? this.blockADeviceId,
      blockBDeviceId: blockBDeviceId ?? this.blockBDeviceId,
      blockCDeviceId: blockCDeviceId ?? this.blockCDeviceId,
      topContributorDeviceIds: topContributorDeviceIds ?? this.topContributorDeviceIds,
      productionLineEquipmentIds: productionLineEquipmentIds ?? this.productionLineEquipmentIds,
    );
  }

  factory CarbonDashboardConfig.fromJson(Map<String, dynamic> json) {
    return CarbonDashboardConfig(
      netEmissionDeviceId: json['netEmissionDeviceId'] as String?,
      carbonIntensityDeviceId: json['carbonIntensityDeviceId'] as String?,
      totalConsumptionDeviceId: json['totalConsumptionDeviceId'] as String?,
      solarDeviceId: json['solarDeviceId'] as String?,
      carbonPricePerTco2e: (json['carbonPricePerTco2e'] as num?)?.toDouble(),
      blockADeviceId: json['blockADeviceId'] as String?,
      blockBDeviceId: json['blockBDeviceId'] as String?,
      blockCDeviceId: json['blockCDeviceId'] as String?,
      topContributorDeviceIds: (json['topContributorDeviceIds'] as List?)?.cast<String>() ?? const [],
      productionLineEquipmentIds: (json['productionLineEquipmentIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'netEmissionDeviceId': netEmissionDeviceId,
        'carbonIntensityDeviceId': carbonIntensityDeviceId,
        'totalConsumptionDeviceId': totalConsumptionDeviceId,
        'solarDeviceId': solarDeviceId,
        'carbonPricePerTco2e': carbonPricePerTco2e,
        'blockADeviceId': blockADeviceId,
        'blockBDeviceId': blockBDeviceId,
        'blockCDeviceId': blockCDeviceId,
        'topContributorDeviceIds': topContributorDeviceIds,
        'productionLineEquipmentIds': productionLineEquipmentIds,
      };
}

/// Local cache for [CarbonDashboardConfig], via SharedPreferences (same
/// mechanism already used by `real_time_data_config`). Used as an instant
/// fallback when [CarbonDashboardConfigService] (the backend) is unreachable
/// — no active client, offline, or a debug entrypoint without Firebase.
///
/// Scoped per plant: every plant has its own saved Device ID mapping. The
/// pre-per-plant single cache entry ([_legacyKey]) is kept as a read-only
/// fallback default for any plant that hasn't been cached individually yet.
class CarbonDashboardConfigStore {
  static const _legacyKey = 'carbon_dashboard_config_v1';
  static String _keyFor(String plant) => 'carbon_dashboard_config_v1::$plant';

  static Future<CarbonDashboardConfig> load(String plant) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(plant)) ?? prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return CarbonDashboardConfig.empty();
    try {
      return CarbonDashboardConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CarbonDashboardConfig.empty();
    }
  }

  static Future<void> save(String plant, CarbonDashboardConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(plant), jsonEncode(config.toJson()));
  }
}

/// Backend persistence for [CarbonDashboardConfig] — `GET/POST
/// /carbon-dashboard-config/:uid?plant=` (see
/// `functions/api/carbonDashboardConfigFunction.js`).
///
/// Scoped per tenant via the `x-client-id` header (auto-attached by
/// [AppConfig.headers]), same multi-tenant Firestore-resolution pattern used
/// by `/facilities` and `/sankey-setting`: the config is written to the
/// active client's own Firestore project when one is configured, falling
/// back to the shared default project otherwise. Also scoped per [plant] —
/// each plant has its own saved Device ID mapping; the backend falls back to
/// the pre-per-plant global doc as a default for any plant not yet saved
/// individually.
class CarbonDashboardConfigService {
  static String get _base => '${AppConfig.dataApiBaseSafe}/carbon-dashboard-config';

  /// Fetches the saved config for [uid] + [plant]. Returns
  /// [CarbonDashboardConfig.empty] on any failure (offline, no active
  /// client, uid missing, etc.) so callers can fall back to the local
  /// [CarbonDashboardConfigStore] cache.
  static Future<CarbonDashboardConfig?> fetch(String uid, String plant) async {
    if (uid.isEmpty || plant.isEmpty) return null;
    try {
      final uri = Uri.parse('$_base/$uid').replace(queryParameters: {'plant': plant});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      debugPrint('[CarbonDashboardConfigService.fetch] GET $uri -> ${res.statusCode} ${res.body}');
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['exists'] != true) return CarbonDashboardConfig.empty();
      return CarbonDashboardConfig.fromJson(data);
    } catch (e) {
      debugPrint('[CarbonDashboardConfigService.fetch] error for uid=$uid plant=$plant: $e');
      return null;
    }
  }

  /// Saves [config] for [uid] + [plant]. Returns true on success; failures
  /// are non-fatal since the caller also persists to the local store.
  static Future<bool> save(String uid, String plant, CarbonDashboardConfig config) async {
    if (uid.isEmpty || plant.isEmpty) return false;
    try {
      final uri = Uri.parse('$_base/$uid').replace(queryParameters: {'plant': plant});
      final res = await http
          .post(uri, headers: AppConfig.headers, body: jsonEncode(config.toJson()))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
