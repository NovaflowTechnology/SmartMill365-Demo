import 'dart:math';
import 'dart:ui';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/utils/leak_probe.dart';

export 'card_widget.dart';

// ─────────────────────────────────────────────
// CardSizing — shared sizing object
// Semua card yang guna CardWidget dapat sizing
// yang sama, consistent di semua resolusi.
// ─────────────────────────────────────────────
class CardSizing {
  final double w;
  final double h;
  final double pad;
  final double strokeW;
  final double armLen;
  final double headerFs;
  final double titleFs;
  final double labelFs;
  final double valueFs;
  final double bodyFs;
  final double accentW;

  const CardSizing({
    required this.w,
    required this.h,
    required this.pad,
    required this.strokeW,
    required this.armLen,
    required this.headerFs,
    required this.titleFs,
    required this.labelFs,
    required this.valueFs,
    required this.bodyFs,
    required this.accentW,
  });

  factory CardSizing.from(double w, double h) {
    final typBase = min(w, h);
    return CardSizing(
      w: w,
      h: h,
      pad: w * 0.04,
      strokeW: w * 0.002,
      armLen: w * 0.07,
      accentW: w * 0.007,
      headerFs: typBase * 0.072,
      titleFs: typBase * 0.065,
      labelFs: typBase * 0.052,
      valueFs: typBase * 0.058,
      bodyFs: typBase * 0.046,
    );
  }
}

// ─────────────────────────────────────────────
// Painters (private)
// ─────────────────────────────────────────────
class _BorderPainter extends CustomPainter {
  final Color glowColor;
  final double strokeWidth;
  const _BorderPainter({required this.glowColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
        rect,
        Paint()
          ..color = glowColor.withOpacity(0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 4
          // MaskFilter.blur is a GPU blur per draw call. With ~11 cards on a
          // page and two blurred painters each, that is 22 blurs every repaint.
          // Without it the glow is a wider translucent stroke — close enough at
          // a glance, and free.
          ..maskFilter = kEnableCardGlowBlur
              ? const MaskFilter.blur(BlurStyle.normal, 6)
              : null);
    canvas.drawRect(
        rect,
        Paint()
          ..color = glowColor.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter old) =>
      old.glowColor != glowColor || old.strokeWidth != strokeWidth;
}

class _BracketPainter extends CustomPainter {
  final Color glowColor;
  final Color highlightColor;
  final double armLength;
  final double strokeWidth;
  const _BracketPainter({
    required this.glowColor,
    required this.highlightColor,
    required this.armLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final L = armLength;
    for (final c in [
      const _BC(Offset(0, 0), 1, 1),
      _BC(Offset(W, 0), -1, 1),
      _BC(Offset(W, H), -1, -1),
      _BC(Offset(0, H), 1, -1),
    ]) {
      final path = Path()
        ..moveTo(c.o.dx + c.dx * L, c.o.dy)
        ..lineTo(c.o.dx, c.o.dy)
        ..lineTo(c.o.dx, c.o.dy + c.dy * L);
      canvas.drawPath(
          path,
          Paint()
            ..color = glowColor.withOpacity(0.50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth * 4
            ..strokeCap = StrokeCap.square
            ..maskFilter = kEnableCardGlowBlur
                ? const MaskFilter.blur(BlurStyle.normal, 7)
                : null);
      canvas.drawPath(
          path,
          Paint()
            ..color = highlightColor.withOpacity(0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth * 2
            ..strokeCap = StrokeCap.square);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) =>
      old.glowColor != glowColor ||
      old.highlightColor != highlightColor ||
      old.armLength != armLength ||
      old.strokeWidth != strokeWidth;
}

class _BC {
  final Offset o;
  final double dx, dy;
  const _BC(this.o, this.dx, this.dy);
}

// ─────────────────────────────────────────────
// CardWidget — reusable card container
// ─────────────────────────────────────────────
class CardWidget extends StatelessWidget {
  /// Builder receives CardSizing so child can use consistent sizing.
  final Widget Function(BuildContext context, CardSizing sizing) builder;

  /// Override glow/border color. Defaults to FlutterFlowTheme.primary.
  final Color? glowColor;

  /// Blur intensity. Default: 2.
  final double blurSigma;

  /// Extra padding multiplier on top (for header space). Default: 1.6.
  final double topPadMultiplier;

  /// Scale factor applied to corner bracket arm length. Default: 1.0.
  final double armLenMultiplier;

  /// Extra padding multiplier on bottom. Default: 1.0.
  final double bottomPadMultiplier;

  const CardWidget({
    super.key,
    required this.builder,
    this.glowColor,
    this.blurSigma = 2,
    this.topPadMultiplier = 1.6,
    this.armLenMultiplier = 1.0,
    this.bottomPadMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primary = glowColor ?? theme.primary;

    // Light: soft blue highlight strip; Dark: cyan glow strip
    final cHighlight = isLight
        ? const Color(0xFF6FACFE)
        : const Color(0xFF00E5FF);

    // Light: white→F1F5FA card fill; Dark: dark glassmorphism
    final gradColors = isLight
        ? [
            const Color(0xFFFFFFFF),
            const Color(0xFFF1F5FA),
          ]
        : [
            const Color(0xFF0E2040).withOpacity(0.45),
            const Color(0xFF07101F).withOpacity(0.55),
          ];

    final gradBegin = isLight ? Alignment.topCenter : Alignment.topLeft;
    final gradEnd   = isLight ? Alignment.bottomCenter : Alignment.bottomRight;

    return LayoutBuilder(builder: (context, constraints) {
      final sizing = CardSizing.from(
        constraints.maxWidth,
        constraints.maxHeight,
      );

      return ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // BackdropFilter is the most expensive widget in Flutter: it forces
            // a saveLayer, reads back every pixel beneath it, blurs it and
            // composites the result — on every repaint. There are ~11 cards on
            // Energy Details alone, so this dominated the frame cost.
            //
            // It also buys almost nothing here: what sits behind the cards is a
            // flat page background, so the blur is blurring a solid colour.
            if (kEnableCardBackdropBlur)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: const SizedBox.expand(),
                ),
              ),

            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: gradBegin,
                    end: gradEnd,
                    colors: gradColors,
                  ),
                  // Light mode: 1px border from palette
                  border: isLight
                      ? Border.all(color: theme.cardStroke, width: 1)
                      : null,
                  boxShadow: isLight
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7A9CC0).withOpacity(0.10),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
              ),
            ),

            // Top highlight strip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: sizing.pad * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cHighlight.withOpacity(isLight ? 0.12 : 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Border painter (glow) — dark only; light uses BoxDecoration border
            if (!isLight)
              Positioned.fill(
                child: CustomPaint(
                  painter: _BorderPainter(
                    glowColor: primary,
                    strokeWidth: sizing.strokeW,
                  ),
                ),
              ),

            // Bracket corners
            Positioned.fill(
              child: CustomPaint(
                painter: _BracketPainter(
                  glowColor: primary,
                  highlightColor: isLight ? primary : Colors.white,
                  armLength: sizing.armLen * armLenMultiplier,
                  strokeWidth: sizing.strokeW,
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.only(
                left: sizing.pad,
                right: sizing.pad,
                top: sizing.pad * topPadMultiplier,
                bottom: sizing.pad * bottomPadMultiplier,
              ),
              child: builder(context, sizing),
            ),
          ],
        ),
      );
    });
  }
}
