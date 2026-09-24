import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class MachinePerformanceRankingWidget extends StatefulWidget {
  final Map<String, dynamic>? oeeData;
  final Map<String, dynamic>? performanceData;
  final Map<String, dynamic>? availabilityData;
  final Map<String, dynamic>? qualityData;
  final String? selectedShift;

  const MachinePerformanceRankingWidget({
    super.key,
    this.oeeData,
    this.performanceData,
    this.availabilityData,
    this.qualityData,
    this.selectedShift,
  });

  @override
  State<MachinePerformanceRankingWidget> createState() => _MachinePerformanceRankingWidgetState();
}

class _MachinePerformanceRankingWidgetState extends State<MachinePerformanceRankingWidget> {
  String? hoveredMachine;
  String? hoveredShift;
  double? hoveredValue;

  // Process API data to get machine rankings
  List<MachineData> _getMachineRankings() {
    if (widget.oeeData == null || widget.oeeData!['data'] == null || (widget.oeeData!['data'] as List).isEmpty) {
      // Return sample data
      return [
        MachineData('M07', 97.5, 96.8),
        MachineData('M23', 95.2, 94.1),
        MachineData('M29', 93.8, 89.2),
        MachineData('M25', 92.1, 88.7),
        MachineData('M11', 91.3, 89.5),
        MachineData('M13', 88.9, 82.1),
        MachineData('M05', 87.2, 84.3),
        MachineData('M21', 85.6, 81.9),
        MachineData('M14', 84.1, 95.2),
        MachineData('M15', 82.7, 78.9),
        MachineData('M04', 81.3, 88.4),
        MachineData('M01', 79.8, 76.2),
        MachineData('M03', 78.4, 73.6),
        MachineData('M18', 76.9, 71.8),
        MachineData('M28', 69.2, 68.1),
      ];
    }

    List<dynamic> records = widget.oeeData!['data'];
    Map<String, Map<String, List<double>>> machineMap = {};

    // Aggregate data by machine
    for (var record in records) {
      String machineId = record['MachineID'] ?? 'Unknown';

      machineMap.putIfAbsent(
          machineId,
          () => {
                'morning': [],
                'night': [],
              });

      // If API already filtered by shift, use the OEE field directly
      if (widget.selectedShift != null && widget.selectedShift != 'All' && record['OEE'] != null) {
        if (widget.selectedShift == 'Morning') {
          machineMap[machineId]!['morning']!.add((record['OEE'] as num).toDouble());
        } else if (widget.selectedShift == 'Night') {
          machineMap[machineId]!['night']!.add((record['OEE'] as num).toDouble());
        }
      }
      // Otherwise, use the shift-specific fields
      else {
        if (record['Morning_OEE'] != null) {
          machineMap[machineId]!['morning']!.add((record['Morning_OEE'] as num).toDouble());
        }
        if (record['Night_OEE'] != null) {
          machineMap[machineId]!['night']!.add((record['Night_OEE'] as num).toDouble());
        }
        // Handle single shift data
        if (record['OEE'] != null && record['Shift'] != null) {
          String shift = record['Shift'] == 'Morning' ? 'morning' : 'night';
          machineMap[machineId]![shift]!.add((record['OEE'] as num).toDouble());
        }
      }
    }

    // Calculate averages and create MachineData objects
    List<MachineData> machines = [];
    machineMap.forEach((machineId, shifts) {
      double morningAvg = shifts['morning']!.isNotEmpty ? shifts['morning']!.reduce((a, b) => a + b) / shifts['morning']!.length : 0;
      double nightAvg = shifts['night']!.isNotEmpty ? shifts['night']!.reduce((a, b) => a + b) / shifts['night']!.length : 0;

      if (morningAvg > 0 || nightAvg > 0) {
        machines.add(MachineData(machineId, morningAvg, nightAvg));
      }
    });

    // Sort by morning OEE (descending) if no specific shift is selected
    // Otherwise, sort by the selected shift's OEE
    if (widget.selectedShift == 'Night') {
      machines.sort((a, b) => b.nightOee.compareTo(a.nightOee));
    } else {
      machines.sort((a, b) => b.morningOee.compareTo(a.morningOee));
    }

    // Return top 15 or all if less than 15
    return machines.take(15).toList();
  }

  @override
  Widget build(BuildContext context) {
    final machineData = _getMachineRankings();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and trophy icon
            Row(
              children: [
                Text(
                  'Machine Performance Ranking (by OEE)',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                // Add shift indicator if a specific shift is selected
                if (widget.selectedShift != null && widget.selectedShift != 'All') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.selectedShift == 'Morning' ? const Color(0xFF64B5F6) : const Color(0xFFE57373),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.selectedShift!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.emoji_events,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              children: [
                // Only show legend for the shifts that are being displayed
                if (widget.selectedShift == null || widget.selectedShift == 'All' || widget.selectedShift == 'Morning') ...[
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7DD3FC),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Morning OEE',
                    style: TextStyle(
                      fontSize: 12,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                  if (widget.selectedShift == null || widget.selectedShift == 'All') const SizedBox(width: 16),
                ],
                // Only show legend for the shifts that are being displayed
                if (widget.selectedShift == null || widget.selectedShift == 'All' || widget.selectedShift == 'Night') ...[
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCA5A5),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Night OEE',
                    style: TextStyle(
                      fontSize: 12,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Chart area
            Expanded(
              child: machineData.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                    )
                  : _buildHorizontalBarChart(context, machineData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBarChart(BuildContext context, List<MachineData> machineData) {
    // Calculate min/max for better scaling
    double minValue = 60;
    double maxValue = 100;

    if (machineData.isNotEmpty) {
      List<double> allValues = [];

      // Only include values for the selected shift
      if (widget.selectedShift == 'Morning') {
        allValues = machineData.map((m) => m.morningOee).toList();
      } else if (widget.selectedShift == 'Night') {
        allValues = machineData.map((m) => m.nightOee).toList();
      } else {
        allValues = [
          ...machineData.map((m) => m.morningOee),
          ...machineData.map((m) => m.nightOee),
        ];
      }

      minValue = (allValues.reduce((a, b) => a < b ? a : b) - 5).floorToDouble();
      maxValue = (allValues.reduce((a, b) => a > b ? a : b) + 5).ceilToDouble();
      minValue = minValue < 0 ? 0 : minValue;
      maxValue = maxValue > 100 ? 100 : maxValue;
    }

    final range = maxValue - minValue;

    return Column(
      children: [
        // X-axis labels (percentage scale)
        Container(
          height: 30,
          margin: const EdgeInsets.only(left: 50),
          child: Row(
            children: [
              for (int i = minValue.toInt(); i <= maxValue.toInt(); i += 5)
                Expanded(
                  child: Text(
                    i.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Chart content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: machineData.asMap().entries.map((entry) {
                final machine = entry.value;

                return Container(
                  height: widget.selectedShift != null && widget.selectedShift != 'All' ? 24 : 40,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      // Machine label
                      SizedBox(
                        width: 50,
                        child: Text(
                          machine.machineId,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                      ),

                      // Chart area
                      Expanded(
                        child: Stack(
                          children: [
                            // Background grid
                            Container(
                              height: widget.selectedShift != null && widget.selectedShift != 'All' ? 24 : 40,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: GridPainter(),
                              ),
                            ),

                            // Morning OEE bar
                            if (machine.morningOee > 0 &&
                                (widget.selectedShift == null || widget.selectedShift == 'All' || widget.selectedShift == 'Morning'))
                              Positioned(
                                top: widget.selectedShift == 'Night' ? 0 : 4,
                                child: Container(
                                  width: ((machine.morningOee - minValue) / range) * (MediaQuery.of(context).size.width - 150),
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7DD3FC),
                                    borderRadius: BorderRadius.all(Radius.circular(2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${machine.morningOee.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Night OEE bar
                            if (machine.nightOee > 0 &&
                                (widget.selectedShift == null || widget.selectedShift == 'All' || widget.selectedShift == 'Night'))
                              Positioned(
                                top: widget.selectedShift == 'Morning' ? 0 : (widget.selectedShift == 'Night' ? 4 : 22),
                                child: Container(
                                  width: ((machine.nightOee - minValue) / range) * (MediaQuery.of(context).size.width - 150),
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFCA5A5),
                                    borderRadius: BorderRadius.all(Radius.circular(2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${machine.nightOee.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom label
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            'OEE (%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class MachineData {
  final String machineId;
  final double morningOee;
  final double nightOee;

  MachineData(this.machineId, this.morningOee, this.nightOee);
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Draw vertical grid lines
    for (int i = 1; i <= 8; i++) {
      final x = (i / 8) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
