import 'package:flutter/material.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

/// Colours and small shared pieces for Solar Settlement.
///
/// Kept in one file so every widget in the module reaches for the same values,
/// and so the module reads as part of the app rather than as its own product.
/// The accent and the panel treatment follow Energy Details — cyan on a deep
/// navy in dark, the theme's own surfaces in light — because a settlement
/// screen that looked like a different application would undermine the numbers
/// on it.
abstract class SettlementColors {
  static const cyan = Color(0xFF00D4FF);
  static const green = Color(0xFF00C853);
  static const amber = Color(0xFFFFC107);
  static const red = Color(0xFFFF4444);

  /// Peak and off-peak keep one colour each across every chart, table and
  /// legend in the module. Two charts disagreeing about which colour means
  /// peak is the fastest way to make a ledger untrustworthy.
  static const peak = amber;
  static const offPeak = green;

  static const darkPanel = Color(0xFF071A2E);
  static const darkCard = Color(0xFF0D1B3E);
  static const darkBorder = Color(0xFF1E2D4D);
}

/// Surface, border and text colours resolved for the viewer's theme.
///
/// Every widget in the module takes its colours from here rather than checking
/// the brightness itself, which is how half a screen ends up styled for the
/// other theme.
class SettlementPalette {
  SettlementPalette(BuildContext context)
      : _t = FlutterFlowTheme.of(context),
        isLight = Theme.of(context).brightness == Brightness.light;

  final FlutterFlowTheme _t;
  final bool isLight;

  Color get page => _t.primaryBackground;
  Color get card => isLight ? _t.secondaryBackground : SettlementColors.darkCard;
  Color get panel => isLight ? _t.secondaryBackground : SettlementColors.darkPanel;
  Color get border =>
      isLight ? _t.alternate : SettlementColors.cyan.withOpacity(0.22);
  Color get accent => isLight ? _t.primary : SettlementColors.cyan;
  Color get text => _t.primaryText;
  Color get subText => _t.secondaryText;
  Color get mutedText => _t.txtTertiary;

  /// The module's standard panel.
  ///
  /// Radius, wash and shadow all follow Energy Details: a card is not a flat
  /// rectangle there, it sits slightly above the page with a faint tint
  /// running through it. Passing an [accent] tints the wash and the glow, which
  /// is what lets a row of cards read as five different readings rather than
  /// five identical boxes.
  BoxDecoration cardDecoration({Color? accent, bool raised = false}) {
    final a = accent ?? this.accent;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: raised ? a.withOpacity(0.55) : border,
          width: raised ? 1.4 : 1),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? [card, Color.alphaBlend(a.withOpacity(0.05), card)]
            : [
                Color.alphaBlend(a.withOpacity(0.07), card),
                Color.alphaBlend(Colors.black.withOpacity(0.18), card),
              ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isLight ? 0.06 : 0.30),
          blurRadius: raised ? 18 : 10,
          offset: const Offset(0, 4),
        ),
        if (!isLight)
          BoxShadow(
            color: a.withOpacity(raised ? 0.16 : 0.07),
            blurRadius: raised ? 22 : 14,
          ),
      ],
    );
  }

  /// A soft tinted square behind an icon, so a heading carries its colour
  /// rather than relying on a bare glyph.
  BoxDecoration iconChip(Color accent) => BoxDecoration(
        color: accent.withOpacity(isLight ? 0.12 : 0.18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withOpacity(0.4)),
      );

  /// The short coloured rule under a card's title. Small, but it is what stops
  /// a column of headings reading as one grey list.
  BoxDecoration titleRule(Color accent) => BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0)],
        ),
      );
}

/// Formatting for the numbers on this screen.
///
/// A settlement is read as money and energy, and both have conventions: money
/// carries two decimals and a thousands separator, energy carries none.
/// Nothing in the module formats its own values, so a figure cannot appear
/// rounded one way in a card and another in the ledger beneath it.
abstract class SettlementFormat {
  static String kwh(double? v, {int decimals = 0}) =>
      v == null ? '—' : '${_thousands(v.toStringAsFixed(decimals))} kWh';

  static String rm(double? v, {int decimals = 2}) =>
      v == null ? '—' : 'RM ${_thousands(v.toStringAsFixed(decimals))}';

  static String rate(double? v, {int decimals = 2}) =>
      v == null || v <= 0 ? '—' : 'RM ${v.toStringAsFixed(decimals)} / kWh';

  static String pct(double? v) =>
      v == null ? '—' : '${v.toStringAsFixed(1)}%';

  static String number(double? v, {int decimals = 0}) =>
      v == null ? '—' : _thousands(v.toStringAsFixed(decimals));

  static String dayLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  static String monthLabel(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _thousands(String s) {
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }
}
