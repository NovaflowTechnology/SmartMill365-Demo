import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/md_prediction/logic/prediction_logic.dart';
import 'package:smartmachine365/web_app_template/md_prediction/widgets/dpm_impact_list.dart';

// ---------------------------------------------------------------------------
// Prediction bar chart
// ---------------------------------------------------------------------------

class PredictionChartWidget extends StatelessWidget {
  final List<double> realValues;
  final double contractLimitKw;
  final List<String> timeLabels;
  /// DPM impacts passed in to populate predicted-bar tooltips with breakdown.
  final List<DpmImpact> dpmImpacts;

  const PredictionChartWidget({
    super.key,
    required this.realValues,
    required this.contractLimitKw,
    this.timeLabels = const [],
    this.dpmImpacts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final prediction = computePrediction(realValues);
    // Parent (_RawChartCard) already provides a bounded SizedBox — no CardWidget
    // wrapper needed here. LayoutBuilder derives font sizes from available height.
    return LayoutBuilder(builder: (ctx, constraints) {
      final labelFs = (constraints.maxHeight * 0.028).clamp(8.0, 12.0);
      return _buildChart(ctx, labelFs, prediction);
    });
  }

  Widget _buildChart(
      BuildContext context, double labelFs, PredictionResult p) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final values = p.allValues;

    if (values.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.poppins(
            color: theme.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final dataMax = values.reduce(max);
    final bool zoomMode =
        contractLimitKw > 0 && dataMax < contractLimitKw * 0.20;
    final maxY = zoomMode
        ? (dataMax * 1.5).clamp(1.0, double.infinity)
        : max(dataMax, contractLimitKw) * 1.15;

    // 10A: Round the Y interval to the nearest clean step so labels never
    // overlap. Steps: 1, 5, 10, 25, 50, 100, 250, 500, 1000 …
    final double rawInterval = maxY / 4;
    final double yInterval = _niceInterval(rawInterval);

    // ── Bar groups ──────────────────────────────────────────────────────
    // 9C: Full pill shape — 6 px rounding on all corners.
    const pillRadius = BorderRadius.all(Radius.circular(6));

    const Color emergencyRed = Color(0xFFFF2222);
    const Color actualBase  = Color(0xFF00C6FF);
    const Color predAmber   = Color(0xFFFFC107);

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < values.length; i++) {
      final isPredicted = i >= p.predictionStartIndex;
      final val = values[i].clamp(0.0, double.infinity);
      final isOverLimit = contractLimitKw > 0 && val >= contractLimitKw;

      // Base accent colour for this bar (not overload-adjusted yet).
      final Color barColor = isPredicted ? predAmber : actualBase;

      // 11C: Split overloaded bars into two rodStackItems so the surcharge
      // zone (above the limit) renders in emergency red.
      final bool splitBar = isOverLimit && contractLimitKw > 0 && !isPredicted;
      final bool splitPred = isOverLimit && contractLimitKw > 0 && isPredicted;

      List<BarChartRodStackItem> stackItems = [];
      if (splitBar) {
        stackItems = [
          BarChartRodStackItem(0, contractLimitKw, actualBase.withOpacity(0.8), BorderSide.none),
          BarChartRodStackItem(contractLimitKw, val, emergencyRed, BorderSide(color: emergencyRed, width: 1)),
        ];
      } else if (splitPred) {
        stackItems = [
          BarChartRodStackItem(0, contractLimitKw, predAmber.withOpacity(0.5), BorderSide.none),
          BarChartRodStackItem(contractLimitKw, val, emergencyRed, BorderSide(color: emergencyRed, width: 1)),
        ];
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              width: 14,
              borderRadius: pillRadius,
              // When stack items are present they own the colour; otherwise
              // use the same gradient / solid fill as before.
              color: stackItems.isNotEmpty ? Colors.transparent : null,
              gradient: stackItems.isEmpty
                  ? (isPredicted
                      ? LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [barColor.withOpacity(0.25), barColor.withOpacity(0.55)],
                        )
                      : LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [const Color(0xFF003A6B), barColor],
                        ))
                  : null,
              borderSide: isOverLimit
                  ? BorderSide(color: emergencyRed, width: 1.5)
                  : (isPredicted ? BorderSide(color: barColor, width: 1.5) : BorderSide.none),
              rodStackItems: stackItems,
            ),
          ],
        ),
      );
    }

    String labelFor(int i) {
      if (i >= p.predictionStartIndex) {
        return 'P${i - p.predictionStartIndex + 1}';
      }
      if (timeLabels.length > i) return timeLabels[i];
      return '$i';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chart header ───────────────────────────────────────────────
        // 10B: Legend moved to top-right; title on left.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: accent bar + title + optional ZOOM badge
            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MD INTERVAL PREDICTION',
                  style: GoogleFonts.poppins(
                    fontSize: labelFs.clamp(9.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00C6FF),
                    letterSpacing: 0.5,
                  ),
                ),
                if (zoomMode) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      'ZOOM',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            // Right: legend with updated icon styles (10C)
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                _legendIcon(_LegendStyle.solidGlow, const Color(0xFF00C6FF), 'Actual', labelFs),
                _legendIcon(_LegendStyle.stroked, const Color(0xFFFFC107), 'Predicted', labelFs),
                _legendIcon(_LegendStyle.solidGlow, const Color(0xFFFF4444), 'Overload', labelFs),
                if (contractLimitKw > 0)
                  _legendIcon(_LegendStyle.dashedLine, const Color(0xFFFF4444),
                      'Limit ${contractLimitKw.toStringAsFixed(0)} kW', labelFs),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Bar chart + trend-connection overlay ───────────────────────
        Expanded(
          child: Stack(
            children: [
              // ── Primary bar chart ──────────────────────────────────
              BarChart(
                BarChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isLight
                      ? Colors.black.withOpacity(0.08)
                      : Colors.white.withOpacity(0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  getTooltipColor: (_) => isLight
                      ? const Color(0xFF1A2B45)
                      : const Color(0xFF0A1628),
                  getTooltipItem: (group, _, rod, __) {
                    final isPred = group.x >= p.predictionStartIndex;
                    final intervalLabel = isPred
                        ? 'P${group.x - p.predictionStartIndex + 1}'
                        : null;

                    // For predicted bars: append top-3 DPM contributors
                    if (isPred && dpmImpacts.isNotEmpty) {
                      final top = dpmImpacts.length > 3
                          ? dpmImpacts.sublist(0, 3)
                          : dpmImpacts;
                      final children = <TextSpan>[
                        for (final d in top)
                          TextSpan(
                            text:
                                '\n${d.equipment.meterId} · ${d.equipment.meterName}  ${d.impactLabel}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: d.isAdjustable
                                  ? const Color(0xFF10B981)
                                  : Colors.white.withOpacity(0.55),
                              fontWeight: d.isAdjustable
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        if (dpmImpacts.length > 3)
                          TextSpan(
                            text:
                                '\n+${dpmImpacts.length - 3} more DPMs…',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                      ];

                      return BarTooltipItem(
                        '⟡ $intervalLabel  ${rod.toY.toStringAsFixed(1)} kW',
                        GoogleFonts.poppins(
                          color: const Color(0xFFFFC107),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        children: children,
                      );
                    }

                    return BarTooltipItem(
                      '${isPred ? "⟡ $intervalLabel\n" : ""}${rod.toY.toStringAsFixed(1)} kW',
                      GoogleFonts.poppins(
                        color: isPred
                            ? const Color(0xFFFFC107)
                            : const Color(0xFF00C6FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: yInterval,
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
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= values.length) {
                        return const SizedBox.shrink();
                      }
                      final isPred = i >= p.predictionStartIndex;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          labelFor(i),
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            color: isPred
                                ? const Color(0xFFFFC107)
                                : theme.secondaryText,
                            fontWeight: isPred
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
              // 11A: Limit line moved to the LineChart overlay so it renders
              // strictly above bars (ExtraLinesData renders behind bars).
              extraLinesData: const ExtraLinesData(),
            ),  // closes BarChartData
          ),    // closes BarChart

              // ── 9D: Trend-connection bezier overlay ────────────────
              // A transparent LineChart with the same coordinate space
              // draws a dashed curved line from the last actual bar top
              // to the tops of P1, P2, P3.
              if (p.predictionStartIndex > 0 && p.predictionStartIndex < values.length)
                IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (values.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      backgroundColor: Colors.transparent,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      // Mirror the same reserved sizes as the BarChart so
                      // plot areas align perfectly.
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false, reservedSize: 48),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false, reservedSize: 28),
                        ),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                      // 11A: Limit line in foreground — above all bars.
                      extraLinesData: contractLimitKw > 0
                          ? ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: zoomMode ? maxY : contractLimitKw,
                                  color: const Color(0xFFFF4444),
                                  strokeWidth: 2.5,
                                  dashArray: [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    // 11D: Position above the line to avoid collision with dashes.
                                    alignment: zoomMode ? Alignment.bottomRight : Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFFE500),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      // Dark backdrop behind the text for contrast.
                                      background: Paint()
                                        ..color = const Color(0xCC000000)
                                        ..strokeWidth = 10
                                        ..strokeJoin = StrokeJoin.round
                                        ..style = PaintingStyle.stroke,
                                    ),
                                    labelResolver: (_) => zoomMode
                                        ? ' ▲ ${contractLimitKw.toStringAsFixed(0)} kW '
                                        : ' LIMIT ${contractLimitKw.toStringAsFixed(0)} kW ',
                                  ),
                                ),
                              ],
                            )
                          : null,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = p.predictionStartIndex - 1; i < values.length; i++)
                              FlSpot(i.toDouble(), values[i].clamp(0.0, double.infinity)),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: const Color(0xFFFFC107).withOpacity(0.55),
                          barWidth: 1.5,
                          dashArray: [5, 4],
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, i) {
                              // Only show dots on predicted points (skip the anchor).
                              if (spot.x < p.predictionStartIndex) {
                                return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0, strokeColor: Colors.transparent);
                              }
                              return FlDotCirclePainter(
                                radius: 3,
                                color: const Color(0xFFFFC107),
                                strokeWidth: 1,
                                strokeColor: const Color(0xFFFFC107).withOpacity(0.4),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 10C: Distinct icon per legend type.
  Widget _legendIcon(_LegendStyle style, Color color, String label, double labelFs) {
    Widget icon;
    switch (style) {
      case _LegendStyle.solidGlow:
        icon = Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5, spreadRadius: 1)],
          ),
        );
      case _LegendStyle.stroked:
        icon = Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
          ),
        );
      case _LegendStyle.dashedLine:
        // 11B: dashed-line icon matching the limit line style.
        icon = SizedBox(
          width: 20,
          height: 9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 5, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 5, height: 2, color: color),
              const SizedBox(width: 2),
              Container(width: 5, height: 2, color: color),
            ],
          ),
        );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: labelFs.clamp(8.0, 10.0),
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 10A: Rounds a raw interval to the nearest "nice" step so Y-axis labels
  // have clean values (e.g. 0, 50, 100, 150 instead of 0, 39, 78, 117).
  static double _niceInterval(double raw) {
    if (raw <= 0) return 1;
    const steps = [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000];
    for (final s in steps) {
      if (s >= raw) return s.toDouble();
    }
    return (raw / 1000).ceilToDouble() * 1000;
  }
}

enum _LegendStyle { solidGlow, stroked, dashedLine }
