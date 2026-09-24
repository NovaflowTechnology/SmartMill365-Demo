import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_presence_unload_hook_stub.dart'
    if (dart.library.html) 'user_presence_unload_hook_web.dart' as unload;

/// Real-time online/offline presence via Firestore (no backend needed).
///
/// Uses a heartbeat approach: writes `last_seen` every 15 seconds.
/// A user is considered "online" if their `last_seen` is within 40 seconds.
/// On tab/browser close (`pagehide`) we best-effort write `status: offline`
/// so another browser can log in immediately instead of waiting out the
/// heartbeat freshness window.
///
/// Usage:
///   UserPresence.goOnline(uid);      // after login
///   UserPresence.goOffline(uid);     // on logout
///   UserPresence.statusStream(uid);  // Stream<String?> 'online'|'offline'
class UserPresence {
  static StreamSubscription? _heartbeatSub;
  static String? _activeUid;
  static String? _activeSessionId;
  static bool _unloadHookInstalled = false;

  /// The session ID that was written to Firestore for the current login.
  /// Null on a new page load until the first [goOnline] with a sessionId is called.
  static String? get activeSessionId => _activeSessionId;

  /// Generate a cryptographically random 32-char hex session ID.
  static String generateSessionId() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return values.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// When true, the auth-state listener in `nav.dart` will NOT auto-call
  /// `goOnline` on user updates. The login flow flips this on before
  /// `signInWithEmail` so it can run its own presence check first without
  /// the listener racing in and overwriting another browser's heartbeat
  /// with our own (which would make the check pass against itself).
  /// `_login()` is responsible for resetting it and calling `goOnline`
  /// manually once the check has passed.
  static bool suspendAutoStart = false;

  /// Heartbeat cadence and freshness window. Keep `freshSeconds` > a couple
  /// of `heartbeatSeconds` so a single missed write doesn't flap the user
  /// to offline, but small enough that a closed tab clears within ~40s.
  static const int heartbeatSeconds = 15;
  static const int freshSeconds = 40;

  static void _installUnloadHook() {
    if (_unloadHookInstalled) return;
    _unloadHookInstalled = true;
    unload.installUnloadHook(() {
      final uid = _activeUid;
      if (uid == null) return;
      try {
        _presenceCol.doc(uid).set({
          'status': 'offline',
          'last_seen': FieldValue.serverTimestamp(),
          'session_id': FieldValue.delete(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  static final _presenceCol =
      FirebaseFirestore.instance.collection('presence');

  /// Mark current user as online + start heartbeat.
  ///
  /// Pass [sessionId] only on an explicit login — it is written to Firestore
  /// and stored as [activeSessionId] so other browsers can detect the takeover.
  /// The heartbeat and auto-start calls (no [sessionId]) deliberately omit the
  /// field so they never overwrite the session that was established at login.
  static Future<void> goOnline(String uid, {String? sessionId}) async {
    _activeUid = uid;
    if (sessionId != null) _activeSessionId = sessionId;
    _installUnloadHook();
    final ref = _presenceCol.doc(uid);

    final data = <String, dynamic>{
      'status': 'online',
      'last_seen': FieldValue.serverTimestamp(),
    };
    if (sessionId != null) {
      data['session_id'] = sessionId;
      data['last_login_at'] = FieldValue.serverTimestamp();
    }

    try {
      await ref.set(data, SetOptions(merge: true));
      debugPrint('[UserPresence] goOnline SUCCESS for $uid');
    } catch (e) {
      debugPrint('[UserPresence] goOnline FAILED for $uid: $e');
    }

    // Heartbeat: re-asserts session_id + status + last_seen every tick.
    // Writing session_id here makes presence self-healing — if another tab's
    // logout cleared session_id, the next heartbeat (≤15s) restores it so
    // this browser remains the active session holder.
    _heartbeatSub?.cancel();
    _heartbeatSub =
        Stream.periodic(const Duration(seconds: heartbeatSeconds)).listen((_) {
      if (_activeUid == uid) {
        final tickData = <String, dynamic>{
          'status': 'online',
          'last_seen': FieldValue.serverTimestamp(),
        };
        if (_activeSessionId != null) {
          tickData['session_id'] = _activeSessionId;
        }
        ref.set(tickData, SetOptions(merge: true)).catchError((e) {
          debugPrint('[UserPresence] heartbeat failed: $e');
        });
      }
    });
  }

  /// Stop the heartbeat and clear local state without writing to Firestore.
  /// Used when this browser is force-kicked by a new login on another browser —
  /// we must NOT write `status:offline` because that would kill the new session.
  static void cancelHeartbeatOnly() {
    _activeUid = null;
    _activeSessionId = null;
    _heartbeatSub?.cancel();
    _heartbeatSub = null;
  }

  /// Mark current user as offline (explicit logout).
  /// Clears session_id so the next login attempt is allowed immediately.
  static Future<void> goOffline(String uid) async {
    _activeUid = null;
    _activeSessionId = null;
    _heartbeatSub?.cancel();
    _heartbeatSub = null;
    try {
      await _presenceCol.doc(uid).set({
        'status': 'offline',
        'last_seen': FieldValue.serverTimestamp(),
        'session_id': FieldValue.delete(),
      }, SetOptions(merge: true));
      debugPrint('[UserPresence] goOffline SUCCESS for $uid');
    } catch (e) {
      debugPrint('[UserPresence] goOffline FAILED: $e');
    }
  }

  static final Map<String, Stream<String?>> _sessionIdStreamCache = {};
  static final Map<String, Stream<String?>> _statusStreamCache = {};

  /// Clear stream caches when logging out or resetting user presence.
  static void clearStreamCaches() {
    _sessionIdStreamCache.clear();
    _statusStreamCache.clear();
  }

  /// Real-time stream of the `session_id` field for a user.
  /// Emits the current session_id whenever it changes in Firestore.
  /// Used by [AppStateNotifier] to detect when another login has taken over.
  static Stream<String?> sessionIdStream(String uid) {
    return _sessionIdStreamCache.putIfAbsent(uid, () {
      return _presenceCol.doc(uid).snapshots().map((snap) {
        if (!snap.exists) return null;
        return snap.data()?['session_id'] as String?;
      }).handleError((e) {
        debugPrint('[UserPresence] sessionIdStream ERROR for $uid: $e');
      }).asBroadcastStream();
    });
  }

  /// Real-time stream of 'online' | 'offline' for a specific user.
  /// Listens to Firestore snapshots — updates are near-instant.
  /// User is "online" only if status == 'online' AND last_seen < 90s ago.
  static Stream<String?> statusStream(String uid) {
    return _statusStreamCache.putIfAbsent(uid, () {
      debugPrint('[UserPresence] statusStream subscribed for $uid');
      return _presenceCol.doc(uid).snapshots().map((snap) {
        if (!snap.exists) return 'offline';
        final data = snap.data();
        if (data == null) return 'offline';

        final status = data['status']?.toString() ?? 'offline';
        final lastSeen = data['last_seen'] as Timestamp?;

        // Consider online only if status is 'online' AND heartbeat is fresh
        if (status == 'online' && lastSeen != null) {
          final age = DateTime.now().difference(lastSeen.toDate());
          if (age.inSeconds <= freshSeconds) {
            return 'online';
          }
        }
        return 'offline';
      }).handleError((e) {
        debugPrint('[UserPresence] statusStream ERROR for $uid: $e');
      }).asBroadcastStream();
    });
  }
}
