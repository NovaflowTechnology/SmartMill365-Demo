import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class Co2KpiCard extends StatelessWidget {
  const Co2KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.trendText,
    required this.trendUp,
    required this.trendGoodWhenDown,
    required this.formulaLine1,
    this.formulaLine2,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String unit;
  final String trendText;
  final bool trendUp;
  final bool trendGoodWhenDown;
  final String formulaLine1;
  final String? formulaLine2;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isBad = trendGoodWhenDown ? trendUp : !trendUp;
    final trendColor = isBad ? t.error : t.success;

    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.9);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : accentColor.withOpacity(0.18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withOpacity(0.04)
                : accentColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            children: [
              // Content (non-positioned — determines card height)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Label ──────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ── Value ──────────────────────────────────────────────
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isLight ? t.txtPrimary : Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // ── Unit ───────────────────────────────────────────────
                    Text(
                      unit,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: t.txtMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // ── Trend ──────────────────────────────────────────────
                    Row(
                      children: [
                        Icon(
                          trendUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          size: 15,
                          color: trendColor,
                        ),
                        Flexible(
                          child: Text(
                            trendText,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: trendColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // ── Formula ────────────────────────────────────────────
                    Text(
                      formulaLine1,
                      style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (formulaLine2 != null)
                      Text(
                        formulaLine2!,
                        style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Left accent bar (drawn on top, fills card height via Positioned)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
