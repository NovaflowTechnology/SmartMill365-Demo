import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Single stat tile used in the KPI row atop the data logger — a label,
/// a headline value, and a supporting caption, with a colored accent bar
/// on the left edge.
class TblKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;
  final Color? subColor;
  final Color? valueColor;

  const TblKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    this.subColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [theme.secondaryBackground.withOpacity(0.97), theme.primaryBackground.withOpacity(0.97)]
              : [const Color(0xFF0E2040).withOpacity(0.85), const Color(0xFF07101F).withOpacity(0.92)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? (isLight ? theme.txtPrimary : Colors.white),
              fontSize: 21,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.poppins(color: subColor ?? theme.secondaryText, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
