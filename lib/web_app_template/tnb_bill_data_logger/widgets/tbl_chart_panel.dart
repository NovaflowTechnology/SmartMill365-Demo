import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../models/tnb_bill_log_entry.dart';

const _cPeak = Color(0xFFFF6D00);
const _cOffPeak = Color(0xFF00BFA5);
const _cPf = Color(0xFFFFC107);
const _cThreshold = Color(0xFFEF5350);

/// Stacked daily cost bars (off-peak base + peak top) with a synced PF trend
/// line underneath — two fl_chart widgets sharing the same day index on the
/// x-axis, mirroring how MD Insight Report pairs TrendBarChart/LineAreaChart
/// rather than a single dual-axis chart.
class TblChartPanel extends StatelessWidget {
  final List<TnbBillLogEntry> entries;
  final double peakRate;
  final double offPeakRate;
  final double tier1Threshold;

  const TblChartPanel({
    super.key,
    required this.entries,
    required this.peakRate,
    required this.offPeakRate,
    required this.tier1Threshold,
  });

  String? _labelFor(int index, int count) {
    if (entries.isEmpty || index < 0 || index >= entries.length) return null;
    final step = (count / 8).ceil().clamp(1, count);
    if (index % step != 0 && index != count - 1) return null;
    final d = entries[index].date;
    return '${d.day}/${d.month}';
  }

  static final _fmtAxisRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  /// Comma-grouped whole-number cost, e.g. 12345 → "12,345" — keeps the
  /// y-axis label a similar width regardless of magnitude; the FittedBox
  /// around it is still the real overflow guard for very large totals.
  String _fmtAxis(double v) => v.toInt().toString().replaceAllMapped(_fmtAxisRegex, (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text('No daily readings in this range', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 13)),
      );
    }

    final costs = entries.map((e) => e.dayCost(peakRate, offPeakRate)).toList();
    final rawMaxCost = costs.fold<double>(0, (m, v) => v > m ? v : m);
    final maxCost = (rawMaxCost * 1.2).clamp(10.0, double.infinity);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCost,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color.fromRGBO(0, 4, 51, 0.92),
                  tooltipBorder: BorderSide(color: theme.primary, width: 1),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final e = entries[group.x.toInt()];
                    return BarTooltipItem(
                      '${e.date.day}/${e.date.month}/${e.date.year}\n',
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: 'Peak: RM ${e.peakCost(peakRate).toStringAsFixed(2)} (${e.peakKwh.toStringAsFixed(0)} kWh)\n',
                          style: GoogleFonts.poppins(color: _cPeak, fontSize: 11.5),
                        ),
                        TextSpan(
                          text: 'Off-Peak: RM ${e.offPeakCost(offPeakRate).toStringAsFixed(2)} (${e.offPeakKwh.toStringAsFixed(0)} kWh)',
                          style: GoogleFonts.poppins(color: _cOffPeak, fontSize: 11.5),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxCost / 4,
                    reservedSize: 54,
                    getTitlesWidget: (v, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('RM${_fmtAxis(v)}', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10)),
                      ),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxCost / 4,
                getDrawingHorizontalLine: (v) => FlLine(color: theme.secondaryText.withOpacity(0.1), strokeWidth: 1, dashArray: const [5, 5]),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < entries.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: costs[i] <= 0 ? 0.01 : costs[i],
                        width: entries.length > 45 ? 4 : (entries.length > 20 ? 7 : 12),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                        rodStackItems: [
                          BarChartRodStackItem(0, entries[i].offPeakCost(offPeakRate), _cOffPeak.withOpacity(0.85)),
                          BarChartRodStackItem(
                            entries[i].offPeakCost(offPeakRate),
                            costs[i] <= 0 ? 0.01 : costs[i],
                            _cPeak.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 1,
          child: LineChart(
            LineChartData(
              minY: 0.80,
              maxY: 1.0,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color.fromRGBO(0, 4, 51, 0.92),
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            'PF ${s.y.toStringAsFixed(3)}',
                            GoogleFonts.poppins(color: _cPf, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ))
                      .toList(),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.1,
                    reservedSize: 54,
                    getTitlesWidget: (v, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(v.toStringAsFixed(2), style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10)),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final label = _labelFor(value.toInt(), entries.length);
                      if (label == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 9.5)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.1,
                getDrawingHorizontalLine: (v) => FlLine(color: theme.secondaryText.withOpacity(0.1), strokeWidth: 1, dashArray: const [5, 5]),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: tier1Threshold.clamp(0.80, 1.0),
                  color: _cThreshold.withOpacity(0.7),
                  strokeWidth: 1.5,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    style: GoogleFonts.poppins(color: _cThreshold, fontSize: 9, fontWeight: FontWeight.w600),
                    labelResolver: (line) => 'PF Tier 1 (${tier1Threshold.toStringAsFixed(2)})',
                  ),
                ),
              ]),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < entries.length; i++)
                      if (entries[i].powerFactor > 0) FlSpot(i.toDouble(), entries[i].powerFactor.clamp(0.80, 1.0))
                  ],
                  isCurved: false,
                  color: _cPf,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: entries.length <= 45,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 2.5, color: _cPf, strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
