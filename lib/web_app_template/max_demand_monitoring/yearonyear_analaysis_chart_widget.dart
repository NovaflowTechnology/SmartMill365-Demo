import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class YearOnYearAnalysisChart extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  final List<Map<String, dynamic>> comparisonYearData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final double contractCapacity;
  final String title;

  const YearOnYearAnalysisChart({
    super.key,
    required this.chartData,
    required this.comparisonYearData,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.contractCapacity,
    this.title = '',
  });

  String get previousPeriod {
    if (comparisonYearData.isNotEmpty && comparisonYearData.first['previous_period'] != null) {
      return comparisonYearData.first['previous_period'].toString();
    }
    return 'Previous Period';
  }

  String get currentPeriod {
    if (comparisonYearData.isNotEmpty && comparisonYearData.first['current_period'] != null) {
      return comparisonYearData.first['current_period'].toString();
    }
    return 'Current Period';
  }

  int get startingMonth {
    // Malaysia time (UTC+8, no DST) so "current month" matches MYT
    // regardless of the viewer's device timezone.
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    int startMonth = now.month + 1;
    if (startMonth > 12) startMonth = startMonth - 12;
    return startMonth;
  }

  List<String> get orderedMonthLabels {
    const allMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    List<String> ordered = [];
    for (int i = 0; i < 12; i++) {
      ordered.add(allMonths[((startingMonth - 1 + i) % 12)]);
    }
    return ordered;
  }

  int getChartPosition(int apiMonth) {
    int position = apiMonth - startingMonth;
    if (position < 0) position += 12;
    return position;
  }

  List<FlSpot> get spotsPreviousPeriod {
    List<FlSpot> spots = [];
    for (var data in chartData) {
      int month = data['month'] as int;
      double value = ((data['previous_period_max_demand_kW'] ?? 0) as num).toDouble();
      spots.add(FlSpot(getChartPosition(month).toDouble(), value));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  List<FlSpot> get spotsCurrentPeriod {
    List<FlSpot> spots = [];
    for (var data in chartData) {
      int month = data['month'] as int;
      double value = ((data['current_period_max_demand_kW'] ?? 0) as num).toDouble();
      spots.add(FlSpot(getChartPosition(month).toDouble(), value));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  double get maxY {
    if (spotsPreviousPeriod.isEmpty && spotsCurrentPeriod.isEmpty) return 1000;
    List<double> allValues = [
      ...spotsPreviousPeriod.map((s) => s.y),
      ...spotsCurrentPeriod.map((s) => s.y),
      contractCapacity,
    ];
    double max = allValues.reduce((a, b) => a > b ? a : b);
    if (max == 0) return contractCapacity > 0 ? contractCapacity * 1.2 : 1000;
    return (max * 1.2).ceilToDouble();
  }

  double get minY => 0;

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool heightBounded = constraints.maxHeight.isFinite;
        const double fallbackChartHeight = 280.0;

        Widget chartBody = _buildChartContent(context);

        return Column(
          mainAxisSize: heightBounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: sizing.accentW,
                        height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withOpacity(0.9),
                              blurRadius: sizing.pad * 0.7,
                              spreadRadius: sizing.accentW * 0.3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: sizing.pad * 0.5),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title.isNotEmpty ? title : 'Year-on-Year Analysis (Last Year vs This Year)',
                            style: GoogleFonts.poppins(
                              fontSize: sizing.titleFs.clamp(12.0, 16.0),
                              fontWeight: FontWeight.w700,
                              color: isLight ? theme.txtPrimary : Colors.white,
                              letterSpacing: 0.6,
                              shadows: isLight ? null : [
                                Shadow(
                                  color: theme.primary.withOpacity(0.7),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, color: theme.secondaryText, size: 20),
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Legend ───────────────────────────────────────────────────────
            Row(
              children: [
                _buildLegendItem(context, color: const Color(0xFF5DADE2), label: previousPeriod, sizing: sizing),
                const SizedBox(width: 20),
                _buildLegendItem(context, color: const Color(0xFF66CDAA), label: currentPeriod, sizing: sizing),
                const SizedBox(width: 20),
                _buildLegendItem(context, color: Colors.red.withOpacity(0.3), label: 'Contract Capacity', isDashed: true, sizing: sizing),
              ],
            ),
            const SizedBox(height: 16),

            // ── Chart body ───────────────────────────────────────────────────
            heightBounded
                ? Expanded(child: chartBody)
                : SizedBox(height: fallbackChartHeight, child: chartBody),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    bool isDashed = false,
    required CardSizing sizing,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: isDashed ? 2 : 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: sizing.bodyFs.clamp(9.0, 12.0),
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildChartContent(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.error, size: 48),
            const SizedBox(height: 16),
            Text(errorMessage!, style: GoogleFonts.poppins(color: theme.error, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (chartData.isEmpty) {
      return Center(
        child: Text('No data available', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 14)),
      );
    }

    return LineChart(_buildLineChartData(context));
  }

  LineChartData _buildLineChartData(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final monthLabels = orderedMonthLabels;

    double yInterval = (maxY / 5).ceilToDouble();
    if (yInterval > 100) {
      yInterval = ((yInterval / 100).ceil() * 100).toDouble();
    } else if (yInterval > 50) {
      yInterval = ((yInterval / 50).ceil() * 50).toDouble();
    } else if (yInterval > 10) {
      yInterval = ((yInterval / 10).ceil() * 10).toDouble();
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.secondaryText.withOpacity(0.1),
          strokeWidth: 1,
        ),
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
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < 12) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(monthLabels[index], style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10), textAlign: TextAlign.center),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(value.toInt().toString(), style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 11,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spotsPreviousPeriod,
          isCurved: true,
          color: const Color(0xFF5DADE2),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: const Color(0xFF5DADE2),
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF5DADE2).withOpacity(0.3), const Color(0xFF5DADE2).withOpacity(0.05)],
            ),
          ),
        ),
        LineChartBarData(
          spots: spotsCurrentPeriod,
          isCurved: true,
          color: const Color(0xFF66CDAA),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: const Color(0xFF66CDAA),
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF66CDAA).withOpacity(0.3), const Color(0xFF66CDAA).withOpacity(0.05)],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (value) => const Color.fromRGBO(0, 4, 51, 0.9),
          tooltipBorder: BorderSide(color: theme.primary, width: 1),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final monthIndex = spot.x.toInt();
              final isPreviousPeriod = spot.bar.color == const Color(0xFF5DADE2);
              final period = isPreviousPeriod ? previousPeriod : currentPeriod;
              return LineTooltipItem(
                '${monthLabels[monthIndex]}\n$period\n${spot.y.toInt()} kW',
                GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              );
            }).toList();
          },
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: contractCapacity,
            color: Colors.red.withOpacity(0.5),
            strokeWidth: 2,
            dashArray: [8, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              style: GoogleFonts.poppins(color: Colors.red.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500),
              labelResolver: (line) => '${contractCapacity.toInt()} kW',
            ),
          ),
        ],
      ),
    );
  }
}
