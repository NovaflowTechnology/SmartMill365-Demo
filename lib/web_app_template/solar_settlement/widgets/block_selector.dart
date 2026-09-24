import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/settlement_models.dart';
import '../solar_settlement_theme.dart';

/// Which block's settlement is on screen, and who it supplies.
///
/// The agreement is stated beside the tabs rather than left implicit: every
/// figure below is one block's energy going to another, and a reader who has
/// to infer the direction will eventually infer it backwards.
class BlockSelector extends StatelessWidget {
  const BlockSelector({
    super.key,
    required this.blocks,
    required this.selectedId,
    required this.onSelect,
    required this.supplier,
    required this.receiver,
  });

  final List<SettlementBlock> blocks;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final SettlementBlock supplier;
  final SettlementBlock receiver;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final tabs = [
      for (final b in blocks)
        _Tab(
          label: b.name,
          selected: b.id == selectedId,
          onTap: () => onSelect(b.id),
        ),
    ];
    final chip = supplier.name.isNotEmpty && receiver.name.isNotEmpty
        ? _AgreementChip(supplier: supplier, receiver: receiver, palette: p)
        : null;

    // Three tabs and the agreement chip stop fitting side by side well before
    // phone width, so below that the chip moves under the tabs rather than
    // squeezing them into initials.
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 720) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: tabs),
            if (chip != null) ...[const SizedBox(height: 12), chip],
          ],
        );
      }
      return Row(children: [
        for (final t in tabs) ...[t, const SizedBox(width: 8)],
        const Spacer(),
        if (chip != null) chip,
      ]);
    });
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? p.accent.withOpacity(p.isLight ? 0.12 : 0.18) : p.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? p.accent : p.border,
              width: selected ? 1.5 : 1),
          // The selected tab glows in dark, the way the mode toggles in the
          // command centres do, so the choice is visible at a glance.
          boxShadow: selected && !p.isLight
              ? [BoxShadow(color: p.accent.withOpacity(0.28), blurRadius: 12)]
              : const [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.accent : p.subText,
          ),
        ),
      ),
    );
  }
}

class _AgreementChip extends StatelessWidget {
  const _AgreementChip({
    required this.supplier,
    required this.receiver,
    required this.palette,
  });

  final SettlementBlock supplier;
  final SettlementBlock receiver;
  final SettlementPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.apartment_rounded, size: 15, color: p.subText),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(supplier.name.toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.text)),
            Text('Supplies',
                style:
                    GoogleFonts.poppins(fontSize: 9.5, color: p.mutedText)),
          ],
        ),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward, size: 15, color: p.accent),
        const SizedBox(width: 12),
        Icon(Icons.apartment_rounded, size: 15, color: p.accent),
        const SizedBox(width: 7),
        Text(receiver.name.toUpperCase(),
            style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: p.accent)),
      ]),
    );
  }
}
