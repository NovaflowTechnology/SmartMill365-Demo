import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class SankeyNode {
  final String id;
  final String label;
  final double value;
  final Color color;
  final int column; // 0 = leftmost
  final String unit;
  final String tierLabel;
  final String mappingLabel;
  final List<String> extraPills;

  const SankeyNode({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
    required this.column,
    this.unit = 'kW',
    this.tierLabel = '',
    this.mappingLabel = '',
    this.extraPills = const [],
  });
}

class SankeyLink {
  final String sourceId;
  final String targetId;
  final double value;

  const SankeyLink({
    required this.sourceId,
    required this.targetId,
    required this.value,
  });
}

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

class _NodeRect {
  final SankeyNode node;
  Rect rect;
  double sourceUsed = 0; // px consumed by outgoing ribbons so far
  double targetUsed = 0; // px consumed by incoming ribbons so far

  _NodeRect(this.node, this.rect);
}

// ---------------------------------------------------------------------------
// Value formatter & Colors
// ---------------------------------------------------------------------------

Color getMappingColor(String text, Color defaultColor) {
  final lower = text.toLowerCase();
  if (lower.contains('peak demand')) return Colors.orangeAccent;
  if (lower.contains('active power') || lower.contains('p(kw)'))
    return const Color(0xFF00C6FF);
  if (lower.contains('energy delivered') || lower.contains('edel'))
    return Colors.greenAccent;
  if (lower.contains('energy received') || lower.contains('erec'))
    return Colors.redAccent;
  if (lower.contains('apparent energy') || lower.contains('eapp'))
    return Colors.purpleAccent;
  if (lower.contains('monthly usage')) return Colors.tealAccent;
  if (lower.contains('yearly usage')) return Colors.indigoAccent;
  if (lower.contains('daily usage')) return Colors.cyanAccent;
  return const Color(0xFF607D8B); // Grey Blue fallback
}

Color _softColor(Color c, {double t = 0.55}) {
  // Blend toward white to get SankeyMATIC-like pastel ribbons.
  return Color.lerp(c, Colors.white, t) ?? c;
}

String _fmtVal(double v, String unit) {
  final isEnergy = unit == 'kWh' || unit == 'kVAh' || unit == 'kVArh';
  if (isEnergy) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(2)} M${unit.substring(1)}';
    }
    return '${v.toStringAsFixed(1)} $unit';
  }
  // Power
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)} MWh';
  return '${v.toStringAsFixed(1)} kWh';
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class SankeyPainter extends CustomPainter {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final String title;
  final String subtitle;
  /// Light text + subtle panels when the chart sits on a dark card (matches reference).
  final bool useLightLabelStyle;

  const SankeyPainter({
    required this.nodes,
    required this.links,
    required this.title,
    required this.subtitle,
    this.useLightLabelStyle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    try {
      _doPaint(canvas, size);
    } catch (e, stack) {
      final p = Paint()..color = Colors.red.withOpacity(0.3);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
      final tp = TextPainter(
         text: TextSpan(text: 'Sankey Error: $e\n$stack', style: const TextStyle(color: Colors.white, fontSize: 13)),
         textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      tp.paint(canvas, const Offset(10, 10));
    }
  }

  void _doPaint(Canvas canvas, Size size) {
    // Visual tuning for "band-like" Sankey look (matches reference):
    // - slightly wider bars
    // - tighter vertical spacing
    // - higher minimum node height so many small flows stay readable
    // Plan v2 §4: sleek 8 px bars; ribbons carry the visual weight.
    const double nodeWidth = 6.0;
    const double topPad = 20.0;
    const double botPad = 24.0;

    // ── 1. Group nodes by column ─────────────────────────────────────────
    final Map<int, List<SankeyNode>> byCol = {};
    for (final n in nodes) {
      byCol.putIfAbsent(n.column, () => []).add(n);
    }
    // Sort each column by their order (stable insertion order from service)
    final cols = byCol.keys.toList()..sort();
    final int colCount = cols.last + 1;

    // ── 1b. Reduce ribbon crossings by ordering nodes (topology-driven) ────
    // Crossings are mostly caused by poor vertical ordering between adjacent
    // columns. We combine:
    // - barycenter sweeps (standard Sankey heuristic)
    // - plus a strict grouping for the last column so children of each parent
    //   stay contiguous (prevents "braiding" regardless of settings order).
    final nodeById = <String, SankeyNode>{for (final n in nodes) n.id: n};
    final out = <String, List<String>>{}; // adjacent forward: col -> col+1
    final inc = <String, List<String>>{}; // adjacent backward: col <- col-1
    for (final l in links) {
      final s = nodeById[l.sourceId];
      final t = nodeById[l.targetId];
      if (s == null || t == null) continue;
      // Only consider forward edges to the next column for ordering.
      if (t.column != s.column + 1) continue;
      out.putIfAbsent(s.id, () => <String>[]).add(t.id);
      inc.putIfAbsent(t.id, () => <String>[]).add(s.id);
    }

    double? barycenter(
      SankeyNode n,
      Map<String, int> posMap,
      List<String>? neighbors,
    ) {
      if (neighbors == null || neighbors.isEmpty) return null;
      double sum = 0;
      int cnt = 0;
      for (final id in neighbors) {
        final p = posMap[id];
        if (p == null) continue;
        sum += p.toDouble();
        cnt++;
      }
      if (cnt == 0) return null;
      return sum / cnt;
    }

    // Initialize position maps from current order.
    Map<int, Map<String, int>> colPos() {
      final map = <int, Map<String, int>>{};
      for (final c in cols) {
        final list = byCol[c] ?? const <SankeyNode>[];
        map[c] = {for (int i = 0; i < list.length; i++) list[i].id: i};
      }
      return map;
    }

    // Do a few sweeps left→right and right→left.
    for (int iter = 0; iter < 3; iter++) {
      // Left → Right: order column c by targets in c+1
      final pos = colPos();
      for (final c in cols) {
        final nextC = c + 1;
        if (!byCol.containsKey(nextC)) continue;
        final nextPos = pos[nextC] ?? const <String, int>{};
        final list = byCol[c]!;
        list.sort((a, b) {
          final ba = barycenter(a, nextPos, out[a.id]);
          final bb = barycenter(b, nextPos, out[b.id]);
          if (ba == null && bb == null) return 0;
          if (ba == null) return 1;
          if (bb == null) return -1;
          return ba.compareTo(bb);
        });
      }

      // Right → Left: order column c by sources in c-1
      final pos2 = colPos();
      for (final c in cols.reversed) {
        final prevC = c - 1;
        if (!byCol.containsKey(prevC)) continue;
        final prevPos = pos2[prevC] ?? const <String, int>{};
        final list = byCol[c]!;
        list.sort((a, b) {
          final ba = barycenter(a, prevPos, inc[a.id]);
          final bb = barycenter(b, prevPos, inc[b.id]);
          if (ba == null && bb == null) return 0;
          if (ba == null) return 1;
          if (bb == null) return -1;
          return ba.compareTo(bb);
        });
      }
    }

    // ── Primary-ancestor grouping (prevents cross-source ribbon crossings) ──
    // Each non-source node is assigned the col-0 ancestor it descends from.
    // We then sort every downstream column by that ancestor's position in col 0,
    // so MSB's subtree stays above I_001's subtree throughout all columns.
    final Map<String, String> primaryAnc = {};
    final col0List = byCol[cols.first] ?? <SankeyNode>[];
    for (final n in col0List) primaryAnc[n.id] = n.id;

    // Propagate ancestor forward column by column.
    for (final c in cols.skip(1)) {
      for (final n in byCol[c] ?? <SankeyNode>[]) {
        final parents = inc[n.id] ?? const <String>[];
        final counts = <String, int>{};
        for (final pid in parents) {
          final anc = primaryAnc[pid];
          if (anc != null) counts[anc] = (counts[anc] ?? 0) + 1;
        }
        if (counts.isNotEmpty) {
          primaryAnc[n.id] =
              counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        }
      }
    }

    // Build a stable index for col-0 ancestors.
    final col0AncPos = <String, int>{
      for (int i = 0; i < col0List.length; i++) col0List[i].id: i,
    };

    // Re-sort every non-source column: primary ancestor first, barycenter second.
    final finalPos = colPos();
    for (final c in cols.skip(1)) {
      final prevPos = finalPos[c - 1] ?? const <String, int>{};
      byCol[c]!.sort((a, b) {
        final pa = col0AncPos[primaryAnc[a.id] ?? ''] ?? 0;
        final pb = col0AncPos[primaryAnc[b.id] ?? ''] ?? 0;
        if (pa != pb) return pa.compareTo(pb);
        // Within same ancestor group: keep barycenter order.
        final ba = barycenter(a, prevPos, inc[a.id]);
        final bb = barycenter(b, prevPos, inc[b.id]);
        if (ba == null && bb == null) return 0;
        if (ba == null) return 1;
        if (bb == null) return -1;
        return ba.compareTo(bb);
      });
    }

    // ── 2. Column x positions ────────────────────────────────────────────
    // Reserve 160 px on the right edge for the last column's labels.
    // This keeps labels inside the viewport without requiring scrolling.
    const double leftPad = 24.0;
    const double rightLabelPad = 170.0;
    final double usableW = size.width - leftPad - nodeWidth - rightLabelPad;
    double colX(int col) =>
        colCount == 1 ? leftPad : leftPad + (col / (colCount - 1)) * usableW;

    // ── 2b. Column Scaling ──────────────────────────────────────────────────
    // Source (col 0) is compressed (0.30x) so one input bar stays visually
    // thin. All downstream columns use a flat 1.0x so the diagram grows by
    // node count, not artificial stretching.
    double colScale(int col) {
      if (col == 0) return 0.30;
      return 1.0;
    }

    // ── 3. Layout — column-based independent centering (plan v6 §2) ──────────
    final double chartH = size.height - topPad - botPad;
    final Map<String, _NodeRect> nodeRects = {};

    const double minH  = 2.0;   // minimum bar / ribbon px
    const double kGap  = 12.0;  // gap between nodes in the same column
    final double maxNodeH = chartH * 0.56;

    // ── pxPerUnit: dominant-column calibration (plan v6) ──────────────────
    // Calibration ensures the tallest column fits the canvas exactly.
    double pxPerUnit;
    {
      double maxScaledSum = 0;
      int dominantCol = cols.isNotEmpty ? cols.first : 0;
      for (final c in cols) {
        final nodesInCol = byCol[c] ?? [];
        final double s = nodesInCol.fold(0.0, (acc, n) => acc + n.value);
        final double scaled = s * colScale(c);
        if (scaled > maxScaledSum) {
          maxScaledSum = scaled;
          dominantCol = c;
        }
      }
      
      final domNodes = byCol[dominantCol] ?? [];
      final int N = domNodes.length;
      final double totalVal = domNodes.fold(0.0, (s, n) => s + n.value);
      final double usedPx = N * minH + max(0, N - 1) * kGap;
      final double available = chartH - usedPx;
      
      pxPerUnit = (totalVal > 0 && available > 0)
          ? (available / (totalVal * colScale(dominantCol))).clamp(0.0, 500.0)
          : 1.0;
    }

    // ── Visual heights ────────────────────────────────────────────────────
    // Every node height is proportional to its value. Min 2.0px.
    final Map<String, double> visualHeight = {
      for (final n in nodes)
        n.id: (n.value * pxPerUnit * colScale(n.column)).clamp(minH, maxNodeH).toDouble(),
    };

    // ── Independent per-column centering ──────────────────────────────────
    // This creates the symmetrical fan-out (Wedge) effect.
    for (final c in cols) {
      final colNodes = byCol[c] ?? [];
      double colTotalH = colNodes.fold(0.0, (s, n) => s + visualHeight[n.id]!);
      if (colNodes.length > 1) colTotalH += (colNodes.length - 1) * kGap;

      double currentY = topPad + max(0.0, (chartH - colTotalH) / 2);
      for (final n in colNodes) {
        final h = visualHeight[n.id]!;
        nodeRects[n.id] = _NodeRect(n, Rect.fromLTWH(colX(c), currentY, nodeWidth, h));
        currentY += h + kGap;
      }
    }

    // ── 4. Pre-compute ribbon heights ──────────────────────────────────────
    // Source side: proportional to node.value so unaccounted gap is preserved.
    // Target side: proportional to target node.value.
    final Map<SankeyLink, double> linkHSrc = {};
    final Map<SankeyLink, double> linkHTgt = {};
    for (final lk in links) {
      final src = nodeRects[lk.sourceId];
      final tgt = nodeRects[lk.targetId];
      if (src == null || tgt == null) continue;
      final double srcVal = src.node.value > 0 ? src.node.value : 1.0;
      linkHSrc[lk] = max(2.0, (lk.value / srcVal) * src.rect.height);
      final double tgtVal = tgt.node.value > 0 ? tgt.node.value : 1.0;
      linkHTgt[lk] = max(2.0, (lk.value / tgtVal) * tgt.rect.height);
    }

    // ── 5. Stable lane allocation to avoid crossings ──────────────────────
    final Map<SankeyLink, double> srcOffset = {};
    final Map<SankeyLink, double> tgtOffset = {};

    final outgoing = <String, List<SankeyLink>>{};
    final incoming = <String, List<SankeyLink>>{};
    for (final lk in links) {
      if (!linkHTgt.containsKey(lk)) continue;
      outgoing.putIfAbsent(lk.sourceId, () => <SankeyLink>[]).add(lk);
      incoming.putIfAbsent(lk.targetId, () => <SankeyLink>[]).add(lk);
    }

    for (final e in outgoing.entries) {
      final src = nodeRects[e.key];
      if (src == null) continue;
      final list = e.value;
      list.sort((a, b) => (nodeRects[a.targetId]?.rect.center.dy ?? 0).compareTo(nodeRects[b.targetId]?.rect.center.dy ?? 0));
      double off = 0;
      for (final lk in list) {
        srcOffset[lk] = off;
        off += linkHSrc[lk]!;
      }
    }

    for (final e in incoming.entries) {
      final tgt = nodeRects[e.key];
      if (tgt == null) continue;
      final list = e.value;
      list.sort((a, b) => (nodeRects[a.sourceId]?.rect.center.dy ?? 0).compareTo(nodeRects[b.sourceId]?.rect.center.dy ?? 0));
      double off = 0;
      for (final lk in list) {
        tgtOffset[lk] = off;
        off += linkHTgt[lk]!;
      }
    }

    // ── 6. Draw tapered ribbons ───────────────────────────────────────────
    for (final lk in links) {
      final src = nodeRects[lk.sourceId];
      final tgt = nodeRects[lk.targetId];
      final hSrc = linkHSrc[lk];
      final hTgt = linkHTgt[lk];
      if (src == null || tgt == null || hSrc == null || hTgt == null) continue;

      final double safeHSrc = hSrc.clamp(0.0, max(1.0, src.rect.height));
      final double safeHTgt = hTgt.clamp(0.0, max(1.0, tgt.rect.height));

      final double y1 = (src.rect.top + (srcOffset[lk] ?? 0))
          .clamp(src.rect.top, max(src.rect.top, src.rect.bottom - safeHSrc));
      final double y2 = (tgt.rect.top + (tgtOffset[lk] ?? 0))
          .clamp(tgt.rect.top, max(tgt.rect.top, tgt.rect.bottom - safeHTgt));
      final x1 = src.rect.right;
      final x2 = tgt.rect.left;
      final cpX1 = x1 + (x2 - x1) * 0.38;
      final cpX2 = x1 + (x2 - x1) * 0.62;

      final Path path = Path()
        ..moveTo(x1, y1)
        ..cubicTo(cpX1, y1, cpX2, y2, x2, y2)
        ..lineTo(x2, y2 + safeHTgt)
        ..cubicTo(cpX2, y2 + safeHTgt, cpX1, y1 + safeHSrc, x1, y1 + safeHSrc)
        ..close();

      // Proportional thickness logic ensured by parent = sum(children).
      final maxNodeVal = max(1.0, nodes.map((n) => n.value).reduce(max));
      final normalized = (lk.value / maxNodeVal).clamp(0.0, 1.0);
      final linkColor = _softColor(src.node.color, t: 0.45 + (1.0 - normalized) * 0.25);
      final double opacity = 0.86;
      canvas.drawPath(
        path, 
        Paint()
          ..color = linkColor.withOpacity(opacity)
          ..style = PaintingStyle.fill
      );
    }

    // ── 7b. Loss ribbon removed (plan v5) ────────────────────────────────
    // effVal for every intermediate node = sum(children.effVal), so ribbons
    // always fill the source bar exactly — no dark gap, no loss needed.

    // ── 8. Draw node bars ─────────────────────────────────────────────────
    for (final nr in nodeRects.values) {
      canvas.drawRect(nr.rect, Paint()..color = nr.node.color.withOpacity(0.95));
    }

    // ── 9. Draw labels ──────────────────────────────────────────────────────
    // Rightmost column labels go RIGHT into the reserved 160px zone (in-viewport).
    const double rightLabelMaxW = 150.0;
    final double labelMaxW =
        (colCount > 1 ? usableW / (colCount - 1) : usableW) - nodeWidth - 10;

    // ── 9a. Label placement — push-down strategy ─────────────────────────────
    // For every column, walk nodes top-to-bottom. Each label is placed at:
    //   max(bar-center-offset, nextAvailableY)
    // This "pushes" overlapping labels downward instead of hiding them, so
    // every node always gets a label — including 0-value nodes.
    const double kLabelGap = 3.0;
    const double kLabelLineH = 12.0; // per text line
    const double kPillH = 11.0;      // per value pill

    // Pass 1: compute the y position each label will actually be drawn at.
    final Map<String, double> labelTopY = {};
    final Map<int, double> nextYForCol = {
      for (final c in cols) c: double.negativeInfinity,
    };

    final List<_NodeRect> sortedNRs = nodeRects.values.toList()
      ..sort((a, b) => a.rect.top.compareTo(b.rect.top));

    for (final nr in sortedNRs) {
      final int c = nr.node.column;
      final int pillCount =
          (nr.node.mappingLabel.isNotEmpty ? 1 : 0) + nr.node.extraPills.length;
      final double estH = kLabelLineH + pillCount * (kPillH + 2);

      // Preferred y: vertically centered on bar.
      final double preferred = nr.rect.center.dy - estH / 2;
      // Actual y: push down if it would overlap the previous label.
      final double actual =
          max(preferred, nextYForCol[c]!);

      // Skip only if the label is entirely below the canvas.
      if (actual > size.height + 10) continue;

      labelTopY[nr.node.id] = actual;
      nextYForCol[c] = actual + estH + kLabelGap;
    }

    // Pass 2: paint labels using the pre-computed y positions.
    for (final nr in nodeRects.values) {
      final n = nr.node;
      if (!labelTopY.containsKey(n.id)) continue;

      final String lbl = n.label.trim();
      final bool hasMapping = n.mappingLabel.isNotEmpty;
      final bool hasExtra = n.extraPills.isNotEmpty;
      if (lbl.isEmpty && !hasMapping && !hasExtra) continue;

      final bool isRightMost = n.column == cols.last;
      final bool isLeftMost = n.column == cols.first;
      final double bx =
          isLeftMost ? nr.rect.left - 150 : nr.rect.right + 6;
      final double effectiveLabelMaxW =
          isRightMost ? rightLabelMaxW : max(50.0, labelMaxW);
      final valStr = _fmtVal(n.value, n.unit);

      // Build text painters.
      final mainClr =
          useLightLabelStyle ? const Color(0xFFF8FAFC) : const Color(0xFF1F2937);
      final pillValClr =
          useLightLabelStyle ? const Color(0xFFE2E8F0) : const Color(0xFF374151);
      final extraClr =
          useLightLabelStyle ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);

      final mainTp = TextPainter(
        text: TextSpan(
          text: n.label,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: mainClr,
            height: 1.15,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: effectiveLabelMaxW);

      final List<({TextPainter tp, Color color})> pillData = [];

      if (hasMapping) {
        final mc = getMappingColor(n.mappingLabel, n.color);
        pillData.add((
          color: mc,
          tp: TextPainter(
            text: TextSpan(
              text: valStr,
              style: GoogleFonts.poppins(
                fontSize: 8.0,
                fontWeight: FontWeight.w500,
                color: pillValClr,
                height: 1.1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: effectiveLabelMaxW),
        ));
      }

      for (final pillTxt in n.extraPills) {
        final mc = getMappingColor(pillTxt, n.color);
        pillData.add((
          color: mc,
          tp: TextPainter(
            text: TextSpan(
              text: pillTxt.split(':').last.trim(),
              style: GoogleFonts.poppins(
                fontSize: 7.8,
                fontWeight: FontWeight.w500,
                color: extraClr,
                height: 1.1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: effectiveLabelMaxW),
        ));
      }

      double totalH = mainTp.height;
      for (final pd in pillData) totalH += pd.tp.height + 2;

      final double ty = labelTopY[n.id]!;

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

      // Background panel for middle columns (readable on dark or light cards).
      if (!isLeftMost && !isRightMost) {
        final double pillMaxW = pillData.isEmpty
            ? 0.0
            : pillData.map((p) => p.tp.width).reduce(max).toDouble();
        final double boxW =
            max(mainTp.width, pillMaxW).toDouble() + 10.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bx - 4, ty - 2, boxW, totalH + 4),
            const Radius.circular(2),
          ),
          Paint()
            ..color = useLightLabelStyle
                ? const Color(0xFF0F172A).withOpacity(0.72)
                : Colors.white.withOpacity(0.88),
        );
      }

      mainTp.paint(canvas, Offset(bx, ty));
      double curY = ty + mainTp.height + 2;
      for (final pd in pillData) {
        pd.tp.paint(canvas, Offset(bx, curY));
        curY += pd.tp.height + 2;
      }

      canvas.restore();
    }


    // Title is now rendered as a Flutter widget above the chart.
  }

  @override
  bool shouldRepaint(covariant SankeyPainter old) =>
      old.nodes != nodes ||
      old.links != links ||
      old.title != title ||
      old.useLightLabelStyle != useLightLabelStyle;
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class SankeyChartWidget extends StatelessWidget {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final String title;
  final String subtitle;
  /// Optional fixed height. If null, fills parent constraints.
  final double? height;

  const SankeyChartWidget({
    super.key,
    required this.nodes,
    required this.links,
    this.title = 'Facility Power Distribution',
    this.subtitle = '',
    this.height,
  });

  double _estimateNeededHeight() {
    if (nodes.isEmpty) return 520;
    // Keep in sync with painter: minH=2, kGap=10, colScale mirrors _doPaint.
    const double minH = 2.0;
    const double topPad = 32.0;
    const double botPad = 48.0;
    const double kGap = 10.0;
    double colScaleEst(int col) {
      if (col == 0) return 0.30;
      return 1.0;
    }

    final byCol = <int, List<SankeyNode>>{};
    for (final n in nodes) byCol.putIfAbsent(n.column, () => []).add(n);

    double maxRequired = 0;
    for (final entry in byCol.entries) {
      final scale = colScaleEst(entry.key);
      final n = entry.value.length;
      final colH = topPad + botPad + (n * minH * scale) + ((n - 1) * kGap);
      if (colH > maxRequired) maxRequired = colH;
    }
    return maxRequired <= 0 ? 520 : maxRequired + 60;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportH =
            height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 520);
        final viewportW =
            constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;

        // If there are too many nodes to pack within the viewport height (due
        // to min bar height + padding), give the painter a larger canvas and
        // rely on pan/zoom to explore the full diagram.
        final neededH = _estimateNeededHeight();
        final paintH = max(viewportH, neededH);

        // chartW: always use actual layout width (no extra canvas needed).
        final double chartW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (viewportW.isFinite ? viewportW : 800);

        // Reserve pixel budget for the Flutter header (~40px) and legends (~80px)
        const double kHeaderH = 40.0;
        const double kLegendH = 80.0;
        final double actualH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : viewportH;
        final double chartSizedBoxH =
            max(200.0, actualH - kHeaderH - kLegendH);

        final lightLabels =
            Theme.of(context).brightness == Brightness.dark;
        final chart = SizedBox(
          width: chartW,
          height: paintH,
          child: CustomPaint(
            painter: SankeyPainter(
              nodes: nodes,
              links: links,
              title: title,
              subtitle: subtitle,
              useLightLabelStyle: lightLabels,
            ),
            child: const SizedBox.expand(),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            _buildHeader(context),

            // ── Chart ─────────────────────────────────────────────────────
            SizedBox(
              width: viewportW,
              height: chartSizedBoxH,
              child: ClipRect(
                child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(80),
                  minScale: 0.30,
                  maxScale: 2.8,
                  child: chart,
                ),
              ),
            ),

            // ── Legend ────────────────────────────────────────────────────
            if (nodes.isNotEmpty) ...[
              Builder(builder: (ctx) {
                final lastCol = nodes.map((n) => n.column).reduce(max);
                final tierNodes =
                    nodes.where((n) => n.column < lastCol).toList();

                // Extract all unique data mapping labels (Active Power, Peak Demand, etc.)
                final mappingLabels = <String>{};
                for (final n in nodes) {
                  if (n.mappingLabel.isNotEmpty) {
                    mappingLabels.add(n.mappingLabel);
                  }
                  for (final p in n.extraPills) {
                    // Extract just the label if formatted as "Label: Value"
                    final label = p.split(':').first.trim();
                    mappingLabels.add(label);
                  }
                }

                return Column(
                  children: [
                    if (tierNodes.isNotEmpty) _buildNodeLegend(ctx, tierNodes),
                    if (mappingLabels.isNotEmpty)
                      _buildDataLegend(ctx, mappingLabels.toList()..sort()),
                  ],
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNodeLegend(BuildContext context, List<SankeyNode> legendNodes) {
    // Deduplicate by label
    final seen = <String>{};
    final unique = legendNodes.where((n) => seen.add(n.label)).toList();

    return _LegendRow(
      items: unique.map((n) {
        return _LegendItem(label: n.label, color: n.color);
      }).toList(),
    );
  }

  Widget _buildDataLegend(BuildContext context, List<String> labels) {
    return _LegendRow(
      items: labels.map((l) {
        return _LegendItem(
          label: l,
          color: getMappingColor(l, const Color(0xFFB0BEC5)),
          isDot: true,
        );
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
              letterSpacing: 0.4,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final List<Widget> items;
  const _LegendRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: items),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDot;

  const _LegendItem({
    required this.label,
    required this.color,
    this.isDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                if (!isDot)
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isDot ? FontWeight.w500 : FontWeight.w600,
              color: isDot ? const Color(0xFF6B7280) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
