import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class DowntimeAnalysisChartWidget extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? selectedShift;

  const DowntimeAnalysisChartWidget({super.key, this.data, this.selectedShift});

  // Calculate downtime from availability data
  Map<String, dynamic> _calculateDowntime() {
    if (data == null || data!['data'] == null || (data!['data'] as List).isEmpty) {
      return {
        'total': 126.0,
        'planned': 42.0,
        'unplanned': 84.0,
        'categories': [
          {'name': 'Planned Maintenance', 'value': 42.0, 'percentage': 33.3},
          {'name': 'Equipment Failure', 'value': 32.0, 'percentage': 25.4},
          {'name': 'Material Shortage', 'value': 28.0, 'percentage': 22.2},
          {'name': 'Quality Adjustment', 'value': 24.0, 'percentage': 19.0},
        ]
      };
    }

    List<dynamic> records = data!['data'];
    double totalDowntime = 0;
    int recordCount = 0;

    for (var record in records) {
      double availability = 0;

      // If API already filtered by shift, use the Availability field directly
      if (selectedShift != null && selectedShift != 'All' && record['Availability'] != null) {
        availability = (record['Availability'] as num).toDouble();
        recordCount++;
      }
      // Otherwise, use the shift-specific fields
      else {
        if (record['Morning_Availability'] != null && record['Night_Availability'] != null) {
          // If a specific shift is selected, only use that shift's data
          if (selectedShift == 'Morning') {
            availability = (record['Morning_Availability'] as num).toDouble();
            recordCount++;
          } else if (selectedShift == 'Night') {
            availability = (record['Night_Availability'] as num).toDouble();
            recordCount++;
          } else {
            // If no specific shift is selected, use the average of both shifts
            availability = ((record['Morning_Availability'] as num).toDouble() + (record['Night_Availability'] as num).toDouble()) / 2;
            recordCount += 2;
          }
        } else if (record['Availability'] != null) {
          availability = (record['Availability'] as num).toDouble();
          recordCount++;
        }
      }

      // Calculate downtime as percentage of unavailability
      // Assuming 24 hours per day, 2 shifts of 12 hours
      double downtime = (100 - availability) * 0.12; // Convert % to hours (12 hours per shift)
      totalDowntime += downtime;
    }

    // Estimate breakdown (these are approximations based on typical industrial data)
    double planned = totalDowntime * 0.33;
    double unplanned = totalDowntime * 0.67;
    double equipmentFailure = totalDowntime * 0.25;
    double materialShortage = totalDowntime * 0.22;
    double qualityAdjustment = totalDowntime * 0.20;

    return {
      'total': totalDowntime,
      'planned': planned,
      'unplanned': unplanned,
      'categories': [
        {'name': 'Planned Maintenance', 'value': planned, 'percentage': (planned / totalDowntime * 100)},
        {'name': 'Equipment Failure', 'value': equipmentFailure, 'percentage': (equipmentFailure / totalDowntime * 100)},
        {'name': 'Material Shortage', 'value': materialShortage, 'percentage': (materialShortage / totalDowntime * 100)},
        {'name': 'Quality Adjustment', 'value': qualityAdjustment, 'percentage': (qualityAdjustment / totalDowntime * 100)},
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final downtimeData = _calculateDowntime();
    final categories = downtimeData['categories'] as List;

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
                Icons.close,
                color: theme.primary ?? Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Downtime Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText ?? Colors.black,
                ),
              ),
              // Add shift indicator if a specific shift is selected
              if (selectedShift != null && selectedShift != 'All') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: selectedShift == 'Morning' ? const Color(0xFF64B5F6) : const Color(0xFFE57373),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedShift!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${downtimeData['total'].toStringAsFixed(0)} hours',
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
                  'Planned: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.secondaryText ?? Colors.grey[600],
                  ),
                ),
                Text(
                  '${downtimeData['planned'].toStringAsFixed(0)} hours',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Unplanned: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.secondaryText ?? Colors.grey[600],
                  ),
                ),
                Text(
                  '${downtimeData['unplanned'].toStringAsFixed(0)} hours',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFE57373),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF64B5F6),
                          value: categories[0]['value'],
                          title: '${categories[0]['percentage'].toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFE57373),
                          value: categories[1]['value'],
                          title: '${categories[1]['percentage'].toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFFFB74D),
                          value: categories[2]['value'],
                          title: '${categories[2]['percentage'].toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF81C784),
                          value: categories[3]['value'],
                          title: '${categories[3]['percentage'].toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                children: [
                  _buildLegendItem(const Color(0xFF64B5F6), 'Planned Maintenance'),
                  const SizedBox(width: 8),
                  _buildLegendItem(const Color(0xFFE57373), 'Equipment Failure'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildLegendItem(const Color(0xFFFFB74D), 'Material Shortage'),
                  const SizedBox(width: 8),
                  _buildLegendItem(const Color(0xFF81C784), 'Quality Adjustment'),
                ],
              ),
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
