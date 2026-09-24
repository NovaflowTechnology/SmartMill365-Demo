import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';

/// "Carbon Flow – From Grid to Emission" card: a Sankey-style flow from a
/// Grid Import node, through weighted block nodes, converging into a Net
/// Emission node. The largest block's flow is highlighted green.
class CarbonFlowDiagram extends StatelessWidget {
  const CarbonFlowDiagram({
    super.key,
    required this.periodLabel,
    required this.gridImportMwh,
    required this.blocks,
    required this.netEmissionTco2e,
    required this.solarOffsetTco2e,
    required this.solarOffsetKwh,
    this.onExpand,
  });

  final String periodLabel;
  final double gridImportMwh;
  final List<CarbonFlowBlock> blocks;
  final double netEmissionTco2e;
  final double solarOffsetTco2e;
  final double solarOffsetKwh;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final largest = blocks.isEmpty ? null : blocks.reduce((a, b) => a.percent >= b.percent ? a : b);

    return DashboardCard(
      title: 'CARBON FLOW – FROM GRID TO EMISSION',
      subtitle: periodLabel,
      trailing: onExpand == null
          ? null
          : InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.open_in_full_rounded, size: 14, color: t.txtMuted),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 208,
            child: blocks.isEmpty
                ? const SizedBox.shrink()
                : LayoutBuilder(builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final nodeW = (w * 0.22).clamp(84.0, 122.0);
                    final blockW = (w * 0.27).clamp(104.0, 140.0);
                    const gap = 10.0;
                    final n = blocks.length;
                    final blockH = ((h - gap * (n - 1)) / n).clamp(40.0, 60.0);
                    final groupH = blockH * n + gap * (n - 1);
                    final blockX = (w - blockW) / 2;
                    final blockRects = [
                      for (var i = 0; i < n; i++) Rect.fromLTWH(blockX, (h - groupH) / 2 + i * (blockH + gap), blockW, blockH),
                    ];
                    final nodeH = math.min(h, 136.0);
                    final leftRect = Rect.fromLTWH(0, (h - nodeH) / 2, nodeW, nodeH);
                    final rightRect = Rect.fromLTWH(w - nodeW, (h - nodeH) / 2, nodeW, nodeH);
                    final hlIndex = largest != null ? blocks.indexOf(largest) : -1;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FlowRibbonPainter(
                              leftRect: leftRect,
                              rightRect: rightRect,
                              blockRects: blockRects,
                              percents: [for (final b in blocks) b.percent],
                              highlightIndex: hlIndex,
                              baseColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF33475E),
                              highlightColor: t.success,
                              isLight: isLight,
                            ),
                          ),
                        ),
                        Positioned.fromRect(
                          rect: leftRect,
                          child: _EndNode(
                            icon: Icons.cell_tower_rounded,
                            label: 'GRID IMPORT',
                            number: _fmt(gridImportMwh),
                            unit: 'kWh',
                            accent: isLight ? t.txtSecondary : Colors.white70,
                            t: t,
                            isLight: isLight,
                          ),
                        ),
                        for (var i = 0; i < n; i++)
                          Positioned.fromRect(
                            rect: blockRects[i],
                            child: _BlockNode(
                              block: blocks[i],
                              highlighted: i == hlIndex,
                              t: t,
                              isLight: isLight,
                            ),
                          ),
                        Positioned.fromRect(
                          rect: rightRect,
                          child: _EndNode(
                            icon: Icons.eco_rounded,
                            label: 'NET EMISSION',
                            number: _fmt(netEmissionTco2e),
                            unit: 'tCO₂e',
                            accent: t.success,
                            t: t,
                            isLight: isLight,
                            highlighted: true,
                          ),
                        ),
                      ],
                    );
                  }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 13, color: t.success),
              const SizedBox(width: 5),
              Text(
                'Solar offset: ',
                style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted),
              ),
              Text(
                '${_fmt(solarOffsetTco2e)} tCO₂e (${_fmt(solarOffsetKwh, decimals: 0)} kWh)',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: t.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v, {int decimals = 1}) {
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }
}

/// Curved Sankey ribbons: grid node → each block → net emission node.
/// Ribbon thickness is proportional to the block's percent share; the
/// highlighted flow is drawn last, in green with a soft glow.
class _FlowRibbonPainter extends CustomPainter {
  const _FlowRibbonPainter({
    required this.leftRect,
    required this.rightRect,
    required this.blockRects,
    required this.percents,
    required this.highlightIndex,
    required this.baseColor,
    required this.highlightColor,
    required this.isLight,
  });

  final Rect leftRect;
  final Rect rightRect;
  final List<Rect> blockRects;
  final List<double> percents;
  final int highlightIndex;
  final Color baseColor;
  final Color highlightColor;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final n = blockRects.length;
    if (n == 0) return;

    final total = percents.fold<double>(0, (s, p) => s + p);
    final shares = [for (final p in percents) total > 0 ? p / total : 1 / n];
    final avail = leftRect.height - 28;
    final thicknesses = [for (final s in shares) (s * avail).clamp(9.0, avail)];
    final sumT = thicknesses.fold<double>(0, (s, v) => s + v);

    // Stacked anchor spans on the end nodes, centred vertically.
    var yL = leftRect.center.dy - sumT / 2;
    var yR = rightRect.center.dy - sumT / 2;
    final segments = <({Rect block, double th, double yLeft, double yRight})>[];
    for (var i = 0; i < n; i++) {
      segments.add((block: blockRects[i], th: thicknesses[i], yLeft: yL, yRight: yR));
      yL += thicknesses[i];
      yR += thicknesses[i];
    }

    void drawFlow(int i, {required bool highlighted}) {
      final seg = segments[i];
      final blockTh = math.min(seg.th, seg.block.height - 12);
      final glow = highlighted
          ? (Paint()
            ..color = highlightColor.withOpacity(0.35)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6))
          : null;

      // Grid node → block.
      final inPath = _ribbon(
        x0: leftRect.right,
        top0: seg.yLeft,
        bot0: seg.yLeft + seg.th,
        x1: seg.block.left,
        top1: seg.block.center.dy - blockTh / 2,
        bot1: seg.block.center.dy + blockTh / 2,
      );
      // Block → net emission node.
      final outPath = _ribbon(
        x0: seg.block.right,
        top0: seg.block.center.dy - blockTh / 2,
        bot0: seg.block.center.dy + blockTh / 2,
        x1: rightRect.left,
        top1: seg.yRight,
        bot1: seg.yRight + seg.th,
      );

      for (final (path, xa, xb) in [(inPath, leftRect.right, seg.block.left), (outPath, seg.block.right, rightRect.left)]) {
        if (glow != null) canvas.drawPath(path, glow);
        final paint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(xa, 0),
            Offset(xb, 0),
            highlighted
                ? [highlightColor.withOpacity(isLight ? 0.45 : 0.55), highlightColor.withOpacity(isLight ? 0.75 : 0.9)]
                : [baseColor.withOpacity(isLight ? 0.30 : 0.55), baseColor.withOpacity(isLight ? 0.45 : 0.8)],
          );
        canvas.drawPath(path, paint);
      }
    }

    for (var i = 0; i < n; i++) {
      if (i != highlightIndex) drawFlow(i, highlighted: false);
    }
    if (highlightIndex >= 0 && highlightIndex < n) {
      drawFlow(highlightIndex, highlighted: true);
    }
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
  bool shouldRepaint(covariant _FlowRibbonPainter old) =>
      old.leftRect != leftRect ||
      old.rightRect != rightRect ||
      old.blockRects != blockRects ||
      old.percents != percents ||
      old.highlightIndex != highlightIndex ||
      old.baseColor != baseColor ||
      old.highlightColor != highlightColor ||
      old.isLight != isLight;
}

class _EndNode extends StatelessWidget {
  const _EndNode({
    required this.icon,
    required this.label,
    required this.number,
    required this.unit,
    required this.accent,
    required this.t,
    required this.isLight,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String number;
  final String unit;
  final Color accent;
  final FlutterFlowTheme t;
  final bool isLight;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? t.success.withOpacity(isLight ? 0.08 : 0.14) : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1A2E)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? t.success.withOpacity(0.4) : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: t.txtMuted),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isLight ? t.txtPrimary : Colors.white),
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtMuted),
          ),
        ],
      ),
    );
  }
}

class _BlockNode extends StatelessWidget {
  const _BlockNode({
    required this.block,
    required this.highlighted,
    required this.t,
    required this.isLight,
  });

  final CarbonFlowBlock block;
  final bool highlighted;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? (isLight ? t.success.withOpacity(0.10) : const Color(0xFF0B2417)) : (isLight ? Colors.white : const Color(0xFF0D1A2E)),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: highlighted ? t.success.withOpacity(0.75) : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: highlighted ? [BoxShadow(color: t.success.withOpacity(0.30), blurRadius: 10, spreadRadius: 0.5)] : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                color: isLight ? t.txtPrimary : Colors.white,
              ),
            ),
            Text(
              '${block.percent.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlighted ? t.success : (isLight ? t.txtPrimary : Colors.white),
              ),
            ),
            Text(
              '${CarbonFlowDiagram._fmt(block.tco2e)} tCO₂e',
              style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtMuted),
            ),
          ],
        ),
      ),
    );
    if (block.deviceId == null || block.deviceId!.isEmpty) return card;
    return Tooltip(
      message: 'Device ID: ${block.deviceId}',
      child: card,
    );
  }
}

/// Shared card chrome used across the Carbon Intelligence Dashboard panels.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.9);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withOpacity(0.03) : Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isLight ? t.txtPrimary : Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
