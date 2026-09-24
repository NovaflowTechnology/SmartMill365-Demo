import 'package:flutter/material.dart';

/// Cyberpunk corner bracket painter — mirrors the energy overview card aesthetic.
class CyberpunkBracketPainter extends CustomPainter {
  final Color  color;
  final double armLength;

  const CyberpunkBracketPainter({
    required this.color,
    required this.armLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W  = size.width;
    final H  = size.height;
    final L  = armLength;
    // Clamp so narrow cards (summary) and wide cards (breakdown/header)
    // all render at the same visual weight.
    final sw = (W * 0.002).clamp(0.0, 1.2);
    for (final c in [
      const _BC(Offset(0, 0),  1,  1),
      _BC(Offset(W, 0), -1,  1),
      _BC(Offset(W, H), -1, -1),
      _BC(Offset(0, H),  1, -1),
    ]) {
      final path = Path()
        ..moveTo(c.o.dx + c.dx * L, c.o.dy)
        ..lineTo(c.o.dx, c.o.dy)
        ..lineTo(c.o.dx, c.o.dy + c.dy * L);
      canvas.drawPath(path, Paint()
        ..color       = color.withOpacity(0.50)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw * 4
        ..strokeCap   = StrokeCap.square
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawPath(path, Paint()
        ..color       = Colors.white.withOpacity(0.95)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw * 2
        ..strokeCap   = StrokeCap.square);
    }
  }

  @override
  bool shouldRepaint(CyberpunkBracketPainter o) =>
      o.color != color || o.armLength != armLength;
}

class _BC {
  final Offset o;
  final double dx, dy;
  const _BC(this.o, this.dx, this.dy);
}

/// Drop-in Stack overlay — place as last child of a Stack to draw corner
/// brackets over any card without interfering with hit-testing.
class CyberpunkBrackets extends StatelessWidget {
  final Color  color;
  final double armLength;

  const CyberpunkBrackets({
    super.key,
    required this.color,
    required this.armLength,
  });

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: CyberpunkBracketPainter(
              color:     color,
              armLength: armLength,
            ),
          ),
        ),
      );
}
