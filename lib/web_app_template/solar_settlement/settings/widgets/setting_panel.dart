import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';

enum NoteTone { info, amber, green }

/// A one-line explanation across the top or bottom of a panel.
class SettingNote extends StatelessWidget {
  const SettingNote({
    super.key,
    required this.text,
    this.tone = NoteTone.info,
    this.icon,
    this.top = false,
  });

  final String text;
  final NoteTone tone;
  final IconData? icon;

  /// Drawn under the header (border below) rather than under the table.
  final bool top;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final color = switch (tone) {
      NoteTone.info => p.accent,
      NoteTone.amber => SettlementColors.amber,
      NoteTone.green => SettlementColors.green,
    };
    final side = BorderSide(color: color.withOpacity(0.25));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(p.isLight ? 0.07 : 0.08),
        border: top ? Border(bottom: side) : Border(top: side),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            icon ??
                switch (tone) {
                  NoteTone.info => Icons.info_outline,
                  NoteTone.amber => Icons.warning_amber_rounded,
                  NoteTone.green => Icons.verified_outlined,
                },
            size: 16,
            color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: p.subText, height: 1.45)),
        ),
      ]),
    );
  }
}

/// One dashboard panel's worth of settings, collapsible from its header.
class SettingPanel extends StatelessWidget {
  const SettingPanel({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.child,
    this.badge,
    this.note,
    this.footer,
    this.collapsed = false,
    this.onToggle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? badge;
  final Widget? note;
  final Widget? footer;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Container(
      decoration: p.cardDecoration(accent: accent),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: p.iconChip(accent),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: p.text)),
                          if (badge != null) badge!,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: p.mutedText)),
                    ],
                  ),
                ),
                if (onToggle != null)
                  AnimatedRotation(
                    turns: collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 22, color: p.subText),
                  ),
              ]),
            ),
          ),
          if (!collapsed) ...[
            Divider(height: 1, thickness: 1, color: p.border),
            if (note != null) note!,
            child,
            if (footer != null) footer!,
          ],
        ],
      ),
    );
  }
}
