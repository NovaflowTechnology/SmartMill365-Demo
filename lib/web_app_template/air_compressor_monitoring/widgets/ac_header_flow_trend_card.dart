import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';
import 'ac_specific_energy_trend_card.dart' show kAcChartRanges;

/// "Header Flow — 24H" line chart: header flow over time plus a dashed Min
/// Flow Threshold line.
class AcHeaderFlowTrendCard extends StatelessWidget {
  const AcHeaderFlowTrendCard({
    super.key,
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
    this.minFlowThreshold,
  });

  // Null when the Header Flow device isn't mapped (or Header Flow otherwise
  // has no live series yet) — the chart shows an empty state instead of
  // fabricating a series.
  final List<AcFlowTrendPoint>? points;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  // Leak min-flow threshold — configured in Air Compressor Dashboard
  // Setting, null (threshold line not drawn) when nothing's been saved yet.
  final double? minFlowThreshold;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final lineColor = isLight ? t.primary : const Color(0xFF31ECFC);
    const leakageColor = Color(0xFFE74852);

    final points = this.points;
    final hasData = points != null && points.isNotEmpty;
    final maxY = hasData ? points.map((p) => p.flowM3Min).reduce((a, b) => a > b ? a : b) * 1.2 : 1.0;

    final spots = hasData ? <FlSpot>[for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].flowM3Min)] : const <FlSpot>[];
    final threshold = minFlowThreshold;
    final thresholdLine = threshold == null
        ? null
        : <FlSpot>[
            FlSpot(0, threshold),
            FlSpot((spots.length - 1).toDouble(), threshold),
          ];

    return DashboardCard(
      title: 'HEADER FLOW — 24H',
      subtitle: 'm³/min',
      trailing: hasData ? _LegendDot(color: lineColor, label: 'Header Flow') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: !hasData
                ? const _EmptyChartState(message: 'Map the Header Flow device\nin Air Compressor Dashboard Setting')
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (points.length / 6).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              final i = value.round();
                              if (i < 0 || i >= points.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(points[i].time, style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => isLight ? Colors.white : const Color(0xFF0D1A2E),
                          tooltipBorder: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
                          getTooltipItems: (touchedSpots) => touchedSpots
                              .where((s) => s.barIndex == 0)
                              .map((s) => LineTooltipItem(
                                    '${s.y.toStringAsFixed(1)} m³/min',
                                    GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: lineColor),
                                  ))
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.25,
                          color: lineColor,
                          barWidth: 2.4,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [lineColor.withOpacity(0.16), lineColor.withOpacity(0.0)],
                            ),
                          ),
                        ),
                        if (thresholdLine != null)
                          LineChartBarData(
                            spots: thresholdLine,
                            isCurved: false,
                            color: leakageColor,
                            barWidth: 1.4,
                            dashArray: const [6, 4],
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
          ),
          if (hasData && thresholdLine != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 8, height: 1.4, color: leakageColor),
                const SizedBox(width: 4),
                Text(
                  'Min Flow Threshold',
                  style: GoogleFonts.poppins(fontSize: 8.5, color: leakageColor),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _RangeToggle(selected: selectedRange, onChanged: onRangeChanged, t: t),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.selected, required this.onChanged, required this.t});

  final String selected;
  final ValueChanged<String> onChanged;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final range in kAcChartRanges)
            InkWell(
              onTap: () => onChanged(range),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected == range ? t.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  range,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected == range ? Colors.white : t.txtMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 28, color: t.txtSubtle),
          const SizedBox(height: 8),
          Text('N/A', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: t.txtSubtle)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle, height: 1.4)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
      ],
    );
  }
}
