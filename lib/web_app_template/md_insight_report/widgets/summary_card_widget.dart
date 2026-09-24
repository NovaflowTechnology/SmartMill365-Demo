import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import 'report_panel_widget.dart';

/// Data for one of the top summary cards (Current MD, Monthly MD, Contract
/// Capacity, MD Status, Estimated Surcharge).
class SummaryCardData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color? valueColor;
  final String subtitle;
  final Color? subtitleColor;

  const SummaryCardData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueColor,
    required this.subtitle,
    this.subtitleColor,
  });
}

/// Icon-badge + big value + colored subtitle card used in the report's top
/// summary row.
class SummaryCard extends StatelessWidget {
  final SummaryCardData data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: data.iconColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(data.icon, size: 16, color: data.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: theme.secondaryText, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(data.value, style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w800, color: data.valueColor ?? theme.primaryText)),
            ),
            if (data.subtitle.isNotEmpty)
              Text(data.subtitle, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: data.subtitleColor ?? theme.secondaryText)),
          ],
        );
      },
    );
  }
}
