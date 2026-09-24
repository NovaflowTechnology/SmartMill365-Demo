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

/// The meters behind allocation and reconciliation, and what to do with a day
/// that has no hourly record.
class LedgerRulesPanel extends StatelessWidget {
  const LedgerRulesPanel({
    super.key,
    required this.config,
    required this.masters,
    required this.supplierName,
    required this.receiverName,
    required this.sentKwh,
    required this.receivedKwh,
    required this.loading,
    required this.onChanged,
    this.collapsed = false,
    this.onToggle,
  });

  final SettlementConfig config;
  final SettlementMasters masters;
  final String supplierName;
  final String receiverName;
  final double? sentKwh;
  final double? receivedKwh;
  final bool loading;
  final ValueChanged<SettlementConfig> onChanged;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final mapped = config.receiveMeterId.isNotEmpty;
    final diff = sentKwh != null && receivedKwh != null
        ? receivedKwh! - sentKwh!
        : null;

    Widget preview(String text) => Text(text,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.robotoMono(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text));

    String kwh(double? v) => loading && v == null ? '…' : SettlementFormat.kwh(v);

    return SettingPanel(
      icon: Icons.rule_rounded,
      accent: const Color(0xFFA78BFA),
      title: 'Ledger & Reconciliation Rules',
      subtitle: 'The send and receive meters behind Allocation and '
          'Reconciliation, gap-fill and line loss',
      collapsed: collapsed,
      onToggle: onToggle,
      child: SettingTable(
        minWidth: 960,
        columns: const [
          SettingColumn('Setting', flex: 20),
          SettingColumn('Value', flex: 30),
          SettingColumn('Detail', flex: 22),
          SettingColumn('Live preview', flex: 16),
          SettingColumn('St', flex: 6, align: Alignment.center),
        ],
        rows: [
          [
            SettingNameCell('Send-side meter',
                sub: 'Allocation · "Supplied to $receiverName"'),
            DeviceDropdown(
              value: config.sendMeterId,
              devices: masters.devices,
              solarFirst: true,
              onChanged: (id) => onChanged(config.copyWith(sendMeterId: id)),
            ),
            const QuietText('split hour by hour into peak and non-peak'),
            preview(kwh(sentKwh)),
            StatusDot(
                config.sendMeterId.isEmpty ? StatusKind.warn : StatusKind.ok),
          ],
          [
            const SettingNameCell('Receive-side meter',
                sub: 'Reconciliation check'),
            DeviceDropdown(
              value: config.receiveMeterId,
              devices: masters.devices,
              allowNone: true,
              onChanged: (id) => onChanged(config.copyWith(
                receiveMeterId: id,
                // A receive-side basis with no receive meter has nothing to
                // bill from, so unmapping it falls back to send-side.
                basis: id.isEmpty ? SettlementBasis.sendSide : null,
              )),
            ),
            QuietText(mapped
                ? 'compared with the send-side meter'
                : 'not mapped — reconciliation checks the ledger only'),
            preview(mapped ? kwh(receivedKwh) : '—'),
            StatusDot(mapped ? StatusKind.ok : StatusKind.warn,
                tooltip: mapped ? null : 'No receive-side meter mapped'),
          ],
          [
            const SettingNameCell('Missing-data fill'),
            SettingDropdown<MissingDataFill>(
              value: config.missingFill,
              options: const [
                SettingOption(MissingDataFill.pending,
                    'Flag as pending — not billed'),
                SettingOption(MissingDataFill.interpolate,
                    'Estimate from the month\'s ToU share (marked est.)'),
              ],
              onChanged: (f) => onChanged(config.copyWith(missingFill: f)),
            ),
            const QuietText('applies to days with no hourly record'),
            preview('—'),
            const StatusDot(StatusKind.ok),
          ],
          [
            const SettingNameCell('Line-loss attribution'),
            SettingDropdown<SettlementBasis>(
              value: config.basis,
              options: [
                SettingOption(SettlementBasis.sendSide,
                    'Bill on send-side (loss to $supplierName)'),
                SettingOption(SettlementBasis.receiveSide,
                    'Bill on receive-side (loss to $receiverName)'),
              ],
            ),
            const QuietText('follows the settlement basis'),
            preview(diff == null
                ? '—'
                : '${SettlementFormat.number(diff)} kWh diff'),
            const StatusDot(StatusKind.linked,
                tooltip: 'Change the basis in Supply Agreement'),
          ],
        ],
      ),
    );
  }
}
