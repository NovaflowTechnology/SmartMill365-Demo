import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../kwh_theme.dart';
import '../models/kwh_state_model.dart';
import '../widgets/kwh_shared_widgets.dart';

class KwhSecInsightTab extends StatefulWidget {
  final KwhStateModel data;

  /// Pre-selected line A (set when navigating from the machine detail dialog).
  final String secLineA;

  const KwhSecInsightTab({super.key, required this.data, required this.secLineA});

  @override
  State<KwhSecInsightTab> createState() => _KwhSecInsightTabState();
}

class _KwhSecInsightTabState extends State<KwhSecInsightTab> {
  String _lineB = '';
  String _audience = 'CEO';

  KwhStateModel get d => widget.data;

  @override
  void initState() {
    super.initState();
    _initLineB();
  }

  @override
  void didUpdateWidget(KwhSecInsightTab old) {
    super.didUpdateWidget(old);
    _initLineB();
  }

  void _initLineB() {
    final mList = d.machineOptions.where((m) => m != 'All').toList();
    if (_lineB.isEmpty && mList.length > 1) {
      // Default to the second machine, but never the same as lineA.
      _lineB = mList.firstWhere((m) => m != widget.secLineA, orElse: () => mList.last);
    }
    if (!mList.contains(_lineB) && mList.isNotEmpty) {
      _lineB = mList.firstWhere((m) => m != widget.secLineA, orElse: () => mList.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    final mList = d.machineOptions.where((m) => m != 'All').toList();

    final lineA = widget.secLineA.isNotEmpty && mList.contains(widget.secLineA) ? widget.secLineA : (mList.isNotEmpty ? mList.first : '');
    final lineB = _lineB.isNotEmpty && mList.contains(_lineB)
        ? _lineB
        : (mList.length > 1
            ? mList[1]
            : mList.isNotEmpty
                ? mList.first
                : '');

    final aEnt = d.enriched.where((e) => e['machine'] == lineA).toList();
    final bEnt = d.enriched.where((e) => e['machine'] == lineB).toList();
    double sum(List l, String f) => l.fold(0.0, (x, e) => x + ((e[f] as num?)?.toDouble() ?? 0));
    final aKwh = sum(aEnt, 'kwh');
    final aTon = sum(aEnt, 'tonnes');
    final bKwh = sum(bEnt, 'kwh');
    final bTon = sum(bEnt, 'tonnes');
    final aKwhT = aTon > 0 ? aKwh / aTon : 0.0;
    final bKwhT = bTon > 0 ? bKwh / bTon : 0.0;
    final aVar = d.targetKwh > 0 ? (aKwhT - d.targetKwh) / d.targetKwh * 100 : 0.0;
    final bVar = d.targetKwh > 0 ? (bKwhT - d.targetKwh) / d.targetKwh * 100 : 0.0;
    final aCost = aKwh * d.rate;
    final bCost = bKwh * d.rate;
    final gap = (aCost - bCost).abs();
    final annGap = gap * 12;
    final saving = annGap * 0.8;
    final gapKwhT = (aKwhT - bKwhT).abs();
    final gapPct = max(aKwhT, bKwhT) > 0 ? gapKwhT / max(aKwhT, bKwhT) * 100 : 0.0;
    final lessEff = aKwhT > bKwhT ? lineA : lineB;
    final moreEff = aKwhT <= bKwhT ? lineA : lineB;

    final aM = d.monthlyAgg(aEnt);
    final bM = d.monthlyAgg(bEnt);
    final allMo = {...aM.map((e) => e['month'] as String), ...bM.map((e) => e['month'] as String)}.toList()..sort();
    final aCostMap = {for (final e in aM) e['month'] as String: (e['sumKwh'] as double) * d.rate};
    final bCostMap = {for (final e in bM) e['month'] as String: (e['sumKwh'] as double) * d.rate};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Audience selector ──────────────────────────────────────────────
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
          Text('SEC Comparison Insight · audience:', style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.secondaryText : Colors.white38)),
          Wrap(children: ['CEO'].map((a) => GestureDetector(
                onTap: () => setState(() => _audience = a),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _audience == a ? (isLight ? theme.primary : KwhColors.cyan.withOpacity(0.2)) : Colors.transparent,
                    border: Border.all(color: _audience == a ? (isLight ? theme.primary : KwhColors.cyan) : KwhColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(a,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _audience == a ? (isLight ? Colors.white : KwhColors.cyan) : (isLight ? theme.secondaryText : Colors.white54))),
                ),
              )).toList()),
        ]),
        const SizedBox(height: 12),

        // ── Line selectors ─────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LINE A', style: kwhLblStyle(isLight, theme)),
            const SizedBox(height: 4),
            kwhDrop(mList, lineA, (v) {/* lineA is controlled by parent via widget.secLineA */}, isLight, theme),
          ])),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LINE B', style: kwhLblStyle(isLight, theme)),
            const SizedBox(height: 4),
            kwhDrop(mList, lineB, (v) => setState(() => _lineB = v ?? ''), isLight, theme),
          ])),
        ]),
        const SizedBox(height: 16),

        // ── VS cards ───────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _secCard(lineA, 'A', aKwhT, aVar, const Color(0xFF5B8DEF), isLight, theme)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: KwhColors.amber, shape: BoxShape.circle),
                    child: Center(child: Text('VS', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)))),
                const SizedBox(height: 4),
                Text('${gapPct.toStringAsFixed(1)}% gap',
                    style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)),
              ])),
          Expanded(child: _secCard(lineB, 'B', bKwhT, bVar, KwhColors.green, isLight, theme)),
        ]),

        // ── Efficiency gap banner ──────────────────────────────────────────
        if (gapKwhT > 0) ...[
          const SizedBox(height: 12),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: KwhColors.amber.withOpacity(0.08), border: Border.all(color: KwhColors.amber.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: KwhColors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'EFFICIENCY GAP DETECTED: $lessEff consuming ${gapPct.toStringAsFixed(1)}% more energy than $moreEff. Gap: ${gapKwhT.toStringAsFixed(1)} kWh/t',
                        style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.primaryText : Colors.white70))),
              ])),
        ],
        const SizedBox(height: 16),

        // ── Cost stat boxes ────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: kwhStatBox(
                  '$lineA EST. COST', '${d.currency} ${aCost.toStringAsFixed(0)}', 'total energy cost', const Color(0xFF5B8DEF), isLight, theme)),
          const SizedBox(width: 12),
          Expanded(
              child:
                  kwhStatBox('$lineB EST. COST', '${d.currency} ${bCost.toStringAsFixed(0)}', 'total energy cost', KwhColors.green, isLight, theme)),
          const SizedBox(width: 12),
          Expanded(
              child: kwhStatBox('COST GAP', '${d.currency} ${gap.toStringAsFixed(0)}', 'annual est: ${d.currency} ${annGap.toStringAsFixed(0)}',
                  KwhColors.red, isLight, theme)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: kwhStatBox('$lineA VARIANCE', '${aVar >= 0 ? '+' : ''}${aVar.toStringAsFixed(1)}%', 'vs target',
                  aVar > d.criticalPct ? KwhColors.red : KwhColors.amber, isLight, theme)),
          const SizedBox(width: 12),
          Expanded(
              child: kwhStatBox('$lineB VARIANCE', '${bVar >= 0 ? '+' : ''}${bVar.toStringAsFixed(1)}%', 'vs target',
                  bVar > d.criticalPct ? KwhColors.red : KwhColors.amber, isLight, theme)),
          const SizedBox(width: 12),
          Expanded(
              child:
                  kwhStatBox('POTENTIAL SAVING', '${d.currency} ${saving.toStringAsFixed(0)}', 'if gap closed 80%', KwhColors.green, isLight, theme)),
        ]),
        const SizedBox(height: 16),

        // ── Monthly cost bar chart ─────────────────────────────────────────
        kwhCard(isLight, theme,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 6, children: [
                Text('Monthly cost — $lineA vs $lineB',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
                Wrap(spacing: 12, runSpacing: 6, children: [
                  kwhLineLegend(const Color(0xFF5B8DEF), 'Line A', isLight, theme),
                  kwhLineLegend(KwhColors.green, 'Line B', isLight, theme),
                ]),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                  height: 200,
                  child: allMo.isEmpty ? kwhEmpty(isLight, theme) : _costBarChart(allMo, aCostMap, bCostMap, lineA, lineB, isLight, theme)),
            ])),
        const SizedBox(height: 16),

        // ── Executive summary ──────────────────────────────────────────────
        kwhCard(isLight, theme,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📋 EXECUTIVE SUMMARY',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1, color: isLight ? theme.primaryText : Colors.white)),
              const SizedBox(height: 12),
              ..._execLines(lineA, lineB, lessEff, moreEff, aKwhT, bKwhT, gapKwhT, gapPct, gap, annGap, saving, aVar, bVar)
                  .asMap()
                  .entries
                  .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(['💰', '🎯', '📌'][e.key % 3], style: const TextStyle(fontSize: 19)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value, style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.primaryText : Colors.white70))),
                      ]))),
            ])),
      ]),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Widget _secCard(String label, String badge, double kwhT, double variance, Color color, bool isLight, FlutterFlowTheme theme) {
    final vc = variance > d.criticalPct
        ? KwhColors.red
        : variance > d.warningPct
            ? KwhColors.amber
            : KwhColors.green;
    final sl = variance > d.criticalPct
        ? 'CRITICAL'
        : variance > d.warningPct
            ? 'NEEDS IMPROVEMENT'
            : 'ON TARGET';
    return kwhCard(isLight, theme,
        borderColor: color.withOpacity(0.3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label.toUpperCase(),
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
            const SizedBox(width: 6),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                child: Text(badge, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
          ]),
          const SizedBox(height: 4),
          Text('KWH / TONNE', style: kwhLblStyle(isLight, theme)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(kwhT.toStringAsFixed(1),
                style: GoogleFonts.poppins(fontSize: 31, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
            Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text('kWh/t', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.secondaryText : Colors.white38))),
          ]),
          Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration:
                  BoxDecoration(color: vc.withOpacity(0.1), border: Border.all(color: vc.withOpacity(0.3)), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber_outlined, color: vc, size: 12),
                const SizedBox(width: 4),
                Text(sl, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: vc)),
              ])),
        ]));
  }

  Widget _costBarChart(
      List<String> months, Map<String, double> aMap, Map<String, double> bMap, String lineA, String lineB, bool isLight, FlutterFlowTheme theme) {
    final maxC = [...aMap.values, ...bMap.values, 1.0].reduce(max);
    final groups = months
        .asMap()
        .entries
        .map((e) => BarChartGroupData(x: e.key, barsSpace: 4, barRods: [
              BarChartRodData(toY: aMap[e.value] ?? 0, color: const Color(0xFF5B8DEF), width: 20, borderRadius: BorderRadius.zero),
              BarChartRodData(toY: bMap[e.value] ?? 0, color: KwhColors.green, width: 20, borderRadius: BorderRadius.zero),
            ]))
        .toList();

    return BarChart(BarChartData(
      maxY: maxC * 1.1,
      barGroups: groups,
      groupsSpace: 24,
      gridData: FlGridData(
          show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: KwhColors.border.withOpacity(0.4), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(months[i], style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)));
                })),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, m) => Text('${d.currency}${(v / 1000).toStringAsFixed(1)}k',
                    style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)))),
      ),
      barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => KwhColors.cardBg,
              getTooltipItem: (g, gi, rod, ri) {
                if (gi >= months.length) return null;
                return BarTooltipItem('${ri == 0 ? lineA : lineB}\n${d.currency} ${rod.toY.toStringAsFixed(0)}',
                    GoogleFonts.poppins(color: Colors.white, fontSize: 16));
              })),
    ));
  }

  List<String> _execLines(
    String lineA,
    String lineB,
    String lessEff,
    String moreEff,
    double aKwhT,
    double bKwhT,
    double gapKwhT,
    double gapPct,
    double gap,
    double annGap,
    double saving,
    double aVar,
    double bVar,
  ) {
    final lessKwhT = aKwhT > bKwhT ? aKwhT : bKwhT;
    final moreKwhT = aKwhT <= bKwhT ? aKwhT : bKwhT;
    switch (_audience) {
      case 'CEO':
        return [
          'Cost gap: ${d.currency} ${gap.toStringAsFixed(0)} (period). Annualised: ${d.currency} ${annGap.toStringAsFixed(0)}.',
          '$lessEff is less efficient. Closing 80% of the gap saves ${d.currency} ${saving.toStringAsFixed(0)}/year.',
          'Recommendation: Approve energy audit for $lessEff. ROI payback < 12 months.',
        ];
      case 'Manager':
        return [
          '$moreEff more efficient by ${gapKwhT.toStringAsFixed(2)} kWh/t (${gapPct.toStringAsFixed(1)}% gap).',
          'Schedule $lessEff maintenance this month to close the efficiency gap.',
          'Cost differential: ${d.currency} ${gap.toStringAsFixed(0)} — favour $moreEff in scheduling.',
        ];
      default:
        return [
          '$lessEff shows ${lessKwhT.toStringAsFixed(2)} kWh/t vs ${moreKwhT.toStringAsFixed(2)} on $moreEff.',
          'Gap: ${gapKwhT.toStringAsFixed(2)} kWh/t — check heating zones, drive eff., auxiliary loads.',
          'Recommend thermal audit + power factor correction on $lessEff.',
        ];
    }
  }
}
