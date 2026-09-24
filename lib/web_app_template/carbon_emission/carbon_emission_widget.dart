import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'carbon_emission_model.dart';
import 'carbon_dashboard_config.dart';
import 'carbon_emission_data_service.dart';
import 'widgets/carbon_kpi_stat_card.dart';
import 'widgets/carbon_flow_diagram.dart';
import 'widgets/emission_breakdown_card.dart';
import 'widgets/top_contributors_card.dart';
import 'widgets/emission_trend_card.dart';
import 'widgets/intensity_by_line_card.dart';
export 'carbon_emission_model.dart';

class CarbonEmissionWidget extends StatefulWidget {
  const CarbonEmissionWidget({super.key});

  @override
  State<CarbonEmissionWidget> createState() => _CarbonEmissionWidgetState();
}

class _CarbonEmissionWidgetState extends State<CarbonEmissionWidget> {
  late CarbonEmissionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // 'daily' (today) or 'monthly' (month to date) — drives every card.
  String _period = 'monthly';

  // null = "All Plants" (the site-wide default config, [kUnassignedPlantKey]).
  // Non-null once the user has picked a specific plant from the dropdown —
  // this is the only filter on the dashboard; it both selects which plant's
  // CarbonDashboardConfig is loaded and narrows Top Contributors / Intensity
  // by Production Line to that plant.
  String? _plantFilter;
  List<String> _plantOptions = [];
  static const _lastPlantPrefsKey = 'carbon_dashboard_last_plant';

  late DateTime _liveTime;
  Timer? _clockTimer;

  CarbonDashboardConfig _config = CarbonDashboardConfig.empty();
  CarbonEmissionLiveData _live = CarbonEmissionLiveData.empty;
  bool _liveLoading = false;
  // Bumped on every _loadLiveData() call so an older, slower-resolving call
  // (e.g. one kicked off for the cached config) can't overwrite the UI after
  // a newer call (e.g. for the just-fetched remote config) has already
  // finished — only the most recently started call is allowed to apply.
  int _liveRequestId = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CarbonEmissionModel());
    _liveTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _liveTime = DateTime.now());
    });
    _loadPlantOptions();
  }

  /// Loads the plant list, then restores the last-viewed plant from this
  /// browser (or defaults to "All Plants" — null) and loads that plant's
  /// config. `null`/[kUnassignedPlantKey] both mean the site-wide default
  /// config, so the dashboard always has something to load.
  Future<void> _loadPlantOptions() async {
    final plants = await CarbonEmissionDataService.fetchPlantOptions();
    if (!mounted) return;
    setState(() => _plantOptions = plants);

    final prefs = await SharedPreferences.getInstance();
    final lastPlant = prefs.getString(_lastPlantPrefsKey);
    final initialPlant = (lastPlant != null && lastPlant != kUnassignedPlantKey && plants.contains(lastPlant))
        ? lastPlant
        : null;
    if (!mounted) return;
    setState(() => _plantFilter = initialPlant);
    unawaited(_loadConfigForPlant(initialPlant ?? kUnassignedPlantKey));
  }

  Future<void> _persistLastPlant(String? plant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlantPrefsKey, plant ?? kUnassignedPlantKey);
  }

  void _onPlantChanged(String? plant) {
    if (plant == _plantFilter) return;
    setState(() => _plantFilter = plant);
    unawaited(_persistLastPlant(plant));
    unawaited(_loadConfigForPlant(plant ?? kUnassignedPlantKey));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _loadConfigForPlant(String plant) async {
    // Show the local cache immediately, then reconcile with the backend
    // (client-scoped via x-client-id) once it responds.
    final cached = await CarbonDashboardConfigStore.load(plant);
    if (mounted) setState(() => _config = cached);
    unawaited(_loadLiveData());

    final uid = AppStateNotifier.instance.uid ?? '';
    final remote = await CarbonDashboardConfigService.fetch(uid, plant);
    if (remote != null) {
      if (mounted) setState(() => _config = remote);
      await CarbonDashboardConfigStore.save(plant, remote);
      unawaited(_loadLiveData());
    }
  }

  void _setPeriod(String period) {
    if (_period == period) return;
    setState(() => _period = period);
    unawaited(_loadLiveData());
  }

  Future<void> _loadLiveData() async {
    final requestId = ++_liveRequestId;
    if (!_config.isConfigured) {
      if (mounted && requestId == _liveRequestId) setState(() => _live = CarbonEmissionLiveData.empty);
      return;
    }
    if (mounted) setState(() => _liveLoading = true);
    CarbonEmissionLiveData resolved;
    try {
      resolved = await CarbonEmissionDataService.resolve(_config, period: _period, plantFilter: _plantFilter);
    } catch (_) {
      resolved = CarbonEmissionLiveData.empty;
    }
    if (!mounted) return;
    // A newer call already started (and may have finished) while this one
    // was resolving — its result is stale, so don't let it clobber the UI.
    if (requestId != _liveRequestId) return;
    setState(() {
      _live = resolved;
      _liveLoading = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

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
                        _buildHeader(t, isLight),
                        const SizedBox(height: 16),
                        _buildControlsRow(t, isLight),
                        const SizedBox(height: 16),
                        _buildKpiCards(t, isLight),
                        const SizedBox(height: 14),
                        _buildMiddleRow(t, isLight),
                        const SizedBox(height: 14),
                        _buildBottomRow(t, isLight),
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

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(FlutterFlowTheme t, bool isLight) {
    // Title/subtitle always sit on their own line, with the period toggle,
    // live chip and icon buttons always on a row underneath — the period
    // toggle + live chip + 2 icon buttons alone demand ~360px, which left
    // the title squeezed to nothing (or the row overflowing outright) on a
    // phone-width screen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'Carbon Intelligence Dashboard  ',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isLight ? t.txtPrimary : Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const TextSpan(text: '🌿', style: TextStyle(fontSize: 18)),
          ]),
        ),
        const SizedBox(height: 2),
        Text(
          'Real-time carbon monitoring and optimization for operational excellence',
          style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // Daily / Monthly period toggle
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF0D1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RangeChip(
                    label: 'Daily',
                    selected: _period == 'daily',
                    onTap: () => _setPeriod('daily'),
                    t: t,
                    isLight: isLight,
                  ),
                  _RangeChip(
                    label: 'Monthly',
                    selected: _period == 'monthly',
                    onTap: () => _setPeriod('monthly'),
                    t: t,
                    isLight: isLight,
                  ),
                ],
              ),
            ),
            // Live status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLight ? t.success.withOpacity(0.08) : t.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: t.success.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: t.success, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(
                    'Live',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: t.success),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('HH:mm:ss').format(_liveTime),
                    style: GoogleFonts.poppins(fontSize: 9, color: t.success.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _iconButton(Icons.notifications_none_rounded, t, isLight),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(color: Color(0xFFE74852), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('12', style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            _iconButton(Icons.help_outline_rounded, t, isLight),
          ],
        ),
      ],
    );
  }

  static String _fmtThousands(double v) {
    final intPart = v.round().toString();
    return intPart.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  Widget _iconButton(IconData icon, FlutterFlowTheme t, bool isLight) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: Icon(icon, size: 17, color: t.txtMuted),
    );
  }

  // ── Controls row: range tabs + date range + Configure Dashboard ────────────

  // Start of the given month's calendar day 1.
  static DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
  // Last calendar day of the given month (day 0 of next month).
  static DateTime _monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);
  static String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  Widget _buildControlsRow(FlutterFlowTheme t, bool isLight) {
    // Follows the current wall-clock time and the Daily/Monthly toggle:
    // today vs yesterday, or current calendar month to date vs last month.
    final now = DateTime.now();
    final daily = _period == 'daily';
    final currentStart = daily ? DateTime(now.year, now.month, now.day) : _monthStart(now);
    final previousMonthAnchor = DateTime(now.year, now.month - 1, 1);
    final previousStart = daily ? now.subtract(const Duration(days: 1)) : _monthStart(previousMonthAnchor);
    final previousEnd = daily ? previousStart : _monthEnd(previousMonthAnchor);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF0D1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: t.txtMuted),
              const SizedBox(width: 7),
              Text(
                '${_fmtDate(currentStart)} - ${_fmtDate(now)}',
                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
              ),
              const SizedBox(width: 5),
              Text(
                'vs ${_fmtDate(previousStart)} - ${_fmtDate(previousEnd)}',
                style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted),
              ),
            ],
          ),
        ),
        if (_plantOptions.isNotEmpty)
          _filterDropdown(
            t: t, isLight: isLight, icon: Icons.factory_outlined,
            label: 'Plant', options: _plantOptions, value: _plantFilter, onChanged: _onPlantChanged,
          ),
        if (_liveLoading)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(strokeWidth: 1.6, color: t.txtMuted),
              ),
              const SizedBox(width: 6),
              Text(
                'Syncing configured devices…',
                style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted),
              ),
            ],
          ),
      ],
    );
  }

  /// One filter-bar dropdown — mirrors Energy Details' filter row (bordered
  /// container, left accent bar, plain `DropdownButton`, null = "All").
  Widget _filterDropdown({
    required FlutterFlowTheme t,
    required bool isLight,
    required IconData icon,
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final active = value != null;
    final cardBg = isLight ? Colors.white : const Color(0xFF0D1A2E);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);
    return Container(
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? t.primary.withOpacity(0.08) : cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? t.primary.withOpacity(0.4) : borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: active ? t.primary : t.txtMuted),
          const SizedBox(width: 6),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value != null && options.contains(value) ? value : null,
                isDense: true,
                isExpanded: true,
                hint: Text(label, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtMuted)),
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: t.txtMuted),
                dropdownColor: cardBg,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isLight ? t.txtPrimary : Colors.white,
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text('$label: All', overflow: TextOverflow.ellipsis)),
                  for (final opt in options) DropdownMenuItem<String>(value: opt, child: Text(opt, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Cards ────────────────────────────────────────────────────────────────

  static String _deltaText(double? pct, String suffix) {
    if (pct == null) return 'No trend data yet';
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% $suffix';
  }

  static bool _deltaUp(double? pct) => (pct ?? 0) >= 0;

  Widget _buildKpiCards(FlutterFlowTheme t, bool isLight) {
    final carbonPrice = _config.carbonPricePerTco2e;
    final netEmission = _live.netEmissionTco2e;
    final emissionCost = (netEmission != null && carbonPrice != null) ? netEmission * carbonPrice : null;
    final costPriceLabel = carbonPrice != null ? carbonPrice.toStringAsFixed(0) : '—';
    final solarKwh = _live.solarKwh;
    final totalKwh = _live.totalConsumptionKwh;
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final cards = [
        CarbonKpiStatCard(
          label: 'NET CARBON EMISSION',
          value: netEmission != null ? netEmission.toStringAsFixed(1) : '—',
          unit: 'tCO₂e',
          trendText: _deltaText(_live.netEmissionDeltaPercent, 'vs last month'),
          trendUp: _deltaUp(_live.netEmissionDeltaPercent),
          trendGoodWhenUp: false,
          secondaryLine: _live.emissionFactorKgPerKwh > 0
              ? 'Emission Factor: ${_live.emissionFactorKgPerKwh.toStringAsFixed(3)} kgCO₂e/kWh'
              : (_config.netEmissionDeviceId == null ? 'Set Device ID in Carbon Dashboard Config' : 'Awaiting live reading'),
          accentColor: t.success,
          sparkline: _live.netEmissionSpark,
          tooltip: _config.netEmissionDeviceId != null
              ? 'Device ID: ${_config.netEmissionDeviceId} × Emission Factor · tCO₂e (month to date)'
              : 'Configure a Device ID in Carbon Dashboard Config to see live emission',
        ),
        CarbonKpiStatCard(
          label: 'CARBON INTENSITY',
          value: _live.carbonIntensityKgPerTon != null ? _live.carbonIntensityKgPerTon!.toStringAsFixed(1) : '—',
          unit: 'kgCO₂e / ton',
          trendText: _deltaText(_live.carbonIntensityDeltaPercent, 'vs yesterday'),
          trendUp: _deltaUp(_live.carbonIntensityDeltaPercent),
          trendGoodWhenUp: false,
          secondaryLine: _live.siteTonnesProduced > 0
              ? 'Production Output: ${_live.siteTonnesProduced.toStringAsFixed(1)} tons (MTD)'
              : (_config.carbonIntensityDeviceId == null ? 'Set Device ID in Carbon Dashboard Config' : 'No production output logged yet'),
          accentColor: const Color(0xFF3B82F6),
          sparkline: _live.carbonIntensitySpark,
          tooltip: _config.carbonIntensityDeviceId != null
              ? 'Device ID: ${_config.carbonIntensityDeviceId} ÷ Production Output · kgCO₂e/ton (month to date)'
              : null,
        ),
        CarbonKpiStatCard(
          label: 'TOTAL ENERGY CONSUMPTION',
          value: totalKwh != null ? _fmtThousands(totalKwh / 1000) : '—',
          unit: 'kWh',
          trendText: _deltaText(_live.totalConsumptionDeltaPercent, 'vs yesterday'),
          trendUp: _deltaUp(_live.totalConsumptionDeltaPercent),
          trendGoodWhenUp: false,
          secondaryLine: totalKwh != null && solarKwh != null
              ? 'Grid: ${_fmtThousands((totalKwh - solarKwh) / 1000)} · Solar: ${_fmtThousands(solarKwh / 1000)} MWh'
              : (_config.totalConsumptionDeviceId == null ? 'Set Device ID in Carbon Dashboard Config' : 'Awaiting live reading'),
          accentColor: const Color(0xFFF59E0B),
          sparkline: _live.totalConsumptionSpark,
          badgeIcon: Icons.bolt_rounded,
          tooltip: _config.totalConsumptionDeviceId != null ? 'Device ID: ${_config.totalConsumptionDeviceId} · kWh (month to date)' : null,
        ),
        CarbonKpiStatCard(
          label: 'SOLAR AVOIDED EMISSION',
          value: _live.solarAvoidedTco2e != null ? _live.solarAvoidedTco2e!.toStringAsFixed(1) : '—',
          unit: 'tCO₂e',
          trendText: _deltaText(_live.solarDeltaPercent, 'vs yesterday'),
          trendUp: _deltaUp(_live.solarDeltaPercent),
          trendGoodWhenUp: true,
          secondaryLine: solarKwh != null
              ? '${_fmtThousands(solarKwh)} kWh generated'
              : (_config.solarDeviceId == null ? 'Set Device ID in Carbon Dashboard Config' : 'Awaiting live reading'),
          accentColor: const Color(0xFF8B5CF6),
          sparkline: _live.solarSpark,
          badgeIcon: Icons.wb_sunny_rounded,
          tooltip: _config.solarDeviceId != null ? 'Device ID: ${_config.solarDeviceId} × Emission Factor · tCO₂e (month to date)' : null,
        ),
        CarbonKpiStatCard(
          label: 'EMISSION COST',
          value: emissionCost != null ? 'RM ${_fmtThousands(emissionCost)}' : '—',
          unit: '',
          trendText: _deltaText(_live.netEmissionDeltaPercent, 'vs last month'),
          trendUp: _deltaUp(_live.netEmissionDeltaPercent),
          trendGoodWhenUp: false,
          secondaryLine: carbonPrice != null ? '@ RM $costPriceLabel / tCO₂e' : 'Set Carbon Price in Carbon Dashboard Config',
          accentColor: const Color(0xFF2563EB),
          sparkline: _live.netEmissionSpark,
          badgeIcon: Icons.savings_rounded,
          tooltip: emissionCost != null ? 'Net Carbon Emission × Carbon Price (Carbon Dashboard Config) · RM (month to date)' : null,
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

  // ── Middle row: Carbon Flow / Emission Breakdown / Top 5 Contributors ─────

  String get _periodLabel => _period == 'daily'
      ? DateFormat('dd MMM yyyy').format(DateTime.now())
      : DateFormat('MMMM yyyy').format(DateTime.now());

  Widget _buildMiddleRow(FlutterFlowTheme t, bool isLight) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 1000;
      final periodLabel = _periodLabel;
      final blocks = _live.blocks.isNotEmpty
          ? _live.blocks
          : [for (final b in kCarbonFlowBlocks) CarbonFlowBlock(label: b.label, percent: 0, tco2e: 0, color: b.color)];
      final netEmission = _live.netEmissionTco2e ?? 0;
      final flow = CarbonFlowDiagram(
        periodLabel: periodLabel,
        gridImportMwh: _live.gridImportMwh ?? 0,
        blocks: blocks,
        netEmissionTco2e: netEmission,
        solarOffsetTco2e: _live.solarAvoidedTco2e ?? 0,
        solarOffsetKwh: _live.solarKwh ?? 0,
      );
      final breakdownSources = [
        EmissionSource(
          label: 'Production Lines',
          sublabel: '(configured contributors)',
          percent: netEmission > 0 ? (_live.breakdownProductionLinesTco2e / netEmission * 100).clamp(0.0, 100.0) : 0.0,
          tco2e: _live.breakdownProductionLinesTco2e,
          color: const Color(0xFF22C55B),
        ),
        EmissionSource(
          label: 'Utilities & Others',
          sublabel: '(remainder of net emission)',
          percent: netEmission > 0 ? (_live.breakdownUtilitiesTco2e / netEmission * 100).clamp(0.0, 100.0) : 0.0,
          tco2e: _live.breakdownUtilitiesTco2e,
          color: const Color(0xFF3B82F6),
        ),
      ];
      final breakdown = EmissionBreakdownCard(
        periodLabel: periodLabel,
        sources: breakdownSources,
        totalTco2e: netEmission,
        onViewDetails: () {},
      );
      final contributors = TopContributorsCard(
        periodLabel: periodLabel,
        contributors: _live.contributors,
        onViewAll: () {},
      );

      if (isNarrow) {
        return Column(
          children: [
            flow,
            const SizedBox(height: 14),
            breakdown,
            const SizedBox(height: 14),
            contributors,
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: flow),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: breakdown),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: contributors),
          ],
        ),
      );
    });
  }

  // ── Bottom row: Emission Trend / Intensity by Production Line ─────────────

  Widget _buildBottomRow(FlutterFlowTheme t, bool isLight) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final periodLabel = _periodLabel;
      final trend =
          EmissionTrendCard(points: _live.trendPoints.isNotEmpty ? _live.trendPoints : kEmissionTrend, deviceId: _config.netEmissionDeviceId);
      final intensity = IntensityByLineCard(
        periodLabel: periodLabel,
        rows: [
          for (final r in _live.productionLineRows)
            ProductionLineIntensity(
              line: r.line,
              productionTon: r.productionTon,
              intensity: r.intensityKgPerTon,
              vsTargetPercent: r.vsTargetPercent,
            ),
        ],
      );

      if (isNarrow) {
        return Column(
          children: [
            trend,
            const SizedBox(height: 14),
            intensity,
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: trend),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: intensity),
          ],
        ),
      );
    });
  }
}

// ── Range chip ───────────────────────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.t,
    required this.isLight,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.success : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : t.txtMuted,
          ),
        ),
      ),
    );
  }
}
