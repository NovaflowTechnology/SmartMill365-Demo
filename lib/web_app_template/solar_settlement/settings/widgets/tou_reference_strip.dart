import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/utils/tou_window.dart';

import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';

/// The Peak Hour ToU window, shown for reference and edited where it lives.
///
/// One window serves demand alerts and settlement alike, so it is linked here
/// rather than copied — a copy would drift, and a ledger split on a different
/// window from the demand chart beside it is a dispute waiting to happen.
class TouReferenceStrip extends StatelessWidget {
  const TouReferenceStrip({super.key, required this.tou, required this.onEdit});

  final TouWindow? tou;
  final VoidCallback onEdit;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String daysLabel(List<int> days) {
    final d = days.where((x) => x >= 1 && x <= 7).toSet().toList()..sort();
    if (d.isEmpty || d.length == 7) return 'every day';
    String run(int from, int to) =>
        from == to ? _names[from - 1] : '${_names[from - 1]}–${_names[to - 1]}';
    final contiguous = d.last - d.first + 1 == d.length;
    return contiguous && d.length > 2
        ? run(d.first, d.last)
        : d.map((x) => _names[x - 1]).join(', ');
  }

  static String _hhmm(double h) {
    final hours = h.floor();
    final mins = ((h - hours) * 60).round();
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final t = tou;
    final value = t == null
        ? 'Not configured for your account — set the Peak Hour ToU in Energy '
            'System Settings, then save here so every viewer uses it.'
        : 'Peak ${_hhmm(t.startHour)}–${_hhmm(t.endHour)} · ${daysLabel(t.days)}'
            ' · non-peak at all other times';

    final title = Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: p.iconChip(SettlementColors.amber),
        child: const Icon(Icons.schedule_rounded,
            size: 19, color: SettlementColors.amber),
      ),
      const SizedBox(width: 13),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ToU Calendar',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
            Text('Defined once in Energy System Settings · shared by MD alerts '
                '& settlement',
                style: GoogleFonts.poppins(fontSize: 12.5, color: p.mutedText)),
          ],
        ),
      ),
    ]);

    final valueText = Text(value,
        style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: t == null ? SettlementColors.amber : p.text));

    final actions = Row(mainAxisSize: MainAxisSize.min, children: [
      const SourceTag(SourceKind.referenced),
      const SizedBox(width: 12),
      SettingButton(
        label: 'Edit in Energy System Settings',
        icon: Icons.arrow_forward_rounded,
        onTap: onEdit,
      ),
    ]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: p.cardDecoration(accent: SettlementColors.amber),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              valueText,
              const SizedBox(height: 12),
              Wrap(children: [actions]),
            ],
          );
        }
        return Row(children: [
          Flexible(flex: 4, child: title),
          const SizedBox(width: 20),
          Expanded(flex: 5, child: valueText),
          const SizedBox(width: 16),
          actions,
        ]);
      }),
    );
  }
}
