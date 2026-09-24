import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import '../models/report_stat.dart';

/// Row of evenly-spaced label/value pairs shown under a chart (e.g. Peak
/// Period / Peak Load / Peak Duration in Load Analysis).
class ReportStatRow extends StatelessWidget {
  final List<ReportStat> stats;
  const ReportStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth / stats.length;
      return Row(
        children: [
          for (final stat in stats)
            SizedBox(
              width: w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.label, style: GoogleFonts.poppins(fontSize: 11.5, color: theme.secondaryText)),
                  const SizedBox(height: 3),
                  Text(stat.value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: theme.primaryText)),
                ],
              ),
            ),
        ],
      );
    });
  }
}
