import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class MachineQualityComparisonWidget extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? selectedShift;

  const MachineQualityComparisonWidget({
    super.key,
    this.data,
    this.selectedShift,
  });

  @override
  State<MachineQualityComparisonWidget> createState() => _MachineQualityComparisonWidgetState();
}

class _MachineQualityComparisonWidgetState extends State<MachineQualityComparisonWidget> {
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
          'morning': (item['Morning_Quality'] ?? 0).toDouble(),
          'night': (item['Night_Quality'] ?? 0).toDouble(),
        });
      } else if (widget.selectedShift?.toLowerCase() == 'morning') {
        processed.add({
          'machine': machine,
          'morning': (item['Morning_Quality'] ?? item['Quality'] ?? 0).toDouble(),
          'night': 0.0,
        });
      } else if (widget.selectedShift?.toLowerCase() == 'night') {
        processed.add({
          'machine': machine,
          'morning': 0.0,
          'night': (item['Night_Quality'] ?? item['Quality'] ?? 0).toDouble(),
        });
      }
    }

    return processed;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> qualityData = _processData();

    if (qualityData.isEmpty) {
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
            'No quality data available',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
        ),
      );
    }

    bool showBothShifts = widget.selectedShift == null || widget.selectedShift == 'All';

    // Calculate dynamic width based on number of machines
    double barWidth = showBothShifts ? 40 : 50;
    double groupSpacing = 30;
    double minChartWidth = qualityData.length * (barWidth + groupSpacing);
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
                'Quality Rate Comparison by Machine',
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
                  'Morning Quality',
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
                  'Night Quality',
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
                    maxY: 100,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (groupIndex >= qualityData.length) return null;
                          if (rod.toY == 0) return null;

                          String shift = rodIndex == 0 ? 'Morning' : 'Night';
                          return BarTooltipItem(
                            '${qualityData[groupIndex]['machine']}\n$shift Quality: ${rod.toY.toStringAsFixed(1)}%',
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
                            if (value.toInt() < qualityData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    qualityData[value.toInt()]['machine'],
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: qualityData.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> data = entry.value;

                      List<BarChartRodData> rods = [];

                      if (showBothShifts || widget.selectedShift?.toLowerCase() == 'morning') {
                        rods.add(
                          BarChartRodData(
                            toY: data['morning'],
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
                            toY: data['night'],
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
