import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/card_widget/card_widget.dart';
import 'package:flutter/material.dart';

import 'powerconsumptionenergydetails_model.dart';
export 'powerconsumptionenergydetails_model.dart';

class PowerconsumptionenergydetailsWidget extends StatefulWidget {
  final bool isLoading;
  final List<dynamic> devices;

  const PowerconsumptionenergydetailsWidget({
    super.key,
    required this.isLoading,
    required this.devices,
  });

  @override
  State<PowerconsumptionenergydetailsWidget> createState() =>
      _PowerconsumptionenergydetailsWidgetState();
}

class _PowerconsumptionenergydetailsWidgetState
    extends State<PowerconsumptionenergydetailsWidget> {
  late PowerconsumptionenergydetailsModel _model;

  double powerDistribution = 0.0;
  final Map<String, Color> deviceColorMap = {};
  int touchedIndex = -1;

  final List<Color> _palette = const [
    Color(0xFF00E5FF), Color(0xFF69FF47), Color(0xFFFF6D00),
    Color(0xFFD500F9), Color(0xFFFFD600), Color(0xFFFF1744),
    Color(0xFF00E676), Color(0xFF2979FF), Color(0xFFFF4081),
    Color(0xFF00BFA5), Color(0xFFFFAB40), Color(0xFF7C4DFF),
  ];
  int _pi = 0;

  Color _nextColor() => _palette[_pi++ % _palette.length];

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerconsumptionenergydetailsModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
    _assignColors(widget.devices);
  }

  void _assignColors(List<dynamic> devices) {
    for (var d in devices.where((d) => d['device'].toString() != 'MSB')) {
      final name = d['device']?.toString() ?? 'Unknown';
      if (!deviceColorMap.containsKey(name)) deviceColorMap[name] = _nextColor();
    }
  }

  @override
  void didUpdateWidget(covariant PowerconsumptionenergydetailsWidget old) {
    super.didUpdateWidget(old);
    _assignColors(widget.devices);
  }

  void _calcTotal(List<dynamic> devices) {
    powerDistribution = devices.fold(
        0.0, (s, d) => s + ((d['total_energy'] as num?)?.toDouble() ?? 0.0));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _fmt(String s) {
    final p = s.split('.');
    p[0] = p[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return p.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.devices
        .where((d) => d['device'].toString() != 'MSB')
        .toList();
    _calcTotal(filtered);
    final chartDevices = filtered
        .where((d) => ((d['total_energy'] as num?)?.toDouble() ?? 0.0) > 0)
        .toList();

    const cCyan  = Color(0xFF00E5FF);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);

    // ── Guna CardWidget builder pattern — sizing dari CardSizing ──
    return CardWidget(
      armLenMultiplier: 0.7,
      builder: (context, s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: s.accentW,
                height: s.headerFs * 1.2,
                decoration: BoxDecoration(
                  color: cCyan,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: cCyan.withOpacity(0.9),
                      blurRadius: s.pad * 0.7,
                      spreadRadius: s.accentW * 0.3,
                    ),
                  ],
                ),
              ),
              SizedBox(width: s.pad * 0.5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Energy Distribution',
                    style: GoogleFonts.poppins(
                      fontSize: s.headerFs,
                      fontWeight: FontWeight.w400,
                      color: isLight ? theme.txtPrimary : Colors.white,
                      letterSpacing: 0.6,
                      shadows: isLight ? null : [
                        Shadow(color: cCyan.withOpacity(0.7), blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s.pad * 0.5),

          // ── Total energy ──
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: s.pad * 0.7, vertical: s.pad * 0.35),
            decoration: BoxDecoration(
              color: cCyan.withOpacity(0.13),
              border: Border.all(color: cCyan.withOpacity(0.55), width: s.strokeW),
              boxShadow: [
                BoxShadow(color: cCyan.withOpacity(0.18), blurRadius: s.pad * 0.8),
              ],
            ),
            child: widget.isLoading
                ? Center(child: CircularProgressIndicator(
                    color: cCyan, strokeWidth: s.strokeW * 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Total Energy Consumption',
                          style: GoogleFonts.poppins(
                            fontSize: s.labelFs,
                            color: cCyan,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: s.pad * 0.3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${_fmt(powerDistribution.toStringAsFixed(3))}kWh',
                          style: GoogleFonts.poppins(
                            fontSize: s.valueFs,
                            color: cCyan,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: cCyan.withOpacity(0.9), blurRadius: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: s.pad * 0.5),

          // ── Chart + legend ──
          Expanded(
            child: widget.isLoading
                ? Center(child: CircularProgressIndicator(
                    color: cCyan, strokeWidth: s.strokeW * 2))
                : LayoutBuilder(builder: (context, cc) {
                    final aW     = cc.maxWidth;
                    final aH     = cc.maxHeight;
                    final pieSize = min(aW * 0.36, aH * 0.88);
                    final pieR    = pieSize * 0.48;
                    final pieTR   = pieSize * 0.54;
                    final legFs   = aH * 0.115;
                    final dotSz   = aH * 0.07;
                    final legGap  = aH * 0.015;

                    final List<PieChartSectionData> sections =
                        powerDistribution <= 0
                            ? [PieChartSectionData(
                                color: Theme.of(context).brightness == Brightness.light
                                    ? FlutterFlowTheme.of(context).alternate
                                    : const Color(0xFF1E3A5F),
                                value: 100, title: '', radius: pieR)]
                            : chartDevices.asMap().entries.map((e) {
                                final i = e.key;
                                final d = e.value;
                                final name = d['device']?.toString() ?? 'Unknown';
                                final isTouched = i == touchedIndex;
                                final sliceColor = deviceColorMap[name] ?? cCyan;
                                return PieChartSectionData(
                                  color: sliceColor,
                                  value: (d['total_energy'] as num?)?.toDouble() ?? 0.0,
                                  title: isTouched
                                      ? '${d['device']}: ${_fmt(d['total_energy'].toStringAsFixed(2))}kW'
                                      : '',
                                  titleStyle: TextStyle(
                                    fontSize: legFs * 0.8,
                                    color: FlutterFlowTheme.of(context).txtOnAccent,
                                    shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                  ),
                                  radius: isTouched ? pieTR : pieR,
                                  borderSide: BorderSide(
                                    color: sliceColor.withOpacity(0.6),
                                    width: s.strokeW,
                                  ),
                                );
                              }).toList();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pie
                        SizedBox(
                          width: pieSize,
                          height: pieSize,
                          child: PieChart(PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, resp) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      resp == null ||
                                      resp.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex =
                                      resp.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sections: sections,
                            sectionsSpace: s.strokeW * 3,
                            centerSpaceRadius: 0,
                          )),
                        ),
                        SizedBox(width: s.pad * 0.6),

                        // Legend — 2 col grid, scroll if > 12, cap at 12
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: legGap,
                              crossAxisSpacing: legGap,
                              mainAxisExtent: dotSz + legGap * 2,
                            ),
                            itemCount: filtered.length.clamp(0, 12),
                            itemBuilder: (context, idx) {
                              final d        = filtered[idx];
                              final name     = d['device']?.toString() ?? 'Unknown';
                              final energy   = (d['total_energy'] as num?)?.toDouble() ?? 0.0;
                              final pct      = powerDistribution > 0
                                  ? (energy / powerDistribution) * 100
                                  : 0.0;
                              final dotColor = deviceColorMap[name] ?? cCyan;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Rounded square dot — more "techy"
                                  Container(
                                    width: dotSz,
                                    height: dotSz,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      borderRadius: BorderRadius.circular(dotSz * 0.28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: dotColor.withOpacity(0.85),
                                          blurRadius: dotSz * 0.8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: s.pad * 0.25),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$name – ${pct.toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: legFs,
                                          color: isLight ? theme.txtSecondary : const Color(0xFFCBD5E1),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),
          ),
        ],
      ),
    );
  }
}