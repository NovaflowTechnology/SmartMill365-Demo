import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'dart:async';

import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class DowntimeAnalysisCardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> machineEfficiencyData;
  final List<Map<String, dynamic>> plannedInputData;
  final bool isLoading;
  final String? machineId;
  final Function(String period)? onPeriodChanged;

  const DowntimeAnalysisCardWidget({
    Key? key,
    this.machineEfficiencyData = const [],
    this.plannedInputData = const [],
    this.isLoading = false,
    this.machineId,
    this.onPeriodChanged,
  }) : super(key: key);

  @override
  State<DowntimeAnalysisCardWidget> createState() => _DowntimeAnalysisCardWidgetState();
}

class _DowntimeAnalysisCardWidgetState extends State<DowntimeAnalysisCardWidget> {
  List<double> actualProductionData = [];
  List<double> plannedProductionData = [];
  List<double> completionRateData = [];
  List<String> labels = [];

  String selectedPeriod = 'Daily';
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _processEfficiencyData();
    _startChartAnimation();
  }

  @override
  void didUpdateWidget(DowntimeAnalysisCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.machineEfficiencyData != oldWidget.machineEfficiencyData ||
        widget.plannedInputData != oldWidget.plannedInputData) {
      _processEfficiencyData();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startChartAnimation() {
    _animationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && actualProductionData.isNotEmpty) {
        setState(() {});
      }
    });
  }

  void _processEfficiencyData() {
    if (widget.machineEfficiencyData.isEmpty && widget.plannedInputData.isEmpty) {
      setState(() {
        actualProductionData = [];
        plannedProductionData = [];
        completionRateData = [];
        labels = [];
      });
      return;
    }

    setState(() {
      actualProductionData = [];
      plannedProductionData = [];
      completionRateData = [];
      labels = [];

      Map<String, double> actualDataMap = {};
      Map<String, double> plannedDataMap = {};
      Map<String, String> labelMap = {};

      for (var record in widget.machineEfficiencyData) {
        final actual = (record['Machine_Actual_Quantity'] as num?)?.toDouble() ?? 0.0;
        final dateKey = record['date_only']?.toString() ?? record['formatted_date']?.toString() ?? '';
        final label = record['formatted_date']?.toString() ?? '';

        if (dateKey.isNotEmpty) {
          actualDataMap[dateKey] = actual;
          if (label.isNotEmpty) labelMap[dateKey] = label;
        }
      }

      for (var record in widget.plannedInputData) {
        final planned = (record['Planned_Production_Qty'] as num?)?.toDouble() ?? 0.0;
        final dateKey = record['date_only']?.toString() ?? record['formatted_date']?.toString() ?? '';
        final label = record['formatted_date']?.toString() ?? '';

        if (dateKey.isNotEmpty) {
          plannedDataMap[dateKey] = planned;
          if (label.isNotEmpty && !labelMap.containsKey(dateKey)) labelMap[dateKey] = label;
        }
      }

      final allDates = {...actualDataMap.keys, ...plannedDataMap.keys}.toList();
      allDates.sort((a, b) => a.compareTo(b));

      final datesToShow = allDates.length > 15 ? allDates.sublist(allDates.length - 15) : allDates;

      for (var dateKey in datesToShow) {
        final actual = actualDataMap[dateKey] ?? 0.0;
        final planned = plannedDataMap[dateKey] ?? 0.0;

        actualProductionData.add(actual);
        plannedProductionData.add(planned);

        final completionRate = planned > 0 ? (actual / planned * 100).clamp(0.0, 120.0) : 0.0;
        completionRateData.add(completionRate);

        String label = labelMap[dateKey] ?? '';
        if (label.isEmpty) label = _generateFallbackLabel(dateKey);
        labels.add(label);
      }

      print('✅ Processed efficiency data:');
      print('   Actual data points: ${actualProductionData.length}');
      print('   Planned data points: ${plannedProductionData.length}');
      print('   Labels: $labels');
    });
  }

  String _generateFallbackLabel(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      switch (selectedPeriod.toLowerCase()) {
        case 'daily':
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
        case 'weekly':
          return 'W${(date.day / 7).ceil()}';
        case 'monthly':
          return '${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
        default:
          return dateKey;
      }
    } catch (e) {
      return dateKey;
    }
  }

  void _cyclePeriod() {
    final periods = ['Daily', 'Weekly', 'Monthly'];
    final currentIndex = periods.indexOf(selectedPeriod);
    final newPeriod = periods[(currentIndex + 1) % periods.length];

    setState(() {
      selectedPeriod = newPeriod;
    });

    if (widget.onPeriodChanged != null) {
      widget.onPeriodChanged!(newPeriod.toLowerCase());
    }
  }

  String get periodDescription {
    switch (selectedPeriod.toLowerCase()) {
      case 'daily':
        return 'Last 30 days';
      case 'weekly':
        return 'Last 12 weeks';
      case 'monthly':
        return 'Last 12 months';
      default:
        return '';
    }
  }

  String _getDateRangeText() {
    if (labels.isEmpty) return periodDescription;
    final oldestLabel = labels.first;
    final newestLabel = labels.last;
    return '$oldestLabel - $newestLabel';
  }

  double get maxY {
    if (actualProductionData.isEmpty && plannedProductionData.isEmpty) return 100.0;
    final maxActual = actualProductionData.isEmpty ? 0.0 : actualProductionData.reduce((a, b) => a > b ? a : b);
    final maxPlanned = plannedProductionData.isEmpty ? 0.0 : plannedProductionData.reduce((a, b) => a > b ? a : b);
    final maxValue = [maxActual, maxPlanned, 100.0].reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  double get yAxisInterval {
    final max = maxY;
    if (max <= 50) return 10;
    if (max <= 100) return 20;
    if (max <= 500) return 50;
    if (max <= 1000) return 100;
    if (max <= 5000) return 500;
    return (max / 8).ceilToDouble();
  }

  List<BarChartGroupData> _buildEmptyBarGroups() {
    int barCount;
    switch (selectedPeriod.toLowerCase()) {
      case 'weekly':
        barCount = 12;
        break;
      case 'monthly':
        barCount = 12;
        break;
      default:
        barCount = 7;
    }

    return List.generate(barCount, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: 0,
            color: const Color(0xFF3b82f6).withOpacity(0.3),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          BarChartRodData(
            toY: 0,
            color: const Color(0xFF10b981).withOpacity(0.3),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
      );
    });
  }

  List<String> _getEmptyLabels() {
    final now = DateTime.now();
    switch (selectedPeriod.toLowerCase()) {
      case 'weekly':
        return List.generate(12, (index) {
          final weeksAgo = 11 - index;
          return 'W${now.subtract(Duration(days: weeksAgo * 7)).day ~/ 7 + 1}';
        });
      case 'monthly':
        return List.generate(12, (index) {
          final monthsAgo = 11 - index;
          final date = DateTime(now.year, now.month - monthsAgo, 1);
          return '${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
        });
      default:
        return List.generate(7, (index) {
          final daysAgo = 6 - index;
          final date = now.subtract(Duration(days: daysAgo));
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
        });
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (actualProductionData.isEmpty && plannedProductionData.isEmpty) return [];

    final maxLength = actualProductionData.length > plannedProductionData.length
        ? actualProductionData.length
        : plannedProductionData.length;

    return List.generate(maxLength, (index) {
      final actualValue = index < actualProductionData.length ? actualProductionData[index] : 0.0;
      final plannedValue = index < plannedProductionData.length ? plannedProductionData[index] : 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: actualValue,
            color: const Color(0xFF3b82f6),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          BarChartRodData(
            toY: plannedValue,
            color: const Color(0xFF10b981),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Builder(builder: (context) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          return Text(label, style: TextStyle(fontSize: 12, color: isLight ? FlutterFlowTheme.of(context).txtPrimary : const Color(0xFFe2e8f0)));
        }),
      ],
    );
  }

  Widget _buildDataInfo() {
    final totalActual = actualProductionData.isNotEmpty ? actualProductionData.reduce((a, b) => a + b).toInt() : 0;
    final totalPlanned = plannedProductionData.isNotEmpty ? plannedProductionData.reduce((a, b) => a + b).toInt() : 0;
    final efficiency = totalPlanned > 0 ? ((totalActual / totalPlanned) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: efficiency >= 90
            ? Colors.green.withOpacity(0.2)
            : efficiency >= 75
                ? Colors.orange.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${selectedPeriod} Efficiency: $efficiency% (${totalActual}/${totalPlanned})',
        style: TextStyle(
          fontSize: 11,
          color: efficiency >= 90
              ? Colors.green
              : efficiency >= 75
                  ? Colors.orange
                  : Colors.red,
          fontWeight: FontWeight.w500,
        ),
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
        height: 450,
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
                      Text(
                        'Machine Production Output Analysis',
                        style: FlutterFlowTheme.of(context).headlineSmall.override(
                              fontFamily: 'Poppins',
                              letterSpacing: 0.0,
                              font: GoogleFonts.poppins(),
                            ),
                      ),
                      Builder(builder: (context) {
                        final isLight = Theme.of(context).brightness == Brightness.light;
                        return Text(
                          _getDateRangeText(),
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Poppins',
                                color: isLight ? FlutterFlowTheme.of(context).secondaryText : Colors.white70,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        );
                      }),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.isLoading ? null : _cyclePeriod,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isLoading
                          ? const Color(0xFFf97316).withOpacity(0.5)
                          : const Color(0xFFf97316),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedPeriod,
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLoading
                  ? 'Loading ${selectedPeriod.toLowerCase()} data...'
                  : (widget.machineEfficiencyData.isNotEmpty || widget.plannedInputData.isNotEmpty)
                      ? ''
                      : 'No data available for ${selectedPeriod.toLowerCase()} view',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Poppins',
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Builder(builder: (context) {
                            final isLight = Theme.of(context).brightness == Brightness.light;
                            return Text(
                              'Loading ${selectedPeriod.toLowerCase()} efficiency data...',
                              style: TextStyle(color: isLight ? FlutterFlowTheme.of(context).secondaryText : Colors.white70),
                            );
                          }),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY,
                            barTouchData: BarTouchData(
                              enabled: actualProductionData.isNotEmpty,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => isLight ? theme.primaryText : const Color(0xFF1f2937),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  if (actualProductionData.isEmpty && plannedProductionData.isEmpty) return null;
                                  String label = rodIndex == 0
                                      ? 'Actual: ${rod.toY.toInt()} units'
                                      : 'Planned: ${rod.toY.toInt()} units';
                                  return BarTooltipItem(
                                    label,
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  interval: yAxisInterval,
                                  getTitlesWidget: (value, meta) {
                                    if (value % yAxisInterval == 0) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: Text(
                                          '${value.toInt()}',
                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: 'Poppins',
                                                fontSize: 9,
                                                letterSpacing: 0.0,
                                                font: GoogleFonts.poppins(),
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    final labelsToUse = actualProductionData.isNotEmpty ||
                                            plannedProductionData.isNotEmpty
                                        ? labels
                                        : _getEmptyLabels();

                                    if (index >= 0 && index < labelsToUse.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 4,
                                        child: Text(
                                          labelsToUse[index],
                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: 'Poppins',
                                                fontSize: 9,
                                                letterSpacing: 0.0,
                                                font: GoogleFonts.poppins(),
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 70,
                                  interval: yAxisInterval,
                                  getTitlesWidget: (value, meta) {
                                    if (value % yAxisInterval == 0) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 8,
                                        child: Text(
                                          value.toInt().toString(),
                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: 'Poppins',
                                                fontSize: 9,
                                                letterSpacing: 0.0,
                                                font: GoogleFonts.poppins(),
                                              ),
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: FlutterFlowTheme.of(context).cardStroke),
                            ),
                            barGroups: (actualProductionData.isEmpty && plannedProductionData.isEmpty)
                                ? _buildEmptyBarGroups()
                                : _buildBarGroups(),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: yAxisInterval,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                        ),
                        if (actualProductionData.isEmpty && plannedProductionData.isEmpty && !widget.isLoading)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.analytics_outlined, size: 48, color: FlutterFlowTheme.of(context).secondaryText),
                                const SizedBox(height: 12),
                                Text(
                                  'No ${selectedPeriod} Data Available',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        font: GoogleFonts.poppins(),
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: [
                _buildLegendItem('Actual Production Qty', const Color(0xFF3b82f6)),
                _buildLegendItem('Planned Production Qty', const Color(0xFF10b981)),
                if (widget.machineEfficiencyData.isNotEmpty || widget.plannedInputData.isNotEmpty)
                  _buildDataInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}