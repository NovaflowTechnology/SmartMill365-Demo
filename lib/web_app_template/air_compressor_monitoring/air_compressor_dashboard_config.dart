import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_config.dart';

/// CHANNEL MAPPING — METRIC FIELD options offered next to each Device ID
/// dropdown, grouped by the physical quantity a slot reads. Mirrors PECC's
/// "DATA SCOPE" + "METRIC FIELD" two-level mapping. 'Active Power (kW)',
/// 'Total Energy (kWh)', and 'Max Demand (kW)' are backed by a live fetch
/// (see `AirCompressorDataService`) — the rest are stored for the mapping
/// but still render the existing demo-gated values until their telemetry
/// field is wired up on the backend.
const List<String> kAcPowerMetricFields = [
  'Active Power (kW)',
  'Total Energy (kWh)',
  'Max Demand (kW)',
  'Power Factor (%)',
  'Reactive Power (kVAR)',
  'Current (A)',
];
const List<String> kAcFlowMetricFields = [
  'Flow Rate (m³/min)',
  'Cumulative Flow (m³)',
];
const List<String> kAcPressureMetricFields = [
  'Pressure (bar)',
  'Differential Pressure (bar)',
];

/// One "Demand Side" load row (e.g. a CAST) — a manual pressure/flow
/// requirement plus an optional live-flow Device ID, mapped independently
/// per load since each cast draws from a different point on the header.
class AcDemandLoadConfig {
  final String label;
  final double? reqPressure;
  final double? reqFlow;
  final String? deviceId;
  final String? field;

  const AcDemandLoadConfig({required this.label, this.reqPressure, this.reqFlow, this.deviceId, this.field});

  factory AcDemandLoadConfig.fromJson(Map<String, dynamic> json) => AcDemandLoadConfig(
        label: json['label'] as String? ?? '',
        reqPressure: (json['reqPressure'] as num?)?.toDouble(),
        reqFlow: (json['reqFlow'] as num?)?.toDouble(),
        deviceId: json['deviceId'] as String?,
        field: json['field'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'reqPressure': reqPressure,
        'reqFlow': reqFlow,
        'deviceId': deviceId,
        'field': field,
      };
}

/// Card → Device ID mapping for the Air Compressor Monitoring dashboard.
///
/// Every field here points at a `meterId` from Master Facility Setting,
/// matching the same source Carbon Dashboard Config reads from. Saved
/// config is read back by `AirCompressorMonitoringWidget` on load.
class AirCompressorDashboardConfig {
  // Top KPI — Total Power = Σ of selected compressor Device IDs.
  final List<String> totalPowerDeviceIds;
  final String? totalPowerField;
  final String? headerFlowDeviceId;
  final String? headerFlowField;
  final String? headerPressureDeviceId;
  final String? headerPressureField;

  // Distribution to Header — exactly 2 compressor slots (matches what the
  // dashboard's Sankey diagram actually renders today).
  final String? ac1DeviceId;
  final String? ac1Field;
  final String? ac2DeviceId;
  final String? ac2Field;

  // Trend chart parameters — null until set in Air Compressor Dashboard
  // Setting, in which case the dashboard omits the benchmark/threshold line
  // instead of drawing a fabricated default.
  final double? seBandLow;
  final double? seBandHigh;
  final double? minFlowThreshold;
  final String nightWindowStart;
  final String nightWindowEnd;

  // System Status — free text / device sources. Null until the user sets
  // them in Air Compressor Dashboard Setting — displayed as "N/A". Leakage
  // Status stays rule-computed (night window + min-flow) — no device slot.
  final String? nextMaintenanceLabel;
  final String? availabilityDeviceId;
  final String? downtimeDeviceId;
  final String? dewPointDeviceId;

  // Compressor Efficiency — Role (Base-load/Peak) is computed from each
  // compressor's specific energy vs seBandHigh by default; toggling to
  // manual lets the user force a role per compressor instead.
  final bool roleAssignmentAuto;
  final String? ac1RoleOverride;
  final String? ac2RoleOverride;

  // Demand Side — one entry per CAST/consumer load, keyed by label.
  final List<AcDemandLoadConfig> demandLoads;

  const AirCompressorDashboardConfig({
    this.totalPowerDeviceIds = const [],
    this.totalPowerField,
    this.headerFlowDeviceId,
    this.headerFlowField,
    this.headerPressureDeviceId,
    this.headerPressureField,
    this.ac1DeviceId,
    this.ac1Field,
    this.ac2DeviceId,
    this.ac2Field,
    this.seBandLow,
    this.seBandHigh,
    this.minFlowThreshold,
    this.nightWindowStart = '22:00',
    this.nightWindowEnd = '06:00',
    this.nextMaintenanceLabel,
    this.availabilityDeviceId,
    this.downtimeDeviceId,
    this.dewPointDeviceId,
    this.roleAssignmentAuto = true,
    this.ac1RoleOverride,
    this.ac2RoleOverride,
    this.demandLoads = const [],
  });

  factory AirCompressorDashboardConfig.empty() => const AirCompressorDashboardConfig();

  bool get isConfigured =>
      totalPowerDeviceIds.isNotEmpty ||
      headerFlowDeviceId != null ||
      headerPressureDeviceId != null ||
      ac1DeviceId != null ||
      ac2DeviceId != null;

  /// Number of mapped slots out of the total mappable slots — drives the
  /// settings page's completion ring.
  int get mappedCount => [
        if (totalPowerDeviceIds.isNotEmpty) true,
        if (headerFlowDeviceId != null) true,
        if (headerPressureDeviceId != null) true,
        if (ac1DeviceId != null) true,
        if (ac2DeviceId != null) true,
      ].length;
  static const int totalSlots = 5;

  AirCompressorDashboardConfig copyWith({
    List<String>? totalPowerDeviceIds,
    String? totalPowerField,
    String? headerFlowDeviceId,
    String? headerFlowField,
    String? headerPressureDeviceId,
    String? headerPressureField,
    String? ac1DeviceId,
    String? ac1Field,
    String? ac2DeviceId,
    String? ac2Field,
    double? seBandLow,
    double? seBandHigh,
    double? minFlowThreshold,
    String? nightWindowStart,
    String? nightWindowEnd,
    String? nextMaintenanceLabel,
    String? availabilityDeviceId,
    String? downtimeDeviceId,
    String? dewPointDeviceId,
    bool? roleAssignmentAuto,
    String? ac1RoleOverride,
    String? ac2RoleOverride,
    List<AcDemandLoadConfig>? demandLoads,
  }) {
    return AirCompressorDashboardConfig(
      totalPowerDeviceIds: totalPowerDeviceIds ?? this.totalPowerDeviceIds,
      totalPowerField: totalPowerField ?? this.totalPowerField,
      headerFlowDeviceId: headerFlowDeviceId ?? this.headerFlowDeviceId,
      headerFlowField: headerFlowField ?? this.headerFlowField,
      headerPressureDeviceId: headerPressureDeviceId ?? this.headerPressureDeviceId,
      headerPressureField: headerPressureField ?? this.headerPressureField,
      ac1DeviceId: ac1DeviceId ?? this.ac1DeviceId,
      ac1Field: ac1Field ?? this.ac1Field,
      ac2DeviceId: ac2DeviceId ?? this.ac2DeviceId,
      ac2Field: ac2Field ?? this.ac2Field,
      seBandLow: seBandLow ?? this.seBandLow,
      seBandHigh: seBandHigh ?? this.seBandHigh,
      minFlowThreshold: minFlowThreshold ?? this.minFlowThreshold,
      nightWindowStart: nightWindowStart ?? this.nightWindowStart,
      nightWindowEnd: nightWindowEnd ?? this.nightWindowEnd,
      nextMaintenanceLabel: nextMaintenanceLabel ?? this.nextMaintenanceLabel,
      availabilityDeviceId: availabilityDeviceId ?? this.availabilityDeviceId,
      downtimeDeviceId: downtimeDeviceId ?? this.downtimeDeviceId,
      dewPointDeviceId: dewPointDeviceId ?? this.dewPointDeviceId,
      roleAssignmentAuto: roleAssignmentAuto ?? this.roleAssignmentAuto,
      ac1RoleOverride: ac1RoleOverride ?? this.ac1RoleOverride,
      ac2RoleOverride: ac2RoleOverride ?? this.ac2RoleOverride,
      demandLoads: demandLoads ?? this.demandLoads,
    );
  }

  factory AirCompressorDashboardConfig.fromJson(Map<String, dynamic> json) {
    return AirCompressorDashboardConfig(
      totalPowerDeviceIds: (json['totalPowerDeviceIds'] as List?)?.cast<String>() ?? const [],
      totalPowerField: json['totalPowerField'] as String?,
      headerFlowDeviceId: json['headerFlowDeviceId'] as String?,
      headerFlowField: json['headerFlowField'] as String?,
      headerPressureDeviceId: json['headerPressureDeviceId'] as String?,
      headerPressureField: json['headerPressureField'] as String?,
      ac1DeviceId: json['ac1DeviceId'] as String?,
      ac1Field: json['ac1Field'] as String?,
      ac2DeviceId: json['ac2DeviceId'] as String?,
      ac2Field: json['ac2Field'] as String?,
      seBandLow: (json['seBandLow'] as num?)?.toDouble(),
      seBandHigh: (json['seBandHigh'] as num?)?.toDouble(),
      minFlowThreshold: (json['minFlowThreshold'] as num?)?.toDouble(),
      nightWindowStart: json['nightWindowStart'] as String? ?? '22:00',
      nightWindowEnd: json['nightWindowEnd'] as String? ?? '06:00',
      nextMaintenanceLabel: json['nextMaintenanceLabel'] as String?,
      availabilityDeviceId: json['availabilityDeviceId'] as String?,
      downtimeDeviceId: json['downtimeDeviceId'] as String?,
      dewPointDeviceId: json['dewPointDeviceId'] as String?,
      roleAssignmentAuto: json['roleAssignmentAuto'] as bool? ?? true,
      ac1RoleOverride: json['ac1RoleOverride'] as String?,
      ac2RoleOverride: json['ac2RoleOverride'] as String?,
      demandLoads: (json['demandLoads'] as List?)?.map((e) => AcDemandLoadConfig.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPowerDeviceIds': totalPowerDeviceIds,
        'totalPowerField': totalPowerField,
        'headerFlowDeviceId': headerFlowDeviceId,
        'headerFlowField': headerFlowField,
        'headerPressureDeviceId': headerPressureDeviceId,
        'headerPressureField': headerPressureField,
        'ac1DeviceId': ac1DeviceId,
        'ac1Field': ac1Field,
        'ac2DeviceId': ac2DeviceId,
        'ac2Field': ac2Field,
        'seBandLow': seBandLow,
        'seBandHigh': seBandHigh,
        'minFlowThreshold': minFlowThreshold,
        'nightWindowStart': nightWindowStart,
        'nightWindowEnd': nightWindowEnd,
        'nextMaintenanceLabel': nextMaintenanceLabel,
        'availabilityDeviceId': availabilityDeviceId,
        'downtimeDeviceId': downtimeDeviceId,
        'dewPointDeviceId': dewPointDeviceId,
        'roleAssignmentAuto': roleAssignmentAuto,
        'ac1RoleOverride': ac1RoleOverride,
        'ac2RoleOverride': ac2RoleOverride,
        'demandLoads': demandLoads.map((d) => d.toJson()).toList(),
      };
}

/// Local cache for [AirCompressorDashboardConfig], via SharedPreferences
/// (same mechanism used by `CarbonDashboardConfigStore`). Used as an
/// instant fallback/paint while [AirCompressorDashboardConfigService] (the
/// backend) is unreachable — no active client, offline, or a debug
/// entrypoint without Firebase. Scoped per plant.
class AirCompressorDashboardConfigStore {
  static String _keyFor(String plant) => 'air_compressor_dashboard_config_v1::$plant';

  static Future<AirCompressorDashboardConfig> load(String plant) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(plant));
    if (raw == null || raw.isEmpty) return AirCompressorDashboardConfig.empty();
    try {
      return AirCompressorDashboardConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AirCompressorDashboardConfig.empty();
    }
  }

  static Future<void> save(String plant, AirCompressorDashboardConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(plant), jsonEncode(config.toJson()));
  }
}

/// Backend persistence for [AirCompressorDashboardConfig] — `GET/POST
/// /air-compressor-dashboard-config/:uid?plant=` (see
/// `functions/api/airCompressorDashboardConfigFunction.js`).
///
/// Scoped per tenant via the `x-client-id` header (auto-attached by
/// [AppConfig.headers]) and per [plant], same multi-tenant Firestore
/// resolution pattern used by `CarbonDashboardConfigService`.
class AirCompressorDashboardConfigService {
  static String get _base => '${AppConfig.dataApiBaseSafe}/air-compressor-dashboard-config';

  /// Fetches the saved config for [uid] + [plant]. Returns `null` on any
  /// failure (offline, no active client, uid missing, etc.) so callers can
  /// fall back to the local [AirCompressorDashboardConfigStore] cache.
  static Future<AirCompressorDashboardConfig?> fetch(String uid, String plant) async {
    if (uid.isEmpty || plant.isEmpty) return null;
    try {
      final uri = Uri.parse('$_base/$uid').replace(queryParameters: {'plant': plant});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      debugPrint('[AirCompressorDashboardConfigService.fetch] GET $uri -> ${res.statusCode} ${res.body}');
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['exists'] != true) return AirCompressorDashboardConfig.empty();
      return AirCompressorDashboardConfig.fromJson(data);
    } catch (e) {
      debugPrint('[AirCompressorDashboardConfigService.fetch] error for uid=$uid plant=$plant: $e');
      return null;
    }
  }

  /// Saves [config] for [uid] + [plant]. Returns true on success; failures
  /// are non-fatal since the caller also persists to the local store.
  static Future<bool> save(String uid, String plant, AirCompressorDashboardConfig config) async {
    if (uid.isEmpty || plant.isEmpty) return false;
    try {
      final uri = Uri.parse('$_base/$uid').replace(queryParameters: {'plant': plant});
      final res = await http.post(uri, headers: AppConfig.headers, body: jsonEncode(config.toJson())).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
