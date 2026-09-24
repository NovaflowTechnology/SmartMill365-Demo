import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class EquipmentLoadCorrelationChart extends StatefulWidget {
  final String title;
  final String selectedEventDate;
  final String selectedEventStart;
  final String selectedEventEnd;

  final Map<String, List<Map<String, dynamic>>> seriesData;
  final List<String> deviceIds;
  // meterId -> Master Facility display name (meterName), for labeling the
  // legend/tooltip with a human-readable name instead of the raw device
  // tag. Optional — Kanban Dashboard's panel builder/settings preview
  // render this same chart without Master Facilities context and simply
  // fall back to showing the raw id.
  final Map<String, String>? deviceNames;
  final double systemPeak;
  final bool isLoading;
  final String? errorMessage;
  final String selectedInterval;
  final ValueChanged<String> onIntervalChanged;
  final void Function(String date, String start, String end) onDateChanged;
  final VoidCallback onRefresh;
  // Opens the "Configure Charts" device-selection dialog. Optional — only
  // the standalone Max Demand Monitoring page wires this up; Kanban
  // Dashboard's live panel builder and settings preview builder render this
  // same chart without it, and simply get no gear icon.
  final VoidCallback? onConfigure;

  const EquipmentLoadCorrelationChart({
    super.key,
    required this.title,
    required this.selectedEventDate,
    required this.selectedEventStart,
    required this.selectedEventEnd,
    required this.seriesData,
    required this.deviceIds,
    this.deviceNames,
    required this.systemPeak,
    required this.isLoading,
    required this.errorMessage,
    required this.selectedInterval,
    required this.onIntervalChanged,
    required this.onDateChanged,
    required this.onRefresh,
    this.onConfigure,
  });

  @override
  State<EquipmentLoadCorrelationChart> createState() => _EquipmentLoadCorrelationChartState();
}

class _EquipmentLoadCorrelationChartState extends State<EquipmentLoadCorrelationChart> {
  DateTime? _pickedDate;

  // ── Zoom / Pan state ─────────────────────────────────────────────────────
  double _minX = 0;
  double _maxX = 24;

  double _scaleStart = 0;
  bool _isScaling = false;

  double? _dragStartX;
  double? _dragStartMinX;

  // ── Constants ─────────────────────────────────────────────────────────────
  static const double _minZoomRange = 4.0;

  // Safe lower bound for clamp — never exceeds _dataLength so clamp(lo, hi)
  // never throws when data has fewer points than _minZoomRange.
  double get _effectiveMinRange => _minZoomRange.clamp(0.0, _dataLength);

  final List<String> _intervals = ['5s', '5m', '15m', '30m', '1hr', '4hr', '12hr'];

  final List<Color> _lineColors = [
    const Color(0xFF00BCD4),
    const Color(0xFFE91E63),
    const Color(0xFFFF9800),
    const Color(0xFF4CAF50),
    const Color(0xFF9C27B0),
    const Color(0xFFFFEB3B),
    const Color(0xFF03A9F4),
    const Color(0xFFFF5722),
    const Color(0xFF8BC34A),
    const Color(0xFF607D8B),
    const Color(0xFFCDDC39),
    const Color(0xFF795548),
    const Color(0xFF009688),
    const Color(0xFFF48FB1),
    const Color(0xFFB0BEC5),
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _resetZoom();
  }

  @override
  void didUpdateWidget(EquipmentLoadCorrelationChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seriesData != oldWidget.seriesData || widget.selectedInterval != oldWidget.selectedInterval) {
      _resetZoom();
    }
  }

  // ── Data helpers ─────────────────────────────────────────────────────────

  // Master Facility display name for a device tag, falling back to the raw
  // tag when it has no name on record (or [deviceNames] wasn't supplied).
  String _labelFor(String deviceId) {
    final name = widget.deviceNames?[deviceId]?.trim();
    return (name != null && name.isNotEmpty) ? name : deviceId;
  }

  double get _dataLength {
    int max = 0;
    for (final id in widget.deviceIds) {
      final len = widget.seriesData[id]?.length ?? 0;
      if (len > max) max = len;
    }
    return max > 0 ? max.toDouble() : 24;
  }

  double get _currentRange => _maxX - _minX;

  // ── Zoom / Pan helpers ───────────────────────────────────────────────────

  void _clampWindow(double newMin, double newMax) {
    final range = newMax - newMin;
    if (newMin < 0) {
      newMin = 0;
      newMax = range;
    }
    if (newMax > _dataLength) {
      newMax = _dataLength;
      newMin = _dataLength - range;
    }
    final upperBound = (_dataLength - range).clamp(0.0, double.maxFinite);
    _minX = newMin.clamp(0, upperBound);
    _maxX = _minX + range;
  }

  void _resetZoom() {
    setState(() {
      _minX = 0;
      _maxX = _dataLength.clamp(_effectiveMinRange, _dataLength);
    });
  }

  void _scrollLeft() {
    if (_minX <= 0) return;
    setState(() {
      final step = _currentRange * 0.2;
      _clampWindow(_minX - step, _maxX - step);
    });
  }

  void _scrollRight() {
    if (_maxX >= _dataLength) return;
    setState(() {
      final step = _currentRange * 0.2;
      _clampWindow(_minX + step, _maxX + step);
    });
  }

  bool get _canScrollLeft => _minX > 0;
  bool get _canScrollRight => _maxX < _dataLength;

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStart = _currentRange;
    _isScaling = true;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isScaling) return;
    setState(() {
      if (details.scale != 1.0) {
        final newRange = (_scaleStart / details.scale).clamp(_effectiveMinRange, _dataLength);
        final chartWidth = context.size?.width ?? 300;
        final focalRatio = details.localFocalPoint.dx / chartWidth;
        final focalX = _minX + (_currentRange * focalRatio);
        final newMin = focalX - newRange * focalRatio;
        _clampWindow(newMin, newMin + newRange);
      }
      if (details.scale == 1.0 && details.focalPointDelta.dx != 0) {
        final chartWidth = context.size?.width ?? 300;
        final dx = -(details.focalPointDelta.dx / chartWidth) * _currentRange;
        _clampWindow(_minX + dx, _maxX + dx);
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartMinX = _minX;
    final chartWidth = context.size?.width ?? 300;
    _dragStartX = details.localPosition.dx / chartWidth * _currentRange;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragStartMinX == null || _dragStartX == null) return;
    setState(() {
      final chartWidth = context.size?.width ?? 300;
      final currentXOffset = details.localPosition.dx / chartWidth * _currentRange;
      final dx = _dragStartX! - currentXOffset;
      final newMin = _dragStartMinX! + dx;
      _clampWindow(newMin, newMin + _currentRange);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _dragStartX = null;
    _dragStartMinX = null;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {
        final zoomFactor = event.scrollDelta.dy > 0 ? 1.15 : 0.87;
        final newRange = (_currentRange * zoomFactor).clamp(_effectiveMinRange, _dataLength);
        RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final local = renderBox.globalToLocal(event.position);
          final focalRatio = (local.dx / renderBox.size.width).clamp(0.0, 1.0);
          final focalX = _minX + (_currentRange * focalRatio);
          final newMin = focalX - newRange * focalRatio;
          _clampWindow(newMin, newMin + newRange);
        } else {
          final center = (_minX + _maxX) / 2;
          _clampWindow(center - newRange / 2, center + newRange / 2);
        }
      });
    }
  }

  // ── Date helpers ─────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _displayYmd(String ymd) {
    final dt = DateTime.tryParse(ymd);
    return dt == null ? ymd : _displayDate(dt);
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      builder: (ctx, child) {
        final isLt = Theme.of(ctx).brightness == Brightness.light;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isLt
                ? ColorScheme.light(primary: theme.primary, onPrimary: Colors.white)
                : ColorScheme.dark(
                    primary: theme.primary,
                    onPrimary: Colors.white,
                    surface: const Color.fromRGBO(0, 4, 51, 1),
                    onSurface: Colors.white,
                  ),
            dialogBackgroundColor: isLt ? Colors.white : const Color.fromRGBO(0, 4, 51, 1),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _pickedDate = picked);
      final date = _formatDate(picked);
      widget.onDateChanged(date, '$date 00:00:00', '$date 23:59:59');
    }
  }

  void _clearDateFilter() {
    setState(() => _pickedDate = null);
    widget.onDateChanged('', '', '');
  }

  // ── Chart helpers ─────────────────────────────────────────────────────────

  List<LineChartBarData> _buildLineBars() {
    final bars = <LineChartBarData>[];
    for (int i = 0; i < widget.deviceIds.length; i++) {
      final points = widget.seriesData[widget.deviceIds[i]] ?? [];
      final color = _lineColors[i % _lineColors.length];
      final spots = points.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value['value'] as double);
      }).toList();
      bars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }
    return bars;
  }

  double _getBottomInterval() {
    if (_currentRange <= 10) return 1;
    if (_currentRange <= 30) return 5;
    return (_currentRange / 6).roundToDouble();
  }

  // ── Scroll indicator ──────────────────────────────────────────────────────

  Widget _buildScrollIndicator() {
    if (_dataLength == 0 || _currentRange >= _dataLength) return const SizedBox.shrink();
    final thumbStart = _minX / _dataLength;
    final thumbWidth = _currentRange / _dataLength;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        return Stack(
          children: [
            Builder(builder: (ctx) {
              final isLt = Theme.of(ctx).brightness == Brightness.light;
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isLt ? FlutterFlowTheme.of(ctx).alternate : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            Positioned(
              left: thumbStart * totalW,
              child: Container(
                width: (thumbWidth * totalW).clamp(20.0, totalW),
                height: 4,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Scroll arrow button ───────────────────────────────────────────────────

  Widget _buildScrollArrow({required bool isLeft}) {
    final theme = FlutterFlowTheme.of(context);
    final isLt = Theme.of(context).brightness == Brightness.light;
    final canScroll = isLeft ? _canScrollLeft : _canScrollRight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canScroll ? (isLeft ? _scrollLeft : _scrollRight) : null,
        onLongPress: canScroll
            ? () async {
                while (isLeft ? _canScrollLeft : _canScrollRight) {
                  if (isLeft)
                    _scrollLeft();
                  else
                    _scrollRight();
                  await Future.delayed(const Duration(milliseconds: 80));
                }
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: canScroll ? theme.primary.withOpacity(0.15) : (isLt ? theme.alternate : Colors.white.withOpacity(0.05)),
            border: Border.all(
              color: canScroll ? theme.primary.withOpacity(0.6) : (isLt ? theme.cardStroke : Colors.white.withOpacity(0.1)),
              width: 1,
            ),
          ),
          child: Icon(
            isLeft ? Icons.chevron_left : Icons.chevron_right,
            color: canScroll ? (isLt ? theme.txtPrimary : Colors.white) : (isLt ? theme.txtMuted : Colors.white24),
            size: 20,
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool heightBounded = constraints.maxHeight.isFinite;
        const double fallbackChartHeight = 300.0;

        Widget chartBody = _buildChartContent(context);

        return Column(
          mainAxisSize: heightBounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: sizing.accentW,
                            height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withOpacity(0.9),
                                  blurRadius: sizing.pad * 0.7,
                                  spreadRadius: sizing.accentW * 0.3,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: sizing.pad * 0.5),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${widget.title} (Peak Window Focus)',
                                style: GoogleFonts.poppins(
                                  fontSize: sizing.titleFs.clamp(12.0, 16.0),
                                  fontWeight: FontWeight.w700,
                                  color: isLight ? theme.txtPrimary : Colors.white,
                                  letterSpacing: 0.6,
                                  shadows: isLight
                                      ? null
                                      : [
                                          Shadow(
                                            color: theme.primary.withOpacity(0.7),
                                            blurRadius: 12,
                                          ),
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_pickedDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Filtered: ${_displayDate(_pickedDate!)}',
                          style: GoogleFonts.poppins(color: theme.primary, fontSize: sizing.bodyFs.clamp(9.0, 12.0)),
                        ),
                      ] else if (widget.selectedEventDate.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Event: ${_displayYmd(widget.selectedEventDate)}',
                          style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 11.0)),
                        ),
                      ],
                      if (widget.systemPeak > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'System Peak Recorded: ${widget.systemPeak.toStringAsFixed(1)} kW',
                          style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: sizing.bodyFs.clamp(9.0, 12.0), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Zoom buttons ───────────────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_out, color: isLight ? theme.txtSecondary : Colors.white),
                      onPressed: () => setState(() {
                        final newRange = (_currentRange * 1.5).clamp(_effectiveMinRange, _dataLength);
                        final center = (_minX + _maxX) / 2;
                        _clampWindow(center - newRange / 2, center + newRange / 2);
                      }),
                      tooltip: 'Zoom Out',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_in, color: isLight ? theme.txtSecondary : Colors.white),
                      onPressed: () => setState(() {
                        final newRange = (_currentRange / 1.8).clamp(_effectiveMinRange, _dataLength);
                        final center = (_minX + _maxX) / 2;
                        _clampWindow(center - newRange / 2, center + newRange / 2);
                      }),
                      tooltip: 'Zoom In',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 4),
                    if (widget.onConfigure != null)
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: theme.secondaryText, size: 20),
                        onPressed: widget.onConfigure,
                        tooltip: 'Configure equipment shown',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    if (widget.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.refresh, color: theme.secondaryText, size: 20),
                        onPressed: widget.onRefresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Interval pills + date picker ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Duration:',
                  style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 13.0), fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _intervals.map((interval) {
                      final isSelected = interval == widget.selectedInterval;
                      return GestureDetector(
                        onTap: () => widget.onIntervalChanged(interval),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? theme.primary : theme.secondaryText.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            interval,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : theme.secondaryText,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openDatePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isLight ? theme.secondaryBackground : const Color(0xFF0D1B4B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _pickedDate != null ? theme.primary : theme.secondaryText.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 14, color: _pickedDate != null ? theme.primary : theme.secondaryText),
                        const SizedBox(width: 5),
                        Text(
                          _pickedDate == null ? 'Filter date' : _displayDate(_pickedDate!),
                          style: GoogleFonts.poppins(
                            fontSize: sizing.bodyFs.clamp(9.0, 11.0),
                            color: _pickedDate != null ? theme.primary : theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_pickedDate != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B4B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Legend ───────────────────────────────────────────────────────
            if (widget.deviceIds.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: widget.deviceIds.asMap().entries.map((entry) {
                  final color = _lineColors[entry.key % _lineColors.length];
                  final deviceId = entry.value;
                  final label = _labelFor(deviceId);
                  return Tooltip(
                    message: label != deviceId ? '$label ($deviceId)' : deviceId,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 6),
                        Text(label, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 10.0))),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // ── Chart body ───────────────────────────────────────────────────
            heightBounded ? Expanded(child: chartBody) : SizedBox(height: fallbackChartHeight, child: chartBody),
          ],
        );
      },
    );
  }

  Widget _buildChartContent(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.primary)));
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load data', style: GoogleFonts.poppins(color: Colors.red, fontSize: 14)),
            const SizedBox(height: 8),
            Text(widget.errorMessage!, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (widget.seriesData.isEmpty) {
      return Center(child: Text('No data available', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 14)));
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildScrollArrow(isLeft: true),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Listener(
                      onPointerSignal: _handlePointerSignal,
                      child: GestureDetector(
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: _handleScaleUpdate,
                        onScaleEnd: _handleScaleEnd,
                        onHorizontalDragStart: _handleHorizontalDragStart,
                        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                        onHorizontalDragEnd: _handleHorizontalDragEnd,
                        child: LineChart(
                          LineChartData(
                            minX: _minX,
                            maxX: _maxX,
                            clipData: const FlClipData.all(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: theme.secondaryText.withOpacity(0.1),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    final firstId = widget.deviceIds.isNotEmpty ? widget.deviceIds.first : '';
                                    final firstPoints = widget.seriesData[firstId] ?? [];
                                    if (idx < 0 || idx >= firstPoints.length) return const SizedBox.shrink();
                                    final step = _getBottomInterval().toInt().clamp(1, 999);
                                    final isLastPoint = idx == firstPoints.length - 1;
                                    if (!isLastPoint && idx % step != 0) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        firstPoints[idx]['time'] as String,
                                        style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: _buildLineBars(),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => const Color.fromRGBO(0, 4, 51, 0.9),
                                tooltipBorder: BorderSide(color: theme.primary, width: 1),
                                fitInsideHorizontally: false,
                                fitInsideVertically: false,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    if (spot.barIndex < 0 || spot.barIndex >= widget.deviceIds.length) return null;
                                    final deviceId = widget.deviceIds[spot.barIndex];
                                    final color = _lineColors[spot.barIndex % _lineColors.length];
                                    return LineTooltipItem(
                                      '${_labelFor(deviceId)}\n${spot.y.toStringAsFixed(1)} kW',
                                      GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildScrollArrow(isLeft: false),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _buildScrollIndicator(),
        ),
      ],
    );
  }
}
