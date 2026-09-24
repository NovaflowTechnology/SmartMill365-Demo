// tnb_e3_bill_simulator_widget.dart
//
// ROOT CAUSE FIX:
//  API response /masterBillingConfig/:uid/active returns a NESTED structure:
//  {
//    "userId": "...",
//    "appliedCategory": "...",
//    "appliedCategoryName": "...",
//    "config": {                        â† semua field ada DI DALAM "config"
//      "targetThreshold": "0.98",
//      "tier1Rate": "1.5",
//      "tier2Trigger": "0.9",
//      "tier2Rate": "3",
//      "mdCapacityCharge": "0.50",
//      ...
//    }
//  }
//  Kod lama baca bd['targetThreshold'] → null (salah).
//  Kod baru baca bd['config']['targetThreshold'] → "0.98" (betul).
//
// PF FORMULA (2-tier stepped):
//  Tier 1 range : tier1Threshold → max(pfValue, tier2Trigger)
//  Tier 2 range : tier2Trigger   → pfValue  (hanya jika pfValue < tier2Trigger)
//
//  Scenario A: T1=0.98, T2=0.96, PF=0.94
//    Tier1 = (0.98-0.96)/0.01 × 1.5% = 3%
//    Tier2 = (0.96-0.94)/0.01 × 3%   = 6%
//    Total = 9% ✓
//
//  Scenario B: T1=0.98, T2=0.90, PF=0.94
//    Tier1 = (0.98-0.94)/0.01 × 1.5% = 6%
//    Tier2 = 0%  (PF 0.94 > T2 0.90, tidak triggered)
//    Total = 6% ✓

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_models.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import 'models/tnb_e3_bill_simulator_model.dart';
import 'tnb_e3_bill_simulator_pdf_exporter.dart';
import 'widgets/tnb_header_card.dart';
import 'widgets/tnb_breakdown_table.dart';
import 'widgets/tnb_summary_cards.dart';
import 'widgets/tnb_footer.dart';
import 'package:smartmachine365/services/filter_memory.dart';
import '../tnb_bill_data_logger/models/tnb_bill_log_entry.dart';
import '../tnb_bill_data_logger/widgets/tbl_chart_panel.dart';
import '../tnb_bill_data_logger/widgets/tbl_legend_dot.dart';

// Fallback constants — used when API returns 0 / null for peak rates
const double _kFallbackPeakRate = 0.355;
const double _kFallbackOffPeakRate = 0.219;

class TnbE3BillSimulatorWidget extends StatefulWidget {
  const TnbE3BillSimulatorWidget({super.key});

  @override
  State<TnbE3BillSimulatorWidget> createState() =>
      _TnbE3BillSimulatorWidgetState();
}

class _TnbE3BillSimulatorWidgetState extends State<TnbE3BillSimulatorWidget> {
  /// ui7 data plane; x-client-id from integration config routes tenant DB/Firestore.
  /// No header → shared function keeps Danapac hardcoded fallback (demo unchanged).
  String get _apiBase => AppConfig.dataApiBaseSafe;
  Map<String, String> get _apiHeaders => AppConfig.headers;

  bool _isLoading = true;
  String? _errorMessage;

  // ── PDF export state ────────────────────────────────────────────────────
  // The captured RepaintBoundary covers the breakdown table + summary cards
  // (the "Main content" section below the header/filter row) — same scope
  // MD Insight Report's RepaintBoundary captures, excluding on-screen-only
  // controls like the meter filter and Download button themselves.
  final GlobalKey _billBoundaryKey = GlobalKey();
  bool _isGeneratingPdf = false;
  String _pdfStatus = 'Capturing report…';
  double _pdfProgress = 0.0;

  // ── Filter state ─────────────────────────────────────────────────────────
  List<FacilityData> _allFacilities = [];
  List<String> _allTopics = [];
  List<String> _topics = [];
  String? _selectedTopic;
  static const String _filterScreen = 'tnb_bill_simulator';
  bool _filtersRestored = false;

  void _rememberFilters() => FilterMemory.save(_filterScreen, {
        'meter': _selectedMeterId,
        'plant': selectedPlant,
      });

  /// Restores once the meter list has loaded. A meter that has since been
  /// removed is skipped, so the screen never opens on something that is gone.
  void _restoreFiltersOnce() {
    if (_filtersRestored || _activeMeters.isEmpty) return;
    _filtersRestored = true;
    FilterMemory.load(_filterScreen).then((saved) {
      if (saved.isEmpty || !mounted) return;
      final meter = saved['meter'];
      if (meter != null && _activeMeters.any((m) => m.id == meter)) {
        _onMeterChanged(meter);
        return;
      }
      final plant = saved['plant'];
      if (plant != null && plant != 'All' && _plantOptions.contains(plant)) {
        _onPlantChanged(plant);
      }
    });
  }

  String selectedPlant = 'All';

  // TNB meters (TNB Meter Setting) — the simulator's dropdown lists these
  // registered meters; each carries its DPM ID link (influxDbTag, e.g.
  // "VDPM002") and its tariff category, which select the billing data source
  // and billing config for the results shown.
  List<TnbMeter> _tnbMeters = [];
  Map<String, String> _plantNameToId = {};
  Map<String, String> _plantIdToName = {};
  Map<String, String> _tariffCategoryNames = {};
  String? _selectedMeterId;
  String _dataSourceLabel = 'MSB';

  List<TnbMeter> get _activeMeters =>
      _tnbMeters.where((m) => m.isActive).toList();

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

  void _onMeterChanged(String? meterId) {
    setState(() {
      _selectedMeterId = meterId;
      // Keep the plant-based topic filter & subtitle in sync with the meter.
      final m = _selectedMeter;
      selectedPlant = m != null ? (_plantIdToName[m.plantId] ?? 'All') : 'All';
      _topics = _filteredTopics;
      if (_topics.isNotEmpty &&
          (_selectedTopic == null || !_topics.contains(_selectedTopic))) {
        _selectedTopic = _topics.first;
      } else if (_topics.isEmpty) {
        _selectedTopic = null;
      }
    });
    _fetchAndBuild();
      _rememberFilters();
  }

  List<String> get _plantOptions {
    final plants = _allFacilities
        .map((f) => f.plant)
        .where((p) => p.isNotEmpty && p != '-')
        .toSet()
        .toList()
      ..sort();
    return ['All', ...plants];
  }

  List<String> get _filteredTopics {
    if (selectedPlant == 'All') return _allTopics;
    final facilityMeterIds = _allFacilities
        .where((f) => f.plant == selectedPlant)
        .map((f) => f.meterId)
        .toSet();
    return _allTopics.where((t) => facilityMeterIds.contains(t)).toList();
  }

  void _onPlantChanged(String plant) {
    setState(() {
      selectedPlant = plant;
      _topics = _filteredTopics;
      if (_topics.isNotEmpty &&
          (_selectedTopic == null || !_topics.contains(_selectedTopic))) {
        _selectedTopic = _topics.first;
      } else if (_topics.isEmpty) {
        _selectedTopic = null;
      }
    });
    // Always rebuild — the plant's TNB meter (DPM link + tariff category)
    // changes the billing source even when the topic stayed the same.
    _fetchAndBuild();
      _rememberFilters();
  }

  Widget _buildCyberpunkDropdown({
    required BuildContext context,
    required String? value,
    required List<String> options,
    required String hint,
    required double width,
    required void Function(String?) onChanged,
    String Function(String)? labelBuilder,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    const cyan = Color(0xFF00D4FF);
    final safeValue = (value != null && options.contains(value)) ? value : null;
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
        border: Border.all(
            color: isLight ? theme.alternate : cyan.withOpacity(0.5),
            width: 1.2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: cyan.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: isLight ? theme.primary : cyan,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                    color: (isLight ? theme.primary : cyan).withOpacity(0.8),
                    blurRadius: 6)
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: safeValue,
                  isExpanded: true,
                  dropdownColor: isLight
                      ? theme.secondaryBackground
                      : const Color(0xFF071A2E),
                  menuMaxHeight: 300,
                  hint: Text(hint,
                      style: GoogleFonts.poppins(
                          color: isLight
                              ? theme.secondaryText
                              : cyan.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  style: GoogleFonts.poppins(
                      color: isLight ? theme.txtPrimary : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isLight ? theme.primary : cyan, size: 22),
                  items: options
                      .map((opt) => DropdownMenuItem<String>(
                            value: opt,
                            child: Text(labelBuilder?.call(opt) ?? opt,
                                style: GoogleFonts.poppins(
                                    color: isLight
                                        ? theme.txtPrimary
                                        : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Display state ─────────────────────────────────────────────────────────
  String _accrualAmount = 'RM 0.00';
  String _totalBeforeRebates = '0.00';
  String _peakStart = '08:00';
  String _peakEnd = '22:00';
  String _categoryName = '';
  String _cycleEffectiveDate = '';
  String _lastUpdated = '';

  // ── PF state (passed down to summary cards, no second HTTP call) ──────────
  double _pfValue = 0;
  double _tier1Threshold = 0.98;
  double _tier2Trigger = 0.96;

  // ── Daily Grid Import Cost chart — current calendar month only (1st day
  // through the last day of the month), same TblChartPanel + daily-bill-log
  // rows TnbBillDataLoggerWidget's own chart uses, so the two stay visually
  // consistent. Reset each month by the year/month filter in _fetchAndBuild
  // rather than a rolling day-count window. ──────────────────────────────
  List<TnbBillLogEntry> _dailyEntries = [];
  double _peakRate = _kFallbackPeakRate;
  double _offPeakRate = _kFallbackOffPeakRate;

  // ── Solar savings state — meter's solarDeviceId (TNB Meter Setting →
  // Solar mapping) selects which device's generation feeds this, else the
  // card shows "no device mapped" instead of a stale hardcoded figure. ────
  // Split peak/off-peak from the new /energyDetails/peak-off-peak endpoint —
  // avoided cost is only worth the peak rate for generation that actually
  // fell inside the site's peak ToU window.
  double _solarPeakKwh = 0;
  double _solarOffPeakKwh = 0;
  double _solarPeakAvoidedCost = 0;
  double _solarOffPeakAvoidedCost = 0;
  bool _solarMapped = false;

  List<TnbBreakdownItem> _breakdownItems = <TnbBreakdownItem>[
    TnbBreakdownItem(
      desc: 'Peak Usage (08:00 - 22:00)',
      usage: '0\nkWh',
      rate: _kFallbackPeakRate.toStringAsFixed(3),
      amount: '0.00',
      tag: 'PEAK',
      tagColor: const Color(0xFFFF6D00),
    ),
    TnbBreakdownItem(
      desc: 'Off-Peak Usage (22:00 - 08:00)',
      usage: '0\nkWh',
      rate: _kFallbackOffPeakRate.toStringAsFixed(3),
      amount: '0.00',
      tag: 'OFF-PEAK',
      tagColor: const Color(0xFF00BFA5),
    ),
    const TnbBreakdownItem(
      desc: 'Maximum Demand (kW)',
      usage: '0 kW',
      rate: '0.00',
      amount: '0.00',
    ),
    const TnbBreakdownItem(
      desc: 'Network Charge',
      usage: '0 kW',
      rate: '0.00',
      amount: '0.00',
    ),
    const TnbBreakdownItem(
      desc: 'Retail Charge',
      usage: '-',
      rate: 'RM 0.00',
      amount: '0.00',
    ),
    const TnbBreakdownItem(
      desc: 'Power Factor Penalty',
      usage: '- PF',
      rate: 'Penalty\nRate',
      amount: '0.00',
      isPenalty: true,
    ),
    const TnbBreakdownItem(
      desc: 'AFA',
      usage: '0\nkWh',
      rate: '0.0',
      amount: '0.00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFiltersAndFetch());
  }

  Future<void> _initFiltersAndFetch() async {
    await AppConfig.refresh();
    try {
      final results = await Future.wait([
        http
            .get(
              Uri.parse('$_apiBase/energyDetailsInfluxDb/devices'),
              headers: _apiHeaders,
            )
            .timeout(const Duration(seconds: 10)),
        FacilityService.getFacilities().catchError((_) => <FacilityData>[]),
        TnbMeterService.fetchMeters().catchError((_) => <TnbMeter>[]),
        TnbMeterService.fetchPlants()
            .catchError((_) => <Map<String, dynamic>>[]),
        TnbMeterService.fetchTariffCategories()
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      final res = results[0] as http.Response;
      final facilities = results[1] as List<FacilityData>;
      _tnbMeters = results[2] as List<TnbMeter>;
      final plantRows = results[3] as List<Map<String, dynamic>>;
      final tariffRows = results[4] as List<Map<String, dynamic>>;
      _tariffCategoryNames = {
        for (final t in tariffRows)
          if ((t['id']?.toString() ?? '').isNotEmpty)
            t['id'].toString(): (t['tariffCategory'] ??
                    t['voltageName'] ??
                    t['name'] ??
                    t['id'])
                .toString(),
      };
      _plantNameToId = {
        for (final p in plantRows)
          if ((p['name']?.toString() ?? '').isNotEmpty)
            p['name'].toString(): p['id']?.toString() ?? '',
      };
      _plantIdToName = {
        for (final e in _plantNameToId.entries) e.value: e.key,
      };
      // Default to the first registered meter so the page opens with a
      // meter-linked result (mirrors the TNB Meter Setting list).
      if (_activeMeters.isNotEmpty) {
        _selectedMeterId = _activeMeters.first.id;
        selectedPlant = _plantIdToName[_activeMeters.first.plantId] ?? 'All';
      }

      List<String> deviceList = [];
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        deviceList = (decoded is List ? decoded : const [])
            .map((d) => (d is Map ? d['device_id'] : d)?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      setState(() {
        _allTopics = deviceList;
        _allFacilities = facilities;
        _topics = _filteredTopics;
        if (_topics.isNotEmpty) {
          for (final pref in const ['MSB', 'DPM047']) {
            if (_topics.contains(pref)) {
              _selectedTopic = pref;
              break;
            }
          }
          _selectedTopic ??= _topics.first;
        }
      });
    } catch (_) {}

    _fetchAndBuild();
  }

  Future<http.Response> _fetchBillingConfig(
      String userUid, String meterCategoryId) async {
    final headers = _apiHeaders;
    if (meterCategoryId.isNotEmpty) {
      final linked = await http
          .get(
            Uri.parse(
                '$_apiBase/masterBillingConfig/$userUid/$meterCategoryId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      // A category doc can exist (200) yet still be missing the fields that
      // actually drive the bill — e.g. two tariff-category entries end up
      // with the same display name ("MV Non-Domestic (ToU)") after one gets
      // recreated, the meter stays bound to the old doc-id, and only the new
      // one ever gets its PF Surcharge / cycle-date fields filled in. Trusting
      // any 200 here silently shows the hardcoded PF fallback (0.98/0.96)
      // instead of the real Master Billing Config values, so fall back to
      // whichever category is actually marked active/applied when the linked
      // one is incomplete.
      if (linked.statusCode == 200 && _isBillingConfigComplete(linked.body)) {
        return linked;
      }
    }
    return http
        .get(
          Uri.parse('$_apiBase/masterBillingConfig/$userUid/active'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));
  }

  // Fields the bill simulator actually reads out of `config` — PF Surcharge
  // Rules plus the rates that feed the breakdown table. Any blank among
  // these means this category was never fully configured in Master Billing
  // Configuration, even though the doc itself exists.
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
      return _criticalBillingFields
          .every((f) => (cfg[f]?.toString().trim().isNotEmpty ?? false));
    } catch (_) {
      return false;
    }
  }

  String _billingDeviceFor(TnbMeter? meter) {
    if (meter != null) {
      if (meter.influxDbTag.trim().isNotEmpty) return meter.influxDbTag.trim();
      if (meter.meterCode.trim().isNotEmpty) return meter.meterCode.trim();
    }
    return _selectedTopic ?? 'MSB';
  }

  Future<void> _fetchAndBuild() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Re-load meters so a DPM ID change in TNB Meter Setting is picked up
      // when the user hits Refresh (or re-selects a meter).
      try {
        final freshMeters = await TnbMeterService.fetchMeters();
        if (mounted) _tnbMeters = freshMeters;
      } catch (_) {}

      final userUid = AppStateNotifier.instance.uid ?? '';
      // Billing config (and the usage-unit lookup that reads it) is shared
      // across every user of this client, not per-login — see
      // AppConfig.sharedConfigOwnerId. energy-settings below stays keyed by
      // the real uid — out of scope for this fix.
      const billingOwnerId = AppConfig.sharedConfigOwnerId;
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      // Plant's TNB meter (TNB Meter Setting) wins: its DPM ID config
      // (influxDbTag, e.g. "VDPM002") is the billing device and its tariff
      // category selects the billing config. Falls back to the topic +
      // globally applied config when the plant has no registered meter.
      final meter = _selectedMeter;
      final billingDevice = _billingDeviceFor(meter);
      final meterCategoryId = meter?.tariffCategoryId.trim() ?? '';
      final solarDeviceId = meter?.solarDeviceId.trim() ?? '';
      _dataSourceLabel = billingDevice;
      _solarMapped = solarDeviceId.isNotEmpty;

      if (meterCategoryId.isNotEmpty) {
        _categoryName = _tariffCategoryNames[meterCategoryId] ?? _categoryName;
      }

      final results = await Future.wait([
        // 0 — billing config from ui7 (meter-linked category, else active)
        _fetchBillingConfig(billingOwnerId, meterCategoryId),

        // 1 — energy settings (peak ToU hours) from ui7
        http
            .get(
              Uri.parse('$_apiBase/energy-settings/$userUid'),
              headers: _apiHeaders,
            )
            .timeout(const Duration(seconds: 15)),

        // 2 — monthly bill metrics from Overall_monthly_energy_consumption
        http
            .get(
              Uri.parse(
                  '$_apiBase/energyComparison/tnb-bill-simulator/$billingDevice'),
              headers: _apiHeaders,
            )
            .timeout(const Duration(seconds: 15)),

        // 3 — MTD usage & rates (billing rates from the billing engine)
        http
            .get(
              Uri.parse(
                '$_apiBase/tnbE3Simulator/usage-unit/$billingOwnerId/$year/$month'
                '?device_id=${Uri.encodeComponent(billingDevice)}',
              ),
              headers: _apiHeaders,
            )
            .timeout(const Duration(seconds: 15)),

        // 4 — electricity tariff (peak/off-peak rates saved in Master Billing)
        http
            .get(
              Uri.parse(
                  '$_apiBase/masterBillingConfig/$billingOwnerId/electricityTariff'),
              headers: _apiHeaders,
            )
            .timeout(const Duration(seconds: 15)),

        // 5 — solar generation (Solar Savings card) — only when the meter has
        // a solar device mapped (TNB Meter Setting → Solar mapping); a 204
        // stand-in keeps every branch the same Future<http.Response> type.
        solarDeviceId.isNotEmpty
            ? http
                .get(
                  Uri.parse(
                      '$_apiBase/energyDetails/total/${Uri.encodeComponent(solarDeviceId)}'),
                  headers: _apiHeaders,
                )
                .timeout(const Duration(seconds: 15))
            : Future.value(http.Response('', 204)),

        // 6 — daily grid-import rows for the "Daily Grid Import Cost · Power
        // Factor Trend" chart — same /energyComparison/daily-bill-log/:device_id
        // endpoint TnbBillDataLoggerWidget's chart reads, requesting just
        // enough days to cover the current calendar month to date (small +2
        // buffer for timezone edge cases, mirrors that widget's
        // _daysSinceMonthStart()+2). Results are filtered to this
        // month/year below so the chart always spans 1st-to-last-day of the
        // current month rather than a rolling window.
        http
            .get(
              Uri.parse(
                  '$_apiBase/energyComparison/daily-bill-log/${Uri.encodeComponent(billingDevice)}?days=${now.day + 2}'),
              headers: _apiHeaders,
            )
            .timeout(const Duration(seconds: 20)),
      ]);

      if (!mounted) return;

      final billingResponse = results[0];
      final energyResponse = results[1];
      final tnbSimResponse = results[2];
      final usageResponse = results[3];
      final electricityTariffResponse = results[4];
      final solarResponse = results[5];
      final dailyLogResponse = results[6];

      // ── Solar generation (kWh, MTD) ─────────────────────────────────────
      double solarMonthlyKwh = 0;
      if (solarResponse.statusCode == 200) {
        try {
          final rows = jsonDecode(solarResponse.body);
          if (rows is List) {
            for (final row in rows) {
              if (row is Map && row['period']?.toString() == 'monthly') {
                solarMonthlyKwh = _p(row['total_energy']);
              }
            }
          }
        } catch (_) {}
      }

      // Parse the Overall_monthly bill metrics once (used for MD, PF, usage).
      Map<String, dynamic> tnbSim = {};
      if (tnbSimResponse.statusCode == 200) {
        tnbSim = jsonDecode(tnbSimResponse.body) as Map<String, dynamic>? ?? {};
      }

      // ── 0. Active billing config ──────────────────────────────────────────
      // Response structure:
      // {
      //   "userId": "...",
      //   "appliedCategory": "...",
      //   "appliedCategoryName": "Tariff E2",
      //   "config": {                      â† NESTED HERE
      //     "targetThreshold": "0.98",     â† Tier 1 PF threshold
      //     "tier1Rate": "1.5",
      //     "tier2Trigger": "0.9",         â† Tier 2 PF threshold
      //     "tier2Rate": "3",
      //     "mdCapacityCharge": "0.50",
      //     "mdNetworkCharge": "0.50",
      //     "currentAFA": "0.50",
      //     "cycleEffectiveDate": "...",
      //     ...
      //   }
      // }
      double mdCapacityCharge = 0;
      double mdNetworkCharge = 0;
      double retailCharge = 0;
      double currentAFA = 0;
      double tier1Threshold = 0.98; // fallback
      double tier1Rate = 1.5; // fallback %
      double tier2Trigger = 0.96; // fallback
      double tier2Rate = 3.0; // fallback %

      if (billingResponse.statusCode == 200) {
        final root = jsonDecode(billingResponse.body) as Map<String, dynamic>;

        // ─── READ FROM NESTED "config" OBJECT ───────────────────────────────
        final cfg = root['config'] as Map<String, dynamic>? ?? {};

        debugPrint('=== BILLING CONFIG (nested cfg) ===');
        debugPrint('targetThreshold : ${cfg['targetThreshold']}');
        debugPrint('tier1Rate       : ${cfg['tier1Rate']}');
        debugPrint('tier2Trigger    : ${cfg['tier2Trigger']}');
        debugPrint('tier2Rate       : ${cfg['tier2Rate']}');
        debugPrint('mdCapacityCharge: ${cfg['mdCapacityCharge']}');
        debugPrint('mdNetworkCharge : ${cfg['mdNetworkCharge']}');
        debugPrint('retailCharge    : ${cfg['retailCharge']}');
        debugPrint('currentAFA      : ${cfg['currentAFA']}');

        mdCapacityCharge = _p(cfg['mdCapacityCharge']);
        mdNetworkCharge = _p(cfg['mdNetworkCharge']);
        retailCharge = _p(cfg['retailCharge']);
        currentAFA = _p(cfg['currentAFA']);

        // targetThreshold = Tier 1 PF threshold (field name dari master billing)
        final double parsedT1Threshold = _p(cfg['targetThreshold']);
        final double parsedT1Rate = _p(cfg['tier1Rate']);
        final double parsedT2Trigger = _p(cfg['tier2Trigger']);
        final double parsedT2Rate = _p(cfg['tier2Rate']);

        if (parsedT1Threshold > 0) tier1Threshold = parsedT1Threshold;
        if (parsedT1Rate > 0) tier1Rate = parsedT1Rate;
        if (parsedT2Trigger > 0) tier2Trigger = parsedT2Trigger;
        if (parsedT2Rate > 0) tier2Rate = parsedT2Rate;

        _cycleEffectiveDate = cfg['cycleEffectiveDate']?.toString() ?? '';

        // Store thresholds for PF card (no second API call needed)
        _tier1Threshold = tier1Threshold;
        _tier2Trigger = tier2Trigger;
      }

      // Category name: meter-linked tariff category, else active billing name.
      if (billingResponse.statusCode == 200) {
        final root = jsonDecode(billingResponse.body) as Map<String, dynamic>;
        final fromMeter = root['appliedCategoryName']?.toString() ?? '';
        if (fromMeter.isNotEmpty) {
          _categoryName = fromMeter;
        } else {
          final catId = root['category']?.toString() ??
              root['appliedCategory']?.toString() ??
              meterCategoryId;
          if (catId.isNotEmpty) {
            _categoryName = _tariffCategoryNames[catId] ?? _categoryName;
          }
        }
      }
      if (_categoryName.isEmpty && meterCategoryId.isNotEmpty) {
        _categoryName = _tariffCategoryNames[meterCategoryId] ?? '';
      }

      debugPrint('=== FINAL PF CONFIG ===');
      debugPrint('tier1Threshold : $tier1Threshold');
      debugPrint('tier1Rate      : $tier1Rate %');
      debugPrint('tier2Trigger   : $tier2Trigger');
      debugPrint('tier2Rate      : $tier2Rate %');

      // ── 1. Peak hours ─────────────────────────────────────────────────────
      if (energyResponse.statusCode == 200) {
        final energyData =
            jsonDecode(energyResponse.body) as Map<String, dynamic>;
        final settings = energyData['settings'] as Map<String, dynamic>? ?? {};
        final cc = settings['contractCapacity'] as Map<String, dynamic>? ?? {};
        final tou = cc['peakHourToU'] as Map<String, dynamic>? ?? {};
        _peakStart = tou['startTime']?.toString() ?? '08:00';
        _peakEnd = tou['endTime']?.toString() ?? '22:00';
      }

      // ── Solar peak/off-peak split (Solar Savings card) — needs the site's
      // ToU window resolved just above, so this is a follow-up call rather
      // than bundled into the parallel batch above (which would race that
      // fetch and use a stale/default window). The backend itself already
      // tries two sources (Overall_hourly_energy_generation, then
      // hourly_device_summary — see /energyDetails/peak-off-peak); this
      // client-side fallback only kicks in if BOTH came back empty, e.g. the
      // device only has data in Influx (which /total/ falls back to but the
      // split endpoint doesn't query) — in which case treat all generation
      // as peak-rate, the old assumption from before this split existed.
      double solarPeakKwh = 0;
      double solarOffPeakKwh = 0;
      if (solarDeviceId.isNotEmpty) {
        try {
          final splitResponse = await http
              .get(
                Uri.parse(
                  '$_apiBase/energyDetails/peak-off-peak/${Uri.encodeComponent(solarDeviceId)}'
                  '?peakStart=$_peakStart&peakEnd=$_peakEnd&year=$year&month=$month',
                ),
                headers: _apiHeaders,
              )
              .timeout(const Duration(seconds: 15));
          if (splitResponse.statusCode == 200) {
            final split =
                jsonDecode(splitResponse.body) as Map<String, dynamic>;
            solarPeakKwh = _p(split['peak_kwh']);
            solarOffPeakKwh = _p(split['off_peak_kwh']);
          }
        } catch (_) {}
        if (solarPeakKwh <= 0 && solarOffPeakKwh <= 0 && solarMonthlyKwh > 0) {
          solarPeakKwh = solarMonthlyKwh;
        }
      }
      _solarPeakKwh = solarPeakKwh;
      _solarOffPeakKwh = solarOffPeakKwh;

      // ── 2. Monthly max demand (Overall_monthly.max_demand_kW) ──────────────
      final double maxDemandKw = _p(tnbSim['max_demand_kW']);

      // ── 3. Power factor (Overall_monthly.power_factor_avg) ──────────────────
      final double pfValue = _p(tnbSim['power_factor']);
      _pfValue = pfValue;
      debugPrint('PF VALUE (Overall_monthly) : $pfValue');

      // ── 4. MTD usage ──────────────────────────────────────────────────────
      // Peak / off-peak usage come from Overall_monthly (peak_usage_kWh,
      // off_peak_usage_kWh); the billing rates still come from the billing
      // engine (usage-unit), falling back to defaults.
      double peakUsage = _p(tnbSim['peak_usage_kWh']);
      double offPeakUsage = _p(tnbSim['off_peak_usage_kWh']);
      double peakRate = _kFallbackPeakRate;
      double offPeakRate = _kFallbackOffPeakRate;
      double peakAmount = 0;
      double offPeakAmount = 0;

      if (electricityTariffResponse.statusCode == 200) {
        final tariff =
            jsonDecode(electricityTariffResponse.body) as Map<String, dynamic>;
        peakRate =
            _p(tariff['peakRate']) > 0 ? _p(tariff['peakRate']) : peakRate;
        offPeakRate = _p(tariff['offPeakRate']) > 0
            ? _p(tariff['offPeakRate'])
            : offPeakRate;
      }

      if (usageResponse.statusCode == 200) {
        final u = jsonDecode(usageResponse.body) as Map<String, dynamic>;
        if (peakUsage <= 0) peakUsage = _p(u['peak_usage_kWh']);
        if (offPeakUsage <= 0) offPeakUsage = _p(u['off_peak_usage_kWh']);
        peakRate = _p(u['peak_rate']) > 0 ? _p(u['peak_rate']) : peakRate;
        offPeakRate =
            _p(u['off_peak_rate']) > 0 ? _p(u['off_peak_rate']) : offPeakRate;
        peakAmount = _p(u['peak_amount']);
        offPeakAmount = _p(u['off_peak_amount']);
      }
      // Recompute amounts from usage x rate when the engine didn't supply them.
      if (peakAmount <= 0) peakAmount = peakUsage * peakRate;
      if (offPeakAmount <= 0) offPeakAmount = offPeakUsage * offPeakRate;

      // Solar generation is self-consumed, not billed — the "saving" is what
      // each kWh would have cost had it been drawn from the grid instead, at
      // whichever rate applied to the hour it was actually generated in.
      _solarPeakAvoidedCost = _solarPeakKwh * peakRate;
      _solarOffPeakAvoidedCost = _solarOffPeakKwh * offPeakRate;
      _peakRate = peakRate;
      _offPeakRate = offPeakRate;

      // ── Daily Grid Import Cost chart rows — filtered to this calendar
      // month (1st day through the last day of the month) rather than just
      // trusting the `days=` window, since that window is sized with a small
      // buffer and could otherwise leak a trailing day from last month in.
      List<TnbBillLogEntry> dailyEntries = [];
      if (dailyLogResponse.statusCode == 200) {
        final decoded = jsonDecode(dailyLogResponse.body);
        if (decoded is List) {
          dailyEntries = decoded
              .map((e) => TnbBillLogEntry.fromJson(e as Map<String, dynamic>))
              .where((e) => e.date.year == year && e.date.month == month)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
        }
      }
      _dailyEntries = dailyEntries;

      _buildFromConfig(
        mdCapacityCharge: mdCapacityCharge,
        mdNetworkCharge: mdNetworkCharge,
        retailCharge: retailCharge,
        maxDemandKw: maxDemandKw,
        currentAFA: currentAFA,
        pfValue: pfValue,
        tier1Threshold: tier1Threshold,
        tier1Rate: tier1Rate,
        tier2Trigger: tier2Trigger,
        tier2Rate: tier2Rate,
        peakUsage: peakUsage,
        offPeakUsage: offPeakUsage,
        peakRate: peakRate,
        offPeakRate: offPeakRate,
        peakAmount: peakAmount,
        offPeakAmount: offPeakAmount,
      );

      if (mounted) {
        _lastUpdated = _fmtTimestamp(DateTime.now());
        setState(() => _isLoading = false);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  // ── PF Penalty Calculation ────────────────────────────────────────────────
  //
  //  SCENARIO A — PF dips below tier2Trigger (e.g. T2=0.96, PF=0.94)
  //  ┌──────────────────────────────────────────────────────────â”
  //  │  0.98 ──── Tier1 range ──── 0.96 ──── Tier2 range ─ 0.94│
  //  │  Tier1 steps = (0.98−0.96)/0.01 = 2 → 2 × 1.5% = 3%    │
  //  │  Tier2 steps = (0.96−0.94)/0.01 = 2 → 2 × 3%   = 6%    │
  //  │  Total = 9% × total billing                              │
  //  └──────────────────────────────────────────────────────────┘
  //
  //  SCENARIO B — PF above tier2Trigger (e.g. T2=0.90, PF=0.94)
  //  ┌──────────────────────────────────────────────────────────â”
  //  │  0.98 ───────── Tier1 range ───────────────── 0.94       │
  //  │  0.90 â† tier2 not crossed                                │
  //  │  Tier1 steps = (0.98−0.94)/0.01 = 4 → 4 × 1.5% = 6%    │
  //  │  Tier2 = 0%                                              │
  //  │  Total = 6% × total billing                              │
  //  └──────────────────────────────────────────────────────────┘
  // ─────────────────────────────────────────────────────────────────────────
  void _buildFromConfig({
    required double mdCapacityCharge,
    required double mdNetworkCharge,
    required double retailCharge,
    required double maxDemandKw,
    required double currentAFA,
    required double pfValue,
    required double tier1Threshold,
    required double tier1Rate,
    required double tier2Trigger,
    required double tier2Rate,
    required double peakUsage,
    required double offPeakUsage,
    required double peakRate,
    required double offPeakRate,
    required double peakAmount,
    required double offPeakAmount,
  }) {
    final double totalKwh = peakUsage + offPeakUsage;
    final double afaRate = currentAFA;
    final double mdCapacityAmount = maxDemandKw * mdCapacityCharge;
    final double networkChargeAmount = maxDemandKw * mdNetworkCharge;
    final double retailChargeAmount = retailCharge;
    final double afaAmount = totalKwh * afaRate;

    pfValue = pfValue.clamp(0.0, 1.0);

    double pfPenaltyPercent = 0;
    double pfPenaltyAmount = 0;
    String pfPenaltyRateDisplay = '0.0%';

    if (pfValue < tier1Threshold) {
      // ── Tier 1 ──
      // Covers from tier1Threshold down to the HIGHER of (pfValue, tier2Trigger).
      // This ensures Tier 1 does NOT count steps that belong to Tier 2.
      final double tier1Lower = math.max(pfValue, tier2Trigger);
      final int tier1Steps = _steps(tier1Threshold, tier1Lower);
      final double tier1Penalty = tier1Steps * tier1Rate;

      // ── Tier 2 ──
      // Only triggered when PF actually drops below tier2Trigger.
      // Covers from tier2Trigger down to pfValue.
      double tier2Penalty = 0;
      if (pfValue < tier2Trigger) {
        final int tier2Steps = _steps(tier2Trigger, pfValue);
        tier2Penalty = tier2Steps * tier2Rate;
        debugPrint(
            'Tier 2 TRIGGERED: steps=$tier2Steps penalty=$tier2Penalty%');
      } else {
        debugPrint(
            'Tier 2 NOT triggered (pfValue=$pfValue >= tier2Trigger=$tier2Trigger)');
      }

      pfPenaltyPercent = tier1Penalty + tier2Penalty;

      debugPrint('=== PF PENALTY CALC ===');
      debugPrint('pfValue        : $pfValue');
      debugPrint('tier1Lower     : $tier1Lower');
      debugPrint('tier1Steps     : $tier1Steps');
      debugPrint('tier1Penalty   : $tier1Penalty %');
      debugPrint('tier2Penalty   : $tier2Penalty %');
      debugPrint('totalPenalty   : $pfPenaltyPercent %');

      final double billingBeforePf = peakAmount +
          offPeakAmount +
          mdCapacityAmount +
          networkChargeAmount +
          retailChargeAmount +
          afaAmount;

      pfPenaltyAmount = billingBeforePf * (pfPenaltyPercent / 100);
      pfPenaltyRateDisplay = '${pfPenaltyPercent.toStringAsFixed(1)}%';
    }

    final double total = peakAmount +
        offPeakAmount +
        mdCapacityAmount +
        networkChargeAmount +
        retailChargeAmount +
        pfPenaltyAmount +
        afaAmount;

    _breakdownItems = <TnbBreakdownItem>[
      TnbBreakdownItem(
        desc: 'Peak Usage ($_peakStart - $_peakEnd)',
        usage: '${_fmt(peakUsage, 0)}\nkWh',
        rate: peakRate.toStringAsFixed(3),
        amount: _fmt(peakAmount),
        tag: 'PEAK',
        tagColor: const Color(0xFFFF6D00),
      ),
      TnbBreakdownItem(
        desc: 'Off-Peak Usage ($_peakEnd - $_peakStart)',
        usage: '${_fmt(offPeakUsage, 0)}\nkWh',
        rate: offPeakRate.toStringAsFixed(3),
        amount: _fmt(offPeakAmount),
        tag: 'OFF-PEAK',
        tagColor: const Color(0xFF00BFA5),
      ),
      TnbBreakdownItem(
        desc: 'Maximum Demand (kW)',
        usage: '${_fmt(maxDemandKw, 1)} kW',
        rate: _fmt(mdCapacityCharge),
        amount: _fmt(mdCapacityAmount),
      ),
      TnbBreakdownItem(
        desc: 'Network Charge',
        usage: '${_fmt(maxDemandKw, 1)} kW',
        rate: _fmt(mdNetworkCharge),
        amount: _fmt(networkChargeAmount),
      ),
      TnbBreakdownItem(
        desc: 'Retail Charge',
        usage: '-',
        rate: 'RM ${_fmt(retailCharge)}',
        amount: _fmt(retailChargeAmount),
      ),
      TnbBreakdownItem(
        desc: 'Power Factor Penalty',
        usage: pfValue > 0 ? '${pfValue.toStringAsFixed(3)} PF' : '- PF',
        rate: pfPenaltyRateDisplay,
        amount: pfPenaltyAmount > 0 ? '+ ${_fmt(pfPenaltyAmount)}' : '0.00',
        isPenalty: true,
      ),
      TnbBreakdownItem(
        desc: 'AFA',
        usage: '${_fmt(totalKwh, 0)}\nkWh',
        rate: afaRate.toStringAsFixed(1),
        amount: afaAmount == 0 ? '0.00' : _fmt(afaAmount),
      ),
    ];

    _totalBeforeRebates = _fmt(total);
    _accrualAmount = 'RM ${_fmt(total)}';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _p(dynamic val) {
    if (val == null) return 0.0;
    final s = val.toString().replaceAll(',', '.').trim();
    if (s.isEmpty) return 0.0;
    return double.tryParse(s) ?? 0.0;
  }

  static final _fmtRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  String _fmt(double num, [int decimals = 2]) {
    return num.toStringAsFixed(decimals).replaceAllMapped(
      _fmtRegex,
      (m) => '${m[1]},',
    );
  }

  /// Count 0.01 steps between upper and lower.
  /// e.g. _steps(0.98, 0.96) → 2
  int _steps(double upper, double lower) {
    if (upper <= lower) return 0;
    return ((upper - lower) * 100).round();
  }

  static const List<String> _monthAbbrev = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "UPDATED"/"Generated" timestamp — full date (day/month/year), not just
  /// the time, so a bill checked yesterday isn't mistaken for today's.
  String _fmtTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthAbbrev[(dt.month - 1).clamp(0, 11)];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$day $month ${dt.year}, $hh:$mm:$ss';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image:
                            Image.asset('assets/images/backgroundanimated.gif')
                                .image,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.008,
                        vertical: MediaQuery.of(context).size.height * 0.022,
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: Color(0xFF00E5FF),
                              strokeWidth: 2,
                            ))
                          : _errorMessage != null
                              ? _buildError()
                              : Stack(
                                  children: [
                                    _buildPage(context),
                                    if (_isGeneratingPdf) _pdfLoadingOverlay(),
                                  ],
                                ),
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

  Widget _buildError() {
    final sw = MediaQuery.of(context).size.width;
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    const cRed = Color(0xFFEF5350);
    const cCyan = Color(0xFF00E5FF);
    final pad = sw * 0.010;
    return Center(
      child: Container(
        padding: EdgeInsets.all(pad * 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? [
                    theme.secondaryBackground.withOpacity(0.97),
                    theme.primaryBackground.withOpacity(0.97),
                  ]
                : [
                    const Color(0xFF0E2040).withOpacity(0.95),
                    const Color(0xFF07101F).withOpacity(0.98),
                  ],
          ),
          borderRadius: BorderRadius.circular(sw * 0.005),
          border: Border.all(color: cRed.withOpacity(0.55), width: sw * 0.0008),
          boxShadow: [
            BoxShadow(color: cRed.withOpacity(0.15), blurRadius: pad * 3)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cRed, size: sw * 0.025),
            SizedBox(height: pad * 0.8),
            Text(
              'SYSTEM ERROR',
              style: GoogleFonts.poppins(
                color: cRed,
                fontSize: sw * 0.010,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: cRed.withOpacity(0.6), blurRadius: 8)],
              ),
            ),
            SizedBox(height: pad * 0.4),
            Text(
              _errorMessage ?? 'Unknown error',
              style: GoogleFonts.poppins(
                  color: isLight ? theme.txtSecondary : Colors.white70,
                  fontSize: sw * 0.0072),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: pad * 1.2),
            GestureDetector(
              onTap: _fetchAndBuild,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: pad * 1.2, vertical: pad * 0.5),
                decoration: BoxDecoration(
                  color: cCyan.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(sw * 0.003),
                  border: Border.all(
                      color: cCyan.withOpacity(0.5), width: sw * 0.0008),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: cCyan, size: sw * 0.012),
                    SizedBox(width: pad * 0.4),
                    Text(
                      'RETRY',
                      style: GoogleFonts.poppins(
                        color: cCyan,
                        fontSize: sw * 0.0072,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isWide = sw > 900;
    final gap = sw * 0.008;

    // Page scrolls (rather than clamping the breakdown table to whatever's
    // left of the viewport) so a table with more rows than fit on screen
    // grows downward instead of needing internal scrolling — internal
    // scrolling is exactly what caused rows to be silently missing from the
    // downloaded PDF, since RepaintBoundary.toImage() only captures what's
    // actually laid out, not content scrolled out of a bounded viewport.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Breadcrumb ──
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
            child: Text(
              'Dashboard/Bill Simulator',
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 12,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
            child: Text(
              _categoryName.isNotEmpty
                  ? '$_categoryName Bill Simulator'
                  : 'Bill Simulator',
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Poppins',
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
          ),
          SizedBox(height: gap),

          // ── Filter bar ──
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10),
            child: Row(
              children: [
                // Dropdown lists the registered TNB meters (TNB Meter Setting);
                // falls back to the plant filter when no meter is registered.
                if (_activeMeters.isNotEmpty)
                  _buildCyberpunkDropdown(
                    context: context,
                    value: _selectedMeterId,
                    options: (() {
                      _restoreFiltersOnce();
                      return _activeMeters.map((m) => m.id).toList();
                    })(),
                    hint: 'TNB Meter',
                    width: 260,
                    labelBuilder: (id) {
                      final m =
                          _activeMeters.where((m) => m.id == id).firstOrNull;
                      return m != null ? _meterLabelFor(m) : id;
                    },
                    onChanged: _onMeterChanged,
                  )
                else
                  _buildCyberpunkDropdown(
                    context: context,
                    value: selectedPlant == 'All' ? null : selectedPlant,
                    options: _plantOptions.where((o) => o != 'All').toList(),
                    hint: 'Plant',
                    width: 200,
                    onChanged: (val) => _onPlantChanged(val ?? 'All'),
                  ),
                if (_selectedMeterId != null || selectedPlant != 'All') ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (_selectedMeterId != null) {
                        _onMeterChanged(null);
                      } else {
                        _onPlantChanged('All');
                      }
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_rounded,
                              color: Colors.redAccent, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Header (fixed height) ──
          TnbHeaderCard(
            headerData: TnbHeaderData(
              title: 'TNB E3 BILL SIMULATOR',
              subtitle: selectedPlant != 'All'
                  ? '$selectedPlant - Enterprise Energy Management'
                  : 'Enterprise Energy Management',
              accrualLabel: 'CURRENT MONTH ACCRUAL (MTD)',
              accrualAmount: _accrualAmount,
              categoryName: _categoryName,
            ),
            onRefresh: _fetchAndBuild,
            lastUpdated: _lastUpdated,
            onDownload: _downloadBillPdf,
            isGenerating: _isGeneratingPdf,
          ),
          SizedBox(height: gap),

          // ── Main content ──
          // TnbFooter is nested inside this RepaintBoundary (rather than
          // sitting after it) so the downloaded PDF, which only screenshots
          // this boundary, actually includes the footer instead of silently
          // dropping it.
          RepaintBoundary(
            key: _billBoundaryKey,
            // Without an opaque background here, the areas not covered by
            // cards/table content paint as transparent, which the exported
            // PDF then flattens to plain white instead of the app's theme —
            // same fix as the RepaintBoundary in md_insight_report_widget.
            child: Container(
              color: FlutterFlowTheme.of(context).primaryBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // IntrinsicHeight (rather than Expanded filling leftover
                  // viewport space) sizes this row to the breakdown table's
                  // natural content height and stretches TnbSummaryCards to
                  // match — the table can now grow past the viewport (the
                  // page itself scrolls) instead of clipping rows internally.
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: TnbBreakdownTable(
                              items: _breakdownItems,
                              totalBeforeRebates: _totalBeforeRebates,
                              categoryName: _categoryName,
                            ),
                          ),
                          SizedBox(width: gap),
                          Expanded(
                            flex: 2,
                            child: TnbSummaryCards(
                              cycleEffectiveDate: _cycleEffectiveDate,
                              pfValue: _pfValue,
                              tier1Threshold: _tier1Threshold,
                              tier2Trigger: _tier2Trigger,
                              solarMapped: _solarMapped,
                              solarPeakKwh: _solarPeakKwh,
                              solarOffPeakKwh: _solarOffPeakKwh,
                              solarPeakAvoidedCost: _solarPeakAvoidedCost,
                              solarOffPeakAvoidedCost: _solarOffPeakAvoidedCost,
                              meterLabel: _selectedMeter != null
                                  ? _meterLabelFor(_selectedMeter!)
                                  : '',
                              dataSource: _dataSourceLabel,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TnbBreakdownTable(
                          items: _breakdownItems,
                          totalBeforeRebates: _totalBeforeRebates,
                          categoryName: _categoryName,
                        ),
                        SizedBox(height: gap),
                        // TnbSummaryCards divides its height across 3 cards
                        // internally via Expanded, so — stacked below the
                        // table rather than stretched beside it — it still
                        // needs IntrinsicHeight to get a concrete height to
                        // divide instead of the unbounded height the page's
                        // outer SingleChildScrollView would otherwise give it.
                        IntrinsicHeight(
                          child: TnbSummaryCards(
                            cycleEffectiveDate: _cycleEffectiveDate,
                            pfValue: _pfValue,
                            tier1Threshold: _tier1Threshold,
                            tier2Trigger: _tier2Trigger,
                            solarMapped: _solarMapped,
                            solarPeakKwh: _solarPeakKwh,
                            solarOffPeakKwh: _solarOffPeakKwh,
                            solarPeakAvoidedCost: _solarPeakAvoidedCost,
                            solarOffPeakAvoidedCost: _solarOffPeakAvoidedCost,
                            meterLabel: _selectedMeter != null
                                ? _meterLabelFor(_selectedMeter!)
                                : '',
                            dataSource: _dataSourceLabel,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: gap),
                  // ── Daily Grid Import Cost chart — sits inside this same
                  // RepaintBoundary as the breakdown table/summary cards
                  // above, so the downloaded PDF (a screenshot of the whole
                  // boundary) picks it up automatically with no extra work
                  // in TnbE3BillSimulatorPdfExporter.
                  _buildDailyCostChartPanel(context),
                  SizedBox(height: gap),
                  TnbFooter(dataSource: _dataSourceLabel),
                ],
              ),
            ),
          ),

          SizedBox(height: gap * 0.5),
        ],
      ),
    );
  }

  /// Daily Grid Import Cost · Power Factor Trend chart — same TblChartPanel
  /// TnbBillDataLoggerWidget uses, fed by [_dailyEntries] (already filtered
  /// to the current calendar month in [_fetchAndBuild], 1st day through the
  /// last day of the month, rather than a rolling day-count window).
  Widget _buildDailyCostChartPanel(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    const cCyan = Color(0xFF00E5FF);
    const cOffPeak = Color(0xFF00BFA5);
    const cPeak = Color(0xFFFF6D00);
    const cAmber = Color(0xFFFFC107);
    final now = DateTime.now();
    final monthLabel = '${_monthAbbrev[(now.month - 1).clamp(0, 11)]} ${now.year}';

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  theme.secondaryBackground.withOpacity(0.97),
                  theme.primaryBackground.withOpacity(0.97),
                ]
              : [
                  const Color(0xFF0E2040).withOpacity(0.92),
                  const Color(0xFF07101F).withOpacity(0.96),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cCyan.withOpacity(0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: cCyan, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Grid Import Cost · Power Factor Trend ($monthLabel)',
                style: GoogleFonts.poppins(
                  color: isLight ? theme.txtPrimary : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const TblLegendDot(color: cOffPeak, label: 'Off-Peak cost'),
              const SizedBox(width: 12),
              const TblLegendDot(color: cPeak, label: 'Peak cost'),
              const SizedBox(width: 12),
              const TblLegendDot(color: cAmber, label: 'Power factor'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TblChartPanel(
              entries: _dailyEntries,
              peakRate: _peakRate,
              offPeakRate: _offPeakRate,
              tier1Threshold: _tier1Threshold,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen scrim shown while [_downloadBillPdf] is capturing/encoding
  /// the report — that work briefly blocks the UI thread, so this at least
  /// gives clear "this is working" feedback instead of the page just going
  /// unresponsive with no explanation. Same treatment as MD Insight Report's
  /// loading overlay.
  Widget _pdfLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1B33),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 180,
                  height: 6,
                  child: LinearProgressIndicator(
                    value: _pdfProgress,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _pdfStatus,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This may take a few seconds — please wait.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Captures the on-screen breakdown table + summary cards (the
  /// [RepaintBoundary]-wrapped "Main content" section, not the header/filter
  /// controls) as a high-res PNG and hands it to
  /// [TnbE3BillSimulatorPdfExporter] so the downloaded PDF is a pixel-faithful
  /// copy of what's currently showing.
  Future<void> _downloadBillPdf() async {
    setState(() {
      _isGeneratingPdf = true;
      _pdfStatus = 'Capturing report…';
      _pdfProgress = 0.1;
    });
    // The setState above dirties the download button's spinner, which lives
    // outside this RepaintBoundary but still shares a frame with it — wait
    // for the frame to complete before calling toImage() so no paint is
    // still pending (mirrors MdInsightReportWidget._downloadReport).
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary = _billBoundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);

      setState(() {
        _pdfStatus = 'Encoding image…';
        _pdfProgress = 0.4;
      });
      await WidgetsBinding.instance.endOfFrame;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      debugPrint(
          'TnbE3BillSimulator: captured ${image.width}x${image.height}px, ${pngBytes.lengthInBytes} bytes');

      setState(() {
        _pdfStatus = 'Building PDF…';
        _pdfProgress = 0.7;
      });
      await WidgetsBinding.instance.endOfFrame;

      final plantLabel = _selectedMeter != null
          ? _meterLabelFor(_selectedMeter!)
          : (selectedPlant != 'All' ? selectedPlant : '');

      await TnbE3BillSimulatorPdfExporter.exportImage(
        categoryName: _categoryName,
        plantLabel: plantLabel,
        accrualAmount: _accrualAmount,
        generatedLabel: _lastUpdated.isNotEmpty ? _lastUpdated : '-',
        pngBytes: pngBytes,
        pixelWidth: image.width,
        pixelHeight: image.height,
      );
      if (mounted) setState(() => _pdfProgress = 1.0);
    } catch (e) {
      debugPrint('TnbE3BillSimulator: error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate PDF.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _pdfProgress = 0.0;
        });
      }
    }
  }
}
