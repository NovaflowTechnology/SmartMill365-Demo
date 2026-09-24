import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'dart:async';
import 'dart:math';

import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class ProductionCardWidget extends StatefulWidget {
  final int actualProduction;
  final int plannedProduction;
  final bool isLoading;
  final List<Map<String, dynamic>> machineEfficiencyData;
  final String? woId;
  final String? opId;

  const ProductionCardWidget({
    Key? key,
    this.actualProduction = 0,
    this.plannedProduction = 0,
    this.isLoading = false,
    this.machineEfficiencyData = const [],
    this.woId,
    this.opId,
  }) : super(key: key);

  @override
  State<ProductionCardWidget> createState() => _ProductionCardWidgetState();
}

class _ProductionCardWidgetState extends State<ProductionCardWidget> {
  List<FlSpot> actualData = [];
  List<DateTime> timestamps = [];
  List<DateTime> originalTimestamps = [];
  Timer? _timer;
  double maxY = 10000;
  bool hasValidData = false;

  static const int SHIFT_START_HOUR = 8;
  static const int SHIFT_END_HOUR = 8;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startRealTimeUpdates();
  }

  @override
  void didUpdateWidget(ProductionCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actualProduction != widget.actualProduction ||
        oldWidget.machineEfficiencyData.length !=
            widget.machineEfficiencyData.length) {
      _updateDataFromProps();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeData() {
    _updateDataFromProps();
  }

  void _updateDataFromProps() {
    bool hasData = false;

    if (widget.machineEfficiencyData.isNotEmpty) {
      hasData = widget.machineEfficiencyData.any((data) =>
          (data['ActualProductionQuantity'] as num?)?.toDouble() != null &&
          (data['ActualProductionQuantity'] as num?)?.toDouble() != 0);
    }

    if (!hasData && widget.actualProduction > 0) {
      hasData = true;
    }

    if (hasData) {
      if (widget.machineEfficiencyData.isNotEmpty) {
        _processEfficiencyData();
      } else {
        _generateDataFromTotals();
      }
    } else {
      _clearData();
    }
  }

  DateTime _getShiftStart(DateTime now) {
    DateTime shiftStart =
        DateTime(now.year, now.month, now.day, SHIFT_START_HOUR, 0, 0);
    if (now.hour < SHIFT_START_HOUR) {
      shiftStart = shiftStart.subtract(const Duration(days: 1));
    }
    return shiftStart;
  }

  DateTime _getShiftEnd(DateTime shiftStart) {
    return shiftStart.add(const Duration(hours: 24));
  }

  double _getMinutesFromShiftStart(DateTime timestamp, DateTime shiftStart) {
    return timestamp.difference(shiftStart).inMinutes.toDouble();
  }

  void _processEfficiencyData() {
    List<FlSpot> newActualData = [];
    List<DateTime> newTimestamps = [];
    List<DateTime> newOriginalTimestamps = [];

    print('🔍 Processing efficiency data (8am-8am shift):');
    print('   Data count: ${widget.machineEfficiencyData.length}');

    List<Map<String, dynamic>> sortedData =
        List.from(widget.machineEfficiencyData);

    // Find the date range from the actual data
    DateTime? dataStart;
    DateTime? dataEnd;
    for (var record in sortedData) {
      final ts = DateTime.tryParse(_extractTimestamp(record));
      if (ts != null) {
        if (dataStart == null || ts.isBefore(dataStart)) dataStart = ts;
        if (dataEnd == null || ts.isAfter(dataEnd)) dataEnd = ts;
      }
    }
    // Use data range as shift window, fall back to today's shift
    DateTime now = DateTime.now();
    DateTime shiftStart = dataStart ?? _getShiftStart(now);
    DateTime shiftEnd = dataEnd?.add(const Duration(minutes: 1)) ?? _getShiftEnd(shiftStart);

    sortedData.sort((a, b) {
      try {
        String timestampA = _extractTimestamp(a);
        String timestampB = _extractTimestamp(b);
        if (timestampA.isNotEmpty && timestampB.isNotEmpty) {
          DateTime? dateA = DateTime.tryParse(timestampA);
          DateTime? dateB = DateTime.tryParse(timestampB);
          if (dateA != null && dateB != null) {
            return dateA.compareTo(dateB);
          }
        }
      } catch (e) {
        print('⚠️ Error sorting data: $e');
      }
      return 0;
    });

    double maxActualValue = 0;
    Map<double, int> usedXPositions = {};

    for (int i = 0; i < sortedData.length; i++) {
      var record = sortedData[i];
      double actualQty =
          (record['ActualProductionQuantity'] as num?)?.toDouble() ?? 0.0;
      String timestampStr = _extractTimestamp(record);
      DateTime? timestamp = DateTime.tryParse(timestampStr);

      if (timestamp != null) {
        DateTime originalTimestamp = timestamp;
        print(
            '   📍 Original API Timestamp: ${_formatFullTimestamp(originalTimestamp)}');

        DateTime adjustedTimestamp = _roundToNearest5Minutes(timestamp);
        print(
            '   📍 Rounded for Chart: ${_formatFullTimestamp(adjustedTimestamp)}');

        if (adjustedTimestamp.isAfter(shiftStart) &&
            adjustedTimestamp.isBefore(shiftEnd)) {
          double minutesFromStart =
              _getMinutesFromShiftStart(adjustedTimestamp, shiftStart);
          double adjustedX = minutesFromStart;

          if (usedXPositions.containsKey(minutesFromStart)) {
            int overlapCount = usedXPositions[minutesFromStart]!;
            adjustedX = minutesFromStart + (overlapCount * 0.5);
            usedXPositions[minutesFromStart] = overlapCount + 1;
          } else {
            usedXPositions[minutesFromStart] = 1;
          }

          newActualData.add(FlSpot(adjustedX, actualQty));
          newTimestamps.add(adjustedTimestamp);
          newOriginalTimestamps.add(originalTimestamp);

          if (actualQty > maxActualValue) {
            maxActualValue = actualQty;
          }

          print(
              '   Point ${newActualData.length}: Time=${_formatTime(adjustedTimestamp)}, Original=${_formatFullTimestamp(originalTimestamp)}, Minutes=${adjustedX.toStringAsFixed(1)}, Qty=$actualQty');
        } else {
          print(
              '   ⚠️ Skipped (outside shift): Time=${_formatDateTime(adjustedTimestamp)}, Qty=$actualQty');
        }
      }
    }

    print('✅ Final data processed:');
    print('   Total points in shift: ${newActualData.length}');
    print('   Max value: $maxActualValue');

    setState(() {
      actualData = newActualData;
      timestamps = newTimestamps;
      originalTimestamps = newOriginalTimestamps;
      maxY = maxActualValue > 0 ? (maxActualValue * 1.2).ceilToDouble() : 10000;
      hasValidData = newActualData.isNotEmpty;
    });
  }

  DateTime _roundToNearest5Minutes(DateTime timestamp) {
    int minutes = timestamp.minute;
    int roundedMinutes = ((minutes / 5).round() * 5) % 60;
    int hour = timestamp.hour;
    if (roundedMinutes == 0 && minutes >= 58) {
      hour = (hour + 1) % 24;
    }
    return DateTime(
        timestamp.year, timestamp.month, timestamp.day, hour, roundedMinutes);
  }

  String _extractTimestamp(Map<String, dynamic> data) {
    if (data.containsKey('Timestamp') && data['Timestamp'] != null)
      return data['Timestamp'].toString();
    if (data.containsKey('DateTime') && data['DateTime'] != null)
      return data['DateTime'].toString();
    if (data.containsKey('FirstTimestamp') && data['FirstTimestamp'] != null)
      return data['FirstTimestamp'].toString();
    if (data.containsKey('Date') && data['Date'] != null)
      return data['Date'].toString();
    return '';
  }

  void _generateDataFromTotals() {
    _generateDataFromTotalsWithValues(widget.actualProduction.toDouble());
  }

  void _generateDataFromTotalsWithValues(double actualTarget) {
    if (actualTarget <= 0) {
      _clearData();
      return;
    }

    print('📊 Generating data from totals (8am-8am shift):');
    print('   Actual Target: $actualTarget');

    DateTime now = DateTime.now();
    DateTime shiftStart = _getShiftStart(now);
    double minutesElapsed = _getMinutesFromShiftStart(now, shiftStart);
    double totalShiftMinutes = 24 * 60;

    List<FlSpot> newActualData = [];
    List<DateTime> newTimestamps = [];

    int pointsToShow = (minutesElapsed / 5).ceil() + 1;

    for (int i = 0; i < pointsToShow; i++) {
      double minutesFromStart = i * 5.0;
      if (minutesFromStart > minutesElapsed) break;

      double progress = minutesFromStart / totalShiftMinutes;
      double curveProgress = _productionCurve(progress);
      double actualValue = actualTarget * curveProgress;

      DateTime pointTime =
          shiftStart.add(Duration(minutes: minutesFromStart.toInt()));

      newActualData.add(FlSpot(minutesFromStart, actualValue));
      newTimestamps.add(pointTime);
    }

    setState(() {
      actualData = newActualData;
      timestamps = newTimestamps;
      maxY = actualTarget > 0 ? (actualTarget * 1.2).ceilToDouble() : 10000;
      hasValidData = true;
    });
  }

  void _clearData() {
    setState(() {
      actualData = [];
      timestamps = [];
      originalTimestamps = [];
      maxY = 10000;
      hasValidData = false;
    });
  }

  double _productionCurve(double t) {
    return 0.5 * (1 - cos(pi * t));
  }

  void _startRealTimeUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !widget.isLoading && hasValidData) {
        setState(() {
          final random = Random();
          if (actualData.isNotEmpty) {
            final lastActualIndex = actualData.length - 1;
            final lastActual = actualData[lastActualIndex].y;
            final maxPossible = maxY * 0.8;

            if (lastActual < maxPossible) {
              final increment = random.nextDouble() * (maxY * 0.01);
              final newValue = min(lastActual + increment, maxPossible);
              actualData[lastActualIndex] =
                  FlSpot(actualData[lastActualIndex].x, newValue);
            }
          }
        });
      }
    });
  }

  String _formatYAxisLabel(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toInt().toString();
  }

  double _calculateInterval() {
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    if (maxY <= 50000) return 10000;
    if (maxY <= 100000) return 20000;
    return (maxY / 5).ceilToDouble();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${_formatTime(dt)}';
  }

  String _formatFullTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _getTimeLabel(double minutes) {
    int totalMinutes = minutes.toInt();
    int hoursFromStart = totalMinutes ~/ 60;
    int hour = (8 + hoursFromStart) % 24;
    return hour.toString().padLeft(2, '0');
  }

  Widget _buildEmptyGraph() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _calculateInterval(),
          verticalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isLight ? theme.cardStroke : const Color(0xFF94a3b8)).withOpacity(0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: (isLight ? theme.cardStroke : const Color(0xFF94a3b8)).withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 120,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _getTimeLabel(value),
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 11),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(),
              reservedSize: 60,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _formatYAxisLabel(value),
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 11),
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: isLight ? theme.cardStroke : const Color(0xFF94a3b8).withOpacity(0.2)),
        ),
        minX: 0,
        maxX: 1440,
        minY: 0,
        maxY: maxY,
        lineBarsData: [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => SizedBox(
        height: 410,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Today Production Progress',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.0,
                                      font: GoogleFonts.poppins(),
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(" + _getCurrentDate() + ")",
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.0,
                                      font: GoogleFonts.poppins(),
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.woId != null &&
                                  widget.woId!.isNotEmpty)
                                Row(
                                  children: [
                                    Text(
                                      'WO ID: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      widget.woId!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: FlutterFlowTheme.of(context)
                                            .txtPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              if (widget.opId != null &&
                                  widget.opId!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        'OP ID: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.opId!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: FlutterFlowTheme.of(context)
                                              .txtPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasValidData
                      ? Stack(children: [_buildEmptyGraph()])
                      : LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) =>
                                    isLight ? theme.primaryText.withOpacity(0.95) : const Color(0xFF1e293b).withOpacity(0.95),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                tooltipMargin: 8,
                                getTooltipItems:
                                    (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots
                                      .map((LineBarSpot touchedSpot) {
                                    final index = touchedSpot.spotIndex;
                                    if (index < 0 || index >= timestamps.length)
                                      return null;

                                    final timestamp =
                                        originalTimestamps.isNotEmpty
                                            ? originalTimestamps[index]
                                            : timestamps[index];
                                    final units = touchedSpot.y.toInt();

                                    return LineTooltipItem(
                                      '',
                                      const TextStyle(),
                                      children: [
                                        TextSpan(
                                          text: 'Units: ',
                                          style: TextStyle(
                                            color: isLight ? theme.txtMuted : const Color(0xFF94a3b8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '${units.toString()}\n',
                                          style: const TextStyle(
                                            color: Color(0xFF3b82f6),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Time: ',
                                          style: TextStyle(
                                            color: isLight ? theme.txtMuted : const Color(0xFF94a3b8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _formatFullTimestamp(timestamp),
                                          style: TextStyle(
                                            color: isLight ? theme.txtPrimary : const Color(0xFFe2e8f0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: (FlTouchEvent event,
                                  LineTouchResponse? touchResponse) {},
                              handleBuiltInTouches: true,
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: _calculateInterval(),
                              verticalInterval: 5,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: FlutterFlowTheme.of(context)
                                    .alternate
                                    .withOpacity(0.5),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: FlutterFlowTheme.of(context)
                                    .alternate
                                    .withOpacity(0.5),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 120,
                                  getTitlesWidget: (value, meta) =>
                                      SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      _getTimeLabel(value),
                                      style: TextStyle(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 11),
                                    ),
                                  ),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _calculateInterval(),
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) =>
                                      SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      _formatYAxisLabel(value),
                                      style: TextStyle(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 11),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                  color:
                                      FlutterFlowTheme.of(context).cardStroke),
                            ),
                            minX: 0,
                            maxX: 1440,
                            minY: 0,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: actualData,
                                isCurved: false,
                                color: const Color(0xFF3b82f6),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFF3b82f6),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      const Color(0xFF3b82f6).withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                    'Actual Production Qty', const Color(0xFF3b82f6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Builder(builder: (context) {
          return Text(
            label,
            style: TextStyle(
                fontSize: 12, color: FlutterFlowTheme.of(context).txtPrimary),
          );
        }),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day:$month:$year';
  }
}
