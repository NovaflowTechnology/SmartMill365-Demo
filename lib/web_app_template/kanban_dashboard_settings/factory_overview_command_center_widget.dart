import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/pecc_live_data.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/services/group_pins_service.dart';

/// 1:1 Factory Overview — the Energy Command Center for one Lot 237 block.
///
/// Serves Block A, B and C. Everything that names a block comes from
/// [lotName] and from the saved configuration, so the same screen sets up any
/// of them; only the filters differ.
class FactoryOverviewCommandCenterWidget extends StatefulWidget {
  final String lotName;
  final String orgName;
  final String orgSubLabel;
  final String bgImageUrl;
  final PeccLiveData? liveData;
  final Map<String, String> widgetLabels;
  final Map<String, dynamic>? ecConfig;
  final int dataTick;
  /// Parent reloads PECC config after settings save.
  final VoidCallback? onConfigChanged;

  const FactoryOverviewCommandCenterWidget({
    super.key,
    required this.lotName,
    this.orgName = '',
    this.orgSubLabel = '',
    this.bgImageUrl = '',
    this.liveData,
    this.widgetLabels = const {},
    this.ecConfig,
    this.dataTick = 0,
    this.onConfigChanged,
  });

  @override
  State<FactoryOverviewCommandCenterWidget> createState() =>
      _FactoryOverviewCommandCenterWidgetState();
}

class _FactoryOverviewCommandCenterWidgetState
    extends State<FactoryOverviewCommandCenterWidget>
    with SingleTickerProviderStateMixin {
  // ── Exact colours from screenshot ──────────────────────────────────────────
  static const _bg        = Color(0xFF040A18);
  static const _border    = Color(0xFF132036);
  static const _cyan      = Color(0xFF00E5FF);
  static const _blue      = Color(0xFF00B8FF);
  static const _yellow    = Color(0xFFF59E0B);
  static const _red       = Color(0xFFEF4444);
  static const _green     = Color(0xFF22C55E);
  static const _orange    = Color(0xFFF97316);
  static const _sub       = Color(0xFF8FA3BC);
  static const _white     = Colors.white;

  int    _layerIdx      = 0;
  String _period        = 'Daily';
  late AnimationController _flowAnim;
  Timer? _clockTimer;
  Timer? _liveRefresh;

  /// One live load at a time. _loadLiveData issues three sequential waves of
  /// HTTP calls across every mapped meter, each with a 10-25s timeout, so a
  /// slow load easily outruns the 60s refresh tick. It is also called from
  /// initState, didUpdateWidget and the manual refresh button. Without this
  /// guard those overlap and every pending response is retained at once,
  /// which is what made the tab's memory climb on the command centres.
  bool _liveInFlight = false;
  /// Ticks once a second for the header clock only. It used to be plain state
  /// updated through setState, which rebuilt and repainted the entire command
  /// centre - floor map, charts, pie and badges - sixty times a minute just to
  /// move the clock. Only the clock Text listens to this now.
  final ValueNotifier<DateTime> _now = ValueNotifier(DateTime.now());
  final ScrollController _consumersScroll = ScrollController();
  final ScrollController _legendScroll = ScrollController();

  /// Live readings keyed by real device_id (no mock catalog).
  final Map<String, double> _powerKw = {};
  final Map<String, double> _energyKwh = {};
  final Map<String, double> _peakKw = {}; // period peak (from 24h MD buckets)
  final Map<String, double> _currentA = {};
  final Map<String, double> _pf = {};
  final Map<String, double> _demandKva = {};
  final Map<String, String> _deviceNames = {};
  final Map<String, String> _settingLabels = {};
  /// Demand Forecast curve (hour-of-day 0..24 → kW), built from power-load-24h.
  List<FlSpot> _forecastSpots = const [];
  double _forecastPeakKw = 0;
  String _forecastPeakWindow = '—';
  bool _liveLoading = false;
  String? _liveError;
  int? _touchedPieIndex;
  bool _realtimeExtrasLoaded = false;

  /// ST Malaysia-style default; used only for Carbon layer estimate.
  static const double _carbonKgPerKwh = 0.574;

  static const _layers = [
    (Icons.flash_on, 'Power (kW)', 'kW'),
    (Icons.battery_charging_full, 'Energy (kWh)', 'kWh'),
    (Icons.electric_bolt, 'Current (A)', 'A'),
    (Icons.speed, 'PF', ''),
    (Icons.swap_vert, 'Demand (kVA)', 'kVA'),
    (Icons.eco, 'Carbon (kgCO₂e)', 'kg'),
  ];

  // Floor badge anchors (fractions of the floor map), one per machine. Six
  // machines in two rows of three, matching the Lot 237 B floor plan: the
  // previous 4+5 grid belonged to a different layout and left badges sitting
  // on gangways instead of machines.
  static const _machineAnchors = [
    // Back row
    (0.29, 0.30),
    (0.57, 0.30),
    (0.88, 0.30),
    // Front row
    (0.27, 0.78),
    (0.59, 0.78),
    (0.90, 0.78),
  ];

  // A pin on the group map is a lot: the bottom strip lists whichever pins
  // currently exist there, so a new one shows up here with no code change —
  // same reasoning as the side nav. "Lot 237 B"/"Lot 237C" aren't pins of
  // their own (Lot 237 itself is the pin; the blocks are inside it), so they
  // stay fixed at the end, same as before this list was made dynamic.
  static const _fixedBlockLots = ['Lot 237 B', 'Lot 237C'];
  List<GroupPin> _groupPins = const [];
  List<String> get _lots => [
        for (final p in _groupPins)
          if (!_sameLot(p.displayName, 'Lot 237')) p.displayName,
        ..._fixedBlockLots,
      ];

  Future<void> _fetchGroupPins() async {
    final pins = await GroupPinsService.fetchPins();
    if (!mounted) return;
    setState(() => _groupPins = pins);
  }

  static const _piePalette = <Color>[
    Color(0xFF00E5FF), Color(0xFF3EE87F), Color(0xFFFF8C1A), Color(0xFFC04FF0),
    Color(0xFFF0E02C), Color(0xFFE5544B), Color(0xFF2FBFA8), Color(0xFF4A7EF0),
    Color(0xFFFF3D8B), Color(0xFF00D4A0), Color(0xFFFFB03A), Color(0xFFA855F7),
    Color(0xFF38BDF8), Color(0xFF84CC16), Color(0xFFFB7185), Color(0xFF64748B),
  ];

  String get _apiPeriod {
    switch (_period.toLowerCase()) {
      case 'monthly':
        return 'monthly';
      case 'yearly':
        return 'yearly';
      default:
        return 'daily';
    }
  }

  Map<String, dynamic>? get _cardsRoot {
    final top = widget.ecConfig?['cards'];
    if (top is Map && top.isNotEmpty) {
      return Map<String, dynamic>.from(top);
    }
    final branding = widget.ecConfig?['branding'];
    if (branding is Map) {
      final fo = branding['factoryOverview'];
      if (fo is Map && fo['cards'] is Map) {
        final cards = Map<String, dynamic>.from(fo['cards'] as Map);
        if (cards.isNotEmpty) return cards;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _groupsRoot {
    final top = widget.ecConfig?['groups'];
    if (top is List && top.isNotEmpty) {
      return top.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final branding = widget.ecConfig?['branding'];
    if (branding is Map) {
      final fo = branding['factoryOverview'];
      if (fo is Map && fo['groups'] is List) {
        final groups = (fo['groups'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (groups.isNotEmpty) return groups;
      }
    }
    return const [];
  }

  Map<String, dynamic> _foCard(String key) {
    final raw = _cardsRoot?[key];
    return raw is Map<String, dynamic> ? raw : (raw is Map ? Map<String, dynamic>.from(raw) : {});
  }

  List<String> _resolveCardDevices(String cardKey) {
    // 1. Check for explicitly mapped devices from Factory Overview Setting sections (consumer[0]..consumer[5]).
    final sectionDevices = <String>{};
    for (final sec in widget.ecConfig?['sections'] as List<dynamic>? ?? []) {
      for (final w in (sec as Map)['widgets'] as List<dynamic>? ?? []) {
        final key = (w as Map)['key']?.toString() ?? '';
        final device = w['selectedDevice']?.toString().trim() ?? '';
        if (device.isEmpty) continue;
        if (cardKey == 'consumers' && key.startsWith('consumer')) {
          sectionDevices.add(device);
        } else if (cardKey == 'distribution' &&
            (key.startsWith('consumer') || key.startsWith('summary'))) {
          sectionDevices.add(device);
        } else if (cardKey == 'summary' && key.startsWith('summary')) {
          sectionDevices.add(device);
        } else if ((cardKey == 'forecast' || cardKey == 'cost') &&
            (key.startsWith('forecast') || key.startsWith('cost') || key.startsWith('summary'))) {
          sectionDevices.add(device);
        }
      }
    }

    // If explicit section mappings exist for this card type, strictly use those mapped devices.
    if (sectionDevices.isNotEmpty) {
      return sectionDevices.toList()..sort();
    }

    // 2. Fallback: if no section widgets are mapped, resolve devices from meter group (e.g. g_all).
    final c = _foCard(cardKey);
    final groups = _groupsRoot;
    final gid = c['group']?.toString() ?? 'g_all';
    Map<String, dynamic>? g;
    for (final x in groups) {
      if (x['id']?.toString() == gid) {
        g = x;
        break;
      }
    }
    g ??= groups.isNotEmpty ? groups.first : null;
    final ids = <String>{
      for (final m in (g?['members'] as List<dynamic>? ?? []))
        if (m.toString().trim().isNotEmpty) m.toString().trim(),
    };
    for (final id in (c['include'] as List<dynamic>? ?? [])) {
      final s = id.toString().trim();
      if (s.isNotEmpty) ids.add(s);
    }
    for (final id in (c['exclude'] as List<dynamic>? ?? [])) {
      ids.remove(id.toString().trim());
    }

    return ids.toList()..sort();
  }

  void _applySettingLabels() {
    _settingLabels.clear();
    final sections = widget.ecConfig?['sections'];
    if (sections is List) {
      for (final sec in sections) {
        if (sec is! Map) continue;
        final widgets = sec['widgets'];
        if (widgets is List) {
          for (final w in widgets) {
            if (w is! Map) continue;
            final device = w['selectedDevice']?.toString().trim() ?? '';
            final label = w['label']?.toString().trim() ?? '';
            final looksTechnical =
                RegExp(r'^[A-Za-z_]+\[\d+\]$').hasMatch(label);
            if (device.isNotEmpty &&
                label.isNotEmpty &&
                !looksTechnical) {
              _settingLabels[device] = label;
            }
          }
        }
      }
    }
  }

  String _nameOf(String id) {
    final customLabel = _settingLabels[id]?.trim() ?? '';
    if (customLabel.isNotEmpty) return customLabel;

    final equipName = _deviceNames[id]?.trim() ?? '';
    if (equipName.isNotEmpty) return equipName;

    return id;
  }

  double _kwOf(String id) => _powerKw[id] ?? 0;
  double _kwhOf(String id) => _energyKwh[id] ?? 0;
  double _ampsOf(String id) => _currentA[id] ?? 0;
  double _pfOf(String id) => _pf[id] ?? 0;
  double _kvaOf(String id) {
    final direct = _sanitizeKw(_demandKva[id] ?? 0);
    if (direct > 0) return direct;
    final kw = _kwOf(id);
    final pf = _pfOf(id);
    if (kw > 0 && pf > 0.05) return kw / pf;
    return kw;
  }
  double _carbonOf(String id) => _kwhOf(id) * _carbonKgPerKwh;

  /// Active ENERGY LAYER metric for a meter (floor badges + top consumers).
  double _layerValueOf(String id) {
    switch (_layerIdx) {
      case 1:
        return _kwhOf(id);
      case 2:
        return _ampsOf(id);
      case 3:
        return _pfOf(id);
      case 4:
        return _kvaOf(id);
      case 5:
        return _carbonOf(id);
      default:
        return _kwOf(id);
    }
  }

  String get _layerUnit => _layers[_layerIdx].$3;

  String _fmtLayerValue(double v) {
    if (_layerIdx == 3) return v > 0 ? v.toStringAsFixed(3) : '—';
    if (_layerIdx == 1 || _layerIdx == 5) {
      return v > 0 ? _fmtNum(v, decimals: v >= 1000 ? 0 : 1) : '—';
    }
    return v > 0 ? v.toStringAsFixed(1) : '—';
  }

  Color _rankColor(int i) {
    if (i == 0) return _red;
    if (i == 1) return _orange;
    if (i == 2) return _yellow;
    if (i < 5) return _cyan;
    return _blue;
  }

  /// Top Energy Consumers + Energy Distribution both rank by kWh so they tally.
  /// Top Energy Consumers + Energy Distribution both rank by kWh so they tally.
  /// Tuple: (name, formattedVal, barFraction, color, deviceId)
  List<(String, String, double, Color, String)> _rankedDevices({required int topN}) {
    final ids = _resolveCardDevices('consumers');
    final rows = <(String, String, double)>[];
    for (final id in ids) {
      rows.add((id, _nameOf(id), _kwhOf(id)));
    }
    rows.sort((a, b) => b.$3.compareTo(a.$3));
    final positive = rows.where((r) => r.$3 > 0).toList();
    final use = positive.isNotEmpty ? positive : rows;
    final maxV = use.isEmpty ? 1.0 : math.max(use.first.$3, 0.001);
    final take = use.take(topN.clamp(1, 30)).toList();
    return [
      for (var i = 0; i < take.length; i++)
        (
          take[i].$2,
          take[i].$3 > 0
              ? '${_fmtNum(take[i].$3, decimals: take[i].$3 >= 1000 ? 0 : 1)} kWh'
              : '—',
          (take[i].$3 / maxV).clamp(0.05, 1.0),
          _rankColor(i),
          take[i].$1,
        ),
    ];
  }

  List<(String, String, double, Color)> _distributionSlicesFromConfig() {
    final c = _foCard('distribution');
    final legendN = (c['legendN'] as num?)?.toInt() ?? 14;
    // Prefer distribution panel meters; if empty, reuse consumers so pie matches.
    var ids = _resolveCardDevices('distribution');
    if (ids.isEmpty) ids = _resolveCardDevices('consumers');
    final rows = <(String, double)>[];
    for (final id in ids) {
      final kwh = _kwhOf(id);
      if (kwh > 0) rows.add((id, kwh));
    }
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    final total = rows.fold<double>(0, (s, e) => s + e.$2);
    if (total <= 0) return const [];
    final top = rows.take(legendN.clamp(0, 30)).toList();
    final shown = top.fold<double>(0, (s, e) => s + e.$2);
    final other = total - shown;
    final out = <(String, String, double, Color)>[
      for (var i = 0; i < top.length; i++)
        (
          top[i].$1,
          '${((top[i].$2 / total) * 100).toStringAsFixed(1)}%',
          top[i].$2,
          _piePalette[i % _piePalette.length],
        ),
    ];
    if (other > 0.01 && legendN < rows.length) {
      out.add((
        'Other',
        '${((other / total) * 100).toStringAsFixed(1)}%',
        other,
        const Color(0xFF64748B),
      ));
    }
    return out;
  }

  /// Floor bubbles follow the active ENERGY LAYER tab.
  /// Tuple: (x, y, valueText, color, unit, deviceName, deviceId)
  /// Where each machine sits on the centre picture, from configuration.
  ///
  /// Keyed by device, because a badge belongs to a machine rather than to its
  /// rank — ordering by consumption moves badges around, and the picture does
  /// not. Anything unset falls back to the built-in anchors, so an untouched
  /// floor map is unchanged.
  Map<String, (double, double)> get _configuredMachinePositions {
    final out = <String, (double, double)>{};
    for (final sec in widget.ecConfig?['sections'] as List<dynamic>? ?? []) {
      for (final w in (sec as Map)['widgets'] as List<dynamic>? ?? []) {
        final m = w as Map;
        final device = m['selectedDevice']?.toString().trim() ?? '';
        if (device.isEmpty) continue;
        final x = double.tryParse(m['xPct']?.toString() ?? '');
        final y = double.tryParse(m['yPct']?.toString() ?? '');
        if (x == null || y == null) continue;
        out[device] = ((x / 100).clamp(0.0, 1.0), (y / 100).clamp(0.0, 1.0));
      }
    }
    return out;
  }

  /// The display name configured for each machine, keyed by device.
  ///
  /// The floor badge leads with this rather than the ranking, because a name
  /// tells an operator which machine they are looking at and "Top #1" does not.
  /// Falls back to the master facility name when a machine has no label set.
  Map<String, String> get _configuredMachineNames {
    final out = <String, String>{};
    for (final sec in widget.ecConfig?['sections'] as List<dynamic>? ?? []) {
      for (final w in (sec as Map)['widgets'] as List<dynamic>? ?? []) {
        final key = (w as Map)['key']?.toString() ?? '';
        if (!key.startsWith('consumer')) continue;
        final device = w['selectedDevice']?.toString().trim() ?? '';
        final label = w['label']?.toString().trim() ?? '';
        // Technical keys are not names — consumer[0] on a badge helps nobody.
        final technical = RegExp(r'^[A-Za-z_]+\[\d+\]$').hasMatch(label);
        if (device.isEmpty || label.isEmpty || technical) continue;
        out[device] = label;
      }
    }
    return out;
  }

  /// Machines whose configured cards include Max Demand.
  ///
  /// Read from the saved configuration, so this follows the settings screen
  /// rather than a second list that would have to be kept in step with it.
  List<String> get _devicesShowingMaxDemand {
    final out = <String>[];
    _configuredMachineMetrics.forEach((device, rows) {
      if (device.isEmpty) return;
      for (final r in rows) {
        if (r['metricKey']?.toString() == 'max_demand') {
          out.add(device);
          return;
        }
      }
    });
    return out;
  }

  /// Cards configured for each machine, keyed by device.
  ///
  /// Same shape the map pins use, so a machine and a site are configured the
  /// same way. Empty for a machine nobody has set up, and the badge then keeps
  /// the single value it always showed.
  Map<String, List<Map<String, dynamic>>> get _configuredMachineMetrics {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final sec in widget.ecConfig?['sections'] as List<dynamic>? ?? []) {
      for (final w in (sec as Map)['widgets'] as List<dynamic>? ?? []) {
        final m = w as Map;
        final device = m['selectedDevice']?.toString().trim() ?? '';
        final rows = (m['metrics'] as List<dynamic>?) ?? const [];
        if (device.isEmpty || rows.isEmpty) continue;
        out[device] = rows
            .whereType<Map>()
            .map((r) => r.cast<String, dynamic>())
            .where((r) => (r['metricKey']?.toString() ?? '').isNotEmpty)
            .toList();
      }
    }
    return out;
  }

  List<(double, double, String, Color, String, String, String)> _liveMachineBadges() {
    final ids = _resolveCardDevices('consumers');
    final rows = <(String, double)>[
      for (final id in ids) (id, _layerValueOf(id)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    // Every mapped machine keeps its badge even when the active layer reads
    // zero. Dropping zero-value rows made machines disappear from the floor map
    // whenever the selected layer had no data for them — so switching to
    // Power (kW) showed 4 badges while the right panel listed 6 by energy.
    // A machine that is mapped but idle should read 0, not vanish.
    final use = rows;
    final unit = _layerUnit.isEmpty ? 'PF' : _layerUnit;
    final placed = _configuredMachinePositions;
    // Every mapped machine, not just as many as there are built-in anchors.
    // Machines can now be added from settings, and one past the sixth had no
    // anchor to sit on, so it never appeared. Anything past the built-ins is
    // parked in the middle until someone gives it a position.
    return [
      for (var i = 0; i < use.length; i++)
        (
          placed[use[i].$1]?.$1 ??
              (i < _machineAnchors.length ? _machineAnchors[i].$1 : 0.5),
          placed[use[i].$1]?.$2 ??
              (i < _machineAnchors.length ? _machineAnchors[i].$2 : 0.5),
          _fmtLayerValue(use[i].$2),
          _rankColor(i),
          unit,
          _shortName(_configuredMachineNames[use[i].$1] ?? _nameOf(use[i].$1)),
          use[i].$1,
        ),
    ];
  }

  /// Whether two lot names refer to the same place despite different spellings.
  static bool _sameLot(String a, String b) {
    String key(String v) => v
        .toLowerCase()
        .replaceAll('block', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return key(a).isNotEmpty && key(a) == key(b);
  }

  /// Truncate long facility names for floor badges.
  String _shortName(String name) {
    final t = name.trim();
    if (t.length <= 18) return t;
    return '${t.substring(0, 16)}…';
  }

  @override
  void initState() {
    super.initState();
    _flowAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _now.value = DateTime.now();
    });
    _loadLiveData();
    _liveRefresh = Timer.periodic(const Duration(seconds: 60), (_) => _loadLiveData());
  }

  @override
  void didUpdateWidget(covariant FactoryOverviewCommandCenterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ecConfig != widget.ecConfig || oldWidget.dataTick != widget.dataTick) {
      _loadLiveData();
    }
  }

  @override
  void dispose() {
    _flowAnim.dispose();
    _clockTimer?.cancel();
    _liveRefresh?.cancel();
    _now.dispose();
    _consumersScroll.dispose();
    _legendScroll.dispose();
    super.dispose();
  }

  Future<void> _loadLiveData() async {
    if (_liveInFlight) return;
    _liveInFlight = true;
    try {
      await _loadLiveDataInner();
    } finally {
      _liveInFlight = false;
    }
  }

  Future<void> _loadLiveDataInner() async {
    final ids = <String>{
      ..._resolveCardDevices('consumers'),
      ..._resolveCardDevices('distribution'),
      ..._resolveCardDevices('summary'),
      ..._resolveCardDevices('forecast'),
      ..._resolveCardDevices('cost'),
    }.toList();
    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _powerKw.clear();
          _energyKwh.clear();
          _peakKw.clear();
          _currentA.clear();
          _pf.clear();
          _demandKva.clear();
          _forecastSpots = const [];
          _forecastPeakKw = 0;
          _forecastPeakWindow = '—';
          _realtimeExtrasLoaded = false;
          _liveError =
              'No meters mapped — configure Meter Groups / Dashboard Panels in ${widget.lotName} settings';
          _liveLoading = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _liveLoading = true;
        _liveError = null;
        _powerKw.clear();
        _energyKwh.clear();
        _peakKw.clear();
        _currentA.clear();
        _pf.clear();
        _demandKva.clear();
        _realtimeExtrasLoaded = false;
      });
    }

    try {
      await Future.wait([
        _fetchEquipmentNames(),
        _fetchPlantNames(),
        _fetchGroupPins(),
        _fetchEnergyOverview(ids),
        _fetchPowerTimeseries(ids),
      ]);
      _applySettingLabels();
      // Fill gaps for meters missing from overview/timeseries (e.g. VOPM001).
      await Future.wait([
        _fillMissingPower(ids),
        _fillMissingEnergy(ids),
      ]);
      await Future.wait([
        _fetchRealtimeExtras(ids),
        _fetchDemandForecastCurve(_resolveCardDevices('forecast')),
        _fetchPeaksForIds([
          ..._resolveCardDevices('summary'),
          // Machines showing a Max Demand card need their peak fetched too.
          // Driven by the configuration rather than by the machine list, so
          // only the cards someone actually set up cost a request.
          ..._devicesShowingMaxDemand,
        ]),
      ]);
      if (mounted) {
        setState(() {
          _liveLoading = false;
          if (_powerKw.isEmpty && _energyKwh.isEmpty) {
            _liveError = 'No live readings yet for mapped meters';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liveLoading = false;
          _liveError = 'Live data error: $e';
        });
      }
    }
  }

  /// Plant names from the facility master, used to turn the bottom strip into
  /// working links. Loaded rather than hardcoded so a lot that is renamed or
  /// added in General Setting needs no change here.
  List<String> _plantNames = [];

  Future<void> _fetchPlantNames() async {
    try {
      final plants = await FacilityService.getFactories();
      if (!mounted) return;
      setState(() {
        _plantNames = plants
            .map((p) => p['name']?.toString().trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      });
    } catch (_) {
      // The strip simply stays unlinked, which is what it was before.
    }
  }

  /// The plant a strip chip should open, or null when none matches.
  ///
  /// Two passes. The chip and the master rarely spell a block the same way
  /// ("Lot 237 B" against "Lot 237 Block B"), which [_sameLot] already
  /// handles. Failing that, a chip naming a sub-block that is not a plant of
  /// its own — "Lot 53A" — falls back to the lot containing it, because that
  /// is where its dashboard actually lives.
  String? _plantForLot(String lot) {
    for (final name in _plantNames) {
      if (_sameLot(lot, name)) return name;
    }
    final trimmed = lot.trim();
    if (trimmed.isNotEmpty &&
        RegExp(r'[A-Za-z]$').hasMatch(trimmed) &&
        RegExp(r'\d').hasMatch(trimmed)) {
      final parent = trimmed.substring(0, trimmed.length - 1).trim();
      for (final name in _plantNames) {
        if (_sameLot(parent, name)) return name;
      }
    }
    return null;
  }

  Future<void> _fetchEquipmentNames() async {
    // Prefer Master Facility Display Name (meterName / equipmentNameId / machineName) keyed by Device ID (meterId).
    try {
      final facilities = await FacilityService.getFacilities();
      for (final f in facilities) {
        final id = f.meterId.trim();
        final meterName = f.meterName.trim();
        final equipName = f.equipmentNameId.trim();
        final machineName = f.machineName.trim();
        final preferredName = meterName.isNotEmpty && meterName != '-'
            ? meterName
            : equipName.isNotEmpty && equipName != '-'
                ? equipName
                : machineName.isNotEmpty && machineName != '-'
                    ? machineName
                    : '';
        if (id.isNotEmpty && preferredName.isNotEmpty) {
          _deviceNames[id] = preferredName;
        }
      }
    } catch (_) {}
    // Fallback: Equipment Settings name by equipment_id.
    try {
      final equipments = await FacilityService.getEquipments();
      for (final e in equipments) {
        final id = e.equipmentId.trim();
        final name = e.name.trim();
        if (id.isNotEmpty && name.isNotEmpty && name != '-') {
          _deviceNames.putIfAbsent(id, () => name);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchEnergyOverview(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty) return;
    final idSet = ids.map((e) => e.toLowerCase()).toSet();
    final res = await http
        .get(
          Uri.parse('$base/energyOverview/data/$_apiPeriod'),
          headers: AppConfig.headers,
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return;
    final data = json.decode(res.body);
    if (data is! List) return;
    for (final raw in data) {
      if (raw is! Map) continue;
      final id = (raw['device'] ?? raw['device_id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      if (!idSet.contains(id.toLowerCase()) &&
          !ids.any((x) => x.toLowerCase() == id.toLowerCase())) {
        continue;
      }
      final match = ids.firstWhere(
        (x) => x.toLowerCase() == id.toLowerCase(),
        orElse: () => id,
      );
      final energy = _asDouble(raw['total_energy'] ?? raw['energy_kwh'] ?? raw['kwh']);
      if (energy > 0) _energyKwh[match] = energy;
      final label = (raw['device_name'] ?? raw['name'] ?? '').toString().trim();
      // Don't overwrite Master Facility display names with raw IDs / weak API labels.
      if (label.isNotEmpty &&
          label.toLowerCase() != match.toLowerCase() &&
          label.toLowerCase() != id.toLowerCase()) {
        _deviceNames.putIfAbsent(match, () => label);
      }
    }
  }

  Future<void> _fetchPowerTimeseries(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty || ids.isEmpty) return;
    final res = await http
        .get(
          Uri.parse(
            '$base/energyDetailsInfluxDb/timeseries/$_apiPeriod'
            '?machine_ids=${ids.map(Uri.encodeComponent).join(',')}&fields=PeakDemand',
          ),
          headers: AppConfig.headers,
        )
        .timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) return;
    final data = json.decode(res.body);
    if (data is! List) return;
    for (final item in data) {
      if (item is! Map) continue;
      final id = (item['machine_id'] ?? item['device_id'] ?? item['device'] ?? '')
          .toString()
          .trim();
      if (id.isEmpty) continue;
      final match = ids.firstWhere(
        (x) => x.toLowerCase() == id.toLowerCase(),
        orElse: () => id,
      );
      final payload = item['data'];
      double kw = 0;
      if (payload is Map) {
        kw = _asDouble(payload['power_kw'] ?? payload['PeakDemand'] ?? payload['active_power']);
      } else {
        kw = _asDouble(item['power_kw']);
      }
      if (kw > 0) _setPowerKw(match, kw);
    }
  }

  /// Fill missing kW via power-load/current (covers meters absent from PeakDemand batch).
  Future<void> _fillMissingPower(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty) return;
    // Also refresh meters whose PeakDemand feed looks corrupt.
    final missing = ids
        .where((id) => !_isPlausibleKw(_powerKw[id] ?? 0))
        .take(40)
        .toList();
    if (missing.isEmpty) return;
    await Future.wait(missing.map((id) async {
      try {
        final res = await http
            .get(
              Uri.parse(
                '$base/energyDetailsInfluxDb/power-load/current'
                '?deviceId=${Uri.encodeComponent(id)}',
              ),
              headers: AppConfig.headers,
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return;
        final body = json.decode(res.body);
        double kw = 0;
        if (body is Map) {
          kw = _asDouble(body['power_kw'] ?? body['P(kW)'] ?? body['active_power']);
        }
        if (_isPlausibleKw(kw)) {
          _powerKw[id] = kw; // overwrite corrupt PeakDemand
        }
      } catch (_) {}
    }));
  }

  /// Fill missing kWh via energyDetails/data/{id}/{period} when overview misses a meter.
  Future<void> _fillMissingEnergy(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty) return;
    final missing = ids.where((id) => (_energyKwh[id] ?? 0) <= 0).take(40).toList();
    if (missing.isEmpty) return;
    final period = _apiPeriod; // daily | monthly | yearly
    await Future.wait(missing.map((id) async {
      try {
        final res = await http
            .get(
              Uri.parse(
                '$base/energyDetails/data/${Uri.encodeComponent(id)}/$period',
              ),
              headers: AppConfig.headers,
            )
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) return;
        final rows = json.decode(res.body);
        if (rows is! List || rows.isEmpty) return;
        final last = rows.last;
        if (last is! Map) return;
        final kwh = _asDouble(last['value'] ?? last['total_energy'] ?? last['kwh']);
        if (kwh > 0) _energyKwh[id] = kwh;
      } catch (_) {}
    }));
  }

  /// Build Demand Forecast from power-load-24h of forecast-panel meters (summed).
  Future<void> _fetchDemandForecastCurve(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty || ids.isEmpty) {
      _forecastSpots = const [];
      _forecastPeakKw = 0;
      _forecastPeakWindow = '—';
      return;
    }
    // Cap concurrent meter pulls; prefer ones that already have load.
    final ranked = [...ids]..sort((a, b) => _kwOf(b).compareTo(_kwOf(a)));
    final targets = ranked.take(8).toList();

    // hourBucket 0..23 → summed kW across meters (per-meter uses MAX in that hour)
    final byHour = List<double>.filled(24, 0);

    await Future.wait(targets.map((id) async {
      try {
        final res = await http
            .get(
              Uri.parse(
                '$base/energyDetails/power-load-24h/${Uri.encodeComponent(id)}',
              ),
              headers: AppConfig.headers,
            )
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) return;
        final body = json.decode(res.body);
        if (body is! Map) return;
        final data = body['data'];
        if (data is! List) return;
        final deviceByHour = List<double>.filled(24, 0);
        double devicePeak = 0;
        for (final row in data) {
          if (row is! Map) continue;
          // Prefer instantaneous power_kW; max_demand_kW=0 must not block it
          // (Dart `0 ?? x` keeps 0).
          final md = _sanitizeKw(_asDouble(row['max_demand_kW']));
          final pw = _sanitizeKw(
            _asDouble(row['power_kW'] ?? row['power_kw']),
          );
          final kw = md > 0 ? md : pw;
          if (kw > devicePeak) devicePeak = kw;
          final label = (row['time_label'] ?? row['time'] ?? '').toString();
          final hour = _hourFromLabel(label);
          if (hour == null || kw <= 0) continue;
          if (kw > deviceByHour[hour]) deviceByHour[hour] = kw;
        }
        for (var h = 0; h < 24; h++) {
          byHour[h] += deviceByHour[h];
        }
        _setPeakKw(id, devicePeak);
        if (!_isPlausibleKw(_powerKw[id] ?? 0) && data.isNotEmpty) {
          final last = data.last;
          if (last is Map) {
            final kw = _sanitizeKw(
              _asDouble(last['power_kW'] ?? last['max_demand_kW']),
            );
            if (kw > 0) _powerKw[id] = kw;
          }
        }
      } catch (_) {}
    }));

    final spots = <FlSpot>[];
    var peakHour = 0;
    var peakVal = 0.0;
    for (var h = 0; h < 24; h++) {
      final v = byHour[h];
      spots.add(FlSpot(h.toDouble(), v));
      if (v > peakVal) {
        peakVal = v;
        peakHour = h;
      }
    }
    // Close the day at 24:00 with last value for a smooth chart edge.
    if (spots.isNotEmpty) {
      spots.add(FlSpot(24, spots.last.y));
    }

    _forecastSpots = spots;
    _forecastPeakKw = peakVal;
    if (peakVal > 0) {
      final end = (peakHour + 1) % 24;
      String hh(int h) => h.toString().padLeft(2, '0');
      _forecastPeakWindow = '${hh(peakHour)}:00 - ${hh(end)}:00';
    } else {
      _forecastPeakWindow = '—';
    }
  }

  /// Latest / peak kW from power-load-24h for Energy Summary meters.
  Future<void> _fetchPeaksForIds(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty || ids.isEmpty) return;
    // Deduplicated: summary panels and machine cards often name the same
    // meter, and each entry costs a request.
    final targets = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    // Batched rather than fired all at once. A floor map can carry two dozen
    // machines now, and a burst that wide made the whole load wait on its
    // slowest request.
    for (var i = 0; i < targets.length; i += 8) {
      await _fetchPeakBatch(targets.skip(i).take(8).toList());
    }
  }

  Future<void> _fetchPeakBatch(List<String> targets) async {
    final base = AppConfig.dataApiBaseSafe;
    await Future.wait(targets.map((id) async {
      if ((_peakKw[id] ?? 0) > 0 && (_powerKw[id] ?? 0) > 0) return;
      try {
        final res = await http
            .get(
              Uri.parse(
                '$base/energyDetails/power-load-24h/${Uri.encodeComponent(id)}',
              ),
              headers: AppConfig.headers,
            )
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) return;
        final body = json.decode(res.body);
        if (body is! Map) return;
        final data = body['data'];
        if (data is! List || data.isEmpty) return;
        double peak = 0;
        for (final row in data) {
          if (row is! Map) continue;
          final md = _sanitizeKw(_asDouble(row['max_demand_kW']));
          final pw = _sanitizeKw(_asDouble(row['power_kW'] ?? row['power_kw']));
          final kw = md > 0 ? md : pw;
          if (kw > peak) peak = kw;
        }
        _setPeakKw(id, peak);
        if (!_isPlausibleKw(_powerKw[id] ?? 0)) {
          final last = data.last;
          if (last is Map) {
            final kw = _sanitizeKw(
              _asDouble(last['power_kW'] ?? last['max_demand_kW']),
            );
            if (kw > 0) _powerKw[id] = kw;
          }
        }
        final stats = body['statistics'];
        if (stats is Map && (_peakKw[id] ?? 0) <= 0) {
          final pk = _sanitizeKw(_asDouble(
            stats['current_max_demand_kW'] ?? stats['max_demand_kW'],
          ));
          _setPeakKw(id, pk);
        }
      } catch (_) {}
    }));
  }

  int? _hourFromLabel(String label) {
    if (label.isEmpty) return null;
    // "14:00", "14:00:00", "2024-01-01 14:00", "2 PM", etc.
    final m24 = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(label);
    if (m24 != null) {
      final h = int.tryParse(m24.group(1)!);
      if (h != null && h >= 0 && h <= 23) return h;
    }
    final m12 = RegExp(r'(\d{1,2})\s*(AM|PM)', caseSensitive: false).firstMatch(label);
    if (m12 != null) {
      var h = int.tryParse(m12.group(1)!) ?? 0;
      final ap = m12.group(2)!.toUpperCase();
      if (ap == 'PM' && h < 12) h += 12;
      if (ap == 'AM' && h == 12) h = 0;
      if (h >= 0 && h <= 23) return h;
    }
    return null;
  }

  /// Per-meter realtime Current (A), PF, Demand (kVA) for ENERGY LAYER tabs.
  Future<void> _fetchRealtimeExtras(List<String> ids) async {
    final base = AppConfig.dataApiBaseSafe;
    if (base.isEmpty || ids.isEmpty) return;

    // Prefer meters that already have power/energy so badges stay relevant.
    final ranked = [...ids]..sort((a, b) {
        final va = math.max(_kwOf(a), _kwhOf(a));
        final vb = math.max(_kwOf(b), _kwhOf(b));
        return vb.compareTo(va);
      });
    final targets = ranked.take(24).toList();

    await Future.wait(targets.map((id) async {
      try {
        final res = await http
            .get(
              Uri.parse(
                '$base/energyDetailsInfluxDb/realtime/${Uri.encodeComponent(id)}'
                '?fields=${Uri.encodeComponent('P(kW),PF,IA,IB,IC,S(kVA),S(VA),Iavg')}',
              ),
              headers: AppConfig.headers,
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) return;
        final data = json.decode(res.body);
        if (data is! List) return;
        double ia = 0, ib = 0, ic = 0, iavg = 0, pf = 0, sKva = 0, pkW = 0;
        for (final row in data) {
          if (row is! Map) continue;
          final field = (row['field'] ?? '').toString();
          final value = _asDouble(row['value']);
          switch (field) {
            case 'IA':
              ia = value;
              break;
            case 'IB':
              ib = value;
              break;
            case 'IC':
              ic = value;
              break;
            case 'Iavg':
              iavg = value;
              break;
            case 'PF':
              pf = value;
              break;
            case 'P(kW)':
              pkW = value;
              break;
            case 'S(kVA)':
              sKva = value;
              break;
            case 'S(VA)':
              // Some feeds store kVA under S(VA).
              if (value > 0 && value < 50000) sKva = value;
              break;
          }
        }
        final amps = iavg > 0 ? iavg : ((ia + ib + ic) / 3.0);
        if (amps > 0) _currentA[id] = amps;
        if (pf > 0) _pf[id] = pf;
        if (_isPlausibleKw(pkW)) {
          final existing = _powerKw[id] ?? 0;
          if (!_isPlausibleKw(existing)) _powerKw[id] = pkW;
        }
        final sSan = _sanitizeKw(sKva);
        if (sSan > 0) {
          _demandKva[id] = sSan;
        } else if (_isPlausibleKw(pkW) && pf > 0.05) {
          _demandKva[id] = pkW / pf;
        } else if (_isPlausibleKw(_kwOf(id)) && pf > 0.05) {
          _demandKva[id] = _kwOf(id) / pf;
        }
      } catch (_) {}
    }));
    _realtimeExtrasLoaded = true;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  /// Reject corrupt PeakDemand feeds (e.g. DPM046 ≈ 4.2e6 "kW" = Edel leak).
  /// Typical factory meter is well below 20 MW; 50 MW is a hard safety cap.
  static const double _maxPlausibleMeterKw = 50000;

  bool _isPlausibleKw(double kw) => kw > 0 && kw < _maxPlausibleMeterKw;

  double _sanitizeKw(double kw) => _isPlausibleKw(kw) ? kw : 0;

  void _setPowerKw(String id, double kw) {
    final v = _sanitizeKw(kw);
    if (v > 0) _powerKw[id] = v;
  }

  void _setPeakKw(String id, double kw) {
    final v = _sanitizeKw(kw);
    if (v > (_peakKw[id] ?? 0)) _peakKw[id] = v;
  }

  String _fmtNum(double n, {int decimals = 1}) {
    final parts = n.toStringAsFixed(decimals).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return decimals > 0 ? '$whole.${parts[1]}' : whole;
  }

  String _clock(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _header(),
          Expanded(child: _overviewBody()),
          _carousel(),
        ],
      ),
    );
  }

  Widget _overviewBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final sideW = (totalW * 0.145).clamp(228.0, 268.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: sideW, child: _leftPanel()),
              const SizedBox(width: 10),
              Expanded(child: _centerPanel()),
              const SizedBox(width: 10),
              SizedBox(width: sideW, child: _rightPanel()),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF050D1A),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  _breadcrumb('Factory Overview'),
                  _chevron(),
                  InkWell(
                    onTap: () {
                      context.goNamed('KanbanDashboard', queryParameters: const {'plant': 'Lot 237'});
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text('Lot 237',
                          style: GoogleFonts.poppins(
                              color: _cyan, fontSize: 11, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                    ),
                  ),
                  _chevron(),
                  Text(widget.lotName,
                      style: GoogleFonts.poppins(
                          color: _white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 3, height: 20,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: _blue.withOpacity(0.6), blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${widget.lotName.toUpperCase()}  ENERGY OVERVIEW',
                      style: GoogleFonts.poppins(
                          color: _white, fontSize: 19,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () {
                      context.goNamed('KanbanDashboard', queryParameters: const {'plant': 'Lot 237'});
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1A00E5FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _cyan.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 13, color: _cyan),
                          const SizedBox(width: 5),
                          Text('Back to Lot 237',
                              style: GoogleFonts.poppins(color: _white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF071220),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _green.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    _liveDot(),
                    const SizedBox(width: 6),
                    Text('LIVE',
                        style: GoogleFonts.shareTechMono(
                            color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    RepaintBoundary(
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _now,
                        builder: (_, now, __) => Text(_clock(now),
                            style: GoogleFonts.shareTechMono(
                                color: _white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF071220),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _period,
                    dropdownColor: const Color(0xFF0C1B30),
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: _white, size: 16),
                    style: GoogleFonts.poppins(color: _white, fontSize: 12),
                    onChanged: (v) {
                      if (v == null || v == _period) return;
                      setState(() {
                        _period = v;
                        _liveLoading = true;
                        _liveError = null;
                        // Clear so Daily/Monthly/Yearly never flash stale numbers.
                        _powerKw.clear();
                        _energyKwh.clear();
                        _peakKw.clear();
                        _currentA.clear();
                        _pf.clear();
                        _demandKva.clear();
                        _forecastSpots = const [];
                        _forecastPeakKw = 0;
                        _forecastPeakWindow = '—';
                        _realtimeExtrasLoaded = false;
                      });
                      _loadLiveData();
                    },
                    items: ['Daily', 'Monthly', 'Yearly'].map((p) =>
                      DropdownMenuItem(
                        value: p,
                        child: Row(children: [
                          const Icon(Icons.calendar_today, color: _sub, size: 12),
                          const SizedBox(width: 6),
                          Text(p),
                        ]),
                      )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breadcrumb(String t) =>
      Text(t, style: GoogleFonts.poppins(color: _sub, fontSize: 11));

  Widget _chevron() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Icon(Icons.chevron_right, size: 13, color: _sub),
  );

  Widget _liveDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, v, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _green.withOpacity(v),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _green.withOpacity(v * 0.6), blurRadius: 6)],
        ),
      ),
    );
  }

  // ── LEFT PANEL ─────────────────────────────────────────────────────────────
  Widget _leftPanel() {
    return Column(
      children: [
        Expanded(flex: 42, child: _energySummaryCard()),
        const SizedBox(height: 7),
        Expanded(flex: 33, child: _demandForecastCard()),
        const SizedBox(height: 7),
        Expanded(flex: 25, child: _costCard()),
      ],
    );
  }

  Widget _energySummaryCard() {
    final ids = _resolveCardDevices('summary');
    final metrics = (_foCard('summary')['metrics'] as List<dynamic>? ?? const [
      'totalConsumption',
      'currentDemand',
      'peakDemand',
      'estimatedEOD',
    ]).map((e) => e.toString()).toList();

    final totalKwh = ids.fold<double>(0, (s, id) => s + _kwhOf(id));
    final currentKw = ids.fold<double>(0, (s, id) => s + _kwOf(id));
    final peakKw = ids.isEmpty
        ? 0.0
        : ids.map((id) => math.max(_peakKw[id] ?? 0, _kwOf(id)))
            .fold<double>(0, (a, b) => math.max(a, b));
    // Rough EOD estimate from elapsed day fraction when daily.
    final now = DateTime.now();
    final dayFrac = ((now.hour * 60 + now.minute) / (24 * 60)).clamp(0.15, 1.0);
    final eodKwh = _apiPeriod == 'daily' ? totalKwh / dayFrac : totalKwh;

    final rows = <Widget>[];
    void add(String key, IconData icon, String label, String val, String unit) {
      if (metrics.isNotEmpty && !metrics.contains(key)) return;
      rows.add(_kpiRow(icon, label, val, unit, _cyan));
    }

    if (_liveLoading && totalKwh == 0 && currentKw == 0) {
      return _card(
        title: 'ENERGY SUMMARY',
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)),
      );
    }

    add('totalConsumption', Icons.bolt, 'Total Consumption',
        totalKwh > 0 ? _fmtNum(totalKwh, decimals: 3) : '—', 'kWh');
    add('currentDemand', Icons.show_chart, 'Current Demand',
        currentKw > 0 ? _fmtNum(currentKw, decimals: 2) : '—', 'kW');
    add('peakDemand', Icons.stacked_bar_chart, 'Peak Demand',
        peakKw > 0 ? _fmtNum(peakKw, decimals: 2) : '—', 'kW');
    add('estimatedEOD', Icons.access_time, 'Estimated EOD',
        eodKwh > 0 ? _fmtNum(eodKwh, decimals: 0) : '—', 'kWh');

    return _card(
      title: 'ENERGY SUMMARY',
      child: rows.isEmpty
          ? Center(
              child: Text(
                _liveError ?? 'Map devices in Meter Groups / Dashboard Panels',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: _sub, fontSize: 11),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...rows,
                if (!_liveLoading && totalKwh <= 0 && currentKw <= 0)
                  Text(
                    ids.isEmpty
                        ? 'No meters in Energy Summary panel'
                        : 'No readings for: ${ids.take(3).join(', ')}${ids.length > 3 ? '…' : ''}',
                    style: GoogleFonts.poppins(color: _sub, fontSize: 9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
    );
  }

  Widget _kpiRow(IconData icon, String label, String val, String unit, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(color: _sub, fontSize: 10.5),
            ),
          ),
        ]),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  maxLines: 1,
                  text: TextSpan(children: [
                    TextSpan(
                      text: val,
                      style: GoogleFonts.shareTechMono(
                        color: c,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '  $unit',
                      style: GoogleFonts.poppins(color: _sub, fontSize: 10),
                    ),
                  ]),
                ),
              ),
            ),
            SizedBox(
              width: 52,
              height: 18,
              child: _miniLine(c),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniLine(Color c) {
    final spots = _forecastSpots.isNotEmpty
        ? _forecastSpots
            .where((s) => s.x <= 23)
            .map((s) => FlSpot(s.x, s.y))
            .toList()
        : const <FlSpot>[
            FlSpot(0, 1),
            FlSpot(1, 1.2),
            FlSpot(2, 1.1),
            FlSpot(3, 1.4),
            FlSpot(4, 1.3),
            FlSpot(5, 1.5),
          ];
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: c,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
      ],
    ));
  }

  Widget _demandForecastCard() {
    final ids = _resolveCardDevices('forecast');
    final peakTxt = _forecastPeakKw > 0
        ? '${_fmtNum(_forecastPeakKw, decimals: 0)} kW'
        : '—';
    final timeTxt = _forecastPeakKw > 0 ? _forecastPeakWindow : '—';

    return _card(
      title: 'DEMAND FORECAST',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expected Peak', style: GoogleFonts.poppins(color: _sub, fontSize: 9)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(peakTxt,
                          style: GoogleFonts.shareTechMono(
                              color: _white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Time', style: GoogleFonts.poppins(color: _sub, fontSize: 9)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(timeTxt,
                          style: GoogleFonts.shareTechMono(
                              color: _white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(child: _demandChart()),
          if (!_liveLoading && _forecastPeakKw <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                ids.isEmpty
                    ? 'Map meters in Demand Forecast panel'
                    : 'Waiting for 24h load curve…',
                style: GoogleFonts.poppins(color: _sub, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _demandChart() {
    final spots = _forecastSpots.isNotEmpty
        ? _forecastSpots
        : const [FlSpot(0, 0), FlSpot(24, 0)];
    final maxY = spots.map((s) => s.y).fold<double>(0, math.max);
    final yTop = maxY > 0 ? maxY * 1.15 : 100.0;
    final peakX = _forecastPeakKw > 0
        ? spots.reduce((a, b) => a.y >= b.y ? a : b).x
        : -1.0;

    return LineChart(LineChartData(
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: yTop,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: math.max(yTop / 4, 1),
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0x1A4F7BCA), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 14,
            interval: 6,
            getTitlesWidget: (v, _) {
              final labels = {
                0.0: '00:00',
                6.0: '06:00',
                12.0: '12:00',
                18.0: '18:00',
                24.0: '24:00',
              };
              final t = labels[v];
              if (t == null) return const SizedBox.shrink();
              return Text(t, style: GoogleFonts.poppins(color: _sub, fontSize: 8));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _cyan,
          barWidth: 2,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cyan.withOpacity(0.25), _cyan.withOpacity(0.0)],
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) {
              if (peakX >= 0 && (spot.x - peakX).abs() < 0.01 && spot.y > 0) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: _red,
                  strokeWidth: 2,
                  strokeColor: _white,
                );
              }
              return FlDotCirclePainter(radius: 0, color: Colors.transparent);
            },
          ),
        ),
      ],
    ));
  }

  Widget _costCard() {
    final cfg = _foCard('cost');
    final ids = _resolveCardDevices('cost');
    final energy = ids.fold<double>(0, (s, id) => s + _kwhOf(id));
    final tariff = (cfg['tariff'] as num?)?.toDouble() ?? 0.365;
    final currency = cfg['currency']?.toString() ?? 'RM';
    final cost = energy * tariff;
    // Previous period not available yet from this endpoint — hide fake delta.
    final fields = (cfg['fields'] as List<dynamic>? ?? const ['estimatedCost'])
        .map((e) => e.toString())
        .toList();

    return _card(
      title: 'COST ESTIMATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (fields.isEmpty || fields.contains('estimatedCost'))
            _costMetricRow(
              label: 'Estimated Cost (${_period == 'Daily' ? 'EOD' : _period})',
              value: energy > 0 ? '$currency ${_fmtNum(cost, decimals: 2)}' : '—',
              emphasize: true,
            ),
          if (fields.contains('tariffRate') || fields.contains('costPerUnit'))
            _costMetricRow(
              label: 'Tariff / kWh',
              value: '$currency ${tariff.toStringAsFixed(3)}',
            ),
          if (energy <= 0)
            Text(
              _liveLoading ? 'Loading…' : (_liveError ?? 'No energy data for cost devices'),
              style: GoogleFonts.poppins(color: _sub, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _costMetricRow({
    required String label,
    required String value,
    bool emphasize = false,
    String? delta,
    bool deltaUp = false,
  }) {
    final deltaColor = deltaUp ? _red : _green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(color: _sub, fontSize: 9.5),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.shareTechMono(
                    color: emphasize ? _white : _sub,
                    fontSize: emphasize ? 12.5 : 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: deltaColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: deltaColor.withOpacity(0.35)),
                ),
                child: Text(
                  delta,
                  style: GoogleFonts.poppins(
                    color: deltaColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── CENTER PANEL ───────────────────────────────────────────────────────────
  Widget _centerPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ENERGY LAYER label + tabs
        Text('ENERGY LAYER — floor map & Top Consumers',
            style: GoogleFonts.poppins(
                color: _sub, fontSize: 10, letterSpacing: 0.5,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        _layerTabs(),
        const SizedBox(height: 8),
        // Floor plan
        Expanded(child: _floorPlan()),
      ],
    );
  }

  Widget _layerTabs() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF071322),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(_layers.length, (i) {
          final sel = i == _layerIdx;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                if (_layerIdx == i) return;
                setState(() => _layerIdx = i);
                if (!_realtimeExtrasLoaded && (i == 2 || i == 3 || i == 4)) {
                  final ids = _resolveCardDevices('consumers');
                  await _fetchRealtimeExtras(ids);
                  if (mounted) setState(() {});
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: sel
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _yellow.withOpacity(0.22),
                            _yellow.withOpacity(0.06),
                          ],
                        )
                      : null,
                  color: sel ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: sel ? _yellow.withOpacity(0.85) : Colors.transparent,
                    width: sel ? 1.2 : 1,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: _yellow.withOpacity(0.25), blurRadius: 8)]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_layers[i].$1, size: 11, color: sel ? _yellow : _sub),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        _layers[i].$2,
                        style: GoogleFonts.poppins(
                          color: sel ? _white : _sub,
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _floorPlan() {
    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060E1F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _blue.withOpacity(0.55), width: 1.5),
          boxShadow: [
            BoxShadow(color: _blue.withOpacity(0.18), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            children: [
              Positioned.fill(child: _bgOrFallback()),

              // Soft vignette — keep the aerial photo readable.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.95,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.06),
                          Colors.black.withOpacity(0.22),
                        ],
                        stops: const [0.55, 0.82, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // The animated flow lines between machines are gone. They were
              // drawn from badge positions rather than from any real routing,
              // so they suggested a connection the data never described — and
              // once badges can be placed anywhere the lines would join
              // whatever happened to be nearest. Repainting the whole floor
              // every frame was the other cost.

              ...() {
                final badges = _liveMachineBadges();
                if (badges.isEmpty && !_liveLoading) {
                  return [
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          _liveError ?? 'No live machine data',
                          style: GoogleFonts.poppins(color: _sub, fontSize: 12),
                        ),
                      ),
                    ),
                  ];
                }
                return List.generate(badges.length, (i) {
                  final m = badges[i];
                  return Positioned(
                    left: (m.$1 * w - 40).clamp(4.0, w - 90),
                    top: (m.$2 * h - 36).clamp(4.0, h - 70),
                    // Badges no longer pulse. The animation drew the eye to
                    // whichever machine happened to be under it rather than to
                    // whichever mattered, and every badge repainting on every
                    // frame is the kind of continuous redraw this dashboard is
                    // trying to avoid.
                    child: Builder(
                      builder: (_) {
                        const pulse = 1.0;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              final devId = m.$7;
                              if (devId.isNotEmpty) {
                                context.pushNamed(
                                  'EnergyComparison',
                                  queryParameters: {'deviceId': devId},
                                );
                              }
                            },
                            child: _machineBadge(
                              cards: _cardsForDevice(m.$7),
                              m.$3,
                              m.$4,
                              m.$5,
                              name: m.$6,
                              pulse: pulse,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                });
              }(),
            ],
          ),
        ),
      );
    });
  }

  /// Cached provider keyed by URL so the floor map is decoded once rather than
  /// on every rebuild, and isolated behind a RepaintBoundary so repaints of the
  /// live cards above it never repaint the image.
  ImageProvider? _bgProvider;
  String _bgProviderUrl = '';

  Widget _bgOrFallback() {
    final url = widget.bgImageUrl;
    if (url.isEmpty) return _fallbackBg();
    if (_bgProvider == null || _bgProviderUrl != url) {
      _bgProvider = NetworkImage(url);
      _bgProviderUrl = url;
    }
    return RepaintBoundary(
      child: Image(
        image: _bgProvider!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallbackBg(),
      ),
    );
  }

  Widget _fallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF091828), Color(0xFF040C18)],
        ),
      ),
      child: Stack(
        children: [
          // Grid lines for factory floor feel
          CustomPaint(painter: _GridPainter()),
          // Centered factory icon hint
          const Center(
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.factory_outlined, size: 180, color: _cyan),
            ),
          ),
          // Block name watermark
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Text(widget.lotName.toUpperCase(), style: GoogleFonts.shareTechMono(
                  color: _white, fontSize: 52, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _machineBadge(
    String val,
    Color c,
    String unit, {
    String name = '',
    double pulse = 1.0,
    List<({String label, String value, String unit, Color color})> cards =
        const [],
  }) {
    final glow = c.withOpacity(0.22 + 0.22 * pulse);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xEE071420).withOpacity(0.88),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: c.withOpacity(0.85), width: 1.4),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 8 + 4 * pulse),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The name is the badge's headline now. The rank pill that used to
          // sit above it was removed: on a floor map the useful thing is which
          // machine this is, and the ranking is already carried by the badge
          // colour and by the list on the right.
          if (name.isNotEmpty)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: _white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(val, style: GoogleFonts.shareTechMono(
              color: _white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(unit, style: GoogleFonts.poppins(color: c, fontSize: 9)),
          // Cards configured for this machine. Drawn under the headline rather
          // than replacing it, so the badge still leads with the value the
          // floor map is ranked by and the extra readings sit beneath it.
          for (final card in cards) ...[
            const SizedBox(height: 4),
            _badgeCard(card),
          ],
        ],
      ),
    );
  }

  /// A machine's configured cards, resolved to text. The value comes from the
  /// same layer readings the badge itself uses, so a card and the headline can
  /// never disagree about the same machine.
  List<({String label, String value, String unit, Color color})> _cardsForDevice(
      String deviceId) {
    final rows = _configuredMachineMetrics[deviceId];
    if (rows == null || rows.isEmpty) return const [];
    const palette = <String, Color>{
      'cyan': Color(0xFF22D3EE),
      'green': Color(0xFF10B981),
      'amber': Color(0xFFF59E0B),
      'purple': Color(0xFF9A6BFF),
      'red': Color(0xFFFF5D6C),
    };
    const labels = <String, String>{
      'cost': 'Energy Cost',
      'energy': 'Total Energy',
      'max_demand': 'Max Demand',
      'md_charges': 'MD Charges',
      'solar': 'Solar',
      'carbon': 'Carbon',
      'pf': 'Power Factor',
    };
    final out = <({String label, String value, String unit, Color color})>[];
    for (final r in rows) {
      final key = r['metricKey']?.toString() ?? '';
      final typed = r['label']?.toString().trim() ?? '';
      // Read from the per-machine figures this floor map already holds, so a
      // card costs no extra request and cannot disagree with the layer view of
      // the same machine. Cost, solar and MD charges have no per-machine
      // source here and read as a dash rather than borrowing another number.
      double raw;
      String unit;
      int decimals;
      switch (key) {
        case 'energy':
          raw = _kwhOf(deviceId);
          unit = 'kWh';
          decimals = 0;
          break;
        case 'max_demand':
          // The peak from power-load-24h, which is what every other Max Demand
          // figure in the app uses. This used to read live active power, so a
          // card labelled Max Demand showed whatever the meter happened to be
          // drawing — and read as a dash for any meter whose live power the
          // floor map had not resolved, which is how the virtual meters
          // (VDPM003, VDPM004, …) came to look like they had no MD at all.
          // They always had it; nothing ever asked for it.
          raw = _peakKw[deviceId] ?? 0;
          unit = 'kW';
          decimals = 0;
          break;
        case 'carbon':
          raw = _carbonOf(deviceId);
          unit = 'kg';
          decimals = 1;
          break;
        case 'pf':
          raw = _pfOf(deviceId);
          unit = '';
          decimals = 3;
          break;
        default:
          raw = 0;
          unit = '';
          decimals = 0;
      }
      final has = raw > 0;
      out.add((
        label: typed.isNotEmpty ? typed : (labels[key] ?? key),
        value: has ? _fmtNum(raw, decimals: decimals) : '—',
        unit: has ? unit : '',
        color: palette[r['colorKey']?.toString() ?? 'cyan'] ?? palette['cyan']!,
      ));
    }
    return out;
  }

  /// One configured card inside a machine badge: a coloured dot, its label and
  /// its value. Kept to a single line — a floor badge has no room for the
  /// boxed layout the map pins use.
  Widget _badgeCard(({String label, String value, String unit, Color color}) card) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: card.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Text(
            card.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                color: _sub, fontSize: 6.5, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 4),
        Text(card.value,
            style: GoogleFonts.shareTechMono(
                color: _white, fontSize: 9, fontWeight: FontWeight.bold)),
        if (card.unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(card.unit,
              style: GoogleFonts.poppins(color: card.color, fontSize: 6.5)),
        ],
      ],
    );
  }

  // ── RIGHT PANEL ────────────────────────────────────────────────────────────
  Widget _rightPanel() {
    return Column(
      children: [
        Expanded(flex: 42, child: _topConsumers()),
        const SizedBox(height: 8),
        Expanded(flex: 58, child: _energyDistribution()),
      ],
    );
  }

  Widget _consumerRow(
    (String, String, String, double, Color, String) it, {
    bool showBar = true,
  }) {
    return InkWell(
      onTap: () {
        final devId = it.$6;
        if (devId.isNotEmpty) {
          context.pushNamed(
            'EnergyComparison',
            queryParameters: {'deviceId': devId},
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: it.$5.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: it.$5.withOpacity(0.5)),
                  ),
                  child: Text(
                    it.$1,
                    style: GoogleFonts.shareTechMono(
                      color: it.$5,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    it.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: _white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  it.$3,
                  style: GoogleFonts.shareTechMono(
                    color: _white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (showBar) ...[
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: it.$4,
                  minHeight: 3.5,
                  backgroundColor: const Color(0xFF132036),
                  valueColor: AlwaysStoppedAnimation(it.$5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topConsumers() {
    final cfg = _foCard('consumers');
    final topN = (cfg['topN'] as num?)?.toInt() ?? 10;
    final showBar = cfg['showBar'] as bool? ?? true;
    final ranked = _rankedDevices(topN: topN);
    final items = <(String, String, String, double, Color, String)>[
      for (var i = 0; i < ranked.length; i++)
        (
          (i + 1).toString().padLeft(2, '0'),
          ranked[i].$1,
          ranked[i].$2,
          ranked[i].$3,
          ranked[i].$4,
          ranked[i].$5,
        ),
    ];
    return _card(
      title: 'TOP ENERGY CONSUMERS',
      child: items.isEmpty
          ? Center(
              child: Text(
                  'No devices resolved — set Meter Groups / Dashboard Panels in ${widget.lotName} settings',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: _sub, fontSize: 11)),
            )
          : Scrollbar(
              controller: _consumersScroll,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              child: ListView.separated(
                controller: _consumersScroll,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _consumerRow(items[i], showBar: showBar),
              ),
            ),
    );
  }

  Widget _energyDistribution() {
    final cfg = _foCard('distribution');
    final showTotal = cfg['showTotal'] as bool? ?? true;
    final useSlices = _distributionSlicesFromConfig();
    final totalKwh = useSlices.fold<double>(0, (s, e) => s + e.$3);

    return _card(
      title: 'ENERGY DISTRIBUTION',
      child: _liveLoading && useSlices.isEmpty
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _cyan))
          : useSlices.isEmpty
              ? Center(
                  child: Text(
                    _liveError ?? 'No energy data — map devices in Meter Groups / Dashboard Panels',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: _sub, fontSize: 11),
                  ),
                )
              : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTotal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _cyan.withOpacity(0.13),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _cyan.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(color: _cyan.withOpacity(0.18), blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Energy Consumption',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_fmtNum(totalKwh, decimals: 3)} kWh',
                      style: GoogleFonts.poppins(
                        color: _cyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: _cyan.withOpacity(0.7), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showTotal) const SizedBox(height: 8),
          Expanded(
            flex: 12,
            child: LayoutBuilder(
              builder: (context, box) {
                final pieSize = math
                    .min(box.maxWidth * 0.72, box.maxHeight * 0.95)
                    .clamp(90.0, 160.0);
                final pieR = pieSize * 0.46;
                return Center(
                  child: SizedBox(
                    width: pieSize,
                    height: pieSize,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 0,
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (event, response) {
                            if (!mounted) return;
                            final idx = (!event.isInterestedForInteractions ||
                                    response?.touchedSection == null)
                                ? null
                                : response!.touchedSection!.touchedSectionIndex;
                            if (idx != _touchedPieIndex) {
                              setState(() => _touchedPieIndex = idx);
                            }
                          },
                        ),
                        sections: [
                          for (var i = 0; i < useSlices.length; i++)
                            PieChartSectionData(
                              color: useSlices[i].$4,
                              value: useSlices[i].$3,
                              title: _touchedPieIndex == i
                                  ? '${useSlices[i].$1 == 'Other' ? 'Other' : _nameOf(useSlices[i].$1)}\n${useSlices[i].$2}'
                                  : '',
                              titleStyle: GoogleFonts.poppins(
                                color: _white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                shadows: const [
                                  Shadow(color: Colors.black87, blurRadius: 6),
                                ],
                              ),
                              titlePositionPercentageOffset: 0.55,
                              radius: _touchedPieIndex == i ? pieR + 8 : pieR,
                              borderSide: BorderSide(
                                color: useSlices[i].$4.withOpacity(0.55),
                                width: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 10,
            child: Scrollbar(
              controller: _legendScroll,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              child: GridView.builder(
                controller: _legendScroll,
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 20,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 5,
                ),
                itemCount: useSlices.length,
                itemBuilder: (_, i) {
                  final it = useSlices[i];
                  return Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: it.$4,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: it.$4.withOpacity(0.7),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (it.$1 != 'Other' && it.$1.isNotEmpty) {
                              context.pushNamed(
                                'EnergyComparison',
                                queryParameters: {'deviceId': it.$1},
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Text(
                            '${it.$1 == 'Other' ? 'Other' : _nameOf(it.$1)} – ${it.$2}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM CAROUSEL ────────────────────────────────────────────────────────
  Widget _carousel() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF040A16),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: _sub, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {},
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _lots.map((lot) {
                  // The strip labels a block "Lot 237 B" while the plant
                  // master calls it "Lot 237 Block B", so compare with the
                  // spacing and the word "block" removed rather than adding a
                  // second list to keep in step.
                  final isActive = _sameLot(lot, widget.lotName);
                  // A chip that names no plant in the master stays dead rather
                  // than navigating somewhere that does not exist.
                  final target = isActive ? null : _plantForLot(lot);
                  final chip = Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? _blue.withOpacity(0.2) : const Color(0xFF0A1628),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive ? _blue : _border, width: 1.2),
                      boxShadow: isActive
                        ? [BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 10)]
                        : [],
                    ),
                    child: Text(
                      lot,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        // Dimmed further when there is nowhere to go, so the
                        // strip shows at a glance which lots are reachable.
                        color: isActive
                            ? _white
                            : (target == null ? _sub.withOpacity(0.45) : _sub),
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  );
                  if (target == null) return chip;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      // go, not push: this swaps which command centre is on
                      // screen. push stacked them, and a few chip clicks left
                      // the sidebar unable to get out from under the pile.
                      onTap: () => context.goNamed(
                        'KanbanDashboard',
                        queryParameters: {'plant': target},
                      ),
                      child: chip,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: _sub, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: _white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Shared card container ─────────────────────────────────────────────────
  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C1A30), Color(0xFF081222)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border.withOpacity(0.95)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 11,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Energy flow paths (aisle network + traveling pulse) ───────────────────────
class _FlowPathPainter extends CustomPainter {
  final double t;
  final List<(double, double, String, Color, String)> machines;

  _FlowPathPainter({required this.t, required this.machines});

  static const _bright = Color(0xFF00E5FF);

  List<Path> _paths(Size size) {
    final w = size.width;
    final h = size.height;
    final topY = h * 0.31;
    final botY = h * 0.63;
    final leftX = w * 0.14;
    final rightX = w * 0.86;
    final midX = w * 0.50;

    final paths = <Path>[];

    // Light aisle loop only — mockup already has yellow floor arrows in the render.
    paths.add(Path()
      ..moveTo(leftX, topY)
      ..lineTo(rightX, topY)
      ..lineTo(rightX, botY)
      ..lineTo(leftX, botY)
      ..close());

    // Center corridor pulse
    paths.add(Path()
      ..moveTo(midX, topY)
      ..lineTo(midX, botY));

    return paths;
  }

  void _drawNeonTube(Canvas canvas, Path path, double s, {double pulseOffset = 0}) {
    // Soft outer glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _bright.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Thin glass body
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _bright.withOpacity(0.28),
    );

    // Traveling energy packet
    final metrics = path.computeMetrics().toList();
    const gap = 280.0;
    const sweepLen = 56.0;
    final shift = (t + pulseOffset) * gap;

    for (final m in metrics) {
      final len = m.length;
      if (len < 24) continue;
      var dist = (shift % gap) - gap;
      while (dist < len) {
        final start = dist;
        final end = dist + sweepLen;
        if (end > 0 && start < len) {
          final extract = m.extractPath(start.clamp(0.0, len), end.clamp(0.0, len));
          canvas.drawPath(
            extract,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.5 * s
              ..strokeCap = StrokeCap.round
              ..color = _bright.withOpacity(0.40)
              ..imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          );
          canvas.drawPath(
            extract,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6 * s
              ..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.75),
          );
        }
        dist += gap;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width / 1200).clamp(0.85, 1.15);
    final paths = _paths(size);

    for (var i = 0; i < paths.length; i++) {
      _drawNeonTube(canvas, paths[i], s, pulseOffset: i * 0.07);
    }

    // Soft floor wash (very light)
    final glowRect = Rect.fromLTRB(
      size.width * 0.12,
      size.height * 0.28,
      size.width * 0.88,
      size.height * 0.66,
    );
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(glowRect.left, glowRect.top),
          Offset(glowRect.right, glowRect.bottom),
          [
            _bright.withOpacity(0.0),
            _bright.withOpacity(0.025 + 0.02 * math.sin(t * math.pi * 2)),
            _bright.withOpacity(0.0),
          ],
          [0.0, 0.5, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _FlowPathPainter old) =>
      old.t != t || old.machines != machines;
}

// ── Grid Background Painter ───────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D2040).withOpacity(0.6)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
