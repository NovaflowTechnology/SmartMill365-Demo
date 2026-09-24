import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/settlement_setup_resolver.dart';
import '../../models/settlement_config.dart';
import '../../models/settlement_masters.dart';
import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';
import 'setting_inputs.dart';
import 'setting_panel.dart';
import 'setting_table.dart';

/// What TNB would have charged, followed link by link:
/// plant → its TNB meter → the meter's tariff category → that category's
/// peak and non-peak rates in Master Billing.
///
/// Nothing on this panel is typed except the bill reference. Each link is
/// edited in the module that owns it, which is why each one says where.
class TnbReferencePanel extends StatelessWidget {
  const TnbReferencePanel({
    super.key,
    required this.config,
    required this.masters,
    required this.tnb,
    required this.loading,
    required this.onChanged,
    required this.onOpenMeters,
    required this.onOpenBilling,
    this.collapsed = false,
    this.onToggle,
  });

  final SettlementConfig config;
  final SettlementMasters masters;
  final TnbRates tnb;
  final bool loading;
  final ValueChanged<SettlementConfig> onChanged;
  final VoidCallback onOpenMeters;
  final VoidCallback onOpenBilling;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final plantId = SettlementSetupResolver.tnbPlantFor(config);
    final meters = SettlementSetupResolver.metersOf(plantId, masters);
    final meter = SettlementSetupResolver.tnbMeterFor(config, masters);
    final category = SettlementSetupResolver.categoryNameFor(meter, masters);

    // Only plants that actually have a TNB meter can price a comparison.
    final plantIds = <String>{
      for (final m in masters.meters)
        if (m.isActive && m.plantId.isNotEmpty) m.plantId,
      plantId,
    };
    final plantOptions = [
      for (final id in plantIds)
        SettingOption(
          id,
          id == config.receiverPlantId
              ? '${masters.plantName(id)} · receiving block'
              : masters.plantName(id),
        ),
    ]..sort((a, b) => a.label.compareTo(b.label));

    String rateText(double v) => loading
        ? '…'
        : v > 0
            ? 'RM ${v.toStringAsFixed(4)} / kWh'
            : 'Not found';

    final sourceText = switch (tnb.source) {
      TnbRateSource.category => 'Master Billing · $category',
      TnbRateSource.electricityTariff =>
        'Master Billing · electricity tariff (shared by all categories)',
      TnbRateSource.none => 'No rate in Master Billing',
    };

    Widget rateCell(double v) => Text(rateText(v),
        style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: loading || v > 0 ? p.text : SettlementColors.amber));

    StatusDot rateStatus(double v) => loading
        ? const StatusDot(StatusKind.linked)
        : v > 0
            ? const StatusDot(StatusKind.linked)
            : const StatusDot(StatusKind.warn,
                tooltip: 'Set the rate in Master Billing Configuration');

    return SettingPanel(
      icon: Icons.receipt_long_outlined,
      accent: const Color(0xFF3B8EFF),
      title: 'TNB Reference Rate',
      badge: const SourceTag(SourceKind.referenced),
      subtitle: 'Feeds "Estimated Grid Cost Comparison" — comparison only, '
          'never the settlement price',
      collapsed: collapsed,
      onToggle: onToggle,
      note: const SettingNote(
        top: true,
        text: 'Linked, not typed: the plant decides the TNB meter, the meter '
            'decides the tariff category, and the category\'s peak and '
            'non-peak rates come from Master Billing Configuration.',
      ),
      footer: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border.withOpacity(0.6)))),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          SettingButton(
              label: 'Edit in TNB Meter Setting',
              icon: Icons.arrow_forward_rounded,
              onTap: onOpenMeters),
          SettingButton(
              label: 'Edit in Master Billing Config',
              icon: Icons.arrow_forward_rounded,
              onTap: onOpenBilling),
        ]),
      ),
      child: SettingTable(
        minWidth: 880,
        columns: const [
          SettingColumn('Step', flex: 20),
          SettingColumn('Value', flex: 40),
          SettingColumn('Source', flex: 28),
          SettingColumn('St', flex: 6, align: Alignment.center),
        ],
        rows: [
          [
            const SettingNameCell('Plant', sub: '1 · the block paying TNB'),
            SettingDropdown<String>(
              value: plantId,
              options: plantOptions,
              onChanged: (id) => onChanged(config.copyWith(
                // Stored empty while it matches the receiver, so it keeps
                // following the receiver if the agreement changes.
                tnbPlantId: id == config.receiverPlantId ? '' : id,
                tnbMeterId: '',
              )),
            ),
            QuietText(config.tnbPlantId.isEmpty
                ? 'follows the receiving block'
                : 'chosen here'),
            StatusDot(meters.isEmpty ? StatusKind.error : StatusKind.ok,
                tooltip: meters.isEmpty
                    ? 'No active TNB meter under this plant'
                    : null),
          ],
          [
            const SettingNameCell('TNB meter', sub: '2 · registered to the plant'),
            SettingDropdown<String>(
              value: meter?.id,
              hint: 'No active TNB meter',
              options: [
                for (final m in meters)
                  SettingOption(
                    m.id,
                    [
                      m.meterLabel.isNotEmpty ? m.meterLabel : m.meterCode,
                      if (m.influxDbTag.trim().isNotEmpty) m.influxDbTag.trim(),
                    ].join(' · '),
                  ),
              ],
              onChanged: meters.length > 1
                  ? (id) => onChanged(config.copyWith(tnbMeterId: id))
                  : null,
            ),
            const LinkedText('TNB Meter Setting'),
            StatusDot(meter == null ? StatusKind.error : StatusKind.linked),
          ],
          [
            const SettingNameCell('Tariff category', sub: '3 · set on the meter'),
            SettingDropdown<String>(
              value: category.isEmpty ? null : category,
              hint: meter == null ? '—' : 'No tariff category on this meter',
              options: [
                if (category.isNotEmpty) SettingOption(category, category),
              ],
            ),
            const LinkedText('TNB Meter Setting · Tariff Category Setup'),
            StatusDot(category.isEmpty ? StatusKind.warn : StatusKind.linked),
          ],
          [
            const SettingNameCell('TNB peak rate',
                sub: '4 · energy charge', dot: SettlementColors.peak),
            rateCell(tnb.peak),
            LinkedText(sourceText),
            rateStatus(tnb.peak),
          ],
          [
            const SettingNameCell('TNB non-peak rate',
                sub: '4 · energy charge', dot: SettlementColors.offPeak),
            rateCell(tnb.offPeak),
            LinkedText(sourceText),
            rateStatus(tnb.offPeak),
          ],
          [
            const SettingNameCell('Bill reference', sub: 'audit trail'),
            SettingTextField(
              value: config.billReference,
              hint: 'e.g. Block B TNB bill · Sep 2026',
              onChanged: (s) => onChanged(config.copyWith(billReference: s)),
            ),
            const QuietText('free text, kept with the settings'),
            StatusDot(config.billReference.trim().isEmpty
                ? StatusKind.warn
                : StatusKind.ok),
          ],
        ],
      ),
    );
  }
}
