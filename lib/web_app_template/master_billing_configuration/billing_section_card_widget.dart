import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

// Pads reported intrinsic height so IntrinsicHeight parent allocates enough
// space for TextFormField's actual layout height (which exceeds intrinsic).
class _IntrinsicPad extends SingleChildRenderObjectWidget {
  final double extra;
  const _IntrinsicPad({required this.extra, required Widget child})
      : super(child: child);
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIntrinsicPad(extra: extra);
}

class _RenderIntrinsicPad extends RenderProxyBox {
  final double extra;
  _RenderIntrinsicPad({required this.extra});
  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) + extra;
  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) + extra;
}

const double _kPad    = 14.0;
const double _kStroke = 0.7;
const double _kArm    = 18.0;

// ── Painters ──────────────────────────────────────────────────────────────────
class _BorderPainter extends CustomPainter {
  final Color c; final double s;
  const _BorderPainter(this.c, this.s);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(r, Paint()..color=c.withOpacity(0.20)..style=PaintingStyle.stroke..strokeWidth=s*4..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));
    canvas.drawRect(r, Paint()..color=c.withOpacity(0.55)..style=PaintingStyle.stroke..strokeWidth=s);
  }
  @override bool shouldRepaint(covariant _BorderPainter o) => o.c!=c||o.s!=s;
}

class _BracketPainter extends CustomPainter {
  final Color gc, hc; final double arm, s;
  const _BracketPainter(this.gc, this.hc, this.arm, this.s);
  @override
  void paint(Canvas canvas, Size size) {
    final W=size.width; final H=size.height; final L=arm;
    for (final p in [
      [Offset(0,0),1.0,1.0],[Offset(W,0),-1.0,1.0],
      [Offset(W,H),-1.0,-1.0],[Offset(0,H),1.0,-1.0]
    ]) {
      final o=p[0] as Offset; final dx=p[1] as double; final dy=p[2] as double;
      final path = Path()..moveTo(o.dx+dx*L,o.dy)..lineTo(o.dx,o.dy)..lineTo(o.dx,o.dy+dy*L);
      canvas.drawPath(path, Paint()..color=gc.withOpacity(0.50)..style=PaintingStyle.stroke..strokeWidth=s*4..strokeCap=StrokeCap.square..maskFilter=const MaskFilter.blur(BlurStyle.normal,7));
      canvas.drawPath(path, Paint()..color=hc.withOpacity(0.95)..style=PaintingStyle.stroke..strokeWidth=s*2..strokeCap=StrokeCap.square);
    }
  }
  @override bool shouldRepaint(covariant _BracketPainter o) => o.gc!=gc||o.hc!=hc||o.arm!=arm||o.s!=s;
}

// ── BillingSectionCard ─────────────────────────────────────────────────────────
class BillingSectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final List<Widget> children;
  final Color? accentColor;

  const BillingSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme   = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent  = accentColor ?? theme.primary;

    final gradColors = isLight
        ? [const Color(0xFFFFFFFF), const Color(0xFFF1F5FA)]
        : [const Color(0xFF0E2040).withOpacity(0.88), const Color(0xFF07101F).withOpacity(0.92)];

    return LayoutBuilder(builder: (context, constraints) {
      // fillMode = parent gave us a finite height (Expanded row)
      // naturalMode = parent is IntrinsicHeight/scroll (unconstrained height)
      final bool fillMode = constraints.maxHeight.isFinite;

      Widget buildContent() => Padding(
        padding: const EdgeInsets.fromLTRB(_kPad, _kPad * 1.4, _kPad, _kPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                width: 5, height: 14,
                decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(1),
                  boxShadow: isLight ? null : [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 6),
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Expanded(child: Text(title,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryText, letterSpacing: 0.3))),
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent,
                  boxShadow: isLight ? null : [BoxShadow(color: accent.withOpacity(0.7), blurRadius: 4)])),
            ]),
            const SizedBox(height: 6),
            Container(height: 1, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent.withOpacity(isLight ? 0.3 : 0.6), Colors.transparent]))),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

      Widget buildDecorations({required Widget child}) => ClipRect(
        child: Stack(
          fit: fillMode ? StackFit.expand : StackFit.loose,
          children: [
            // ① Background
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isLight ? Alignment.topCenter    : Alignment.topLeft,
                  end:   isLight ? Alignment.bottomCenter : Alignment.bottomRight,
                  colors: gradColors,
                ),
                border: isLight ? Border.all(color: theme.cardStroke, width: 1) : null,
              ),
            )),
            // ② Top highlight
            Positioned(top: 0, left: 0, right: 0, child: Container(
              height: _kPad * 2,
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [(isLight ? const Color(0xFF6FACFE) : const Color(0xFF00E5FF)).withOpacity(isLight ? 0.12 : 0.09), Colors.transparent],
              )),
            )),
            // ③ Glow border — dark only
            if (!isLight) Positioned.fill(child: CustomPaint(painter: _BorderPainter(accent, _kStroke))),
            // ④ Bracket corners
            Positioned.fill(child: CustomPaint(painter: _BracketPainter(accent, isLight ? accent : Colors.white, _kArm, _kStroke))),
            // ⑤ Content
            child,
          ],
        ),
      );

      if (fillMode) {
        // Parent controls height — content is Positioned.fill, fills given height
        return buildDecorations(child: Positioned.fill(child: buildContent()));
      } else {
        // IntrinsicHeight/scroll mode — non-positioned content drives Stack height
        // _IntrinsicPad adds buffer so IntrinsicHeight allocates enough for TextFormFields
        return _IntrinsicPad(
          extra: 48,
          child: buildDecorations(child: buildContent()),
        );
      }
    });
  }
}
