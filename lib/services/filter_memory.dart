import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';

/// Remembers the filter a screen was left on, so a reload does not drop the
/// user back to the defaults.
///
/// A dashboard is usually opened on the same plant, line or meter every day,
/// and re-picking four dropdowns after every refresh is work the app should be
/// doing. Selections are kept per screen and per signed-in user, so two people
/// sharing a browser do not inherit each other's view.
///
/// Deliberately local to the browser: this is a convenience, not configuration,
/// and it must never become another thing that has to be saved to the server
/// and kept in step.
class FilterMemory {
  FilterMemory._();

  static String _key(String screen) {
    final uid = AppStateNotifier.instance.uid ?? 'anon';
    return 'filters.$uid.$screen';
  }

  /// Stores the given selections. Null and empty values are dropped rather
  /// than written, so "nothing selected" restores as nothing selected.
  static Future<void> save(String screen, Map<String, String?> values) async {
    try {
      final keep = <String, String>{
        for (final e in values.entries)
          if ((e.value ?? '').isNotEmpty) e.key: e.value!,
      };
      final prefs = await SharedPreferences.getInstance();
      if (keep.isEmpty) {
        await prefs.remove(_key(screen));
      } else {
        await prefs.setString(_key(screen), json.encode(keep));
      }
    } catch (_) {
      // Storage can be unavailable (private windows, blocked site data). The
      // screen simply opens on its defaults, which is what it did before.
    }
  }

  static Future<Map<String, String>> load(String screen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(screen));
      if (raw == null || raw.isEmpty) return const {};
      final decoded = json.decode(raw);
      if (decoded is! Map) return const {};
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return const {};
    }
  }

  static Future<void> clear(String screen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(screen));
    } catch (_) {}
  }
}
