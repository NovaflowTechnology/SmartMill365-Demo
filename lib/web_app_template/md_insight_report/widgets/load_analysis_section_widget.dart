import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/utils/tou_window.dart';

import 'chart_legend_widget.dart';
import 'line_area_chart_widget.dart';
import '../models/report_stat.dart';
import 'report_panel_widget.dart';
import 'report_stat_row_widget.dart';
import 'section_header_widget.dart';

/// "Load Analysis" card: 24-hour power load line chart against contract
/// capacity, with a Peak Period/Load/Duration stat row underneath.
class LoadAnalysisSection extends StatelessWidget {
  final List<double> hourlyValues;
  final double contractCapacity;
  final List<ReportStat> stats;

  /// Peak Hour ToU start/end as stored in settings ("HH:mm"). Null when the
  /// window is not configured, in which case no band is drawn.
  final String? peakStart;
  final String? peakEnd;

  /// Peak weekdays, 1 = Monday. Empty applies the window to every day.
  final List<int> peakDays;

  /// The day this 24-hour trend belongs to — the day Max Demand was recorded.
  /// Used only to decide whether that day is a peak day at all; if it cannot
  /// be parsed the band is still drawn, since a missing date is not evidence
  /// that the day was off-peak.
  final String? date;

  const LoadAnalysisSection({
    super.key,
    required this.hourlyValues,
    required this.contractCapacity,
    required this.stats,
    this.peakStart,
    this.peakEnd,
    this.peakDays = const [],
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        final parsedDate = date == null ? null : DateTime.tryParse(date!);
        final window = TouWindow.parse(peakStart, peakEnd, days: peakDays);
        // The whole chart is one day, so the day either qualifies or it does
        // not — there is nothing to shade partially.
        final tou =
            window != null && window.appliesOn(parsedDate?.weekday) ? window : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.schedule_rounded, title: 'Load Analysis'),
            const SizedBox(height: 4),
            Text('24-HOUR POWER LOAD TREND', style: GoogleFonts.poppins(fontSize: 11.5, color: theme.secondaryText, letterSpacing: 0.6)),
            const SizedBox(height: 10),
            ChartLegend(
              seriesLabel: 'Power Load (kW)',
              extraLabel: tou == null ? null : 'Peak Hour ToU',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineAreaChart(
                values: hourlyValues,
                thresholdValue: contractCapacity,
                touWindow: tou,
                labelBuilder: (i, count) {
                  // count <= 1 (e.g. the single-point placeholder shown while
                  // the report is still loading) would divide by zero below.
                  if (count <= 1) return null;
                  final hour = (i * 24 / (count - 1)).round();
                  if (hour % 4 != 0) return null;
                  return '${hour.toString().padLeft(2, '0')}:00';
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
