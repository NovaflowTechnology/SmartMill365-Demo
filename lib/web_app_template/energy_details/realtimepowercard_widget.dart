import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/card_widget/card_widget.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter/material.dart';

import 'realtimepowercard_model.dart';
export 'realtimepowercard_model.dart';

const _kCyan = Color(0xFF00E5FF);

class RealtimepowercardWidget extends StatefulWidget {
  final double peak_energy;
  final double average_energy;
  final double prevEdel;
  final dynamic isLoading;
  final Map<String, dynamic> power;

  const RealtimepowercardWidget({
    super.key,
    required this.peak_energy,
    required this.average_energy,
    required this.isLoading,
    required this.prevEdel,
    required this.power,
  });

  @override
  State<RealtimepowercardWidget> createState() =>
      _RealtimepowercardWidgetState();
}

class _RealtimepowercardWidgetState extends State<RealtimepowercardWidget> {
  late RealtimepowercardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RealtimepowercardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _fmt(double v) => NumberFormat('#,##0.000', 'en_US').format(v);

  double get _currentKw {
    if (widget.power.containsKey('P(kW)')) {
      return (widget.power['P(kW)'] as num).toDouble();
    } else if (widget.power.containsKey('P(W)')) {
      return (widget.power['P(W)'] as num).toDouble() / 1000.0;
    }
    return 0.0;
  }

  String get _currentKwLabel =>
      _currentKw == 0.0 ? 'No Data' : '${_currentKw.round()} kW';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Base design at 380px; scale proportionally.
        final availW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 380.0;
        final scale = (availW / 380.0).clamp(0.7, 2.0);

        final titleFontSize = 20.0 * scale;
        final labelFontSize = 14.0 * scale;
        final valueFontSize = 16.0 * scale;
        final displayFontSize = 28.0 * scale;
        final hPad = 16.0 * scale;
        final vPad = 12.0 * scale;
        final smallGap = 8.0 * scale;

        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 10 * scale, 0),
          child: SizedBox(
            width: availW,
            height: 380.0, // Fixed height to maintain uniform layout with other cards
            child: CardWidget(
              armLenMultiplier: 0.56,
              topPadMultiplier: 0.0,
              glowColor: _kCyan,
              builder: (context, s) {
                return Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(hPad, hPad, hPad, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Real Time Power',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: titleFontSize,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    font: GoogleFonts.poppins(),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: smallGap * 1.5),
                      widget.isLoading == true
                          ? const Expanded(
                              child: Center(child: CircularProgressIndicator()))
                          : Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // ── Gauge (Top) ──
                                  Expanded(
                                    child: SfRadialGauge(
                                      axes: [
                                        // Outer Axis for ticks
                                        RadialAxis(
                                          canScaleToFit: true,
                                          startAngle: 180,
                                          endAngle: 0,
                                          radiusFactor: 1.0,
                                          showLabels: false,
                                          showAxisLine: false,
                                          showTicks: true,
                                          minorTicksPerInterval: 3,
                                          interval: 40,
                                          minimum: 0,
                                          maximum: 800,
                                          majorTickStyle: MajorTickStyle(
                                            length: 0.1,
                                            lengthUnit: GaugeSizeUnit.factor,
                                            thickness: 2,
                                            color: const Color(0xFF00E5FF)
                                                .withOpacity(0.8),
                                          ),
                                          minorTickStyle: MinorTickStyle(
                                            length: 0.05,
                                            lengthUnit: GaugeSizeUnit.factor,
                                            thickness: 1,
                                            color: const Color(0xFF00E5FF)
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        // Inner Axis for track and pointer
                                        RadialAxis(
                                          canScaleToFit: true,
                                          startAngle: 180,
                                          endAngle: 0,
                                          radiusFactor: 0.85,
                                          showLabels: false,
                                          showTicks: false,
                                          minimum: 0,
                                          maximum: 800,
                                          axisLineStyle: AxisLineStyle(
                                            thickness: 0.18,
                                            thicknessUnit: GaugeSizeUnit.factor,
                                            color: Theme.of(context).brightness == Brightness.light
                                                ? FlutterFlowTheme.of(context).alternate
                                                : const Color(0xFF0F172A),
                                          ),
                                          pointers: [
                                            RangePointer(
                                              value: _currentKw.clamp(0, 800),
                                              width: 0.18,
                                              sizeUnit: GaugeSizeUnit.factor,
                                              enableAnimation: true,
                                              animationDuration: 1500,
                                              animationType:
                                                  AnimationType.easeOutBack,
                                              gradient: const SweepGradient(
                                                colors: [
                                                  Color(0xFF00E5FF),
                                                  Color(0xFFFDE047),
                                                  Color(0xFFF97316),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ],
                                          annotations: [
                                            GaugeAnnotation(
                                              angle: 270,
                                              positionFactor: 0.1,
                                              widget: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _currentKwLabel,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .headlineMedium
                                                      .override(
                                                        fontFamily: 'Poppins',
                                                        font:
                                                            GoogleFonts.poppins(),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: displayFontSize,
                                                        color: _kCyan,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ── Stats (Bottom) ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Left: Peak Today
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Peak Today',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  font: GoogleFonts.poppins(),
                                                  letterSpacing: 0.0,
                                                  fontSize: labelFontSize,
                                                ),
                                          ),
                                          SizedBox(height: 2 * scale),
                                          Text(
                                            '${_fmt(widget.peak_energy)} kW',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyLarge
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  font: GoogleFonts.poppins(),
                                                  color: const Color(0xFF8B5CF6), // Purple
                                                  fontSize: valueFontSize,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ],
                                      ),
                                      // Right: Daily Consumption
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Daily Consumption',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  font: GoogleFonts.poppins(),
                                                  letterSpacing: 0.0,
                                                  fontSize: labelFontSize,
                                                ),
                                          ),
                                          SizedBox(height: 2 * scale),
                                          Text(
                                            '${_fmt(widget.average_energy)} kWh',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyLarge
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  font: GoogleFonts.poppins(),
                                                  color: _kCyan, // Cyan
                                                  fontSize: valueFontSize,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: vPad),
                                ],
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
