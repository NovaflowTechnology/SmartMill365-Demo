import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class MachineOutputComparisonWidget extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? selectedShift;

  const MachineOutputComparisonWidget({
    super.key,
    this.data,
    this.selectedShift,
  });

  @override
  State<MachineOutputComparisonWidget> createState() => _MachineOutputComparisonWidgetState();
}

class _MachineOutputComparisonWidgetState extends State<MachineOutputComparisonWidget> {
  List<Map<String, dynamic>> _processData() {
    if (widget.data == null || widget.data!['data'] == null) {
      return [];
    }

    List<dynamic> apiData = widget.data!['data'];
    List<Map<String, dynamic>> processed = [];

    for (var item in apiData) {
      String machine = item["MachineID"] ?? '';
      
      if (widget.selectedShift == null || widget.selectedShift == 'All') {
        processed.add({
          'machine': machine,
          'morning': item['Morning_NGQuantity'] ?? 0,
          'night': item['Night_NGQuantity'] ?? 0,
        });
      } else if (widget.selectedShift?.toLowerCase() == 'morning') {
        processed.add({
          'machine': machine,
          'morning': item['Morning_NGQuantity'] ?? item['NGQuantity'] ?? 0,
          'night': 0,
        });
      } else if (widget.selectedShift?.toLowerCase() == 'night') {
        processed.add({
          'machine': machine,
          'morning': 0,
          'night': item['Night_NGQuantity'] ?? item['NGQuantity'] ?? 0,
        });
      }
    }

    return processed;
  }

  double _getMaxY() {
    List<Map<String, dynamic>> data = _processData();
    if (data.isEmpty) return 2000;

    double maxValue = 0;
    for (var item in data) {
      double morning = (item['morning'] ?? 0).toDouble();
      double night = (item['night'] ?? 0).toDouble();
      maxValue = [maxValue, morning, night].reduce((a, b) => a > b ? a : b);
    }

    return (maxValue * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> outputData = _processData();

    if (outputData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary,
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Center(
          child: Text(
            'No output data available',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
        ),
      );
    }

    bool showBothShifts = widget.selectedShift == null || widget.selectedShift == 'All';
    
    // Calculate dynamic width based on number of machines
    double barWidth = showBothShifts ? 40 : 50;
    double groupSpacing = 30;
    double minChartWidth = outputData.length * (barWidth + groupSpacing);
    double containerWidth = MediaQuery.of(context).size.width - 32;
    double chartWidth = minChartWidth > containerWidth ? minChartWidth : containerWidth;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Output Comparison by Machine',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Poppins',
                      font: GoogleFonts.poppins(),
                    ),
              ),
              Icon(
                Icons.open_in_full,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              if (showBothShifts || widget.selectedShift?.toLowerCase() == 'morning') ...[
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.lightBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Morning Output',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
                const SizedBox(width: 16),
              ],
              if (showBothShifts || widget.selectedShift?.toLowerCase() == 'night') ...[
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Night Output',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable chart container
          SizedBox(
            height: 340,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 340,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (groupIndex >= outputData.length) return null;
                          
                          String shift = rodIndex == 0 ? 'Morning' : 'Night';
                          int value = rod.toY.round();
                          
                          if (value == 0) return null;
                          
                          return BarTooltipItem(
                            '${outputData[groupIndex]['machine']}\n$shift: $value units',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < outputData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    outputData[value.toInt()]['machine'],
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: outputData.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> data = entry.value;
                      
                      List<BarChartRodData> rods = [];
                      
                      if (showBothShifts || widget.selectedShift?.toLowerCase() == 'morning') {
                        rods.add(
                          BarChartRodData(
                            toY: (data['morning'] ?? 0).toDouble(),
                            color: Colors.lightBlue,
                            width: showBothShifts ? 15 : 25,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        );
                      }
                      
                      if (showBothShifts || widget.selectedShift?.toLowerCase() == 'night') {
                        rods.add(
                          BarChartRodData(
                            toY: (data['night'] ?? 0).toDouble(),
                            color: Colors.redAccent,
                            width: showBothShifts ? 15 : 25,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        );
                      }
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: rods,
                        barsSpace: 4,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}