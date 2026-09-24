import 'package:flutter/material.dart';

/// One row of the Executive Summary bullet list: a leading icon badge and a
/// sentence with a single colored highlight (e.g. "exceeded contract
/// capacity by **35.5%**.").
class ExecutiveBullet {
  final IconData icon;
  final Color color;
  final String prefix;
  final String highlight;
  final String suffix;

  const ExecutiveBullet({
    required this.icon,
    required this.color,
    required this.prefix,
    required this.highlight,
    this.suffix = '.',
  });
}
