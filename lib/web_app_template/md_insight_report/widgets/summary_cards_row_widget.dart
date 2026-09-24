import 'package:flutter/material.dart';

import 'summary_card_widget.dart';

/// Responsive wrap of the report's top summary cards — 5 columns on wide
/// screens, down to 2 on narrow ones.
class SummaryCardsRow extends StatelessWidget {
  final List<SummaryCardData> cards;

  const SummaryCardsRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 1100
          ? 5
          : constraints.maxWidth > 700
              ? 3
              : 2;
      final cardWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final c in cards) SizedBox(width: cardWidth, height: 150, child: SummaryCard(data: c))],
      );
    });
  }
}
