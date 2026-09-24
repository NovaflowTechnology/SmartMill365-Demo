import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      glowColor: valueColor,
      topPadMultiplier: 1.0,
      builder: (context, sizing) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: sizing.bodyFs.clamp(12.0, 14.0),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: sizing.headerFs.clamp(32.0, 42.0),
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: sizing.bodyFs.clamp(12.0, 13.0),
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
