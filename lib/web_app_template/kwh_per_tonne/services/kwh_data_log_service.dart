import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

class KwhDataLogService {
  static String get _base => '${AppConfig.apiBase}/kwhPerTonneDataLog';

  /// Fetch all data-log entries. Returns normalized entries whose field names
  /// match what KwhDataLogTab and the parent widget expect.
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final res = await http.get(Uri.parse(_base), headers: AppConfig.headers).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => _normalize(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Create a new entry. [body] must use MySQL column names:
  ///   date, machine_id, product_type, factory_id, plant_id, zone_id,
  ///   kWh_consumed, tonnes_produced, variance, cost, status
  static Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: AppConfig.headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _normalize(Map<String, dynamic>.from(jsonDecode(res.body)));
    }
    throw Exception('Failed to create entry (${res.statusCode}): ${_errorBody(res.body)}');
  }

  static Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) async {
    final res = await http
        .put(
          Uri.parse('$_base/$id'),
          headers: AppConfig.headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _normalize(Map<String, dynamic>.from(jsonDecode(res.body)));
    }
    throw Exception('Failed to update entry (${res.statusCode}): ${_errorBody(res.body)}');
  }

  static Future<void> delete(String id) async {
    final res = await http.delete(Uri.parse('$_base/$id'), headers: AppConfig.headers).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete entry (${res.statusCode}): ${_errorBody(res.body)}');
    }
  }

  // Pulls the backend's { "error": "..." } message out of the response body
  // so callers surface the real reason instead of just a bare status code.
  // Falls back to the raw body if it isn't JSON.
  static String _errorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) return decoded['error'].toString();
    } catch (_) {}
    return body;
  }

  static Future<List<String>> getMachineNames() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.apiBase}/equipment'), headers: AppConfig.headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final names = data
            .map((e) => e['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        if (names.isNotEmpty) return names;
      }
    } catch (_) {}
    return ['CNC-01', 'CNC-02', 'Mixer-1', 'Press-A', 'Press-B'];
  }

  /// Map MySQL column names → field names used by KwhDataLogTab and
  /// the enrichment logic in KwhPerTonneWidget.
  static Map<String, dynamic> _normalize(Map<String, dynamic> e) {
    return {
      'id': e['id']?.toString() ?? '',
      'date': e['date']?.toString() ?? '',
      'machine': e['machine_id']?.toString() ?? '',
      'product': e['product_type']?.toString() ?? '',
      'processDepartment': e['zone_id']?.toString() ?? '',
      'factory_id': e['factory_id']?.toString() ?? '',
      'plant_id': e['plant_id']?.toString() ?? '',
      'kwh':    double.tryParse(e['kWh_consumed']?.toString()    ?? '') ?? 0.0,
      'tonnes': double.tryParse(e['tonnes_produced']?.toString() ?? '') ?? 0.0,
    };
  }
}
