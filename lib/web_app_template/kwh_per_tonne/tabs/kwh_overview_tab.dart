import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../../master_facility_setting/models/facility_data.dart';
import '../../sec_comparison_insight/sec_machine_card_widget.dart';
import '../kwh_theme.dart';
import '../models/kwh_state_model.dart';
import '../widgets/kwh_shared_widgets.dart';

class KwhOverviewTab extends StatelessWidget {
  final KwhStateModel data;
  final bool sortByVariance;
  final void Function(FacilityData) onMachineDetail;
  final VoidCallback onAddData;
  final VoidCallback onSecInsight;
  final VoidCallback onToggleSort;

  const KwhOverviewTab({
    super.key,
    required this.data,
    required this.sortByVariance,
    required this.onMachineDetail,
    required this.onAddData,
    required this.onSecInsight,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);

    final filtered  = data.filteredFacilities;
    final consumers = data.topConsumers;
    final maxSec    = consumers.isEmpty ? 1.0 : consumers.map(data.secFor).reduce(max);
    final critCount = filtered.where((f) => data.secFor(f) > data.targetKwh * (1 + data.criticalPct / 100)).length;
    final warnCount = filtered.where((f) {
      final s = data.secFor(f);
      return s > data.targetKwh * (1 + data.warningPct / 100) && s <= data.targetKwh * (1 + data.criticalPct / 100);
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── KPI cards ──────────────────────────────────────────────────────
        // 4 Expanded columns squeeze into unreadable slivers on a phone —
        // wrap into a 2-column grid below the tablet breakpoint instead.
        LayoutBuilder(builder: (context, constraints) {
          final kpiCards = [
            _kpiCard('FLEET AVG KWH/T', data.fleetAvgKwhT.toStringAsFixed(1), 'kWh/t', 'vs target ${data.targetKwh.toStringAsFixed(0)}', isLight, theme),
            _kpiCard('FLEET VARIANCE',
              '${data.fleetVariance >= 0 ? '+' : ''}${data.fleetVariance.toStringAsFixed(1)}%', '', 'avg deviation across fleet',
              isLight, theme,
              valueColor: data.fleetVariance > data.criticalPct ? KwhColors.red : data.fleetVariance > data.warningPct ? KwhColors.amber : KwhColors.green),
            _kpiCard('ON TARGET', '${data.onTargetCount}', '/${filtered.length}', 'machines within tolerance', isLight, theme, valueColor: KwhColors.green),
            _kpiCard('EST. ENERGY COST', '${data.currency} ${data.totalCost.toStringAsFixed(0)}', '',
              '@ ${data.currency} ${data.rate.toStringAsFixed(2)}/kWh', isLight, theme, valueColor: KwhColors.amber, bigVal: true),
          ];
          if (constraints.maxWidth < kBreakpointMedium) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final c in kpiCards) SizedBox(width: cardWidth, child: c)],
            );
          }
          return Row(children: [
            for (int i = 0; i < kpiCards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: kpiCards[i]),
            ],
          ]);
        }),
        const SizedBox(height: 16),

        // ── Middle row ─────────────────────────────────────────────────────
        Builder(builder: (context) {
          final topConsumersCard = kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              Text('TOP ENERGY CONSUMERS', style: kwhLblStyle(isLight, theme)),
              Text('sorted by Δ vs target', style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)),
            ]),
            const SizedBox(height: 12),
            ...consumers.take(8).map((f) {
              final sec   = data.secFor(f);
              final v     = data.targetKwh > 0 ? (sec - data.targetKwh) / data.targetKwh * 100 : 0.0;
              final ratio = maxSec > 0 ? sec / maxSec : 0.0;
              final label = f.meterName.isNotEmpty ? f.meterName : f.meterId;
              final vc    = v > data.criticalPct ? KwhColors.red : v > data.warningPct ? KwhColors.amber : KwhColors.green;
              return GestureDetector(
                onTap: () => onMachineDetail(f),
                child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                  SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70), overflow: TextOverflow.ellipsis)),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), minHeight: 8,
                      backgroundColor: isLight ? theme.alternate.withOpacity(0.3) : KwhColors.border,
                      valueColor: AlwaysStoppedAnimation(vc)))),
                  const SizedBox(width: 8),
                  Text('${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: vc)),
                ])),
              );
            }),
          ]));

          final fleetStatusCard = kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              Text('FLEET STATUS', style: kwhLblStyle(isLight, theme)),
              Text('${filtered.length} machines', style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              kwhStatusNum(data.onTargetCount.toString(), KwhColors.green),
              kwhStatusNum(warnCount.toString(),           KwhColors.amber),
              kwhStatusNum(critCount.toString(),           KwhColors.red),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: Row(children: [
              Expanded(flex: max(data.onTargetCount, 1), child: Container(height: 6, color: KwhColors.green)),
              Expanded(flex: max(warnCount, 1),           child: Container(height: 6, color: KwhColors.amber)),
              Expanded(flex: max(critCount, 1),           child: Container(height: 6, color: KwhColors.red)),
            ])),
            const SizedBox(height: 10),
            kwhDot(KwhColors.green, 'Healthy',         isLight, theme),
            const SizedBox(height: 4),
            kwhDot(KwhColors.amber, 'At risk',          isLight, theme),
            const SizedBox(height: 4),
            kwhDot(KwhColors.red,   'Action required',  isLight, theme),
          ]));

          final activeAlertsCard = kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              Text('ACTIVE ALERTS', style: kwhLblStyle(isLight, theme)),
              Text('${critCount + warnCount} open', style: GoogleFonts.poppins(fontSize: 14, color: KwhColors.red)),
            ]),
            const SizedBox(height: 10),
            ...consumers.where((f) => data.secFor(f) > data.targetKwh * (1 + data.warningPct / 100)).take(4).map((f) {
              final sec   = data.secFor(f);
              final v     = data.targetKwh > 0 ? (sec - data.targetKwh) / data.targetKwh * 100 : 0.0;
              final isCrit = v > data.criticalPct;
              final label  = f.meterName.isNotEmpty ? f.meterName : f.meterId;
              final vc     = isCrit ? KwhColors.red : KwhColors.amber;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: vc.withOpacity(0.08), border: Border.all(color: vc.withOpacity(0.3)), borderRadius: BorderRadius.circular(4)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 2, children: [
                    Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
                    Text(isCrit ? 'CRITICAL' : 'WARNING', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: vc)),
                  ]),
                  Text('+${v.toStringAsFixed(1)}% over target. ${isCrit ? "Immediate review needed." : "Investigate."}',
                    style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white54)),
                ]),
              );
            }),
          ]));

          return LayoutBuilder(builder: (context, constraints) {
            // Below the tablet breakpoint, three side-by-side cards (one of
            // them a fixed 240px) can't fit — stack them full-width instead.
            if (constraints.maxWidth < kBreakpointMedium) {
              return Column(children: [
                SizedBox(width: double.infinity, child: topConsumersCard),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: fleetStatusCard),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: activeAlertsCard),
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: topConsumersCard),
              const SizedBox(width: 12),
              SizedBox(width: 240, child: fleetStatusCard),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: activeAlertsCard),
            ]);
          });
        }),
        const SizedBox(height: 16),

        // ── Action row ─────────────────────────────────────────────────────
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
            kwhActionBtn('↓ Prioritize issues (sort by Δ%)', active: sortByVariance, color: KwhColors.amber, onTap: onToggleSort, isLight: isLight, theme: theme),
            kwhActionBtn('A → Z', active: !sortByVariance, onTap: onToggleSort, isLight: isLight, theme: theme),
            kwhActionBtn('⚡ SEC comparison', onTap: onSecInsight, isLight: isLight, theme: theme),
          ]),
          kwhBtn('+ Add production data', onTap: onAddData, bg: KwhColors.cyan, tc: Colors.black),
        ]),
        const SizedBox(height: 16),

        // ── Machine cards grid ─────────────────────────────────────────────
        LayoutBuilder(builder: (ctx, cons) {
          final cols  = max(1, (cons.maxWidth / 320).floor().clamp(1, 5));
          final gap   = (cons.maxWidth * 0.01).clamp(6.0, 14.0);
          final cardW = (cons.maxWidth - gap * (cols - 1)) / cols;
          final cardH = cardW * 0.95;
          return Wrap(spacing: gap, runSpacing: gap, children: filtered.asMap().entries.map((entry) {
            final i       = entry.key;
            final f       = entry.value;
            final id      = f.meterId.trim();
            final label   = f.meterName.isNotEmpty ? f.meterName : (id.isNotEmpty ? id : 'Device ${i + 1}');
            final agg     = data.polAgg[label];
            final tonnage = (agg?['sumTonnes'] as double?) ?? 0.0;
            return GestureDetector(
              onTap: () => onMachineDetail(f),
              child: SizedBox(width: cardW, height: cardH,
                child: SecMachineCardWidget(
                  machineName: label,
                  machineType: f.equipmentType,
                  meterId: id,
                  secValue: data.secFor(f),
                  // Per-machine target from Equipment Settings (energy module's
                  // "Target kWh / Tonne" field). 0 means the machine hasn't had
                  // one configured yet — the card itself renders a "not
                  // configured" state for that rather than silently borrowing
                  // the fleet-wide threshold.
                  targetSec: f.targetKwhPerTonne,
                  // No entries logged yet today for this machine in the
                  // kWh/Tonne Data Log — the card shows a "pending production
                  // data" notice in place of secValue's placeholder number.
                  hasProductionData: data.hasDataToday(f),
                  isLoading: id.isNotEmpty && !(data.facilityLoaded[id] ?? false),
                  onlineStatus: f.onlineStatus,
                  lastSeen: f.lastSeen,
                  cumulativeKwh: id.isNotEmpty ? (data.facilityEnergy[id] ?? 0.0) : 0.0,
                  cumulativeTonnage: tonnage,
                  warningPct: data.warningPct,
                  criticalPct: data.criticalPct,
                )),
            );
          }).toList());
        }),
      ]),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Widget _kpiCard(String label, String value, String unit, String sub, bool isLight, FlutterFlowTheme theme, {Color? valueColor, bool bigVal = false}) =>
    kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: kwhLblStyle(isLight, theme)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: GoogleFonts.poppins(fontSize: bigVal ? 22 : 28, fontWeight: FontWeight.w700, color: valueColor ?? (isLight ? theme.primaryText : Colors.white))),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 4),
            child: Text(unit, style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.secondaryText : Colors.white54))),
        ],
      ]),
      Text(sub, style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.secondaryText : Colors.white38)),
    ]));
}
