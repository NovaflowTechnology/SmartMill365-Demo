import 'package:flutter/material.dart';

import '../logic/settlement_calculator.dart';
import '../models/settlement_config.dart';
import '../models/settlement_models.dart';
import '../solar_settlement_theme.dart';
import 'settlement_card.dart';

/// The period at a glance: what was generated, what was supplied, how it split
/// across the tariff windows, and what it comes to.
///
/// Every figure is taken from [SettlementCalculator] rather than summed here,
/// so a card and the ledger below it cannot disagree. Labels and decimal
/// places follow Solar Settlement Setting. A share reads as a dash when
/// nothing was supplied — "0.0%" of nothing looks like a finding and is not
/// one.
class SettlementKpiRow extends StatelessWidget {
  const SettlementKpiRow({
    super.key,
    required this.period,
    this.config = const SettlementConfig(),
  });

  final SettlementPeriod period;
  final SettlementConfig config;

  String _label(String key) {
    final custom = config.kpi(key).label;
    return custom.isEmpty
        ? KpiKeys.defaultLabel(key, period.receiver.name)
        : custom;
  }

  int _dp(String key) => config.kpi(key).decimals;

  @override
  Widget build(BuildContext context) {
    final p = period;
    final generated = SettlementCalculator.solarGenerated(p);
    final supplied = SettlementCalculator.supplied(p);
    final peakKwh = SettlementCalculator.peakKwh(p);
    final offPeakKwh = SettlementCalculator.offPeakKwh(p);
    final total = SettlementCalculator.totalValueRm(p);

    // One pass over the days for all five series. Building them inside each
    // card would walk the month five times for the same answer.
    final genSeries = <double>[];
    final supSeries = <double>[];
    final peakSeries = <double>[];
    final offSeries = <double>[];
    final valueSeries = <double>[];
    for (final d in p.days) {
      genSeries.add(d.solarGeneratedKwh);
      supSeries.add(d.suppliedKwh);
      peakSeries.add(d.peakKwh);
      offSeries.add(d.offPeakKwh);
      valueSeries.add(d.totalValueRm);
    }

    final cards = <Widget>[
      SettlementCard(
        accent: SettlementColors.amber,
        child: SettlementStat(
          label: _label(KpiKeys.generation),
          value: SettlementFormat.kwh(generated > 0 ? generated : null,
              decimals: _dp(KpiKeys.generation)),
          spark: genSeries,
          sub: p.supplier.name.isEmpty ? null : p.supplier.name,
          icon: Icons.wb_sunny_outlined,
          iconColor: SettlementColors.amber,
        ),
      ),
      SettlementCard(
        accent: SettlementColors.cyan,
        child: SettlementStat(
          label: _label(KpiKeys.supplied),
          value: SettlementFormat.kwh(supplied > 0 ? supplied : null,
              decimals: _dp(KpiKeys.supplied)),
          spark: supSeries,
          sharePct: SettlementCalculator.suppliedSharePct(p),
          sub: _shareSub(SettlementCalculator.suppliedSharePct(p)),
          icon: Icons.arrow_forward,
          iconColor: SettlementColors.cyan,
        ),
      ),
      SettlementCard(
        accent: SettlementColors.peak,
        child: SettlementStat(
          label: '${_label(KpiKeys.peak)}${_window(p.rates.peakLabel)}',
          value: SettlementFormat.kwh(peakKwh > 0 ? peakKwh : null,
              decimals: _dp(KpiKeys.peak)),
          spark: peakSeries,
          sharePct: SettlementCalculator.peakSharePct(p),
          sub: _shareSub(SettlementCalculator.peakSharePct(p)),
          icon: Icons.trending_up,
          iconColor: SettlementColors.peak,
        ),
      ),
      SettlementCard(
        accent: SettlementColors.offPeak,
        child: SettlementStat(
          label: '${_label(KpiKeys.offPeak)}${_window(p.rates.offPeakLabel)}',
          value: SettlementFormat.kwh(offPeakKwh > 0 ? offPeakKwh : null,
              decimals: _dp(KpiKeys.offPeak)),
          spark: offSeries,
          sharePct: SettlementCalculator.offPeakSharePct(p),
          sub: _shareSub(SettlementCalculator.offPeakSharePct(p)),
          icon: Icons.nightlight_outlined,
          iconColor: SettlementColors.offPeak,
        ),
      ),
      SettlementCard(
        accent: SettlementColors.green,
        child: SettlementStat(
          label: _label(KpiKeys.total),
          value: SettlementFormat.rm(total > 0 ? total : null,
              decimals: _dp(KpiKeys.total)),
          spark: valueSeries,
          sub: total > 0
              ? 'Peak ${SettlementFormat.rm(SettlementCalculator.peakValueRm(p))}'
                  '  ·  Non-Peak ${SettlementFormat.rm(SettlementCalculator.offPeakValueRm(p))}'
              : null,
          icon: Icons.savings_outlined,
          iconColor: SettlementColors.green,
        ),
      ),
    ];

    // Wrap, not a fixed Row: five cards do not fit a laptop width, and a
    // dashboard that scrolls sideways is a dashboard nobody reads the end of.
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth >= 1500
          ? 5
          : c.maxWidth >= 1150
              ? 3
              : c.maxWidth >= 720
                  ? 2
                  : 1;
      const gap = 12.0;
      final width = (c.maxWidth - gap * (perRow - 1)) / perRow;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ],
      );
    });
  }

  static String _window(String label) => label.isEmpty ? '' : ' ($label)';

  static String? _shareSub(double? pct) => pct == null
      ? null
      : "${SettlementFormat.pct(pct)} of the period's generation";
}
