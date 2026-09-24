import 'package:flutter/material.dart';

/// A thumbnail of the period's shape, drawn beneath a figure.
///
/// A single [CustomPainter] rather than a chart widget: this is thirty points
/// with no axes, no touch handling and no legend, and a real chart here would
/// add a layer per card for nothing. One painter draws the fill and the line in
/// two passes and allocates nothing that outlives the frame — which matters on
/// a page that keeps ten of these alive and refreshes them every load.
class SettlementSparkline extends StatelessWidget {
  const SettlementSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 34,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Fewer than two points is a dot, not a trend, and drawing one would imply
    // a shape the data does not have.
    if (values.length < 2 || !values.any((v) => v > 0)) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var max = 0.0;
    for (final v in values) {
      if (v > max) max = v;
    }
    if (max <= 0) return;

    final dx = size.width / (values.length - 1);
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      // A floor of two pixels keeps a zero day visible as a baseline rather
      // than as a gap the eye reads as missing data.
      final y = size.height -
          (values[i] / max * (size.height - 3)).clamp(0.0, size.height - 3) -
          2;
      final x = dx * i;
      i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || !identical(old.values, values);
}
