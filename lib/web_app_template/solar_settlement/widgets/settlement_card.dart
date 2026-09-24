import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../solar_settlement_theme.dart';
import 'settlement_sparkline.dart';

/// The panel every section of this screen sits in.
///
/// One wrapper rather than a Container per widget: the padding, the title
/// treatment and the trailing-action slot then cannot drift between sections,
/// which is what makes a page of panels read as one screen.
///
/// It lifts on hover, the way the cards in Energy Details do. That is not
/// decoration for its own sake — it tells the reader the card is a thing in
/// itself, and a page of them stops reading as a wall.
class SettlementCard extends StatefulWidget {
  const SettlementCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.accent,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final String? title;
  final IconData? icon;

  /// Colours the icon chip, the rule under the title and the card's own wash.
  /// Left null it follows the module accent.
  final Color? accent;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  State<SettlementCard> createState() => _SettlementCardState();
}

class _SettlementCardState extends State<SettlementCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final accent = widget.accent ?? p.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: p.cardDecoration(accent: accent, raised: _hover),
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Row(children: [
                if (widget.icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: p.iconChip(accent),
                    child: Icon(widget.icon, size: 17, color: accent),
                  ),
                  const SizedBox(width: 11),
                ],
                Expanded(
                  child: Text(
                    widget.title!,
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ]),
              const SizedBox(height: 9),
              Container(height: 3, width: 46, decoration: p.titleRule(accent)),
              const SizedBox(height: 15),
            ],
            widget.child,
          ],
        ),
      ),
    );
  }
}

/// A label above a value, used wherever this screen states one figure.
///
/// The value carries the weight — a settlement screen is read for its numbers,
/// so they are set large enough to be read across a desk, with the label and
/// any qualifier kept quiet beneath.
class SettlementStat extends StatelessWidget {
  const SettlementStat({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
    this.icon,
    this.iconColor,
    this.sharePct,
    this.spark = const [],
  });

  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  /// Draws a thin bar under the figure, 0–100. A share is easier to judge as a
  /// length than as a second number the reader has to compare in their head.
  final double? sharePct;

  /// The period day by day. Drawn as a sparkline under the figure, so a card
  /// says how the month went as well as what it added up to — one total and
  /// one shape in the space a total used to occupy alone.
  final List<double> spark;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final accent = iconColor ?? p.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: p.iconChip(accent),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: p.subText,
                  letterSpacing: 0.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.04,
            color: valueColor ?? p.text,
            // Figures line up column to column, which matters on a page that
            // is read down as much as across.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (spark.isNotEmpty) ...[
          const SizedBox(height: 10),
          SettlementSparkline(values: spark, color: accent),
        ],
        if (sharePct != null) ...[
          const SizedBox(height: 12),
          _ShareBar(pct: sharePct!, color: accent),
        ],
        if (sub != null) ...[
          const SizedBox(height: 9),
          Text(sub!,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: p.mutedText, height: 1.35)),
        ],
      ],
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.pct, required this.color});

  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final v = (pct / 100).clamp(0.0, 1.0);
    return LayoutBuilder(builder: (context, c) {
      return Stack(children: [
        Container(
          height: 6,
          width: c.maxWidth,
          decoration: BoxDecoration(
            color: p.isLight
                ? p.border
                : Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        // Animated so a card that refreshes reads as a value moving rather
        // than as the page flickering.
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          height: 6,
          width: c.maxWidth * v,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
                colors: [color.withOpacity(0.65), color]),
            boxShadow: p.isLight
                ? const []
                : [BoxShadow(color: color.withOpacity(0.5), blurRadius: 7)],
          ),
        ),
      ]);
    });
  }
}

/// Shown wherever a section has nothing to draw, so an unconfigured screen
/// never looks like a broken one.
class SettlementEmpty extends StatelessWidget {
  const SettlementEmpty({
    super.key,
    required this.message,
    this.height = 120,
    this.icon = Icons.hourglass_empty,
  });

  final String message;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: p.mutedText.withOpacity(0.7)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: p.mutedText, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
