import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/card_widget/card_widget.dart';
import 'package:flutter/material.dart';

import 'powerusagecard_model.dart';
export 'powerusagecard_model.dart';

class PowerusagecardWidget extends StatefulWidget {
  final List<dynamic> devices;
  final bool isLoading;
  final String period;

  const PowerusagecardWidget({
    super.key,
    required this.devices,
    required this.period,
    required this.isLoading,
  });

  @override
  State<PowerusagecardWidget> createState() => _PowerusagecardWidgetState();
}

class _PowerusagecardWidgetState extends State<PowerusagecardWidget> {
  late PowerusagecardModel _model;
  double powerDistribution = 0.0;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerusagecardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _addCommas(String s) {
    final parts = s.split('.');
    parts[0] = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.join('.');
  }

  void _calcTotal() {
    powerDistribution = widget.devices.fold(
        0.0, (s, d) => s + ((d['total_energy'] as num?)?.toDouble() ?? 0.0));
  }

  String get _periodName {
    switch (widget.period) {
      case 'daily':   return 'Daily';
      case 'monthly': return 'Monthly';
      case 'yearly':  return 'Yearly';
      default:        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    _calcTotal();
    final theme = FlutterFlowTheme.of(context);
    const cCyan = Color(0xFF00E5FF);

    return CardWidget(
      armLenMultiplier: 0.7,
      topPadMultiplier: 0.0,
      builder: (context, s) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        final vPad    = s.h * 0.08;
        final hPad    = s.w * 0.04;
        final titleFs = s.h * 0.14;
        final labelFs = s.h * 0.11;
        final valueFs = s.h * 0.18;
        final iconSz  = s.h * 0.11;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title — mentok atas ──
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Energy Usage',
                  style: GoogleFonts.poppins(
                    fontSize: titleFs,
                    fontWeight: FontWeight.w400,
                    color: isLight ? theme.txtPrimary : Colors.white,
                    letterSpacing: 0.6,
                    shadows: isLight ? null : [
                      Shadow(color: cCyan.withOpacity(0.6), blurRadius: 10),
                    ],
                  ),
                ),
              ),

              // ── Values — mentok bawah ──
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: widget.isLoading
                  ? Center(child: CircularProgressIndicator(
                      color: cCyan, strokeWidth: 2))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Usage
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$_periodName Usage',
                                      style: GoogleFonts.poppins(
                                        fontSize: labelFs,
                                        color: theme.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: s.w * 0.01),
                                  Icon(Icons.flash_on,
                                      size: iconSz, color: Colors.amber),
                                ],
                              ),
                              SizedBox(height: s.h * 0.04),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${_addCommas(powerDistribution.toStringAsFixed(3))}kWh',
                                  style: GoogleFonts.poppins(
                                    fontSize: valueFs,
                                    color: theme.primary,
                                    fontWeight: FontWeight.w700,
                                    shadows: isLight ? null : [Shadow(
                                      color: theme.primary.withOpacity(0.6),
                                      blurRadius: 10,
                                    )],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: s.w * 0.05),

                        // Emission
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$_periodName Emission',
                                      style: GoogleFonts.poppins(
                                        fontSize: labelFs,
                                        color: theme.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: s.w * 0.01),
                                  Icon(Icons.cloud_outlined,
                                      size: iconSz, color: Colors.redAccent),
                                ],
                              ),
                              SizedBox(height: s.h * 0.04),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${_addCommas((powerDistribution * 0.58).toStringAsFixed(3))}kgCO2e',
                                  style: GoogleFonts.poppins(
                                    fontSize: valueFs,
                                    color: theme.error,
                                    fontWeight: FontWeight.w700,
                                    shadows: isLight ? null : [Shadow(
                                      color: theme.error.withOpacity(0.6),
                                      blurRadius: 10,
                                    )],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}