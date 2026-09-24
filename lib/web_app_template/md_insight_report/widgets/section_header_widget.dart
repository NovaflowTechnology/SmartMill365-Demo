import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

/// Section title used throughout the MD Insight Report: a circular badge
/// (either a number, "3. CAPACITY ANALYSIS", or a small icon for the
/// icon-only chart sections) followed by the title.
class SectionHeader extends StatelessWidget {
  final String? number;
  final IconData? icon;
  final String title;

  const SectionHeader({super.key, this.number, this.icon, required this.title}) : assert(number != null || icon != null, 'Provide either number or icon');

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = isLight ? theme.primary : const Color(0xFF3FA9F5);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.12),
            border: Border.all(color: accent, width: 1.4),
          ),
          child: number != null
              ? Text(number!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: accent))
              : Icon(icon, size: 14, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.6),
        ),
      ],
    );
  }
}
