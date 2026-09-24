import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';

const List<String> kAcChartRanges = ['24h', '7D', '30D'];

/// "Specific Energy Trend — vs 5-6 Benchmark Band" line chart: the actual
/// specific-energy series plus two flat dashed reference lines marking the
/// benchmark band.
class AcSpecificEnergyTrendCard extends StatelessWidget {
  const AcSpecificEnergyTrendCard({
    super.key,
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
    this.bandLow,
    this.bandHigh,
  });

  // Null when Total Power / Header Flow devices aren't mapped (or Specific
  // Energy otherwise has no live series yet) — the chart shows an empty
  // state instead of fabricating a series.
  final List<AcTrendPoint>? points;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  // Benchmark band — configured in Air Compressor Dashboard Setting, null
  // (band not drawn) when nothing's been saved yet.
  final double? bandLow;
  final double? bandHigh;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final lineColor = isLight ? t.primary : const Color(0xFF31ECFC);
    final benchmarkColor = t.txtMuted;

    final points = this.points;
    final hasData = points != null && points.isNotEmpty;
    final spots = hasData ? <FlSpot>[for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].specificEnergy)] : const <FlSpot>[];
    final low = bandLow;
    final high = bandHigh;
    final lowLine = low == null ? null : <FlSpot>[FlSpot(0, low), FlSpot((spots.length - 1).toDouble(), low)];
    final highLine = high == null ? null : <FlSpot>[FlSpot(0, high), FlSpot((spots.length - 1).toDouble(), high)];
    final bandLabel = (low != null && high != null) ? '${low.toStringAsFixed(1)}-${high.toStringAsFixed(1)}' : 'N/A';

    return DashboardCard(
      title: 'SPECIFIC ENERGY TREND',
      subtitle: 'kW/(m³/min) · vs $bandLabel benchmark band',
      trailing: Wrap(
        spacing: 10,
        children: [
          if (hasData) const _LegendDot(color: null, label: 'Specific Energy', isBenchmark: false),
          _LegendDot(color: null, label: 'Benchmark ($bandLabel)', isBenchmark: true),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: !hasData
                ? const _EmptyChartState(message: 'Map Total Power & Header Flow devices\nin Air Compressor Dashboard Setting')
                : LineChart(
                    LineChartData(
                      minY: 3.0,
                      maxY: 8.0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
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
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(1),
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
                                    s.y.toStringAsFixed(2),
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
                              colors: [lineColor.withOpacity(0.18), lineColor.withOpacity(0.0)],
                            ),
                          ),
                        ),
                        if (highLine != null)
                          LineChartBarData(
                            spots: highLine,
                            isCurved: false,
                            color: benchmarkColor,
                            barWidth: 1.4,
                            dashArray: const [6, 4],
                            dotData: const FlDotData(show: false),
                          ),
                        if (lowLine != null)
                          LineChartBarData(
                            spots: lowLine,
                            isCurved: false,
                            color: benchmarkColor,
                            barWidth: 1.4,
                            dashArray: const [6, 4],
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
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
  const _LegendDot({required this.color, required this.label, required this.isBenchmark});

  final Color? color;
  final String label;
  final bool isBenchmark;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dotColor = color ?? (isBenchmark ? t.txtMuted : (isLight ? t.primary : const Color(0xFF31ECFC)));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 2.4, color: dotColor),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
      ],
    );
  }
}
