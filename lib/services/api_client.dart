import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

/// Thin HTTP wrapper around package:http that automatically:
///   1. Prepends AppConfig.apiBase to relative paths
///   2. Injects x-client-id header on every request
///   3. Sets Content-Type: application/json on POST/PUT/PATCH
///
/// Usage:
///   final res = await ApiClient.get('/facilities');
///   final res = await ApiClient.post('/equipment', body: {...});
class ApiClient {
  ApiClient._();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-client-id': AppConfig.clientId,
      };

  static Uri _uri(String path) =>
      Uri.parse('${AppConfig.apiBase}$path');

  static Future<http.Response> get(String path,
      {Map<String, String>? extraHeaders}) async {
    return http.get(
      _uri(path),
      headers: {..._headers, ...?extraHeaders},
    );
  }

  static Future<http.Response> post(String path,
      {Object? body, Map<String, String>? extraHeaders}) async {
    return http.post(
      _uri(path),
      headers: {..._headers, ...?extraHeaders},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String path,
      {Object? body, Map<String, String>? extraHeaders}) async {
    return http.put(
      _uri(path),
      headers: {..._headers, ...?extraHeaders},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(String path,
      {Object? body, Map<String, String>? extraHeaders}) async {
    return http.patch(
      _uri(path),
      headers: {..._headers, ...?extraHeaders},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String path,
      {Map<String, String>? extraHeaders}) async {
    return http.delete(
      _uri(path),
      headers: {..._headers, ...?extraHeaders},
    );
  }
}
