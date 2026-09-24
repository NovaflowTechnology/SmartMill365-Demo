import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../models/tnb_e3_bill_simulator_model.dart';
import 'tnb_pf_surcharge_card.dart';
import 'tnb_cyber_deco.dart';

class TnbSummaryCards extends StatelessWidget {
  final String cycleEffectiveDate;
  final double pfValue;
  final double tier1Threshold;
  final double tier2Trigger;
  final bool   pfLoading;
  final bool   solarMapped;
  final double solarPeakKwh;
  final double solarOffPeakKwh;
  final double solarPeakAvoidedCost;
  final double solarOffPeakAvoidedCost;
  final String meterLabel;
  final String dataSource;

  const TnbSummaryCards({
    super.key,
    this.cycleEffectiveDate     = '',
    this.pfValue                = 0,
    this.tier1Threshold         = 0.98,
    this.tier2Trigger           = 0.96,
    this.pfLoading              = false,
    this.solarMapped            = false,
    this.solarPeakKwh           = 0,
    this.solarOffPeakKwh        = 0,
    this.solarPeakAvoidedCost   = 0,
    this.solarOffPeakAvoidedCost = 0,
    this.meterLabel             = '',
    this.dataSource             = '',
  });

  Map<String, String> _getBillingCycleInfo() {
    try {
      final start    = DateTime.parse(cycleEffectiveDate.trim());
      final today    = DateTime.now();
      final end      = DateTime(start.year, start.month + 1, 0);
      final daysLeft = end
          .difference(DateTime(today.year, today.month, today.day))
          .inDays + 1;

      const months = [
        '', 'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December',
      ];

      final startSuffix = _daySuffix(start.day);
      final endSuffix   = _daySuffix(end.day);
      final cycleLabel  =
          'Cycle: ${start.day}$startSuffix ${months[start.month]} '
          '- ${end.day}$endSuffix ${months[end.month]}';

      if (daysLeft <= 0) return {'value': 'Cycle Ended', 'subtitle': cycleLabel};
      return {'value': '$daysLeft Days Left', 'subtitle': cycleLabel};
    } catch (_) {
      return {'value': '— Days Left', 'subtitle': 'Set cycle date in Master Billing'};
    }
  }

  static final _thousandsRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  String _fmtNum(double num, {int decimals = 2}) {
    return num.toStringAsFixed(decimals).replaceAllMapped(
      _thousandsRegex,
      (m) => '${m[1]},',
    );
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:  return 'st';
      case 2:  return 'nd';
      case 3:  return 'rd';
      default: return 'th';
    }
  }

  Color _daysLeftColor(String value, {required bool isLight, required FlutterFlowTheme theme}) {
    final match = RegExp(r'^(\d+)').firstMatch(value);
    if (match == null) return isLight ? theme.txtPrimary : Colors.white;
    final days = int.tryParse(match.group(1) ?? '') ?? 99;
    if (days <= 3) return const Color(0xFFEF5350);
    if (days <= 7) return const Color(0xFFFFB300);
    return isLight ? theme.txtPrimary : Colors.white;
  }

  BoxDecoration _cardDeco(
    double sw,
    double radius,
    double borderW, {
    required Color glowColor,
    required bool isLight,
    required FlutterFlowTheme theme,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end:   Alignment.bottomRight,
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
      border: Border.all(color: glowColor.withOpacity(0.45), width: borderW),
      boxShadow: [
        BoxShadow(
          color:        glowColor.withOpacity(0.10),
          blurRadius:   sw * 0.012,
          spreadRadius: 1,
        ),
      ],
    );
  }

  Widget _sideCard({
    required Widget child,
    required Color glowColor,
    required double armLen,
    required BoxDecoration decoration,
    required double pad,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(pad * 1.2),
          decoration: decoration,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: child,
          ),
        ),
        CyberpunkBrackets(color: glowColor, armLength: armLen * 0.7),
      ],
    );
  }

  /// One half of the Solar Savings card's Peak/Off-Peak split — a tag chip
  /// (same PEAK/OFF-PEAK coloring as TnbBreakdownTable's usage rows) above
  /// the avoided-cost figure and its kWh subtitle.
  Widget _solarSplitColumn({
    required String label,
    required Color tagColor,
    required Color valueColor,
    required double avoidedCost,
    required double kwh,
    required double fsTag,
    required double fsValue,
    required double fsSub,
    required double pad,
    required FlutterFlowTheme theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: pad * 0.5, vertical: pad * 0.15),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(pad * 0.3),
            border: Border.all(color: tagColor.withOpacity(0.6)),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: tagColor,
              fontSize: fsTag,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(height: pad * 0.35),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '- RM ${_fmtNum(avoidedCost)}',
            style: GoogleFonts.poppins(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: fsValue,
            ),
          ),
        ),
        SizedBox(height: pad * 0.2),
        Text(
          '${_fmtNum(kwh, decimals: 0)} kWh',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: theme.secondaryText,
            fontSize: fsSub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme   = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sw      = MediaQuery.of(context).size.width;
    const cCyan   = Color(0xFF00E5FF);
    const cGreen  = Color(0xFF00C853);

    final cards      = TnbE3BillSimulatorModel.summaryCards;
    final cycleInfo  = _getBillingCycleInfo();
    final cycleValue = cycleInfo['value']!;
    final solarTotalAvoidedCost = solarPeakAvoidedCost + solarOffPeakAvoidedCost;
    final solarTotalKwh = solarPeakKwh + solarOffPeakKwh;

    final pad     = sw * 0.010;
    final fsTitle = sw * 0.0078;
    final fsValue = sw * 0.012;
    final fsSplitValue = sw * 0.0092;
    final fsSub   = sw * 0.0075;
    final fsTag   = sw * 0.0058;
    final radius  = sw * 0.005;
    final borderW = sw * 0.0008;
    final armLen  = sw * 0.0112;
    // Same PEAK/OFF-PEAK tag colors as TnbBreakdownTable's usage rows, so the
    // split reads as the same concept wherever it appears in this page.
    const cPeak    = Color(0xFFFF6D00);
    const cOffPeak = Color(0xFF00BFA5);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _sideCard(
            pad: pad,
            armLen: armLen,
            glowColor: cGreen,
            decoration: _cardDeco(sw, radius, borderW, glowColor: cGreen, isLight: isLight, theme: theme),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: sw * 0.004,
                      height: fsTitle * 1.3,
                      decoration: BoxDecoration(
                        color: cGreen,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: cGreen.withOpacity(0.7), blurRadius: pad * 0.5)],
                      ),
                    ),
                    SizedBox(width: pad * 0.5),
                    Expanded(
                      child: Text(
                        cards[0].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: theme.secondaryText,
                          fontSize: fsTitle,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: pad * 0.5),
                if (!solarMapped)
                  Text(
                    'No solar device mapped — set it in TNB Meter Setting',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: theme.secondaryText,
                      fontSize: fsSub,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _solarSplitColumn(
                          label: 'PEAK',
                          tagColor: cPeak,
                          valueColor: cGreen,
                          avoidedCost: solarPeakAvoidedCost,
                          kwh: solarPeakKwh,
                          fsTag: fsTag,
                          fsValue: fsSplitValue,
                          fsSub: fsSub,
                          pad: pad,
                          theme: theme,
                        ),
                      ),
                      Container(
                        width: borderW,
                        height: fsSplitValue * 2.6,
                        margin: EdgeInsets.symmetric(horizontal: pad * 0.6),
                        color: theme.alternate.withOpacity(0.4),
                      ),
                      Expanded(
                        child: _solarSplitColumn(
                          label: 'OFF-PEAK',
                          tagColor: cOffPeak,
                          valueColor: cGreen,
                          avoidedCost: solarOffPeakAvoidedCost,
                          kwh: solarOffPeakKwh,
                          fsTag: fsTag,
                          fsValue: fsSplitValue,
                          fsSub: fsSub,
                          pad: pad,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: pad * 0.6),
                  Divider(color: theme.alternate.withOpacity(0.25), height: 1),
                  SizedBox(height: pad * 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL AVOIDED',
                        style: GoogleFonts.poppins(
                          color: theme.secondaryText,
                          fontSize: fsSub,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '- RM ${_fmtNum(solarTotalAvoidedCost)} (${_fmtNum(solarTotalKwh, decimals: 0)} kWh)',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: cGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: fsSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: pad),
        Expanded(
          child: TnbPfSurchargeCard(
            pfValue:        pfValue,
            tier1Threshold: tier1Threshold,
            tier2Trigger:   tier2Trigger,
            isLoading:      pfLoading,
          ),
        ),
        SizedBox(height: pad),
        Expanded(
          child: _sideCard(
            pad: pad,
            armLen: armLen,
            glowColor: cCyan,
            decoration: _cardDeco(sw, radius, borderW, glowColor: cCyan, isLight: isLight, theme: theme),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: sw * 0.004,
                      height: fsTitle * 1.3,
                      decoration: BoxDecoration(
                        color: cCyan,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: cCyan.withOpacity(0.7), blurRadius: pad * 0.5)],
                      ),
                    ),
                    SizedBox(width: pad * 0.5),
                    Expanded(
                      child: Text(
                        cards[2].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: theme.secondaryText,
                          fontSize: fsTitle,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: pad * 0.5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    cycleValue,
                    style: GoogleFonts.poppins(
                      color: _daysLeftColor(cycleValue, isLight: isLight, theme: theme),
                      fontWeight: FontWeight.bold,
                      fontSize: fsValue,
                    ),
                  ),
                ),
                SizedBox(height: pad * 0.25),
                Text(
                  cycleInfo['subtitle']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: theme.secondaryText,
                    fontSize: fsSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
