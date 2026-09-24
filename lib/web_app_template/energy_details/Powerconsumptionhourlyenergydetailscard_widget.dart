import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import '/components/card_widget/card_widget.dart';
import 'package:smartmachine365/web_app_template/energy_comparison/powerconsumptionhourlyenergydetailscard_model.dart';

class PowerconsumptionhourlyenergydetailscardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;
  final List<Map<String, dynamic>> chartDataPrevious;
  final bool isLoading;
  final String title;
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  // ✅ Optional duration filter — only shown when provided
  final String? selectedDuration;
  final List<String>? durationOptions;
  final Function(String)? onDurationChanged;

  const PowerconsumptionhourlyenergydetailscardWidget({
    super.key,
    required this.chartData,
    required this.chartDataPrevious,
    required this.isLoading,
    required this.title,
    required this.selectedDate,
    required this.onDateChanged,
    this.selectedDuration,
    this.durationOptions,
    this.onDurationChanged,
  });

  @override
  State<PowerconsumptionhourlyenergydetailscardWidget> createState() => _PowerconsumptionhourlyenergydetailscardWidgetState();
}

class _PowerconsumptionhourlyenergydetailscardWidgetState extends State<PowerconsumptionhourlyenergydetailscardWidget> {
  double _minX = 0;
  double _maxX = 24;

  // ── Y-axis manual offset ────────────────────
  double _yAxisOffset = 0;

  // ── Scale gesture tracking ──────────────────
  double _scaleStart = 0;
  bool _isScaling = false;

  // ── Drag tracking (single-finger scroll) ────
  double? _dragStartX; // chart-unit X at drag start
  double? _dragStartMinX;

  late PowerconsumptionhourlyenergydetailscardModel _model;

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerconsumptionhourlyenergydetailscardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
    _resetZoom();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PowerconsumptionhourlyenergydetailscardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chartData != oldWidget.chartData || widget.selectedDuration != oldWidget.selectedDuration) {
      _resetZoom();
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  double get _dataLength {
    final current = widget.chartData.length;
    final previous = widget.chartDataPrevious.length;
    final maxLen = current > previous ? current : previous;
    return maxLen > 0 ? maxLen.toDouble() : 24;
  }

  double get _currentRange => _maxX - _minX;

  /// Parse duration string to minutes (e.g. "15min" -> 15, "1hr" -> 60).
  int _parseDurationMinutes(String? duration) {
    if (duration == null) return 60;
    final lower = duration.toLowerCase().trim();
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(lower);
    if (minMatch != null) return int.parse(minMatch.group(1)!);
    final hrMatch = RegExp(r'(\d+)\s*h').firstMatch(lower);
    if (hrMatch != null) return int.parse(hrMatch.group(1)!) * 60;
    return 60;
  }

  /// Returns the minimum zoom range based on duration.
  double get _minZoomRange {
    final durationMin = _parseDurationMinutes(widget.selectedDuration);
    if (durationMin < 15) {
      return 1.0;
    } else if (durationMin < 60) {
      return 2.0;
    }
    return 4.0;
  }

  /// Initial visible range based on duration.
  double get _defaultVisibleRange {
    const double fixedRange = 66.66666666666669;
    final double dataLen = _dataLength;
    double visibleRange = fixedRange.clamp(_minZoomRange, dataLen);
    if (visibleRange > dataLen) {
      visibleRange = dataLen;
    }
    return visibleRange;
  }

  /// Clamp minX/maxX so the window stays fully within [0, _dataLength].
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
    _minX = newMin.clamp(0, _dataLength - range);
    _maxX = _minX + range;
  }

  // ─────────────────────────────────────────────
  // Zoom / Pan helpers
  // ─────────────────────────────────────────────

  void _resetZoom() {
    setState(() {
      _invalidateYScale();
      _minX = 0;
      _maxX = _defaultVisibleRange;
    });
  }

  void _scrollLeft() {
    if (_minX <= 0) return;
    setState(() {
      _invalidateYScale();
      final step = _currentRange * 0.2;
      _clampWindow(_minX - step, _maxX - step);
    });
  }

  void _scrollRight() {
    if (_maxX >= _dataLength) return;
    setState(() {
      _invalidateYScale();
      final step = _currentRange * 0.2;
      _clampWindow(_minX + step, _maxX + step);
    });
  }

  bool get _canScrollLeft => _minX > 0;
  bool get _canScrollRight => _maxX < _dataLength;

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStart = _currentRange;
    _isScaling = true;
    _invalidateYScale();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isScaling) return;
    setState(() {
      _invalidateYScale();
      if (details.scale != 1.0) {
        final newRange = (_scaleStart / details.scale).clamp(_minZoomRange, _dataLength);
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
    _invalidateYScale();
    _dragStartMinX = _minX;
    final chartWidth = context.size?.width ?? 300;
    _dragStartX = details.localPosition.dx / chartWidth * _currentRange;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragStartMinX == null || _dragStartX == null) return;
    setState(() {
      _invalidateYScale();
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
        _invalidateYScale();
        final zoomFactor = event.scrollDelta.dy > 0 ? 1.15 : 0.87;
        final newRange = (_currentRange * zoomFactor).clamp(_minZoomRange, _dataLength);
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

  void _adjustYAxisUp() {
    setState(() {
      _invalidateYScale();
      _yAxisOffset += (_getMaxY() - _getMinY()) * 0.1;
    });
  }

  void _adjustYAxisDown() {
    setState(() {
      _invalidateYScale();
      _yAxisOffset -= (_getMaxY() - _getMinY()) * 0.1;
    });
  }

  void _resetYAxis() {
    setState(() {
      _invalidateYScale();
      _yAxisOffset = 0;
    });
  }

  // ─────────────────────────────────────────────
  // Date navigation
  // ─────────────────────────────────────────────

  void _previousDay() => widget.onDateChanged(widget.selectedDate.subtract(const Duration(days: 1)));
  void _nextDay() => widget.onDateChanged(widget.selectedDate.add(const Duration(days: 1)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        final isLt = Theme.of(ctx).brightness == Brightness.light;
        final pri = FlutterFlowTheme.of(ctx).primary;
        return Theme(
          data: (isLt ? ThemeData.light() : ThemeData.dark()).copyWith(
            colorScheme: isLt
                ? ColorScheme.light(primary: pri, onPrimary: Colors.white)
                : ColorScheme.dark(
                    primary: pri,
                    onPrimary: Colors.white,
                    surface: const Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
            dialogBackgroundColor: isLt ? Colors.white : const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateChanged(picked);
    }
  }

  // ─────────────────────────────────────────────
  // Chart spot builders
  // ─────────────────────────────────────────────

  List<FlSpot> _getChartSpots() => widget.chartData.isEmpty
      ? []
      : List.generate(
          widget.chartData.length,
          (i) => FlSpot(i.toDouble(), (widget.chartData[i]['value'] ?? 0).toDouble()),
        );

  List<FlSpot> _getPreviousChartSpots() => widget.chartDataPrevious.isEmpty
      ? []
      : List.generate(
          widget.chartDataPrevious.length,
          (i) => FlSpot(i.toDouble(), (widget.chartDataPrevious[i]['value'] ?? 0).toDouble()),
        );

  // ─────────────────────────────────────────────
  // Y-axis auto-scale
  // ─────────────────────────────────────────────

  _YScale? _yScaleCache;

  List<double> _getVisibleValues() {
    final visible = <double>[];
    for (final entry in widget.chartData.asMap().entries) {
      if (entry.key >= _minX && entry.key <= _maxX) {
        visible.add((entry.value['value'] ?? 0).toDouble());
      }
    }
    for (final entry in widget.chartDataPrevious.asMap().entries) {
      if (entry.key >= _minX && entry.key <= _maxX) {
        visible.add((entry.value['value'] ?? 0).toDouble());
      }
    }
    return visible;
  }

  double _niceStep(double value, {bool round = false}) {
    if (value <= 0) return 1;
    final exp = (log(value) / log(10)).floorToDouble();
    final frac = value / pow(10, exp);
    double niceFrac;
    if (round) {
      niceFrac = frac < 1.5
          ? 1
          : frac < 3
              ? 2
              : frac < 7
                  ? 5
                  : 10;
    } else {
      niceFrac = frac <= 1
          ? 1
          : frac <= 2
              ? 2
              : frac <= 5
                  ? 5
                  : 10;
    }
    return niceFrac * pow(10, exp);
  }

  _YScale _computeYScale() {
    if (_yScaleCache != null) return _yScaleCache!;
    final values = _getVisibleValues();
    if (values.isEmpty) {
      return _yScaleCache = const _YScale(minY: -1000, maxY: 1000, interval: 200);
    }
    double rawMin = values.reduce((a, b) => a < b ? a : b);
    double rawMax = values.reduce((a, b) => a > b ? a : b);
    final double absMax = max(rawMax.abs(), rawMin.abs());
    if (absMax == 0) {
      return _yScaleCache = const _YScale(minY: -1000, maxY: 1000, interval: 200);
    }
    if ((rawMax - rawMin).abs() < absMax * 0.001) {
      rawMin = rawMin - absMax * 0.1;
      rawMax = rawMax + absMax * 0.1;
    }
    final double range = rawMax - rawMin;
    final double interval = _niceStep(range / 5, round: true).clamp(1.0, double.infinity);
    double minY = (rawMin / interval).floorToDouble() * interval;
    double maxY = (rawMax / interval).ceilToDouble() * interval;
    if (maxY - rawMax < interval * 0.5) maxY += interval;
    if (maxY <= minY) maxY = minY + interval;
    return _yScaleCache = _YScale(minY: minY, maxY: maxY, interval: interval);
  }

  double _getMinY() => _computeYScale().minY + _yAxisOffset;
  double _getMaxY() => _computeYScale().maxY + _yAxisOffset;
  double _getYInterval() => _computeYScale().interval;
  void _invalidateYScale() => _yScaleCache = null;

  String _formatYLabel(double value) {
    final absVal = value.abs();
    final sign = value < 0 ? '-' : '';
    if (absVal >= 1000000) {
      final mw = absVal / 1000000;
      return '$sign${mw % 1 == 0 ? mw.toStringAsFixed(0) : mw.toStringAsFixed(1)}MW';
    } else if (absVal >= 1000) {
      final kw = absVal / 1000;
      return '$sign${kw % 1 == 0 ? kw.toStringAsFixed(0) : kw.toStringAsFixed(1)}kW';
    } else {
      return '$sign${absVal.toStringAsFixed(0)}W';
    }
  }

  double _getLeftReservedSize() {
    final scale = _computeYScale();
    final labels = <String>[];
    double tick = scale.minY;
    while (tick <= scale.maxY + scale.interval * 0.01) {
      labels.add(_formatYLabel(tick));
      tick += scale.interval;
      if (scale.interval <= 0) break;
    }
    const double charWidth = 6.5;
    final maxChars = labels.fold<int>(0, (prev, l) => l.length > prev ? l.length : prev);
    return (maxChars * charWidth) + 20;
  }

  // ─────────────────────────────────────────────
  // Duration dropdown
  // ─────────────────────────────────────────────

  Widget _buildDurationDropdown() {
    if (widget.selectedDuration == null || widget.durationOptions == null || widget.onDurationChanged == null) return const SizedBox.shrink();
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isLight ? FlutterFlowTheme.of(context).secondaryBackground : const Color.fromRGBO(0, 4, 51, 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FlutterFlowTheme.of(context).primary, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedDuration,
          dropdownColor: isLight ? FlutterFlowTheme.of(context).secondaryBackground : const Color(0xFF0A0F3D),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isLight ? FlutterFlowTheme.of(context).secondaryText : Colors.white70, size: 18),
          style: GoogleFonts.poppins(color: isLight ? FlutterFlowTheme.of(context).txtPrimary : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          items: widget.durationOptions!.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (val) {
            if (val != null) widget.onDurationChanged!(val);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Scroll indicator bar
  // ─────────────────────────────────────────────

  Widget _buildScrollIndicator() {
    if (_dataLength == 0 || _currentRange >= _dataLength) {
      return const SizedBox.shrink();
    }
    final thumbStart = _minX / _dataLength;
    final thumbWidth = _currentRange / _dataLength;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        return Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? FlutterFlowTheme.of(context).alternate.withOpacity(0.5)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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

  // ─────────────────────────────────────────────
  // Arrow scroll button
  // ─────────────────────────────────────────────

  Widget _buildScrollArrow({required bool isLeft}) {
    final canScroll = isLeft ? _canScrollLeft : _canScrollRight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canScroll ? (isLeft ? _scrollLeft : _scrollRight) : null,
        onLongPress: canScroll
            ? () async {
                while (isLeft ? _canScrollLeft : _canScrollRight) {
                  if (isLeft) {
                    _scrollLeft();
                  } else {
                    _scrollRight();
                  }
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
            color: canScroll ? FlutterFlowTheme.of(context).primary.withOpacity(0.15) : FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
            border: Border.all(
              color: canScroll ? FlutterFlowTheme.of(context).primary.withOpacity(0.6) : FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            isLeft ? Icons.chevron_left : Icons.chevron_right,
            color: canScroll ? FlutterFlowTheme.of(context).primaryText : FlutterFlowTheme.of(context).secondaryText,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    final previousDate = widget.selectedDate.subtract(const Duration(days: 1));
    final previousDateString = DateFormat('dd/MMM/yyyy').format(previousDate);
    final leftReservedSize = _getLeftReservedSize();

    final minY = _getMinY();
    final maxY = _getMaxY();
    final bool showZeroLine = minY < 0 && maxY > 0;

    final bottomInterval = _currentRange > 12 ? 2.0 : 1.0;

    final durationMin = _parseDurationMinutes(widget.selectedDuration);
    final isHighResolution = durationMin < 15;

    return SizedBox(
      height: 560,
      child: CardWidget(
      armLenMultiplier: 0.20,
      topPadMultiplier: 0.0,
      bottomPadMultiplier: 0.0,
      glowColor: FlutterFlowTheme.of(context).primary,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────
          // Title/legend always sit on their own line, with the zoom/date
          // toolbar always on a row underneath — same shape at every screen
          // width, instead of squeezing a dropdown + five icon buttons + a
          // date pill beside the title, which overflowed off the right edge
          // on a narrow screen.
          Text(
            widget.title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isLight ? theme.txtPrimary : Colors.white),
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              _legendDash(const Color(0xFF3B82F6)),
              Text(DateFormat('dd/MMM/yyyy').format(widget.selectedDate), style: GoogleFonts.poppins(fontSize: 12, color: isLight ? theme.secondaryText : Colors.white70)),
              _legendDash(const Color(0xFFFF6B6B)),
              Text(previousDateString, style: GoogleFonts.poppins(fontSize: 12, color: isLight ? theme.secondaryText : Colors.white70)),
              if (isHighResolution)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: FlutterFlowTheme.of(context).primary.withOpacity(0.5)),
                  ),
                  child: Text(
                    'High Res · Scroll to explore',
                    style: GoogleFonts.poppins(fontSize: 10, color: FlutterFlowTheme.of(context).primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDurationDropdown(),
              IconButton(
                icon: Icon(Icons.zoom_out, color: isLight ? theme.txtPrimary : Colors.white),
                onPressed: () => setState(() {
                  _invalidateYScale();
                  final newRange = (_currentRange * 1.5).clamp(_minZoomRange, _dataLength);
                  final center = (_minX + _maxX) / 2;
                  _clampWindow(center - newRange / 2, center + newRange / 2);
                }),
                tooltip: 'Zoom Out',
              ),
              IconButton(
                icon: Icon(Icons.zoom_in, color: isLight ? theme.txtPrimary : Colors.white),
                onPressed: () => setState(() {
                  _invalidateYScale();
                  final newRange = (_currentRange / 1.8).clamp(_minZoomRange, _dataLength);
                  final center = (_minX + _maxX) / 2;
                  _clampWindow(center - newRange / 2, center + newRange / 2);
                }),
                tooltip: 'Zoom In',
              ),
              IconButton(
                icon: Icon(Icons.arrow_upward, color: isLight ? theme.txtPrimary : Colors.white),
                onPressed: _adjustYAxisUp,
                tooltip: 'Y-Axis Up',
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, color: isLight ? theme.txtPrimary : Colors.white),
                onPressed: _adjustYAxisDown,
                tooltip: 'Y-Axis Down',
              ),
              IconButton(
                icon: Icon(Icons.restore_rounded, color: isLight ? theme.txtPrimary : Colors.white),
                onPressed: _resetYAxis,
                tooltip: 'Reset Y-Axis',
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isLight ? theme.secondaryBackground : const Color.fromRGBO(0, 4, 51, 1),
                  border: Border.all(color: FlutterFlowTheme.of(context).primary, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: isLight ? theme.secondaryText : Colors.grey, size: 28),
                      onPressed: _previousDay,
                      tooltip: 'Previous Day',
                    ),
                    InkWell(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Text(
                          DateFormat('dd/MMM/yyyy').format(widget.selectedDate),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: isLight ? theme.txtPrimary : Colors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
                      onPressed: _nextDay,
                      tooltip: 'Next Day',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (widget.isLoading)
            SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(color: FlutterFlowTheme.of(context).primary)),
            )
          else if (widget.chartData.isEmpty && widget.chartDataPrevious.isEmpty)
            SizedBox(
              height: 300,
              child: Center(
                child: Text('No data available', style: TextStyle(color: isLight ? theme.secondaryText : Colors.white70)),
              ),
            )
          else ...[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: _buildScrollArrow(isLeft: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRect(
                      child: Listener(
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
                              minY: minY,
                              maxY: maxY,
                              clipData: const FlClipData.all(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: _getYInterval(),
                                getDrawingHorizontalLine: (value) {
                                  if (showZeroLine && value == 0) {
                                    return FlLine(
                                      color: isLight ? theme.txtSecondary : Colors.white.withOpacity(0.55),
                                      strokeWidth: 1.2,
                                      dashArray: [6, 4],
                                    );
                                  }
                                  return FlLine(
                                    color: isLight ? theme.alternate.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                                    strokeWidth: 1,
                                  );
                                },
                                getDrawingVerticalLine: (_) => FlLine(
                                  color: isLight ? theme.alternate.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    // ── Always use interval=1 so fl_chart calls
                                    // getTitlesWidget for every index, then we decide
                                    // which ones to actually render inside the callback.
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0) return const SizedBox.shrink();

                                      // Pick label from whichever dataset covers this index.
                                      // Current day may have fewer points than previous day
                                      // (e.g. today 17 entries, yesterday 24). Use
                                      // chartDataPrevious as fallback so "00:00" at index 23
                                      // is still rendered on the axis.
                                      String label = '';
                                      if (idx < widget.chartData.length) {
                                        label = (widget.chartData[idx]['label'] ?? '').toString();
                                      } else if (idx < widget.chartDataPrevious.length) {
                                        label = (widget.chartDataPrevious[idx]['label'] ?? '').toString();
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                      if (label.isEmpty) return const SizedBox.shrink();

                                      final maxLen = widget.chartData.length > widget.chartDataPrevious.length
                                          ? widget.chartData.length
                                          : widget.chartDataPrevious.length;
                                      final isLastPoint = idx == maxLen - 1;

                                      // Show: last point always + every Nth point based on range
                                      // bottomInterval controls how dense the labels are.
                                      final step = bottomInterval.toInt().clamp(1, 999);
                                      final showThisTick = isLastPoint || (idx % step == 0);
                                      if (!showThisTick) return const SizedBox.shrink();

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          label,
                                          style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : Colors.white70, fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: leftReservedSize,
                                    interval: _getYInterval(),
                                    getTitlesWidget: (value, meta) {
                                      if (value < minY - 0.01 || value > maxY + 0.01) {
                                        return const SizedBox.shrink();
                                      }
                                      final isZero = value.abs() < 0.001;
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: Text(
                                          _formatYLabel(value),
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.poppins(
                                            color: isZero ? (isLight ? theme.txtPrimary : Colors.white) : (isLight ? theme.secondaryText : Colors.white70),
                                            fontSize: 10,
                                            fontWeight: isZero ? FontWeight.w700 : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: isLight ? theme.alternate : Colors.white.withOpacity(0.2), width: 1),
                              ),
                              lineBarsData: [
                                if (widget.chartDataPrevious.isNotEmpty)
                                  LineChartBarData(
                                    spots: _getPreviousChartSpots(),
                                    isCurved: true,
                                    color: const Color(0xFFFF6B6B),
                                    barWidth: 2,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFF6B6B).withOpacity(0.3),
                                          const Color(0xFFFF6B6B).withOpacity(0.05),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      cutOffY: 0,
                                      applyCutOffY: showZeroLine,
                                    ),
                                    aboveBarData: showZeroLine
                                        ? BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF6B6B).withOpacity(0.05),
                                                const Color(0xFFFF6B6B).withOpacity(0.25),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            cutOffY: 0,
                                            applyCutOffY: true,
                                          )
                                        : BarAreaData(show: false),
                                  ),
                                LineChartBarData(
                                  spots: _getChartSpots(),
                                  isCurved: true,
                                  color: const Color(0xFF3B82F6),
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF3B82F6).withOpacity(0.5),
                                        const Color(0xFF3B82F6).withOpacity(0.1),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    cutOffY: 0,
                                    applyCutOffY: showZeroLine,
                                  ),
                                  aboveBarData: showZeroLine
                                      ? BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF3B82F6).withOpacity(0.05),
                                              const Color(0xFF3B82F6).withOpacity(0.3),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          cutOffY: 0,
                                          applyCutOffY: true,
                                        )
                                      : BarAreaData(show: false),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => const Color(0xFF1A1F4E),
                                  tooltipRoundedRadius: 8,
                                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                    return touchedBarSpots.map((barSpot) {
                                      final index = barSpot.x.toInt();
                                      final hasPrevious = widget.chartDataPrevious.isNotEmpty;
                                      final isCurrentDay = hasPrevious ? barSpot.barIndex == 1 : barSpot.barIndex == 0;
                                      final dataSource = isCurrentDay ? widget.chartData : widget.chartDataPrevious;
                                      final dateString = isCurrentDay ? DateFormat('dd/MMM/yyyy').format(widget.selectedDate) : previousDateString;
                                      final dotColor = isCurrentDay ? const Color(0xFF3B82F6) : const Color(0xFFFF6B6B);
                                      if (index < 0 || index >= dataSource.length) return null;
                                      final label = dataSource[index]['label'] ?? '';
                                      final value = (dataSource[index]['value'] ?? 0) as num;
                                      return LineTooltipItem(
                                        '$dateString\n$label\n${_formatYLabel(value.toDouble())}',
                                        GoogleFonts.poppins(
                                          color: dotColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Align(
                    alignment: Alignment.center,
                    child: _buildScrollArrow(isLeft: false),
                  ),
                ],
              ),
            ),
            // Remove the hardcoded 8px box to allow true flush alignment
            Padding(
              padding: EdgeInsets.only(
                left: 40,
                right: 40,
                bottom: _dataLength > 0 && _currentRange < _dataLength ? 12 : 0,
              ),
              child: _buildScrollIndicator(),
            ),
          ],
        ],
      ),
      ),
    ),
    );
  }

  Widget _legendDash(Color color) => Container(
        width: 16,
        height: 3,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}

class _YScale {
  final double minY;
  final double maxY;
  final double interval;

  const _YScale({
    required this.minY,
    required this.maxY,
    required this.interval,
  });
}
