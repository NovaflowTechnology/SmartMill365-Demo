import 'package:flutter/material.dart';

/// Shared semantic colors for the MD Insight Report — kept in one place so
/// every section (summary cards, executive summary, gauge, charts, table)
/// stays visually consistent.
class MdReportColors {
  const MdReportColors._();

  static const Color red = Color(0xFFEF4444);
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color teal = Color(0xFF14B8A6);

  static const List<Color> donutSeries = [red, Color(0xFFFDE047), blue, teal];
}
