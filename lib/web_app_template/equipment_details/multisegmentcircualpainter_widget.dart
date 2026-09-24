import 'package:flutter/material.dart';
import 'dart:math' as math;

class MultiSegmentCircularPainter extends CustomPainter {
  final double availability;
  final double performance;
  final double quality;
  final Color availabilityColor;
  final Color performanceColor;
  final Color qualityColor;
  final Color backgroundColor;

  MultiSegmentCircularPainter({
    required this.availability,
    required this.performance,
    required this.quality,
    required this.availabilityColor,
    required this.performanceColor,
    required this.qualityColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 8.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Each segment takes 120 degrees (2π/3 radians)
    final segmentAngle = 2 * math.pi / 3;
    final startAngle = -math.pi / 2; // Start from top

    // Availability segment (0° to 120°)
    if (availability > 0) {
      final availabilityPaint = Paint()
        ..color = availabilityColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final availabilityRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

      canvas.drawArc(
        availabilityRect,
        startAngle,
        segmentAngle * availability,
        false,
        availabilityPaint,
      );
    }

    // Performance segment (120° to 240°)
    if (performance > 0) {
      final performancePaint = Paint()
        ..color = performanceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final performanceRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

      canvas.drawArc(
        performanceRect,
        startAngle + segmentAngle,
        segmentAngle * performance,
        false,
        performancePaint,
      );
    }

    // Quality segment (240° to 360°)
    if (quality > 0) {
      final qualityPaint = Paint()
        ..color = qualityColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final qualityRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

      canvas.drawArc(
        qualityRect,
        startAngle + (segmentAngle * 2),
        segmentAngle * quality,
        false,
        qualityPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}