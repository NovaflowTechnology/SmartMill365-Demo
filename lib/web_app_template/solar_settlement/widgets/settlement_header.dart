import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../solar_settlement_theme.dart';

/// Title, the period being settled, and the actions that apply to it.
///
/// The month picker belongs here rather than beside the table because it
/// changes every figure on the page, not just the ledger.
class SettlementHeader extends StatelessWidget {
  const SettlementHeader({
    super.key,
    required this.month,
    required this.onPickMonth,
    this.onExport,
    this.onSettings,
    this.isLoading = false,
  });

  final DateTime month;
  final ValueChanged<DateTime> onPickMonth;
  final VoidCallback? onExport;

  /// Null for anyone who may not change the rates, and the gear is then not
  /// drawn at all. Hiding a control nobody may use beats showing one that
  /// refuses.
  final VoidCallback? onSettings;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    // The title plus three controls overflow a tablet, and a header that clips
    // is a header that loses its actions — so below that width they stack.
    return LayoutBuilder(builder: (context, c) {
      final controls = Row(mainAxisSize: MainAxisSize.min, children: [
        if (isLoading) ...[
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
          ),
          const SizedBox(width: 12),
        ],
        _MonthPicker(month: month, onPick: onPickMonth),
        const SizedBox(width: 10),
        _ExportButton(onTap: onExport),
        if (onSettings != null) ...[
          const SizedBox(width: 10),
          _SettingsButton(onTap: onSettings!),
        ],
      ]);

      if (c.maxWidth < 780) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(palette: p, compact: true),
            const SizedBox(height: 16),
            controls,
          ],
        );
      }
      return Row(children: [
        Expanded(child: _Title(palette: p, compact: false)),
        controls,
      ]);
    });
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.palette, required this.compact});

  final SettlementPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 38 : 44,
          height: compact ? 38 : 44,
          alignment: Alignment.center,
          decoration: p.iconChip(SettlementColors.amber),
          child: Icon(Icons.solar_power_outlined,
              size: compact ? 20 : 23, color: SettlementColors.amber),
        ),
        const SizedBox(width: 13),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Solar Settlement',
                  style: GoogleFonts.poppins(
                      fontSize: compact ? 26 : 34,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: p.text)),
              const SizedBox(height: 3),
              Text(
                'Energy supplied between blocks, priced by time of use.',
                style: GoogleFonts.poppins(
                    fontSize: compact ? 12.5 : 14, color: p.subText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.month, required this.onPick});

  final DateTime month;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    // Twelve months back is as far as a settlement is ever reopened, and a
    // longer list turns a two-click action into a scroll.
    final now = DateTime.now();
    final options =
        List.generate(12, (i) => DateTime(now.year, now.month - i, 1));
    return PopupMenuButton<DateTime>(
      tooltip: 'Settlement period',
      onSelected: onPick,
      itemBuilder: (_) => [
        for (final m in options)
          PopupMenuItem<DateTime>(
            value: m,
            child: Text(SettlementFormat.monthLabel(m),
                style: GoogleFonts.poppins(fontSize: 13.5)),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: p.panel,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: p.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_outlined, size: 15, color: p.subText),
          const SizedBox(width: 9),
          Text(SettlementFormat.monthLabel(month),
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.text)),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, size: 17, color: p.subText),
        ]),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: p.accent.withOpacity(p.isLight ? 0.10 : 0.16),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: p.accent.withOpacity(0.55)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.download_outlined, size: 16, color: p.accent),
            const SizedBox(width: 8),
            Text('Export',
                style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.accent)),
          ]),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    // A gear, and carrying the same weight as the other actions. Drawn muted
    // and unlabelled it read as an empty square — a control nobody could find
    // is the same as one that is not there.
    return Tooltip(
      message: 'Solar Settlement Setting',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: SettlementColors.amber.withOpacity(p.isLight ? 0.10 : 0.16),
            borderRadius: BorderRadius.circular(9),
            border:
                Border.all(color: SettlementColors.amber.withOpacity(0.6)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.settings_outlined,
                size: 17, color: SettlementColors.amber),
            const SizedBox(width: 8),
            Text('Settings',
                style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: SettlementColors.amber)),
          ]),
        ),
      ),
    );
  }
}
