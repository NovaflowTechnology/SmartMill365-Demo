import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/utils/tou_window.dart';

class PowerLoadTrendChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> powerLoadData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final double maxPowerKw;
  final double contractCapacity;
  final DateTime? lastUpdated;

  /// Peak Hour ToU start/end as stored in settings ("HH:mm"). Null leaves the
  /// chart unshaded, which is what should happen when nobody has configured
  /// the window — an invented band would be read as fact.
  final String? peakStart;
  final String? peakEnd;

  /// Peak weekdays, 1 = Monday. Empty shades every day.
  final List<int> peakDays;

  const PowerLoadTrendChart({
    super.key,
    this.title = '',
    required this.powerLoadData,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.maxPowerKw = 0.0,
    this.contractCapacity = 1800.0,
    this.lastUpdated,
    this.peakStart,
    this.peakEnd,
    this.peakDays = const [],
  });

  double _getPowerValue(Map<String, dynamic> item) {
    final value = item['max_demand_kW'] ?? item['maxDemandKW'] ?? item['power'] ?? 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  /// Hour-of-day for a plotted point, or null when its timestamp cannot be
  /// read. Handles both the ISO timestamps the API returns and the plain
  /// "HH:mm" labels used elsewhere.
  double? _hourAt(int index) {
    if (index < 0 || index >= powerLoadData.length) return null;
    final label = _getTimeLabel(powerLoadData[index]);
    if (label.isEmpty) return null;
    final parsed = DateTime.tryParse(label);
    if (parsed != null) return parsed.hour + parsed.minute / 60.0;
    final parts = label.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h + m / 60.0;
  }

  /// Weekday for a plotted point, or null when the label carries no date.
  /// A bare "HH:mm" cannot say which day it is, and that is treated as
  /// unknown rather than assumed to be a peak day.
  int? _weekdayAt(int index) {
    if (index < 0 || index >= powerLoadData.length) return null;
    final parsed = DateTime.tryParse(_getTimeLabel(powerLoadData[index]));
    return parsed?.weekday;
  }

  String _getTimeLabel(Map<String, dynamic> item) {
    return item['time_label'] ?? item['timestamp'] ?? '';
  }

  List<FlSpot> get _powerLoadSpots {
    if (powerLoadData.isEmpty) return [];
    final spots = <FlSpot>[];
    for (var i = 0; i < powerLoadData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _getPowerValue(powerLoadData[i])));
    }
    return spots;
  }

  num get _maxY {
    double maxValue = maxPowerKw > 0 ? maxPowerKw : 0;
    if (powerLoadData.isNotEmpty) {
      double dataMax = powerLoadData.fold(0.0, (max, item) {
        double value = _getPowerValue(item);
        return value > max ? value : max;
      });
      maxValue = maxValue > dataMax ? maxValue : dataMax;
    }
    if (contractCapacity > maxValue) maxValue = contractCapacity;
    final calculatedMaxY = (maxValue * 1.2).ceilToDouble();
    final roundedMaxY = ((calculatedMaxY / 100).ceil() * 100).toDouble();
    return roundedMaxY > 0 ? roundedMaxY : 2000;
  }

  double get _minX => 0;

  double get _maxX {
    if (powerLoadData.isEmpty) return 24;
    return (powerLoadData.length - 1).toDouble();
  }

  String _getLastUpdatedText() {
    if (lastUpdated == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool heightBounded = constraints.maxHeight.isFinite;
        const double fallbackChartHeight = 280.0;

        Widget chartBody = _buildChart(context);

        return Column(
          mainAxisSize: heightBounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: sizing.accentW,
                            height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withOpacity(0.9),
                                  blurRadius: sizing.pad * 0.7,
                                  spreadRadius: sizing.accentW * 0.3,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: sizing.pad * 0.5),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title.isNotEmpty ? title : '24-Hour Power Load Trend',
                                style: GoogleFonts.poppins(
                                  fontSize: sizing.titleFs.clamp(12.0, 16.0),
                                  fontWeight: FontWeight.w700,
                                  color: isLight ? theme.txtPrimary : Colors.white,
                                  letterSpacing: 0.6,
                                  shadows: isLight ? null : [
                                    Shadow(
                                      color: theme.primary.withOpacity(0.7),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (lastUpdated != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            'Updated ${_getLastUpdatedText()}',
                            style: GoogleFonts.poppins(
                              color: theme.secondaryText,
                              fontSize: sizing.bodyFs.clamp(9.0, 11.0),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(errorMessage!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      ),
                    if (onRefresh != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.refresh, color: theme.secondaryText, size: 20),
                        onPressed: isLoading ? null : onRefresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Refresh data',
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Legend ───────────────────────────────────────────────────────
            Row(
              children: [
                _buildLegendItem(context, color: Colors.blue, label: 'Power Load (kW)', sizing: sizing),
                const SizedBox(width: 20),
                _buildLegendItem(context, color: Colors.red.withOpacity(0.3), label: 'Contract Capacity', isDashed: true, sizing: sizing),
                // Only named when a window is actually configured — a legend
                // entry for a band that is not drawn sends the reader looking
                // for something that is not there.
                if (TouWindow.parse(peakStart, peakEnd) != null) ...[
                  const SizedBox(width: 20),
                  _buildZoneLegendItem(context,
                      fill: const Color(0x4DFF5252),
                      edge: const Color(0xE6FF5252),
                      label: 'Peak Hour ToU',
                      sizing: sizing),
                  const SizedBox(width: 20),
                  _buildZoneLegendItem(context,
                      fill: const Color(0x2E66BB6A),
                      edge: const Color(0x9966BB6A),
                      label: 'Off Peak',
                      sizing: sizing),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Chart body ───────────────────────────────────────────────────
            heightBounded
                ? Expanded(child: chartBody)
                : SizedBox(height: fallbackChartHeight, child: chartBody),
          ],
        );
      },
    );
  }

  /// A filled swatch rather than a line, because these entries stand for
  /// shaded areas behind the series, not for series of their own.
  Widget _buildZoneLegendItem(
    BuildContext context, {
    required Color fill,
    required Color edge,
    required String label,
    required CardSizing sizing,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 10,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: edge, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: sizing.bodyFs.clamp(9.0, 12.0),
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    bool isDashed = false,
    required CardSizing sizing,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: isDashed ? 2 : 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: sizing.bodyFs.clamp(9.0, 12.0),
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading && powerLoadData.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
        ),
      );
    }

    if (powerLoadData.isEmpty) return _buildEmptyState(context);

    return LineChart(
      _buildLineChartData(context),
      key: ValueKey('linechart_${powerLoadData.hashCode}'),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: theme.secondaryText),
          const SizedBox(height: 16),
          Text('No data available', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 14)),
          if (onRefresh != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Refresh', style: GoogleFonts.poppins(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    double yInterval = (_maxY / 5).ceilToDouble();
    if (yInterval > 100) {
      yInterval = ((yInterval / 100).ceil() * 100).toDouble();
    } else if (yInterval > 50) {
      yInterval = ((yInterval / 50).ceil() * 50).toDouble();
    }

    int dataPointCount = powerLoadData.length;
    double xInterval;
    if (dataPointCount <= 12) {
      xInterval = 1;
    } else if (dataPointCount <= 24) {
      xInterval = 2;
    } else if (dataPointCount <= 48) {
      xInterval = 4;
    } else {
      xInterval = (dataPointCount / 10).ceilToDouble();
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        // Vertical guides lined up with the time labels below, matching the
        // insight report's chart so the two read the same way.
        drawVerticalLine: true,
        verticalInterval: xInterval,
        getDrawingVerticalLine: (value) => FlLine(
          color: theme.secondaryText.withOpacity(0.08),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.secondaryText.withOpacity(0.1),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: xInterval,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index < 0 || index >= powerLoadData.length) return const SizedBox.shrink();
              String timeLabel = _getTimeLabel(powerLoadData[index]);
              try {
                final time = DateTime.parse(timeLabel);
                timeLabel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              } catch (e) {
                if (timeLabel.isEmpty) return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(timeLabel, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(value.toInt().toString(), style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10));
            },
          ),
        ),
      ),
      rangeAnnotations: RangeAnnotations(
        verticalRangeAnnotations: [
          // Derived from each point's own timestamp, not from the axis
          // position. This chart shows a rolling 24 hours that can start at
          // any hour, so assuming it runs midnight to midnight put the band
          // in the wrong place entirely.
          for (final span in TouWindow.parse(peakStart, peakEnd,
                      days: peakDays)
                  ?.spansFromHours(powerLoadData.length, _hourAt,
                      weekdayAt: _weekdayAt) ??
              const <({double from, double to})>[])
            VerticalRangeAnnotation(
              x1: span.from,
              x2: span.to,
              // Amber rather than the panel's cyan, which is the colour of
              // the load line and made the band look like part of the series.
              // Heavier than it looks on paper: over this dark navy a light
              // wash turns grey and stops reading as a colour.
              color: const Color(0x4DFF5252),
            ),
          // Off-peak, cool and much fainter, so the day reads as two named
          // zones instead of one stripe and an unexplained remainder.
          for (final span in TouWindow.parse(peakStart, peakEnd,
                      days: peakDays)
                  ?.spansFromHours(powerLoadData.length, _hourAt,
                      weekdayAt: _weekdayAt, inside: false) ??
              const <({double from, double to})>[])
            VerticalRangeAnnotation(
              x1: span.from,
              x2: span.to,
              color: const Color(0x2E66BB6A),
            ),
        ],
      ),
      borderData: FlBorderData(show: false),
      minX: _minX,
      maxX: _maxX,
      minY: 0,
      maxY: _maxY.toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: _powerLoadSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.05)],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (value) => const Color.fromRGBO(0, 4, 51, 0.9),
          tooltipBorder: BorderSide(color: theme.primary, width: 1),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              int index = spot.x.toInt();
              String timeLabel = '';
              if (index >= 0 && index < powerLoadData.length) {
                timeLabel = _getTimeLabel(powerLoadData[index]);
                try {
                  final time = DateTime.parse(timeLabel);
                  timeLabel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                } catch (_) {
                  // use original label if parsing fails
                }
              }
              return LineTooltipItem(
                '${spot.y.toInt()} kW\n$timeLabel',
                GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              );
            }).toList();
          },
        ),
      ),
      extraLinesData: ExtraLinesData(
        verticalLines: [
          // Dashed edges on the ToU band, matching the insight report so the
          // same window looks the same on both screens.
          for (final span in TouWindow.parse(peakStart, peakEnd,
                      days: peakDays)
                  ?.spansFromHours(powerLoadData.length, _hourAt,
                      weekdayAt: _weekdayAt) ??
              const <({double from, double to})>[]) ...[
            VerticalLine(
              x: span.from,
              color: const Color(0xE6FF5252),
              strokeWidth: 1.5,
              dashArray: const [4, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(left: 6, bottom: 2),
                style: GoogleFonts.poppins(
                  color: const Color(0xE6FF5252),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                labelResolver: (_) => 'PEAK',
              ),
            ),
            VerticalLine(
              x: span.to,
              color: const Color(0xE6FF5252),
              strokeWidth: 1.5,
              dashArray: const [4, 4],
            ),
          ],
        ],
        horizontalLines: [
          HorizontalLine(
            y: contractCapacity,
            color: Colors.red.withOpacity(0.5),
            strokeWidth: 2,
            dashArray: [8, 4],
            label: HorizontalLineLabel(show: false),
          ),
        ],
      ),
    );
  }
}
