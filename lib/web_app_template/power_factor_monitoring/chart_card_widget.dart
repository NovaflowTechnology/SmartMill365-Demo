import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'dart:async';
import 'dart:math';

class MachineConfig {
  final String id;
  final String name;
  final Color color;

  MachineConfig({
    required this.id,
    required this.name,
    required this.color,
  });
}

class ChartCard extends StatefulWidget {
  final Map<String, dynamic>? powerFactorData;
  final List<MachineConfig> machines;
  final Map<String, bool> machineChecked;

  // ── Duration controlled by parent ─────────────────────────────
  final String selectedDuration;
  final ValueChanged<String> onDurationChanged;

  const ChartCard({
    super.key,
    this.powerFactorData,
    required this.machines,
    required this.machineChecked,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> with TickerProviderStateMixin {
  // ── View mode ─────────────────────────────────────────────────
  bool isMonthlyView = false;

  // ── Chart data ────────────────────────────────────────────────
  Map<String, List<FlSpot>> machineData = {};
  Map<String, List<FlSpot>> monthlyMachineData = {};

  bool _awaitingDurationData = false;

  // ── X-axis window ─────────────────────────────────────────────
  double _minX = 0;
  double _maxX = 0;

  // ── Y-axis manual offset ──────────────────────────────────────
  double _yOffset = 0;

  // ── Zoom ──────────────────────────────────────────────────────
  double _zoomLevel = 1.0;
  final double _minZoom = 0.5;
  final double _maxZoom = 3.0;

  // ── Drag tracking ─────────────────────────────────────────────
  double? _dragStartMinX;
  double? _dragStartX;
  double _scaleStartRange = 0;

  // ── Timer / animation ─────────────────────────────────────────
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Chrome heights ────────────────────────────────────────────
  static const double _paddingAll = 20.0;
  static const double _headerHeight = 40.0;
  static const double _gap1 = 12.0;
  static const double _gap2 = 8.0;
  static const double _zoomBarH = 36.0;
  static const double _scrollBarH = 24.0;
  static const double _chrome = (_paddingAll * 2) + _headerHeight + (_gap1 * 2) + (_gap2 * 2) + _zoomBarH + _scrollBarH + 24.0;

  int get _dataLength {
    switch (widget.selectedDuration) {
      case '5min':
        return 288;
      case '15min':
        return 96;
      case '30min':
        return 48;
      case '6hr':
        return 72; // 5-min buckets over 6 hours — enough points for a trend line
      case '24hr':
        return 96; // 15-min buckets over 24 hours
      case '1hr':
      default:
        return 24;
    }
  }

  double get _defaultVisibleRange {
    switch (widget.selectedDuration) {
      case '5min':
        return 24;
      case '15min':
        return 20;
      case '30min':
        return 16;
      case '6hr':
        return 24;
      case '24hr':
        return 24;
      case '1hr':
      default:
        return 12;
    }
  }

  double get _minZoomRange => 2.0;

  // For short durations (e.g. '24hr' â†' _dataLength == 1) the dataset is
  // shorter than _minZoomRange, which would make clamp(lower, upper) throw
  // since lower > upper. Cap the effective minimum at _dataLength so the
  // clamp call is always valid.
  double get _effectiveMinZoomRange => _minZoomRange.clamp(0.0, _dataLength.toDouble());
  double get _currentRange => _maxX - _minX;
  double get _thumbFraction => _dataLength > 0 ? (_currentRange / _dataLength).clamp(0.0, 1.0) : 1.0;
  double get _thumbStart => _dataLength > 0 ? (_minX / _dataLength).clamp(0.0, 1.0) : 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeData();
    _resetWindow();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChartCard old) {
    super.didUpdateWidget(old);
    final machinesChanged = old.machines.map((m) => m.id).join(',') !=
        widget.machines.map((m) => m.id).join(',');
    if (old.selectedDuration != widget.selectedDuration || machinesChanged) {
      setState(() {
        _awaitingDurationData = true;
        machineData = {for (var m in widget.machines) m.id: []};
        _initializeData();
        _resetWindow();
      });
    }
    if (old.powerFactorData != widget.powerFactorData) {
      _updateWithNewData();
    }
  }

  void _initializeData() {
    final rng = Random();
    machineData = {
      for (var m in widget.machines)
        m.id: () {
          double v = (0.75 + rng.nextDouble() * 0.2) * 200;
          return List.generate(_dataLength, (i) {
            v = (v + (rng.nextDouble() - 0.5) * 2).clamp(100.0, 200.0);
            return FlSpot(i.toDouble(), v);
          });
        }(),
    };
    monthlyMachineData = {
      for (var m in widget.machines)
        m.id: () {
          double v = (0.75 + rng.nextDouble() * 0.2) * 200;
          return List.generate(30, (i) {
            v = (v + (rng.nextDouble() - 0.5) * 2).clamp(100.0, 200.0);
            return FlSpot(i.toDouble(), v);
          });
        }(),
    };
  }

  void _startRealTimeUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !isMonthlyView && widget.powerFactorData == null) {
        setState(_updateLiveStreamData);
      }
    });
  }

  void _updateLiveStreamData() {
    final rng = Random();
    for (var m in widget.machines) {
      final list = machineData[m.id];
      if (list == null || list.isEmpty) continue;
      final newY = (list.last.y + (rng.nextDouble() - 0.5) * 2).clamp(0.0, 200.0);
      list.removeAt(0);
      list.add(FlSpot(49, newY));
      for (int i = 0; i < list.length; i++) {
        list[i] = FlSpot(i.toDouble(), list[i].y);
      }
    }
  }

  void _updateWithNewData() {
    if (!mounted || widget.powerFactorData == null) return;
    try {
      final api = widget.powerFactorData!;
      setState(() {
        _awaitingDurationData = false;
        if (api['data'] is List) {
          for (var item in api['data'] as List) {
            if (item is! Map) continue;
            final id = item['machine_id']?.toString();
            final pf = item['power_factor'];
            if (id == null || pf is! num) continue;
            final list = machineData[id];
            if (list == null || list.isEmpty) continue;
            list.removeAt(0);
            list.add(FlSpot(list.length.toDouble(), pf.toDouble() * 200));
            for (int i = 0; i < list.length; i++) {
              list[i] = FlSpot(i.toDouble(), list[i].y);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('ChartCard update error: $e');
    }
  }

  void _resetWindow() {
    _yOffset = 0;
    _zoomLevel = 1.0;
    _minX = 0;
    _maxX = _defaultVisibleRange.clamp(_effectiveMinZoomRange, _dataLength.toDouble());
  }

  void _clampWindow(double newMin, double newMax) {
    final range = newMax - newMin;
    double lo = newMin < 0 ? 0 : newMin;
    double hi = lo + range;
    if (hi > _dataLength) {
      hi = _dataLength.toDouble();
      lo = hi - range;
    }
    _minX = lo.clamp(0.0, (_dataLength - range).clamp(0.0, double.infinity));
    _maxX = _minX + range;
  }

  void _scrollLeft() {
    if (_minX <= 0) return;
    setState(() => _clampWindow(_minX - _currentRange * 0.2, _maxX - _currentRange * 0.2));
  }

  void _scrollRight() {
    if (_maxX >= _dataLength) return;
    setState(() => _clampWindow(_minX + _currentRange * 0.2, _maxX + _currentRange * 0.2));
  }

  void _zoomIn() {
    setState(() {
      final newRange = (_currentRange / 1.6).clamp(_effectiveMinZoomRange, _dataLength.toDouble());
      final center = (_minX + _maxX) / 2;
      _clampWindow(center - newRange / 2, center + newRange / 2);
      _zoomLevel = (_zoomLevel + 0.2).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      final newRange = (_currentRange * 1.5).clamp(_effectiveMinZoomRange, _dataLength.toDouble());
      final center = (_minX + _maxX) / 2;
      _clampWindow(center - newRange / 2, center + newRange / 2);
      _zoomLevel = (_zoomLevel - 0.2).clamp(_minZoom, _maxZoom);
    });
  }

  void _yUp() => setState(() => _yOffset += 10);
  void _yDown() => setState(() => _yOffset -= 10);
  void _yReset() => setState(() => _yOffset = 0);

  void _handlePointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      setState(() {
        final factor = e.scrollDelta.dy > 0 ? 1.15 : 0.87;
        final newRange = (_currentRange * factor).clamp(_effectiveMinZoomRange, _dataLength.toDouble());
        final center = (_minX + _maxX) / 2;
        _clampWindow(center - newRange / 2, center + newRange / 2);
        _zoomLevel = (_zoomLevel - e.scrollDelta.dy * 0.001).clamp(_minZoom, _maxZoom);
      });
    }
  }

  void _handleScaleStart(ScaleStartDetails d) => _scaleStartRange = _currentRange;

  void _handleScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      if (d.scale != 1.0) {
        final newRange = (_scaleStartRange / d.scale).clamp(_effectiveMinZoomRange, _dataLength.toDouble());
        final center = (_minX + _maxX) / 2;
        _clampWindow(center - newRange / 2, center + newRange / 2);
      } else if (d.focalPointDelta.dx != 0) {
        final chartWidth = context.size?.width ?? 600;
        final dx = -(d.focalPointDelta.dx / chartWidth) * _currentRange;
        _clampWindow(_minX + dx, _maxX + dx);
      }
    });
  }

  void _handleDragStart(DragStartDetails d) {
    _dragStartMinX = _minX;
    _dragStartX = d.localPosition.dx / (context.size?.width ?? 600) * _currentRange;
  }

  void _handleDragUpdate(DragUpdateDetails d) {
    if (_dragStartMinX == null || _dragStartX == null) return;
    setState(() {
      final currentXOffset = d.localPosition.dx / (context.size?.width ?? 600) * _currentRange;
      final dx = _dragStartX! - currentXOffset;
      _clampWindow(_dragStartMinX! + dx, _dragStartMinX! + dx + _currentRange);
    });
  }

  void _handleDragEnd(DragEndDetails _) {
    _dragStartX = null;
    _dragStartMinX = null;
  }

  ({double minY, double maxY}) _yBounds(List<List<FlSpot>> all) {
    double lo = 200, hi = 0;
    for (final spots in all) {
      for (final s in spots) {
        if (s.x < _minX || s.x > _maxX) continue;
        if (s.y < lo) lo = s.y;
        if (s.y > hi) hi = s.y;
      }
    }
    if (lo >= hi) {
      lo = 0;
      hi = 200;
    }
    final center = (lo + hi) / 2;
    final range = hi - lo;
    final zr = (min(200.0, hi + range * 0.3) - max(0.0, lo - range * 0.3)) / _zoomLevel;
    return (minY: center - zr / 2 + _yOffset, maxY: center + zr / 2 + _yOffset);
  }

  String _formatTimeLabel(int idx) {
    int stepMin;
    switch (widget.selectedDuration) {
      case '5min':
        stepMin = 5;
        break;
      case '15min':
        stepMin = 15;
        break;
      case '30min':
        stepMin = 30;
        break;
      case '6hr':
        stepMin = 360;
        break;
      case '24hr':
        stepMin = 1440;
        break;
      default:
        stepMin = 60;
    }
    final totalMin = idx * stepMin;
    final h = (totalMin ~/ 60) % 24;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardH = constraints.hasBoundedHeight ? constraints.maxHeight : (MediaQuery.of(context).size.height * 0.65).clamp(480.0, 960.0);
      final chartH = (cardH - _chrome).clamp(80.0, double.infinity);

      return SizedBox(
        width: double.infinity,
        height: cardH,
        child: CardWidget(
          topPadMultiplier: 1.0,
          builder: (context, sizing) => SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: _headerHeight, child: _buildHeader()),
                const SizedBox(height: _gap1),
                SizedBox(
                  height: chartH,
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildXArrow(isLeft: true),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildChart()),
                                const SizedBox(width: 6),
                                _buildYArrows(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildXArrow(isLeft: false),
                        ],
                      ),
                      if (_awaitingDurationData)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(0, 4, 51, 0.75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF0EA5E9), strokeWidth: 2),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading ${widget.selectedDuration} data…',
                                  style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: _gap2),
                SizedBox(height: _scrollBarH, child: _buildScrollIndicator()),
                const SizedBox(height: _gap2),
                SizedBox(height: _zoomBarH, child: _buildZoomIndicator()),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Opacity(
              opacity: isMonthlyView ? 0.5 : _pulseAnimation.value,
              child: Icon(Icons.circle, size: 8, color: isMonthlyView ? Colors.grey : const Color(0xFF10b981)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isMonthlyView ? 'MONTHLY POWER ANALYTICS' : 'LIVE STREAM',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.5)),
            ),
            child: Text(
              widget.selectedDuration,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0EA5E9)),
            ),
          ),
        ]),
        Row(children: [
          _iconBtn(Icons.zoom_in, _zoomIn, tooltip: 'Zoom In'),
          const SizedBox(width: 4),
          _iconBtn(Icons.zoom_out, _zoomOut, tooltip: 'Zoom Out'),
          const SizedBox(width: 12),
          _toggleBtn('Real time', !isMonthlyView, () => setState(() => isMonthlyView = false)),
          const SizedBox(width: 8),
          _toggleBtn('Monthly', isMonthlyView, () => setState(() => isMonthlyView = true)),
        ]),
      ],
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0EA5E9) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: active ? const Color(0xFF0EA5E9) : const Color(0xFF475569)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: active ? Colors.white : const Color(0xFF94A3B8), fontWeight: active ? FontWeight.w500 : FontWeight.w400)),
        ),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap, {String? tooltip}) => Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 16),
          ),
        ),
      );

  Widget _buildXArrow({required bool isLeft}) {
    final canScroll = isLeft ? _minX > 0 : _maxX < _dataLength;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: canScroll ? (isLeft ? _scrollLeft : _scrollRight) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canScroll ? const Color(0xFF0EA5E9).withOpacity(0.15) : Colors.white.withOpacity(0.03),
              border: Border.all(
                color: canScroll ? const Color(0xFF0EA5E9).withOpacity(0.6) : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: canScroll ? Colors.white : Colors.white24,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYArrows() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _yArrowBtn(Icons.keyboard_arrow_up, _yUp, tooltip: 'Y Up'),
          const SizedBox(height: 4),
          _yArrowBtn(Icons.refresh, _yReset, tooltip: 'Reset Y'),
          const SizedBox(height: 4),
          _yArrowBtn(Icons.keyboard_arrow_down, _yDown, tooltip: 'Y Down'),
        ],
      );

  Widget _yArrowBtn(IconData icon, VoidCallback onTap, {String? tooltip}) => Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 16),
          ),
        ),
      );

  Widget _buildChart() {
    final activeMap = isMonthlyView ? monthlyMachineData : machineData;
    final bars = <LineChartBarData>[];
    final active = <MachineConfig>[];
    final allSpots = <List<FlSpot>>[];

    for (var m in widget.machines) {
      if (widget.machineChecked[m.id] != true) continue;
      final spots = activeMap[m.id] ?? [];
      if (spots.isEmpty) continue;
      active.add(m);
      allSpots.add(spots);
      bars.add(LineChartBarData(
        spots: spots,
        isCurved: false,
        isStepLineChart: false,
        color: m.color,
        barWidth: 2.5 * _zoomLevel,
        isStrokeCapRound: true,
        dotData: FlDotData(show: _zoomLevel > 1.5),
        belowBarData: BarAreaData(show: false),
      ));
    }

    if (bars.isEmpty) {
      return Center(
        child: Text('Select at least one machine to display', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
      );
    }

    final b = _yBounds(allSpots);

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: ClipRect(
          child: LineChart(LineChartData(
            lineTouchData: _touch(active),
            gridData: _grid(),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: isMonthlyView ? _monthlyBottomTitles() : _liveBottomTitles(),
              leftTitles: _leftTitles(b.minY, b.maxY),
            ),
            borderData: FlBorderData(show: false),
            minX: isMonthlyView ? 0 : _minX,
            maxX: isMonthlyView ? 29 : _maxX,
            minY: b.minY,
            maxY: b.maxY,
            lineBarsData: bars,
          )),
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    if (_currentRange >= _dataLength || _dataLength == 0) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final totalW = constraints.maxWidth;
      final thumbW = (_thumbFraction * totalW).clamp(16.0, totalW);
      final thumbL = (_thumbStart * totalW).clamp(0.0, totalW - thumbW);
      return Column(children: [
        Stack(children: [
          Container(height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
          Positioned(
            left: thumbL,
            child: Container(
                width: thumbW, height: 4, decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(2))),
          ),
        ]),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Showing ${_minX.toInt() + 1}–${_maxX.toInt()} of $_dataLength pts',
                style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF475569))),
            Text('Scroll · Drag · Pinch to zoom', style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF475569))),
          ],
        ),
      ]);
    });
  }

  Widget _buildZoomIndicator() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Color(0xFF64748B), size: 16),
            onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(_minZoom, _maxZoom)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Text('${(_zoomLevel * 100).toInt()}%',
                style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF64748B), size: 16),
            onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(_minZoom, _maxZoom)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );

  AxisTitles _liveBottomTitles() => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: max(1, (_currentRange / 6).ceilToDouble()),
          getTitlesWidget: (v, _) {
            final idx = v.toInt();
            if (idx < 0 || idx >= _dataLength) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_formatTimeLabel(idx), style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 9)),
            );
          },
        ),
      );

  AxisTitles _monthlyBottomTitles() => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: max(1, 2 / _zoomLevel),
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i >= 0 && i % 5 == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('D${i + 1}', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 9)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );

  LineTouchData _touch(List<MachineConfig> active) => LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1E293B),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tooltipMargin: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          maxContentWidth: 200,
          getTooltipItems: (spots) => spots.map((s) {
            final m = active[s.barIndex];
            return LineTooltipItem(
              '${m.name}  ${_formatTimeLabel(s.x.toInt())}\n${(s.y / 200).toStringAsFixed(3)}',
              GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              children: [
                TextSpan(
                  text: '\nPower Factor',
                  style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w400),
                ),
              ],
            );
          }).toList(),
        ),
        handleBuiltInTouches: true,
      );

  FlGridData _grid() => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: max(10, 40 / _zoomLevel),
        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF334155), strokeWidth: 1),
      );

  AxisTitles _leftTitles(double minY, double maxY) {
    final interval = max(10.0, (maxY - minY) / 5);
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: interval,
        reservedSize: 42,
        getTitlesWidget: (v, _) => Text(
          (v / 200).toStringAsFixed(2),
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10),
        ),
      ),
    );
  }
}
