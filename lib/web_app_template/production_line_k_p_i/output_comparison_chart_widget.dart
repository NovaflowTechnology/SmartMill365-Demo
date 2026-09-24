import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class OutputComparisonChartWidget extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? selectedShift;
  
  const OutputComparisonChartWidget({super.key, this.data, this.selectedShift});

  // Calculate totals from API data
  Map<String, int> _calculateTotals() {
    if (data == null || data!['data'] == null || (data!['data'] as List).isEmpty) {
      return {'morning': 13420, 'night': 11160, 'total': 24580};
    }

    List<dynamic> records = data!['data'];
    int morningTotal = 0;
    int nightTotal = 0;

    for (var record in records) {
      // If API already filtered by shift, use the NGQuantity field directly
      if (selectedShift != null && selectedShift != 'All' && record['NGQuantity'] != null) {
        if (selectedShift == 'Morning') {
          morningTotal += (record['NGQuantity'] as num).toInt();
        } else if (selectedShift == 'Night') {
          nightTotal += (record['NGQuantity'] as num).toInt();
        }
      } 
      // Otherwise, use the shift-specific fields
      else {
        if (record['Morning_NGQuantity'] != null) {
          morningTotal += (record['Morning_NGQuantity'] as num).toInt();
        }
        if (record['Night_NGQuantity'] != null) {
          nightTotal += (record['Night_NGQuantity'] as num).toInt();
        }
        // Handle single shift data
        if (record['NGQuantity'] != null && record['Shift'] != null) {
          if (record['Shift'] == 'Morning') {
            morningTotal += (record['NGQuantity'] as num).toInt();
          } else {
            nightTotal += (record['NGQuantity'] as num).toInt();
          }
        }
      }
    }

    // If a specific shift is selected, only return that shift's data
    if (selectedShift != null && selectedShift != 'All') {
      if (selectedShift == 'Morning') {
        return {'morning': morningTotal, 'night': 0, 'total': morningTotal};
      } else {
        return {'morning': 0, 'night': nightTotal, 'total': nightTotal};
      }
    }

    return {
      'morning': morningTotal,
      'night': nightTotal,
      'total': morningTotal + nightTotal
    };
  }

  // Group data by week for chart display
  Map<int, Map<String, double>> _getWeeklyData() {
    if (data == null || data!['data'] == null || (data!['data'] as List).isEmpty) {
      return {
        0: {'morning': 13500, 'night': 11000},
        1: {'morning': 13200, 'night': 11400},
        2: {'morning': 13600, 'night': 11200},
        3: {'morning': 13400, 'night': 11300},
      };
    }

    List<dynamic> records = data!['data'];
    Map<int, Map<String, List<int>>> weeklyData = {};

    for (var record in records) {
      if (record['Date'] != null) {
        DateTime date = DateTime.parse(record['Date']);
        int weekNumber = ((date.day - 1) / 7).floor();

        weeklyData.putIfAbsent(weekNumber, () => {'morning': [], 'night': []});

        // If API already filtered by shift, use the NGQuantity field directly
        if (selectedShift != null && selectedShift != 'All' && record['NGQuantity'] != null) {
          if (selectedShift == 'Morning') {
            weeklyData[weekNumber]!['morning']!.add((record['NGQuantity'] as num).toInt());
          } else if (selectedShift == 'Night') {
            weeklyData[weekNumber]!['night']!.add((record['NGQuantity'] as num).toInt());
          }
        } 
        // Otherwise, use the shift-specific fields
        else {
          if (record['Morning_NGQuantity'] != null && record['Night_NGQuantity'] != null) {
            weeklyData[weekNumber]!['morning']!.add((record['Morning_NGQuantity'] as num).toInt());
            weeklyData[weekNumber]!['night']!.add((record['Night_NGQuantity'] as num).toInt());
          } else if (record['NGQuantity'] != null && record['Shift'] != null) {
            String shift = record['Shift'] == 'Morning' ? 'morning' : 'night';
            weeklyData[weekNumber]![shift]!.add((record['NGQuantity'] as num).toInt());
          }
        }
      }
    }

    // Calculate averages
    Map<int, Map<String, double>> result = {};
    weeklyData.forEach((week, shifts) {
      if (week < 4) {
        result[week] = {
          'morning': shifts['morning']!.isNotEmpty 
              ? shifts['morning']!.reduce((a, b) => a + b) / shifts['morning']!.length 
              : 0,
          'night': shifts['night']!.isNotEmpty 
              ? shifts['night']!.reduce((a, b) => a + b) / shifts['night']!.length 
              : 0,
        };
      }
    });

    // If a specific shift is selected, zero out the other shift
    if (selectedShift != null && selectedShift != 'All') {
      result.forEach((week, values) {
        if (selectedShift == 'Morning') {
          values['night'] = 0;
        } else {
          values['morning'] = 0;
        }
      });
    }

    return result.isEmpty ? {
      0: {'morning': 13500, 'night': 11000},
      1: {'morning': 13200, 'night': 11400},
      2: {'morning': 13600, 'night': 11200},
      3: {'morning': 13400, 'night': 11300},
    } : result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final totals = _calculateTotals();
    final weeklyData = _getWeeklyData();

    // Determine which shift(s) to display based on the selected filter
    bool showMorning = selectedShift == null || selectedShift == 'All' || selectedShift == 'Morning';
    bool showNight = selectedShift == null || selectedShift == 'All' || selectedShift == 'Night';

    // Calculate maxY for chart scaling
    double maxY = 14000;
    weeklyData.forEach((week, values) {
      double morning = values['morning'] ?? 0;
      double night = values['night'] ?? 0;
      if (morning > maxY) maxY = morning;
      if (night > maxY) maxY = night;
    });
    maxY = (maxY * 1.1).ceilToDouble(); // Add 10% padding

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 320,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.primary,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: theme.primary ?? Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Output Comparison',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText ?? Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${totals['total']!.toStringAsFixed(0)} units',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.primaryText ?? Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // Only show shift breakdown if not filtered to a specific shift
          if (selectedShift == null || selectedShift == 'All')
            Row(
              children: [
                Text(
                  'Morning: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.secondaryText ?? Colors.grey[600],
                  ),
                ),
                Text(
                  totals['morning']!.toStringAsFixed(0),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Night: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.secondaryText ?? Colors.grey[600],
                  ),
                ),
                Text(
                  totals['night']!.toStringAsFixed(0),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFE57373),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: weeklyData.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final style = GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: theme.secondaryText ?? Colors.grey[600],
                              );

                              String text = '';
                              switch (value.toInt()) {
                                case 0:
                                  text = 'Week 1';
                                  break;
                                case 1:
                                  text = 'Week 2';
                                  break;
                                case 2:
                                  text = 'Week 3';
                                  break;
                                case 3:
                                  text = 'Week 4';
                                  break;
                                default:
                                  text = '';
                                  break;
                              }

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(text, style: style),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: maxY / 5,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${(value / 1000).toStringAsFixed(0)}k',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: theme.secondaryText ?? Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            if (showMorning && (entry.value['morning'] ?? 0) > 0)
                              BarChartRodData(
                                toY: entry.value['morning']!,
                                color: const Color(0xFF64B5F6),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            if (showNight && (entry.value['night'] ?? 0) > 0)
                              BarChartRodData(
                                toY: entry.value['night']!,
                                color: const Color(0xFFE57373),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          // Only show legend for the shifts that are being displayed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showMorning) ...[
                _buildLegendItem(const Color(0xFF64B5F6), 'Morning Output'),
                if (showNight) const SizedBox(width: 16),
              ],
              if (showNight)
                _buildLegendItem(const Color(0xFFE57373), 'Night Output'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}