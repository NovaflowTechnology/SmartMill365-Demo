import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';

/// "Air Compressor Distribution to Header" Sankey-style diagram: AC1 + AC2
/// flow-contribution ribbons converge into the Header node, which then flows
/// onward into the (not-yet-instrumented) Demand Side node.
class AcDistributionFlowCard extends StatelessWidget {
  const AcDistributionFlowCard({
    super.key,
    required this.compressors,
    this.ac1DeviceId,
    this.ac2DeviceId,
    this.headerFlowDeviceId,
    this.headerPressureDeviceId,
  });

  final List<AcCompressor> compressors;
  // Device IDs configured in Air Compressor Dashboard Setting — shown as a
  // subtitle under each compressor node, null when not yet mapped. The
  // per-node readings are shown as "N/A" until their device ID is mapped.
  final String? ac1DeviceId;
  final String? ac2DeviceId;
  final String? headerFlowDeviceId;
  final String? headerPressureDeviceId;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final ac1 = compressors[0];
    final ac2 = compressors[1];

    return DashboardCard(
      title: 'AIR COMPRESSOR DISTRIBUTION TO HEADER',
      trailing: Tooltip(
        message: 'Compressor power is live where mapped; flow contribution is illustrative until Header Flow telemetry is wired up.',
        child: Icon(Icons.info_outline_rounded, size: 13, color: t.txtSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 520,
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              // Cap the diagram's own width and center it: scaling node
              // positions off the raw card width stretches the Header →
              // Demand ribbon into a huge empty gap on wide screens.
              final contentW = math.min(w, 900.0);
              final offsetX = (w - contentW) / 2;
              final sourceW = (contentW * 0.24).clamp(104.0, 150.0);
              final headerW = (contentW * 0.17).clamp(92.0, 122.0);
              final demandW = (contentW * 0.26).clamp(120.0, 168.0);
              const gap = 14.0;

              final sourceH = (h - gap) / 2;
              final ac1Rect = Rect.fromLTWH(offsetX, 0, sourceW, sourceH);
              final ac2Rect = Rect.fromLTWH(offsetX, sourceH + gap, sourceW, sourceH);

              final headerX = offsetX + contentW * 0.40;
              final headerH = math.min(h * 0.56, 180.0);
              final headerRect = Rect.fromLTWH(headerX, (h - headerH) / 2, headerW, headerH);

              final demandH = math.min(h * 0.62, 190.0);
              final demandRect = Rect.fromLTWH(offsetX + contentW - demandW, (h - demandH) / 2, demandW, demandH);

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CompressorFlowPainter(
                        ac1Rect: ac1Rect,
                        ac2Rect: ac2Rect,
                        headerRect: headerRect,
                        demandRect: demandRect,
                        ac1Share: ac1.flowSharePercent / 100,
                        ac2Share: ac2.flowSharePercent / 100,
                        sourceColor: isLight ? const Color(0xFF22C55B) : const Color(0xFF24A891),
                        pendingColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF33475E),
                        isLight: isLight,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: ac1Rect,
                    child: _CompressorNode(compressor: ac1, deviceId: ac1DeviceId, t: t, isLight: isLight),
                  ),
                  Positioned.fromRect(
                    rect: ac2Rect,
                    child: _CompressorNode(compressor: ac2, deviceId: ac2DeviceId, t: t, isLight: isLight),
                  ),
                  Positioned(
                    left: ac1Rect.right + 4,
                    top: ac1Rect.center.dy - 16,
                    width: headerX - ac1Rect.right - 8,
                    // Flow has no live backend yet — always N/A, regardless
                    // of whether the Device ID is mapped.
                    child: _flowLabel('N/A', t),
                  ),
                  Positioned(
                    left: ac2Rect.right + 4,
                    top: ac2Rect.center.dy - 16,
                    width: headerX - ac2Rect.right - 8,
                    child: _flowLabel('N/A', t),
                  ),
                  Positioned.fromRect(
                    rect: headerRect,
                    child: _HeaderNode(t: t, isLight: isLight),
                  ),
                  Positioned.fromRect(rect: demandRect, child: _DemandSideNode(t: t, isLight: isLight)),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: t.txtSubtle, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                'Power shown is live where mapped; flow distribution is illustrative',
                style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowLabel(String text, FlutterFlowTheme t) => Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w600, color: t.txtMuted),
      );
}

/// Two-hop ribbon painter: AC1 + AC2 (fan-in) → Header, then Header → Demand
/// Side (single, muted — no live split across casts yet).
class _CompressorFlowPainter extends CustomPainter {
  const _CompressorFlowPainter({
    required this.ac1Rect,
    required this.ac2Rect,
    required this.headerRect,
    required this.demandRect,
    required this.ac1Share,
    required this.ac2Share,
    required this.sourceColor,
    required this.pendingColor,
    required this.isLight,
  });

  final Rect ac1Rect;
  final Rect ac2Rect;
  final Rect headerRect;
  final Rect demandRect;
  final double ac1Share;
  final double ac2Share;
  final Color sourceColor;
  final Color pendingColor;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final avail = headerRect.height - 20;
    final th1 = (ac1Share * avail).clamp(10.0, avail);
    final th2 = (ac2Share * avail).clamp(10.0, avail);
    final totalTh = th1 + th2;
    var yHeader = headerRect.center.dy - totalTh / 2;

    void drawRibbon(Rect from, double fromTh, double toTh, double yTo, Color color) {
      final path = _ribbon(
        x0: from.right,
        top0: from.center.dy - fromTh / 2,
        bot0: from.center.dy + fromTh / 2,
        x1: headerRect.left,
        top1: yTo,
        bot1: yTo + toTh,
      );
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(from.right, 0),
          Offset(headerRect.left, 0),
          [color.withOpacity(isLight ? 0.30 : 0.55), color.withOpacity(isLight ? 0.50 : 0.85)],
        );
      canvas.drawPath(path, paint);
    }

    drawRibbon(ac1Rect, math.min(th1, ac1Rect.height - 16), th1, yHeader, sourceColor);
    yHeader += th1;
    drawRibbon(ac2Rect, math.min(th2, ac2Rect.height - 16), th2, yHeader, sourceColor);

    // Header → Demand Side: single muted ribbon (not yet split by cast).
    final outTh = math.min(totalTh, demandRect.height - 24);
    final outPath = _ribbon(
      x0: headerRect.right,
      top0: headerRect.center.dy - outTh / 2,
      bot0: headerRect.center.dy + outTh / 2,
      x1: demandRect.left,
      top1: demandRect.center.dy - outTh / 2,
      bot1: demandRect.center.dy + outTh / 2,
    );
    final outPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(headerRect.right, 0),
        Offset(demandRect.left, 0),
        [pendingColor.withOpacity(isLight ? 0.20 : 0.35), pendingColor.withOpacity(isLight ? 0.12 : 0.22)],
      );
    canvas.drawPath(outPath, outPaint);
  }

  Path _ribbon({
    required double x0,
    required double top0,
    required double bot0,
    required double x1,
    required double top1,
    required double bot1,
  }) {
    final mx = (x0 + x1) / 2;
    return Path()
      ..moveTo(x0, top0)
      ..cubicTo(mx, top0, mx, top1, x1, top1)
      ..lineTo(x1, bot1)
      ..cubicTo(mx, bot1, mx, bot0, x0, bot0)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _CompressorFlowPainter old) =>
      old.ac1Rect != ac1Rect ||
      old.ac2Rect != ac2Rect ||
      old.headerRect != headerRect ||
      old.demandRect != demandRect ||
      old.ac1Share != ac1Share ||
      old.ac2Share != ac2Share ||
      old.isLight != isLight;
}

class _CompressorNode extends StatelessWidget {
  const _CompressorNode({required this.compressor, required this.deviceId, required this.t, required this.isLight});

  final AcCompressor compressor;
  final String? deviceId;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            compressor.id,
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Power', style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtMuted)),
              const SizedBox(width: 6),
              _powerReading(compressor, t, isLight),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Load', style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtMuted)),
              const SizedBox(width: 6),
              Text(
                'N/A', // Load % has no live backend yet.
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: t.success),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: t.txtSubtle, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                'N/A', // No live run-state signal exists yet.
                style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w600, color: t.txtSubtle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Tooltip(
            message: deviceId != null
                ? 'Device ID: $deviceId'
                : 'Not configured — set a Device ID in Air Compressor Dashboard Setting',
            child: Text(
              deviceId ?? 'N/A',
              style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w600, color: deviceId != null ? t.txtSubtle : t.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerReading(AcCompressor compressor, FlutterFlowTheme t, bool isLight) {
    final text = Text(
      compressor.powerValue != null
          ? '${compressor.powerValue!.toStringAsFixed(0)} ${compressor.unit}'
          : (compressor.fieldSupported ? 'N/A' : 'Not available yet'),
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: compressor.fieldSupported ? (isLight ? t.txtPrimary : Colors.white) : t.warning,
      ),
    );
    if (compressor.fieldSupported) return text;
    return Tooltip(
      message: 'The METRIC FIELD mapped in Air Compressor Dashboard Setting has no live source yet',
      child: text,
    );
  }
}

// Header Pressure/Flow have no live backend yet (see AirCompressorDataService)
// — both readings always show "N/A".
class _HeaderNode extends StatelessWidget {
  const _HeaderNode({required this.t, required this.isLight});

  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.primary.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: t.primary.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(Icons.propane_tank_rounded, size: 16, color: t.primary),
          ),
          const SizedBox(height: 6),
          Text(
            'HEADER',
            style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: t.txtMuted),
          ),
          const SizedBox(height: 4),
          Text('Pressure', style: GoogleFonts.poppins(fontSize: 7.5, color: t.txtSubtle)),
          Text(
            'N/A',
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: isLight ? t.txtPrimary : Colors.white),
          ),
          const SizedBox(height: 3),
          Text('Flow', style: GoogleFonts.poppins(fontSize: 7.5, color: t.txtSubtle)),
          Text(
            'N/A',
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: isLight ? t.txtPrimary : Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DemandSideNode extends StatelessWidget {
  const _DemandSideNode({required this.t, required this.isLight});

  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return DottedBorderBox(
      color: amber.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DEMAND SIDE',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: t.txtMuted),
            ),
            Text('(7 CAST)', style: GoogleFonts.poppins(fontSize: 7.5, color: t.txtSubtle)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: amber.withOpacity(isLight ? 0.12 : 0.18), borderRadius: BorderRadius.circular(5)),
              child: Text('SPEC PENDING', style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w700, color: amber)),
            ),
            const SizedBox(height: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.txtSubtle, width: 1.4, style: BorderStyle.solid),
              ),
              alignment: Alignment.center,
              child: Text('--', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: t.txtSubtle)),
            ),
            const SizedBox(height: 6),
            Text(
              'Data not available\nin Phase 1',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 7.5, color: t.txtSubtle, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dashed-border rounded box (Flutter has no built-in dashed border).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: color),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) => old.color != color;
}
