import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_models.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_service.dart';
import 'package:smartmachine365/utils/report_exporter_saver_io.dart'
    if (dart.library.html) 'package:smartmachine365/utils/report_exporter_saver_web.dart' as csv_saver;

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../tnb_e3_bill_simulator/widgets/tnb_footer.dart';
import 'models/tnb_bill_log_entry.dart';
import 'widgets/tbl_chart_panel.dart';
import 'widgets/tbl_cyberpunk_dropdown.dart';
import 'widgets/tbl_error_panel.dart';
import 'widgets/tbl_kpi_card.dart';
import 'widgets/tbl_legend_dot.dart';
import 'widgets/tbl_range_toggle.dart';
import 'widgets/tbl_snapshot_table.dart';

const double _kFallbackPeakRate = 0.355;
const double _kFallbackOffPeakRate = 0.219;
const Color _cCyan = Color(0xFF00E5FF);
const Color _cPeak = Color(0xFFFF6D00);
const Color _cOffPeak = Color(0xFF00BFA5);
const Color _cAmber = Color(0xFFFFC107);
const Color _cGreen = Color(0xFF34D399);
const Color _cRed = Color(0xFFF87171);

class TnbBillDataLoggerWidget extends StatefulWidget {
  const TnbBillDataLoggerWidget({super.key});

  @override
  State<TnbBillDataLoggerWidget> createState() => _TnbBillDataLoggerWidgetState();
}

class _TnbBillDataLoggerWidgetState extends State<TnbBillDataLoggerWidget> {
  String get _apiBase => AppConfig.dataApiBaseSafe;
  Map<String, String> get _apiHeaders => AppConfig.headers;

  bool _isLoading = true;
  bool _isExportingCsv = false;
  String? _errorMessage;

  // ── Meter selection (same TNB Meter Setting list the Bill Simulator uses) ──
  List<TnbMeter> _tnbMeters = [];
  Map<String, String> _plantIdToName = {};
  String? _selectedMeterId;
  String _dataSourceLabel = 'MSB';

  List<TnbMeter> get _activeMeters => _tnbMeters.where((m) => m.isActive).toList();

  TnbMeter? get _selectedMeter {
    for (final m in _tnbMeters) {
      if (m.id == _selectedMeterId) return m;
    }
    return null;
  }

  String _meterLabelFor(TnbMeter m) {
    final plant = _plantIdToName[m.plantId] ?? '';
    final label = m.meterLabel.isNotEmpty ? m.meterLabel : m.meterCode;
    if (plant.isNotEmpty && label.isNotEmpty) return '$plant — $label';
    return plant.isNotEmpty ? plant : label;
  }

  // ── Range + data ────────────────────────────────────────────────────────
  int _rangeDays = 30;
  List<TnbBillLogEntry> _entries = [];
  double _peakRate = _kFallbackPeakRate;
  double _offPeakRate = _kFallbackOffPeakRate;
  double _tier1Threshold = 0.98;
  double _tier2Trigger = 0.96;
  double _tier1Rate = 1.5;
  double _tier2Rate = 3.0;
  double _mdCapacityCharge = 0;
  double _mdNetworkCharge = 0;
  double _retailCharge = 0;
  double _currentAFA = 0;

  // ── MTD accrual inputs — sourced from the same
  // /energyComparison/tnb-bill-simulator/:device_id endpoint the Bill
  // Simulator's own "CURRENT MONTH ACCRUAL (MTD)" card reads (see
  // _fetchAndBuild), instead of derived from this page's own daily rows —
  // power_factor_avg in particular is a true monthly average, not simply
  // summable/averageable from per-day averages, so pulling it from the same
  // source is the only way this card is guaranteed to agree with the Bill
  // Simulator's, independent of the 14D/30D/90D display-range filter.
  double _monthlyPeakUsageKwh = 0;
  double _monthlyOffPeakUsageKwh = 0;
  double _monthlyMaxDemandKw = 0;
  double _monthlyPowerFactor = 0;

  // ── Solar (Solar Gen columns) — only fetched when the selected meter has
  // a solarDeviceId mapped (TNB Meter Setting → Solar mapping), same gate
  // TnbSummaryCards' Solar Savings card uses. _peakStart/_peakEnd are the
  // site's ToU window (energy-settings), needed to split generation into
  // peak/off-peak the same way the Bill Simulator's own solar card does. ──
  String _peakStart = '08:00';
  String _peakEnd = '22:00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFiltersAndFetch());
  }

  Future<void> _initFiltersAndFetch() async {
    await AppConfig.refresh();
    try {
      final results = await Future.wait([
        TnbMeterService.fetchMeters().catchError((_) => <TnbMeter>[]),
        TnbMeterService.fetchPlants().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      _tnbMeters = results[0] as List<TnbMeter>;
      final plantRows = results[1] as List<Map<String, dynamic>>;
      _plantIdToName = {
        for (final p in plantRows)
          if ((p['id']?.toString() ?? '').isNotEmpty) p['id'].toString(): (p['name']?.toString() ?? ''),
      };
      if (_activeMeters.isNotEmpty) {
        _selectedMeterId = _activeMeters.first.id;
      }
    } catch (_) {}
    _fetchAndBuild();
  }

  void _onMeterChanged(String? meterId) {
    setState(() => _selectedMeterId = meterId);
    _fetchAndBuild();
  }

  void _onRangeChanged(int days) {
    if (days == _rangeDays) return;
    setState(() => _rangeDays = days);
    _fetchAndBuild();
  }

  // ── Billing config (tier thresholds + cycle start day) — same nested
  // "config" shape / active-category fallback as the Bill Simulator. ────────
  static const List<String> _criticalBillingFields = [
    'targetThreshold',
    'tier1Rate',
    'tier2Trigger',
    'tier2Rate',
    'mdCapacityCharge',
    'mdNetworkCharge',
    'currentAFA',
  ];

  bool _isBillingConfigComplete(String body) {
    try {
      final root = jsonDecode(body) as Map<String, dynamic>;
      final cfg = root['config'] as Map<String, dynamic>? ?? {};
      return _criticalBillingFields.every((f) => (cfg[f]?.toString().trim().isNotEmpty ?? false));
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _fetchBillingConfig(String userUid, String meterCategoryId) async {
    final headers = _apiHeaders;
    if (meterCategoryId.isNotEmpty) {
      final linked = await http
          .get(Uri.parse('$_apiBase/masterBillingConfig/$userUid/$meterCategoryId'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (linked.statusCode == 200 && _isBillingConfigComplete(linked.body)) {
        return linked;
      }
    }
    return http.get(Uri.parse('$_apiBase/masterBillingConfig/$userUid/active'), headers: headers).timeout(const Duration(seconds: 15));
  }

  String _billingDeviceFor(TnbMeter? meter) {
    if (meter != null) {
      if (meter.influxDbTag.trim().isNotEmpty) return meter.influxDbTag.trim();
      if (meter.meterCode.trim().isNotEmpty) return meter.meterCode.trim();
    }
    return 'MSB';
  }

  double _p(dynamic val) {
    if (val == null) return 0.0;
    final s = val.toString().replaceAll(',', '.').trim();
    if (s.isEmpty) return 0.0;
    return double.tryParse(s) ?? 0.0;
  }

  // "MTD" here is a plain calendar month-to-date, matching what
  // Overall_monthly_energy_consumption (and therefore the Bill Simulator's
  // own accrual figure) actually groups by: SQL year/month columns. The
  // Master Billing Config's cycleEffectiveDate is NOT used to bound that
  // query anywhere in this app — TnbSummaryCards only reads it for the
  // "Days Left" display — so using it here instead would silently disagree
  // with the Bill Simulator's own MTD on any device whose billing cycle
  // doesn't start on the 1st.
  int _daysSinceMonthStart() => DateTime.now().day - 1;

  Future<void> _fetchAndBuild() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      try {
        final freshMeters = await TnbMeterService.fetchMeters();
        if (mounted) _tnbMeters = freshMeters;
      } catch (_) {}

      final meter = _selectedMeter;
      final billingDevice = _billingDeviceFor(meter);
      final meterCategoryId = meter?.tariffCategoryId.trim() ?? '';
      _dataSourceLabel = billingDevice;

      const billingOwnerId = AppConfig.sharedConfigOwnerId;

      final billingResponse = await _fetchBillingConfig(billingOwnerId, meterCategoryId);
      double tier1Threshold = 0.98;
      double tier2Trigger = 0.96;
      double tier1Rate = 1.5;
      double tier2Rate = 3.0;
      double mdCapacityCharge = 0;
      double mdNetworkCharge = 0;
      double retailCharge = 0;
      double currentAFA = 0;
      if (billingResponse.statusCode == 200) {
        final root = jsonDecode(billingResponse.body) as Map<String, dynamic>;
        final cfg = root['config'] as Map<String, dynamic>? ?? {};
        final parsedT1 = _p(cfg['targetThreshold']);
        final parsedT2 = _p(cfg['tier2Trigger']);
        if (parsedT1 > 0) tier1Threshold = parsedT1;
        if (parsedT2 > 0) tier2Trigger = parsedT2;
        final parsedT1Rate = _p(cfg['tier1Rate']);
        final parsedT2Rate = _p(cfg['tier2Rate']);
        if (parsedT1Rate > 0) tier1Rate = parsedT1Rate;
        if (parsedT2Rate > 0) tier2Rate = parsedT2Rate;
        mdCapacityCharge = _p(cfg['mdCapacityCharge']);
        mdNetworkCharge = _p(cfg['mdNetworkCharge']);
        retailCharge = _p(cfg['retailCharge']);
        currentAFA = _p(cfg['currentAFA']);
      }
      _tier1Threshold = tier1Threshold;
      _tier2Trigger = tier2Trigger;
      _tier1Rate = tier1Rate;
      _tier2Rate = tier2Rate;
      _mdCapacityCharge = mdCapacityCharge;
      _mdNetworkCharge = mdNetworkCharge;
      _retailCharge = retailCharge;
      _currentAFA = currentAFA;

      final tariffResponse = await http
          .get(Uri.parse('$_apiBase/masterBillingConfig/$billingOwnerId/electricityTariff'), headers: _apiHeaders)
          .timeout(const Duration(seconds: 15));
      double peakRate = _kFallbackPeakRate;
      double offPeakRate = _kFallbackOffPeakRate;
      if (tariffResponse.statusCode == 200) {
        final tariff = jsonDecode(tariffResponse.body) as Map<String, dynamic>;
        peakRate = _p(tariff['peakRate']) > 0 ? _p(tariff['peakRate']) : peakRate;
        offPeakRate = _p(tariff['offPeakRate']) > 0 ? _p(tariff['offPeakRate']) : offPeakRate;
      }
      _peakRate = peakRate;
      _offPeakRate = offPeakRate;

      // MTD accrual inputs — same endpoint + fields the Bill Simulator's own
      // "CURRENT MONTH ACCRUAL (MTD)" card reads (Overall_monthly_energy_
      // consumption for the current year/month), so _mtdCost below is
      // guaranteed to agree with that card instead of drifting from it.
      final monthlySimResponse = await http
          .get(Uri.parse('$_apiBase/energyComparison/tnb-bill-simulator/${Uri.encodeComponent(billingDevice)}'), headers: _apiHeaders)
          .timeout(const Duration(seconds: 15));
      if (monthlySimResponse.statusCode == 200) {
        final sim = jsonDecode(monthlySimResponse.body) as Map<String, dynamic>;
        _monthlyPeakUsageKwh = _p(sim['peak_usage_kWh']);
        _monthlyOffPeakUsageKwh = _p(sim['off_peak_usage_kWh']);
        _monthlyMaxDemandKw = _p(sim['max_demand_kW']);
        _monthlyPowerFactor = _p(sim['power_factor']);
      }

      // Site's ToU peak window (same source the Bill Simulator's own Solar
      // Savings card uses) — needed to split solar generation into peak vs
      // off-peak below. Falls back to the app-wide 08:00/22:00 default.
      final userId = AppStateNotifier.instance.uid ?? '';
      final energySettingsResponse = await http
          .get(Uri.parse('$_apiBase/energy-settings/$userId'), headers: _apiHeaders)
          .timeout(const Duration(seconds: 15));
      if (energySettingsResponse.statusCode == 200) {
        final energyData = jsonDecode(energySettingsResponse.body) as Map<String, dynamic>;
        final settings = energyData['settings'] as Map<String, dynamic>? ?? {};
        final cc = settings['contractCapacity'] as Map<String, dynamic>? ?? {};
        final tou = cc['peakHourToU'] as Map<String, dynamic>? ?? {};
        _peakStart = tou['startTime']?.toString() ?? '08:00';
        _peakEnd = tou['endTime']?.toString() ?? '22:00';
      }

      // Always fetch enough days to cover the current calendar month (so the
      // MTD KPI is correct) even when the display range (14D) is shorter.
      final daysToFetch = math.min(180, math.max(_rangeDays, _daysSinceMonthStart() + 2));
      final logResponse = await http
          .get(
            Uri.parse('$_apiBase/energyComparison/daily-bill-log/${Uri.encodeComponent(billingDevice)}?days=$daysToFetch'),
            headers: _apiHeaders,
          )
          .timeout(const Duration(seconds: 20));

      List<TnbBillLogEntry> entries = [];
      if (logResponse.statusCode == 200) {
        final decoded = jsonDecode(logResponse.body);
        if (decoded is List) {
          entries = decoded.map((e) => TnbBillLogEntry.fromJson(e as Map<String, dynamic>)).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        }
      }

      // Solar Gen columns — only when the meter has a solarDeviceId mapped
      // (TNB Meter Setting → Solar mapping); merged in by date rather than
      // fetched inline above since it's a different device_id/table than the
      // grid-import figures. Best-effort: a failure here just leaves the
      // Solar Gen columns blank, same as an unmapped meter.
      final solarDeviceId = meter?.solarDeviceId.trim() ?? '';
      if (solarDeviceId.isNotEmpty && entries.isNotEmpty) {
        try {
          final solarResponse = await http
              .get(
                Uri.parse(
                  '$_apiBase/energyDetails/solar-daily/${Uri.encodeComponent(solarDeviceId)}'
                  '?peakStart=$_peakStart&peakEnd=$_peakEnd&days=$daysToFetch',
                ),
                headers: _apiHeaders,
              )
              .timeout(const Duration(seconds: 20));
          if (solarResponse.statusCode == 200) {
            final solarDecoded = jsonDecode(solarResponse.body);
            if (solarDecoded is List) {
              final byDate = <String, Map<String, dynamic>>{
                for (final row in solarDecoded)
                  if (row is Map) (row['date']?.toString() ?? ''): row.cast<String, dynamic>(),
              };
              entries = entries.map((e) {
                final dateKey = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
                final row = byDate[dateKey];
                if (row == null) return e;
                return e.withSolar(peakKwh: _p(row['peak_kwh']), offPeakKwh: _p(row['off_peak_kwh']));
              }).toList();
            }
          }
        } catch (_) {}
      }

      // Running MTD (RM) column — computed over the FULL fetched entries
      // (which always cover the whole calendar month, see daysToFetch above)
      // rather than just the display slice, so a 14D/90D view still shows
      // the true month-to-date figure instead of restarting the running
      // total from whatever day the display window happens to begin on.
      double runningMtd = 0;
      int? mtdMonth;
      entries = entries.map((e) {
        if (mtdMonth != e.date.month) {
          runningMtd = 0;
          mtdMonth = e.date.month;
        }
        runningMtd += e.dayCost(peakRate, offPeakRate);
        return e.withMtdCost(runningMtd);
      }).toList();

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  // ── Derived views ──────────────────────────────────────────────────────
  List<TnbBillLogEntry> get _displayEntries {
    if (_entries.length <= _rangeDays) return _entries;
    return _entries.sublist(_entries.length - _rangeDays);
  }

  /// e.g. _pfSteps(0.98, 0.96) → 2 — matches TnbE3BillSimulatorWidget._steps.
  int _pfSteps(double upper, double lower) {
    if (upper <= lower) return 0;
    return ((upper - lower) * 100).round();
  }

  // Full current-month accrual — same formula as TnbE3BillSimulatorWidget's
  // _buildFromConfig (peak + off-peak usage cost, MD capacity/network
  // charge, retail charge, AFA, PF penalty), computed from the identical
  // monthly inputs that card reads (_monthlyPeakUsageKwh etc., fetched in
  // _fetchAndBuild) rather than from this page's own day-by-day rows, so
  // this card always agrees with the Bill Simulator's "CURRENT MONTH
  // ACCRUAL (MTD)" — independent of the 14D/30D/90D display-range filter.
  double get _mtdCost {
    final peakAmount = _monthlyPeakUsageKwh * _peakRate;
    final offPeakAmount = _monthlyOffPeakUsageKwh * _offPeakRate;
    final totalKwh = _monthlyPeakUsageKwh + _monthlyOffPeakUsageKwh;
    final mdCapacityAmount = _monthlyMaxDemandKw * _mdCapacityCharge;
    final networkChargeAmount = _monthlyMaxDemandKw * _mdNetworkCharge;
    final afaAmount = totalKwh * _currentAFA;

    final pfValue = _monthlyPowerFactor.clamp(0.0, 1.0);
    double pfPenaltyAmount = 0;
    if (pfValue < _tier1Threshold) {
      final tier1Lower = math.max(pfValue, _tier2Trigger);
      final tier1Penalty = _pfSteps(_tier1Threshold, tier1Lower) * _tier1Rate;

      double tier2Penalty = 0;
      if (pfValue < _tier2Trigger) {
        tier2Penalty = _pfSteps(_tier2Trigger, pfValue) * _tier2Rate;
      }

      final pfPenaltyPercent = tier1Penalty + tier2Penalty;
      final billingBeforePf = peakAmount + offPeakAmount + mdCapacityAmount + networkChargeAmount + _retailCharge + afaAmount;
      pfPenaltyAmount = billingBeforePf * (pfPenaltyPercent / 100);
    }

    return peakAmount + offPeakAmount + mdCapacityAmount + networkChargeAmount + _retailCharge + pfPenaltyAmount + afaAmount;
  }

  double get _avgDailyCost {
    final d = _displayEntries;
    if (d.isEmpty) return 0;
    return d.fold(0.0, (s, e) => s + e.dayCost(_peakRate, _offPeakRate)) / d.length;
  }

  double get _dayOverDayPct {
    final d = _displayEntries;
    if (d.length < 2) return 0;
    final last = d.last.dayCost(_peakRate, _offPeakRate);
    final prev = d[d.length - 2].dayCost(_peakRate, _offPeakRate);
    if (prev <= 0) return 0;
    return (last - prev) / prev * 100;
  }

  double? get _worstPf {
    final valid = _displayEntries.where((e) => e.powerFactor > 0).toList();
    if (valid.isEmpty) return null;
    return valid.map((e) => e.powerFactor).reduce((a, b) => a < b ? a : b);
  }

  String get _worstPfStatus {
    final pf = _worstPf;
    if (pf == null) return 'No PF readings';
    if (pf < _tier2Trigger) return 'Below Tier 2 (${_tier2Trigger.toStringAsFixed(2)})';
    if (pf < _tier1Threshold) return 'Below Tier 1 (${_tier1Threshold.toStringAsFixed(2)})';
    return 'Above Tier 1 threshold';
  }

  Color _worstPfColor(FlutterFlowTheme theme) {
    final pf = _worstPf;
    if (pf == null) return theme.secondaryText;
    if (pf >= _tier1Threshold) return _cGreen;
    if (pf >= _tier2Trigger) return _cAmber;
    return _cRed;
  }

  double get _peakMdPeriod => _displayEntries.fold(0.0, (s, e) => math.max(s, e.maxDemandKw));

  // ── CSV export ─────────────────────────────────────────────────────────
  Future<void> _exportCsv() async {
    if (_isExportingCsv) return;
    setState(() => _isExportingCsv = true);
    try {
      String cell(String v) => '"${v.replaceAll('"', '""')}"';
      final headers = [
        'Date',
        'Peak_kWh',
        'Peak_Cost_RM',
        'OffPeak_kWh',
        'OffPeak_Cost_RM',
        'Day_Cost_RM',
        'Max_Demand_kW',
        'PF_avg',
        'Meter',
        'Device_ID',
      ];
      final meterLabel = _selectedMeter != null ? _meterLabelFor(_selectedMeter!) : _dataSourceLabel;
      final lines = <String>[
        headers.map(cell).join(','),
        ..._displayEntries.map((e) => [
              '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
              e.peakKwh.toStringAsFixed(1),
              e.peakCost(_peakRate).toStringAsFixed(2),
              e.offPeakKwh.toStringAsFixed(1),
              e.offPeakCost(_offPeakRate).toStringAsFixed(2),
              e.dayCost(_peakRate, _offPeakRate).toStringAsFixed(2),
              e.maxDemandKw.toStringAsFixed(1),
              e.powerFactor > 0 ? e.powerFactor.toStringAsFixed(3) : '',
              meterLabel,
              _dataSourceLabel,
            ].map(cell).join(',')),
      ];
      final bytes = utf8.encode('﻿${lines.join('\r\n')}');
      final now = DateTime.now();
      final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      await csv_saver.saveExcelBytes(bytes: bytes, fileName: 'TnbBillDataLogger_${_dataSourceLabel}_${_rangeDays}d_$ts.csv');
      if (!mounted) return;
      final theme = FlutterFlowTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exported ${_displayEntries.length} rows to CSV'),
        backgroundColor: theme.success,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      final theme = FlutterFlowTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: theme.error,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Align(
                  alignment: const AlignmentDirectional(0, -1),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      image: DecorationImage(fit: BoxFit.cover, image: Image.asset('assets/images/backgroundanimated.gif').image),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.008,
                        vertical: MediaQuery.of(context).size.height * 0.022,
                      ),
                      child: _isLoading && _entries.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: _cCyan, strokeWidth: 2))
                          : _errorMessage != null
                              ? TblErrorPanel(message: _errorMessage!, onRetry: _fetchAndBuild)
                              : _buildPage(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sw = MediaQuery.of(context).size.width;
    final gap = sw * 0.008;
    final meter = _selectedMeter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildHeader(theme),
        SizedBox(height: gap * 0.5),
        _buildFilterBar(context, theme),
        _buildKpiRow(theme, gap),
        SizedBox(height: gap),
        _buildChartPanel(theme, isLight),
        SizedBox(height: gap),
        // ── Snapshot table ──
        Expanded(
          child: TblSnapshotTable(
            entries: _displayEntries,
            peakRate: _peakRate,
            offPeakRate: _offPeakRate,
            peakStart: _peakStart,
            peakEnd: _peakEnd,
          ),
        ),
        SizedBox(height: gap),
        TnbFooter(dataSource: meter != null ? '$_dataSourceLabel (TNB Meter DPM ID)' : _dataSourceLabel),
        SizedBox(height: gap * 0.5),
      ],
    );
  }

  // ── Breadcrumb + title ─────────────────────────────────────────────────
  List<Widget> _buildHeader(FlutterFlowTheme theme) {
    return [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
        child: Text('Dashboard/Bill Simulator/Data Logger',
            style: theme.titleLarge.override(fontFamily: 'Poppins', color: theme.primaryText, fontSize: 12, letterSpacing: 0.0, font: GoogleFonts.poppins())),
      ),
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
        child: Text('Bill Simulator Data Logger',
            style: theme.headlineMedium.override(fontFamily: 'Poppins', letterSpacing: 0.0, font: GoogleFonts.poppins())),
      ),
    ];
  }

  // ── Filter / action bar ──
  // Spacer/Expanded requires a Flex (Row) ancestor, not Wrap — so the left
  // group (meter + range, which needs to wrap on narrow screens) and the
  // right group (rate label + CSV + refresh, kept compact) are two separate
  // widgets inside one Row rather than one flat Wrap.
  Widget _buildFilterBar(BuildContext context, FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_activeMeters.isNotEmpty)
                  TblCyberpunkDropdown(
                    value: _selectedMeterId,
                    options: _activeMeters.map((m) => m.id).toList(),
                    hint: 'TNB Meter',
                    width: 260,
                    labelBuilder: (id) {
                      final m = _activeMeters.where((m) => m.id == id).firstOrNull;
                      return m != null ? _meterLabelFor(m) : id;
                    },
                    onChanged: _onMeterChanged,
                  ),
                TblRangeToggle(selectedDays: _rangeDays, onChanged: _onRangeChanged),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Peak RM ${_peakRate.toStringAsFixed(3)}  ·  Off-Peak RM ${_offPeakRate.toStringAsFixed(3)}',
            style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 11.5),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isExportingCsv ? null : _exportCsv,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _cCyan.withOpacity(0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: _cCyan.withOpacity(0.5))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _isExportingCsv
                    ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: _cCyan))
                    : const Icon(Icons.download_outlined, color: _cCyan, size: 15),
                const SizedBox(width: 6),
                Text('Export CSV', style: GoogleFonts.poppins(color: _cCyan, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _fetchAndBuild,
            child: Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.primary.withOpacity(0.4))),
              child: _isLoading
                  ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary))
                  : Icon(Icons.refresh_rounded, color: theme.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI row ────────────────────────────────────────────────────────────
  Widget _buildKpiRow(FlutterFlowTheme theme, double gap) {
    return Row(
      children: [
        Expanded(
          child: TblKpiCard(
            label: 'MTD GRID IMPORT COST',
            value: 'RM ${_fmt(_mtdCost)}',
            sub: 'Matches Bill Simulator accrual (MTD)',
            accent: _cGreen,
          ),
        ),
        SizedBox(width: gap * 0.6),
        Expanded(
          child: TblKpiCard(
            label: 'AVG DAILY COST',
            value: 'RM ${_fmt(_avgDailyCost, decimals: 0)}',
            sub: '${_dayOverDayPct >= 0 ? '▲' : '▼'} ${_dayOverDayPct.abs().toStringAsFixed(1)}% latest day',
            subColor: _dayOverDayPct >= 0 ? _cRed : _cGreen,
            accent: _cCyan,
          ),
        ),
        SizedBox(width: gap * 0.6),
        Expanded(
          child: TblKpiCard(
            label: 'WORST PF (PERIOD)',
            value: _worstPf != null ? _worstPf!.toStringAsFixed(3) : '–',
            sub: _worstPfStatus,
            accent: _worstPfColor(theme),
            valueColor: _worstPf == null ? null : _worstPfColor(theme),
          ),
        ),
        SizedBox(width: gap * 0.6),
        Expanded(
          child: TblKpiCard(
            label: 'PEAK MD (PERIOD)',
            value: '${_fmt(_peakMdPeriod, decimals: 0)} kW',
            sub: '${_displayEntries.length} day(s) · $_dataSourceLabel',
            accent: _cAmber,
          ),
        ),
      ],
    );
  }

  // ── Chart panel ────────────────────────────────────────────────────────
  Widget _buildChartPanel(FlutterFlowTheme theme, bool isLight) {
    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [theme.secondaryBackground.withOpacity(0.97), theme.primaryBackground.withOpacity(0.97)]
              : [const Color(0xFF0E2040).withOpacity(0.92), const Color(0xFF07101F).withOpacity(0.96)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cCyan.withOpacity(0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: _cCyan, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('Daily Grid Import Cost · Power Factor Trend',
                  style: GoogleFonts.poppins(color: isLight ? theme.txtPrimary : Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              const TblLegendDot(color: _cOffPeak, label: 'Off-Peak cost'),
              const SizedBox(width: 12),
              const TblLegendDot(color: _cPeak, label: 'Peak cost'),
              const SizedBox(width: 12),
              const TblLegendDot(color: _cAmber, label: 'Power factor'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TblChartPanel(
              entries: _displayEntries,
              peakRate: _peakRate,
              offPeakRate: _offPeakRate,
              tier1Threshold: _tier1Threshold,
            ),
          ),
        ],
      ),
    );
  }

  static final _fmtRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  String _fmt(double num, {int decimals = 2}) {
    return num.toStringAsFixed(decimals).replaceAllMapped(_fmtRegex, (m) => '${m[1]},');
  }
}
