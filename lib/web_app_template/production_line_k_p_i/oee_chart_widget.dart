import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class OEEChartWidget extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? selectedShift;

  const OEEChartWidget({super.key, this.data, this.selectedShift});

  // Calculate average OEE from API data
  Map<String, double> _calculateAverages() {
    if (data == null || data!['data'] == null || (data!['data'] as List).isEmpty) {
      return {'morning': 82.3, 'night': 74.7, 'overall': 78.5};
    }

    List<dynamic> records = data!['data'];
    double morningTotal = 0;
    double nightTotal = 0;
    int morningCount = 0;
    int nightCount = 0;

    for (var record in records) {
      // If API already filtered by shift, use the OEE field directly
      if (selectedShift != null && selectedShift != 'All' && record['OEE'] != null) {
        if (selectedShift == 'Morning') {
          morningTotal += (record['OEE'] as num).toDouble();
          morningCount++;
        } else if (selectedShift == 'Night') {
          nightTotal += (record['OEE'] as num).toDouble();
          nightCount++;
        }
      } 
      // Otherwise, use the shift-specific fields
      else {
        if (record['Morning_OEE'] != null) {
          morningTotal += (record['Morning_OEE'] as num).toDouble();
          morningCount++;
        }
        if (record['Night_OEE'] != null) {
          nightTotal += (record['Night_OEE'] as num).toDouble();
          nightCount++;
        }
        // Handle single shift data
        if (record['OEE'] != null && record['Shift'] != null) {
          if (record['Shift'] == 'Morning') {
            morningTotal += (record['OEE'] as num).toDouble();
            morningCount++;
          } else {
            nightTotal += (record['OEE'] as num).toDouble();
            nightCount++;
          }
        }
      }
    }

    double morning = morningCount > 0 ? morningTotal / morningCount : 0;
    double night = nightCount > 0 ? nightTotal / nightCount : 0;
    double overall = (morningCount + nightCount) > 0 ? (morningTotal + nightTotal) / (morningCount + nightCount) : 0;

    // If a specific shift is selected, only return that shift's data
    if (selectedShift != null && selectedShift != 'All') {
      if (selectedShift == 'Morning') {
        return {'morning': morning, 'night': 0, 'overall': morning};
      } else {
        return {'morning': 0, 'night': night, 'overall': night};
      }
    }

    return {'morning': morning, 'night': night, 'overall': overall};
  }

  // Group data by date/week for chart display
  List<FlSpot> _getChartData(bool isMorning) {
    if (data == null || data!['data'] == null || (data!['data'] as List).isEmpty) {
      return isMorning
          ? [FlSpot(0, 82), FlSpot(1, 84), FlSpot(2, 81), FlSpot(3, 82.5)]
          : [FlSpot(0, 76), FlSpot(1, 74), FlSpot(2, 73.5), FlSpot(3, 75)];
    }

    // If a specific shift is selected and it doesn't match the requested shift, return empty
    if (selectedShift != null && selectedShift != 'All') {
      if ((selectedShift == 'Morning' && !isMorning) || 
          (selectedShift == 'Night' && isMorning)) {
        return [];
      }
    }

    List<dynamic> records = data!['data'];
    Map<int, List<double>> weeklyData = {};

    for (var record in records) {
      if (record['Date'] != null) {
        DateTime date = DateTime.parse(record['Date']);
        int weekNumber = ((date.day - 1) / 7).floor();

        double oeeValue = 0;
        
        // If API already filtered by shift, use the OEE field directly
        if (selectedShift != null && selectedShift != 'All' && record['OEE'] != null) {
          if ((selectedShift == 'Morning' && isMorning) || 
              (selectedShift == 'Night' && !isMorning)) {
            oeeValue = (record['OEE'] as num).toDouble();
          }
        } 
        // Otherwise, use the shift-specific fields
        else {
          if (record['Morning_OEE'] != null && record['Night_OEE'] != null) {
            oeeValue = isMorning ? (record['Morning_OEE'] as num).toDouble() : (record['Night_OEE'] as num).toDouble();
          } else if (record['OEE'] != null && record['Shift'] != null) {
            if ((isMorning && record['Shift'] == 'Morning') || (!isMorning && record['Shift'] == 'Night')) {
              oeeValue = (record['OEE'] as num).toDouble();
            }
          }
        }

        if (oeeValue > 0) {
          weeklyData.putIfAbsent(weekNumber, () => []);
          weeklyData[weekNumber]!.add(oeeValue);
        }
      }
    }

    List<FlSpot> spots = [];
    weeklyData.forEach((week, values) {
      if (values.isNotEmpty && week < 4) {
        double avg = values.reduce((a, b) => a + b) / values.length;
        spots.add(FlSpot(week.toDouble(), avg));
      }
    });

    return spots.isEmpty
        ? (isMorning
            ? [FlSpot(0, 82), FlSpot(1, 84), FlSpot(2, 81), FlSpot(3, 82.5)]
            : [FlSpot(0, 76), FlSpot(1, 74), FlSpot(2, 73.5), FlSpot(3, 75)])
        : spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final averages = _calculateAverages();
    final morningSpots = _getChartData(true);
    final nightSpots = _getChartData(false);

    // Calculate min/max Y for better chart scaling
    double minY = 70;
    double maxY = 90;
    if (morningSpots.isNotEmpty || nightSpots.isNotEmpty) {
      List<double> allYValues = [
        ...morningSpots.map((s) => s.y),
        ...nightSpots.map((s) => s.y),
      ];
      if (allYValues.isNotEmpty) {
        minY = (allYValues.reduce((a, b) => a < b ? a : b) - 5).floorToDouble();
        maxY = (allYValues.reduce((a, b) => a > b ? a : b) + 5).ceilToDouble();
      }
    }

    // Determine which shift(s) to display based on the selected filter
    bool showMorning = selectedShift == null || selectedShift == 'All' || selectedShift == 'Morning';
    bool showNight = selectedShift == null || selectedShift == 'All' || selectedShift == 'Night';

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
                Icons.trending_up,
                color: theme.primary ?? Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Overall OEE',
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
            '${averages['overall']!.toStringAsFixed(1)}%',
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
                  '${averages['morning']!.toStringAsFixed(1)}%',
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
                  '${averages['night']!.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFE57373),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: morningSpots.isEmpty && nightSpots.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 2,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: (theme.alternate ?? Colors.grey).withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: (theme.alternate ?? Colors.grey).withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
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
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 4,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${value.toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: theme.secondaryText ?? Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 3,
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        if (showMorning && morningSpots.isNotEmpty)
                          LineChartBarData(
                            spots: morningSpots,
                            isCurved: true,
                            color: const Color(0xFF64B5F6),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFF64B5F6),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF64B5F6).withOpacity(0.1),
                            ),
                          ),
                        if (showNight && nightSpots.isNotEmpty)
                          LineChartBarData(
                            spots: nightSpots,
                            isCurved: true,
                            color: const Color(0xFFE57373),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFFE57373),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFFE57373).withOpacity(0.1),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          // Only show legend for the shifts that are being displayed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showMorning) ...[
                _buildLegendItem(const Color(0xFF64B5F6), 'Morning Shift OEE'),
                if (showNight) const SizedBox(width: 16),
              ],
              if (showNight)
                _buildLegendItem(const Color(0xFFE57373), 'Night Shift OEE'),
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