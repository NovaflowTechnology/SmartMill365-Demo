import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class PowerLoadDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> distributionData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final String title;

  const PowerLoadDistributionChart({
    super.key,
    required this.distributionData,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.title = '',
  });

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
                            title.isNotEmpty ? title : 'Power Load Distribution',
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
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5DADE2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Average Power Load (kW)',
                  style: GoogleFonts.poppins(
                    fontSize: sizing.bodyFs.clamp(9.0, 12.0),
                    color: theme.secondaryText,
                  ),
                ),
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

  Widget _buildChartContent(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load data', style: GoogleFonts.poppins(color: Colors.red, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (distributionData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 14),
        ),
      );
    }

    return BarChart(_buildBarChartData(context));
  }

  BarChartData _buildBarChartData(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Define colors for each time period
    final colors = [
      const Color(0xFF5DADE2), // 00:00-06:00
      const Color(0xFF66CDAA), // 06:00-10:00
      const Color(0xFFFFD54F), // 10:00-14:00
      const Color(0xFFEF8A8A), // 14:00-18:00
      const Color(0xFFB39DDB), // 18:00-22:00
      const Color(0xFF90A4AE), // 22:00-24:00
    ];

    final barData = distributionData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return {
        'day': item['time_period'] as String,
        'value': (item['average_power_load_kW'] ?? 0.0).toDouble(),
        'color': colors[index % colors.length],
      };
    }).toList();

    double maxValue = 0;
    for (var item in barData) {
      if ((item['value'] as double) > maxValue) maxValue = item['value'] as double;
    }
    double maxY = maxValue > 0 ? (maxValue * 1.1) : 1800;
    if (maxY < 1800) maxY = 1800;

    final barGroups = List.generate(
      barData.length,
      (index) => _makeGroupData(index, barData[index]['value'] as double, barData[index]['color'] as Color),
    );

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      minY: 0,
      groupsSpace: 12,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (value) => const Color.fromRGBO(0, 4, 51, 0.9),
          tooltipBorder: BorderSide(color: theme.primary, width: 1),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final idx = group.x.toInt();
            if (idx < 0 || idx >= distributionData.length || idx >= barData.length) return null;
            final data = distributionData[idx];
            final totalEnergy = (data['total_energy_kWh'] as num?)?.toDouble() ?? 0.0;
            return BarTooltipItem(
              '${barData[idx]['day'] ?? ''}\n'
              '${rod.toY.toStringAsFixed(1)} kW\n'
              'Total: ${totalEnergy.toStringAsFixed(1)} kWh\n'
              'Hours: ${data['hours_count'] ?? 0}',
              GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < barData.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    barData[value.toInt()]['day'] as String,
                    style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 4,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 10),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.secondaryText.withOpacity(0.1),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color.withOpacity(0.9),
          width: 45,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
