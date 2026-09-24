import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

/// Which of the two equipment-level charts a "Configure" action targets.
/// Each chart's gear icon opens its own scoped dialog (see
/// `widgets/max_demand_chart_config_dialog.dart`) rather than one combined
/// dialog, so picking a device to exclude from one chart never shows the
/// other chart's unrelated list.
enum MaxDemandChartTarget { correlation, mdRanking }

/// Per-tenant selection for the Max Demand Monitoring page's two
/// equipment-level charts — which Master-Facilities-eligible devices each
/// chart should skip. A device excluded here is still eligible by every
/// other rule (TNB meter scope, Influx tags, `includeMdRanking`); this is a
/// manual narrowing on top of that, not a replacement for it.
///
/// A device with no entry in either set (the default, unconfigured state)
/// is included — same "excluded" semantics as
/// `MdInsightReportImageConfig.excludedEquipmentByPlant`.
class MaxDemandChartConfig {
  final Set<String> excludedCorrelationDeviceIds;
  final Set<String> excludedMdRankingDeviceIds;

  const MaxDemandChartConfig({
    this.excludedCorrelationDeviceIds = const {},
    this.excludedMdRankingDeviceIds = const {},
  });

  factory MaxDemandChartConfig.empty() => const MaxDemandChartConfig();

  MaxDemandChartConfig copyWith({
    Set<String>? excludedCorrelationDeviceIds,
    Set<String>? excludedMdRankingDeviceIds,
  }) {
    return MaxDemandChartConfig(
      excludedCorrelationDeviceIds: excludedCorrelationDeviceIds ?? this.excludedCorrelationDeviceIds,
      excludedMdRankingDeviceIds: excludedMdRankingDeviceIds ?? this.excludedMdRankingDeviceIds,
    );
  }

  factory MaxDemandChartConfig.fromJson(Map<String, dynamic> json) {
    Set<String> asSet(dynamic v) => ((v as List?)?.cast<String>() ?? const []).toSet();
    return MaxDemandChartConfig(
      excludedCorrelationDeviceIds: asSet(json['excludedCorrelationDeviceIds']),
      excludedMdRankingDeviceIds: asSet(json['excludedMdRankingDeviceIds']),
    );
  }

  Map<String, dynamic> toJson() => {
        'excludedCorrelationDeviceIds': excludedCorrelationDeviceIds.toList(),
        'excludedMdRankingDeviceIds': excludedMdRankingDeviceIds.toList(),
      };
}

/// Backend persistence for [MaxDemandChartConfig] — `GET/POST
/// /max-demand-chart-config/:uid` (see
/// `functions/api/maxDemandChartConfigFunction.js`), scoped per tenant via
/// the `x-client-id` header, same multi-tenant Firestore resolution as
/// `MdInsightReportImageConfigService`. Callers pass
/// [AppConfig.sharedConfigOwnerId] — this is shared across every user of a
/// client, not saved per login.
class MaxDemandChartConfigService {
  const MaxDemandChartConfigService._();

  static String get _base => AppConfig.dataApiBaseSafe;
  static Map<String, String> get _headers => AppConfig.headers;

  static Future<MaxDemandChartConfig> getConfig(String uid) async {
    if (uid.isEmpty) return const MaxDemandChartConfig();
    try {
      final res = await http.get(
        Uri.parse('$_base/max-demand-chart-config/$uid'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return MaxDemandChartConfig.fromJson(json.decode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching Max Demand chart config: $e');
    }
    return const MaxDemandChartConfig();
  }

  static Future<bool> saveConfig(String uid, MaxDemandChartConfig config) async {
    if (uid.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$_base/max-demand-chart-config/$uid'),
        headers: _headers,
        body: json.encode(config.toJson()),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving Max Demand chart config: $e');
      return false;
    }
  }
}
