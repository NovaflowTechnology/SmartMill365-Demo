import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Small circular "X% mapped" progress ring used at the top of the settings
/// page, next to a summary line.
class MappingCompletionRing extends StatelessWidget {
  const MappingCompletionRing({super.key, required this.percent, this.size = 46});

  final double percent; // 0..100
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              percent: percent.clamp(0, 100),
              trackColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1A2D4F),
              progressColor: t.primary,
            ),
          ),
          Text(
            '${percent.round()}%',
            style: GoogleFonts.poppins(fontSize: size * 0.26, fontWeight: FontWeight.w800, color: isLight ? t.txtPrimary : Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.percent, required this.trackColor, required this.progressColor});

  final double percent;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final progress = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final sweep = 2 * math.pi * (percent / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, progress);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percent != percent || old.trackColor != trackColor || old.progressColor != progressColor;
}
