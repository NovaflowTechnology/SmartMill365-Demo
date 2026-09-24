import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';

/// Title, the published version, and the page's actions.
class SettingHeader extends StatelessWidget {
  const SettingHeader({
    super.key,
    required this.versionLabel,
    required this.effectiveFrom,
    required this.published,
    required this.dirty,
    required this.saving,
    required this.onBack,
    required this.onHistory,
    required this.onNewVersion,
    required this.onEditVersion,
    required this.onSave,
    this.updatedLine = '',
  });

  final String versionLabel;
  final DateTime effectiveFrom;

  /// This version has been saved at least once.
  final bool published;
  final bool dirty;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback? onHistory;
  final VoidCallback onNewVersion;
  final VoidCallback onEditVersion;
  final VoidCallback? onSave;
  final String updatedLine;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 900;
      final left = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back, size: 15, color: p.accent),
                const SizedBox(width: 6),
                Text('Solar Settlement',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.accent)),
                Text('  ·  Settings',
                    style:
                        GoogleFonts.poppins(fontSize: 12.5, color: p.mutedText)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: compact ? 38 : 44,
              height: compact ? 38 : 44,
              alignment: Alignment.center,
              decoration: p.iconChip(SettlementColors.amber),
              child: Icon(Icons.tune_rounded,
                  size: compact ? 20 : 23, color: SettlementColors.amber),
            ),
            const SizedBox(width: 13),
            Flexible(
              child: Text('Solar Settlement Setting',
                  style: GoogleFonts.poppins(
                      fontSize: compact ? 24 : 30,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: p.text)),
            ),
          ]),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Wire each panel of the Solar Settlement dashboard to its data. '
              'Prices are defined here; blocks, meters, ToU and TNB tariffs are '
              'linked from the modules that own them, not re-created.',
              style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14, color: p.subText, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            SettingButton(
                label: 'Version history',
                icon: Icons.history,
                ghost: true,
                onTap: onHistory),
            SettingButton(
                label: 'New version…',
                icon: Icons.add_circle_outline,
                onTap: onNewVersion),
            SettingButton(
                label: 'Save settings',
                icon: Icons.save_outlined,
                primary: true,
                busy: saving,
                onTap: onSave),
          ]),
        ],
      );

      final pill = _VersionPill(
        label: versionLabel,
        effectiveFrom: effectiveFrom,
        state: !published
            ? 'Not published'
            : dirty
                ? 'Unsaved changes'
                : 'Published',
        good: published && !dirty,
        updatedLine: updatedLine,
        onTap: onEditVersion,
      );

      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [left, const SizedBox(height: 14), pill],
        );
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: left),
        const SizedBox(width: 20),
        pill,
      ]);
    });
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.label,
    required this.effectiveFrom,
    required this.state,
    required this.good,
    required this.updatedLine,
    required this.onTap,
  });

  final String label;
  final DateTime effectiveFrom;
  final String state;
  final bool good;
  final String updatedLine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final dot = good ? SettlementColors.green : SettlementColors.amber;
    return Tooltip(
      message: 'Change the effective month of this version',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: p.cardDecoration(accent: dot),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: dot.withOpacity(0.6), blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Text(label,
                    style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.text)),
                const SizedBox(width: 8),
                Icon(Icons.edit_calendar_outlined, size: 15, color: p.subText),
              ]),
              const SizedBox(height: 5),
              Text(
                  '$state  ·  effective ${SettlementFormat.dayLabel(effectiveFrom)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: p.subText)),
              if (updatedLine.isNotEmpty)
                Text(updatedLine,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: p.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}
