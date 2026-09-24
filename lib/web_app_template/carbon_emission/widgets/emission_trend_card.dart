import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import 'carbon_flow_diagram.dart' show DashboardCard;

/// "Emission Trend" line chart with Actual / Target / Forecast series.
class EmissionTrendCard extends StatelessWidget {
  const EmissionTrendCard({
    super.key,
    required this.points,
    this.deviceId,
  });

  final List<EmissionTrendPoint> points;
  // Net Carbon Emission Device ID feeding this trend, set via Configure Dashboard.
  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final actualColor = t.success;
    final targetColor = isLight ? t.primary : const Color(0xFF31ECFC);
    final forecastColor = t.txtMuted;

    final actualSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        if (points[i].actual != null) FlSpot(i.toDouble(), points[i].actual!),
    ];
    final targetSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        if (points[i].target != null) FlSpot(i.toDouble(), points[i].target!),
    ];
    final forecastSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        if (points[i].forecast != null) FlSpot(i.toDouble(), points[i].forecast!),
    ];

    final maxY = [
      ...points.map((p) => p.actual ?? 0),
      ...points.map((p) => p.target ?? 0),
      ...points.map((p) => p.forecast ?? 0),
    ].reduce((a, b) => a > b ? a : b);

    return DashboardCard(
      title: 'EMISSION TREND',
      subtitle: 'tCO₂e · Jan – Dec${deviceId != null && deviceId!.isNotEmpty ? ' · Device: $deviceId' : ''}',
      trailing: Wrap(
        spacing: 10,
        children: [
          _LegendDot(color: actualColor, label: 'Actual'),
          _LegendDot(color: targetColor, label: 'Target', dashed: true),
          _LegendDot(color: forecastColor, label: 'Forecast', dashed: true),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.15,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY * 1.15) / 4,
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
                  reservedSize: 40,
                  interval: (maxY * 1.15) / 4,
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
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        points[i].month,
                        style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => isLight ? Colors.white : const Color(0xFF0D1A2E),
                tooltipBorder: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
                getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                  final label = s.barIndex == 0 ? 'Actual' : (s.barIndex == 1 ? 'Target' : 'Forecast');
                  final color = s.barIndex == 0 ? actualColor : (s.barIndex == 1 ? targetColor : forecastColor);
                  return LineTooltipItem(
                    '$label  ${s.y.toStringAsFixed(1)}',
                    GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: actualSpots,
                isCurved: true,
                curveSmoothness: 0.25,
                color: actualColor,
                barWidth: 2.4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(radius: 2.6, color: actualColor, strokeWidth: 0),
                ),
              ),
              LineChartBarData(
                spots: targetSpots,
                isCurved: false,
                color: targetColor,
                barWidth: 1.6,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: forecastSpots,
                isCurved: false,
                color: forecastColor,
                barWidth: 1.6,
                dashArray: [3, 3],
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 2.4, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
      ],
    );
  }
}
