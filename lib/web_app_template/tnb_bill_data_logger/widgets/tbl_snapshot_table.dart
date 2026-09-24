import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../../tnb_e3_bill_simulator/widgets/tnb_cyber_deco.dart';
import '../models/tnb_bill_log_entry.dart';

const _cCyan = Color(0xFF00E5FF);
const _cPeak = Color(0xFFFF6D00);
const _cOffPeak = Color(0xFF00BFA5);
const _cSolar = Color(0xFF34D399);

/// Newest-first daily snapshot log — same card chrome as
/// TnbBreakdownTable (cyan header row, corner brackets) so this reads as a
/// sibling of the Bill Simulator rather than a bolted-on page.
class TblSnapshotTable extends StatelessWidget {
  final List<TnbBillLogEntry> entries;
  final double peakRate;
  final double offPeakRate;
  final String peakStart;
  final String peakEnd;

  const TblSnapshotTable({
    super.key,
    required this.entries,
    required this.peakRate,
    required this.offPeakRate,
    this.peakStart = '08:00',
    this.peakEnd = '22:00',
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sw = MediaQuery.of(context).size.width;

    final pad = sw * 0.010;
    final fsTh = (sw * 0.0081).clamp(9.0, 12.0);
    final fsTd = (sw * 0.0088).clamp(10.0, 13.0);
    final radius = sw * 0.005;
    final borderW = sw * 0.0008;

    final rows = entries.reversed.toList();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(pad * 1.4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? [
                      theme.secondaryBackground.withOpacity(0.97),
                      theme.primaryBackground.withOpacity(0.97),
                    ]
                  : [
                      const Color(0xFF0E2040).withOpacity(0.92),
                      const Color(0xFF07101F).withOpacity(0.96),
                    ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _cCyan.withOpacity(0.40), width: borderW),
          ),
          child: rows.isEmpty
              ? Center(
                  child: Text('No daily snapshots yet', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 13)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group row — labels the PEAK IMPORT / OFF-PEAK IMPORT /
                    // SOLAR GEN column pairs below, matching the reference
                    // layout's two-tier header.
                    Row(
                      children: [
                        const Expanded(flex: 5, child: SizedBox()),
                        _groupTh(fsTh * 0.85, 'PEAK IMPORT · $peakStart–$peakEnd · @${peakRate.toStringAsFixed(3)}', flex: 4, color: _cPeak),
                        _groupTh(fsTh * 0.85, 'OFF-PEAK IMPORT · $peakEnd–$peakStart · @${offPeakRate.toStringAsFixed(3)}', flex: 4, color: _cOffPeak),
                        _groupTh(fsTh * 0.85, 'SOLAR GEN (KWH)', flex: 4, color: _cSolar),
                        const Expanded(flex: 6, child: SizedBox()),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: pad * 0.4),
                      child: Row(
                        children: [
                          _th(fsTh, 'DATE', flex: 3),
                          _th(fsTh, 'MTD\n(RM)', flex: 2, align: TextAlign.right),
                          _th(fsTh, 'PEAK\nKWH', flex: 2, align: TextAlign.right, color: _cPeak),
                          _th(fsTh, 'PEAK\nCOST (RM)', flex: 2, align: TextAlign.right, color: _cPeak),
                          _th(fsTh, 'OFF-PEAK\nKWH', flex: 2, align: TextAlign.right, color: _cOffPeak),
                          _th(fsTh, 'OFF-PEAK\nCOST (RM)', flex: 2, align: TextAlign.right, color: _cOffPeak),
                          _th(fsTh, 'SOLAR\nPEAK', flex: 2, align: TextAlign.right, color: _cSolar),
                          _th(fsTh, 'SOLAR\nOFF-PEAK', flex: 2, align: TextAlign.right, color: _cSolar),
                          _th(fsTh, 'DAY COST\n(RM)', flex: 2, align: TextAlign.right),
                          _th(fsTh, 'MD\n(KW)', flex: 2, align: TextAlign.right),
                          _th(fsTh, 'PF', flex: 2, align: TextAlign.right),
                        ],
                      ),
                    ),
                    Divider(color: _cCyan.withOpacity(0.20), height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final prev = i + 1 < rows.length ? rows[i + 1] : null;
                          return _buildRow(rows[i], prev, pad, fsTd, theme, isLight);
                        },
                      ),
                    ),
                  ],
                ),
        ),
        CyberpunkBrackets(color: _cCyan, armLength: sw * 0.0088 * 0.7),
      ],
    );
  }

  static final _thousandsRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  String _fmtThousands(double num) => num.toStringAsFixed(2).replaceAllMapped(_thousandsRegex, (m) => '${m[1]},');

  Widget _groupTh(double fs, String label, {required int flex, required Color color}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: color.withOpacity(0.65), fontSize: fs, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      ),
    );
  }

  Widget _th(double fs, String label, {int flex = 1, TextAlign align = TextAlign.left, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.poppins(
          color: (color ?? _cCyan).withOpacity(0.75),
          fontSize: fs,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildRow(
    TnbBillLogEntry e,
    TnbBillLogEntry? prev,
    double pad,
    double fsTd,
    FlutterFlowTheme theme,
    bool isLight,
  ) {
    final dayCost = e.dayCost(peakRate, offPeakRate);
    final prevCost = prev?.dayCost(peakRate, offPeakRate);
    final delta = (prevCost != null && prevCost > 0) ? ((dayCost - prevCost) / prevCost * 100) : null;
    final defText = isLight ? theme.txtPrimary : Colors.white;

    Color pfColor() {
      if (e.powerFactor <= 0) return theme.secondaryText;
      if (e.powerFactor >= 0.95) return const Color(0xFF34D399);
      if (e.powerFactor >= 0.85) return const Color(0xFFFBBF24);
      return const Color(0xFFF87171);
    }

    Widget cell(String text, {Color? color, int flex = 2, FontWeight? weight}) => Expanded(
          flex: flex,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(color: color ?? defText, fontSize: fsTd, fontWeight: weight ?? FontWeight.w500),
          ),
        );

    return Container(
      padding: EdgeInsets.symmetric(vertical: pad * 0.6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}',
              style: GoogleFonts.poppins(color: defText, fontSize: fsTd, fontWeight: FontWeight.w600),
            ),
          ),
          cell(_fmtThousands(e.mtdCost), color: defText, weight: FontWeight.w600),
          cell(e.peakKwh.toStringAsFixed(0), color: _cPeak.withOpacity(0.9)),
          cell(e.peakCost(peakRate).toStringAsFixed(2), color: _cPeak.withOpacity(0.9)),
          cell(e.offPeakKwh.toStringAsFixed(0), color: _cOffPeak.withOpacity(0.9)),
          cell(e.offPeakCost(offPeakRate).toStringAsFixed(2), color: _cOffPeak.withOpacity(0.9)),
          cell(e.solarPeakKwh > 0 ? e.solarPeakKwh.toStringAsFixed(0) : '–', color: _cSolar),
          cell(e.solarOffPeakKwh > 0 ? e.solarOffPeakKwh.toStringAsFixed(0) : '–', color: _cSolar),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(dayCost.toStringAsFixed(2), style: GoogleFonts.poppins(color: defText, fontSize: fsTd, fontWeight: FontWeight.w700)),
                if (delta != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    '${delta >= 0 ? '▲' : '▼'}${delta.abs().toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      color: delta >= 0 ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      fontSize: fsTd * 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          cell(e.maxDemandKw.toStringAsFixed(1), color: defText),
          cell(e.powerFactor > 0 ? e.powerFactor.toStringAsFixed(3) : '–', color: pfColor(), weight: FontWeight.w700),
        ],
      ),
    );
  }
}
