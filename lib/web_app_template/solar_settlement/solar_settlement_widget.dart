import 'package:flutter/material.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';
import 'package:smartmachine365/utils/tou_window.dart';

import 'logic/settlement_loader.dart';
import 'logic/settlement_pricing.dart';
import 'logic/settlement_setup_resolver.dart';
import 'models/settlement_config.dart';
import 'models/settlement_masters.dart';
import 'models/settlement_models.dart';
import 'services/settlement_config_service.dart';
import 'services/solar_settlement_service.dart';
import 'solar_settlement_theme.dart';
import 'widgets/block_selector.dart';
import 'widgets/daily_supply_chart.dart';
import 'widgets/settlement_footer_cards.dart';
import 'widgets/settlement_header.dart';
import 'widgets/settlement_kpi_row.dart';
import 'widgets/settlement_ledger_table.dart';
import 'widgets/settlement_rate_card.dart';

/// Solar Settlement — what one block generated, what it supplied to another,
/// and what that is worth under the time-of-use agreement between them.
///
/// This file only arranges the screen. The terms come from Solar Settlement
/// Setting through [SettlementConfigService]; every figure comes from
/// [SettlementLoader] and [SettlementCalculator]; every pixel comes from the
/// widgets in `widgets/`. Keeping the page this thin is what lets the
/// arithmetic be read — and argued with — without reading any Flutter.
class SolarSettlementWidget extends StatefulWidget {
  const SolarSettlementWidget({super.key});

  @override
  State<SolarSettlementWidget> createState() => _SolarSettlementWidgetState();
}

class _SolarSettlementWidgetState extends State<SolarSettlementWidget> {
  /// Only a Super Admin is shown the settings entry. The terms it edits decide
  /// what one block invoices another, so this is an authority question, not a
  /// preference — and the setting page checks again on its own.
  bool get _canEditSettings =>
      AppRoles.normalizeRole(AppStateNotifier.instance.userRole ?? '') ==
          AppRoles.superAdmin;

  SettlementConfig _config = const SettlementConfig();
  SettlementMasters _masters = const SettlementMasters();
  SettlementSetup _setup = const SettlementSetup(blocks: []);
  bool _setupLoaded = false;

  String _selectedId = '';
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  SettlementPeriod _period = SettlementPeriod.empty(DateTime.now());
  bool _loading = true;

  /// Guards against a slow month landing after the user has moved on to
  /// another one — the later request wins, not the later response.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _loadToken++;
    super.dispose();
  }

  Future<void> _init() async {
    final token = ++_loadToken;
    final results = await Future.wait<Object>([
      SettlementConfigService.load(),
      SettlementConfigService.loadMasters(),
    ]);
    if (!mounted || token != _loadToken) return;
    final config = (results[0] as ConfigLoadResult).config;
    final masters = results[1] as SettlementMasters;
    setState(() {
      _config = config;
      _masters = masters;
      _setup = SettlementSetupResolver.resolve(config, masters);
      _selectedId = config.supplierPlantId;
      _setupLoaded = true;
    });
    await _load();
  }

  bool get _showsAgreement =>
      _setup.hasAgreement && _selectedId == _setup.supplier!.id;

  SettlementBlock? get _selected {
    for (final b in _setup.blocks) {
      if (b.id == _selectedId) return b;
    }
    return null;
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    final supplier = _setup.supplier;
    final receiver = _setup.receiver;
    setState(() {
      _loading = true;
      if (!_showsAgreement) _period = SettlementPeriod.empty(_month);
    });
    if (!_showsAgreement || supplier == null || receiver == null) {
      setState(() => _loading = false);
      return;
    }

    // The window the Super Admin saved the settlement under, so every viewer
    // splits the day the same way. Before anything is saved, the viewer's own.
    final uid = AppStateNotifier.instance.uid ?? '';
    final touUid =
        _config.touSourceUid.isNotEmpty ? _config.touSourceUid : uid;
    final pre = await Future.wait<Object?>([
      SolarSettlementService.touWindow(touUid),
      SettlementConfigService.tnbRates(_setup.categoryId),
    ]);
    if (!mounted || token != _loadToken) return;
    final tou = pre[0] as TouWindow?;
    final tnb = pre[1] as TnbRates;

    final inputs = SettlementInputs(
      month: _month,
      supplier: supplier,
      receiver: receiver,
      splitMeterId: _config.basis == SettlementBasis.sendSide
          ? _config.sendMeterId
          : _config.receiveMeterId,
      receiveMeterId: _config.receiveMeterId,
      // The agreed prices are never guessed from TNB. With no version in
      // effect they stay zero and the screen says the month is unpriced.
      rates: SettlementPricing.ratesFor(_config, _month, tnb,
          plantName: _masters.plantName(_config.plantId)),
      tnb: tnb,
      tnbCategoryName: _setup.categoryName,
      tou: tou,
      missingFill: _config.missingFill,
    );

    final totals = await SettlementLoader.loadTotals(inputs);
    if (!mounted || token != _loadToken) return;
    setState(() {
      _period = totals;
      _loading = false;
    });

    // Second pass fills the ToU split day by day, so the ledger populates as
    // the hourly records arrive instead of the page waiting on all of them.
    await SettlementLoader.refineTouSplit(
      totals,
      inputs,
      isCancelled: () => !mounted || token != _loadToken,
      onProgress: (partial) {
        if (!mounted || token != _loadToken) return;
        setState(() => _period = partial);
      },
    );
  }

  void _onBlock(String id) {
    if (id == _selectedId) return;
    setState(() => _selectedId = id);
    _load();
  }

  void _onMonth(DateTime m) {
    if (m.year == _month.year && m.month == _month.month) return;
    setState(() => _month = DateTime(m.year, m.month, 1));
    _load();
  }

  void _openSettings() => context.goNamed('SolarSettlementSetting');

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    const none =
        SettlementBlock(id: '', name: '', solarMeterId: '', gridMeterId: '');

    return Scaffold(
      backgroundColor: p.page,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          // A fixed gutter eats a phone. It narrows with the viewport, but
          // never below 12 so content is not flush against the edge.
          final gutter =
              c.maxWidth < 620 ? 12.0 : (c.maxWidth < 1000 ? 18.0 : 24.0);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettlementHeader(
                  month: _month,
                  onPickMonth: _onMonth,
                  isLoading: _loading,
                  // Export is offered once there is something to export.
                  onExport: _period.isEmpty ? null : () {},
                  onSettings: _canEditSettings ? _openSettings : null,
                ),
                const SizedBox(height: 18),
                if (_setupLoaded && _setup.blocks.isEmpty)
                  _message(
                    p,
                    icon: Icons.solar_power_outlined,
                    title: 'Solar Settlement is not set up yet',
                    body: 'No blocks were found for the configured plant. '
                        'A Super Admin can choose the plant and the supply '
                        'agreement in Solar Settlement Setting.',
                  )
                else ...[
                  BlockSelector(
                    blocks: _setup.blocks,
                    selectedId: _selectedId,
                    onSelect: _onBlock,
                    supplier: _setup.supplier ?? none,
                    receiver: _setup.receiver ?? none,
                  ),
                  const SizedBox(height: 18),
                  if (!_setupLoaded)
                    const SizedBox(height: 240)
                  else if (!_showsAgreement)
                    _message(
                      p,
                      icon: Icons.handshake_outlined,
                      title:
                          'No supply agreement for ${_selected?.name ?? 'this block'}',
                      body: 'This block does not supply solar to another '
                          'block, so there is nothing to settle. Pick the '
                          'block that does.',
                    )
                  else ...[
                    SettlementKpiRow(period: _period, config: _config),
                    const SizedBox(height: 14),
                    _chartAndRates(),
                    const SizedBox(height: 14),
                    SettlementLedgerTable(
                      period: _period,
                      onExport: _period.isEmpty ? null : () {},
                    ),
                    const SizedBox(height: 14),
                    _footer(),
                  ],
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _chartAndRates() => LayoutBuilder(builder: (context, c) {
        final chart = DailySupplyChart(period: _period);
        final rates = SettlementRateCard(rates: _period.rates);
        // Below this width the chart would be too narrow to read a month in,
        // so the rate card moves underneath rather than squeezing it.
        if (c.maxWidth < 1100) {
          return Column(children: [
            chart,
            const SizedBox(height: 14),
            rates,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 7, child: chart),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: rates),
        ]);
      });

  Widget _footer() => LayoutBuilder(builder: (context, c) {
        final cards = [
          AllocationCheckCard(period: _period),
          ReconciliationCard(period: _period),
          GridCostComparisonCard(period: _period),
        ];
        if (c.maxWidth < 1100) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: 14),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      });

  Widget _message(
    SettlementPalette p, {
    required IconData icon,
    required String title,
    required String body,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: p.cardDecoration(),
        child: Column(children: [
          Icon(icon, size: 42, color: p.mutedText),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: p.text,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: p.mutedText,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ]),
      );
}
