import 'package:flutter/foundation.dart';

class ParseDoubleValue {
  static double parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Error parsing double value: $value');
        return 0.0;
      }
    }
    return 0.0;
  }
}