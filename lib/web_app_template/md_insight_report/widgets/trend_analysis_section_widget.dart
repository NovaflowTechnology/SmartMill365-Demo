import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import 'trend_bar_chart_widget.dart';
import '../models/report_stat.dart';
import 'report_panel_widget.dart';
import 'report_stat_row_widget.dart';
import 'section_header_widget.dart';

/// "Trend Analysis" card: daily maximum-demand line chart across the billing
/// period, with an Above-Contract-Since/vs-Last-Month stat row underneath.
class TrendAnalysisSection extends StatelessWidget {
  final List<double> dailyValues;
  final double contractCapacity;
  final List<ReportStat> stats;
  final String monthAbbrev;

  const TrendAnalysisSection({
    super.key,
    required this.dailyValues,
    required this.contractCapacity,
    required this.stats,
    this.monthAbbrev = '',
  });

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(number: '5', title: 'Trend Analysis'),
            const SizedBox(height: 4),
            Text('DAILY MAXIMUM DEMAND TREND (KW)', style: GoogleFonts.poppins(fontSize: 11.5, color: theme.secondaryText, letterSpacing: 0.6)),
            const SizedBox(height: 10),
            Expanded(
              child: TrendBarChart(
                values: dailyValues,
                thresholdValue: contractCapacity,
                labelBuilder: (i, count) {
                  final day = i + 1;
                  if (day != 1 && day % 3 != 0) return null;
                  return monthAbbrev.isNotEmpty ? '$day $monthAbbrev' : '$day';
                },
              ),
            ),
            const SizedBox(height: 10),
            ReportStatRow(stats: stats),
          ],
        );
      },
    );
  }
}
