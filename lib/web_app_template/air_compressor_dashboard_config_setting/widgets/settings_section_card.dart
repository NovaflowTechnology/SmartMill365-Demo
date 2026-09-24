import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Collapsible settings section — the "pgroup" shell from the reference
/// mockup: an index badge, title + description, a status pill, and a
/// chevron that expands/collapses the body.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.child,
    this.initiallyExpanded = true,
  });

  final int index;
  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.9);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpandableNotifier(
        initialExpanded: initiallyExpanded,
        child: ExpandablePanel(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(isLight ? 0.1 : 0.16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: t.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSubtle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isLight ? 0.1 : 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          collapsed: const SizedBox.shrink(),
          expanded: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
          theme: ExpandableThemeData(
            tapHeaderToExpand: true,
            tapBodyToExpand: false,
            tapBodyToCollapse: false,
            headerAlignment: ExpandablePanelHeaderAlignment.center,
            hasIcon: true,
            expandIcon: Icons.chevron_right_rounded,
            collapseIcon: Icons.keyboard_arrow_down_rounded,
            iconSize: 20,
            iconColor: t.txtMuted,
            iconPadding: const EdgeInsets.only(right: 14),
          ),
        ),
      ),
    );
  }
}
