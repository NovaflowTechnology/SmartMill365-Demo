import 'package:flutter/material.dart';

abstract class KwhColors {
  static const cyan      = Color(0xFF00D4FF);
  static const green     = Color(0xFF00C853);
  static const amber     = Color(0xFFFFC107);
  static const red       = Color(0xFFFF4444);
  static const cardBg    = Color(0xFF0D1B3E);
  static const border    = Color(0xFF1E2D4D);
  static const darkInput = Color(0xFF0A1628);
}

abstract class KwhTabs {
  static const overview   = 0;
  static const charts     = 1;
  static const compare    = 2;
  static const secInsight = 3;
  static const addData    = 4;
  static const dataLog    = 5;
  static const labels = [
    'Overview',
    'Charts',
    'Compare',
    '⚡ SEC Insight',
    '+ Add data',
    'Data log',
  ];
}
