import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/utils/leak_probe.dart';
import '/components/card_widget/card_widget.dart';

import 'powerusagecardenergydetails_model.dart';
export 'powerusagecardenergydetails_model.dart';

class PowerusagecardenergydetailsWidget extends StatefulWidget {
  final double dailyUsage;
  final double monthlyUsage;
  final double yearlyUsage;
  final double dailyEmission; // -1 = not provided → fall back to estimate
  final bool isLoading;

  const PowerusagecardenergydetailsWidget({
    super.key,
    required this.dailyUsage,
    required this.monthlyUsage,
    required this.yearlyUsage,
    this.dailyEmission = -1.0,
    required this.isLoading,
  });

  @override
  State<PowerusagecardenergydetailsWidget> createState() =>
      _PowerusagecardenergydetailsWidgetState();
}

class _PowerusagecardenergydetailsWidgetState
    extends State<PowerusagecardenergydetailsWidget>
    with SingleTickerProviderStateMixin {
  late PowerusagecardenergydetailsModel _model;
  late TimerDrivenAnimation _floatCtrl;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();

    _floatCtrl = TimerDrivenAnimation(
        period: const Duration(milliseconds: 6000), reverse: true);

    _model = createModel(context, () => PowerusagecardenergydetailsModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  String addCommas(String numberStr) {
    return numberStr.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match m) => ',',
    );
  }

  Widget _buildFloatingIcon(
      BuildContext context, Color accentColor, IconData topIcon) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, (-5.0 + _floatCtrl.value * 10.0)),
          child: SizedBox(
            width: 58,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -2,
                  child: Transform.translate(
                    offset: Offset(0, -(-5.0 + _floatCtrl.value * 10.0) * 0.5),
                    child: _buildIndicatorIcon(topIcon, accentColor,
                        opacity: 1.0, containerSize: 26, iconSize: 16),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(
                            0.2 + (((-5.0 + _floatCtrl.value * 10.0) + 5) / 10) * 0.3,
                          ),
                          blurRadius: 10,
                          spreadRadius: 2 + ((-5.0 + _floatCtrl.value * 10.0) + 5) / 5,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicatorIcon(IconData icon, Color color,
      {double opacity = 1.0, double containerSize = 18, double iconSize = 12}) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 6),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: color.withOpacity(opacity),
        shadows: [Shadow(color: color, blurRadius: 6)],
      ),
    );
  }

  Widget _buildStatBox({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required Color valueColor,
    required Widget graphicWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Poppins',
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 16,
                letterSpacing: 0.0,
                font: GoogleFonts.poppins(),
              ),
        ),
        const SizedBox(height: 4),
        Container(
          // Border Dihapus sesuai permintaan gambar
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 70, // Sedikit lebih tinggi agar ikon leluasa
                alignment: Alignment.center,
                child: graphicWidget,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: FlutterFlowTheme.of(context).titleLarge.override(
                              fontFamily: 'Poppins',
                              color: valueColor,
                              letterSpacing: 2.0,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              font: GoogleFonts.poppins(),
                            ),
                      ),
                    ),
                    Text(
                      unit,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Poppins',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 10,
                            letterSpacing: 0.0,
                            font: GoogleFonts.poppins(),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = FlutterFlowTheme.of(context).primary;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 0),
      child: SizedBox(
        width: 380,
        height: 380, // Tinggi disesuaikan
        child: CardWidget(
          armLenMultiplier: 0.56,
          topPadMultiplier: 0.0,
          glowColor: accentColor,
          builder: (context, s) {
            return Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Energy Usage',
                        style:
                            FlutterFlowTheme.of(context).headlineSmall.override(
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.0,
                                  font: GoogleFonts.poppins(),
                                ),
                      ),
                      Icon(
                        Icons.bolt_rounded,
                        color: accentColor,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  widget.isLoading
                      ? const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                      : Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatBox(
                                      context: context,
                                      title: 'Daily Usage',
                                      value: addCommas(
                                          widget.dailyUsage.round().toString()),
                                      unit: 'kWh',
                                      valueColor: accentColor,
                                      graphicWidget: _buildFloatingIcon(context,
                                          accentColor, Icons.bolt_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatBox(
                                      context: context,
                                      title: 'Monthly Usage',
                                      value: addCommas(widget.monthlyUsage
                                          .round()
                                          .toString()),
                                      unit: 'kWh',
                                      valueColor: accentColor,
                                      graphicWidget: _buildFloatingIcon(
                                          context,
                                          accentColor,
                                          Icons.calendar_today_rounded),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatBox(
                                      context: context,
                                      title: 'Yearly Usage',
                                      value: addCommas(widget.yearlyUsage
                                          .round()
                                          .toString()),
                                      unit: 'kWh',
                                      valueColor: accentColor,
                                      graphicWidget: _buildFloatingIcon(
                                          context,
                                          accentColor,
                                          Icons.calendar_month_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatBox(
                                      context: context,
                                      title: 'Daily Emission',
                                      value: addCommas(
                                          (widget.dailyEmission >= 0
                                                  ? widget.dailyEmission
                                                  : widget.dailyUsage * 0.58)
                                              .round()
                                              .toString()),
                                      unit: 'kgCO2e',
                                      valueColor:
                                          FlutterFlowTheme.of(context).error,
                                      graphicWidget: _buildFloatingIcon(
                                          context,
                                          FlutterFlowTheme.of(context).error,
                                          Icons.co2_rounded),
                                    ),
                                  ),
                                ],
                              ),
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
  }
}
