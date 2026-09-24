import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'tnb_cyber_deco.dart';

/// PF Surcharge card — data is provided by the parent (main widget already
/// fetches PF + billing config, no need for a second HTTP call here).
class TnbPfSurchargeCard extends StatelessWidget {
  final double pfValue;
  final double tier1Threshold;
  final double tier2Trigger;
  final bool   isLoading;

  const TnbPfSurchargeCard({
    super.key,
    this.pfValue        = 0,
    this.tier1Threshold = 0.98,
    this.tier2Trigger   = 0.96,
    this.isLoading      = false,
  });

  _PfStatus get _status {
    if (pfValue <= 0)                return _PfStatus.noData;
    if (pfValue >= tier1Threshold)   return _PfStatus.good;
    if (pfValue >= tier2Trigger)     return _PfStatus.tier1;
    return _PfStatus.tier2;
  }

  Color get _pfColor {
    switch (_status) {
      case _PfStatus.good:   return const Color(0xFF00E676);
      case _PfStatus.tier1:  return const Color(0xFFFFAB40);
      case _PfStatus.tier2:  return const Color(0xFFEF5350);
      case _PfStatus.noData: return const Color(0xFF90A4AE);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case _PfStatus.good:   return 'NORMAL — No Penalty';
      case _PfStatus.tier1:  return 'WARNING: Tier 1 Penalty Active';
      case _PfStatus.tier2:  return 'ACTION REQUIRED: Check Capacitor Banks';
      case _PfStatus.noData: return 'No Data Available';
    }
  }

  String get _statusTag {
    switch (_status) {
      case _PfStatus.good:   return 'NORMAL';
      case _PfStatus.tier1:  return 'TIER 1';
      case _PfStatus.tier2:  return 'TIER 2';
      case _PfStatus.noData: return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme   = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sw      = MediaQuery.of(context).size.width;
    final color   = _pfColor;

    final pad       = sw * 0.010;
    final fsHead    = sw * 0.0081;
    final fsBadge   = sw * 0.0073;
    final fsPf      = sw * 0.0180;
    final fsThresh  = sw * 0.0072;
    final fsStatus  = sw * 0.0081;
    final fsMeta    = sw * 0.0064;
    final radius    = sw * 0.005;
    final borderW   = sw * 0.0008;
    final barH      = sw * 0.0038;
    final iconSz    = sw * 0.007;
    final armLen    = sw * 0.0112;

    final barValue  = pfValue.clamp(0.0, 1.0);

    return Stack(
      children: [
        Container(
          width:   double.infinity,
          height:  double.infinity,
          padding: EdgeInsets.all(pad * 1.4),
          decoration: BoxDecoration(
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
            border: Border.all(color: color.withOpacity(0.55), width: borderW),
            boxShadow: [
              BoxShadow(
                color:        color.withOpacity(0.15),
                blurRadius:   pad * 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color:       color,
                    strokeWidth: 2,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width:  borderW * 5,
                              height: fsHead * 1.4,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: pad * 0.5)],
                              ),
                            ),
                            SizedBox(width: pad * 0.5),
                            Text(
                              'PF SURCHARGE RISK',
                              style: GoogleFonts.poppins(
                                color:        isLight ? theme.txtPrimary : Colors.white,
                                fontSize:     fsHead,
                                fontWeight:   FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: pad * 0.5, vertical: pad * 0.2),
                          decoration: BoxDecoration(
                            color:        color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(radius * 0.5),
                            border:       Border.all(color: color.withOpacity(0.5), width: borderW),
                          ),
                          child: Text(
                            _statusTag,
                            style: GoogleFonts.poppins(
                              color:        color,
                              fontSize:     fsBadge,
                              fontWeight:   FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: pad * 0.4),

                    // ── PF value ──
                    Text(
                      pfValue > 0 ? '${pfValue.toStringAsFixed(3)} PF' : '-- PF',
                      style: GoogleFonts.poppins(
                        color:      color,
                        fontWeight: FontWeight.bold,
                        fontSize:   fsPf,
                        shadows: [Shadow(color: color.withOpacity(0.7), blurRadius: 12)],
                      ),
                    ),
                    SizedBox(height: pad * 0.15),

                    // ── Threshold labels ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _threshLabel('T2', tier2Trigger, const Color(0xFFEF5350), fsThresh),
                        _threshLabel('T1', tier1Threshold, const Color(0xFFFFAB40), fsThresh),
                        Text(
                          'TARGET ≥ ${tier1Threshold.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color:        color.withOpacity(0.55),
                            fontSize:     fsMeta,
                            fontWeight:   FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: pad * 0.2),

                    // ── Segmented neon bar ──
                    _buildSegmentedBar(barValue, barH, borderW, radius),
                    SizedBox(height: pad * 0.3),

                    // ── Status message ──
                    Row(
                      children: [
                        Icon(
                          _status == _PfStatus.good
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: color,
                          size:  iconSz,
                        ),
                        SizedBox(width: pad * 0.4),
                        Expanded(
                          child: Text(
                            _statusLabel,
                            style: GoogleFonts.poppins(
                              color:        color,
                              fontSize:     fsStatus,
                              fontWeight:   FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
        ),

        CyberpunkBrackets(
          color:     color,
          armLength: armLen * 0.7,
        ),
      ],
    );
  }

  Widget _threshLabel(String tag, double val, Color color, double fs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color:  color,
            shape:  BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$tag: ${val.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            color:      color.withOpacity(0.85),
            fontSize:   fs,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedBar(double value, double barH, double borderW, double radius) {
    const int totalSegs = 20;
    final int filledSegs = (value * totalSegs).round().clamp(0, totalSegs);

    Color segColor(int i) {
      final segVal = (i + 1) / totalSegs;
      if (segVal <= tier2Trigger)   return const Color(0xFFEF5350);
      if (segVal <= tier1Threshold) return const Color(0xFFFFAB40);
      return const Color(0xFF00E676);
    }

    return Row(
      children: List.generate(totalSegs, (i) {
        final active = i < filledSegs;
        final c      = segColor(i);
        return Expanded(
          child: Container(
            height: barH,
            margin: EdgeInsets.symmetric(horizontal: barH * 0.15),
            decoration: BoxDecoration(
              color:        active ? c : c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(barH * 0.25),
              boxShadow: active
                  ? [BoxShadow(color: c.withOpacity(0.65), blurRadius: barH * 1.5)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

enum _PfStatus { good, tier1, tier2, noData }
