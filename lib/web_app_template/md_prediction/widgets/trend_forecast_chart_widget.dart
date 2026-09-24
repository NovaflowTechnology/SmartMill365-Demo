import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/md_prediction/logic/prediction_logic.dart';

// ---------------------------------------------------------------------------
// 30-min trend forecast line chart
// ---------------------------------------------------------------------------

class TrendForecastChartWidget extends StatelessWidget {
  final MacroPredictionResult macro;
  final double contractLimitKw;

  const TrendForecastChartWidget({
    super.key,
    required this.macro,
    required this.contractLimitKw,
  });

  static const Color _colorActual = Color(0xFF00C6FF);
  static const Color _colorPredicted = Color(0xFFFFC107);
  static const Color _colorLimit = Color(0xFFFF4444);

  @override
  Widget build(BuildContext context) {
    // Parent (_RawChartCard) already provides a bounded SizedBox — no CardWidget
    // wrapper needed. Using LayoutBuilder to derive font sizes.
    return LayoutBuilder(builder: (ctx, constraints) {
      final fakeFs = (constraints.maxHeight * 0.028).clamp(8.0, 12.0);
      return _buildContent(ctx, fakeFs);
    });
  }

  Widget _buildContent(BuildContext context, double labelFs) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final allActual = macro.actualSlice;
    final allPredicted = macro.predictedValues;

    if (allActual.isEmpty) {
      return Center(
        child: Text(
          'Insufficient data for trend forecast',
          style: GoogleFonts.poppins(
            color: theme.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Build FlSpots: actual occupies x=0..n-1, predicted x=n..n+2
    final actualSpots = <FlSpot>[
      for (int i = 0; i < allActual.length; i++)
        FlSpot(i.toDouble(), allActual[i].clamp(0, double.infinity)),
    ];

    // Connect predicted line starting from the last actual point.
    final predOffset = allActual.length - 1;
    final predictedSpots = <FlSpot>[
      FlSpot(predOffset.toDouble(), allActual.last.clamp(0, double.infinity)),
      for (int i = 0; i < allPredicted.length; i++)
        FlSpot((predOffset + 1 + i).toDouble(),
            allPredicted[i].clamp(0, double.infinity)),
    ];

    final allY = [...allActual, ...allPredicted, if (contractLimitKw > 0) contractLimitKw];
    final maxY = (allY.reduce(max) * 1.2).clamp(100.0, double.infinity);
    final yInterval = ((maxY / 5) / 100).ceil() * 100.0;
    final totalPoints = allActual.length + allPredicted.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_colorPredicted, Color(0xFFFF8F00)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '30-MIN TREND FORECAST  ·  NEXT 90 MIN',
              style: GoogleFonts.poppins(
                fontSize: labelFs.clamp(9.0, 12.0),
                fontWeight: FontWeight.w700,
                color: _colorPredicted,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            _legendItem(_colorActual, 'Actual', labelFs),
            const SizedBox(width: 12),
            _legendItem(_colorPredicted, 'Predicted', labelFs, isDashed: true),
            if (contractLimitKw > 0) ...[
              const SizedBox(width: 12),
              _legendItem(_colorLimit, 'Limit', labelFs, isDashed: true),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // ── Line chart ────────────────────────────────────────────────────
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (totalPoints - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval > 0 ? yInterval : maxY / 5,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isLight
                      ? Colors.black.withOpacity(0.07)
                      : Colors.white.withOpacity(0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: yInterval > 0 ? yInterval : maxY / 5,
                    getTitlesWidget: (val, _) => Text(
                      val >= 1000
                          ? '${(val / 1000).toStringAsFixed(1)}k'
                          : val.toInt().toString(),
                      style: GoogleFonts.poppins(
                          color: theme.secondaryText, fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: totalPoints <= 12 ? 1 : (totalPoints / 8).ceilToDouble(),
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      final isPred = i >= allActual.length;
                      String label = '';

                      if (!isPred && i < macro.actualLabels.length) {
                        try {
                          final t = DateTime.parse(macro.actualLabels[i]);
                          label = '${t.hour.toString().padLeft(2, '0')}:'
                              '${t.minute.toString().padLeft(2, '0')}';
                        } catch (_) {
                          label = macro.actualLabels[i];
                        }
                      } else {
                        final predIdx = i - allActual.length;
                        if (predIdx >= 0 && predIdx < macro.predictedLabels.length) {
                          try {
                            final t = DateTime.parse(macro.predictedLabels[predIdx]);
                            label = '${t.hour.toString().padLeft(2, '0')}:'
                                '${t.minute.toString().padLeft(2, '0')}';
                          } catch (_) {}
                        }
                      }

                      if (label.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            color: isPred ? _colorPredicted : theme.secondaryText,
                            fontWeight: isPred ? FontWeight.w700 : FontWeight.normal,
                            fontStyle: isPred ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // Actual line
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: _colorActual,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _colorActual.withOpacity(0.18),
                        _colorActual.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                // Predicted dashed line (gold/amber)
                LineChartBarData(
                  spots: predictedSpots,
                  isCurved: true,
                  color: _colorPredicted,
                  barWidth: 2.0,
                  isStrokeCapRound: true,
                  dashArray: [6, 4],
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, i) {
                      // Only show dot on actual predicted points, not the connector.
                      if (i == 0) return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0, strokeColor: Colors.transparent);
                      return FlDotCirclePainter(
                        radius: 3.5,
                        color: _colorPredicted,
                        strokeWidth: 1,
                        strokeColor: _colorPredicted.withOpacity(0.4),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _colorPredicted.withOpacity(0.12),
                        _colorPredicted.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0D1B2E),
                  tooltipBorder: const BorderSide(color: Color(0xFF00C6FF), width: 1),
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final i = spot.x.toInt();
                      final isPred = i >= allActual.length;
                      final color = isPred ? _colorPredicted : _colorActual;
                      String time = '';
                      if (!isPred && i < macro.actualLabels.length) {
                        try {
                          final t = DateTime.parse(macro.actualLabels[i]);
                          time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        } catch (_) {}
                      } else {
                        final pi = i - allActual.length;
                        if (pi >= 0 && pi < macro.predictedLabels.length) {
                          try {
                            final t = DateTime.parse(macro.predictedLabels[pi]);
                            time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                          } catch (_) {}
                        }
                      }
                      final prefix = isPred ? '⟡ PRED\n' : '';
                      return LineTooltipItem(
                        '$prefix${spot.y.toStringAsFixed(1)} kW\n$time',
                        GoogleFonts.poppins(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              extraLinesData: contractLimitKw > 0
                  ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: contractLimitKw,
                          color: _colorLimit.withOpacity(0.85),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 6, bottom: 4),
                            style: GoogleFonts.poppins(
                              color: _colorLimit,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                              ],
                            ),
                            labelResolver: (_) =>
                                'LIMIT ${contractLimitKw.toStringAsFixed(0)} kW',
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, double fs,
      {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDashed
            ? SizedBox(
                width: 20,
                child: Row(
                  children: [
                    Container(width: 6, height: 2, color: color),
                    const SizedBox(width: 2),
                    Container(width: 6, height: 2, color: color),
                  ],
                ),
              )
            : Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
                ),
              ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fs.clamp(8.0, 10.0),
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
