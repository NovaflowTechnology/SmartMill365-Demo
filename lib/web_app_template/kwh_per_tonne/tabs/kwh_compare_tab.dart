import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../kwh_theme.dart';
import '../models/kwh_state_model.dart';
import '../widgets/kwh_shared_widgets.dart';

// Below the tablet breakpoint, the 8-column ranked list squeezes into
// unreadable slivers — switch to fixed column widths inside a
// horizontally-scrolling table instead.
const double _rankColRank = 40;
const double _rankColName = 150;
const double _rankColKwhT = 65;
const double _rankColBar  = 100;
const double _rankColKwh  = 70;
const double _rankColTon  = 70;
const double _rankColVar  = 75;
const double _rankColCost = 90;

class KwhCompareTab extends StatefulWidget {
  final KwhStateModel data;

  const KwhCompareTab({super.key, required this.data});

  @override
  State<KwhCompareTab> createState() => _KwhCompareTabState();
}

class _KwhCompareTabState extends State<KwhCompareTab> {
  String _mode = 'Machine';
  String _compareA = '';
  String _compareB = '';

  KwhStateModel get d => widget.data;

  @override
  void initState() {
    super.initState();
    _initSelections();
  }

  @override
  void didUpdateWidget(KwhCompareTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initSelections();
  }

  void _initSelections() {
    final items = _items;
    if (_compareA.isEmpty && items.isNotEmpty) _compareA = items[0];
    if (_compareB.isEmpty && items.length > 1)  _compareB = items[1];
    if (!items.contains(_compareA) && items.isNotEmpty) _compareA = items[0];
    if (!items.contains(_compareB) && items.length > 1) _compareB = items[1];
  }

  List<String> get _items => (_mode == 'Machine'
      ? d.machineOptions
      : d.typeOptions).where((v) => v != 'All').toList();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);
    final items   = _items;

    List<Map<String, dynamic>> forItem(String v) => _mode == 'Machine'
        ? d.enriched.where((e) => e['machine'] == v).toList()
        : d.enriched.where((e) => e['product'] == v).toList();

    final aEnt = forItem(_compareA); final bEnt = forItem(_compareB);
    double s(List l, String f) => l.fold(0.0, (x, e) => x + ((e[f] as num?)?.toDouble() ?? 0));
    final aKwh = s(aEnt, 'kwh'); final aTon = s(aEnt, 'tonnes');
    final bKwh = s(bEnt, 'kwh'); final bTon = s(bEnt, 'tonnes');
    final aKwhT = aTon > 0 ? aKwh / aTon : 0.0;
    final bKwhT = bTon > 0 ? bKwh / bTon : 0.0;
    final aVar  = d.targetKwh > 0 ? (aKwhT - d.targetKwh) / d.targetKwh * 100 : 0.0;
    final bVar  = d.targetKwh > 0 ? (bKwhT - d.targetKwh) / d.targetKwh * 100 : 0.0;

    final aM    = d.monthlyAgg(aEnt); final bM = d.monthlyAgg(bEnt);
    final allMo = {...aM.map((e) => e['month'] as String), ...bM.map((e) => e['month'] as String)}.toList()..sort();

    final ranked    = _mode == 'Machine' ? d.machineAggList() : d.productAggList();
    final maxKwhT   = ranked.isEmpty ? 1.0 : ranked.map((e) => e['kwhT'] as double).reduce(max);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Controls ───────────────────────────────────────────────────────
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 10, children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, runSpacing: 4, children: [
            Text('MODE', style: kwhLblStyle(isLight, theme)),
            const SizedBox(width: 8),
            kwhModeBtn('Machine', _mode, () => setState(() { _mode = 'Machine'; _compareA = ''; _compareB = ''; }), isLight, theme),
            kwhModeBtn('Product', _mode, () => setState(() { _mode = 'Product'; _compareA = ''; _compareB = ''; }), isLight, theme),
          ]),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
            Text('ITEM A', style: kwhLblStyle(isLight, theme)),
            kwhDrop(items, _compareA, (v) => setState(() => _compareA = v ?? ''), isLight, theme, width: 200),
          ]),
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: KwhColors.amber, shape: BoxShape.circle),
            child: Center(child: Text('VS', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)))),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
            Text('ITEM B', style: kwhLblStyle(isLight, theme)),
            kwhDrop(items, _compareB, (v) => setState(() => _compareB = v ?? ''), isLight, theme, width: 200),
          ]),
        ]),
        const SizedBox(height: 16),

        // ── Comparison cards ───────────────────────────────────────────────
        Row(children: [
          Expanded(child: _compareCard(_compareA, 'A', aKwhT, aKwh, aTon, aVar, aKwh * d.rate, const Color(0xFF5B8DEF), isLight, theme)),
          const SizedBox(width: 12),
          Expanded(child: _compareCard(_compareB, 'B', bKwhT, bKwh, bTon, bVar, bKwh * d.rate, KwhColors.green,         isLight, theme)),
        ]),
        const SizedBox(height: 12),

        // ── Insight bullets ────────────────────────────────────────────────
        kwhCard(isLight, theme, child: Column(children: [
          kwhBullet(aKwhT == bKwhT ? 'Equal efficiency.'
              : aKwhT < bKwhT ? '$_compareA more efficient by ${(bKwhT - aKwhT).toStringAsFixed(2)} kWh/t.'
              : '$_compareB more efficient by ${(aKwhT - bKwhT).toStringAsFixed(2)} kWh/t.',
              const Color(0xFF7FB3FF), isLight, theme),
          kwhBullet('kWh gap: ${(aKwh - bKwh).abs().toStringAsFixed(0)} | Cost gap: ${d.currency} ${((aKwh - bKwh).abs() * d.rate).toStringAsFixed(0)}', KwhColors.amber, isLight, theme),
          kwhBullet(aVar > d.warningPct && bVar > d.warningPct ? 'Both above target — review both.'
              : aVar > d.warningPct ? '$_compareA above target.'
              : bVar > d.warningPct ? '$_compareB above target.'
              : 'Both within target.', KwhColors.red, isLight, theme),
        ])),
        const SizedBox(height: 16),

        // ── Monthly trend ──────────────────────────────────────────────────
        kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 6, children: [
            Text('Monthly trend — A vs B', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
            Wrap(spacing: 12, runSpacing: 6, children: [
              kwhLineLegend(const Color(0xFF5B8DEF), _compareA, isLight, theme),
              kwhLineLegend(KwhColors.green, _compareB, isLight, theme),
              kwhDashLegend(KwhColors.amber, 'Target', isLight, theme),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: allMo.isEmpty ? kwhEmpty(isLight, theme) : _compareTrend(allMo, aM, bM, isLight, theme)),
        ])),
        const SizedBox(height: 16),

        // ── Ranked list ────────────────────────────────────────────────────
        kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('All ${_mode == 'Machine' ? 'machines' : 'products'} ranked by kWh/t',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < kBreakpointMedium;
            final table = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _rankHeader(isLight, theme, narrow),
              ...ranked.asMap().entries.map((e) => _rankRow(e.key + 1, e.value, maxKwhT, isLight, theme, narrow)),
            ]);
            if (!narrow) return table;
            const totalW = _rankColRank + _rankColName + _rankColKwhT + _rankColBar + _rankColKwh + _rankColTon + _rankColVar + _rankColCost;
            return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: totalW, child: table));
          }),
        ])),
      ]),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Widget _compareCard(String label, String badge, double kwhT, double kwh, double tonnes, double variance, double cost, Color color, bool isLight, FlutterFlowTheme theme) {
    final vc = variance > d.criticalPct ? KwhColors.red : variance > d.warningPct ? KwhColors.amber : KwhColors.green;
    return kwhCard(isLight, theme, borderColor: color.withOpacity(0.4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          child: Text(badge, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: kwhStatCol('KWH/T',     kwhT.toStringAsFixed(2),     isLight, theme, big: true)),
        Expanded(child: kwhStatCol('TOTAL KWH', kwh.toStringAsFixed(0),      isLight, theme)),
        Expanded(child: kwhStatCol('TONNES',    tonnes.toStringAsFixed(1),   isLight, theme)),
      ]),
      const SizedBox(height: 8),
      Text('${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}% variance', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: vc)),
      Text('Est. cost: ${d.currency} ${cost.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.secondaryText : Colors.white54)),
    ]));
  }

  Widget _compareTrend(List<String> months, List<Map> aM, List<Map> bM, bool isLight, FlutterFlowTheme theme) {
    Map<String, double> toMap(List<Map> ml) => {for (final e in ml) e['month'] as String: e['kwhT'] as double};
    final aMap   = toMap(aM); final bMap = toMap(bM);
    final aSpots = months.asMap().entries.map((e) => FlSpot(e.key.toDouble(), aMap[e.value] ?? 0)).toList();
    final bSpots = months.asMap().entries.map((e) => FlSpot(e.key.toDouble(), bMap[e.value] ?? 0)).toList();
    final allY   = [...aSpots.map((s) => s.y), ...bSpots.map((s) => s.y), d.targetKwh];
    final minY   = (allY.reduce(min) * 0.9).floorToDouble();
    final maxY   = (allY.reduce(max) * 1.1).ceilToDouble();

    return LineChart(LineChartData(minY: minY, maxY: maxY,
      lineBarsData: [
        LineChartBarData(spots: aSpots, color: const Color(0xFF5B8DEF), isCurved: true, barWidth: 2, dotData: const FlDotData(show: true)),
        LineChartBarData(spots: bSpots, color: KwhColors.green,         isCurved: true, barWidth: 2, dotData: const FlDotData(show: true)),
      ],
      extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: d.targetKwh, color: KwhColors.amber.withOpacity(0.6), strokeWidth: 1.5, dashArray: [6, 4])]),
      gridData: FlGridData(show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(color: (isLight ? theme.alternate : KwhColors.border).withOpacity(0.4), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, m) { final i = v.toInt(); if (i < 0 || i >= months.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i], style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38))); })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)))),
      ),
    ));
  }

  Widget _rankCell(bool narrow, double width, {required int flex, required Widget child}) =>
      narrow ? SizedBox(width: width, child: child) : Expanded(flex: flex, child: child);

  Widget _rankHeader(bool isLight, FlutterFlowTheme theme, bool narrow) {
    final labels  = ['#', _mode == 'Machine' ? 'MACHINE' : 'PRODUCT', 'KWH/T', '', 'KWH', 'TONNES', 'VARIANCE', 'EST. COST'];
    final widths  = [_rankColRank, _rankColName, _rankColKwhT, _rankColBar, _rankColKwh, _rankColTon, _rankColVar, _rankColCost];
    final flexes  = [1, 2, 1, 4, 1, 1, 1, 1];
    return Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: KwhColors.border))),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          _rankCell(narrow, widths[i], flex: flexes[i],
            child: Text(labels[i], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
      ]));
  }

  Widget _rankRow(int rank, Map<String, dynamic> e, double maxKwhT, bool isLight, FlutterFlowTheme theme, bool narrow) {
    final kwhT  = e['kwhT'] as double;
    final v     = e['variancePct'] as double;
    final vc    = v > d.criticalPct ? KwhColors.red : v > d.warningPct ? KwhColors.amber : KwhColors.green;
    final label = (e['machine'] ?? e['label'] ?? '') as String;
    final isA   = label == _compareA; final isB = label == _compareB;
    final barColor = isA ? const Color(0xFF5B8DEF) : isB ? KwhColors.green : (isLight ? theme.alternate : const Color(0xFF1E2D4D));
    return Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: KwhColors.border.withOpacity(0.5)))),
      child: Row(children: [
        _rankCell(narrow, _rankColRank, flex: 1, child: Text('#$rank', style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.secondaryText : Colors.white38))),
        _rankCell(narrow, _rankColName, flex: 2, child: Row(children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isLight ? theme.primaryText : Colors.white70))),
          if (isA) ...[const SizedBox(width: 4), kwhBadge('A', const Color(0xFF5B8DEF))],
          if (isB) ...[const SizedBox(width: 4), kwhBadge('B', KwhColors.green)],
        ])),
        _rankCell(narrow, _rankColKwhT, flex: 1, child: Text(kwhT.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: vc))),
        _rankCell(narrow, _rankColBar, flex: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: maxKwhT > 0 ? (kwhT / maxKwhT).clamp(0.0, 1.0) : 0, minHeight: 8,
            backgroundColor: isLight ? theme.alternate.withOpacity(0.2) : KwhColors.darkInput,
            valueColor: AlwaysStoppedAnimation(barColor)))),
        _rankCell(narrow, _rankColKwh, flex: 1, child: Text((e['sumKwh']    as double? ?? 0).toStringAsFixed(0), style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white54))),
        _rankCell(narrow, _rankColTon, flex: 1, child: Text((e['sumTonnes'] as double? ?? 0).toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white54))),
        _rankCell(narrow, _rankColVar, flex: 1, child: Text('${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%',     style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: vc))),
        _rankCell(narrow, _rankColCost, flex: 1, child: Text('${d.currency} ${(e['cost'] as double? ?? 0).toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white54))),
      ]));
  }
}
