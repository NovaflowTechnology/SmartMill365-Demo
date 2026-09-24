import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/settlement_models.dart';
import '../solar_settlement_theme.dart';
import 'settlement_card.dart';

/// Each day's supplied energy, stacked into its two tariff windows.
///
/// Stacked rather than side by side because the day's total is the number
/// being settled; the split is how it was priced. Side-by-side bars would make
/// the eye compare peak against off-peak, which is not the question.
class DailySupplyChart extends StatelessWidget {
  const DailySupplyChart({super.key, required this.period});

  final SettlementPeriod period;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final days = period.days;
    final hasSplit = days.any((d) => d.suppliedKwh > 0);

    return SettlementCard(
      title: 'Daily Solar Supply to ${period.receiver.name.isEmpty ? 'receiver' : period.receiver.name}',
      icon: Icons.stacked_bar_chart,
      trailing: hasSplit ? _Legend(period: period) : null,
      child: !hasSplit
          ? SettlementEmpty(
              height: 210,
              message: days.isEmpty
                  ? 'No energy recorded for this period.'
                  : 'Waiting for the hourly records that split each day into '
                      'peak and non-peak.',
            )
          : SizedBox(height: 210, child: _bars(context, p, days)),
    );
  }

  Widget _bars(BuildContext context, SettlementPalette p, List<SettlementDay> days) {
    final maxY = days.fold<double>(0, (m, d) => d.suppliedKwh > m ? d.suppliedKwh : m);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final d = days[group.x];
              return BarTooltipItem(
                '${SettlementFormat.dayLabel(d.date)}\n',
                GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                children: [
                  TextSpan(
                    text: 'Peak  ${SettlementFormat.kwh(d.peakKwh)}\n'
                        'Non-Peak  ${SettlementFormat.kwh(d.offPeakKwh)}\n'
                        'Value  ${SettlementFormat.rm(d.totalValueRm)}',
                    style: GoogleFonts.poppins(
                        fontSize: 10.5, color: Colors.white70),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (v, _) => Text(
                SettlementFormat.number(v),
                style: GoogleFonts.poppins(fontSize: 9.5, color: p.mutedText),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                // Every other day on a month-long axis; all thirty labels
                // overlap into a grey smear.
                if (days.length > 16 && i.isOdd) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${days[i].date.day}',
                      style: GoogleFonts.poppins(
                          fontSize: 9.5, color: p.mutedText)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].suppliedKwh,
                  width: days.length > 20 ? 9 : 14,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3)),
                  rodStackItems: [
                    BarChartRodStackItem(
                        0, days[i].offPeakKwh, SettlementColors.offPeak),
                    BarChartRodStackItem(days[i].offPeakKwh,
                        days[i].suppliedKwh, SettlementColors.peak),
                  ],
                  color: SettlementColors.offPeak,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.period});

  final SettlementPeriod period;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style:
                    GoogleFonts.poppins(fontSize: 10.5, color: p.subText)),
          ],
        );
    final peakLabel = period.rates.peakLabel;
    final offLabel = period.rates.offPeakLabel;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      dot(SettlementColors.peak,
          peakLabel.isEmpty ? 'Peak' : 'Peak ($peakLabel)'),
      const SizedBox(width: 14),
      dot(SettlementColors.offPeak,
          offLabel.isEmpty ? 'Non-Peak' : 'Non-Peak ($offLabel)'),
    ]);
  }
}
