import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import '../md_insight_report_colors.dart';

/// Small "series color — label" legend row shown above the load/trend charts.
class ChartLegend extends StatelessWidget {
  final String seriesLabel;
  final Color seriesColor;

  /// Optional third entry, used for the shaded Peak Hour ToU band. A shaded
  /// area with nothing naming it invites the reader to guess.
  final String? extraLabel;

  const ChartLegend({
    super.key,
    required this.seriesLabel,
    this.seriesColor = MdReportColors.blue,
    this.extraLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    Widget item(Color color, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 20, height: dashed ? 2 : 3, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: theme.secondaryText)),
          ],
        );
    Widget zone(Color fill, Color edge, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: edge, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: theme.secondaryText)),
          ],
        );

    return Row(children: [
      item(seriesColor, seriesLabel),
      const SizedBox(width: 16),
      item(MdReportColors.red.withOpacity(0.5), 'Contract Capacity', dashed: true),
      if (extraLabel != null) ...[
        const SizedBox(width: 16),
        zone(const Color(0x4DFF5252), const Color(0xE6FF5252), extraLabel!),
        const SizedBox(width: 12),
        zone(const Color(0x2E66BB6A), const Color(0x9966BB6A), 'Off Peak'),
      ],
    ]);
  }
}
