import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/settlement_models.dart';
import '../solar_settlement_theme.dart';
import 'settlement_card.dart';

/// The rates this period is settled at, the version they were published in,
/// and the windows they apply in.
///
/// Stated together because a rate without its window cannot be checked, and a
/// rate without its version cannot be traced. The window comes from Energy
/// System Settings rather than from anything typed here — one window for the
/// whole app, so a settlement and a demand chart can never disagree about when
/// peak begins.
class SettlementRateCard extends StatelessWidget {
  const SettlementRateCard({super.key, required this.rates});

  final SettlementRates rates;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final next = rates.nextEffectiveFrom;
    return SettlementCard(
      title: 'Settlement Rate (This Period)',
      icon: Icons.sell_outlined,
      trailing: rates.versionLabel.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.accent.withOpacity(0.35)),
              ),
              child: Text(rates.versionLabel,
                  style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.accent)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!rates.isConfigured)
            SettlementEmpty(
              height: 84,
              message: next != null
                  ? 'No settlement rate is in effect for this month. Pricing '
                      'starts ${SettlementFormat.dayLabel(next)}.'
                  : 'No settlement rate agreed for this period yet.',
            )
          else ...[
            _RateRow(
              color: SettlementColors.peak,
              label: 'Peak Hour',
              window: rates.peakLabel,
              rate: rates.peakRmPerKwh,
              decimals: rates.peakDecimals,
              factor: rates.peakFactor,
            ),
            const SizedBox(height: 10),
            _RateRow(
              color: SettlementColors.offPeak,
              label: 'Non-Peak Hour',
              window: rates.offPeakLabel,
              rate: rates.offPeakRmPerKwh,
              decimals: rates.offPeakDecimals,
              factor: rates.offPeakFactor,
            ),
            if (rates.effectiveFrom != null) ...[
              const SizedBox(height: 10),
              Text(
                  'Effective from ${SettlementFormat.dayLabel(rates.effectiveFrom!)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: p.mutedText)),
            ],
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: p.border),
          const SizedBox(height: 14),
          Text('TIME OF USE WINDOW',
              style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: p.mutedText)),
          const SizedBox(height: 8),
          Text(
            rates.peakLabel.isEmpty
                ? 'Peak hours are not configured. Set them in Energy System '
                    'Settings so every day can be split and priced.'
                : 'Peak ${rates.peakLabel}  ·  Non-Peak ${rates.offPeakLabel}',
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: p.subText, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Windows follow the Peak Hour ToU setting shared by every screen '
            'in the app.',
            style: GoogleFonts.poppins(fontSize: 10.5, color: p.mutedText),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.color,
    required this.label,
    required this.window,
    required this.rate,
    required this.decimals,
    required this.factor,
  });

  final Color color;
  final String label;
  final String window;
  final double rate;
  final int decimals;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final detail = [
      if (window.isNotEmpty) window,
      if (factor > 0) 'TNB × ${factor.toStringAsFixed(2)}',
    ].join('  ·  ');
    return Row(children: [
      Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.text)),
            if (detail.isNotEmpty)
              Text(detail,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: p.mutedText)),
          ],
        ),
      ),
      Text(SettlementFormat.rate(rate, decimals: decimals),
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.text,
              fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}
