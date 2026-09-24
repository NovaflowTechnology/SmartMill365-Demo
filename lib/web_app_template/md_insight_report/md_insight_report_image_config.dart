import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

/// Per-tenant MD Insight Report settings: the report's dynamic images (the
/// plant-status background photo in the Executive Summary section and the
/// footer brand logo — both optional URL overrides, falling back to the
/// report's bundled asset images when unset) plus, per plant, which
/// equipment its Equipment Analysis ranking should skip.
class MdInsightReportImageConfig {
  final String? plantBackgroundImageUrl;
  final String? footerLogoImageUrl;

  /// `{ meterCode: [excluded device tag, ...] }` — a plant with no entry
  /// here has nothing excluded (every candidate equipment counts).
  final Map<String, List<String>> excludedEquipmentByPlant;

  const MdInsightReportImageConfig({
    this.plantBackgroundImageUrl,
    this.footerLogoImageUrl,
    this.excludedEquipmentByPlant = const {},
  });

  factory MdInsightReportImageConfig.fromJson(Map<String, dynamic> json) {
    String? asUrl(dynamic v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final rawMap =
        (json['excludedEquipmentByPlant'] as Map?)?.cast<String, dynamic>() ??
            const {};
    final excluded = <String, List<String>>{
      for (final entry in rawMap.entries)
        entry.key: List<String>.from((entry.value as List?) ?? const []),
    };
    return MdInsightReportImageConfig(
      plantBackgroundImageUrl: asUrl(json['plantBackgroundImageUrl']),
      footerLogoImageUrl: asUrl(json['footerLogoImageUrl']),
      excludedEquipmentByPlant: excluded,
    );
  }

  Map<String, dynamic> toJson() => {
        'plantBackgroundImageUrl': plantBackgroundImageUrl,
        'footerLogoImageUrl': footerLogoImageUrl,
        'excludedEquipmentByPlant': excludedEquipmentByPlant,
      };
}

/// Backend-persisted (per-tenant) store for [MdInsightReportImageConfig] —
/// same multi-tenant Firestore-per-client resolution as
/// CarbonDashboardConfigService, via
/// functions/api/mdInsightReportConfigFunction.js.
class MdInsightReportImageConfigService {
  const MdInsightReportImageConfigService._();

  static String get _base => AppConfig.dataApiBaseSafe;
  static Map<String, String> get _headers => AppConfig.headers;

  static Future<MdInsightReportImageConfig> getConfig(String uid) async {
    if (uid.isEmpty) return const MdInsightReportImageConfig();
    try {
      final res = await http.get(
        Uri.parse('$_base/md-insight-report-config/$uid'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return MdInsightReportImageConfig.fromJson(
            json.decode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching MD Insight Report image config: $e');
    }
    return const MdInsightReportImageConfig();
  }

  static Future<bool> saveConfig(
    String uid,
    MdInsightReportImageConfig config,
  ) async {
    if (uid.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$_base/md-insight-report-config/$uid'),
        headers: _headers,
        body: json.encode(config.toJson()),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving MD Insight Report image config: $e');
      return false;
    }
  }
}
