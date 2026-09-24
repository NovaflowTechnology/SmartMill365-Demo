import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../flutter_flow/flutter_flow_theme.dart';

class MachineChartInPercentWidget extends StatelessWidget {
  final String? title;
  final Map<String, dynamic>? weeklyData;
  final Map<String, dynamic>? monthlyData;
  final Map<String, dynamic>? yearlyData;
  final String? selectedShift;

  const MachineChartInPercentWidget({
    Key? key,
    this.title,
    this.weeklyData,
    this.monthlyData,
    this.yearlyData,
    this.selectedShift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.primary,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? "N/A",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = (constraints.maxWidth - 32) / 3; // 3 charts with 16px spacing each
                  return Row(
                    children: [
                      Expanded(child: _buildChartCard(context, 'Weekly', weeklyData)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildChartCard(context, 'Monthly', monthlyData)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildChartCard(context, 'Yearly', yearlyData)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, Map<String, dynamic>? data) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.primary,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16), // Balances the '%' on the left
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Morning Shift', const Color(0xFF4DD0E1)),
                const SizedBox(width: 16),
                _buildLegendItem('Night Shift', const Color(0xFFFF9800)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildChart(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(Map<String, dynamic>? data) {
    List<dynamic> chartData = [];
    bool hasData = false;

    if (data != null && data['data'] != null) {
      chartData = data['data'];
      hasData = chartData.isNotEmpty;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: hasData),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasData,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      chartData[value.toInt()]['label']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
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
              showTitles: false,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
        ),
        barGroups: hasData ? _buildBarGroups(chartData) : [],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<dynamic> chartData) {
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < chartData.length; i++) {
      var item = chartData[i];

      if (selectedShift == null || selectedShift == 'All Shifts') {
        // Show both shifts
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (item['Morning_OEE'] ?? 0).toDouble(),
                color: const Color(0xFF4DD0E1),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: (item['Night_OEE'] ?? 0).toDouble(),
                color: const Color(0xFFFF9800),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show selected shift only
        double oeeValue = (item['OEE'] ?? 0).toDouble();
        Color barColor = selectedShift == 'Morning Shift' ? const Color(0xFF4DD0E1) : const Color(0xFFFF9800);

        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: oeeValue,
                color: barColor,
                width: 24,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      }
    }

    return groups;
  }
}
