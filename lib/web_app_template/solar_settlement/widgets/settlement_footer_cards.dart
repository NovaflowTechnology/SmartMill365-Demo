import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/settlement_calculator.dart';
import '../models/settlement_models.dart';
import '../solar_settlement_theme.dart';
import 'settlement_card.dart';

/// Does the supplying block's generation add up?
///
/// Generation, what went to the other block, what was kept, and what is left
/// over. The leftover is the point: it should be zero, and showing it as a
/// signed figure means an over-allocation is as visible as a shortfall.
class AllocationCheckCard extends StatelessWidget {
  const AllocationCheckCard({super.key, required this.period});

  final SettlementPeriod period;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final a = SettlementCalculator.allocation(period);
    final generated = a.generated;
    final supplied = SettlementCalculator.supplied(period);
    final name = period.supplier.name.isEmpty ? 'supplier' : period.supplier.name;

    return SettlementCard(
      title: 'Solar Allocation Check ($name)',
      icon: Icons.wb_sunny_outlined,
      child: generated <= 0
          ? const SettlementEmpty(
              height: 96,
              message: 'No generation recorded for this period.')
          : Column(mainAxisSize: MainAxisSize.min, children: [
              _Line(label: 'Solar generation', value: generated),
              _Line(
                  label: 'Supplied to ${period.receiver.name.isEmpty ? 'receiver' : period.receiver.name}',
                  value: supplied),
              _Line(label: 'Self-use', value: period.selfUseKwh),
              _Line(
                  label: 'Unallocated',
                  value: period.unallocatedKwh,
                  emphasise: period.unallocatedKwh.abs() > 0),
              const SizedBox(height: 12),
              _Verdict(
                ok: SettlementCalculator.isReconciled(period),
                okText: 'Allocation verified',
                badText:
                    '${SettlementFormat.kwh(a.difference.abs())} unaccounted',
                palette: p,
              ),
            ]),
    );
  }
}

/// Do both sides of the agreement report the same energy?
///
/// One number from the supplying block, one from the receiving block, and the
/// gap between them. Stated side by side because a settlement is only as good
/// as the agreement between the two meters that measure it.
class ReconciliationCard extends StatelessWidget {
  const ReconciliationCard({super.key, required this.period});

  final SettlementPeriod period;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final supplied = SettlementCalculator.supplied(period);
    final mapped = period.receivedKwh != null;
    // Same ledger on both sides until a receiving meter is mapped.
    final received = period.receivedKwh ?? supplied;
    final diff = supplied - received;
    // Meters never agree to the kWh; the same tolerance as the allocation
    // check keeps ordinary metering noise from reading as a dispute.
    final tolerance = (supplied * 0.001).clamp(1.0, double.infinity);

    return SettlementCard(
      title: 'Settlement Reconciliation',
      icon: Icons.balance,
      child: supplied <= 0
          ? const SettlementEmpty(
              height: 96,
              message: 'Nothing to reconcile for this period yet.')
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: _Side(
                    title: period.supplier.name.isEmpty
                        ? 'Supplier'
                        : period.supplier.name,
                    caption: 'Solar supplied',
                    value: supplied,
                    palette: p,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('=',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: p.mutedText)),
                ),
                Expanded(
                  child: _Side(
                    title: period.receiver.name.isEmpty
                        ? 'Receiver'
                        : period.receiver.name,
                    caption: 'Solar received',
                    value: received,
                    palette: p,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Text('Difference  ${SettlementFormat.kwh(diff)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: p.mutedText)),
              const SizedBox(height: 10),
              _Verdict(
                ok: diff.abs() <= tolerance,
                okText: 'Reconciled',
                badText: 'Meters disagree by ${SettlementFormat.kwh(diff.abs())}',
                palette: p,
              ),
              const SizedBox(height: 10),
              Text(
                mapped
                    ? 'Send-side and receive-side meters as mapped in Solar '
                        'Settlement Setting. The whole month is compared, so a '
                        'day still pending on one side shows as a difference.'
                    : 'Both sides read the supplying block’s meter until a '
                        'receive-side meter is mapped, so this check confirms '
                        'the ledger rather than the two meters.',
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: p.mutedText, height: 1.45),
              ),
            ]),
    );
  }
}

/// What the receiving block would have paid the grid for the same energy.
class GridCostComparisonCard extends StatelessWidget {
  const GridCostComparisonCard({super.key, required this.period});

  final SettlementPeriod period;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final avoided = SettlementCalculator.costAvoidedRm(period);
    final name =
        period.receiver.name.isEmpty ? 'receiver' : period.receiver.name;

    return SettlementCard(
      title: 'Estimated Grid Cost Comparison ($name)',
      icon: Icons.compare_arrows,
      child: avoided == null
          ? const SettlementEmpty(
              height: 96,
              message:
                  'No TNB rate resolved for this block. Check its TNB meter, '
                  'the meter\'s tariff category, and Master Billing.')
          : Column(mainAxisSize: MainAxisSize.min, children: [
              _CompareRow(
                label: 'Peak',
                kwh: SettlementCalculator.peakKwh(period),
                rate: period.gridTariffPeakRm,
                palette: p,
              ),
              _CompareRow(
                label: 'Non-Peak',
                kwh: SettlementCalculator.offPeakKwh(period),
                rate: period.gridTariffOffPeakRm,
                palette: p,
              ),
              Divider(height: 22, color: p.border),
              _CompareRow(
                label: 'Grid equivalent',
                kwh: SettlementCalculator.supplied(period),
                rate: 0,
                total: SettlementCalculator.gridEquivalentRm(period),
                bold: true,
                palette: p,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: SettlementColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: SettlementColors.green.withOpacity(0.45)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text('Estimated grid cost avoided',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.text)),
                  ),
                  Text(SettlementFormat.rm(avoided),
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: SettlementColors.green)),
                ]),
              ),
              const SizedBox(height: 8),
              Text(
                'TNB rates from Master Billing'
                '${period.tnbCategoryName.isEmpty ? '' : ' · ${period.tnbCategoryName}'}'
                ', via the block\'s TNB meter. Actual invoices include demand '
                'and other charges, so treat this as an estimate.',
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: p.mutedText, height: 1.45),
              ),
            ]),
    );
  }
}

// ── shared pieces ───────────────────────────────────────────────────────────

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final double value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(fontSize: 13, color: p.subText)),
        ),
        Text(SettlementFormat.kwh(value),
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: emphasise ? SettlementColors.amber : p.text,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.title,
    required this.caption,
    required this.value,
    required this.palette,
  });

  final String title;
  final String caption;
  final double value;
  final SettlementPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text)),
      Text(caption,
          style: GoogleFonts.poppins(fontSize: 10.5, color: p.mutedText)),
      const SizedBox(height: 6),
      Text(SettlementFormat.kwh(value),
          style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: p.text,
              fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.kwh,
    required this.rate,
    required this.palette,
    this.total,
    this.bold = false,
  });

  final String label;
  final double kwh;
  final double rate;
  final double? total;
  final bool bold;
  final SettlementPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final value = total ?? kwh * rate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold ? p.text : p.subText)),
        ),
        Expanded(
          flex: 4,
          child: Text(SettlementFormat.number(kwh),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: p.subText,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        Expanded(
          flex: 3,
          child: Text(rate > 0 ? rate.toStringAsFixed(4) : '',
              textAlign: TextAlign.right,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: p.mutedText)),
        ),
        Expanded(
          flex: 4,
          child: Text(SettlementFormat.rm(value),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: p.text,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ]),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.ok,
    required this.okText,
    required this.badText,
    required this.palette,
  });

  final bool ok;
  final String okText;
  final String badText;
  final SettlementPalette palette;

  @override
  Widget build(BuildContext context) {
    final color = ok ? SettlementColors.green : SettlementColors.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(children: [
        Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(ok ? okText : badText,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ]),
    );
  }
}
