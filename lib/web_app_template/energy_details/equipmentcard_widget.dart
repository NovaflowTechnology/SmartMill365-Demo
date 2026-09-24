import 'package:flutter/material.dart';
import 'package:smartmachine365/utils/leak_probe.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import '/components/card_widget/card_widget.dart';

class EquipmentCardWidget extends StatefulWidget {
  final Map<String, dynamic> currentData;
  final Map<String, dynamic> voltageData;
  final Map<String, dynamic> powerData;

  const EquipmentCardWidget({Key? key, required this.currentData, required this.voltageData, required this.powerData}) : super(key: key);

  @override
  State<EquipmentCardWidget> createState() => _EquipmentCardWidgetState();
}

class _EquipmentCardWidgetState extends State<EquipmentCardWidget> with TickerProviderStateMixin {
  List<FlSpot> voltageChartData = [];
  List<FlSpot> currentChartData = [];
  List<FlSpot> powerChartData = [];

  late TimerDrivenAnimation _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = TimerDrivenAnimation(
        period: const Duration(seconds: 4), reverse: true);

    _initializeData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Get current values from real data
    double currentVoltage = _extractVoltageValue();
    double currentCurrent = _extractCurrentValue();
    double currentPower = _extractPowerValue();

    // Seed the 20-point window at the current reading. This used to add
    // Random() variation per point, which drew a history that never happened —
    // the wiggle looked like past measurements but was noise. A flat line at
    // the true value still fills the chart, and the fabricated past is gone;
    // real points shift in from the right as readings arrive.
    for (int i = 0; i < 20; i++) {
      voltageChartData.add(FlSpot(i.toDouble(), currentVoltage));
      currentChartData.add(FlSpot(i.toDouble(), currentCurrent));
      powerChartData.add(FlSpot(i.toDouble(), currentPower));
    }
  }

  // A 2s Timer.periodic used to live here, re-rendering all three charts with
  // Random() jitter layered on top of the real values. It repainted far faster
  // than the 5s data poll, so the extra movement was noise rather than data —
  // at the cost of pegging a CPU core. The charts now advance only when real
  // values arrive, via didUpdateWidget → _updateChartWithNewData().

  @override
  void didUpdateWidget(EquipmentCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update chart data when new data is received
    if (oldWidget.currentData != widget.currentData || oldWidget.voltageData != widget.voltageData || oldWidget.powerData != widget.powerData) {
      _updateChartWithNewData();
    }
  }

  void _updateChartWithNewData() {
    if (!mounted) return;

    setState(() {
      // Add the latest real values to the chart
      double currentVoltage = _extractVoltageValue();
      double currentCurrent = _extractCurrentValue();
      double currentPower = _extractPowerValue();

      if (voltageChartData.isNotEmpty) {
        voltageChartData.removeAt(0);
        voltageChartData.add(FlSpot(19, currentVoltage));
      }

      if (currentChartData.isNotEmpty) {
        currentChartData.removeAt(0);
        currentChartData.add(FlSpot(19, currentCurrent));
      }

      if (powerChartData.isNotEmpty) {
        powerChartData.removeAt(0);
        powerChartData.add(FlSpot(19, currentPower));
      }

      // Reindex data points
      for (int i = 0; i < voltageChartData.length; i++) {
        voltageChartData[i] = FlSpot(i.toDouble(), voltageChartData[i].y);
        currentChartData[i] = FlSpot(i.toDouble(), currentChartData[i].y);
        powerChartData[i] = FlSpot(i.toDouble(), powerChartData[i].y);
      }
    });
  }

  double _extractVoltageValue() {
    try {
      if (widget.voltageData.containsKey('Uavg') && widget.voltageData['Uavg'] != null) {
        return double.tryParse(widget.voltageData['Uavg'].toString()) ?? 0.0;
      } else if (widget.voltageData.containsKey('value') && widget.voltageData['value'] != "No Data") {
        return double.tryParse(widget.voltageData['value'].toString()) ?? 0.0;
      }
    } catch (e) {
      print('Error extracting voltage value: $e');
    }
    return 0.0;
  }

  double _extractCurrentValue() {
    try {
      if (widget.currentData.containsKey('Iavg') && widget.currentData['Iavg'] != null) {
        return double.tryParse(widget.currentData['Iavg'].toString()) ?? 0.0;
      } else if (widget.currentData.containsKey('value') && widget.currentData['value'] != "No Data") {
        return double.tryParse(widget.currentData['value'].toString()) ?? 0.0;
      }
    } catch (e) {
      print('Error extracting current value: $e');
    }
    return 0.0;
  }

  double _extractPowerValue() {
    try {
      if (widget.powerData.containsKey('P(kW)') && widget.powerData['P(kW)'] != null) {
        return double.tryParse(widget.powerData['P(kW)'].toString()) ?? 0.0;
      } else if (widget.powerData.containsKey('P(W)') && widget.powerData['P(W)'] != null) {
        return (double.tryParse(widget.powerData['P(W)'].toString()) ?? 0.0) / 1000;
      } else if (widget.powerData.containsKey('P') && widget.powerData['P'] != null) {
        return double.tryParse(widget.powerData['P'].toString()) ?? 0.0;
      } else if (widget.powerData.containsKey('value') && widget.powerData['value'] != "No Data") {
        return double.tryParse(widget.powerData['value'].toString()) ?? 0.0;
      }
    } catch (e) {
      print('Error extracting power value: $e');
    }
    return 0.0;
  }

  String _formatValue(double value, String unit) {
    if (value == 0.0) return "No Data";

    switch (unit) {
      case 'V':
        return "${value.toInt()}V";
      case 'A':
        return "${value.toStringAsFixed(1)}A";
      case 'kW':
        return "${value.toStringAsFixed(2)}kW";
      default:
        return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive height: use screen height fraction but cap it
        final screenH = MediaQuery.of(context).size.height;
        final cardHeight = (screenH * 0.45).clamp(360.0, 520.0);

    return SizedBox(
      width: double.infinity,
      height: cardHeight,
      child: CardWidget(
      armLenMultiplier: 0.20,
      topPadMultiplier: 0.0,
      glowColor: FlutterFlowTheme.of(context).primary,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Energy Power Parameter Live Data',
                    style: FlutterFlowTheme.of(
                      context,
                    ).headlineSmall.override(fontFamily: 'Poppins', letterSpacing: 0.0, font: GoogleFonts.poppins()),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.bolt_rounded, color: FlutterFlowTheme.of(context).primary, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  // Each section: label row (20) + gap (6) + chart + gap between sections
                  // 3 sections, 2 gaps of 8 between them, minus 20px for label row each
                  final availH = innerConstraints.maxHeight;
                  final chartH = ((availH - (3 * 20) - (2 * 8) - (2 * 8)) / 3).clamp(40.0, 100.0);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildParameterSection('Voltage (V)', _formatValue(_extractVoltageValue(), 'V'), voltageChartData, const Color(0xFF3b82f6), chartH),
                      _buildParameterSection('Current (A)', _formatValue(_extractCurrentValue(), 'A'), currentChartData, const Color(0xFFf59e0b), chartH),
                      _buildParameterSection('Power (kW)', _formatValue(_extractPowerValue(), 'kW'), powerChartData, const Color(0xFF10b981), chartH),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
      },
    );
  }

  Widget _buildParameterSection(String label, String value, List<FlSpot> data, Color color, double chartHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: FlutterFlowTheme.of(context).secondaryText)),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: value == "No Data" ? 0.5 : (0.5 + _pulseController.value * 0.5),
                  child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: value == "No Data" ? Colors.grey : color)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: chartHeight,
          child: data.isEmpty
              ? Center(child: Text('No Chart Data', style: TextStyle(color: Colors.grey[400], fontSize: 10)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 19,
                    minY: data.isNotEmpty ? data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5 : 0,
                    maxY: data.isNotEmpty ? data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5 : 10,
                    lineBarsData: [
                      LineChartBarData(
                        spots: data,
                        isCurved: true,
                        color: color,
                        barWidth: 1.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
