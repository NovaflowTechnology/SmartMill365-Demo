import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

import 'md_insight_report_models.dart';

class MdInsightReportService {
  static String get _base => AppConfig.dataApiBaseSafe;
  static Map<String, String> get _headers => AppConfig.headers;

  /// Fetches the computed MD001-404 rule lines + chart/table data for
  /// [deviceId] over [period] ('YYYY-MM', defaults to the current month on
  /// the backend). [cc] and [mdRate] are resolved by the caller (same
  /// sources as the summary cards: energy-settings contractCapacity and
  /// masterBillingConfig mdCapacityCharge+mdNetworkCharge) since the backend
  /// doesn't re-resolve tariff config itself.
  static Future<MdInsightReport?> fetchReport({
    required String deviceId,
    required double cc,
    required double mdRate,
    String? period,
    List<String>? equipmentDeviceIds,
    String? peakStart,
    String? peakEnd,
    List<int>? peakDays,
  }) async {
    if (deviceId.trim().isEmpty) return null;
    try {
      final uri = Uri.parse('$_base/md-insight-rules').replace(queryParameters: {
        'device_id': deviceId,
        'cc': cc.toString(),
        'md_rate': mdRate.toString(),
        if (period != null) 'period': period,
        if (equipmentDeviceIds != null && equipmentDeviceIds.isNotEmpty)
          'equipment_device_ids': equipmentDeviceIds.join(','),
        if (peakStart != null && peakEnd != null) 'peak_start': peakStart,
        if (peakStart != null && peakEnd != null) 'peak_end': peakEnd,
        if (peakDays != null && peakDays.isNotEmpty) 'peak_days': peakDays.join(','),
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        return MdInsightReport.fromJson(json.decode(res.body) as Map<String, dynamic>);
      }
      debugPrint('MdInsightReportService: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('MdInsightReportService: error fetching report: $e');
    }
    return null;
  }

  /// Logs a completed report generation to `md_insight_report_log` (MySQL),
  /// via POST /md-insight-report-log. Called right after a report download
  /// succeeds, so the log only records reports that were actually produced.
  /// Returns the generated `report_id` on success, or null if logging failed
  /// — a logging failure shouldn't block the user from getting their PDF.
  static Future<String?> logReportGeneration({
    required String plantCode,
    required String period,
    required String generatedBy,
    required String reportState,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final uri = Uri.parse('$_base/md-insight-report-log');
      final res = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'plant_code': plantCode,
          'period': period,
          'generated_by': generatedBy,
          'report_state': reportState,
          if (payload != null) 'payload_json': payload,
        }),
      );
      if (res.statusCode == 201) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return data['report_id']?.toString();
      }
      debugPrint('MdInsightReportService: log ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('MdInsightReportService: error logging report generation: $e');
    }
    return null;
  }

  /// Fetches past report generations from `md_insight_report_log` via
  /// GET /md-insight-report-log, most recent first. [plantCode] narrows the
  /// list to one plant (omit for all plants this tenant has generated).
  static Future<List<MdInsightReportLogEntry>> fetchReportLogs({
    String? plantCode,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$_base/md-insight-report-log').replace(
        queryParameters: {
          if (plantCode != null && plantCode.isNotEmpty) 'plant_code': plantCode,
          'limit': limit.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final logs = (data['logs'] as List?) ?? [];
        return logs
            .map((e) => MdInsightReportLogEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
      debugPrint('MdInsightReportService: fetchReportLogs ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('MdInsightReportService: error fetching report logs: $e');
    }
    return const [];
  }

  /// Looks up the canonical, locked snapshot for [plantCode]/[period] — the
  /// single `source='auto'` row the monthly rollup (or its backfill route)
  /// wrote once that month closed. Returns null if that month hasn't been
  /// locked yet (e.g. the current, still-in-progress month, or a plant/
  /// period the rollup hasn't reached), in which case the caller should
  /// fall back to the live `/md-insight-rules` recompute.
  static Future<MdInsightReportLogEntry?> fetchLockedSnapshot({
    required String plantCode,
    required String period,
  }) async {
    if (plantCode.trim().isEmpty || period.trim().isEmpty) return null;
    try {
      final uri = Uri.parse('$_base/md-insight-report-log').replace(
        queryParameters: {
          'plant_code': plantCode,
          'period': period,
          'source': 'auto',
          'limit': '1',
        },
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final logs = (data['logs'] as List?) ?? [];
        if (logs.isEmpty) return null;
        return MdInsightReportLogEntry.fromJson((logs.first as Map).cast<String, dynamic>());
      }
      debugPrint('MdInsightReportService: fetchLockedSnapshot ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('MdInsightReportService: error fetching locked snapshot: $e');
    }
    return null;
  }
}
