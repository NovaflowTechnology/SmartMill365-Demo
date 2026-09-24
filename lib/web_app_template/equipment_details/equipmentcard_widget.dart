import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import '/components/card_widget/card_widget.dart';

class EquipmentCardWidget extends StatefulWidget {
  const EquipmentCardWidget({Key? key}) : super(key: key);

  @override
  State<EquipmentCardWidget> createState() => _EquipmentCardWidgetState();
}

class _EquipmentCardWidgetState extends State<EquipmentCardWidget> with TickerProviderStateMixin {
  List<FlSpot> voltageData = [];
  List<FlSpot> currentData = [];
  List<FlSpot> speedData = [];

  double currentVoltage = 180;
  double currentCurrent = 18;
  double currentSpeed = 0.25;

  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      voltageData.add(FlSpot(i.toDouble(), 175 + random.nextDouble() * 10));

      double currentValue;
      if (i < 8 || i > 16) {
        currentValue = 15 + random.nextDouble() * 6;
      } else {
        currentValue = 25 + random.nextDouble() * 10;
      }
      currentData.add(FlSpot(i.toDouble(), currentValue));
      speedData.add(FlSpot(i.toDouble(), 0.2 + random.nextDouble() * 0.1));
    }
  }

  void _startRealTimeUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        final random = Random();
        setState(() {
          currentVoltage = 175 + random.nextDouble() * 10;
          voltageData.removeAt(0);
          voltageData.add(FlSpot(19, currentVoltage));

          currentCurrent = 15 + random.nextDouble() * 15;
          currentData.removeAt(0);
          currentData.add(FlSpot(19, currentCurrent));

          currentSpeed = 0.2 + random.nextDouble() * 0.1;
          speedData.removeAt(0);
          speedData.add(FlSpot(19, currentSpeed));

          for (int i = 0; i < voltageData.length; i++) {
            voltageData[i] = FlSpot(i.toDouble(), voltageData[i].y);
            currentData[i] = FlSpot(i.toDouble(), currentData[i].y);
            speedData[i] = FlSpot(i.toDouble(), speedData[i].y);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                          'Specified Equipment Parameters Monitoring',
                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Poppins',
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10b981).withOpacity(_pulseAnimation.value),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.now().toString().substring(0, 16),
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Poppins',
                          letterSpacing: 0.0,
                          font: GoogleFonts.poppins(),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final availH = innerConstraints.maxHeight;
                        final chartH = ((availH - (3 * 20) - (2 * 8) - (2 * 8)) / 3).clamp(40.0, 100.0);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildParameterSection(
                              'Voltage (V)',
                              '${currentVoltage.toInt()}V',
                              voltageData,
                              const Color(0xFF3b82f6),
                              chartH,
                            ),
                            _buildParameterSection(
                              'Current (A)',
                              '${currentCurrent.toInt()}A',
                              currentData,
                              const Color(0xFFf59e0b),
                              chartH,
                            ),
                            _buildParameterSection(
                              'Speed (m/s)',
                              currentSpeed.toStringAsFixed(2),
                              speedData,
                              const Color(0xFF10b981),
                              chartH,
                            ),
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

  Widget _buildParameterSection(
    String label,
    String value,
    List<FlSpot> data,
    Color color,
    double chartHeight,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(builder: (context) {
              final isLight = Theme.of(context).brightness == Brightness.light;
              return Text(
                label,
                style: TextStyle(fontSize: 12, color: isLight ? FlutterFlowTheme.of(context).txtSecondary : const Color(0xFF94a3b8)),
              );
            }),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: chartHeight,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 19,
              minY: data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5,
              maxY: data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
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
