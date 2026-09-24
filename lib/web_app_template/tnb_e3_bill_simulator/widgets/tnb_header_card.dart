import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../models/tnb_e3_bill_simulator_model.dart';
import 'tnb_cyber_deco.dart';

class TnbHeaderCard extends StatelessWidget {
  final TnbHeaderData? headerData;
  final VoidCallback? onRefresh;
  final String lastUpdated;

  /// Opens the browser's save dialog for a PDF snapshot of the current bill
  /// breakdown. Optional so callers that don't support it can omit the
  /// button — same pattern as MD Insight Report's ReportHeader.
  final VoidCallback? onDownload;
  final bool isGenerating;

  const TnbHeaderCard({
    super.key,
    this.headerData,
    this.onRefresh,
    this.lastUpdated = '',
    this.onDownload,
    this.isGenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final sw = screenWidth < 1000 ? 1000.0 : screenWidth;
    const cCyan = Color(0xFF00E5FF);
    const cGreen = Color(0xFF00E676);

    final catName = headerData?.categoryName ?? '';
    const title = 'BILL SIMULATOR';
    const subtitle = "Lot 237 - Enterprise Energy Management";
    final accrualLabel = headerData?.accrualLabel ?? 'CURRENT MONTH ACCRUAL (MTD)';
    final accrualAmt = headerData?.accrualAmount ?? 'RM 0.00';

    final pad = (sw * 0.010).clamp(8.0, 20.0);
    final fsTitle = (sw * 0.0130).clamp(13.0, 24.0);
    final fsSub = (sw * 0.0094).clamp(11.0, 18.0);
    final fsLabel = (sw * 0.0079).clamp(10.0, 14.0);
    final fsValue = (sw * 0.0180).clamp(18.0, 32.0);
    final fsBadge = (sw * 0.0081).clamp(10.0, 16.0);
    final fsMeta = (sw * 0.0064).clamp(9.0, 12.0);
    final radius = sw * 0.005;
    final borderW = (sw * 0.0008).clamp(0.5, 2.0);
    final iconSz = (sw * 0.0110).clamp(14.0, 20.0);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: pad * 1.8, vertical: pad * 1.2),
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
            border: Border.all(color: cCyan.withOpacity(0.45), width: borderW),
            boxShadow: [
              BoxShadow(
                color: cCyan.withOpacity(0.12),
                blurRadius: pad * 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title row ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: borderW * 5,
                          height: fsTitle * 1.4,
                          decoration: BoxDecoration(
                            color: cCyan,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(color: cCyan.withOpacity(0.8), blurRadius: pad * 0.6),
                            ],
                          ),
                        ),
                        SizedBox(width: pad * 0.5),
                        if (catName.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: pad * 0.6, vertical: pad * 0.25),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(radius * 0.5),
                              border: Border.all(color: theme.primary.withOpacity(0.5)),
                            ),
                            child: Text(
                              catName,
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
                            title,
                            style: GoogleFonts.poppins(
                              color: isLight ? theme.txtPrimary : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: fsTitle,
                              letterSpacing: 0.8,
                              shadows: [Shadow(color: cCyan.withOpacity(0.5), blurRadius: 10)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: pad * 0.3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: theme.secondaryText,
                        fontSize: fsSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: pad * 0.8),
                    // ── Accrual section ──
                    Text(
                      accrualLabel,
                      style: GoogleFonts.poppins(
                        color: theme.secondaryText,
                        fontSize: fsLabel,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: pad * 0.25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          accrualAmt,
                          style: GoogleFonts.poppins(
                            color: cGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: fsValue,
                            shadows: [Shadow(color: cGreen.withOpacity(0.6), blurRadius: 14)],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onDownload != null) ...[
                              _downloadButton(pad, radius, borderW, iconSz, cCyan),
                              SizedBox(width: pad * 0.4),
                            ],
                            if (onRefresh != null)
                              GestureDetector(
                                onTap: onRefresh,
                                child: Container(
                                  padding: EdgeInsets.all(pad * 0.28),
                                  decoration: BoxDecoration(
                                    color: cCyan.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(radius * 0.4),
                                    border: Border.all(color: cCyan.withOpacity(0.35), width: borderW),
                                  ),
                                  child: Icon(Icons.refresh_rounded, color: cCyan.withOpacity(0.80), size: iconSz),
                                ),
                              ),
                            if (lastUpdated.isNotEmpty) ...[
                              SizedBox(width: pad * 0.4),
                              Text(
                                'UPDATED $lastUpdated',
                                style: GoogleFonts.poppins(
                                  color: cCyan.withOpacity(0.55),
                                  fontSize: fsMeta,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Left: title + subtitle ──────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: borderW * 5,
                                height: fsTitle * 1.4,
                                decoration: BoxDecoration(
                                  color: cCyan,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cCyan.withOpacity(0.8),
                                      blurRadius: pad * 0.6,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: pad * 0.5),
                              if (catName.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: pad * 0.6, vertical: pad * 0.25),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(radius * 0.5),
                                    border: Border.all(color: theme.primary.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    catName,
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
                                  title,
                                  style: GoogleFonts.poppins(
                                    color: isLight ? theme.txtPrimary : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: fsTitle,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(color: cCyan.withOpacity(0.5), blurRadius: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: pad * 0.3),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: theme.secondaryText,
                              fontSize: fsSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: pad),

                    // ── Right: accrual + last updated + refresh ─────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          accrualLabel,
                          style: GoogleFonts.poppins(
                            color: theme.secondaryText,
                            fontSize: fsLabel,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: pad * 0.25),
                        Text(
                          accrualAmt,
                          style: GoogleFonts.poppins(
                            color: cGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: fsValue,
                            shadows: [
                              Shadow(color: cGreen.withOpacity(0.6), blurRadius: 14),
                            ],
                          ),
                        ),
                        if (lastUpdated.isNotEmpty) ...[
                          SizedBox(height: pad * 0.3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Download PDF button
                              if (onDownload != null) ...[
                                _downloadButton(pad, radius, borderW, iconSz, cCyan),
                                SizedBox(width: pad * 0.4),
                              ],
                              // Refresh button
                              if (onRefresh != null)
                                GestureDetector(
                                  onTap: onRefresh,
                                  child: Container(
                                    padding: EdgeInsets.all(pad * 0.28),
                                    decoration: BoxDecoration(
                                      color: cCyan.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(radius * 0.4),
                                      border: Border.all(
                                        color: cCyan.withOpacity(0.35),
                                        width: borderW,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.refresh_rounded,
                                      color: cCyan.withOpacity(0.80),
                                      size: iconSz,
                                    ),
                                  ),
                                ),
                              if (onRefresh != null) SizedBox(width: pad * 0.4),
                              // Last updated label
                              Text(
                                'UPDATED $lastUpdated',
                                style: GoogleFonts.poppins(
                                  color: cCyan.withOpacity(0.55),
                                  fontSize: fsMeta,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ] else if (onRefresh != null || onDownload != null) ...[
                          SizedBox(height: pad * 0.3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onDownload != null) ...[
                                _downloadButton(pad, radius, borderW, iconSz, cCyan),
                                SizedBox(width: pad * 0.4),
                              ],
                              if (onRefresh != null)
                                GestureDetector(
                                  onTap: onRefresh,
                                  child: Container(
                                    padding: EdgeInsets.all(pad * 0.28),
                                    decoration: BoxDecoration(
                                      color: cCyan.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(radius * 0.4),
                                      border: Border.all(
                                        color: cCyan.withOpacity(0.35),
                                        width: borderW,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.refresh_rounded,
                                      color: cCyan.withOpacity(0.80),
                                      size: iconSz,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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

  /// Same bordered icon-box treatment as the refresh button, swapped to a
  /// download glyph (or a spinner while [isGenerating]) so the two controls
  /// read as one consistent pair.
  Widget _downloadButton(
      double pad, double radius, double borderW, double iconSz, Color cCyan) {
    return GestureDetector(
      onTap: isGenerating ? null : onDownload,
      child: Container(
        padding: EdgeInsets.all(pad * 0.28),
        decoration: BoxDecoration(
          color: cCyan.withOpacity(0.08),
          borderRadius: BorderRadius.circular(radius * 0.4),
          border: Border.all(color: cCyan.withOpacity(0.35), width: borderW),
        ),
        child: isGenerating
            ? SizedBox(
                width: iconSz,
                height: iconSz,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cCyan.withOpacity(0.80)),
              )
            : Icon(Icons.download_rounded,
                color: cCyan.withOpacity(0.80), size: iconSz),
      ),
    );
  }
}
