import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/kanban_grid_preview.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/widget_config_dialog.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class MonitorPreviewWidget extends StatelessWidget {
  final int headerRows;
  final int footerRows;
  final String dateLabel;
  final List<KanbanCellConfig?> cells;
  final void Function(int cellIndex)? onCellTap;
  final void Function(int cellIndex)? onCellDelete;
  final void Function(int fromIndex, int toIndex)? onCellDrop;
  final Widget Function(KanbanCellConfig cell)? widgetBuilder;

  static const double _designWidth = 1920;
  static const double _designHeight = 1080;
  static const double _aspectRatio = _designWidth / _designHeight;
  static const double _border = 10.0;

  const MonitorPreviewWidget({
    super.key,
    required this.headerRows,
    required this.footerRows,
    required this.dateLabel,
    this.cells = const [],
    this.onCellTap,
    this.onCellDelete,
    this.onCellDrop,
    this.widgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _aspectRatio,
          child: LayoutBuilder(builder: (context, constraints) {
            final frameW = constraints.maxWidth;
            final frameH = constraints.maxHeight;

            // ── Inner canvas (inside the border) ────────────────────────
            final innerW = frameW - _border * 2;
            final innerH = frameH - _border * 2;

            // ── Scale factors: design-space → real pixels ────────────────
            // FittedBox(fit: BoxFit.fill) maps 1920×1080 → innerW×innerH
            // linearly, so every design coordinate scales by these factors.
            final scaleY = innerH / _designHeight;

            // ── Title bar height in real pixels ──────────────────────────
            final titleH = KanbanGridPreview.titleBarHeight * scaleY;

            // ── Grid area height ─────────────────────────────────────────
            // KanbanGridPreview lives inside `Expanded` after the title bar,
            // so Flutter gives it exactly (innerH - titleH) as maxHeight.
            final gridH = innerH - titleH;

            // ── Cell dimensions — identical to KanbanGridPreview ─────────
            //
            // KanbanGridPreview.build():
            //   totalRows = headerRows + gridRows + footerRows
            //   cellH     = constraints.maxHeight / totalRows   → gridH / totalRows
            //   cellW     = constraints.maxWidth  / gridCols    → innerW / gridCols
            //
            // Content cell top (relative to grid area top):
            //   (headerRows + row) * cellH
            //
            // In frame space (what Positioned needs):
            //   left = border + col  * cellW
            //   top  = border + titleH + (headerRows + row) * cellH
            const cols = KanbanGridPreview.gridCols;
            const contentRows = KanbanGridPreview.gridRows;
            final totalRows = headerRows + contentRows + footerRows;

            final cellW = innerW / cols;
            final cellH =
                gridH / totalRows; // ← same divisor as KanbanGridPreview

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Visual layer (no gestures) ───────────────────────────
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.25),
                        width: _border,
                      ),
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      boxShadow: [
                        BoxShadow(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                            color: Color(0x661A1A3E),
                            blurRadius: 24,
                            offset: Offset(0, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: _designWidth,
                          height: _designHeight,
                          child: Column(
                            children: [
                              // Title bar
                              SizedBox(
                                width: _designWidth,
                                height: KanbanGridPreview.titleBarHeight,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                        'assets/images/header_dashboard.png',
                                        fit: BoxFit.fill),
                                    Center(
                                      child: Text(
                                        dateLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontFamily: 'Poppins',
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Grid — Expanded gives it exactly
                              // (_designHeight - titleBarHeight) in design space,
                              // which maps to (innerH - titleH) in real pixels.
                              Expanded(
                                child: KanbanGridPreview(
                                  headerRows: headerRows,
                                  footerRows: footerRows,
                                  cells: cells,
                                  widgetBuilder: widgetBuilder,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Tap overlay ──────────────────────────────────────────
                if (onCellTap != null)
                  Positioned.fill(
                    child: _SpanAwareTapOverlay(
                      titleH: titleH,
                      cellW: cellW,
                      cellH: cellH,
                      border: _border,
                      headerRows: headerRows,
                      cells: cells,
                      onCellTap: onCellTap!,
                      onCellDelete: onCellDelete,
                      onCellDrop: onCellDrop,
                    ),
                  ),
              ],
            );
          }),
        ),

        // Monitor neck + base
        Builder(builder: (context) {
          final primary = FlutterFlowTheme.of(context).primary;
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF222233),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(4)),
                  border: Border(
                    left: BorderSide(
                        color: primary.withOpacity(0.15), width: 0.5),
                    right: BorderSide(
                        color: primary.withOpacity(0.15), width: 0.5),
                  ),
                ),
              ),
              Container(
                width: 180,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF333344),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: primary.withOpacity(0.1), width: 0.5),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Span-aware tap overlay
//
// Mirrors KanbanGridPreview's cell placement formula exactly so tap targets
// are pixel-perfect regardless of container size.
// ─────────────────────────────────────────────────────────────────────────────
class _SpanAwareTapOverlay extends StatelessWidget {
  final double titleH;
  final double cellW;
  final double cellH;
  final double border;
  final int headerRows;
  final List<KanbanCellConfig?> cells;
  final void Function(int) onCellTap;
  final void Function(int)? onCellDelete;
  final void Function(int fromIndex, int toIndex)? onCellDrop;

  const _SpanAwareTapOverlay({
    required this.titleH,
    required this.cellW,
    required this.cellH,
    required this.border,
    required this.headerRows,
    required this.cells,
    required this.onCellTap,
    this.onCellDelete,
    this.onCellDrop,
  });

  @override
  Widget build(BuildContext context) {
    const cols = KanbanGridPreview.gridCols;
    const contentRows = KanbanGridPreview.gridRows;
    final primary = FlutterFlowTheme.of(context).primary;

    final Set<int> coveredIndices = {};
    final List<Widget> overlays = [];

    for (int index = 0; index < cols * contentRows; index++) {
      if (coveredIndices.contains(index)) continue;

      final col = index % cols;
      final row = index ~/ cols;
      final cell = index < cells.length ? cells[index] : null;
      final (colSpan, rowSpan) =
          cell != null ? KanbanGridPreview.parseSize(cell.size) : (1, 1);

      // Mark sub-cells covered by this span
      for (int dr = 0; dr < rowSpan; dr++) {
        for (int dc = 0; dc < colSpan; dc++) {
          final ci = (row + dr) * cols + (col + dc);
          if (ci != index) coveredIndices.add(ci);
        }
      }

      // ── Frame-space position ─────────────────────────────────────────
      final left = border + col * cellW;
      final top = border + titleH + (headerRows + row) * cellH;
      final width = cellW * colSpan;
      final height = cellH * rowSpan;

      final btnSize = (cellH * 0.12).clamp(14.0, 22.0);
      final iconSize = btnSize * 0.65;

      final cellWidget = _buildCellOverlay(
        context: context,
        index: index,
        cell: cell,
        width: width,
        height: height,
        btnSize: btnSize,
        iconSize: iconSize,
        primary: primary,
      );

      overlays.add(
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: cellWidget,
        ),
      );
    }

    return Stack(children: overlays);
  }

  Widget _buildCellOverlay({
    required BuildContext context,
    required int index,
    required KanbanCellConfig? cell,
    required double width,
    required double height,
    required double btnSize,
    required double iconSize,
    required Color primary,
  }) {
    final canDrop = onCellDrop != null;

    // ── Delete button content for filled cells ───────────────────────────
    Widget filledContent = cell != null && onCellDelete != null
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(btnSize * 0.2),
              child: GestureDetector(
                onTap: () => onCellDelete!(index),
                child: Container(
                  width: btnSize,
                  height: btnSize,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).error.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          FlutterFlowTheme.of(context).error.withOpacity(0.6),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(Icons.close,
                      size: iconSize,
                      color: FlutterFlowTheme.of(context).error),
                ),
              ),
            ),
          )
        : const SizedBox.expand();

    // ── Drag-and-drop wrapper ────────────────────────────────────────────
    if (canDrop) {
      return DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => onCellDrop!(details.data, index),
        builder: (context, candidateData, _) {
          final isHovered = candidateData.isNotEmpty;

          if (cell != null) {
            // Filled cell → draggable + tap
            return LongPressDraggable<int>(
              data: index,
              hapticFeedbackOnStart: true,
              delay: const Duration(milliseconds: 350),
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.25),
                    border: Border.all(color: primary, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_with,
                          color: primary,
                          size: (height * 0.18).clamp(16.0, 28.0)),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          cell.widgetName,
                          style: TextStyle(
                              color: primary,
                              fontSize: (height * 0.07).clamp(10.0, 14.0),
                              fontFamily: 'Poppins'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.06),
                  border: Border.all(color: primary.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(Icons.open_with,
                      color: primary.withOpacity(0.3),
                      size: (height * 0.15).clamp(14.0, 24.0)),
                ),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onCellTap(index),
                child: Stack(
                  children: [
                    // Hover highlight when another cell is dragged over
                    if (isHovered)
                      Container(
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          border: Border.all(color: primary, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    filledContent,
                    // Drag handle hint
                    Positioned(
                      bottom: btnSize * 0.2,
                      left: btnSize * 0.2,
                      child: Icon(Icons.drag_indicator,
                          color: primary.withOpacity(0.35),
                          size: btnSize * 0.9),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Empty cell → tap target + drop highlight
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCellTap(index),
              child: isHovered
                  ? Container(
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        border: Border.all(color: primary, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Icon(Icons.add_circle_outline,
                            color: primary,
                            size: (height * 0.2).clamp(18.0, 32.0)),
                      ),
                    )
                  : const SizedBox.expand(),
            );
          }
        },
      );
    }

    // ── No drag support (read-only / non-settings mode) ──────────────────
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onCellTap(index),
      child: filledContent,
    );
  }
}
