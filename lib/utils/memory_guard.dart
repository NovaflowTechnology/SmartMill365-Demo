import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'memory_guard_platform_stub.dart'
    if (dart.library.html) 'memory_guard_platform_web.dart' as platform;

/// Writes to the browser console.
///
/// Plain `print` on purpose. `debugPrint` produces nothing in a release web
/// build, and a `console.log` binding through JS interop threw and was
/// swallowed by its own fallback — so for two builds the guard ran completely
/// silently and there was no way to tell it apart from not running at all.
/// `print` is the one that demonstrably reaches the console here.
// ignore: avoid_print
void _log(String message) => print(message);

/// Keeps a long-running dashboard from reaching the browser's out-of-memory
/// kill, by reloading the page before it gets there.
///
/// This does not stop memory from growing — it stops the growth from ending in
/// a crash. A dashboard left open all day gets reloaded, costing about two
/// seconds, instead of dying and showing "Aw, Snap".
///
/// ## Why not memory
///
/// The obvious design is "reload when memory is high", and that is what this
/// class used to do. It never fired once. On web the only figure a page can
/// read about itself is `performance.memory.usedJSHeapSize`, and that covers
/// the JS heap alone. This app renders through CanvasKit, so almost everything
/// that grows lives in WASM linear memory and in GPU surfaces — neither of
/// which appears in that number. Tabs measured at 2.4 GB in Chrome's task
/// manager were still reporting a JS heap of well under 200 MB, so a 1500 MB
/// threshold could never be crossed no matter how bad things got.
///
/// `performance.measureUserAgentSpecificMemory()` does include WASM, but it
/// requires the document to be cross-origin isolated (COOP/COEP), which would
/// change how the app is served and would break cross-origin API calls. That is
/// not a trade worth making for a diagnostic.
///
/// So the signals here are ones the page can count for itself: how many times
/// it has navigated, and how long it has been open. Navigation is the primary
/// one — see [maxNavigations] for the measurements behind that. The heap check
/// is kept only for the rare case where the JS heap really is what grows.
///
/// ## When a reload happens
///
/// * hidden tab past [hiddenMaxAge] — nobody is looking, recycle immediately
/// * [hardMaxNavigations] page changes — even mid-interaction
/// * idle for [idleBefore] and past [maxNavigations] — the normal path
/// * past [maxAge] when idle, or [hardMaxAge] regardless — backstops for a
///   screen that is left on one module and never navigates at all
class MemoryGuard with WidgetsBindingObserver {
  MemoryGuard({
    // Sized from measurement, not preference. An idle tab climbs roughly
    // 20 MB per minute, so a 45-minute window let it reach about 900 MB before
    // recycling; 25 minutes holds the peak near 500 MB. Navigation costs far
    // more per event than time does, which is why its counts are so much
    // smaller than the minutes.
    this.maxNavigations = 12,
    this.hardMaxNavigations = 20,
    this.maxAge = const Duration(minutes: 25),
    this.hardMaxAge = const Duration(minutes: 50),
    this.hiddenMaxAge = const Duration(minutes: 5),
    this.heapLimitMb = 900,
    this.hardHeapLimitMb = 1500,
    this.idleBefore = const Duration(seconds: 45),
    this.checkEvery = const Duration(minutes: 1),
  });

  /// Reload after this many page changes, as soon as the user goes idle.
  ///
  /// Measured, not guessed: sitting on one page for 24 minutes moved the tab
  /// by about 60 MB, while a handful of moves between modules moved the tab and
  /// the GPU process by roughly 680 MB together. Each page builds new CanvasKit
  /// surfaces and the old ones are not given back when it is disposed, so what
  /// drives this app towards the browser's limit is navigation, not time.
  ///
  /// Age is kept as a backstop below, but it is the weaker signal: an operator
  /// who leaves one screen up all shift is in no danger, and one who moves
  /// between modules for ten minutes is — and only this counter sees that.
  final int maxNavigations;

  /// Reload at this count even mid-interaction. Somebody working quickly
  /// through modules never goes idle, which is exactly when the count climbs
  /// fastest.
  final int hardMaxNavigations;

  /// Reload once the page is this old, as soon as the user goes idle.
  final Duration maxAge;

  /// Reload at this age whether or not the user is busy. A wall-mounted screen
  /// that is touched constantly never satisfies the idle condition, and waiting
  /// politely for an idle moment that never comes ends in a crash.
  final Duration hardMaxAge;

  /// A tab the user cannot see is recycled far sooner. It costs nothing to
  /// reload, and several dashboards left open in background tabs add up on the
  /// same machine.
  final Duration hiddenMaxAge;

  /// Secondary trigger. Rarely reached in a CanvasKit build — see class docs.
  final int heapLimitMb;
  final int hardHeapLimitMb;

  final Duration idleBefore;
  final Duration checkEvery;

  final Stopwatch _age = Stopwatch();
  int _navigations = 0;

  /// How many times this tab has already recycled. Survives the reload in
  /// sessionStorage, because the console is wiped by every page load and a
  /// counter that resets tells you nothing about an unattended screen.
  ///
  /// Diagnostic only — it never affects when a reload happens. It exists to
  /// answer one question: does a reload actually give the memory back? Compare
  /// the tab's footprint at the same age across cycles. Flat means the reload
  /// is clean. Climbing means each cycle leaves something behind, and that
  /// would be beyond anything this class can fix.
  int _reloads = 0;
  String? _lastRoute;
  DateTime _lastInteraction = DateTime.now();
  Timer? _timer;
  bool _reloading = false;

  void start() {
    if (!kIsWeb) return;
    _age.start();
    _reloads = platform.readReloadCount();
    // Announce immediately. Waiting a full minute for the first line made it
    // impossible to tell "not started" apart from "not started yet".
    _log('[MemoryGuard] started — reloads so far $_reloads — recycle at '
        '$maxNavigations nav idle, $hardMaxNavigations nav hard, '
        '${maxAge.inMinutes}min idle, ${hiddenMaxAge.inMinutes}min hidden');
    _timer = Timer.periodic(checkEvery, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _age.stop();
  }

  /// Call from any pointer/key handler so an active user is never interrupted.
  void noteInteraction() => _lastInteraction = DateTime.now();

  /// Call on every route notification, passing the current route.
  ///
  /// Only a route that differs from the last one counts. The router notifies on
  /// every rebuild, not only when the page changes, so counting notifications
  /// gave 21 for a handful of actual moves — enough to trip a threshold of 20
  /// within a minute of normal use.
  ///
  /// Also drops decoded images, because leaving a page is the moment its
  /// bitmaps stop being needed.
  void noteNavigation(String route) {
    if (route == _lastRoute) return;
    _lastRoute = route;
    _navigations++;
    releaseCachedMemory();
  }

  /// JS heap in MB, or null where `performance.memory` is unavailable
  /// (everything outside Chromium). Reported for diagnostics; do not read this
  /// as the page's real memory use.
  int? get heapMb => platform.readUsedHeapMb();

  void _check() {
    if (_reloading) return;

    final age = _age.elapsed;
    final hidden = platform.isDocumentHidden();
    final mb = heapMb;
    final idle = DateTime.now().difference(_lastInteraction) >= idleBefore;

    // One line a minute, so it is possible to confirm from the console that the
    // guard is alive and to see how close it is — the previous version failed
    // silently for weeks precisely because it never said anything.
    _log('[MemoryGuard] age ${age.inMinutes}min, nav $_navigations, '
        'heap ${mb ?? "?"}MB, hidden=$hidden, idle=$idle, '
        'reloads=$_reloads');

    String? reason;
    if (hidden && age >= hiddenMaxAge) {
      reason = 'hidden ${age.inMinutes}min';
    } else if (_navigations >= hardMaxNavigations) {
      reason = 'hard nav $_navigations';
    } else if (idle && _navigations >= maxNavigations) {
      reason = 'idle at nav $_navigations';
    } else if (age >= hardMaxAge) {
      reason = 'hard age ${age.inMinutes}min';
    } else if (mb != null && mb >= hardHeapLimitMb) {
      reason = 'hard heap ${mb}MB';
    } else if (idle && age >= maxAge) {
      reason = 'idle at ${age.inMinutes}min';
    } else if (idle && mb != null && mb >= heapLimitMb) {
      reason = 'idle heap ${mb}MB';
    }

    if (reason == null) return;

    _reloading = true;
    platform.writeReloadCount(_reloads + 1);
    _log('[MemoryGuard] reloading — $reason (cycle ${_reloads + 1})');
    if (!platform.reloadPage()) {
      // Nothing happened, so the guard must not stay latched. Clearing this is
      // what lets the next tick try again instead of the tab going quiet.
      _reloading = false;
    }
  }
}

final memoryGuard = MemoryGuard();

/// Drops the decoded images the framework is holding, which is the one sizeable
/// thing here that can actually be released on demand.
///
/// Call it when the user changes what they are looking at — a filter change, a
/// device switch, leaving a page — because that is the moment the old decoded
/// bitmaps stop being needed. It cannot release CanvasKit's render surfaces;
/// those are outside Dart's reach.
///
/// Only the evicted half of the cache is cleared. `clearLiveImages()` also
/// drops images that are still on screen, and those do not come back on their
/// own — using it here made every icon and image in the app disappear.
void releaseCachedMemory() {
  PaintingBinding.instance.imageCache.clear();
}
