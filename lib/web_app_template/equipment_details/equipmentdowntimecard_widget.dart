import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class EquipmentDowntimeCard extends StatelessWidget {
  final List<String> categories;
  final List<double> timeValues;
  final List<double> accumulatedValues;
  final int totalDowntime;
  final double maxY;
  final bool isLoading;

  const EquipmentDowntimeCard({
    Key? key,
    this.categories = const [],
    this.timeValues = const [],
    this.accumulatedValues = const [],
    this.totalDowntime = 0,
    this.maxY = 1200,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    'Equipment Downtime Reason Analysis',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Poppins',
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          font: GoogleFonts.poppins(),
                        ),
                  ),
                ),
                if (totalDowntime > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).error,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Total: $totalDowntime mins',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Poppins',
                            color: FlutterFlowTheme.of(context).error,
                            fontWeight: FontWeight.w600,
                            font: GoogleFonts.poppins(),
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 20,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Time (Mins)',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Downtime Data',
                                style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      font: GoogleFonts.poppins(),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Equipment is running smoothly',
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      font: GoogleFonts.poppins(),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : DowntimeChart(
                          categories: categories,
                          timeValues: timeValues,
                          maxY: maxY,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class DowntimeChart extends StatelessWidget {
  final List<String> categories;
  final List<double> timeValues;
  final double maxY;

  const DowntimeChart({
    Key? key,
    required this.categories,
    required this.timeValues,
    required this.maxY,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int dataLength = categories.length;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    final labelColor = isLight ? theme.txtMuted : Colors.grey.shade400;
    final gridColor = isLight ? theme.cardStroke : Colors.grey.shade700;

    if (dataLength == 0 || timeValues.length != dataLength) {
      return Center(
        child: Text(
          'Invalid data format',
          style: TextStyle(color: theme.txtMuted),
        ),
      );
    }

    return Stack(
      children: [
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY > 0 ? maxY : 1200,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => isLight ? theme.primaryText : Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex >= 0 && groupIndex < categories.length) {
                    return BarTooltipItem(
                      '${categories[groupIndex]}\n${timeValues[groupIndex].toStringAsFixed(1)} mins',
                      TextStyle(color: theme.txtOnAccent, fontWeight: FontWeight.bold),
                    );
                  }
                  return null;
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: maxY > 0 ? maxY / 5 : 200,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < categories.length) {
                      String displayText = categories[index];
                      if (displayText.length > 15) {
                        displayText = '${displayText.substring(0, 12)}...';
                      }

                      return Transform.rotate(
                        angle: -0.5,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: timeValues.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: Colors.orange[400],
                    width: categories.length > 8 ? 30 : 40,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              );
            }).toList(),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 5 : 200,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: gridColor,
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: BarValuePainter(
              timeValues: timeValues,
              categories: categories,
              maxY: maxY > 0 ? maxY : 1200,
            ),
          ),
        ),
      ],
    );
  }
}

class BarValuePainter extends CustomPainter {
  final List<double> timeValues;
  final List<String> categories;
  final double maxY;

  BarValuePainter({
    required this.timeValues,
    required this.categories,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 45;
    const double rightPadding = 10;
    const double bottomPadding = 80;
    const double topPadding = 10;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final int barCount = timeValues.length;

    if (barCount == 0) return;

    final double barSpacing = chartWidth / barCount;

    for (int i = 0; i < barCount; i++) {
      final double value = timeValues[i];
      final double barHeight = (value / maxY) * chartHeight;

      final double xPos = leftPadding + (i * barSpacing) + (barSpacing / 2);
      final double yPos = topPadding + chartHeight - barHeight - 5;

      final textSpan = TextSpan(
        text: value.toStringAsFixed(0),
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, yPos));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}