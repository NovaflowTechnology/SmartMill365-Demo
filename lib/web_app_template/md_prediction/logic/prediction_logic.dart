import 'dart:math';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class PredictionResult {
  /// Combined list: real readings first, then projected points.
  final List<double> allValues;

  /// Index in [allValues] where predictions begin.
  final int predictionStartIndex;

  /// Estimated peak at the end of the current 30-min MD interval,
  /// including the configured safety buffer.
  final double predictedPeak;

  const PredictionResult({
    required this.allValues,
    required this.predictionStartIndex,
    required this.predictedPeak,
  });
}

// ---------------------------------------------------------------------------
// Algorithm: Simple Linear Regression projection
// ---------------------------------------------------------------------------

/// Runs simple linear regression on the last [windowSize] readings in
/// [values], projects [projectCount] future points, and applies a
/// [safetyBuffer] (5 % by default) to the computed peak.
///
/// Returns a [PredictionResult] with the combined real + projected values and
/// the safety-buffered predicted peak.
PredictionResult computePrediction(
  List<double> values, {
  int windowSize = 8,
  int projectCount = 3,
  double safetyBuffer = 0.05,
}) {
  if (values.isEmpty) {
    return const PredictionResult(
      allValues: [],
      predictionStartIndex: 0,
      predictedPeak: 0,
    );
  }

  // Slide to the last [windowSize] samples.
  final window = values.length <= windowSize
      ? values
      : values.sublist(values.length - windowSize);

  final n = window.length;
  double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
  for (int i = 0; i < n; i++) {
    sumX += i;
    sumY += window[i];
    sumXY += i * window[i];
    sumXX += i * i;
  }
  final denom = n * sumXX - sumX * sumX;
  final slope = denom == 0 ? 0.0 : (n * sumXY - sumX * sumY) / denom;
  final intercept = (sumY - slope * sumX) / n;

  // Project [projectCount] future points beyond the window.
  final projected = <double>[
    for (int i = 1; i <= projectCount; i++)
      intercept + slope * (n - 1 + i),
  ];

  final allValues = [...values, ...projected];
  final predictedPeak = allValues.reduce(max) * (1 + safetyBuffer);

  return PredictionResult(
    allValues: allValues,
    predictionStartIndex: values.length,
    predictedPeak: predictedPeak,
  );
}

// ---------------------------------------------------------------------------
// Macro prediction model
// ---------------------------------------------------------------------------

class MacroPredictionResult {
  /// The actual data slice displayed on the trend chart.
  final List<double> actualSlice;

  /// Time labels matching [actualSlice].
  final List<String> actualLabels;

  /// 3 projected 30-min interval values.
  final List<double> predictedValues;

  /// ISO-8601 timestamps for the 3 projected intervals.
  final List<String> predictedLabels;

  /// Max of the 3 predicted values — shown in the "NEXT 90M PEAK" card.
  final double next90mPeak;

  const MacroPredictionResult({
    required this.actualSlice,
    required this.actualLabels,
    required this.predictedValues,
    required this.predictedLabels,
    required this.next90mPeak,
  });
}

// ---------------------------------------------------------------------------
// Algorithm: 30-min macro regression with time-of-day adjustment
// ---------------------------------------------------------------------------

/// Runs linear regression on up to [windowSize] of the most recent 30-min
/// readings in [values], projects 3 future 30-min intervals, and applies a
/// time-of-day multiplier to each projected point.
///
/// [timeLabels] must be ISO-8601 strings aligned with [values].
/// Returns [MacroPredictionResult.predictedValues] clamped to ≥ 0.
MacroPredictionResult computeMacroPrediction(
  List<double> values,
  List<String> timeLabels, {
  int windowSize = 10,
  int displaySize = 12,
}) {
  if (values.isEmpty) {
    return const MacroPredictionResult(
      actualSlice: [],
      actualLabels: [],
      predictedValues: [],
      predictedLabels: [],
      next90mPeak: 0,
    );
  }

  // Clamp window to available data.
  final effWindow = min(windowSize, values.length);
  final window = values.sublist(values.length - effWindow);
  final windowLabels = timeLabels.length >= effWindow
      ? timeLabels.sublist(timeLabels.length - effWindow)
      : List<String>.filled(effWindow, '');

  // Linear least-squares regression.
  final n = window.length;
  double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
  for (int i = 0; i < n; i++) {
    sumX += i;
    sumY += window[i];
    sumXY += i * window[i];
    sumXX += i * i;
  }
  final denom = n * sumXX - sumX * sumX;
  final slope = denom == 0 ? 0.0 : (n * sumXY - sumX * sumY) / denom;
  final intercept = (sumY - slope * sumX) / n;

  // Parse the last known timestamp for future point generation.
  DateTime? lastTime;
  for (int i = windowLabels.length - 1; i >= 0; i--) {
    try {
      lastTime = DateTime.parse(windowLabels[i]);
      break;
    } catch (_) {}
  }
  lastTime ??= DateTime.now();

  // Project 3 future intervals with time-of-day adjustment.
  final predictedValues = <double>[];
  final predictedLabels = <String>[];
  for (int i = 1; i <= 3; i++) {
    final rawValue = intercept + slope * (n - 1 + i);
    final nextTime = lastTime.add(Duration(minutes: 30 * i));
    final adjusted = rawValue.clamp(0.0, double.infinity) * _timeAdjustment(nextTime);
    predictedValues.add(adjusted);
    predictedLabels.add(nextTime.toIso8601String());
  }

  // Slice for display (show last [displaySize] actual points on the chart).
  final effDisplay = min(displaySize, values.length);
  final actualSlice = values.sublist(values.length - effDisplay);
  final actualLabels = timeLabels.length >= effDisplay
      ? timeLabels.sublist(timeLabels.length - effDisplay)
      : List<String>.filled(effDisplay, '');

  final next90mPeak = predictedValues.isEmpty ? 0.0 : predictedValues.reduce(max);

  return MacroPredictionResult(
    actualSlice: actualSlice,
    actualLabels: actualLabels,
    predictedValues: predictedValues,
    predictedLabels: predictedLabels,
    next90mPeak: next90mPeak,
  );
}

double _timeAdjustment(DateTime time) {
  final h = time.hour;
  if (h >= 17 || h < 7) return 1.075; // night: +7.5%
  return 0.95; // day: -5%
}
