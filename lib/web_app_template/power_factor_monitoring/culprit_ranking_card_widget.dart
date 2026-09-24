import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';

class CulpritData {
  final String name;
  double value;
  final Color color;

  CulpritData({
    required this.name,
    required double value,
    required this.color,
  }) : value = value.clamp(0.0, 1.0);
}

class CulpritRankingCard extends StatefulWidget {
  final List<CulpritData> culprits;
  final ValueChanged<List<CulpritData>>? onValuesChanged;

  const CulpritRankingCard({
    super.key,
    required this.culprits,
    this.onValuesChanged,
  });

  @override
  State<CulpritRankingCard> createState() => _CulpritRankingCardState();
}

class _CulpritRankingCardState extends State<CulpritRankingCard> {
  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: sizing.accentW,
                  height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withOpacity(0.9),
                        blurRadius: sizing.pad * 0.7,
                        spreadRadius: sizing.accentW * 0.3,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: sizing.pad * 0.5),
                Text(
                  'CULPRIT RANKING',
                  style: GoogleFonts.poppins(
                    fontSize: sizing.titleFs.clamp(11.0, 13.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Culprit bars ─────────────────────────────────────
            ...widget.culprits.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildCulpritBar(entry.value, entry.key + 1, entry.key, sizing),
              );
            }),
          ],
        );
      },
    );
  }

  void _updateValue(int index, double newValue) {
    setState(() {
      widget.culprits[index].value = newValue.clamp(0.0, 1.0);
    });
    widget.onValuesChanged?.call(widget.culprits);
  }

  Widget _buildCulpritBar(CulpritData culprit, int rank, int index, CardSizing sizing) {
    final String displayValue = 'PF : ${culprit.value.toStringAsFixed(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOP$rank ${culprit.name}',
              style: GoogleFonts.poppins(
                fontSize: sizing.bodyFs.clamp(10.0, 12.0),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF06B6D4),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Text(
                displayValue,
                style: GoogleFonts.poppins(
                  fontSize: sizing.bodyFs.clamp(9.0, 11.0),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final double normalizedValue = culprit.value.clamp(0.0, 1.0);
            final double markerPosition = (normalizedValue * constraints.maxWidth) - 2;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                final double newValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                _updateValue(index, newValue);
              },
              onTapDown: (details) {
                final double newValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                _updateValue(index, newValue);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
                    ),
                    Container(
                      width: normalizedValue * constraints.maxWidth,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [culprit.color, culprit.color.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: culprit.color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                    ),
                    Positioned(
                      left: markerPosition.clamp(0.0, constraints.maxWidth - 4),
                      child: Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3, offset: const Offset(0, 1))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
