import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/md_prediction/logic/prediction_logic.dart';
import 'package:smartmachine365/web_app_template/md_prediction/widgets/prediction_chart_widget.dart';
import 'package:smartmachine365/web_app_template/md_prediction/widgets/trend_forecast_chart_widget.dart';
import 'package:smartmachine365/web_app_template/tnb_e3_bill_simulator/widgets/tnb_cyber_deco.dart';
import 'package:smartmachine365/web_app_template/md_prediction/services/md_prediction_service.dart';
import 'package:smartmachine365/web_app_template/md_prediction/widgets/dpm_impact_list.dart';

// ---------------------------------------------------------------------------
// MD Prediction Dashboard — fully responsive, scales HD → 8K
// ---------------------------------------------------------------------------

class MdPredictionDashboard extends StatefulWidget {
  final double livePowerKw;
  final double contractLimitKw;
  final List<double> intervalReadings;
  final List<String> timeLabels;
  final List<ActiveEquipmentData> activeEquipment;
  final bool isLoadingEquipment;

  const MdPredictionDashboard({
    super.key,
    required this.livePowerKw,
    required this.contractLimitKw,
    required this.intervalReadings,
    this.timeLabels = const [],
    this.activeEquipment = const [],
    this.isLoadingEquipment = false,
  });

  @override
  State<MdPredictionDashboard> createState() => _MdPredictionDashboardState();
}

class _MdPredictionDashboardState extends State<MdPredictionDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  PredictionResult get _prediction => computePrediction(widget.intervalReadings);
  double get _predictedPeak => _prediction.predictedPeak;

  MacroPredictionResult get _macro =>
      computeMacroPrediction(widget.intervalReadings, widget.timeLabels);

  bool get _isOverLimit =>
      widget.contractLimitKw > 0 &&
      (widget.livePowerKw >= widget.contractLimitKw ||
          _predictedPeak >= widget.contractLimitKw);

  double get _usagePct => widget.contractLimitKw > 0
      ? (widget.livePowerKw / widget.contractLimitKw * 100).clamp(0, 999)
      : 0;

  List<DpmImpact> get _dpmImpacts {
    if (widget.activeEquipment.isEmpty) return [];
    final totalKw = widget.activeEquipment.fold(0.0, (s, e) => s + e.currentKw);
    return (widget.activeEquipment.map((e) {
      final frac = totalKw > 0 ? e.currentKw / totalKw : 0.0;
      return DpmImpact(
        equipment: e,
        impactKw: e.currentKw,
        loadFraction: frac,
      );
    }).toList()
      // Running machines first (kW > 0), then idle, then sort by kW desc within each group
      ..sort((a, b) {
        if ((a.impactKw > 0) != (b.impactKw > 0)) {
          return a.impactKw > 0 ? -1 : 1;
        }
        return b.impactKw.compareTo(a.impactKw);
      }));
  }

  double get _exceedKw =>
      (_predictedPeak - widget.contractLimitKw).clamp(0.0, double.infinity);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Drive ALL sizes from screen height so it looks right on every DPI/res.
    final sh = MediaQuery.of(context).size.height;

    // Reference heights — scale with screen height, hard-clamped for extremes
    final statusH   = (sh * 0.055).clamp(44.0,  72.0);
    final kpiH      = (sh * 0.115).clamp(90.0, 160.0);
    final midH   = (sh * 0.460).clamp(340.0, 700.0);
    final trendH = (sh * 0.340).clamp(260.0, 520.0);

    final impacts = _dpmImpacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Row 1: Status banner ──────────────────────────────────────────
        SizedBox(height: statusH, child: _buildStatusBar(context, statusH)),
        SizedBox(height: sh * 0.014),

        // ── Row 2: KPI metric cards ───────────────────────────────────────
        SizedBox(height: kpiH, child: _buildMetricRow(context, kpiH)),
        SizedBox(height: sh * 0.016),

        // ── Row 3: Chart  |  DPM panel — Expanded fills chart, no fixed contentH
        SizedBox(
          height: midH,
          child: _buildMidSection(context, impacts: impacts),
        ),
        SizedBox(height: sh * 0.016),

        // ── Row 4: 90-minute trend (full width)
        SizedBox(height: trendH, child: _buildTrendSection(context)),
      ],
    );
  }

  // ── Mid section ────────────────────────────────────────────────────────────

  Widget _buildMidSection(
    BuildContext context, {
    required List<DpmImpact> impacts,
  }) {
    final hasData = widget.activeEquipment.isNotEmpty || widget.isLoadingEquipment;
    final gap = MediaQuery.of(context).size.width * 0.008;

    final chartCard = _ExpandedChartCard(
      title: hasData ? 'INTERVAL FORECAST' : 'INTERVAL FORECAST',
      subtitle: hasData
          ? 'Hover P1–P3 to see DPM breakdown'
          : 'Short-term MD interval prediction',
      icon: Icons.bar_chart_rounded,
      accentColor: const Color(0xFF00C6FF),
      child: PredictionChartWidget(
        realValues: widget.intervalReadings,
        contractLimitKw: widget.contractLimitKw,
        timeLabels: widget.timeLabels,
        dpmImpacts: impacts,
      ),
    );

    if (!hasData) return chartCard;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 60, child: chartCard),
        SizedBox(width: gap),
        Expanded(
          flex: 40,
          child: _ScrollableChartCard(
            title: 'DPM RUNNING',
            subtitle: _isOverLimit
                ? 'MD EXCEEDS limit by ${_exceedKw.toStringAsFixed(0)} kW — shutdown ADJUSTABLE to recover'
                : 'Active DPMs contributing to current MD load',
            icon: Icons.precision_manufacturing_outlined,
            accentColor: _isOverLimit ? const Color(0xFFFF4444) : const Color(0xFF10B981),
            child: widget.isLoadingEquipment && impacts.isEmpty
                ? _buildEquipmentLoading()
                : DpmImpactList(
                    impacts: impacts,
                    predictedPeak: _predictedPeak,
                    exceedKw: _exceedKw,
                    isOverLimit: _isOverLimit,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentLoading() {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _ShimmerRow(delay: i * 120),
        ),
      ),
    );
  }

  // ── Trend section ──────────────────────────────────────────────────────────

  Widget _buildTrendSection(BuildContext context) {
    return _ExpandedChartCard(
      title: 'TREND FORECAST',
      subtitle: 'Next 90-minute maximum demand projection',
      icon: Icons.multiline_chart_rounded,
      accentColor: const Color(0xFF00C6FF),
      child: TrendForecastChartWidget(
        macro: _macro,
        contractLimitKw: widget.contractLimitKw,
      ),
    );
  }

  // ── Status bar ─────────────────────────────────────────────────────────────

  Widget _buildStatusBar(BuildContext context, double height) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final statusColor =
        _isOverLimit ? const Color(0xFFFF4444) : const Color(0xFF10B981);
    final statusText =
        _isOverLimit ? 'CRITICAL: MD OVERFLOW RISK' : 'MD STATUS: NORMAL';
    final sh = MediaQuery.of(context).size.height;
    final fontSize = (sh * 0.014).clamp(10.0, 14.0);

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(isLight ? 0.07 : 0.13),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border(
                    left: BorderSide(color: statusColor, width: 3),
                    bottom: BorderSide(
                        color: statusColor.withOpacity(0.25), width: 1),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1),
                ],
              ),
            ),
          ),
          CyberpunkBrackets(color: statusColor, armLength: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_isOverLimit)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => _statusDot(statusColor, _pulseAnim.value),
                  )
                else
                  _statusDot(statusColor, 1.0),
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(1, 1)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sh * 0.010).clamp(8.0, 14.0),
                    vertical:   (sh * 0.004).clamp(3.0,  6.0),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    border: Border.all(
                        color: statusColor.withOpacity(0.45), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: statusColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 0),
                    ],
                  ),
                  child: Text(
                    '${_usagePct.toStringAsFixed(1)}% CAPACITY',
                    style: GoogleFonts.poppins(
                      fontSize: (sh * 0.011).clamp(9.0, 13.0),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(Color color, double opacity) => Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(opacity * 0.7),
                blurRadius: 8,
                spreadRadius: 2),
          ],
        ),
      );

  // ── KPI metric row ─────────────────────────────────────────────────────────

  Widget _buildMetricRow(BuildContext context, double cardH) {
    final predPeak = _predictedPeak;
    final macro    = _macro;
    final next90m  = macro.next90mPeak;
    final next90mOver =
        widget.contractLimitKw > 0 && next90m >= widget.contractLimitKw;

    return LayoutBuilder(builder: (ctx, constraints) {
      final gap  = constraints.maxWidth * 0.01;
      final cardW = (constraints.maxWidth - gap * 3) / 4;
      return Row(
        children: [
          _MetricCard(
            width: cardW, height: cardH,
            title: 'LIVE POWER',
            value: '${widget.livePowerKw.toStringAsFixed(1)} kW',
            subtitle: '${_usagePct.toStringAsFixed(1)}% of contract limit',
            valueColor: const Color(0xFF00C6FF),
            subtitleColor: const Color(0xFF00C6FF).withOpacity(0.7),
            icon: Icons.bolt,
            glowColor: const Color(0xFF00C6FF),
          ),
          SizedBox(width: gap),
          _MetricCard(
            width: cardW, height: cardH,
            title: 'MD THRESHOLD',
            value: widget.contractLimitKw > 0
                ? '${widget.contractLimitKw.toStringAsFixed(0)} kW'
                : 'N/A',
            subtitle: 'Contract surcharge limit',
            valueColor: Colors.redAccent,
            subtitleColor: Colors.redAccent.withOpacity(0.7),
            icon: Icons.warning_amber_rounded,
            glowColor: Colors.redAccent,
          ),
          SizedBox(width: gap),
          _MetricCard(
            width: cardW, height: cardH,
            title: 'PREDICTED PEAK',
            value: '${predPeak.toStringAsFixed(1)} kW',
            subtitle: _isOverLimit
                ? '⚠ Exceeds by ${(predPeak - widget.contractLimitKw).toStringAsFixed(1)} kW'
                : '✓ Within safe range',
            valueColor: _isOverLimit
                ? const Color(0xFFFF4444)
                : const Color(0xFFFFC107),
            subtitleColor: _isOverLimit
                ? const Color(0xFFFF4444).withOpacity(0.8)
                : const Color(0xFF10B981),
            icon: Icons.trending_up,
            glowColor: _isOverLimit
                ? const Color(0xFFFF4444)
                : const Color(0xFFFFC107),
          ),
          SizedBox(width: gap),
          _MetricCard(
            width: cardW, height: cardH,
            title: 'NEXT 90M PEAK',
            value: next90m > 0 ? '${next90m.toStringAsFixed(1)} kW' : '---',
            subtitle: next90mOver
                ? '⚠ Trend exceeds limit'
                : next90m > 0
                    ? '✓ Trend within range'
                    : 'Insufficient history',
            valueColor: next90mOver
                ? const Color(0xFFFF4444)
                : const Color(0xFFFFC107),
            subtitleColor: next90mOver
                ? const Color(0xFFFF4444).withOpacity(0.8)
                : const Color(0xFF10B981),
            icon: Icons.multiline_chart_rounded,
            glowColor: next90mOver
                ? const Color(0xFFFF4444)
                : const Color(0xFFFFC107),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// _ExpandedChartCard — card where the chart fills all remaining height via
// Expanded. The parent SizedBox constrains total height; header takes what it
// needs; Expanded gives the rest to the chart. No hardcoded contentHeight.
// ---------------------------------------------------------------------------

class _ExpandedChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _ExpandedChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sh = MediaQuery.of(context).size.height;
    final titleFs   = 14.0.clamp(12.0, 16.0);
    final subtitleFs = 10.0.clamp(9.0, 12.0);
    final iconSz    = (sh * 0.020).clamp(12.0, 20.0);

    return Container(
      decoration: _cardDecoration(isLight, accentColor),
      child: Stack(
        children: [
          // Content fills the card
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sh * 0.012).clamp(10.0, 18.0),
                    vertical:   (sh * 0.008).clamp(8.0,  14.0),
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: accentColor.withOpacity(0.12), width: 1),
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width:  iconSz + 10,
                      height: iconSz + 10,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, size: iconSz, color: accentColor),
                    ),
                    SizedBox(width: (sh * 0.008).clamp(6.0, 12.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                fontSize: titleFs,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.8,
                              )),
                          Text(subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFs,
                                color: accentColor.withOpacity(0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ]),
                ),
                // Chart fills remaining height
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          // Corner brackets overlay
          CyberpunkBrackets(color: accentColor, armLength: 14),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ScrollableChartCard — card where the body scrolls (DPM list)
// Uses Expanded so it fills the full Row height.
// ---------------------------------------------------------------------------

class _ScrollableChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _ScrollableChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sh = MediaQuery.of(context).size.height;
    final titleFs    = 14.0.clamp(12.0, 16.0);
    final subtitleFs = 10.0.clamp(9.0, 12.0);
    final iconSz     = (sh * 0.020).clamp(12.0, 20.0);

    return Container(
      decoration: _cardDecoration(isLight, accentColor),
      child: Stack(
        children: [
          // Content fills the card
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sh * 0.012).clamp(10.0, 18.0),
                    vertical:   (sh * 0.008).clamp(8.0,  14.0),
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: accentColor.withOpacity(0.12), width: 1),
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width:  iconSz + 10,
                      height: iconSz + 10,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, size: iconSz, color: accentColor),
                    ),
                    SizedBox(width: (sh * 0.008).clamp(6.0, 12.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                fontSize: titleFs,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.8,
                              )),
                          Text(subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFs,
                                color: accentColor.withOpacity(0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ]),
                ),
                // Body — scrollable DPM list
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all((sh * 0.010).clamp(8.0, 14.0)),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Corner brackets overlay
          CyberpunkBrackets(color: accentColor, armLength: 14),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card decoration helper
// ---------------------------------------------------------------------------

BoxDecoration _cardDecoration(bool isLight, Color accentColor) => BoxDecoration(
      color: isLight
          ? Colors.white.withOpacity(0.6)
          : const Color(0xFF0A1628).withOpacity(0.85),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accentColor.withOpacity(0.18), width: 1),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Shimmer placeholder row (shown while equipment data loads)
// ---------------------------------------------------------------------------

class _ShimmerRow extends StatefulWidget {
  final int delay;
  const _ShimmerRow({required this.delay});
  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03 + _anim.value * 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.white.withOpacity(0.05 + _anim.value * 0.04),
              width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08 + _anim.value * 0.08),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07 + _anim.value * 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04 + _anim.value * 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05 + _anim.value * 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric card — responsive via explicit width/height from parent
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;
  final Color subtitleColor;
  final IconData icon;
  final Color glowColor;

  const _MetricCard({
    required this.width,
    required this.height,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    required this.subtitleColor,
    required this.icon,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CardWidget(
        topPadMultiplier: 0.85,
        glowColor: glowColor,
        builder: (ctx, sizing) => _buildContent(ctx, sizing),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final titleFs  = sizing.bodyFs.clamp(10.0, 12.0);
    final valueFs  = sizing.headerFs.clamp(24.0, 32.0);
    final bodyFs   = sizing.bodyFs.clamp(10.0, 12.0);
    const iconSize = 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: theme.secondaryText,
            fontSize: titleFs,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: valueColor,
                    fontSize: valueFs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: iconSize, color: valueColor.withOpacity(0.8)),
          ],
        ),
        const SizedBox(height: 3),
        Flexible(
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: subtitleColor,
              fontSize: bodyFs,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
