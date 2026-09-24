import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// KPI stat card for the Air Compressor Monitoring header row: label, big
/// value + unit, a delta/trend line, a muted comparison line, and either a
/// 5-star rating row (System Health) or nothing below.
class AcKpiStatCard extends StatelessWidget {
  const AcKpiStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.subtitle = '',
    this.deltaValue,
    this.deltaPercent,
    this.deltaGood = true,
    this.comparisonLabel = '',
    this.comparisonValue = '',
    this.icon,
    this.starRating,
  });

  final String label;
  final String value;
  final String unit;
  final String subtitle;
  final double? deltaValue;
  final double? deltaPercent;
  final bool deltaGood;
  final String comparisonLabel;
  final String comparisonValue;
  final IconData? icon;
  final double? starRating;

  bool get _hasDelta => deltaValue != null || deltaPercent != null;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final trendColor = deltaGood ? t.success : t.error;

    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.9);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: t.txtMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(isLight ? 0.1 : 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 12, color: t.primary),
                  ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtSubtle),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isLight ? t.txtPrimary : Colors.white,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: t.txtMuted),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (_hasDelta) ...[
              Row(
                children: [
                  Icon(
                    deltaGood ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                    size: 15,
                    color: trendColor,
                  ),
                  Flexible(
                    child: Text(
                      deltaPercent != null
                          ? '${deltaPercent!.toStringAsFixed(1)}% ${deltaGood ? "Improved" : "Worsened"}'
                          : deltaValue!.toStringAsFixed(2),
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: trendColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$comparisonLabel $comparisonValue',
                style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (starRating != null) ...[
              _StarRating(rating: starRating!, t: t),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.t});

  final double rating;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            rating >= i + 1
                ? Icons.star_rounded
                : (rating > i ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: 15,
            color: rating > i ? const Color(0xFFF59E0B) : t.txtSubtle,
          ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: t.txtMuted),
        ),
      ],
    );
  }
}
