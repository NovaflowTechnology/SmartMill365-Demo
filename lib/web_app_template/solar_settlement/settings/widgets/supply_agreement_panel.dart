import 'package:flutter/material.dart';

import '../../logic/settlement_setup_resolver.dart';
import '../../models/settlement_config.dart';
import '../../models/settlement_masters.dart';
import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';
import 'setting_inputs.dart';
import 'setting_panel.dart';
import 'setting_table.dart';

/// Who supplies whom, under which plant, on what cycle and basis.
class SupplyAgreementPanel extends StatelessWidget {
  const SupplyAgreementPanel({
    super.key,
    required this.config,
    required this.masters,
    required this.onChanged,
    this.collapsed = false,
    this.onToggle,
  });

  final SettlementConfig config;
  final SettlementMasters masters;
  final ValueChanged<SettlementConfig> onChanged;
  final bool collapsed;
  final VoidCallback? onToggle;

  void _pickPlant(String id) {
    final blocks = SettlementSetupResolver.blocksOf(id, masters);
    onChanged(config.copyWith(
      plantId: id,
      supplierPlantId: blocks.isNotEmpty ? blocks[0].id : '',
      receiverPlantId: blocks.length > 1 ? blocks[1].id : '',
      // The TNB link followed the old receiver; it follows the new one.
      tnbPlantId: '',
      tnbMeterId: '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final blocks = SettlementSetupResolver.blocksOf(config.plantId, masters);
    String name(String id) =>
        SettlementSetupResolver.blockName(id, config.plantId, masters);

    final blockOptions = [
      for (final b in blocks) SettingOption(b.id, name(b.id)),
      for (final id in {config.supplierPlantId, config.receiverPlantId})
        if (id.isNotEmpty && !blocks.any((b) => b.id == id))
          SettingOption(id, '${masters.plantName(id)} · outside this plant'),
    ];
    final plantOptions = [
      for (final p in masters.plants) SettingOption(p.id, p.name),
      if (masters.plant(config.plantId) == null && config.plantId.isNotEmpty)
        SettingOption(config.plantId, config.plantId),
    ];

    final sameParty = config.supplierPlantId.isNotEmpty &&
        config.supplierPlantId == config.receiverPlantId;
    final partiesSet =
        config.supplierPlantId.isNotEmpty && config.receiverPlantId.isNotEmpty;
    final supplier = name(config.supplierPlantId);
    final receiver = name(config.receiverPlantId);

    return SettingPanel(
      icon: Icons.swap_horiz_rounded,
      accent: SettlementColors.cyan,
      title: 'Supply Agreement',
      subtitle: 'Header scope: the plant, who supplies whom, cycle and basis',
      collapsed: collapsed,
      onToggle: onToggle,
      note: const SettingNote(
        top: true,
        text: 'Blocks come from the Plant → Block tree in General Factory '
            'Setting and TNB Meter Setting. This page does not create blocks.',
      ),
      child: SettingTable(
        minWidth: 820,
        columns: const [
          SettingColumn('Setting', flex: 20),
          SettingColumn('Value', flex: 46),
          SettingColumn('Detail', flex: 24),
          SettingColumn('St', flex: 7, align: Alignment.center),
        ],
        rows: [
          [
            const SettingNameCell('Plant', sub: 'the settlement sits under'),
            SettingDropdown<String>(
              value: config.plantId,
              options: plantOptions,
              onChanged: _pickPlant,
            ),
            const LinkedText('from General Factory Setting'),
            StatusDot(
              blocks.length >= 2 ? StatusKind.linked : StatusKind.warn,
              tooltip: blocks.length >= 2
                  ? '${blocks.length} blocks under this plant'
                  : 'This plant has fewer than two blocks',
            ),
          ],
          [
            const SettingNameCell('Supplier → Receiver'),
            Row(children: [
              Expanded(
                child: SettingDropdown<String>(
                  value: config.supplierPlantId,
                  options: blockOptions,
                  hint: 'Supplier',
                  onChanged: (id) =>
                      onChanged(config.copyWith(supplierPlantId: id)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: SettlementColors.cyan),
              ),
              Expanded(
                child: SettingDropdown<String>(
                  value: config.receiverPlantId,
                  options: blockOptions,
                  hint: 'Receiver',
                  onChanged: (id) => onChanged(
                      config.copyWith(receiverPlantId: id, tnbMeterId: '')),
                ),
              ),
            ]),
            sameParty
                ? const QuietText('a block cannot supply itself',
                    color: SettlementColors.red)
                : const LinkedText('from the block tree'),
            StatusDot(
              sameParty || !partiesSet ? StatusKind.error : StatusKind.ok,
              tooltip: sameParty
                  ? 'Supplier and receiver are the same block'
                  : partiesSet
                      ? null
                      : 'Pick both blocks',
            ),
          ],
          const [
            SettingNameCell('Settlement period'),
            SettingDropdown<String>(
              value: 'monthly',
              options: [
                SettingOption('monthly', 'Monthly'),
                SettingOption('quarterly', 'Quarterly — not available yet',
                    enabled: false),
              ],
              onChanged: _noop,
            ),
            QuietText('one ledger per calendar month'),
            StatusDot(StatusKind.ok),
          ],
          [
            const SettingNameCell('Settlement basis'),
            SettingDropdown<SettlementBasis>(
              value: config.basis,
              options: [
                SettingOption(SettlementBasis.sendSide,
                    'Send-side ($supplier send meter)'),
                SettingOption(
                  SettlementBasis.receiveSide,
                  config.receiveMeterId.isEmpty
                      ? 'Receive-side — map a receive meter first'
                      : 'Receive-side ($receiver inlet meter)',
                  enabled: config.receiveMeterId.isNotEmpty,
                ),
              ],
              onChanged: (b) => onChanged(config.copyWith(basis: b)),
            ),
            QuietText(config.basis == SettlementBasis.sendSide
                ? 'line loss falls to $supplier'
                : 'line loss falls to $receiver'),
            const StatusDot(StatusKind.ok),
          ],
        ],
      ),
    );
  }

  static void _noop(String _) {}
}
