import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'air_compressor_monitoring_model.dart';
import 'air_compressor_dashboard_config.dart';
import 'air_compressor_data_service.dart';
import 'widgets/ac_header_bar.dart';
import 'widgets/ac_kpi_stat_card.dart';
import 'widgets/ac_distribution_flow_card.dart';
import 'widgets/ac_insight_feed_card.dart';
import 'widgets/ac_demand_side_grid_card.dart';
import 'widgets/ac_compressor_efficiency_card.dart';
import 'widgets/ac_system_status_card.dart';
import 'widgets/ac_specific_energy_trend_card.dart';
import 'widgets/ac_header_flow_trend_card.dart';
export 'air_compressor_monitoring_model.dart';

/// "Compressed Air Command Center" — Phase 1 static demo dashboard for the
/// new Utility Monitoring > Air Compressor Monitoring sidebar module.
class AirCompressorMonitoringWidget extends StatefulWidget {
  const AirCompressorMonitoringWidget({super.key});

  @override
  State<AirCompressorMonitoringWidget> createState() => _AirCompressorMonitoringWidgetState();
}

class _AirCompressorMonitoringWidgetState extends State<AirCompressorMonitoringWidget> {
  late AirCompressorMonitoringModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late DateTime _liveTime;
  Timer? _clockTimer;

  String _selectedTimeRange = '15m';
  String _specificEnergyRange = '24h';
  String _headerFlowRange = '24h';

  // Plant is fixed (matches the settings page's own single-fixed-page
  // scope) — configured device IDs / parameters, empty until loaded.
  static const String _plant = 'Lot 237';
  AirCompressorDashboardConfig _config = AirCompressorDashboardConfig.empty();
  AcLiveData _live = AcLiveData.empty;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AirCompressorMonitoringModel());
    _liveTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _liveTime = DateTime.now());
    });
    unawaited(_loadConfig());
  }

  Future<void> _loadConfig() async {
    // Local cache first (instant paint), then reconcile with the backend
    // (client-scoped via x-client-id) once it responds — same pattern as
    // CarbonEmissionWidget's _loadConfigForPlant.
    final cached = await AirCompressorDashboardConfigStore.load(_plant);
    if (mounted) setState(() => _config = cached);
    unawaited(_loadLiveData());

    final uid = AppStateNotifier.instance.uid ?? '';
    final remote = await AirCompressorDashboardConfigService.fetch(uid, _plant);
    if (remote != null) {
      if (mounted) setState(() => _config = remote);
      await AirCompressorDashboardConfigStore.save(_plant, remote);
      unawaited(_loadLiveData());
    }
  }

  // Total Power / AC1 / AC2 power resolved from the mapped Device IDs — the
  // rest of the dashboard stays on Phase 1 demo values (see AcLiveData).
  Future<void> _loadLiveData() async {
    final live = await AirCompressorDataService.resolve(_config);
    if (mounted) setState(() => _live = live);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: t.primaryBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.primaryBackground,
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/backgroundanimated.gif'),
                ),
              ),
              child: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AcHeaderBar(
                          liveTime: _liveTime,
                          selectedRange: _selectedTimeRange,
                          onRangeChanged: (r) => setState(() => _selectedTimeRange = r),
                        ),
                        const SizedBox(height: 16),
                        _buildKpiCards(),
                        const SizedBox(height: 14),
                        _buildMiddleRow(),
                        const SizedBox(height: 14),
                        AcDemandSideGridCard(points: [for (final p in kAcCastPoints) _resolveCastPoint(p)]),
                        const SizedBox(height: 14),
                        _buildBottomRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Total Power is backed by a real fetch today. Specific Energy is Total
  // Power ÷ Header Flow — Header Flow has no live backend yet, so it stays
  // "--" until that telemetry exists (never falls back to an unrelated
  // reading just because Header Flow is missing). Total Flow, Header
  // Pressure, and System Health have no live backend yet either, so they
  // always render "--".
  String _kpiValue(String label) {
    switch (label) {
      case 'TOTAL POWER':
        return _live.totalPowerValue?.toStringAsFixed(0) ?? '--';
      case 'SPECIFIC ENERGY':
        final power = _live.totalPowerValue;
        final headerFlow = _live.headerFlowValue;
        if (power == null || headerFlow == null || headerFlow == 0) return '--';
        return (power / headerFlow).toStringAsFixed(2);
      default:
        return '--';
    }
  }

  // TOTAL POWER's unit follows whichever METRIC FIELD is mapped (kW or
  // kWh) — every other KPI keeps its static unit from kAcKpiDefs.
  String _kpiUnit(AcKpiDef kpi) => kpi.label == 'TOTAL POWER' ? _live.totalPowerUnit : kpi.unit;

  // AC1/AC2 with their live reading (kW or kWh, per mapped METRIC FIELD)
  // swapped in when available — null (shown as "N/A") until a Device ID is
  // mapped, or "Not available yet" when mapped but the field has no live
  // source (e.g. Power Factor).
  List<AcCompressor> get _liveCompressors => [
        kAc1.copyWith(powerValue: _live.ac1Value, unit: _live.ac1Unit, fieldSupported: _live.ac1FieldSupported),
        kAc2.copyWith(powerValue: _live.ac2Value, unit: _live.ac2Unit, fieldSupported: _live.ac2FieldSupported),
      ];

  // Demand Side flow has no live backend yet (see AirCompressorDataService)
  // — never show the fabricated demo reading, mapped or not. The manual
  // requirement (pressure/flow) is real user config, so it still comes
  // through independently of that.
  AcCastPoint _resolveCastPoint(AcCastPoint demo) {
    final load = _config.demandLoads.where((d) => d.label == demo.label).firstOrNull;
    return AcCastPoint(
      label: demo.label,
      value: null,
      reqPressure: load?.reqPressure,
      reqFlow: load?.reqFlow,
    );
  }

  // System Status / Leakage Status / Availability / Downtime / Dew Point
  // have no live backend or rule engine yet — all null, rendered as "N/A".
  Widget _buildSystemStatusCard() {
    return AcSystemStatusCard(
      status: AcSystemStatus(nextMaintenance: _config.nextMaintenanceLabel ?? 'N/A'),
    );
  }

  Widget _buildKpiCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final cards = [
        for (final kpi in kAcKpiDefs)
          AcKpiStatCard(
            label: kpi.label,
            value: _kpiValue(kpi.label),
            unit: _kpiUnit(kpi),
            subtitle: kpi.subtitle,
          ),
      ];

      if (isNarrow) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth < 560 ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: cards,
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMiddleRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 1000;
      final left = AcDistributionFlowCard(
        compressors: _liveCompressors,
        ac1DeviceId: _config.ac1DeviceId,
        ac2DeviceId: _config.ac2DeviceId,
        headerFlowDeviceId: _config.headerFlowDeviceId,
        headerPressureDeviceId: _config.headerPressureDeviceId,
      );
      final right = Column(
        children: [
          // AI Insight has no live backend at all — show the empty state
          // instead of the fabricated demo insights.
          const AcInsightFeedCard(insights: [], onViewAll: null),
          const SizedBox(height: 14),
          // Specific Energy / Role have no live backend yet — every row
          // renders "N/A"; only the configured benchmark band is shown for
          // context.
          AcCompressorEfficiencyCard(
            compressors: _liveCompressors,
            seBandLow: _config.seBandLow,
            seBandHigh: _config.seBandHigh,
          ),
          const SizedBox(height: 14),
          _buildSystemStatusCard(),
        ],
      );

      if (isNarrow) {
        return Column(children: [left, const SizedBox(height: 14), right]);
      }
      // No IntrinsicHeight/stretch here: it forces the (shorter) flow card
      // to match the (taller) right column's height, leaving a large empty
      // gap below the diagram instead of the card sizing to its own content.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: left),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: right),
        ],
      );
    });
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      // Neither Specific Energy nor Header Flow has a live backend yet —
      // null points means the charts render their "N/A" empty state.
      final energyTrend = AcSpecificEnergyTrendCard(
        points: null,
        selectedRange: _specificEnergyRange,
        onRangeChanged: (r) => setState(() => _specificEnergyRange = r),
        bandLow: _config.seBandLow,
        bandHigh: _config.seBandHigh,
      );
      final flowTrend = AcHeaderFlowTrendCard(
        points: null,
        selectedRange: _headerFlowRange,
        onRangeChanged: (r) => setState(() => _headerFlowRange = r),
        minFlowThreshold: _config.minFlowThreshold,
      );

      if (isNarrow) {
        return Column(children: [energyTrend, const SizedBox(height: 14), flowTrend]);
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: energyTrend),
            const SizedBox(width: 12),
            Expanded(child: flowTrend),
          ],
        ),
      );
    });
  }
}
