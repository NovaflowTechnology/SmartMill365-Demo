import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../../master_facility_setting/models/facility_data.dart';
import '../kwh_theme.dart';
import '../models/kwh_state_model.dart';

/// Shows the machine detail modal sheet.
/// Buttons navigate by calling [onNavigate] then [onSetMachine] / [onSetSecLine].
void showMachineDetailDialog({
  required BuildContext context,
  required bool isLight,
  required FlutterFlowTheme theme,
  required FacilityData facility,
  required KwhStateModel data,
  required void Function(int tab) onNavigate,
  required void Function(String machine) onSetFormMachine,
  required void Function(String machine) onSetSecLineA,
}) {
  final machineName = facility.meterName.isNotEmpty ? facility.meterName : facility.meterId;
  final agg         = data.polAgg[machineName];
  final sec         = data.secFor(facility);
  final totalKwh    = (agg?['sumKwh']    as double?) ?? 0.0;
  final totalTonnes = (agg?['sumTonnes'] as double?) ?? 0.0;
  final variancePct = data.targetKwh > 0 ? (sec - data.targetKwh) / data.targetKwh * 100 : 0.0;
  final cost        = totalKwh * data.rate;
  final varColor    = variancePct > data.criticalPct ? KwhColors.red
      : variancePct > data.warningPct ? KwhColors.amber
      : KwhColors.green;
  final statusLabel = data.statusLabel(variancePct);

  final allEntries = List<Map<String, dynamic>>.from(
    data.enriched.where((e) => e['machine']?.toString() == machineName),
  )..sort((a, b) => (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''));
  final recentEntries = allEntries.take(3).toList();

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: responsiveDialogWidth(ctx, 540),
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: isLight ? theme.secondaryBackground : const Color(0xFF0D1B3E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isLight ? theme.alternate : KwhColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(machineName: machineName, statusLabel: statusLabel, varColor: varColor, isLight: isLight, theme: theme),
            const SizedBox(height: 14),
            _StatsRow(
              labels: const ['KWH / TONNE', 'TOTAL KWH', 'TOTAL TONNES'],
              values: [sec.toStringAsFixed(2), totalKwh.toStringAsFixed(0), totalTonnes.toStringAsFixed(1)],
              colors: [varColor, isLight ? theme.primaryText : Colors.white, isLight ? theme.primaryText : Colors.white],
              isLight: isLight, theme: theme,
            ),
            const SizedBox(height: 8),
            _StatsRow(
              labels: const ['VARIANCE', 'EST. COST', 'ENTRIES'],
              values: ['${variancePct >= 0 ? '+' : ''}${variancePct.toStringAsFixed(1)}%', '${data.currency} ${cost.toStringAsFixed(0)}', allEntries.length.toString()],
              colors: [varColor, KwhColors.amber, isLight ? theme.primaryText : Colors.white],
              isLight: isLight, theme: theme,
            ),
            const SizedBox(height: 16),
            _RecentEntries(entries: recentEntries, data: data, isLight: isLight, theme: theme),
            const SizedBox(height: 16),
            _ActionButtons(
              machineName: machineName,
              onAddEntry: () { Navigator.pop(ctx); onSetFormMachine(machineName); onNavigate(KwhTabs.addData); },
              onSecInsight: () { Navigator.pop(ctx); onSetSecLineA(machineName); onNavigate(KwhTabs.secInsight); },
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String machineName;
  final String statusLabel;
  final Color varColor;
  final bool isLight;
  final FlutterFlowTheme theme;

  const _Header({required this.machineName, required this.statusLabel, required this.varColor, required this.isLight, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
    child: Row(children: [
      Text(machineName, style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: varColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: varColor.withOpacity(0.5)),
        ),
        child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: varColor)),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Icon(Icons.close, size: 20, color: isLight ? theme.secondaryText : Colors.white54),
      ),
    ]),
  );
}

class _StatsRow extends StatelessWidget {
  final List<String> labels;
  final List<String> values;
  final List<Color> colors;
  final bool isLight;
  final FlutterFlowTheme theme;

  const _StatsRow({required this.labels, required this.values, required this.colors, required this.isLight, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: List.generate(labels.length, (i) => _tile(i))),
  );

  Widget _tile(int i) => Expanded(
    child: Container(
      margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLight ? theme.primaryBackground : KwhColors.darkInput,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isLight ? theme.alternate : KwhColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(labels[i], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(values[i], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: colors[i])),
      ]),
    ),
  );
}

class _RecentEntries extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final KwhStateModel data;
  final bool isLight;
  final FlutterFlowTheme theme;

  const _RecentEntries({required this.entries, required this.data, required this.isLight, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RECENT ENTRIES', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: ['DATE', 'KWH', 'TONNES', 'KWH/T', 'COST', 'STATUS'].map((h) =>
        Expanded(child: Text(h, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8)))
      ).toList()),
      const SizedBox(height: 6),
      if (entries.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('No entries yet', style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.secondaryText : Colors.white38)),
        )
      else
        ...entries.map((e) => _entryRow(e)),
    ]),
  );

  Widget _entryRow(Map<String, dynamic> e) {
    final v  = e['variancePct'] as double;
    final vc = v > data.criticalPct ? KwhColors.red : v > data.warningPct ? KwhColors.amber : KwhColors.green;
    final sl = e['statusLabel'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(child: Text(e['date']?.toString() ?? '',                        style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        Expanded(child: Text((e['kwh']    as num?)?.toStringAsFixed(0) ?? '0',  style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        Expanded(child: Text((e['tonnes'] as num?)?.toStringAsFixed(1) ?? '0',  style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        Expanded(child: Text((e['kwhT']   as double).toStringAsFixed(2),        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: vc))),
        Expanded(child: Text('${data.currency} ${(e['cost'] as double).toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: vc.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
          child: Text(sl, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: vc)),
        )),
      ]),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String machineName;
  final VoidCallback onAddEntry;
  final VoidCallback onSecInsight;

  const _ActionButtons({required this.machineName, required this.onAddEntry, required this.onSecInsight});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: onAddEntry,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: KwhColors.cyan, borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text('+ Add entry for $machineName', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black))),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: onSecInsight,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: KwhColors.cyan), borderRadius: BorderRadius.circular(4), color: KwhColors.cyan.withOpacity(0.08)),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt, color: KwhColors.cyan, size: 14),
              const SizedBox(width: 4),
              Text('View SEC insight', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: KwhColors.cyan)),
            ])),
          ),
        ),
      ),
    ]),
  );
}
