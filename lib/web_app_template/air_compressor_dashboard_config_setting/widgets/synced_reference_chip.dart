import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Read-only "🔒 synced from Panel N" reference row — shown wherever a
/// value is already mapped elsewhere (Top KPI) so it isn't re-mapped and
/// can't drift between panels.
class SyncedReferenceChip extends StatelessWidget {
  const SyncedReferenceChip({
    super.key,
    required this.title,
    required this.sourceLabel,
    this.onEditSource,
  });

  final String title;
  final String sourceLabel;
  final VoidCallback? onEditSource;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sync = isLight ? t.primary : const Color(0xFF31ECFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: sync.withOpacity(isLight ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sync.withOpacity(0.35), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, size: 13, color: sync),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white)),
                Text(sourceLabel, style: GoogleFonts.poppins(fontSize: 9, color: sync)),
              ],
            ),
          ),
          if (onEditSource != null)
            InkWell(
              onTap: onEditSource,
              child: Text('Edit in Panel 1 ›', style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: sync)),
            ),
        ],
      ),
    );
  }
}
