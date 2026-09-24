import 'dart:convert';
import 'session_storage_backend_stub.dart'
    if (dart.library.html) 'session_storage_backend_web.dart' as storage;

/// Per-user session & settings persistence via browser localStorage.
///
/// Uses `window.localStorage` so the session is shared across tabs in the
/// same browser — copy-pasting a deep link into a new tab keeps the user
/// signed in. Cross-tab "phantom logout" is prevented separately, in
/// `AppStateNotifier.update()`, which refuses to wipe localStorage when a
/// Firebase auth event arrives with a null user but a valid session is
/// still present (e.g. another tab calling `signOut` mid-login).
///
/// Keys in localStorage:
///   sf365_active_uid          → UID of the currently active user
///   sf365_session_{uid}       → session data (role, modules, token, …)
///   sf365_settings_{uid}      → user-specific settings (theme, sidebar, …)
class SessionStorage {
  static storage.KeyValueStore get _store => storage.store;
  // ── Key helpers ───────────────────────────────────────────────────────────
  static const String _activeUidKey = 'sf365_active_uid';
  static String _sessionKey(String uid) => 'sf365_session_$uid';
  static String _settingsKey(String uid) => 'sf365_settings_$uid';

  // ── Active UID ────────────────────────────────────────────────────────────

  /// Returns the UID of the last logged-in user (or null).
  static String? getActiveUid() => _store[_activeUidKey];

  // ── Session (auth + profile data) ─────────────────────────────────────────

  /// Save user session data keyed by their UID.
  ///
  /// [sessionId] is optional — if omitted, the existing stored session_id is
  /// preserved so heartbeat/role-refresh writes don't wipe the login session_id.
  static void saveSession({
    required String? uid,
    required String? email,
    required String? userName,
    required String? userRole,
    required String? accessToken,
    required String? userCompany,
    required List<String> accessibleModules,
    required List<String> accessibleSubModules,
    String? sessionId,
  }) {
    if (uid == null || uid.isEmpty) return;

    // Mark this user as the active one
    _store[_activeUidKey] = uid;

    // Preserve the existing session_id if a new one wasn't provided
    final resolvedSessionId =
        sessionId ?? (getSessionForUid(uid)?['session_id'] as String?);

    final sessionData = <String, dynamic>{
      'uid': uid,
      'email': email,
      'userName': userName,
      'userRole': userRole,
      'accessToken': accessToken,
      'userCompany': userCompany,
      'accessibleModules': accessibleModules,
      'accessibleSubModules': accessibleSubModules,
      'loggedIn': true,
      'loginTimestamp': DateTime.now().toIso8601String(),
      if (resolvedSessionId != null) 'session_id': resolvedSessionId,
    };

    _store[_sessionKey(uid)] = json.encode(sessionData);
  }

  /// Get the session_id for the currently active user, if one is stored.
  static String? getSessionId() {
    return getSession()?['session_id'] as String?;
  }

  /// Update only the session_id for the currently active user.
  /// Used when the sessionIdStream learns the Firestore session_id for the
  /// first time (e.g. on a new tab opening with an existing Firebase session).
  static void updateSessionId(String sessionId) {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return;
    final existing = getSessionForUid(uid);
    if (existing == null) return;
    existing['session_id'] = sessionId;
    _store[_sessionKey(uid)] = json.encode(existing);
  }

  /// Retrieve session for the currently active user.
  static Map<String, dynamic>? getSession() {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return null;
    return getSessionForUid(uid);
  }

  /// Retrieve session for a specific user.
  static Map<String, dynamic>? getSessionForUid(String uid) {
    final raw = _store[_sessionKey(uid)];
    if (raw == null || raw.isEmpty) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear session for the active user and remove active marker.
  static void clearSession() {
    final uid = getActiveUid();
    if (uid != null) {
      _store.remove(_sessionKey(uid));
    }
    _store.remove(_activeUidKey);
  }

  /// Check if a session exists for the active user.
  static bool hasSession() {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return false;
    return _store.containsKey(_sessionKey(uid));
  }

  // ── Settings (per-user preferences) ───────────────────────────────────────

  /// Save a single setting for the active user.
  static void saveSetting(String key, dynamic value) {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return;
    final settings = getSettings();
    settings[key] = value;
    _store[_settingsKey(uid)] = json.encode(settings);
  }

  /// Save multiple settings at once for the active user.
  static void saveSettings(Map<String, dynamic> newSettings) {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return;
    final settings = getSettings();
    settings.addAll(newSettings);
    _store[_settingsKey(uid)] = json.encode(settings);
  }

  /// Get all settings for the active user.
  static Map<String, dynamic> getSettings() {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return {};
    return getSettingsForUid(uid);
  }

  /// Get all settings for a specific user.
  static Map<String, dynamic> getSettingsForUid(String uid) {
    final raw = _store[_settingsKey(uid)];
    if (raw == null || raw.isEmpty) return {};
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Get a single setting value for the active user.
  static T? getSetting<T>(String key) {
    final settings = getSettings();
    return settings[key] as T?;
  }

  /// Remove a single setting for the active user.
  static void removeSetting(String key) {
    final uid = getActiveUid();
    if (uid == null || uid.isEmpty) return;
    final settings = getSettings();
    settings.remove(key);
    _store[_settingsKey(uid)] = json.encode(settings);
  }

  /// Clear all settings for the active user.
  static void clearSettings() {
    final uid = getActiveUid();
    if (uid != null) {
      _store.remove(_settingsKey(uid));
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  /// Remove ALL data (session + settings) for a specific user.
  static void removeUserData(String uid) {
    _store.remove(_sessionKey(uid));
    _store.remove(_settingsKey(uid));
    // If this was the active user, clear the marker
    if (getActiveUid() == uid) {
      _store.remove(_activeUidKey);
    }
  }
}
