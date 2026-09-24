import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import '../md_insight_report_colors.dart';

/// Daily maximum-demand bar chart with a dashed contract-capacity threshold
/// line — same look as Max Demand Monitoring's `DailyMaxDemandChart`, sized
/// to fit the Trend Analysis panel.
class TrendBarChart extends StatelessWidget {
  final List<double> values;
  final double thresholdValue;
  final Color barColor;

  /// Returns the x-axis label for [index] (out of [count] points), or null
  /// to skip that tick.
  final String? Function(int index, int count) labelBuilder;

  const TrendBarChart({
    super.key,
    required this.values,
    required this.thresholdValue,
    required this.labelBuilder,
    this.barColor = MdReportColors.green,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (values.isEmpty) {
      return Center(
        child: Text('No data available', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 14)),
      );
    }

    final rawMaxVal = values.fold<double>(thresholdValue, (m, v) => v > m ? v : m);
    final maxVal = rawMaxVal.isFinite ? rawMaxVal : 0.0;
    // Same 500 kW floor as LineAreaChart: avoids a zero maxY (and the
    // resulting NaN in fl_chart's tick generation) while the report is
    // still loading and every value is 0.
    final maxY = (((maxVal * 1.15) / 500).ceil() * 500.0).clamp(500.0, double.infinity).toDouble();

    final barWidth = values.length >= 30 ? 10.0 : (values.length >= 20 ? 11.0 : 12.0);
    final barSpacing = values.length >= 30 ? 6.0 : (values.length >= 20 ? 7.0 : 8.0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        groupsSpace: barSpacing,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color.fromRGBO(0, 4, 51, 0.9),
            tooltipBorder: BorderSide(color: theme.primary, width: 1),
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toInt()} kW',
              GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
            ),
          ),
        ),
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
              getTitlesWidget: (value, meta) {
                final label = labelBuilder(value.toInt(), values.length);
                if (label == null) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(label, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10)));
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (v) => FlLine(color: theme.secondaryText.withOpacity(0.1), strokeWidth: 1, dashArray: const [5, 5]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [for (int i = 0; i < values.length; i++) _makeGroupData(i, values[i], barWidth)],
        extraLinesData: ExtraLinesData(horizontalLines: [
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
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, double barWidth) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor.withOpacity(0.85),
          width: barWidth,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
        ),
      ],
    );
  }
}
