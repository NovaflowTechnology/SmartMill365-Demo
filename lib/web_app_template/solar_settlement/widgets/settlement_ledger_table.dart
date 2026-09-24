import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/settlement_calculator.dart';
import '../models/settlement_models.dart';
import '../solar_settlement_theme.dart';
import 'settlement_card.dart';

/// Day by day, what was supplied and what it is worth.
///
/// This is the part anyone disputing an invoice will read, so every column is
/// traceable: energy, the rate it was priced at, and the product. Nothing is
/// rounded before it is multiplied, and the totals row comes from
/// [SettlementCalculator] rather than from adding up the rendered strings.
class SettlementLedgerTable extends StatelessWidget {
  const SettlementLedgerTable({
    super.key,
    required this.period,
    this.onExport,
  });

  final SettlementPeriod period;
  final VoidCallback? onExport;

  static const _flex = [16, 14, 13, 10, 9, 12, 10, 9, 12, 13];

  /// Below this the columns stop being readable and the table scrolls instead.
  static const double _minWidth = 980;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return SettlementCard(
      title: 'Daily Settlement Ledger',
      icon: Icons.receipt_long_outlined,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      trailing: onExport == null ? null : _exportLink(p),
      child: period.days.isEmpty
          ? const SettlementEmpty(
              message: 'No settlement lines for this period.')
          // Its own horizontal scroller: a ten-column ledger is wider than a
          // laptop, and the page itself must never scroll sideways.
          //
          // The width has to be pinned, not merely floored. A scroll view
          // hands its child unbounded width, and Expanded with nothing to
          // divide lets every row size to its own content — which is how a
          // table ends up with each line starting in a different place.
          : LayoutBuilder(builder: (context, c) {
              final width = c.maxWidth > _minWidth ? c.maxWidth : _minWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(children: [
                    _header(p),
                    ...period.days.asMap().entries.map((e) => _row(p, e.value, e.key)),
                    _totals(p),
                    if (!period.rates.isConfigured) _rateNotice(p),
                    if (period.days.any((d) => d.estimated))
                      _notice(
                          p,
                          'est. — the day has no hourly record, so its split '
                          'follows the rest of the month (Missing-data fill).'),
                  ]),
                ),
              );
            }),
    );
  }

  Widget _exportLink(SettlementPalette p) => InkWell(
        onTap: onExport,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.download_outlined, size: 14, color: p.accent),
            const SizedBox(width: 6),
            Text('Export',
                style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.accent)),
          ]),
        ),
      );

  /// Columns 3-5 are the peak window, 6-8 the non-peak one. A faint wash
  /// behind each group is what lets someone follow one tariff down thirty
  /// rows without counting columns.
  static Color? _groupTint(int i, SettlementPalette p) {
    final opacity = p.isLight ? 0.045 : 0.055;
    if (i >= 3 && i <= 5) return SettlementColors.peak.withOpacity(opacity);
    if (i >= 6 && i <= 8) return SettlementColors.offPeak.withOpacity(opacity);
    return null;
  }

  Widget _cell(SettlementPalette p, int i, Widget child,
          {Alignment align = Alignment.centerRight}) =>
      Expanded(
        flex: _flex[i],
        child: Container(
          alignment: align,
          color: _groupTint(i, p),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: child,
        ),
      );

  Widget _text(SettlementPalette p, String s,
          {bool bold = false, Color? color, double size = 13.5}) =>
      Text(
        s,
        style: GoogleFonts.poppins(
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? p.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        overflow: TextOverflow.ellipsis,
      );

  /// Says once why the money columns are empty, instead of leaving a page of
  /// dashes for the reader to interpret.
  Widget _rateNotice(SettlementPalette p) {
    final next = period.rates.nextEffectiveFrom;
    return _notice(
      p,
      next != null
          ? 'Energy is measured, but no settlement rate is in effect for this '
              'month — pricing starts ${SettlementFormat.dayLabel(next)}.'
          : 'Energy is measured, but no settlement rate has been agreed for '
              'this period, so nothing is priced yet.',
    );
  }

  Widget _notice(SettlementPalette p, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
        child: Row(children: [
          Icon(Icons.info_outline, size: 14, color: p.mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 11.5, color: p.mutedText),
            ),
          ),
        ]),
      );

  /// A rate cell. Nothing agreed yet reads as a dash, never as 0.00.
  Widget _rate(SettlementPalette p, double rate, int decimals) => _text(
        p,
        rate > 0 ? rate.toStringAsFixed(decimals) : '-',
        color: p.mutedText,
      );

  /// A money cell, shown only when there was a rate to price it with.
  Widget _value(SettlementPalette p, double value, double rate,
          {bool bold = false}) =>
      _text(
        p,
        rate > 0 ? SettlementFormat.number(value, decimals: 2) : '-',
        bold: bold,
        color: rate > 0 ? null : p.mutedText,
      );

  Widget _header(SettlementPalette p) {
    Widget h(int i, String s, {Alignment a = Alignment.centerRight}) => _cell(
          p,
          i,
          Text(
            s,
            textAlign:
                a == Alignment.centerLeft ? TextAlign.left : TextAlign.right,
            style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: p.mutedText),
          ),
          align: a,
        );
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(children: [
        h(0, 'DATE', a: Alignment.centerLeft),
        h(1, 'SOLAR GENERATED'),
        h(2, 'GRID IMPORT'),
        h(3, 'PEAK kWh'),
        h(4, 'RATE'),
        h(5, 'PEAK VALUE'),
        h(6, 'NON-PEAK kWh'),
        h(7, 'RATE'),
        h(8, 'NON-PEAK VALUE'),
        h(9, 'TOTAL VALUE'),
      ]),
    );
  }

  Widget _row(SettlementPalette p, SettlementDay d, int index) {
    // A day whose hourly record has not arrived cannot be priced, and saying
    // so is the difference between a pending line and a zero one.
    final pending = d.suppliedKwh <= 0 && d.solarGeneratedKwh > 0;
    return Container(
      decoration: BoxDecoration(
        // Alternating rows, faint enough to be felt rather than seen. A
        // thirty-line ledger read across ten columns is where the eye slips.
        color: index.isOdd
            ? (p.isLight
                ? Colors.black.withOpacity(0.02)
                : Colors.white.withOpacity(0.018))
            : null,
        border: Border(bottom: BorderSide(color: p.border.withOpacity(0.45))),
      ),
      child: Row(children: [
        _cell(
            p,
            0,
            Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                  child:
                      _text(p, SettlementFormat.dayLabel(d.date), bold: true)),
              if (d.estimated) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Estimated — no hourly record for this day',
                  child: _text(p, 'est.',
                      color: SettlementColors.amber, size: 11.5),
                ),
              ],
            ]),
            align: Alignment.centerLeft),
        _cell(p, 1, _text(p, SettlementFormat.number(d.solarGeneratedKwh))),
        _cell(
            p,
            2,
            _text(p, SettlementFormat.number(d.gridImportKwh),
                color: p.mutedText)),
        if (pending) ...[
          _cell(p, 3, _text(p, 'pending', color: p.mutedText, size: 11)),
          _cell(p, 4, _text(p, '-', color: p.mutedText)),
          _cell(p, 5, _text(p, '-', color: p.mutedText)),
          _cell(p, 6, _text(p, 'pending', color: p.mutedText, size: 11)),
          _cell(p, 7, _text(p, '-', color: p.mutedText)),
          _cell(p, 8, _text(p, '-', color: p.mutedText)),
          _cell(p, 9, _text(p, '-', color: p.mutedText)),
        ] else ...[
          _cell(p, 3, _text(p, SettlementFormat.number(d.peakKwh))),
          _cell(p, 4, _rate(p, d.peakRate, period.rates.peakDecimals)),
          // A value of 0.00 against a rate nobody has set reads as "this
          // energy was worth nothing". It was not priced at all, which is a
          // different statement and the one the dash makes.
          _cell(p, 5, _value(p, d.peakValueRm, d.peakRate)),
          _cell(p, 6, _text(p, SettlementFormat.number(d.offPeakKwh))),
          _cell(p, 7, _rate(p, d.offPeakRate, period.rates.offPeakDecimals)),
          _cell(p, 8, _value(p, d.offPeakValueRm, d.offPeakRate)),
          _cell(
              p,
              9,
              _value(p, d.totalValueRm,
                  d.peakRate > 0 || d.offPeakRate > 0 ? 1 : 0,
                  bold: true)),
        ],
      ]),
    );
  }

  Widget _totals(SettlementPalette p) {
    final s = period;
    return Container(
      decoration: BoxDecoration(
        color: p.accent.withOpacity(p.isLight ? 0.05 : 0.07),
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(children: [
        _cell(p, 0, _text(p, 'Total', bold: true), align: Alignment.centerLeft),
        _cell(
            p,
            1,
            _text(p,
                SettlementFormat.number(SettlementCalculator.solarGenerated(s)),
                bold: true)),
        _cell(
            p,
            2,
            _text(p, SettlementFormat.number(SettlementCalculator.gridImport(s)),
                color: p.mutedText)),
        _cell(
            p,
            3,
            _text(p, SettlementFormat.number(SettlementCalculator.peakKwh(s)),
                bold: true)),
        _cell(p, 4, _text(p, '', color: p.mutedText)),
        _cell(
            p,
            5,
            _value(p, SettlementCalculator.peakValueRm(s),
                period.rates.peakRmPerKwh,
                bold: true)),
        _cell(
            p,
            6,
            _text(p, SettlementFormat.number(SettlementCalculator.offPeakKwh(s)),
                bold: true)),
        _cell(p, 7, _text(p, '', color: p.mutedText)),
        _cell(
            p,
            8,
            _value(p, SettlementCalculator.offPeakValueRm(s),
                period.rates.offPeakRmPerKwh,
                bold: true)),
        _cell(
            p,
            9,
            _text(
                p,
                period.rates.isConfigured
                    ? SettlementFormat.number(
                        SettlementCalculator.totalValueRm(s),
                        decimals: 2)
                    : '-',
                bold: true,
                color: period.rates.isConfigured ? p.accent : p.mutedText)),
      ]),
    );
  }
}
