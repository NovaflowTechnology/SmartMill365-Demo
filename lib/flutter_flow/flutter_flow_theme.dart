// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';
SharedPreferences? _prefs;

abstract class FlutterFlowTheme {
  static Future initialize() async => _prefs = await SharedPreferences.getInstance();
  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.dark
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) =>
      mode == ThemeMode.system ? _prefs?.remove(kThemeModeKey) : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? DarkModeTheme() : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;

  // Custom slots
  late Color pageGradientTop;
  late Color cardStroke;
  late Color statusGreen;
  late Color iconSoftBg;
  late Color metricBlue;
  late Color vizGlowCore;
  late Color vizGlowMid;
  late Color vizGlowEdge;
  late Color softBlue1;
  late Color softBlue2;
  late Color flowGrad1;
  late Color flowGrad2;
  late Color cyanAccent2;
  // Text color palette
  late Color txtPrimary;    // #1F2A37 — headings, values
  late Color txtSecondary;  // #4B5563 — body, descriptions
  late Color txtTertiary;   // #6B7280 — supporting text
  late Color txtMuted;      // #9CA3AF — labels, placeholders
  late Color txtSubtle;     // #B0B8C5 — disabled, hints
  late Color txtOnAccent;   // #FFFFFF  — text on colored bg

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;
  TextStyle get displayLarge => typography.displayLarge;
  String get displayMediumFamily => typography.displayMediumFamily;
  TextStyle get displayMedium => typography.displayMedium;
  String get displaySmallFamily => typography.displaySmallFamily;
  TextStyle get displaySmall => typography.displaySmall;
  String get headlineLargeFamily => typography.headlineLargeFamily;
  TextStyle get headlineLarge => typography.headlineLarge;
  String get headlineMediumFamily => typography.headlineMediumFamily;
  TextStyle get headlineMedium => typography.headlineMedium;
  String get headlineSmallFamily => typography.headlineSmallFamily;
  TextStyle get headlineSmall => typography.headlineSmall;
  String get titleLargeFamily => typography.titleLargeFamily;
  TextStyle get titleLarge => typography.titleLarge;
  String get titleMediumFamily => typography.titleMediumFamily;
  TextStyle get titleMedium => typography.titleMedium;
  String get titleSmallFamily => typography.titleSmallFamily;
  TextStyle get titleSmall => typography.titleSmall;
  String get labelLargeFamily => typography.labelLargeFamily;
  TextStyle get labelLarge => typography.labelLarge;
  String get labelMediumFamily => typography.labelMediumFamily;
  TextStyle get labelMedium => typography.labelMedium;
  String get labelSmallFamily => typography.labelSmallFamily;
  TextStyle get labelSmall => typography.labelSmall;
  String get bodyLargeFamily => typography.bodyLargeFamily;
  TextStyle get bodyLarge => typography.bodyLarge;
  String get bodyMediumFamily => typography.bodyMediumFamily;
  TextStyle get bodyMedium => typography.bodyMedium;
  String get bodySmallFamily => typography.bodySmallFamily;
  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography => ThemeTypography(this);
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF2563EB);
  late Color secondary = const Color(0xFF00C6FF);
  late Color tertiary = const Color(0xFFF59E0B);
  late Color alternate = const Color(0xFFDCE3ED);
  late Color primaryText = const Color(0xFF1F2A37);
  late Color secondaryText = const Color(0xFF4B5563);
  late Color primaryBackground = const Color(0xFFEEF2F8);
  late Color secondaryBackground = const Color(0xFFFFFFFF);
  late Color accent1 = const Color(0x4C2563EB);
  late Color accent2 = const Color(0x4E00C6FF);
  late Color accent3 = const Color(0x4DF59E0B);
  late Color accent4 = const Color(0xB3EAF3FF);
  late Color success = const Color(0xFF22C55B);
  late Color warning = const Color(0xFFF59E0B);
  late Color error = const Color(0xFFEF4444);
  late Color info = const Color(0xFF374151);

  // Custom slots
  late Color pageGradientTop = const Color(0xFFF5F7FB);
  late Color cardStroke = const Color(0xFFE3EAF3);
  late Color statusGreen = const Color(0xFF22C55B);
  late Color iconSoftBg = const Color(0xFFEAF3FF);
  late Color metricBlue = const Color(0xFF2563EB);
  // Radial blue glow behind center viz
  late Color vizGlowCore = const Color(0xFFB8D8F8);
  late Color vizGlowMid = const Color(0xFFCDE5FA);
  late Color vizGlowEdge = const Color(0x00EEF2F8);
  // Palette extras
  late Color softBlue1 = const Color(0xFFDCEBFF);
  late Color softBlue2 = const Color(0xFFCFE8FF);
  late Color flowGrad1 = const Color(0xFF6FACFE);
  late Color flowGrad2 = const Color(0xFF38BDF8);
  late Color cyanAccent2 = const Color(0xFF67E8F9);
  // Text color palette
  late Color txtPrimary   = const Color(0xFF1F2A37);
  late Color txtSecondary = const Color(0xFF4B5563);
  late Color txtTertiary  = const Color(0xFF6B7280);
  late Color txtMuted     = const Color(0xFF9CA3AF);
  late Color txtSubtle    = const Color(0xFFB0B8C5);
  late Color txtOnAccent  = const Color(0xFFFFFFFF);
}

abstract class Typography {
  String get displayLargeFamily;
  TextStyle get displayLarge;
  String get displayMediumFamily;
  TextStyle get displayMedium;
  String get displaySmallFamily;
  TextStyle get displaySmall;
  String get headlineLargeFamily;
  TextStyle get headlineLarge;
  String get headlineMediumFamily;
  TextStyle get headlineMedium;
  String get headlineSmallFamily;
  TextStyle get headlineSmall;
  String get titleLargeFamily;
  TextStyle get titleLarge;
  String get titleMediumFamily;
  TextStyle get titleMedium;
  String get titleSmallFamily;
  TextStyle get titleSmall;
  String get labelLargeFamily;
  TextStyle get labelLarge;
  String get labelMediumFamily;
  TextStyle get labelMedium;
  String get labelSmallFamily;
  TextStyle get labelSmall;
  String get bodyLargeFamily;
  TextStyle get bodyLarge;
  String get bodyMediumFamily;
  TextStyle get bodyMedium;
  String get bodySmallFamily;
  TextStyle get bodySmall;
}

class ThemeTypography extends Typography {
  ThemeTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'Poppins';
  TextStyle get displayLarge => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.bold,
        fontSize: 57.0,
      );
  String get displayMediumFamily => 'Poppins';
  TextStyle get displayMedium => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 45.0,
      );
  String get displaySmallFamily => 'Poppins';
  TextStyle get displaySmall => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 36.0,
      );
  String get headlineLargeFamily => 'Poppins';
  TextStyle get headlineLarge => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 32.0,
      );
  String get headlineMediumFamily => 'Poppins';
  TextStyle get headlineMedium => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 28.0,
      );
  String get headlineSmallFamily => 'Poppins';
  TextStyle get headlineSmall => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 20.0,
      );
  String get titleLargeFamily => 'Poppins';
  TextStyle get titleLarge => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 22.0,
      );
  String get titleMediumFamily => 'Poppins';
  TextStyle get titleMedium => GoogleFonts.getFont(
        'Poppins',
        color: theme.info,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
      );
  String get titleSmallFamily => 'Poppins';
  TextStyle get titleSmall => GoogleFonts.getFont(
        'Poppins',
        color: theme.info,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );
  String get labelLargeFamily => 'Poppins';
  TextStyle get labelLarge => GoogleFonts.getFont(
        'Poppins',
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      );
  String get labelMediumFamily => 'Poppins';
  TextStyle get labelMedium => GoogleFonts.getFont(
        'Poppins',
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 12.0,
      );
  String get labelSmallFamily => 'Poppins';
  TextStyle get labelSmall => GoogleFonts.getFont(
        'Poppins',
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 11.0,
      );
  String get bodyLargeFamily => 'Poppins';
  TextStyle get bodyLarge => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontSize: 16.0,
      );
  String get bodyMediumFamily => 'Poppins';
  TextStyle get bodyMedium => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );
  String get bodySmallFamily => 'Poppins';
  TextStyle get bodySmall => GoogleFonts.getFont(
        'Poppins',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
}

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFF31ECFC);
  late Color secondary = const Color(0xFF39D2C0);
  late Color tertiary = const Color(0xFF6D5FED);
  late Color alternate = const Color(0xFF22282F);
  late Color primaryText = const Color(0xFFFFFFFF);
  late Color secondaryText = const Color(0xFF95A1AC);
  late Color primaryBackground = const Color(0xFF0C153D);
  // Deep navy (not purple/indigo) — cards & elevated surfaces.
  late Color secondaryBackground = const Color(0xFF15233F);
  late Color accent1 = const Color(0x4C9489F5);
  late Color accent2 = const Color(0x4E39D2C0);
  late Color accent3 = const Color(0x4D6D5FED);
  late Color accent4 = const Color(0xB31D2428);
  late Color success = const Color(0xFF24A891);
  late Color warning = const Color(0xFFCA6C45);
  late Color error = const Color(0xFFE74852);
  late Color info = const Color(0xFFFFFFFF);

  // Custom slots
  late Color pageGradientTop = const Color(0xFF0C153D);
  late Color cardStroke = const Color(0xFF22282F);
  late Color statusGreen = const Color(0xFF24A891);
  late Color iconSoftBg = const Color(0xFF22282F);
  late Color metricBlue = const Color(0xFF31ECFC);
  late Color vizGlowCore = const Color(0xFF1A3A6E);
  late Color vizGlowMid = const Color(0xFF0F2550);
  late Color vizGlowEdge = const Color(0x000C153D);
  late Color softBlue1 = const Color(0xFF1A2A4A);
  late Color softBlue2 = const Color(0xFF0F1F3A);
  late Color flowGrad1 = const Color(0xFF31ECFC);
  late Color flowGrad2 = const Color(0xFF39D2C0);
  late Color cyanAccent2 = const Color(0xFF39D2C0);
  // Text color palette (dark equivalents)
  late Color txtPrimary   = const Color(0xFFFFFFFF);
  late Color txtSecondary = const Color(0xFFCDD5E0);
  late Color txtTertiary  = const Color(0xFF95A1AC);
  late Color txtMuted     = const Color(0xFF6B7A8D);
  late Color txtSubtle    = const Color(0xFF4A5568);
  late Color txtOnAccent  = const Color(0xFFFFFFFF);
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = true,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
    required TextStyle font,
  }) =>
      useGoogleFonts
          ? GoogleFonts.getFont(
              fontFamily!,
              color: color ?? this.color,
              fontSize: fontSize ?? this.fontSize,
              letterSpacing: letterSpacing ?? this.letterSpacing,
              fontWeight: fontWeight ?? this.fontWeight,
              fontStyle: fontStyle ?? this.fontStyle,
              decoration: decoration,
              height: lineHeight,
              shadows: shadows,
            )
          : copyWith(
              fontFamily: fontFamily,
              color: color,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              decoration: decoration,
              height: lineHeight,
              shadows: shadows,
            );
}
