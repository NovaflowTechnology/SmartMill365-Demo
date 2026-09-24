import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// KPI stat card for the Carbon Intelligence Dashboard header row:
/// label + info icon, optional badge icon, big value, trend line,
/// a muted secondary line, and a mini sparkline.
class CarbonKpiStatCard extends StatelessWidget {
  const CarbonKpiStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.trendText,
    required this.trendUp,
    required this.trendGoodWhenUp,
    required this.secondaryLine,
    required this.accentColor,
    required this.sparkline,
    this.badgeIcon,
    this.tooltip,
  });

  final String label;
  final String value;
  final String unit;
  final String trendText;
  final bool trendUp;
  final bool trendGoodWhenUp;
  final String secondaryLine;
  final Color accentColor;
  final List<double> sparkline;
  final IconData? badgeIcon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isGood = trendGoodWhenUp ? trendUp : !trendUp;
    final trendColor = isGood ? t.success : t.error;

    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.9);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : accentColor.withOpacity(0.18);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withOpacity(0.04) : accentColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Label row ────────────────────────────────────────────────
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
                if (tooltip != null) ...[
                  const SizedBox(width: 3),
                  Tooltip(
                    message: tooltip!,
                    child: Icon(Icons.info_outline_rounded, size: 11, color: t.txtSubtle),
                  ),
                ],
                if (badgeIcon != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(isLight ? 0.1 : 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(badgeIcon, size: 12, color: accentColor),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // ── Value ────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
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
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: t.txtMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // ── Trend ────────────────────────────────────────────────────
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
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              secondaryLine,
              style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // ── Sparkline ────────────────────────────────────────────────
            SizedBox(
              height: 28,
              child: _Sparkline(values: sparkline, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 1.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
