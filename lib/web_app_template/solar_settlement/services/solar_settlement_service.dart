import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/utils/tou_window.dart';
import 'package:smartmachine365/web_app_template/energy_system_settings/energy_system_setting_service.dart';

/// Fetches the energy Solar Settlement is built from, and nothing else.
///
/// No widgets and no arithmetic beyond assembling what the endpoints return —
/// the sums live in [SettlementCalculator] so the same figures cannot be
/// worked out two ways. Anything this cannot obtain comes back as zero or an
/// empty list, never as a plausible-looking guess: a settlement is money, and
/// a number nobody can trace is worse than a blank.
class SolarSettlementService {
  const SolarSettlementService._();

  static String get _base => AppConfig.dataApiBaseSafe;

  /// The month's per-day energy for one meter, keyed by day of month.
  ///
  /// One request per meter — `daily?month=YYYY-MM` returns the whole month, so
  /// a thirty-day ledger does not cost thirty round trips.
  static Future<Map<int, double>> monthlyDaily(
      String deviceId, DateTime month) async {
    if (deviceId.isEmpty) return const {};
    final ym = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    try {
      final res = await http
          .get(
            Uri.parse('$_base/energyDetails/data/$deviceId/daily?month=$ym'),
            headers: AppConfig.headers,
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return const {};
      final body = jsonDecode(res.body);
      final rows = body is List ? body : (body['data'] as List? ?? const []);
      final out = <int, double>{};
      for (final r in rows) {
        if (r is! Map) continue;
        final day = _dayOf(r['label']?.toString() ?? r['date']?.toString() ?? '');
        if (day == null) continue;
        out[day] = _toDouble(r['value'] ?? r['total_energy']);
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// One day's 0..23 breakdown for a meter, used to split a day into ToU
  /// windows. Empty when the day has no hourly record — the ledger then shows
  /// that day's split as unavailable rather than apportioning it by assumption.
  static Future<List<double>> hourlyForDay(
      String deviceId, DateTime day) async {
    if (deviceId.isEmpty) return const [];
    final d = '${day.year}-${day.month.toString().padLeft(2, '0')}'
        '-${day.day.toString().padLeft(2, '0')}';
    try {
      final res = await http
          .get(
            Uri.parse('$_base/energyDetails/data/$deviceId/hourly?date=$d'),
            headers: AppConfig.headers,
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      final rows = body is List ? body : (body['data'] as List? ?? const []);
      final out = List<double>.filled(24, 0);
      for (final r in rows) {
        if (r is! Map) continue;
        final h = _hourOf(r['label']?.toString() ?? r['hour']?.toString() ?? '');
        if (h == null || h < 0 || h > 23) continue;
        out[h] = _toDouble(r['value'] ?? r['total_energy']);
      }
      return out.any((v) => v > 0) ? out : const [];
    } catch (_) {
      return const [];
    }
  }

  /// The Peak Hour ToU window, as configured in Energy System Settings.
  ///
  /// Null when it has not been set. The endpoint answers an unsaved user with a
  /// placeholder window and `exists: false`; that placeholder is nobody's
  /// choice, so it is refused here rather than used to price a settlement.
  static Future<TouWindow?> touWindow(String uid) async {
    if (uid.trim().isEmpty) return null;
    try {
      final res = await EnergySystemSettingsService.getSettings(uid);
      if (res['exists'] != true) return null;
      final settings = res['settings'];
      if (settings is! Map) return null;
      final cc = settings['contractCapacity'];
      if (cc is! Map) return null;
      final tou = cc['peakHourToU'];
      if (tou is! Map) return null;
      final days = (tou['days'] as List?)
              ?.map((e) => e is num ? e.toInt() : int.tryParse('$e'))
              .whereType<int>()
              .toList() ??
          const <int>[];
      return TouWindow.parse(
        tou['startTime']?.toString(),
        tou['endTime']?.toString(),
        days: days,
      );
    } catch (_) {
      return null;
    }
  }

  static int? _dayOf(String label) {
    // Labels arrive as "1/9" (day/month) or "2026-09-01" depending on the
    // endpoint; both are read rather than one being assumed.
    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})$').firstMatch(label.trim());
    if (slash != null) return int.tryParse(slash.group(1)!);
    final iso = RegExp(r'^\d{4}-\d{2}-(\d{2})').firstMatch(label.trim());
    if (iso != null) return int.tryParse(iso.group(1)!);
    return null;
  }

  static int? _hourOf(String label) {
    final m = RegExp(r'^(\d{1,2})').firstMatch(label.trim());
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
