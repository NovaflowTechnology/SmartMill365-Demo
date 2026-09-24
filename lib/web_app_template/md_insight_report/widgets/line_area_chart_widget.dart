import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import 'package:smartmachine365/utils/tou_window.dart';

import '../md_insight_report_colors.dart';

/// Peak Hour ToU band colours, shared with the legend swatch so the two can
/// never disagree. A brighter orange than the palette's, because the band is a
/// wash over a dark panel rather than a solid mark.
// Traffic-light zones: red is the expensive window, green is the cheap one,
// which is the reading people already bring to a tariff chart.
//
// Both are heavier than they look written down. A translucent wash over this
// dark navy loses saturation fast — amber at 25% came out as brown, and
// nobody should have to read "brown" as "peak tariff".
const Color _touFill = Color(0x4DFF5252);
const Color _touEdge = Color(0xE6FF5252);

/// Off-peak gets its own wash so the day reads as two named zones rather than
/// one shaded stripe and an unexplained remainder. Cool and much fainter, so
/// it separates from peak at a glance without fighting the series.
const Color _offPeakFill = Color(0x2E66BB6A);

/// Minimal filled line chart with a dashed contract-capacity threshold line,
/// used for both the 24h load trend and the daily MD trend so their look
/// stays consistent.
class LineAreaChart extends StatelessWidget {
  final List<double> values;
  final double thresholdValue;
  final Color lineColor;

  /// Returns the x-axis label for [index] (out of [count] points), or null
  /// to skip that tick.
  final String? Function(int index, int count) labelBuilder;

  /// Peak Hour ToU window to shade behind the series, or null to shade
  /// nothing. Reading the chart against the tariff window is most of the
  /// point of looking at it — where the load sits matters as much as how high
  /// it goes — and until now that had to be held in the reader's head.
  final TouWindow? touWindow;

  const LineAreaChart({
    super.key,
    required this.values,
    required this.thresholdValue,
    required this.labelBuilder,
    this.lineColor = MdReportColors.blue,
    this.touWindow,
  });

  /// This chart's axis is always a full day across evenly spaced points, so a
  /// point's hour follows from its position.
  double? _hourAtIndex(int index) {
    if (values.length < 2) return null;
    return index * 24 / (values.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final rawMaxVal = values.fold<double>(thresholdValue, (m, v) => v > m ? v : m);
    final maxVal = rawMaxVal.isFinite ? rawMaxVal : 0.0;
    // Clamped to a 500 kW floor: when both the contract-capacity threshold and
    // every value are 0 (e.g. report still loading), maxY would otherwise be 0
    // too, making horizontalInterval/leftTitles.interval (maxY / 5) also 0 —
    // fl_chart's tick generation divides by that interval and throws
    // "Unsupported operation: NaN" internally.
    final maxY = (((maxVal * 1.15) / 500).ceil() * 500.0).clamp(500.0, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          // Vertical guides at the same 4-hour spacing as the axis labels, so
          // a peak can be read back to a time without tracing down to the
          // axis. Fainter than the horizontal ones because they cross the
          // filled area, where a strong line would compete with the series.
          drawVerticalLine: true,
          verticalInterval:
              values.length > 6 ? (values.length - 1) / 6 : 1,
          getDrawingVerticalLine: (v) => FlLine(
            color: theme.secondaryText.withOpacity(0.08),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (v) => FlLine(color: theme.secondaryText.withOpacity(0.1), strokeWidth: 1, dashArray: const [5, 5]),
        ),
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: [
            for (final span in touWindow?.spansFromHours(
                    values.length, _hourAtIndex) ??
                const <({double from, double to})>[])
              VerticalRangeAnnotation(
                x1: span.from,
                x2: span.to,
                // Amber, not blue: blue is the load series itself, so a blue
                // band read as part of the line rather than as a tariff
                // window. At 0.16 over the dark navy panel it desaturated into
                // a muddy grey and stopped reading as a colour at all, so the
                // fill is heavier and the hue brighter than the palette's
                // orange.
                color: _touFill,
              ),
            for (final span in touWindow?.spansFromHours(
                    values.length, _hourAtIndex,
                    inside: false) ??
                const <({double from, double to})>[])
              VerticalRangeAnnotation(
                x1: span.from,
                x2: span.to,
                color: _offPeakFill,
              ),
          ],
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 11)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final label = labelBuilder(v.toInt(), values.length);
                if (label == null) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(label, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10)));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color.fromRGBO(0, 4, 51, 0.9),
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y.toInt()} kW', GoogleFonts.poppins(color: Colors.white, fontSize: 13.5))).toList(),
          ),
        ),
        extraLinesData: ExtraLinesData(verticalLines: [
          // Dashed edges on the ToU band. A flat wash of colour alone reads as
          // a rendering artefact; an explicit boundary reads as a tariff
          // window with a start and an end.
          for (final span in touWindow?.spansFromHours(
                  values.length, _hourAtIndex) ??
              const <({double from, double to})>[]) ...[
            VerticalLine(
              x: span.from,
              color: _touEdge,
              strokeWidth: 1.5,
              dashArray: const [4, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(left: 6, bottom: 2),
                style: GoogleFonts.poppins(
                  color: _touEdge,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                labelResolver: (_) => 'PEAK',
              ),
            ),
            VerticalLine(
              x: span.to,
              color: _touEdge,
              strokeWidth: 1.5,
              dashArray: const [4, 4],
            ),
          ],
        ], horizontalLines: [
          HorizontalLine(
            y: thresholdValue,
            color: MdReportColors.red.withOpacity(0.6),
            strokeWidth: 2,
            dashArray: const [8, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              style: GoogleFonts.poppins(color: MdReportColors.red, fontSize: 10, fontWeight: FontWeight.w600),
              labelResolver: (line) => 'Contract Capacity (${thresholdValue.toInt()} kW)',
            ),
          ),
        ]),
        lineBarsData: [
          LineChartBarData(
            spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.03)]),
            ),
          ),
        ],
      ),
    );
  }
}
