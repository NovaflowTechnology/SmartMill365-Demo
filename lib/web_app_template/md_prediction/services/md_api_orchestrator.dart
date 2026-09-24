import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

// ---------------------------------------------------------------------------
// MD API Orchestrator — throttled queue with exponential backoff
// ---------------------------------------------------------------------------
// Prevents 500 errors caused by firing 12+ parallel requests to the Cloud
// Function. All device fetches go through a shared semaphore that limits
// concurrency to [maxConcurrent] slots. Failed requests are retried up to
// [maxRetries] times with exponential backoff before returning null.

class MdApiOrchestrator {
  MdApiOrchestrator._();

  // Max parallel in-flight HTTP requests at any time.
  static const int _maxConcurrent = 2;
  // Retry attempts per URL (1s → 2s → 4s).
  static const int _maxRetries = 3;
  // Base backoff duration — doubles on each retry.
  static const Duration _backoffBase = Duration(seconds: 1);
  // Minimum gap between dispatching consecutive requests — avoids burst spikes.
  static const Duration _interRequestDelay = Duration(milliseconds: 100);

  // ── Semaphore state ────────────────────────────────────────────────────────
  static int _active = 0;
  static final Queue<_QueuedRequest> _queue = Queue();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetches [url] through the throttled queue.
  /// Returns the decoded JSON body (Map or List) on success, or null on failure.
  static Future<dynamic> fetch(String url, {Duration? timeout}) {
    final completer = Completer<dynamic>();
    _queue.add(_QueuedRequest(
      url: url,
      timeout: timeout ?? const Duration(seconds: 10),
      completer: completer,
    ));
    _drain();
    return completer.future;
  }

  /// Fetches multiple [urls] through the same throttled queue and returns
  /// results in the same order. Failed requests yield null entries.
  static Future<List<dynamic>> fetchAll(
    List<String> urls, {
    Duration? timeout,
  }) {
    return Future.wait(
      urls.map((u) => fetch(u, timeout: timeout)),
    );
  }

  /// Fetches the InfluxDB realtime endpoint for a single [deviceId] and a
  /// single [field] (e.g. `'P(kW)'`).
  ///
  /// Requesting one field at a time avoids the InfluxDB **schema collision**
  /// error that occurs when a multi-field query mixes integer and float
  /// measurements in the same result set.
  ///
  /// Returns the numeric value on success, or `null` on failure / no data.
  static Future<double?> fetchInfluxField(
    String baseUrl,
    String deviceId,
    String field, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final url = '$baseUrl/energyDetailsInfluxDb/realtime'
        '/$deviceId?fields=${Uri.encodeComponent(field)}';
    final body = await fetch(url, timeout: timeout);
    if (body == null) return null;

    // Normalise to a flat list regardless of wrapper format or double-encoding.
    dynamic decoded = body;
    if (decoded is String) {
      try { decoded = json.decode(decoded); } catch (_) { return null; }
    }
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      final inner = decoded['value'] ?? decoded['data'] ?? decoded['items'];
      list = inner is List ? inner : [];
    } else {
      return null;
    }

    for (final item in list) {
      if (item is! Map) continue;
      final f = (item['field'] ?? item['Field'] ?? '').toString();
      if (f == field) {
        final v = item['value'] ?? item['Value'];
        if (v == null) continue;
        final d = v is num ? v.toDouble() : double.tryParse(v.toString());
        if (d != null && d > 0) return d;
      }
    }
    return null;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static void _drain() {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      final req = _queue.removeFirst();
      _active++;
      _execute(req).then((_) {
        _active--;
        _drain(); // pick up the next queued request
      });
    }
  }

  static Future<void> _execute(_QueuedRequest req) async {
    dynamic result;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final res = await http
            .get(Uri.parse(req.url), headers: AppConfig.headers)
            .timeout(req.timeout);

        if (res.statusCode == 200) {
          result = json.decode(res.body);
          break;
        }

        // 5xx server errors: retry with backoff
        if (res.statusCode >= 500 && attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }

        // 4xx or other non-retryable: give up immediately
        break;
      } on TimeoutException {
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
        }
      } catch (_) {
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
        }
      }
    }
    req.completer.complete(result); // null on all failures
  }

  static Future<void> _backoff(int attempt) =>
      Future.delayed(_backoffBase * (1 << attempt)); // 1s, 2s, 4s
}

// ---------------------------------------------------------------------------
// Simple queue and request model
// ---------------------------------------------------------------------------

class Queue<T> {
  final _items = <T>[];
  void add(T item) => _items.add(item);
  T removeFirst() => _items.removeAt(0);
  bool get isNotEmpty => _items.isNotEmpty;
}

class _QueuedRequest {
  final String url;
  final Duration timeout;
  final Completer<dynamic> completer;
  const _QueuedRequest({
    required this.url,
    required this.timeout,
    required this.completer,
  });
}
