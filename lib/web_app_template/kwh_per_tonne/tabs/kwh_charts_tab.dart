import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../kwh_theme.dart';
import '../models/kwh_state_model.dart';
import '../widgets/kwh_shared_widgets.dart';

class KwhChartsTab extends StatelessWidget {
  final KwhStateModel data;

  const KwhChartsTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);
    final monthly = data.monthlyAgg(data.enriched);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // ── Trend line chart ───────────────────────────────────────────────
        kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 8, children: [
            Text('Monthly kWh / tonne trend', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
            Wrap(spacing: 16, runSpacing: 8, children: [
              kwhLineLegend(const Color(0xFF7FB3FF), 'kWh/t', isLight, theme),
              kwhDashLegend(KwhColors.amber, 'Warning', isLight, theme),
              kwhDashLegend(KwhColors.red,   'Critical', isLight, theme),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: monthly.isEmpty ? kwhEmpty(isLight, theme) : _trendChart(monthly, isLight, theme)),
        ])),
        const SizedBox(height: 16),

        // ── Bar chart ──────────────────────────────────────────────────────
        kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 8, children: [
            Text('Monthly kWh vs tonnes produced', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
            Wrap(spacing: 16, runSpacing: 8, children: [
              kwhLineLegend(const Color(0xFF5B8DEF), 'kWh (left)',    isLight, theme),
              kwhLineLegend(KwhColors.green,          'Tonnes (right)', isLight, theme),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: monthly.isEmpty ? kwhEmpty(isLight, theme) : _barChart(monthly, isLight, theme)),
        ])),
      ]),
    );
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  Widget _trendChart(List<Map<String, dynamic>> monthly, bool isLight, FlutterFlowTheme theme) {
    final spots = monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['kwhT'] as double)).toList();
    final allY  = spots.map((s) => s.y).toList();
    final warn  = data.targetKwh * (1 + data.warningPct  / 100);
    final crit  = data.targetKwh * (1 + data.criticalPct / 100);
    final minY  = (([...allY, data.targetKwh].reduce(min)) * 0.95).floorToDouble();
    final maxY  = (([...allY, crit]).reduce(max) * 1.05).ceilToDouble();

    return LineChart(LineChartData(
      minY: minY, maxY: maxY,
      lineBarsData: [LineChartBarData(
        spots: spots, color: const Color(0xFF7FB3FF), isCurved: true, barWidth: 2,
        dotData: FlDotData(show: spots.length <= 6,
          getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4,
            color: s.y > crit ? KwhColors.red : const Color(0xFF7FB3FF), strokeWidth: 1.5, strokeColor: Colors.white)),
      )],
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(y: warn, color: KwhColors.amber.withOpacity(0.7), strokeWidth: 1.5, dashArray: [6, 4]),
        HorizontalLine(y: crit, color: KwhColors.red.withOpacity(0.7),   strokeWidth: 1.5, dashArray: [6, 4]),
      ]),
      gridData: FlGridData(show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(color: (isLight ? theme.alternate : KwhColors.border).withOpacity(0.4), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, m) {
            final i = v.toInt();
            if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(monthly[i]['month'] as String, style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)));
          })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)))),
      ),
    ));
  }

  Widget _barChart(List<Map<String, dynamic>> monthly, bool isLight, FlutterFlowTheme theme) {
    final maxKwh    = monthly.map((e) => e['sumKwh']    as double).fold(0.0, max);
    final maxTonnes = monthly.map((e) => e['sumTonnes'] as double).fold(0.0, max);
    final factor    = maxTonnes > 0 && maxKwh > 0 ? maxKwh / maxTonnes : 1.0;
    final groups    = monthly.asMap().entries.map((e) => BarChartGroupData(x: e.key, barsSpace: 4, barRods: [
      BarChartRodData(toY: e.value['sumKwh']    as double,              color: const Color(0xFF5B8DEF), width: 20, borderRadius: BorderRadius.zero),
      BarChartRodData(toY: (e.value['sumTonnes'] as double) * factor,   color: KwhColors.green,         width: 20, borderRadius: BorderRadius.zero),
    ])).toList();

    return BarChart(BarChartData(
      maxY: maxKwh * 1.1, barGroups: groups, groupsSpace: 24,
      gridData: FlGridData(show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(color: (isLight ? theme.alternate : KwhColors.border).withOpacity(0.4), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38,
          getTitlesWidget: (v, m) => Text('${(factor > 0 ? v / factor : 0).toInt()}t', style: GoogleFonts.poppins(fontSize: 14, color: KwhColors.green.withOpacity(0.7))))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, m) {
            final i = v.toInt();
            if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(monthly[i]['month'] as String, style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)));
          })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
          getTitlesWidget: (v, m) => Text(v == 0 ? '0k' : '${(v / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)))),
      ),
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => KwhColors.cardBg,
        getTooltipItem: (g, gi, rod, ri) {
          if (gi >= monthly.length) return null;
          final d = monthly[gi];
          return ri == 0
              ? BarTooltipItem('${d['month']}\n${(d['sumKwh'] as double).toStringAsFixed(0)} kWh', GoogleFonts.poppins(color: Colors.white, fontSize: 16))
              : BarTooltipItem('${(d['sumTonnes'] as double).toStringAsFixed(1)}t',                  GoogleFonts.poppins(color: KwhColors.green, fontSize: 16));
        },
      )),
    ));
  }
}
