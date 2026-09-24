import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/utils/leak_probe.dart';
import '/components/card_widget/card_widget.dart';
import 'energydetailsvoltagecard_model.dart';
export 'energydetailsvoltagecard_model.dart';

class EnergydetailsvoltagecardWidget extends StatefulWidget {
  final Map<String, dynamic> voltageData;
  const EnergydetailsvoltagecardWidget({super.key, required this.voltageData});

  @override
  State<EnergydetailsvoltagecardWidget> createState() =>
      _EnergydetailsvoltagecardWidgetState();
}

class _EnergydetailsvoltagecardWidgetState
    extends State<EnergydetailsvoltagecardWidget>
    with TickerProviderStateMixin {
  late EnergydetailsvoltagecardModel _model;

  late TimerDrivenAnimation _pulseTick;
  late TimerDrivenAnimation _scanTick;

  final Map<String, AnimationController> _countCtrls = {};
  // One CurvedAnimation per key, created once. A CurvedAnimation registers a
  // status listener on its parent controller, so building a new one on every
  // data update (5s polling) grew the controller's listener list without bound
  // — leaking memory and burning CPU on every tick.
  final Map<String, CurvedAnimation> _countCurves = {};
  final Map<String, Animation<double>> _countAnims = {};
  final Map<String, double> _prevValues = {};

  @override
  void setState(VoidCallback cb) {
    super.setState(cb);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EnergydetailsvoltagecardModel());

    _pulseTick = TimerDrivenAnimation(
        period: const Duration(milliseconds: 2400), reverse: true);

    _scanTick = TimerDrivenAnimation(period: const Duration(milliseconds: 2500));

    for (final key in ['UAB', 'UBC', 'UCA', 'Uavg']) {
      final ctrl = AnimationController(
          duration: const Duration(milliseconds: 1200), vsync: this);
      final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
      _countCtrls[key] = ctrl;
      _countCurves[key] = curve;
      _countAnims[key] = Tween<double>(begin: 0, end: 0).animate(curve);
      _prevValues[key] = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerCountUp();
      safeSetState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant EnergydetailsvoltagecardWidget old) {
    super.didUpdateWidget(old);
    _triggerCountUp();
  }

  void _triggerCountUp() {
    for (final key in ['UAB', 'UBC', 'UCA', 'Uavg']) {
      final raw = widget.voltageData[key];
      final target = raw is num ? raw.toDouble() : 0.0;
      final prev = _prevValues[key] ?? 0.0;
      if (target != prev) {
        final ctrl = _countCtrls[key]!;
        // Reuse the existing curve — Tween.animate() attaches no listeners.
        _countAnims[key] =
            Tween<double>(begin: prev, end: target).animate(_countCurves[key]!);
        ctrl.forward(from: 0);
        _prevValues[key] = target;
      }
    }
  }

  @override
  void dispose() {
    _pulseTick.dispose();
    _scanTick.dispose();
    for (final c in _countCurves.values) c.dispose();
    for (final c in _countCtrls.values) c.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  String addCommas(String s) {
    final parts = s.split('.');
    parts[0] =
        parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.join('.');
  }

  // RepaintBoundary around the animation itself, not the card. Without it a
  // 14px dot ticking at 60fps re-rasterised the entire card every frame, which
  // is why removing the blur and the saveLayer changed nothing.
  Widget _pulseDot(Color color) => RepaintBoundary(
        child: AnimatedBuilder(
        animation: _pulseTick,
        builder: (_, __) => SizedBox(
          width: 14,
          height: 14,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withOpacity((0.2 + _pulseTick.value * 0.8) * 0.6), width: 1),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity((0.2 + _pulseTick.value * 0.8)),
                boxShadow: [
                  BoxShadow(
                      color: color
                          .withOpacity((0.2 + _pulseTick.value * 0.8) * 0.9),
                      blurRadius: 6,
                      spreadRadius: 1),
                ],
              ),
            ),
          ]),
        ),
      ),
      );

  Widget _scanLine(Color color) => !kEnableCardScanLine
      ? const SizedBox.shrink()
      : Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        // Positioned must stay the direct child of the Stack — wrapping it in a
        // RepaintBoundary made its parent data ignored, so the thin scan line
        // stretched to fill the whole card as a grey block. The boundary goes
        // inside instead, which still isolates the 60fps repaint.
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _scanTick,
            builder: (_, __) {
              final pos = _scanTick.value;
              final o = (pos < 0.9 ? 1.0 : (1.0 - pos) / 0.1).clamp(0.0, 1.0);
              // Fade via the gradient colours, not an Opacity widget: Opacity
              // with a changing value forces a saveLayer every frame.
              return Align(
                alignment: Alignment(0, (pos * 2) - 1),
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      color.withOpacity(0.7 * o),
                      color.withOpacity(o),
                      color.withOpacity(0.7 * o),
                      Colors.transparent,
                    ]),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4 * o), blurRadius: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _countUpText(String key, String suffix, TextStyle style) =>
      AnimatedBuilder(
        animation: _countAnims[key]!,
        builder: (_, __) {
          final val = _countAnims[key]!.value;
          final display = val == 0 && _prevValues[key] == 0
              ? 'No Data'
              : '${addCommas(val.round().toString())} $suffix';
          return Text(display, style: style);
        },
      );

  Widget _buildCompactCell(BuildContext ctx, String label, String key,
      String suffix, Color accent, IconData icon) {
    final sw = MediaQuery.of(ctx).size.width;
    final labelFs = (sw * 0.007).clamp(9.0, 13.0);
    final valueFs = (sw * 0.012).clamp(12.0, 22.0);
    final iconSz = (sw * 0.009).clamp(10.0, 16.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.4), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: accent.withOpacity(0.8), size: iconSz),
                      const SizedBox(width: 4),
                      _pulseDot(accent),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: FlutterFlowTheme.of(ctx).bodySmall.override(
                        fontFamily: 'Poppins',
                        font: GoogleFonts.poppins(),
                        color: FlutterFlowTheme.of(ctx)
                            .primaryText
                            .withOpacity(0.8),
                        fontSize: labelFs,
                        letterSpacing: 0.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _countUpText(
                      key,
                      suffix,
                      FlutterFlowTheme.of(ctx).titleMedium.override(
                        fontFamily: 'Poppins',
                        font: GoogleFonts.poppins(),
                        color: accent,
                        fontSize: valueFs,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: accent.withOpacity(0.5), blurRadius: 10)
                        ],
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCell(BuildContext ctx, String label, String key,
      String suffix, Color accent, IconData icon) {
    final sw = MediaQuery.of(ctx).size.width;
    final labelFs = (sw * 0.009).clamp(10.0, 14.0);
    final valueFs = (sw * 0.016).clamp(16.0, 28.0);
    final iconSz = (sw * 0.011).clamp(12.0, 18.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withOpacity(0.18), accent.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 1),
          ],
        ),
        child: Stack(children: [
          _scanLine(accent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: accent.withOpacity(0.5), width: 1),
                      ),
                      child: Icon(icon, color: accent, size: iconSz),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: FlutterFlowTheme.of(ctx).bodyMedium.override(
                            fontFamily: 'Poppins',
                            font: GoogleFonts.poppins(),
                            color: FlutterFlowTheme.of(ctx)
                                .primaryText
                                .withOpacity(0.9),
                            fontSize: labelFs,
                            letterSpacing: 0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _pulseDot(accent),
                  ],
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _countUpText(
                        key,
                        suffix,
                        FlutterFlowTheme.of(ctx).titleLarge.override(
                            fontFamily: 'Poppins',
                            font: GoogleFonts.poppins(),
                            color: accent,
                            fontSize: valueFs,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                  color: accent.withOpacity(0.7),
                                  blurRadius: 18),
                              Shadow(
                                  color: accent.withOpacity(0.3),
                                  blurRadius: 30),
                            ])),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlutterFlowTheme.of(context).primary;
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight.isFinite && constraints.maxHeight > 100
          ? constraints.maxHeight
          : 280.0;
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 0),
        child: SizedBox(
          width: double.infinity,
          height: h,
          child: CardWidget(
            armLenMultiplier: 0.56,
            topPadMultiplier: 0.0,
            glowColor: accent,
            builder: (ctx, _) => Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voltage Analysis',
                          style: FlutterFlowTheme.of(ctx)
                              .headlineSmall
                              .override(
                                  fontFamily: 'Poppins',
                                  font: GoogleFonts.poppins(),
                                  fontSize:
                                      (MediaQuery.of(ctx).size.width * 0.012)
                                          .clamp(13.0, 22.0),
                                  letterSpacing: 0.0,
                                  shadows: [
                                Shadow(
                                    color: accent.withOpacity(0.5),
                                    blurRadius: 10)
                              ])),
                      Icon(Icons.ev_station_rounded, color: accent, size: 24),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    height: 2,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [accent, Colors.transparent])),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Row(children: [
                            Expanded(
                                child: _buildCompactCell(
                                    ctx,
                                    'Voltage A-B',
                                    'UAB',
                                    'V',
                                    accent,
                                    Icons.electrical_services_rounded)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: _buildCompactCell(
                                    ctx,
                                    'Voltage B-C',
                                    'UBC',
                                    'V',
                                    accent,
                                    Icons.electrical_services_rounded)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: _buildCompactCell(
                                    ctx,
                                    'Voltage C-A',
                                    'UCA',
                                    'V',
                                    accent,
                                    Icons.electrical_services_rounded)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 5,
                          child: _buildFeaturedCell(
                              ctx,
                              'Voltage Average',
                              'Uavg',
                              'V',
                              accent,
                              Icons.electrical_services_rounded),
                        ),
                      ],
                    ),
                  ),
                ].divide(const SizedBox(height: 16)),
              ),
            ),
          ),
        ),
      );
    });
  }
}
