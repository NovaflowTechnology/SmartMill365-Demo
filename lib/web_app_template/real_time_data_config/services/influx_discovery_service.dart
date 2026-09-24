import 'package:smartmachine365/services/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discovery_models.dart';

/// Discovery service — proxies InfluxDB via discoverydevice.js API.
/// Bucket: ENERGY_DEMO | Measurement: power_meter
/// Tags:   device_id, device_name, site_id
class InfluxDiscoveryService {
  static String get _apiBase => '${AppConfig.dataApiBase}/discoveryDevice';
  static const _measurement = 'power_meter';

  // Confirmed 17 fields from power_meter measurement
  static const _knownFields = [
    'P_kW', 'Q_VAR', 'S_VA',
    'UAB', 'UBC', 'UCA', 'Uavg',
    'IA', 'IB', 'IC', 'Iavg',
    'PF', 'PeakDemand', 'Freq',
    'Edel', 'Erec', 'status',
  ];

  // ── Discovery ──────────────────────────────────────────────────────────────

  Future<List<DiscoveredDevice>> discoverAllDevices({String start = '-24h'}) async {
    // Fetch enriched device list (InfluxDB + MySQL if configured) and fields in parallel.
    // Fallback: if enriched endpoint fails, fall back to InfluxDB-only meta — data is never lost.
    List<Map<String, dynamic>> enrichedList = [];
    try {
      enrichedList = await _getEnriched(start: start);
    } catch (_) {
      // Enriched failed — fall back to plain meta
      enrichedList = [];
    }

    // If enriched returned nothing, fall back to InfluxDB meta
    if (enrichedList.isEmpty) {
      final results = await Future.wait([
        _getDevices(start: start),
        _getMeta(start: start),
      ]);
      final deviceIds = results[0] as List<String>;
      final metaMap   = results[1] as Map<String, Map<String, dynamic>>;
      if (deviceIds.isEmpty) return [];
      final fieldResults = await Future.wait(
        deviceIds.map((id) => _getFields(id, start: start)),
      );
      final seen = <String, DiscoveredDevice>{};
      for (int i = 0; i < deviceIds.length; i++) {
        final id   = deviceIds[i];
        final meta = metaMap[id] ?? {};
        seen[id] = DiscoveredDevice(
          deviceId:    id,
          deviceName:  meta['device_name'] as String? ?? id,
          displayName: meta['device_name'] as String? ?? id,
          deviceType:  null,
          plantId:     meta['site_id'] as String? ?? '',
          zoneId:      '',
          plantName:   meta['site_id'] as String? ?? '',
          zoneName:    '',
          tags:        fieldResults[i],
        );
      }
      return seen.values.toList();
    }

    // Enriched succeeded — fetch fields for all devices in parallel
    final deviceIds = enrichedList.map((e) => e['device_id'] as String).toList();
    final fieldResults = await Future.wait(
      deviceIds.map((id) => _getFields(id, start: start)),
    );

    final seen = <String, DiscoveredDevice>{};
    for (int i = 0; i < enrichedList.length; i++) {
      final e  = enrichedList[i];
      final id = e['device_id'] as String? ?? '';
      if (id.isEmpty) continue;
      seen[id] = DiscoveredDevice(
        deviceId:    id,
        deviceName:  e['device_name'] as String? ?? id,
        displayName: e['device_name'] as String? ?? id,
        deviceType:  null,
        plantId:     e['site_id']   as String? ?? '',
        zoneId:      e['zone_id']   as String? ?? '',
        plantName:   e['site_name'] as String? ?? e['site_id'] as String? ?? '',
        zoneName:    e['zone_name'] as String? ?? '',
        tags:        fieldResults[i],
        siteId:      e['site_id']    as String? ?? '',
        machineId:   e['machine_id'] as String? ?? '',
        machineName: e['machine_name'] as String? ?? '',
        lineId:      e['line_id']    as String? ?? '',
        lineName:    e['line_name']  as String? ?? '',
        parentId:    e['parent_id']  as String? ?? '',
        parentName:  e['parent_name'] as String? ?? '',
      );
    }
    return seen.values.toList();
  }

  Future<DiscoveredDevice?> refreshSingleDevice(String deviceId) async {
    try {
      final results = await Future.wait([
        _getMeta(start: '-7d'),
        _getFields(deviceId, start: '-7d'),
      ]);
      final metaMap = results[0] as Map<String, Map<String, dynamic>>;
      final tags    = results[1] as List<InfluxTag>;
      final meta    = metaMap[deviceId] ?? {};
      return DiscoveredDevice(
        deviceId:    deviceId,
        deviceName:  meta['device_name'] as String? ?? deviceId,
        displayName: meta['device_name'] as String? ?? deviceId,
        deviceType:  null,
        plantId:     meta['site_id'] as String? ?? '',
        zoneId:      '',
        plantName:   meta['site_id'] as String? ?? '',
        zoneName:    '',
        tags:        tags,
        isApproved:  true,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Realtime values ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBatchRealtimeValues(List<InfluxTag> tags) async {
    if (tags.isEmpty) return {};

    final grouped = <String, List<InfluxTag>>{};
    for (final t in tags) {
      grouped.putIfAbsent(t.measurement, () => []).add(t);
    }

    final result = <String, dynamic>{};
    await Future.wait(grouped.entries.map((entry) async {
      final deviceId   = entry.key;
      final fieldNames = entry.value.map((t) => t.fieldName).join(',');
      final values     = await _getRealtime(deviceId, fields: fieldNames);
      result.addAll(values);
    }));
    return result;
  }

  // ── Field history ──────────────────────────────────────────────────────────

  Future<List<HistoryPoint>> fetchFieldHistory(
      String deviceId, String fieldName,
      {String range = '-1h'}) async {
    try {
      final uri = Uri.parse('$_apiBase/history/$deviceId').replace(
        queryParameters: {
          'field':  fieldName,
          'start':  range,
          'window': '1m',
        },
      );
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return [];
      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data.map((item) {
        final t = DateTime.tryParse(item['time'] as String? ?? '');
        final v = (item['value'] as num?)?.toDouble();
        if (t == null || v == null) return null;
        return HistoryPoint(t, v);
      }).whereType<HistoryPoint>().toList();
    } catch (_) {
      return [];
    }
  }

  // ── Private API calls ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getEnriched({required String start}) async {
    try {
      final uri = Uri.parse('$_apiBase/enriched')
          .replace(queryParameters: {'start': start});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _getDevices({required String start}) async {
    try {
      final uri = Uri.parse('$_apiBase/devices')
          .replace(queryParameters: {'start': start});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as List<dynamic>;
      return data
          .map((e) => (e as Map<String, dynamic>)['device_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getMeta({required String start}) async {
    try {
      final uri = Uri.parse('$_apiBase/meta')
          .replace(queryParameters: {'start': start});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return {};
      final data = json.decode(res.body) as List<dynamic>;
      return {
        for (final item in data)
          if ((item as Map<String, dynamic>)['device_id'] is String &&
              (item['device_id'] as String).isNotEmpty)
            item['device_id'] as String: item,
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<InfluxTag>> _getFields(String deviceId, {required String start}) async {
    try {
      final uri = Uri.parse('$_apiBase/fields/$deviceId')
          .replace(queryParameters: {'start': start});
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return _fallbackTags(deviceId);
      final body   = json.decode(res.body) as Map<String, dynamic>;
      final fields = body['fields'] as List<dynamic>? ?? [];
      if (fields.isEmpty) return _fallbackTags(deviceId);
      return fields.map((f) {
        final field = f['field'] as String? ?? '';
        return field.isNotEmpty
            ? InfluxTag(
                measurement: deviceId, // used as group key in getBatchRealtimeValues
                fieldName:   field,
                tagName:     field,
                unit:        _inferUnit(field))
            : null;
      }).whereType<InfluxTag>().toList();
    } catch (_) {
      return _fallbackTags(deviceId);
    }
  }

  Future<Map<String, dynamic>> _getRealtime(String deviceId, {String? fields}) async {
    try {
      final params = <String, String>{};
      if (fields != null && fields.isNotEmpty) params['fields'] = fields;
      final uri = Uri.parse('$_apiBase/realtime/$deviceId')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data   = json.decode(res.body) as List<dynamic>;
        final result = <String, dynamic>{};
        for (final item in data) {
          final field = item['field'] as String?;
          final value = item['value'];
          if (field != null && field.isNotEmpty) {
            result['$deviceId.$field'] = value?.toString() ?? '';
          }
        }
        // If realtime returned data, use it
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}

    // Fallback: /realtime is hardcoded to -5m on the deployed API.
    // Use /history with a wider window to get the most recent values.
    return _getRealtimeViaHistory(deviceId, fields: fields);
  }

  Future<Map<String, dynamic>> _getRealtimeViaHistory(String deviceId,
      {String? fields}) async {
    final fieldList = fields != null && fields.isNotEmpty
        ? fields.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList()
        : _knownFields;

    // Fetch in batches of 5 to avoid hammering the API.
    final result = <String, dynamic>{};
    for (int i = 0; i < fieldList.length; i += 5) {
      final batch = fieldList.skip(i).take(5).toList();
      final values = await Future.wait(
        batch.map((f) => _getLatestViaHistory(deviceId, f)),
      );
      for (int j = 0; j < batch.length; j++) {
        if (values[j] != null) {
          result['$deviceId.${batch[j]}'] = values[j];
        }
      }
    }
    return result;
  }

  Future<dynamic> _getLatestViaHistory(String deviceId, String field) async {
    try {
      final uri = Uri.parse('$_apiBase/history/$deviceId').replace(
        queryParameters: {
          'field':  field,
          'start':  '-30m',
          'window': '1m',
        },
      );
      final res = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      if (data.isEmpty) return null;
      return data.last['value'];
    } catch (_) {
      return null;
    }
  }

  List<InfluxTag> _fallbackTags(String deviceId) => _knownFields
      .map((f) => InfluxTag(
            measurement: deviceId,
            fieldName:   f,
            tagName:     f,
            unit:        _inferUnit(f)))
      .toList();

  String _inferUnit(String field) {
    final f = field.toLowerCase();
    if (f == 'pf')          return 'PF';
    if (f == 'freq')        return 'Hz';
    if (f == 'peakdemand')  return 'kW';
    if (f == 'p_kw')        return 'kW';
    if (f == 'q_var')       return 'kVAR';
    if (f == 's_va')        return 'kVA';
    if (f == 'status')      return '';
    if (f.startsWith('edel') || f.startsWith('erec')) return 'kWh';
    if (f == 'ia' || f == 'ib' || f == 'ic' || f == 'iavg') return 'A';
    if (f.startsWith('u') || f.startsWith('v'))              return 'V';
    return '';
  }
}

class HistoryPoint {
  final DateTime time;
  final double value;
  const HistoryPoint(this.time, this.value);
}
