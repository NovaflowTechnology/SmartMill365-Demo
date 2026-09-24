import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class MetricCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? valueColor;
  final Color? subtitleColor;
  final IconData? icon;
  // Small pill shown in the icon's slot next to the value (e.g. "Peak: Sep
  // 15") instead of a whole extra line, so cards in the same row never grow
  // taller than their siblings. Takes precedence over `icon` when set.
  final String? trailingLabel;

  const MetricCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueColor,
    this.subtitleColor,
    this.icon,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.0,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          title,
          style: GoogleFonts.poppins(
            color: theme.secondaryText,
            fontSize: sizing.bodyFs.clamp(10.0, 12.0),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 12),

        // Value with optional icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: valueColor ?? theme.primaryText,
                    fontSize: sizing.headerFs.clamp(24.0, 32.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (trailingLabel != null && trailingLabel!.isNotEmpty)
              Padding(
                // Nudges the pill up to sit at the same baseline the icon
                // would occupy, so this slot never grows taller than the
                // 24px icon does on sibling cards.
                padding: const EdgeInsets.only(bottom: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    // Neutral regardless of subtitleColor — this badge is
                    // informational (which day), not a status indicator like
                    // the subtitle (up/down vs last month) can be.
                    color: theme.secondaryText.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailingLabel!,
                    style: GoogleFonts.poppins(
                      color: theme.secondaryText,
                      fontSize: sizing.bodyFs.clamp(9.0, 10.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 24,
                color: valueColor ?? theme.primaryText,
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: subtitleColor ?? const Color(0xFF10B981),
            fontSize: sizing.bodyFs.clamp(10.0, 12.0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
