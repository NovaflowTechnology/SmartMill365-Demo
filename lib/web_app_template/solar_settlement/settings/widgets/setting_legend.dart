import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';

/// The key to the source tags used on every row below.
class SettingLegend extends StatelessWidget {
  const SettingLegend({super.key});

  static const _items = [
    (SourceKind.raw, 'a meter field — meters come from Master Facilities'),
    (SourceKind.module, 'computed by the settlement engine (locked)'),
    (SourceKind.price, 'defined here — the settlement source of truth'),
    (SourceKind.referenced, 'linked from another setting — edit it there'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: p.cardDecoration(),
      child: Wrap(
        spacing: 22,
        runSpacing: 10,
        children: [
          for (final (kind, text) in _items)
            Row(mainAxisSize: MainAxisSize.min, children: [
              SourceTag(kind),
              const SizedBox(width: 8),
              Text(text,
                  style: GoogleFonts.poppins(fontSize: 12.5, color: p.subText)),
            ]),
        ],
      ),
    );
  }
}
