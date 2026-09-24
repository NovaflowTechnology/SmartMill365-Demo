import 'package:flutter/material.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart' show CardSizing;
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

/// Flat, bordered panel used throughout the MD Insight Report — a plain
/// dark box with a thin border, matching the report design mock exactly
/// (no glow/bracket/glass chrome from the app's default CardWidget).
///
/// Keeps the same `builder(context, sizing)` shape as CardWidget so section
/// widgets that relied on [CardSizing] for responsive font sizes didn't need
/// to change.
class ReportPanel extends StatelessWidget {
  final Widget Function(BuildContext context, CardSizing sizing) builder;
  final EdgeInsetsGeometry padding;

  const ReportPanel({
    super.key,
    required this.builder,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(builder: (context, constraints) {
      final sizing = CardSizing.from(
        constraints.maxWidth,
        constraints.maxHeight.isFinite ? constraints.maxHeight : constraints.maxWidth * 0.6,
      );
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: isLight ? theme.secondaryBackground : const Color(0xFF0B1B33),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isLight ? theme.alternate : Colors.white.withOpacity(0.12)),
        ),
        child: builder(context, sizing),
      );
    });
  }
}
