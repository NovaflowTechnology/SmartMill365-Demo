import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import 'carbon_flow_diagram.dart' show DashboardCard;

/// "Emission Breakdown by Source" donut chart with legend and a
/// "View Details" action.
class EmissionBreakdownCard extends StatelessWidget {
  const EmissionBreakdownCard({
    super.key,
    required this.periodLabel,
    required this.sources,
    required this.totalTco2e,
    this.onViewDetails,
  });

  final String periodLabel;
  final List<EmissionSource> sources;
  final double totalTco2e;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DashboardCard(
      title: 'EMISSION BREAKDOWN',
      subtitle: 'by Source · $periodLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 44,
                    sections: [
                      for (final s in sources)
                        PieChartSectionData(
                          value: s.percent,
                          color: s.color,
                          radius: 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalTco2e.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLight ? t.txtPrimary : Colors.white,
                      ),
                    ),
                    Text(
                      'tCO₂e',
                      style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final s in sources) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: s.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isLight ? t.txtPrimary : Colors.white,
                          ),
                        ),
                        if (s.sublabel.isNotEmpty)
                          TextSpan(
                            text: ' ${s.sublabel}',
                            style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                          ),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${s.percent.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: s.color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.tco2e.toStringAsFixed(1)} tCO₂e',
                    style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (onViewDetails != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onViewDetails,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E2D48)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtSecondary : Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
