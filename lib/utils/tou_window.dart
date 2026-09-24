/// The Peak Hour ToU window, shared by every chart that shades it.
///
/// The window is configured once in Energy System Settings
/// (`contractCapacity.peakHourToU`) as `"HH:mm"` strings, and several charts
/// need to draw the same band over a 24-hour axis. Keeping the parsing and the
/// wrap-around handling here means those charts cannot drift apart — a band
/// that disagrees between two screens is worse than no band at all.
class TouWindow {
  const TouWindow(this.startHour, this.endHour, {this.days = const []});

  /// Hours past midnight, e.g. 14:30 is 14.5.
  final double startHour;
  final double endHour;

  /// Weekdays the window applies to, 1 = Monday through 7 = Sunday, matching
  /// Dart's `DateTime.weekday`. Empty means every day — which is also what a
  /// caller gets when it has no way to tell one day from another, so the band
  /// stays visible rather than silently vanishing.
  final List<int> days;

  /// Parses `"HH:mm"` (as stored in settings) into a window, or null when
  /// either end is missing or malformed. Null means "not configured", and
  /// callers draw nothing rather than guessing a default window.
  static TouWindow? parse(String? start, String? end,
      {List<int> days = const []}) {
    final s = _hours(start);
    final e = _hours(end);
    if (s == null || e == null || s == e) return null;
    return TouWindow(s, e, days: days);
  }

  static double? _hours(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 24 || m < 0 || m > 59) {
      return null;
    }
    return h + m / 60.0;
  }

  /// True when the window runs past midnight, e.g. 22:00 to 06:00.
  bool get wrapsMidnight => endHour < startHour;

  /// The window as ranges of hours, split in two when it wraps midnight so a
  /// chart can shade both ends of the axis.
  List<({double from, double to})> get hourRanges => wrapsMidnight
      ? [(from: startHour, to: 24.0), (from: 0.0, to: endHour)]
      : [(from: startHour, to: endHour)];

  /// The same ranges expressed in chart x-coordinates, for an axis that runs
  /// from midnight to midnight across [lastIndex] + 1 evenly spaced points.
  ///
  /// Only correct when the axis really does start at 00:00. A rolling 24-hour
  /// window starting at, say, 14:00 needs [spansFromHours] instead.
  List<({double from, double to})> spanFor(int lastIndex) {
    if (lastIndex <= 0) return const [];
    final scale = lastIndex / 24.0;
    return hourRanges
        .map((r) => (from: r.from * scale, to: r.to * scale))
        .toList();
  }

  /// Bands derived from the hour each plotted point actually falls on.
  ///
  /// This is the safe version: it makes no assumption about where the axis
  /// begins, so it works for a rolling window as well as a midnight-to-
  /// midnight day. [hourAt] returns the hour-of-day for a point, or null if
  /// that point has no usable timestamp.
  ///
  /// Consecutive in-window points are merged into one band, and the edges are
  /// pushed out half a step so the shading meets the neighbouring points
  /// rather than stopping short at their centres.
  /// [weekdayAt] returns 1-7 for a point, or null when unknown. Points on a
  /// day outside [days] are left unshaded, so a Saturday reading is not
  /// presented as peak-rate time.
  /// [inside] false returns the gaps instead — the off-peak stretches — so a
  /// chart can colour both zones from one window rather than shading one and
  /// leaving the reader to infer the other.
  List<({double from, double to})> spansFromHours(
    int count,
    double? Function(int index) hourAt, {
    int? Function(int index)? weekdayAt,
    bool inside = true,
  }) {
    if (count <= 1) return const [];
    final spans = <({double from, double to})>[];
    int? runStart;
    for (var i = 0; i < count; i++) {
      final h = hourAt(i);
      final isPeak = h != null &&
          contains(h) &&
          appliesOn(weekdayAt == null ? null : weekdayAt(i));
      final wanted = inside ? isPeak : !isPeak;
      if (wanted && runStart == null) {
        runStart = i;
      } else if (!wanted && runStart != null) {
        spans.add((from: runStart - 0.5, to: i - 0.5));
        runStart = null;
      }
    }
    if (runStart != null) {
      spans.add((from: runStart - 0.5, to: count - 1 + 0.5));
    }
    return spans;
  }

  /// Whether the window applies on a given weekday. An unknown weekday, or an
  /// empty [days], counts as applying.
  bool appliesOn(int? weekday) =>
      days.isEmpty || weekday == null || days.contains(weekday);

  /// Whether an hour-of-day falls inside the window, wrap-around included.
  bool contains(double hour) => wrapsMidnight
      ? hour >= startHour || hour < endHour
      : hour >= startHour && hour < endHour;
}
