import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../models/tnb_e3_bill_simulator_model.dart';
import 'tnb_cyber_deco.dart';

class TnbBreakdownTable extends StatelessWidget {
  final List<TnbBreakdownItem> items;
  final String totalBeforeRebates;
  final String categoryName;

  const TnbBreakdownTable({
    super.key,
    required this.items,
    required this.totalBeforeRebates,
    this.categoryName = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sw = MediaQuery.of(context).size.width;
    const cCyan = Color(0xFF00E5FF);
    const cAmber = Color(0xFFFFC107);

    final pad = sw * 0.010;
    final fsTitle = sw * 0.0130;
    final fsTh = sw * 0.0081;
    final fsTd = sw * 0.0099;
    final fsMono = sw * 0.0088;
    final fsTot = sw * 0.0108;
    final fsTotV = sw * 0.0118;
    final fsBadge = sw * 0.0081;
    final radius = sw * 0.005;
    final borderW = sw * 0.0008;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          // No fixed/height: double.infinity here — the card must size to
          // fit ALL rows (see the plain Column below) so the PDF export,
          // which screenshots this widget via RepaintBoundary, captures the
          // full table instead of whatever a bounded viewport would clip.
          padding: EdgeInsets.all(pad * 1.8),
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
            border: Border.all(color: cCyan.withOpacity(0.40), width: borderW),
            boxShadow: [
              BoxShadow(
                color: cCyan.withOpacity(0.08),
                blurRadius: pad * 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ──
              Row(
                children: [
                  Container(
                    width: borderW * 5,
                    height: fsTitle * 1.3,
                    decoration: BoxDecoration(
                      color: cCyan,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                            color: cCyan.withOpacity(0.8),
                            blurRadius: pad * 0.6),
                      ],
                    ),
                  ),
                  SizedBox(width: pad * 0.6),
                  if (categoryName.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: pad * 0.6, vertical: pad * 0.25),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(radius * 0.5),
                        border:
                            Border.all(color: theme.primary.withOpacity(0.5)),
                      ),
                      child: Text(
                        categoryName,
                        style: GoogleFonts.poppins(
                          color: theme.primary,
                          fontSize: fsBadge,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: pad * 0.5),
                  ],
                  Flexible(
                    child: Text(
                      TnbE3BillSimulatorModel.breakdownTitle,
                      style: GoogleFonts.poppins(
                        color: isLight ? theme.txtPrimary : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: fsTitle,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: cCyan.withOpacity(0.5), blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: pad),

              // ── Table header ──
              Padding(
                padding: EdgeInsets.symmetric(vertical: pad * 0.5),
                child: Row(
                  children: [
                    _th(fsTh, 'DESCRIPTION', flex: 4),
                    _th(fsTh, 'USAGE /\nUNIT', flex: 2),
                    _th(fsTh, 'RATE (RM)', flex: 2),
                    _th(fsTh, 'AMOUNT\n(RM)', flex: 2, align: TextAlign.right),
                  ],
                ),
              ),
              Divider(color: cCyan.withOpacity(0.20), height: 1),

              // Plain Column (not a scrolling ListView) so every row is
              // actually laid out and painted — a ListView only lays out
              // whatever's currently scrolled into its viewport, which is
              // exactly what was getting silently dropped from the PDF.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map((item) => _buildRow(item, pad, fsTd, fsMono, sw,
                        FlutterFlowTheme.of(context)))
                    .toList(),
              ),

              Divider(
                  color: cCyan.withOpacity(0.30),
                  height: 1,
                  thickness: borderW * 2),
              SizedBox(height: pad * 0.7),

              // ── Total row ──
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Text(
                      'TOTAL BEFORE REBATES',
                      style: GoogleFonts.poppins(
                        color: isLight ? theme.txtPrimary : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: fsTot,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      totalBeforeRebates,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        color: cAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: fsTotV,
                        shadows: [
                          Shadow(color: cAmber.withOpacity(0.6), blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Corner brackets ──
        CyberpunkBrackets(
          color: cCyan,
          armLength: sw * 0.0088,
        ),
      ],
    );
  }

  Widget _th(double fs, String label,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.poppins(
          color: const Color(0xFF00E5FF).withOpacity(0.65),
          fontSize: fs,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildRow(TnbBreakdownItem item, double pad, double fsTd,
      double fsMono, double sw, FlutterFlowTheme theme) {
    final textColor =
        item.isPenalty ? const Color(0xFFE53935) : theme.primaryText;
    final tagR = sw * 0.003;
    final fsTag = sw * 0.0053;

    return Container(
      padding: EdgeInsets.symmetric(vertical: pad * 0.85),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.desc,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: fsTd,
                    fontWeight:
                        item.isPenalty ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                if (item.tag != null) ...[
                  SizedBox(height: pad * 0.3),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.004, vertical: sw * 0.0015),
                    decoration: BoxDecoration(
                      color: item.tagColor!.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(tagR),
                      border:
                          Border.all(color: item.tagColor!.withOpacity(0.6)),
                    ),
                    child: Text(
                      item.tag!,
                      style: GoogleFonts.poppins(
                        color: item.tagColor,
                        fontSize: fsTag,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Usage
          Expanded(
            flex: 2,
            child: Text(
              item.usage,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: fsTd,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Rate
          Expanded(
            flex: 2,
            child: item.isPenalty
                ? Text(
                    item.rate,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE53935),
                      fontSize: fsMono,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    item.rate,
                    style: GoogleFonts.poppins(
                      color: theme.secondaryText,
                      fontSize: fsTd,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Text(
              item.amount,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: item.isPenalty
                    ? const Color(0xFFE53935)
                    : theme.primaryText,
                fontSize: fsMono,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
