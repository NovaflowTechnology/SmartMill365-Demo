import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

/// Counts live instances of the objects most likely to be retained after a
/// page is left: State objects, polling services and timers.
///
/// A page that disposes cleanly returns to 0 once you navigate away. A count
/// that keeps climbing as you move between modules is a retention leak — the
/// old page is still alive, still holding its timers, its data and its whole
/// widget tree.
///
/// Active in debug and profile builds, silent in release. Profile matters here:
/// a debug web build is far heavier than what users get and hot restart leaves
/// the previous app in memory, so its numbers are not comparable to the live
/// site. `flutter run --profile` builds close to release and still reports.
class LeakProbe {
  LeakProbe._();

  static final Map<String, int> _live = {};
  static final Map<String, int> _created = {};
  static Timer? _reporter;

  /// Call from initState / constructor.
  static void register(String label) {
    if (kReleaseMode) return;
    _live[label] = (_live[label] ?? 0) + 1;
    _created[label] = (_created[label] ?? 0) + 1;
    _ensureReporter();
  }

  /// Counts an event (an HTTP poll, a rebuild) rather than a live object. The
  /// report shows how many happened in the last window, so "requests per minute
  /// stays constant over 30 minutes" can be read straight off the console.
  static final Map<String, int> _events = {};

  static void tick(String label) {
    if (kReleaseMode) return;
    _events[label] = (_events[label] ?? 0) + 1;
    _ensureReporter();
  }

  /// Call from dispose.
  static void unregister(String label) {
    if (kReleaseMode) return;
    _live[label] = (_live[label] ?? 1) - 1;
  }

  static void _ensureReporter() {
    if (_reporter != null) return;
    _reporter = Timer.periodic(const Duration(seconds: 30), (_) => report());
  }

  /// Prints the table now. Also called automatically every 30s.
  static void report() {
    if (kReleaseMode) return;
    final rows = _live.entries.where((e) => e.value != 0 || _created[e.key] != 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) return;
    final buf = StringBuffer('\n[LEAK PROBE] live / created\n');
    for (final r in rows) {
      final leaked = r.value > 1 ? '   <-- still alive' : '';
      buf.writeln('  ${r.key.padRight(34)} ${r.value.toString().padLeft(3)} /'
          ' ${(_created[r.key] ?? 0).toString().padLeft(4)}$leaked');
    }
    if (_events.isNotEmpty) {
      buf.writeln('  -- per 30s --');
      for (final e in _events.entries) {
        buf.writeln('  ${e.key.padRight(34)} ${e.value.toString().padLeft(3)}');
      }
      _events.clear();
    }
    debugPrint(buf.toString());
  }
}

/// Set to true to stop every decorative animation on the dashboards (pulse
/// dots, scan lines, float). They repeat forever at 60fps, so on CanvasKit they
/// keep the frame pipeline running even when nothing changes.
///
/// This exists to answer one question with a measurement instead of a guess:
/// flip it, rebuild, and see whether idle CPU drops. If it does, the decorative
/// animations are the cost and we decide which ones are worth keeping. If CPU
/// stays pinned, they are not the cause and we look elsewhere.
const bool kDisableDecorativeAnimations = false;

extension MaybeRepeat on AnimationController {
  /// repeat(), unless decorative animations are switched off.
  void maybeRepeat({bool reverse = false}) {
    if (kDisableDecorativeAnimations) return;
    repeat(reverse: reverse);
  }
}

/// Frames per second for decorative animations (pulse dots, scan lines).
///
/// Flutter drives an AnimationController at the display rate — 60fps. A 1.2s
/// pulse and a 2.5s scan look identical at a fraction of that, and each frame
/// skipped is a frame CanvasKit does not have to rasterise. 20fps is a third of
/// the work for no visible difference; lower it further if that is still too
/// much, raise it to 60 to restore the original behaviour.
const int kDecorativeAnimationFps = 20;

/// A repeating 0..1 animation driven by a Timer instead of a Ticker.
///
/// This is the point the throttling attempt missed: an AnimationController with
/// repeat() runs a Ticker, and while any Ticker is active Flutter schedules a
/// frame every vsync — 60 a second — whether or not a widget rebuilds. Sampling
/// the controller less often changed nothing because the frames were being
/// produced regardless.
///
/// With no Ticker, frames are only scheduled when this notifier changes, so the
/// pipeline genuinely runs at [kDecorativeAnimationFps].
class TimerDrivenAnimation extends ValueNotifier<double> {
  TimerDrivenAnimation({required this.period, this.reverse = false}) : super(0) {
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 / kDecorativeAnimationFps).round()),
      (_) => _tick(),
    );
  }

  final Duration period;

  /// Ping-pongs 0->1->0 instead of sawtoothing 0->1.
  final bool reverse;

  late final Timer _timer;
  final Stopwatch _clock = Stopwatch()..start();

  void _tick() {
    final t = (_clock.elapsedMilliseconds % period.inMilliseconds) /
        period.inMilliseconds;
    value = reverse ? (t < 0.5 ? t * 2 : (1 - t) * 2) : t;
  }

  @override
  void dispose() {
    _timer.cancel();
    _clock.stop();
    super.dispose();
  }
}

/// Whether the frosted-glass blur behind each CardWidget is drawn.
///
/// BackdropFilter forces a saveLayer, a read-back of everything beneath it and
/// a Gaussian blur, on every repaint. Energy Details renders about eleven cards,
/// so this was the largest single cost on the page — and it blurs a flat
/// background, so switching it off is barely visible.
/// Measured at roughly 4% of page memory — not worth losing the frosted glass.
/// Flip to false only if profiling on a specific machine says otherwise.
const bool kEnableCardBackdropBlur = true;

/// Whether the card border and bracket glows are drawn with a GPU blur.
///
/// Each blurred stroke is a separate blur pass. A page with eleven cards runs
/// twenty-two of them on every repaint. Off, the glow is drawn as a wider
/// translucent stroke instead — visually similar, no blur pass.
/// Turning it off did not move the numbers, so the glow stays.
const bool kEnableCardGlowBlur = true;

/// Whether the scan line sweeping down each card is drawn.
///
/// Unlike the pulse dot, which dirties 14x14 pixels, the scan line spans the
/// full width of a card and moves vertically, so every frame dirties the whole
/// card area. Four cards at 20fps repaint four full cards a frame — the largest
/// repaint area on the page by a wide margin. The pulse dots stay either way.
/// Kept: it is part of the look the client asked for, and the cost sits in
/// producing frames at all rather than in this one element.
const bool kEnableCardScanLine = true;
