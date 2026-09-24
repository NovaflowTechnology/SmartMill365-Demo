import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/settlement_pricing.dart';
import '../../models/settlement_config.dart';
import '../../models/settlement_masters.dart';
import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';
import 'setting_inputs.dart';
import 'setting_panel.dart';
import 'setting_table.dart';

/// The price the supplying block charges, per time-of-use tier. The only
/// place a settlement price is defined.
class SettlementRatePanel extends StatelessWidget {
  const SettlementRatePanel({
    super.key,
    required this.peak,
    required this.offPeak,
    required this.tnb,
    required this.peakWindow,
    required this.offPeakWindow,
    required this.supplierName,
    required this.receiverName,
    required this.onPeak,
    required this.onOffPeak,
    this.collapsed = false,
    this.onToggle,
  });

  final RateTier peak;
  final RateTier offPeak;
  final TnbRates tnb;
  final String peakWindow;
  final String offPeakWindow;
  final String supplierName;
  final String receiverName;
  final ValueChanged<RateTier> onPeak;
  final ValueChanged<RateTier> onOffPeak;
  final bool collapsed;
  final VoidCallback? onToggle;

  static String _plain(double v) =>
      v.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

  static double _round(double v, int decimals) =>
      double.parse(v.toStringAsFixed(decimals));

  @override
  Widget build(BuildContext context) {
    final pass = SettlementPricing.passesGuardrail(peak, offPeak, tnb);
    return SettingPanel(
      icon: Icons.payments_outlined,
      accent: SettlementColors.green,
      title: 'Settlement Rate',
      badge: const SourceTag(SourceKind.price),
      subtitle: 'Price $supplierName charges $receiverName — defined only here',
      collapsed: collapsed,
      onToggle: onToggle,
      footer: SettingNote(
        tone: pass ? NoteTone.green : NoteTone.amber,
        text: 'Guardrail: every tier should show green — $receiverName pays '
            'less than TNB. A red tier means $receiverName is worse off than '
            'buying from TNB in that window.',
      ),
      child: SettingTable(
        minWidth: 1000,
        columns: const [
          SettingColumn('Tier', flex: 15),
          SettingColumn('Pricing mode', flex: 14),
          SettingColumn('Settlement price', flex: 19),
          SettingColumn('Derived from', flex: 22),
          SettingColumn('vs TNB reference', flex: 20),
          SettingColumn('St', flex: 5, align: Alignment.center),
        ],
        rows: [
          _row(context, 'Peak', peakWindow, SettlementColors.peak, peak,
              tnb.peak, onPeak),
          _row(context, 'Non-Peak', offPeakWindow, SettlementColors.offPeak,
              offPeak, tnb.offPeak, onOffPeak),
        ],
      ),
    );
  }

  List<Widget> _row(
    BuildContext context,
    String title,
    String window,
    Color dot,
    RateTier tier,
    double tnbRate,
    ValueChanged<RateTier> onTier,
  ) {
    final fixed = tier.mode == PricingMode.fixed;
    final resolved = tier.resolve(tnbRate);
    final saving = SettlementPricing.savingVsTnb(tnbRate, resolved);

    final input = fixed
        ? RateInput(
            value: tier.price > 0 ? tier.price.toStringAsFixed(tier.decimals) : '',
            onChanged: (s) => onTier(tier.copyWith(price: double.tryParse(s) ?? 0)),
            onBlur: () =>
                onTier(tier.copyWith(price: _round(tier.price, tier.decimals))),
            decimals: tier.decimals,
            onDecimals: (n) => onTier(
                tier.copyWith(decimals: n, price: _round(tier.price, n))),
          )
        : RateInput(
            value: tier.factor > 0 ? _plain(tier.factor) : '',
            prefix: '×',
            hint: '0.90',
            onChanged: (s) =>
                onTier(tier.copyWith(factor: double.tryParse(s) ?? 0)),
            decimals: tier.decimals,
            onDecimals: (n) => onTier(tier.copyWith(decimals: n)),
          );

    final derived = fixed
        ? const QuietText('flat rate')
        : tnbRate > 0
            ? QuietText(
                'TNB RM ${tnbRate.toStringAsFixed(4)} × ${tier.factor > 0 ? _plain(tier.factor) : '?'}'
                ' = ${SettlementFormat.rate(resolved, decimals: tier.decimals)}')
            : const QuietText('needs a TNB rate — see TNB Reference Rate',
                color: SettlementColors.amber);

    final Widget vsTnb;
    if (saving == null) {
      vsTnb = QuietText(tnbRate > 0 ? 'enter a price' : 'no TNB reference');
    } else {
      final good = saving >= 0;
      vsTnb = Text(
        good
            ? '$receiverName saves RM ${saving.toStringAsFixed(4)}/kWh'
            : '$receiverName pays RM ${(-saving).toStringAsFixed(4)}/kWh more',
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: good ? SettlementColors.green : SettlementColors.red),
      );
    }

    final StatusDot status;
    if (resolved <= 0) {
      status = const StatusDot(StatusKind.warn, tooltip: 'No price yet');
    } else if (saving != null && saving < 0) {
      status = const StatusDot(StatusKind.error,
          tooltip: 'Charges more than TNB in this window');
    } else {
      status = const StatusDot(StatusKind.ok);
    }

    return [
      SettingNameCell(title, sub: window.isEmpty ? null : window, dot: dot),
      SettingDropdown<PricingMode>(
        value: tier.mode,
        options: const [
          SettingOption(PricingMode.fixed, 'Fixed'),
          SettingOption(PricingMode.tnbFactor, 'TNB × factor'),
        ],
        onChanged: (m) => onTier(tier.copyWith(mode: m)),
      ),
      input,
      derived,
      vsTnb,
      status,
    ];
  }
}
