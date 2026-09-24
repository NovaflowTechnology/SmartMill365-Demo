import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/settlement_config.dart';
import '../../models/settlement_masters.dart';
import '../../solar_settlement_theme.dart';
import 'device_dropdown.dart';
import 'setting_badges.dart';
import 'setting_inputs.dart';
import 'setting_panel.dart';
import 'setting_table.dart';

/// This month's figures for each hero card, as the draft would show them.
class KpiPreview {
  const KpiPreview({
    this.generation,
    this.supplied,
    this.peak,
    this.offPeak,
    this.total,
    this.loading = false,
  });

  final double? generation;
  final double? supplied;
  final double? peak;
  final double? offPeak;
  final double? total;
  final bool loading;
}

/// The five hero cards: what each is called, where its figure comes from, and
/// how precisely it is shown.
class KpiStripPanel extends StatelessWidget {
  const KpiStripPanel({
    super.key,
    required this.config,
    required this.masters,
    required this.receiverName,
    required this.preview,
    required this.touConfigured,
    required this.priced,
    required this.onChanged,
    this.collapsed = false,
    this.onToggle,
  });

  final SettlementConfig config;
  final SettlementMasters masters;
  final String receiverName;
  final KpiPreview preview;
  final bool touConfigured;
  final bool priced;
  final ValueChanged<SettlementConfig> onChanged;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final sendSide = config.basis == SettlementBasis.sendSide;
    final supplyMeter = sendSide ? config.sendMeterId : config.receiveMeterId;
    final noReadings = !preview.loading && (preview.generation ?? 0) <= 0;

    return SettingPanel(
      icon: Icons.view_week_outlined,
      accent: SettlementColors.amber,
      title: 'Top KPI Strip',
      subtitle: 'The five hero cards across the top of the dashboard',
      collapsed: collapsed,
      onToggle: onToggle,
      child: SettingTable(
        minWidth: 1120,
        columns: const [
          SettingColumn('Widget', flex: 13),
          SettingColumn('Display label', flex: 18),
          SettingColumn('Source', flex: 8),
          SettingColumn('Meter', flex: 20),
          SettingColumn('Field', flex: 15),
          SettingColumn('Unit', flex: 5),
          SettingColumn('Live preview', flex: 15),
          SettingColumn('St', flex: 5, align: Alignment.center),
        ],
        rows: [
          [
            const SettingNameCell('Solar Generation'),
            _label(KpiKeys.generation),
            const SourceTag(SourceKind.raw),
            DeviceDropdown(
              value: config.generationMeterId,
              devices: masters.devices,
              solarFirst: true,
              onChanged: (id) {
                // The send-side meter usually is the generation meter; keep
                // them together until someone deliberately separates them.
                final follow = config.sendMeterId == config.generationMeterId;
                onChanged(config.copyWith(
                  generationMeterId: id,
                  sendMeterId: follow ? id : null,
                ));
              },
            ),
            _locked('Daily energy'),
            _unit(context, 'kWh'),
            _preview(context, KpiKeys.generation, preview.generation),
            StatusDot(
              config.generationMeterId.isEmpty || noReadings
                  ? StatusKind.warn
                  : StatusKind.ok,
              tooltip: config.generationMeterId.isEmpty
                  ? 'Pick the solar meter'
                  : noReadings
                      ? 'No readings from this meter this month'
                      : null,
            ),
          ],
          [
            SettingNameCell('Solar Supplied',
                sub: sendSide ? 'send-side meter' : 'receive-side meter'),
            _label(KpiKeys.supplied),
            const SourceTag(SourceKind.referenced),
            LinkedText(supplyMeter.isEmpty
                ? 'Ledger rules · meter not mapped'
                : 'Ledger rules · $supplyMeter'),
            const QuietText('hourly energy, split by ToU'),
            _unit(context, 'kWh'),
            _preview(context, KpiKeys.supplied, preview.supplied),
            StatusDot(
              supplyMeter.isEmpty ? StatusKind.warn : StatusKind.linked,
              tooltip: 'Set in Ledger & Reconciliation Rules below',
            ),
          ],
          [
            const SettingNameCell('Peak Solar'),
            _label(KpiKeys.peak),
            const SourceTag(SourceKind.module),
            _locked('Settlement engine'),
            _locked('Peak kWh (ToU-classified)'),
            _unit(context, 'kWh'),
            _preview(context, KpiKeys.peak, preview.peak),
            _touStatus(),
          ],
          [
            const SettingNameCell('Non-Peak Solar'),
            _label(KpiKeys.offPeak),
            const SourceTag(SourceKind.module),
            _locked('Settlement engine'),
            _locked('Non-peak kWh (ToU-classified)'),
            _unit(context, 'kWh'),
            _preview(context, KpiKeys.offPeak, preview.offPeak),
            _touStatus(),
          ],
          [
            const SettingNameCell('Total Settlement Value'),
            _label(KpiKeys.total),
            const SourceTag(SourceKind.module),
            _locked('Settlement engine'),
            _locked('Σ (kWh × tier rate)'),
            _unit(context, 'RM'),
            _preview(context, KpiKeys.total, preview.total, money: true),
            StatusDot(priced ? StatusKind.ok : StatusKind.warn,
                tooltip: priced ? null : 'Enter both tier prices below'),
          ],
        ],
      ),
    );
  }

  Widget _touStatus() => StatusDot(
        touConfigured ? StatusKind.ok : StatusKind.warn,
        tooltip: touConfigured
            ? 'Split by the Peak Hour ToU window'
            : 'Peak Hour ToU is not configured',
      );

  Widget _label(String key) {
    final def = KpiKeys.defaultLabel(key, receiverName);
    final d = config.kpi(key);
    return SettingTextField(
      value: d.label.isEmpty ? def : d.label,
      defaultValue: def,
      onChanged: (t) => onChanged(config.withKpi(
          key, d.copyWith(label: t.trim() == def ? '' : t.trim()))),
    );
  }

  static Widget _locked(String label) => SettingDropdown<String>(
        value: label,
        options: [SettingOption(label, label)],
      );

  static Widget _unit(BuildContext context, String unit) {
    final p = SettlementPalette(context);
    return Text(unit,
        style: GoogleFonts.poppins(fontSize: 13, color: p.subText));
  }

  Widget _preview(BuildContext context, String key, double? v,
      {bool money = false}) {
    final p = SettlementPalette(context);
    final d = config.kpi(key);
    final text = preview.loading && (v == null || v <= 0)
        ? '…'
        : money
            ? SettlementFormat.rm(v != null && v > 0 ? v : null,
                decimals: d.decimals)
            : SettlementFormat.number(v, decimals: d.decimals);
    return Row(children: [
      Expanded(
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoMono(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
      ),
      const SizedBox(width: 6),
      DecimalsSelect(
        value: d.decimals,
        options: money ? const [0, 2, 3] : const [0, 1, 2],
        onChanged: (n) =>
            onChanged(config.withKpi(key, d.copyWith(decimals: n))),
      ),
    ]);
  }
}
