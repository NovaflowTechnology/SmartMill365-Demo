import 'package:flutter/material.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/widget_config_dialog.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Pure-visual grid preview — no GestureDetectors.
/// Taps are handled by the overlay in MonitorPreviewWidget.
class KanbanGridPreview extends StatelessWidget {
  static const double titleBarHeight = 80.0;
  static const int gridCols = 4;
  static const int gridRows = 3;

  final int headerRows;
  final int footerRows;
  final List<KanbanCellConfig?> cells;

  /// Optional: supply a real widget builder to render actual content
  /// inside each filled cell (settings preview mode).
  /// Omit for the dashboard grid (it renders widgets itself).
  final Widget Function(KanbanCellConfig cell)? widgetBuilder;

  const KanbanGridPreview({
    super.key,
    required this.headerRows,
    required this.footerRows,
    this.cells = const [],
    this.widgetBuilder,
  });

  // ── Parse "colSpan x rowSpan" from size string ──────────────────────────
  static (int cols, int rows) parseSize(String size) {
    final parts = size.toLowerCase().split('x');
    if (parts.length == 2) {
      final c = int.tryParse(parts[0].trim()) ?? 1;
      final r = int.tryParse(parts[1].trim()) ?? 1;
      return (c.clamp(1, gridCols), r.clamp(1, gridRows));
    }
    return (1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalRows = headerRows + gridRows + footerRows;
      final cellW = constraints.maxWidth / gridCols;
      final cellH = constraints.maxHeight / totalRows;

      final List<Widget> children = [];

      // Grid lines
      final primary = FlutterFlowTheme.of(context).primary;
      children.add(CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _GridPainter(cols: gridCols, rows: totalRows, color: primary),
      ));

      // Header rows
      for (int r = 0; r < headerRows; r++) {
        children.add(Positioned(
          top: r * cellH,
          left: 0,
          width: constraints.maxWidth,
          height: cellH,
          child: Container(
            color: primary.withOpacity(0.06),
            alignment: Alignment.center,
            child: Text('Header ${r + 1}', style: TextStyle(color: primary.withOpacity(0.4), fontSize: 18, fontFamily: 'Poppins')),
          ),
        ));
      }

      // Content cells — compute which cells are covered by spanning widgets
      final Set<int> coveredIndices = {};

      for (int index = 0; index < gridCols * gridRows; index++) {
        if (coveredIndices.contains(index)) continue;

        final col = index % gridCols;
        final row = index ~/ gridCols;
        final cell = index < cells.length ? cells[index] : null;
        final (colSpan, rowSpan) = cell != null ? parseSize(cell.size) : (1, 1);

        // Mark all cells this widget covers as occupied
        for (int dr = 0; dr < rowSpan; dr++) {
          for (int dc = 0; dc < colSpan; dc++) {
            final coveredIdx = (row + dr) * gridCols + (col + dc);
            if (coveredIdx != index) coveredIndices.add(coveredIdx);
          }
        }

        final left = col * cellW;
        final top = (headerRows + row) * cellH;
        final width = cellW * colSpan;
        final height = cellH * rowSpan;

        children.add(Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: _CellVisual(
            index: index,
            cell: cell,
            widgetBuilder: widgetBuilder,
          ),
        ));
      }

      // Footer rows
      for (int r = 0; r < footerRows; r++) {
        final row = headerRows + gridRows + r;
        children.add(Positioned(
          top: row * cellH,
          left: 0,
          width: constraints.maxWidth,
          height: cellH,
          child: Container(
            color: primary.withOpacity(0.06),
            alignment: Alignment.center,
            child: Text('Footer ${r + 1}', style: TextStyle(color: primary.withOpacity(0.4), fontSize: 18, fontFamily: 'Poppins')),
          ),
        ));
      }

      return Stack(children: children);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visual-only cell — no GestureDetector
// ─────────────────────────────────────────────────────────────────────────────
class _CellVisual extends StatelessWidget {
  final int index;
  final KanbanCellConfig? cell;
  final Widget Function(KanbanCellConfig)? widgetBuilder;

  const _CellVisual({required this.index, required this.cell, this.widgetBuilder});

  @override
  Widget build(BuildContext context) {
    final isEmpty = cell == null;

    if (isEmpty) {
      final primary = FlutterFlowTheme.of(context).primary;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000A3A),
          border: Border.all(color: primary.withOpacity(0.08), width: 0.5),
        ),
        child: _EmptyVisual(index: index),
      );
    }

    // ── Filled cell → CardWidget with cyberpunk glow ──
    return CardWidget(
      glowColor: FlutterFlowTheme.of(context).primary,
      blurSigma: 1,
      topPadMultiplier: 0.2,
      bottomPadMultiplier: 0.2,
      armLenMultiplier: 0.4,
      builder: (context, sizing) =>
          _FilledVisual(cell: cell!, widgetBuilder: widgetBuilder),
    );
  }
}

class _EmptyVisual extends StatelessWidget {
  final int index;
  const _EmptyVisual({required this.index});

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_circle_outline, color: primary.withOpacity(0.15), size: 28),
        const SizedBox(height: 6),
        Text('Cell ${index + 1}', style: TextStyle(color: primary.withOpacity(0.2), fontSize: 16, fontFamily: 'Poppins')),
      ],
    );
  }
}

class _FilledVisual extends StatelessWidget {
  final KanbanCellConfig cell;
  final Widget Function(KanbanCellConfig)? widgetBuilder;

  const _FilledVisual({required this.cell, this.widgetBuilder});

  @override
  Widget build(BuildContext context) {
    // If a real widget builder is provided, render the actual widget
    if (widgetBuilder != null) {
      return ClipRect(child: widgetBuilder!(cell));
    }

    // Fallback: show name + size badge only
    final theme = FlutterFlowTheme.of(context);
    final (colSpan, rowSpan) = KanbanGridPreview.parseSize(cell.size);
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(cell.widgetName,
              style: TextStyle(color: theme.primary, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.primary.withOpacity(0.3), width: 0.5),
            ),
            child: Text('${colSpan}×${rowSpan}', style: TextStyle(color: theme.primary, fontSize: 13, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid line painter
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final int cols;
  final int rows;
  final Color color;
  const _GridPainter({required this.cols, required this.rows, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 0.5;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (int c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * cellW, 0), Offset(c * cellW, size.height), paint);
    }
    for (int r = 1; r < rows; r++) {
      canvas.drawLine(Offset(0, r * cellH), Offset(size.width, r * cellH), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.cols != cols || old.rows != rows || old.color != color;
}
