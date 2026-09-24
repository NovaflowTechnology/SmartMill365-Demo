import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:glow_container/glow_container.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/pecc_live_data.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/plant_energy_command_center/card_style_dialog.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Lot 237 Energy Command Center — hero KPIs, plant health sidebar, 3D flow map,
/// alerts/events panel, and bottom charts (no SEC trend / SEC hero card).
class LotCommandCenterWidget extends StatefulWidget {
  final String lotName;
  final String orgName;
  final String orgSubLabel;

  /// The client's logo. Empty falls back to the initials badge, which is what
  /// this header has always drawn.
  final String logoUrl;
  final String bgImageUrl;
  final PeccLiveData? liveData;
  final Map<String, String> widgetLabels;

  /// Where a flow-diagram card sits, as fractions (0-1) of the background
  /// image — keyed the same as the anchor maps below ('blockA', 'gridTnb',
  /// etc.), not the settings doc's 'flow.' prefix. Missing a key keeps that
  /// card's built-in spot, so an unconfigured plant renders exactly as it
  /// always has.
  final Map<String, (double, double)> widgetPositions;
  final int dataTick;

  /// Font size / colour per card, keyed the same way as [widgetLabels] —
  /// e.g. `hero[0]`. Empty for a card nobody has customised, which then
  /// draws exactly as it always has.
  final CardStyleSet cardStyles;

  /// Only a Super Admin sees a card as editable — the same authority the
  /// group map's own centre card already requires.
  final bool canEditCards;

  /// Saves one card's style back to this dashboard's settings document.
  /// Returns false (nothing shown as changed) when the write did not land.
  final Future<bool> Function(String key, CardTextStyle style)? onSaveCardStyle;

  const LotCommandCenterWidget({
    super.key,
    required this.lotName,
    this.orgName = '',
    this.orgSubLabel = '',
    this.logoUrl = '',
    this.bgImageUrl = '',
    this.liveData,
    this.widgetLabels = const {},
    this.widgetPositions = const {},
    this.dataTick = 0,
    this.cardStyles = CardStyleSet.empty,
    this.canEditCards = false,
    this.onSaveCardStyle,
  });

  @override
  State<LotCommandCenterWidget> createState() => _LotCommandCenterWidgetState();
}

class _LotCommandCenterWidgetState extends State<LotCommandCenterWidget> with TickerProviderStateMixin {
  static const double _dw = 1920;
  static const double _dh = 1080;

  static const _bg = Color(0xFF0A0F20);
  static const _bg2 = Color(0xFF060810);
  static const _panelBg = Color(0xB3091020);
  static const _cardBg = Color(0xFF0D1428);
  static const _border1 = Color(0xFF1C2A48);
  // Energy Details–aligned accents (cyan / electric blue / solar green / amber).
  static const _accent = Color(0xFF00E5FF);
  static const _accentBlue = Color(0xFF00B4FF);
  static const _accentG = Color(0xFF22C55E);
  static const _accentO = Color(0xFFF59E0B);
  // Cost / MD — gold (do not use purple/indigo on this dashboard).
  static const _accentP = Color(0xFFEAB308);
  static const _red = Color(0xFFEF4444);
  static const _white = Colors.white;
  static const _sub = Color(0xFFA8B4C8);
  static const _navBg = Color(0xFF060810);

  int _flowTab = 1; // default Power Flow (mockup-matched center)
  int _displayMode = 0; // 0 = Daily (30-min SQL demand), 1 = Monthly (daily SQL energy)
  double _bgAspect = 2.1;
  ImageStreamListener? _bgAspectListener;
  ImageStream? _bgAspectStream;

  // Card centers — Plant Total centered; Solar far right; blocks aligned below.
  static const _flowAnchors = <String, (double, double)>{
    'plantTotal': (0.50, 0.20),
    'solar': (0.84, 0.21),
    'blockA': (0.24, 0.70),
    'blockB': (0.50, 0.70),
    'blockC': (0.76, 0.70),
  };

  // Power Flow — blocks over buildings; grid bus + TNB reserved in bottom band.
  static const _powerFlowAnchors = <String, (double, double)>{
    'plantTotal': (0.52, 0.17),
    // Lowered from 0.47: at that height the cards sat on the solar roofs and
    // hid the buildings. 0.60 drops them onto the clear road band while still
    // leaving room for the supply bus above the GRID (TNB) card at 0.925.
    'blockA': (0.28, 0.60),
    'blockB': (0.50, 0.60),
    'blockC': (0.72, 0.60),
    'gridTnb': (0.08, 0.925),
  };
  static const _pfTowerAsset = 'assets/images/power_grid_tower_v2.png';


  void _loadBgAspect(String url) {
    if (_bgAspectListener != null && _bgAspectStream != null) {
      _bgAspectStream!.removeListener(_bgAspectListener!);
    }
    _bgAspectListener = null;
    _bgAspectStream = null;
    if (url.isEmpty) return;
    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());
    _bgAspectStream = stream;
    _bgAspectListener = ImageStreamListener((info, _) {
      final h = info.image.height.toDouble();
      if (h <= 0 || !mounted) return;
      final aspect = info.image.width / h;
      if ((aspect - _bgAspect).abs() > 0.01) setState(() => _bgAspect = aspect);
    });
    stream.addListener(_bgAspectListener!);
  }

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _intro.dispose();
    if (_bgAspectListener != null && _bgAspectStream != null) {
      _bgAspectStream!.removeListener(_bgAspectListener!);
    }
    super.dispose();
  }

  String _label(String key, String fallback) {
    final v = widget.widgetLabels[key];
    final raw = v != null && v.isNotEmpty ? v : fallback;
    // Strip any time-period suffixes stored in DB labels so they never appear in UI.
    return raw
        .replaceAll(RegExp(r'\s*\(TODAY\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\(Today\)', caseSensitive: false), '')
        .trim();
  }

  String _v(String live) => live != '—' && live.isNotEmpty ? live : '—';

  /// Live Power Flow value, else mock placeholder (Daily only).
  String _pfOr(String live, String mock) =>
      (live.isNotEmpty && live != '—') ? live : mock;

  /// Monthly: live only — never fall back to Daily mock KPIs.
  String _pfLiveOrDash(String live) =>
      (live.isNotEmpty && live != '—') ? live : '—';

  bool get _pfIsMonthly => _displayMode == 1;
  String get _pfPeriodTag => _pfIsMonthly ? 'MTD' : 'Today';
  String get _pfDeltaCompare => _pfIsMonthly ? 'Last Month' : 'Yesterday';

  String get _pfTotal => _pfIsMonthly
      ? (_pfLiveOrDash(_live.pfPlantTotalKwhMonthly) != '—' ? _live.pfPlantTotalKwhMonthly : _pfLiveOrDash(_live.totalEnergyMtd))
      : (_pfLiveOrDash(_live.pfPlantTotalKwh) != '—' ? _live.pfPlantTotalKwh : _pfLiveOrDash(_live.heroTotalEnergyToday));
  String get _pfSolar => _pfIsMonthly
      ? (_pfLiveOrDash(_live.pfPlantSolarKwhMonthly) != '—' ? _live.pfPlantSolarKwhMonthly : '—')
      : (_pfLiveOrDash(_live.pfPlantSolarKwh) != '—' ? _live.pfPlantSolarKwh : _pfLiveOrDash(_live.heroSolarToday));
  String get _pfSolarPct => _pfIsMonthly
      ? _pfLiveOrDash(_live.pfPlantSolarPctMonthly)
      : _pfLiveOrDash(_live.pfPlantSolarPct);
  String get _pfGrid => _pfIsMonthly
      ? (_pfLiveOrDash(_live.pfPlantGridKwhMonthly) != '—' ? _live.pfPlantGridKwhMonthly : '—')
      : (_pfLiveOrDash(_live.pfPlantGridKwh) != '—' ? _live.pfPlantGridKwh : _pfLiveOrDash(_live.heroGridImportToday));
  String get _pfGridPct => _pfIsMonthly
      ? _pfLiveOrDash(_live.pfPlantGridPctMonthly)
      : _pfLiveOrDash(_live.pfPlantGridPct);
  String get _pfCost => _pfIsMonthly
      ? (_pfLiveOrDash(_live.pfHeroCostMonthly) != '—'
          ? _live.pfHeroCostMonthly
          : _pfLiveOrDash(_live.totalCostMtd))
      : _pfLiveOrDash(_live.heroEnergyCostToday);
  String get _pfCarbon => _pfIsMonthly
      ? (_pfLiveOrDash(_live.pfHeroCarbonMonthly) != '—'
          ? _live.pfHeroCarbonMonthly
          : _pfLiveOrDash(_live.heroCarbonToday))
      : _pfLiveOrDash(_live.heroCarbonToday);
  String get _pfTnbKwh => _pfIsMonthly
      ? _pfLiveOrDash(_live.pfTnbKwhMonthly)
      : _pfLiveOrDash(_live.pfTnbKwh);
  String get _pfTnbHz =>
      _pfIsMonthly ? _pfLiveOrDash(_live.pfTnbHz) : _pfLiveOrDash(_live.pfTnbHz);
  String get _pfTnbPf =>
      _pfIsMonthly ? _pfLiveOrDash(_live.pfTnbPf) : _pfLiveOrDash(_live.pfTnbPf);

  bool get _isSingleBlock => widget.lotName.trim().toLowerCase() == 'lot 48';

  (double, double) _getFlowAnchor(String key) {
    final override = widget.widgetPositions[key];
    if (override != null) return override;
    if (_isSingleBlock && key == 'blockA') return const (0.50, 0.70);
    return _flowAnchors[key] ?? const (0.50, 0.70);
  }

  (double, double) _getPowerFlowAnchor(String key) {
    final override = widget.widgetPositions[key];
    if (override != null) return override;
    if (_isSingleBlock && key == 'blockA') return const (0.50, 0.47);
    return _powerFlowAnchors[key] ?? const (0.50, 0.47);
  }

  List<(String, String, String, String, String, String)> get _pfBlockRows {
    final liveBlocks =
        _pfIsMonthly ? _live.pfBlocksMonthly : _live.pfBlocks;
    if (liveBlocks.isNotEmpty) {
      if (_isSingleBlock) {
        final b = liveBlocks.first;
        return [(b.label, b.totalKwh, b.gridKwh, b.gridPct, b.solarKwh, b.solarPct)];
      }
      return [
        for (final b in liveBlocks)
          (b.label, b.totalKwh, b.gridKwh, b.gridPct, b.solarKwh, b.solarPct),
      ];
    }
    if (_isSingleBlock) {
      return const [
        ('BLOCK A', '—', '—', '—', '—', '—'),
      ];
    }
    return const [
      ('BLOCK A', '—', '—', '—', '—', '—'),
      ('BLOCK B', '—', '—', '—', '—', '—'),
      ('BLOCK C', '—', '—', '—', '—', '—'),
    ];
  }

  (String pct, bool up) _pfDeltaAt(int i) {
    final deltas =
        _pfIsMonthly ? _live.powerFlowHeroDeltasMonthly : _live.powerFlowHeroDeltas;
    if (i >= deltas.length || deltas[i].text == '—') {
      return ('—', true);
    }
    return (deltas[i].text, deltas[i].favorable);
  }

  List<double> _pfTrendOr(List<double> live, List<double> mock) =>
      live.length >= 2 && live.any((v) => v > 0) ? live : mock;

  /// Total trend = live total, else grid + solar per interval (monthly + daily).
  List<double> _pfTrendTotalMerged(List<double> grid, List<double> solar, List<double> liveTotal) {
    if (liveTotal.length >= 2 && liveTotal.any((v) => v > 0)) return liveTotal;
    final n = grid.length > solar.length ? grid.length : solar.length;
    if (n < 2) return liveTotal;
    return List.generate(
      n,
      (i) => (i < grid.length ? grid[i] : 0) + (i < solar.length ? solar[i] : 0),
    );
  }

  List<double> get _pfTrendTotalLive => _pfIsMonthly
      ? _live.pfTrendTotalMonthly
      : _live.pfTrendTotal;
  List<double> get _pfTrendGridLive => _pfIsMonthly
      ? _live.pfTrendGridMonthly
      : _live.pfTrendGrid;
  List<double> get _pfTrendSolarLive => _pfIsMonthly
      ? _live.pfTrendSolarMonthly
      : _live.pfTrendSolar;
  List<String> get _pfTrendLabelsLive => _pfIsMonthly
      ? _live.pfTrendMonthlyLabels
      : const [];

  static String _addThousands(String d) {
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && (d.length - i) % 3 == 0) b.write(',');
      b.write(d[i]);
    }
    return b.toString();
  }

  String _countUp(String raw, double t) {
    if (t >= 1.0) return raw;
    final m = RegExp(r'\d[\d,]*(?:\.\d+)?').firstMatch(raw);
    if (m == null) return raw;
    final numStr = m.group(0)!;
    final dot = numStr.indexOf('.');
    final decimals = dot >= 0 ? numStr.length - dot - 1 : 0;
    final hasComma = numStr.contains(',');
    final value = double.tryParse(numStr.replaceAll(',', '')) ?? 0;
    final cur = value * t;
    String out;
    if (decimals > 0) {
      out = cur.toStringAsFixed(decimals);
      if (hasComma) {
        final p = out.split('.');
        out = '${_addThousands(p[0])}.${p[1]}';
      }
    } else {
      final s = cur.round().toString();
      out = hasComma ? _addThousands(s) : s;
    }
    return raw.replaceFirst(numStr, out);
  }

  Widget _kpi(String value, TextStyle style, {TextAlign? align}) =>
      _LiveCountText(value: value, style: style, textAlign: align, tick: widget.dataTick);

  PeccLiveData get _live => widget.liveData ?? PeccLiveData.empty;

  Map<String, String> get _flowValues =>
      _displayMode == 0 ? _live.flowValues : _live.flowValuesMonthly;
  Map<String, String> get _flowPcts =>
      _displayMode == 0 ? _live.flowPcts : _live.flowPctsMonthly;

  void _syncPulseAnimation() {
    // Animated flow lines run on all tabs now (Energy, Power, Solar)
    if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  double _flowMw(String? raw) {
    if (raw == null || raw == '—' || raw.isEmpty) return 0;
    final m = RegExp(r'([\d,]+(?:\.\d+)?)').firstMatch(raw);
    return double.tryParse(m?.group(1)?.replaceAll(',', '') ?? '') ?? 0;
  }

  Map<String, double> _flowIntensities(Map<String, String> flow) {
    const keys = ['blockA', 'blockB', 'blockC', 'solar'];
    var max = _flowMw(flow['plantTotal']);
    final vals = <String, double>{};
    for (final k in keys) {
      final v = _flowMw(flow[k]);
      vals[k] = v;
      if (v > max) max = v;
    }
    return {
      for (final e in vals.entries)
        e.key: max > 0 ? (e.value / max).clamp(0.22, 1.0) : 0.4,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadBgAspect(widget.bgImageUrl);
    _syncPulseAnimation();
    _loadLotNames();
  }

  /// The lots this chip can switch to.
  ///
  /// Read from the facility master rather than a list kept here, so a lot added
  /// or renamed in General Setting appears without a code change — and because
  /// that call is already narrowed to what the signed-in user may open, the
  /// chip cannot offer a lot they are not entitled to.
  List<String> _lotNames = [];

  Future<void> _loadLotNames() async {
    try {
      final plants = await FacilityService.getFactories();
      if (!mounted) return;
      setState(() {
        _lotNames = plants
            .map((p) => p['name']?.toString().trim() ?? '')
            .where((n) =>
                n.isNotEmpty &&
                !n.toLowerCase().startsWith('test') &&
                RegExp(r'\d').hasMatch(n))
            .toList();
      });
    } catch (_) {
      // The chip simply stays a label, which is what it was before.
    }
  }

  @override
  void didUpdateWidget(covariant LotCommandCenterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bgImageUrl != widget.bgImageUrl) _loadBgAspect(widget.bgImageUrl);
  }


  @override
  Widget build(BuildContext context) {
    // Match group ECC dashboardMode — contain keeps 16:9 proportions, no stretch.
    return ColoredBox(
      color: _bg2,
      child: Center(
          child: FittedBox(
          fit: BoxFit.contain,
            child: SizedBox(
                width: _dw,
                height: _dh,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bg, _bg2]),
                  ),
                  child: Column(children: [
                _topBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _flowTab == 1 ? _powerFlowHeroRow() : _heroRow(),
                  ),
                Expanded(
                    flex: _flowTab == 1 ? 11 : 3,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: _flowTab == 1
                          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Expanded(flex: 7, child: _centerFlowMap()),
                              const SizedBox(width: 12),
                              Expanded(flex: 3, child: _powerFlowRightPanel()),
                            ])
                          : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              SizedBox(width: 360, child: _plantHealthSidebar()),
                              const SizedBox(width: 14),
                              Expanded(child: _centerFlowMap()),
                              const SizedBox(width: 14),
                              SizedBox(width: 330, child: _rightPanel()),
                    ]),
                  ),
                ),
                  Expanded(
                    flex: _flowTab == 1 ? 6 : 2,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _flowTab == 1 ? _powerFlowBottomCharts() : _bottomCharts(),
                    ),
                  ),
                ]),
          ),
          ),
          ),
        ),
      );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _topBar() {
    final org = widget.orgName.trim().isEmpty ? 'THONG GUAN GROUP' : widget.orgName.trim().toUpperCase();
    final sub = widget.orgSubLabel.trim().isEmpty
        ? 'ENERGY MANAGEMENT SYSTEM'
        : widget.orgSubLabel.trim().toUpperCase();
    final title = '${widget.lotName} ENERGY COMMAND CENTER'.toUpperCase();
    final initials = org.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}, ${days[now.weekday - 1]}';
    final updated = _v(_live.lastUpdated);
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: _navBg,
        border: Border(bottom: BorderSide(color: _border1, width: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: const Color(0xFFCC1A1A), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          // The uploaded logo when there is one, initials otherwise, and
          // initials again if the image fails to load — an empty square where
          // the brand should be is worse than two letters.
          clipBehavior: Clip.antiAlias,
          child: widget.logoUrl.trim().isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.network(
                    widget.logoUrl.trim(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(initials,
                        style: const TextStyle(
                            color: _white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ),
                )
              : Text(initials, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(org, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          Text(
            _flowTab == 1 ? widget.lotName.toUpperCase() : sub,
            style: TextStyle(
              color: _flowTab == 1 ? _accentG : _accent,
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: _flowTab == 1 ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 0.6,
            ),
          ),
        ]),
        const Spacer(),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              updated != '—' ? 'Online  |  Last updated: $updated' : 'Online  |  Awaiting data',
              style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12),
            ),
          ]),
        ]),
        const Spacer(),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(timeStr, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22)),
          Text(dateStr, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12)),
        ]),
        const SizedBox(width: 14),
        _iconBtn(Icons.notifications_none, badge: true),
        const SizedBox(width: 8),
        _iconBtn(Icons.help_outline),
        const SizedBox(width: 8),
        _iconBtn(Icons.calendar_today_outlined),
        const SizedBox(width: 10),
        _modeToggle(),
        const SizedBox(width: 14),
        // The chevron here was decoration for a chip that did nothing. It now
        // switches command centre — go, not push, so the dashboards replace one
        // another instead of stacking.
        PopupMenuButton<String>(
          tooltip: 'Switch command center',
          offset: const Offset(0, 44),
          color: _cardBg,
          onSelected: (name) {
            if (name == widget.lotName) return;
            context.goNamed('KanbanDashboard',
                queryParameters: {'plant': name});
          },
          itemBuilder: (_) => [
            for (final name in _lotNames)
              PopupMenuItem<String>(
                value: name,
                child: Row(children: [
                  if (name == widget.lotName)
                    const Icon(Icons.check, color: _white, size: 15)
                  else
                    const SizedBox(width: 15),
                  const SizedBox(width: 8),
                  Text(name.toUpperCase(),
                      style: TextStyle(
                          color: name == widget.lotName ? _white : _sub,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.lotName.toUpperCase(), style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, color: _sub, size: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _modeToggle() {
    Widget btn(String label, int idx) {
      final on = _displayMode == idx;
      return InkWell(
        onTap: () => setState(() => _displayMode = idx),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? _accentBlue.withOpacity(0.22) : _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? _accentBlue : _border1, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: on ? _white : _sub,
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn('Daily', 0),
      const SizedBox(width: 8),
      btn('Monthly', 1),
    ]);
  }

  Widget _iconBtn(IconData i, {bool badge = false}) => Stack(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(9), border: Border.all(color: _border1)),
          child: Icon(i, color: _sub, size: 17),
        ),
        if (badge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
          ),
      ]);

  // ── Hero KPI row (4 cards — Energy Flow tab) ───────────────────────────────
  Widget _heroRow() {
    final deltas = _live.heroDeltas;
    final d0 = deltas.isNotEmpty ? deltas[0] : const PeccHeroDelta();
    final d1 = deltas.length > 1 ? deltas[1] : const PeccHeroDelta();
    final d2 = deltas.length > 2 ? deltas[2] : const PeccHeroDelta();
    final d3 = deltas.length > 3 ? deltas[3] : const PeccHeroDelta();
    final items = [
      // _pfGrid, not _pfTotal. This card is named after the grid meter — the
      // dashboard even shows that meter's own display name on it — so it has
      // to read what the meter reads. Drawing grid + solar here made it
      // disagree with the GRID (TNB) card beside it by exactly the day's solar.
      (_label('hero[0]', 'GRID IMPORT METER'), _pfKwh(_pfGrid), d0, _accentBlue, Icons.bolt, 'hero[0]'),
      (_label('hero[1]', 'TOTAL SOLAR GENERATION'), _pfKwh(_pfSolar), d1, _accentG, Icons.wb_sunny_outlined, 'hero[1]'),
      (_label('hero[3]', 'ENERGY COST${_pfIsMonthly ? ' (MTD)' : ''}'), _pfCost, d2, _accentP, Icons.attach_money, 'hero[3]'),
      (_label('hero[4]', 'CARBON EMISSION'), _pfCarbon, d3, _accentO, Icons.cloud_outlined, 'hero[4]'),
    ];
    return Row(children: [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(child: _heroCard(items[i].$1, items[i].$2, items[i].$3, items[i].$4, items[i].$5, items[i].$6)),
      ],
    ]);
  }

  /// Every card on this dashboard that wants font size / colour goes through
  /// this one wrapper: a pencil badge appears in the corner when [editable],
  /// and tapping it opens [CardStyleDialog] for [cardKey]. Nothing else about
  /// adding it to a new card differs from card to card.
  Widget _editableCard({required String cardKey, required String title, required Widget card}) {
    if (!widget.canEditCards) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openCardStyleDialog(cardKey, title),
        child: Stack(clipBehavior: Clip.none, children: [
          card,
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.edit_outlined, size: 12, color: _white),
            ),
          ),
        ]),
      ),
    );
  }

  /// Same pencil badge as [_editableCard], for a card that already owns its
  /// tap gesture (the map pins navigate to a block's own command centre when
  /// tapped). Wrapping those in another full-card GestureDetector would put
  /// two tap handlers over the same area and the navigation could stop
  /// working, so here only the small corner badge gets a tap target — the
  /// caller stacks it on top of its own card, on top of its own gesture
  /// detector, in a Stack.
  Widget? _editBadge(String cardKey, String title) {
    if (!widget.canEditCards) return null;
    return Positioned(
      top: 6,
      right: 6,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openCardStyleDialog(cardKey, title),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.edit_outlined, size: 11, color: _white),
          ),
        ),
      ),
    );
  }

  Future<void> _openCardStyleDialog(String cardKey, String title) async {
    final save = widget.onSaveCardStyle;
    if (save == null) return;
    final result = await CardStyleDialog.show(context,
        title: title, initial: widget.cardStyles.of(cardKey));
    if (result == null || !mounted) return;
    final ok = await save(cardKey, result);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the card style. Nothing was changed.')),
      );
    }
  }

  Widget _heroCard(String title, String value, PeccHeroDelta delta, Color color, IconData icon, String cardKey) {
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _sub;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return _editableCard(
      cardKey: cardKey,
      title: title,
      card: _glass(
      accent: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.toUpperCase(), style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: style.labelSize > 0 ? style.labelSize : 14, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              _kpi(value, TextStyle(color: valueColor, fontFamily: 'Poppins', fontSize: style.valueSize > 0 ? style.valueSize : 36, fontWeight: FontWeight.w800, height: 1.05)),
              if (delta.text != '—') ...[
                const SizedBox(height: 6),
                Row(children: [
                  _chip(delta.text, delta.favorable),
                  const SizedBox(width: 8),
                  Text('vs $_pfDeltaCompare', style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12)),
                ]),
              ],
            ]),
          ),
          ]),
        ),
      ),
    );
  }

  /// Power Flow — 4 hero KPIs (consumption / solar / cost / carbon).
  Widget _powerFlowHeroRow() {
    final d0 = _pfDeltaAt(0);
    final d1 = _pfDeltaAt(1);
    final d2 = _pfDeltaAt(2);
    final d3 = _pfDeltaAt(3);
    final items = <(String, String, String, bool, Color, String)>[
      // Same card on the Power Flow tab, same reason as above.
      (_label('hero[0]', 'GRID IMPORT METER'), _pfKwh(_pfGrid), d0.$1, d0.$2, _accentBlue, 'hero[0]'),
      (_label('hero[1]', 'TOTAL SOLAR GENERATION'), _pfKwh(_pfSolar), d1.$1, d1.$2, _accentG, 'hero[1]'),
      (_label('hero[3]', 'ENERGY COST${_pfIsMonthly ? ' (MTD)' : ''}'), _pfCost, d2.$1, d2.$2, _accentP, 'hero[3]'),
      (_label('hero[4]', 'CARBON EMISSION'), _pfCarbon, d3.$1, d3.$2, _accentO, 'hero[4]'),
    ];
    return Row(children: [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: _powerFlowHeroCard(
            title: items[i].$1,
            value: items[i].$2,
            deltaPct: items[i].$3,
            up: items[i].$4,
            color: items[i].$5,
            cardKey: items[i].$6,
          ),
        ),
      ],
    ]);
  }

  String _pfKwh(String raw) {
    if (raw == '—' || raw.isEmpty) return '—';
    return raw.contains('kWh') ? raw : '$raw kWh';
  }

  Widget _powerFlowHeroCard({
    required String title,
    required String value,
    required String deltaPct,
    required bool up,
    required Color color,
    required String cardKey,
  }) {
    // Mockup colors by arrow direction (down = red, up = green), not favorability.
    final deltaColor = up ? _accentG : _red;
    final arrow = up ? '▲' : '▼';
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _sub;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return _editableCard(
      cardKey: cardKey,
      title: title,
      card: _glass(
      accent: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: style.labelSize > 0 ? style.labelSize : 11, letterSpacing: 0.35), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _kpi(value, TextStyle(color: valueColor, fontFamily: 'Poppins', fontSize: style.valueSize > 0 ? style.valueSize : 28, fontWeight: FontWeight.w800, height: 1.05)),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: deltaColor.withOpacity(0.14), borderRadius: BorderRadius.circular(5)),
              child: Text('$arrow $deltaPct', style: TextStyle(color: deltaColor, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'vs $_pfDeltaCompare',
                style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ]),
      ),
      ),
    );
  }

  // ── Left: Plant Health sidebar ────────────────────────────────────────────
  Widget _plantHealthSidebar() {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _panelHeader('PLANT HEALTH', ''),
          const SizedBox(height: 6),
          _healthBanner(),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 360;
                return Column(
                  children: [
                    _sidebarMetric(
                      _label('sidebar[1]', 'CURRENT LOAD'),
                      _v(_live.sidebarCurrentLoad),
                      _v(_live.sidebarCurrentLoadSub),
                      _accentBlue,
                      compact: compact,
                      cardKey: 'sidebar[1]',
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    _sidebarMetric(
                      _label('sidebar[2]', 'MAX DEMAND (MD)'),
                      _v(_live.sidebarMaxDemand),
                      _v(_live.sidebarMaxDemandSub),
                      _accentP,
                      showBar: _live.sidebarMdBarPct > 0,
                      barPct: _live.sidebarMdBarPct.clamp(0.0, 1.0),
                      compact: compact,
                      cardKey: 'sidebar[2]',
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    _sidebarMetric(
                      _label('sidebar[3]', 'POWER FACTOR'),
                      _v(_live.sidebarPowerFactor),
                      _v(_live.sidebarPowerFactorSub),
                      _accentBlue,
                      compact: compact,
                      cardKey: 'sidebar[3]',
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    _sidebarMetric(
                      _label('sidebar[4]', 'SOLAR CONTRIBUTION'),
                      _v(_live.sidebarSolarContribution),
                      _v(_live.sidebarSolarSub),
                      _accentG,
                      compact: compact,
                      cardKey: 'sidebar[4]',
                    ),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _healthBanner() {
    final health = _v(_live.sidebarPlantHealth);
    final sub = _v(_live.sidebarPlantHealthSub);
    return _glass(
      accent: _accentG,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: _accentG.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield_outlined, color: _accentG, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(health.toUpperCase(), style: const TextStyle(color: _accentG, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(sub, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sidebarMetric(String title, String value, String sub, Color color,
      {bool showBar = false, double barPct = 0, bool compact = false, String cardKey = ''}) {
    final style = widget.cardStyles.of(cardKey);
    final titleSize = style.labelSize > 0 ? style.labelSize : (compact ? 11.0 : 12.0);
    final valueSize = style.valueSize > 0 ? style.valueSize : (compact ? 22.0 : 26.0);
    final subSize = compact ? 10.0 : 11.0;
    final titleColor = heroColors[style.labelColorKey] ?? color;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return Expanded(
      child: _editableCard(
        cardKey: cardKey,
        title: title,
        card: _glass(
        accent: color,
      child: Padding(
          padding: EdgeInsets.fromLTRB(10, compact ? 5 : 6, 10, compact ? 5 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(color: titleColor, fontFamily: 'Poppins', fontSize: titleSize, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: compact ? 2 : 3),
              Row(children: [
          Expanded(
                  child: _kpi(value, TextStyle(color: valueColor, fontFamily: 'Poppins', fontSize: valueSize, fontWeight: FontWeight.w800, height: 1.0)),
                ),
                if (!showBar)
                  SizedBox(width: compact ? 52 : 58, height: compact ? 20 : 22, child: CustomPaint(painter: _Spark(color))),
              ]),
              SizedBox(height: compact ? 1 : 2),
              Text(
                sub,
                style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: subSize, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showBar) ...[
                SizedBox(height: compact ? 3 : 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: barPct, minHeight: compact ? 4 : 5, backgroundColor: _border1, color: _accentP),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ── Center: 3D energy flow map ────────────────────────────────────────────
  Widget _centerFlowMap() {
    // Power Flow tab → mockup 1:1 layout (Grid/Solar split + GRID TNB).
    if (_flowTab == 1) return _powerFlowCenterMap();

    final flow = _flowValues;
    final pcts = _flowPcts;
    final intensities = _flowIntensities(flow);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          // Mockup — Plant Total widest + centered; blocks below.
          final plantW = w * 0.30;
          final plantH = h * 0.24;
          final solarW = w * 0.17;
          final solarH = h * 0.19;
          final blockW = w * 0.18;
          final blockH = h * 0.20;

          Offset center(String key) {
            final a = _getFlowAnchor(key);
            return Offset(a.$1 * w, a.$2 * h);
          }

          ({Offset cardBottom, Offset cardTop, Offset center, Size size}) layout(String key) {
            final sz = switch (key) {
              'plantTotal' => Size(plantW, plantH),
              'solar' => Size(solarW, solarH),
              _ => Size(blockW, blockH),
            };
            final c = center(key);
            final top = c.dy - sz.height / 2;
            return (
              cardBottom: Offset(c.dx, top + sz.height),
              cardTop: Offset(c.dx, top),
              center: c,
              size: sz,
            );
          }

          final layouts = <String, ({Offset cardBottom, Offset cardTop, Offset center, Size size})>{
            for (final k in _flowAnchors.keys) k: layout(k),
          };

          Widget cardAt(String key, String label, String value, String pct, Color color, {bool large = false}) {
            final l = layouts[key]!;
            final cardKey = 'flow.$key';
            final node = _flowNode(
              label,
              value,
              pct,
              color,
              large: large || key == 'plantTotal',
              medium: key == 'solar',
              cardKey: cardKey,
            );
            final badge = _editBadge(cardKey, label);
            return Positioned(
              left: l.center.dx - l.size.width / 2,
              top: l.center.dy - l.size.height / 2,
              child: SizedBox(
                width: l.size.width,
                height: l.size.height,
                child: Stack(clipBehavior: Clip.none, children: [
                  _blockPlant(key) != null
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _openBlock(_blockPlant(key)!),
                            behavior: HitTestBehavior.opaque,
                            child: node,
                          ),
                        )
                      : node,
                  if (badge != null) badge,
                ]),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
        Positioned.fill(
          child: _bgImageOrFallback(),
        ),
        Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
              gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.30),
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.45),
                      ],
                      stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
              Positioned.fill(
                // No RepaintBoundary here on purpose: this painter fills the
                // whole map and repaints every frame, so a boundary would
                // allocate a full-screen texture and re-rasterise it 60 times a
                // second. Memory climbed measurably when one was added here.
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    painter: _FlowLinesPainter(
                      layouts: layouts,
                      hubKey: 'plantTotal',
                      tab: _flowTab,
                      pulse: _pulse.value,
                      intensities: intensities,
            ),
          ),
        ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Row(children: [
                  for (int i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _flowTabBtn(['Energy Flow', 'Power Flow'][i], i),
                  ],
                ]),
              ),
              cardAt('blockA', _label('flow.blockA', 'Block A'), _v(flow['blockA'] ?? '—'), _v(pcts['blockA'] ?? '—'), _accentBlue),
              if (!_isSingleBlock) ...[
                cardAt('blockB', _label('flow.blockB', 'Block B'), _v(flow['blockB'] ?? '—'), _v(pcts['blockB'] ?? '—'), _accentBlue),
                cardAt('blockC', _label('flow.blockC', 'Block C'), _v(flow['blockC'] ?? '—'), _v(pcts['blockC'] ?? '—'), _accentBlue),
              ],
              cardAt('plantTotal', _label('flow.plantTotal', 'Plant Total'), _v(flow['plantTotal'] ?? '—'), _v(_live.plantMdPct), _accent, large: true),
              cardAt('solar', _label('flow.solar', 'Solar Plant'), _v(flow['solar'] ?? '—'), _v(pcts['solar'] ?? '—'), _accentG),
            ],
          );
        },
      ),
    );
  }

  /// Power Flow center — clean mockup layout (even spacing, light glass, aerial fill).
  Widget _powerFlowCenterMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final s = (w / 1260).clamp(0.88, 1.18);

            Offset anchor(String key) {
              final a = _getPowerFlowAnchor(key);
              return Offset(a.$1 * w, a.$2 * h);
            }

            // Block cards — compact; sit above the grid supply bus (Lot 237).
            final blockSz = Size((_isSingleBlock ? 220 : 200) * s, (_isSingleBlock ? 148 : 132) * s);
            final gridCardSz = Size(118 * s, 66 * s);

            final blockCenters = _isSingleBlock
                ? [anchor('blockA')]
                : [anchor('blockA'), anchor('blockB'), anchor('blockC')];
            final gridCardC = anchor('gridTnb');
            // A saved position overrides which side the card sits on (and
            // which edge its supply line leaves from below); left unset, the
            // card keeps its original side so an unconfigured plant renders
            // exactly as it always has.
            final gridCustomised = widget.widgetPositions.containsKey('gridTnb');
            final gridOnRight = gridCustomised ? gridCardC.dx >= w / 2 : _isSingleBlock;

            final blockRects = [
              for (final c in blockCenters) Rect.fromCenter(center: c, width: blockSz.width, height: blockSz.height),
            ];

            // Bottom band for TNB card — do not pull upward into block row (was clamp min 0.62).
            final gridTopMin = gridOnRight ? h * 0.78 : h * 0.805;
            final gridCardLeft = gridCustomised
                ? (gridCardC.dx - gridCardSz.width / 2).clamp(6.0, w - gridCardSz.width - 6.0)
                : (gridOnRight ? w - gridCardSz.width - 6.0 : 6.0);
            final gridTop = (gridCardC.dy - gridCardSz.height / 2).clamp(
              gridTopMin,
              h - gridCardSz.height - 6,
            );
            final gridRect = Rect.fromLTWH(
              gridCardLeft,
              gridTop,
              gridCardSz.width,
              gridCardSz.height,
            );
            // Neon trunk runs in the clear strip between block cards and grid hardware.
            final supplyBusY = (gridTop - 10 * s).clamp(
              blockRects.map((r) => r.bottom).reduce(math.max) + 14 * s,
              gridTop - 4,
            );

            // Lot 48: tower + GRID card on the right; multi-block lots keep tower on the left.
            final towerH = h * 0.40;
            final towerW = towerH * 0.85;
            final towerLeft = gridOnRight ? w - towerW - 6.0 : 4.0;
            final towerBottom = gridTop + gridCardSz.height * 0.15;
            final towerTop = (towerBottom - towerH).clamp(h * 0.12, gridTop - 8);

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                // Match Energy Flow aerial treatment (BoxFit.fill + same vignette).
                Positioned.fill(
                  child: _bgImageOrFallback(width: w, height: h),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.18),
                            Colors.transparent,
                            Colors.black.withOpacity(0.28),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: towerLeft - 10,
                  top: towerTop - 10,
                  width: towerW + 20,
                  height: towerH + 20,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => CustomPaint(
                        foregroundPainter: _TowerElectricPulsePainter(pulse: _pulse.value),
                        child: Image.asset(
                          _pfTowerAsset,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => CustomPaint(
                            painter: _IsometricSubstationPainter(pulse: _pulse.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PowerFlowGridLinesPainter(
                          blockRects: blockRects,
                          gridRect: gridRect,
                          supplyBusY: supplyBusY,
                          gridOnRight: gridOnRight,
                          pulse: _pulse.value,
                        ),
                      ),
                    ),
                  ),
                ),
                // Tabs left, legend right.
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 2; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        _flowTabBtn(['Energy Flow', 'Power Flow'][i], i),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _powerFlowLegend(),
                ),
                for (var i = 0; i < _pfBlockRows.length.clamp(0, 3); i++)
                  Positioned(
                    left: blockRects[i].left,
                    top: blockRects[i].top,
                    width: blockRects[i].width,
                    height: blockRects[i].height,
                    child: GlowContainer(
                      gradientColors: [_accentBlue, _accentBlue.withOpacity(0.3), Colors.transparent],
                      glowRadius: 8.0,
                      showAnimatedBorder: true,
                      rotationDuration: const Duration(seconds: 3),
                      containerOptions: const ContainerOptions(
                        borderRadius: 10.0,
                        backgroundColor: Colors.transparent,
                      ),
                      child: _powerFlowBlockCard(
                        label: _pfBlockRows[i].$1,
                        totalKwh: _pfBlockRows[i].$2,
                        gridKwh: _pfBlockRows[i].$3,
                        gridPct: _pfBlockRows[i].$4,
                        solarKwh: _pfBlockRows[i].$5,
                        solarPct: _pfBlockRows[i].$6,
                        scale: s,
                        onTap: _blockPlant(_pfBlockRows[i].$1) != null
                            ? () => _openBlock(_blockPlant(_pfBlockRows[i].$1)!)
                            : null,
                        cardKey: 'pfBlock.${_pfBlockRows[i].$1}',
                      ),
                    ),
                  ),
                Positioned(
                  left: gridRect.left,
                  top: gridRect.top,
                  width: gridRect.width,
                  height: gridRect.height,
                  child: _powerFlowGridTnbCard(s),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _powerFlowLegend() {
    Widget item(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withOpacity(0.6), blurRadius: 5)]),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: _white.withOpacity(0.9), fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w500)),
        ]);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        item(_accentBlue, 'Grid Supply'),
        const SizedBox(width: 12),
        item(_accentG, 'Solar Generation'),
      ]),
    );
  }

  Widget _powerFlowPlantHub(double s) {
    Widget col({required IconData icon, required Color color, required String title, required String value, String? sub}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Row(children: [
              Icon(icon, size: 14 * s, color: color),
              SizedBox(width: 5 * s),
              Expanded(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10.5 * s)),
              ),
            ]),
            SizedBox(height: 4 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('$value kWh', style: TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 17 * s, fontWeight: FontWeight.w800, height: 1.05)),
            ),
            if (sub != null) ...[
              SizedBox(height: 2 * s),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontFamily: 'Poppins', fontSize: 9.5 * s, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
    }

    return _flowGlass(
      accent: _accentBlue,
      large: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 10 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.lotName.toUpperCase()} PLANT (TOTAL)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _accent, fontFamily: 'Poppins', fontSize: 12 * s, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            SizedBox(height: 6 * s),
            Expanded(
              child: Row(children: [
                col(icon: Icons.apartment_rounded, color: _white, title: 'Total Consumption', value: _pfTotal),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * s),
                  child: Container(width: 1, height: double.infinity, color: _border1.withOpacity(0.8)),
                ),
                col(icon: Icons.wb_sunny_outlined, color: _accentG, title: 'Solar Used', value: _pfSolar, sub: '($_pfSolarPct of Consumption)'),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * s),
                  child: Container(width: 1, height: double.infinity, color: _border1.withOpacity(0.8)),
                ),
                col(icon: Icons.cell_tower, color: _accentBlue, title: 'Grid Import', value: _pfGrid, sub: '($_pfGridPct of Consumption)'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// The command centre a block on this map opens, or null when the name is
  /// not a block at all.
  ///
  /// Takes either the flow-map key (`blockC`) or the card label ("Block C"),
  /// because the same block is identified both ways on this screen.
  String? _blockPlant(String keyOrLabel) {
    final t = keyOrLabel.trim().toLowerCase();
    // B and C only. Block A has no command centre set up yet, and a link that
    // lands on an empty page is worse than no link.
    for (final b in const ['b', 'c']) {
      if (t == 'block$b' || t == 'block $b' || t.contains('block $b')) {
        return 'Lot 237 Block ${b.toUpperCase()}';
      }
    }
    return null;
  }

  /// go, not push: this swaps which command centre is on screen rather than
  /// stacking another full-screen dashboard on top of this one.
  void _openBlock(String plant) {
    context.goNamed('KanbanDashboard', queryParameters: {'plant': plant});
  }

  Widget _powerFlowBlockCard({
    required String label,
    required String totalKwh,
    required String gridKwh,
    required String gridPct,
    required String solarKwh,
    required String solarPct,
    required double scale,
    VoidCallback? onTap,
    String cardKey = '',
  }) {
    final s = scale;
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _accentBlue;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    final card = _flowGlass(
      accent: _accentBlue,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 8 * s, 6 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header: Left (Icon + Label + Total Consumption), Right (Total Value + kWh) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.domain_rounded, color: labelColor, size: 13 * s),
                          SizedBox(width: 4 * s),
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                                color: labelColor,
                                fontFamily: 'Poppins',
                                fontSize: (style.labelSize > 0 ? style.labelSize : 11) * s,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5),
                          ),
                          if (onTap != null) ...[
                            SizedBox(width: 4 * s),
                            Icon(Icons.open_in_new, color: _accent.withOpacity(0.85), size: 11 * s),
                          ],
                        ],
                      ),
                      SizedBox(height: 1 * s),
                      Text(
                        'Total Consumption',
                        style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 8.5 * s, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topRight,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Poppins', color: _white),
                      children: [
                        TextSpan(
                          text: totalKwh,
                          style: TextStyle(
                              fontSize: (style.valueSize > 0 ? style.valueSize : 16) * s,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              color: valueColor),
                        ),
                        TextSpan(
                          text: ' kWh',
                          style: TextStyle(fontSize: 10 * s, fontWeight: FontWeight.w600, color: valueColor.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5 * s),
            // ── Two sub-boxes ──
            Expanded(
              child: Row(children: [
                Expanded(child: _pfMiniBox(color: _accentBlue, title: 'Grid Import', kwh: gridKwh, pct: gridPct, s: s)),
                SizedBox(width: 5 * s),
                Expanded(child: _pfMiniBox(color: _accentG, title: 'Solar Generation', kwh: solarKwh, pct: solarPct, s: s)),
              ]),
            ),
          ],
        ),
      ),
    );
    final badge = _editBadge(cardKey, label);
    final tappable = onTap == null
        ? card
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: card,
            ),
          );
    if (badge == null) return tappable;
    return Stack(clipBehavior: Clip.none, children: [tappable, badge]);
  }

  Widget _pfMiniBox({required Color color, required String title, required String kwh, required String pct, required double s}) {
    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 4 * s, 6 * s, 4 * s),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontFamily: 'Poppins', fontSize: 9.5 * s, fontWeight: FontWeight.w700, letterSpacing: 0.1),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kwh == '—' ? '—' : kwh,
              style: TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 14 * s, fontWeight: FontWeight.w800, height: 1.05),
            ),
          ),
          Text(
            'kWh',
            style: TextStyle(color: _white.withOpacity(0.75), fontFamily: 'Poppins', fontSize: 8.5 * s, fontWeight: FontWeight.w500, height: 1.0),
          ),
          if (pct != '—')
            Text(
              pct,
              style: TextStyle(color: color, fontFamily: 'Poppins', fontSize: 9.5 * s, fontWeight: FontWeight.w700, height: 1.0),
            ),
        ],
      ),
    );
  }

  /// Compact GRID (TNB) card under the tower.
  Widget _powerFlowGridTnbCard(double s) {
    const cardKey = 'grid.tnb';
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _white;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return _editableCard(
      cardKey: cardKey,
      title: 'GRID (TNB)',
      card: _flowGlass(
      accent: _accentBlue,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GRID (TNB)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: (style.labelSize > 0 ? style.labelSize : 12) * s, fontWeight: FontWeight.w800, letterSpacing: 0.35, height: 1.1)),
            SizedBox(height: 2 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('$_pfTnbKwh kWh', style: TextStyle(color: valueColor, fontFamily: 'Poppins', fontSize: (style.valueSize > 0 ? style.valueSize : 16) * s, fontWeight: FontWeight.w800, height: 1.05)),
            ),
            SizedBox(height: 2 * s),
            Text('$_pfTnbHz Hz  |  PF $_pfTnbPf', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _white.withOpacity(0.85), fontFamily: 'Poppins', fontSize: 10.5 * s, height: 1.1)),
          ],
        ),
      ),
      ),
    );
  }

  Widget _flowTabBtn(String label, int idx) {
    final active = _flowTab == idx;
    return GestureDetector(
      onTap: () => setState(() {
        _flowTab = idx;
        _syncPulseAnimation();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _accentBlue.withOpacity(0.28) : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? _accentBlue : _border1),
        ),
        child: Text(label, style: TextStyle(color: active ? _white : _sub, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _flowNode(String label, String value, String pct, Color color,
      {bool large = false, bool medium = false, String cardKey = ''}) {
    final style = widget.cardStyles.of(cardKey);
    final titleSize = style.labelSize > 0 ? style.labelSize : (large ? 14.0 : (medium ? 13.0 : 13.0));
    final valueSize = style.valueSize > 0 ? style.valueSize : (large ? 40.0 : (medium ? 32.0 : 32.0));
    final pctSize = large ? 12.0 : 11.0;
    final titleColor = heroColors[style.labelColorKey] ?? color;
    final valueColor = heroColors[style.valueColorKey] ?? _white;

    return GlowContainer(
      gradientColors: [color, color.withOpacity(0.3), Colors.white],
      glowRadius: large ? 14.0 : 10.0,
      showAnimatedBorder: true,
      rotationDuration: const Duration(seconds: 3),
      containerOptions: const ContainerOptions(
        borderRadius: 10.0,
        backgroundColor: Colors.transparent,
      ),
      child: _flowGlass(
        accent: color,
        large: large,
        glow: 1.0,
        child: Padding(
          // Tight vertical rhythm: long labels such as "BLOCK A MAIN INCOMING
          // DPM" wrap to two lines and used to overflow the fixed-height card
          // by a few pixels.
          padding: EdgeInsets.fromLTRB(large ? 16 : 14, large ? 10 : 8, large ? 16 : 14, large ? 8 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontFamily: 'Poppins',
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.15,
                ),
              ),
            ),
            SizedBox(height: large ? 4 : 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _kpi(
                value,
                TextStyle(
                  color: valueColor,
                  fontFamily: 'Poppins',
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pct,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _white.withOpacity(0.85),
                fontFamily: 'Poppins',
                fontSize: pctSize,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Glass card — fills parent SizedBox from Energy Flow layout.
  Widget _flowGlass({required Color accent, required Widget child, bool large = false, double glow = 0.4}) {
    final radius = large ? 10.0 : 9.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.14),
                const Color(0x80060E1C), // ~50% opaque dark glass
                const Color(0x73040A16),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            border: Border.all(color: accent.withOpacity(0.65), width: 1.25),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.22 * glow), blurRadius: 14, spreadRadius: 0),
              BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Cached provider keyed by URL so the aerial map is decoded once instead of
  /// on every rebuild, isolated behind a RepaintBoundary so the animated flow
  /// lines and live cards above it never force the image to repaint.
  ImageProvider? _bgProvider;
  String _bgProviderUrl = '';

  Widget _bgImageOrFallback({BoxFit fit = BoxFit.fill, double? width, double? height}) {
    final url = widget.bgImageUrl;
    if (url.isEmpty) return _buildingFallback();
    if (_bgProvider == null || _bgProviderUrl != url) {
      _bgProvider = NetworkImage(url);
      _bgProviderUrl = url;
    }
    return RepaintBoundary(
      child: Image(
        image: _bgProvider!,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildingFallback(),
      ),
    );
  }

  Widget _buildingFallback() => AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => CustomPaint(
          painter: _AnimatedIsometricGridPainter(pulse: _pulse.value),
          child: const SizedBox.expand(),
        ),
      );

  // ── Right: Alerts & Events ────────────────────────────────────────────────
  Widget _rightPanel() {
    return Column(children: [
      Expanded(child: _panel(child: _alertsPanel())),
      const SizedBox(height: 10),
      Expanded(child: _panel(child: _eventsPanel())),
    ]);
  }

  /// Power Flow mockup — Energy Flow Summary stepper + Energy Mix donut.
  Widget _powerFlowRightPanel() {
    return Column(children: [
      Expanded(flex: 11, child: _panel(child: _powerFlowSummaryPanel())),
      const SizedBox(height: 10),
      Expanded(flex: 9, child: _panel(child: _powerFlowEnergyMixPanel())),
    ]);
  }

  Widget _powerFlowSummaryPanel() {
    final solarKwh = double.tryParse(_pfSolar.replaceAll(',', '')) ?? 0;
    final gridKwh = double.tryParse(_pfGrid.replaceAll(',', '')) ?? 0;
    final totalKwh = double.tryParse(_pfTotal.replaceAll(',', '')) ?? 0;
    // % only when Total is known — never show Solar 100% just because grid meter failed.
    final solarPct = totalKwh > 0
        ? '${((solarKwh / totalKwh) * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%'
        : '—';
    final gridPct = totalKwh > 0
        ? '${((gridKwh / totalKwh) * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%'
        : '—';
    final steps = <(IconData, Color, String, String, String)>[
      (Icons.wb_sunny_outlined, _accentG, 'Solar Generation', '$_pfSolar kWh', solarPct),
      (Icons.wb_sunny_outlined, _accentG, 'Solar Used (Total)', '$_pfSolar kWh', solarPct),
      (Icons.electrical_services_outlined, _accentBlue, 'Grid Import (Total)', '$_pfGrid kWh', gridPct),
      (Icons.bolt, _accent, 'Total Consumption', '$_pfTotal kWh', totalKwh > 0 ? '100%' : '—'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'ENERGY FLOW SUMMARY',
          style: TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  SizedBox(
                    height: 10,
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: _sub.withOpacity(0.7), size: 18),
                  ),
                Expanded(child: _powerFlowSummaryStep(steps[i].$1, steps[i].$2, steps[i].$3, steps[i].$4, steps[i].$5)),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _powerFlowSummaryStep(IconData icon, Color color, String title, String value, String pct) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardBg.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                pct != '—' ? '$value ($pct)' : value,
                style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, height: 1.1),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _powerFlowEnergyMixPanel() {
    // Pie slices from Solar Used + Grid Import kWh, only when Total is known.
    // If Total is missing (meter down), do NOT normalize solar alone to 100%.
    final solarKwh = double.tryParse(_pfSolar.replaceAll(',', '')) ?? 0;
    final gridKwh = double.tryParse(_pfGrid.replaceAll(',', '')) ?? 0;
    final totalKwh = double.tryParse(_pfTotal.replaceAll(',', '')) ?? 0;
    double sFrac = 0;
    double gFrac = 0;
    String solarLegend = _pfSolarPct;
    String gridLegend = _pfGridPct;
    if (totalKwh > 0) {
      sFrac = (solarKwh / totalKwh).clamp(0.0, 1.0);
      gFrac = (gridKwh / totalKwh).clamp(0.0, 1.0);
      final sum = sFrac + gFrac;
      if (sum > 0 && (sum - 1.0).abs() > 0.02) {
        sFrac /= sum;
        gFrac /= sum;
      }
      solarLegend = '${(sFrac * 100).toStringAsFixed(1)}%';
      gridLegend = '${(gFrac * 100).toStringAsFixed(1)}%';
    } else if (solarKwh > 0 || gridKwh > 0) {
      solarLegend = '—';
      gridLegend = '—';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'ENERGY MIX',
          style: TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
        const SizedBox(height: 4),
          Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Lock square aspect — without this, PieChart can squash into an oval
              // when the right-panel flex height changes after live refresh.
              final side = math
                  .min(constraints.maxHeight * 0.92, constraints.maxWidth * 0.50)
                  .clamp(100.0, 168.0);
              final outer = side / 2;
              final hole = outer * 0.60;
              final ring = (outer - hole).clamp(8.0, outer);
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: side,
                      height: side,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(alignment: Alignment.center, children: [
                          if (sFrac + gFrac > 0)
                            PieChart(
                              PieChartData(
                                startDegreeOffset: -90,
                                sectionsSpace: 2,
                                centerSpaceRadius: hole,
                                sections: [
                                  if (sFrac > 0)
                                    PieChartSectionData(value: sFrac * 100, color: _accentG, radius: ring, showTitle: false),
                                  if (gFrac > 0)
                                    PieChartSectionData(value: gFrac * 100, color: _accentBlue, radius: ring, showTitle: false),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Container(
                                width: side,
                                height: side,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _border1, width: ring.clamp(6.0, 14.0)),
                                ),
                              ),
                            ),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              totalKwh > 0 ? '$_pfTotal' : '—',
                              style: TextStyle(color: _white, fontFamily: 'Poppins', fontSize: side < 110 ? 14 : 17, fontWeight: FontWeight.w800),
                            ),
                            Text('kWh', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: side < 110 ? 11 : 13)),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _mixLegendRow(_accentG, 'Solar Used', solarLegend),
                        const SizedBox(height: 12),
                        _mixLegendRow(_accentBlue, 'Grid Import', gridLegend),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          ),
        ]),
    );
  }

  Widget _mixLegendRow(Color c, String label, String pct) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500)),
          Text(pct, style: TextStyle(color: c, fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
      ]);

  Widget _alertsPanel() {
    final critical = _live.alertCritical;
    final warning = _live.alertWarning;
    final info = _live.alertInfo;
    final allClear = critical == 0 && warning == 0 && info == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _panelHeader(_label('panel.alerts', 'CURRENT ALERTS'), ''),
        const SizedBox(height: 8),
        Expanded(
          child: _glass(
            accent: allClear ? _accentG : _red,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 150;
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(allClear ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: allClear ? _accentG : _red, size: compact ? 28 : 32),
                        SizedBox(height: compact ? 6 : 8),
                        Text(
                          allClear ? 'All Systems Normal' : 'Active Alerts',
                          style: TextStyle(color: _white, fontFamily: 'Poppins', fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: compact ? 8 : 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _alertCount('$critical', 'Critical', _red, compact: compact),
                          SizedBox(width: compact ? 12 : 14),
                          _alertCount('$warning', 'Warning', _accentO, compact: compact),
                          SizedBox(width: compact ? 12 : 14),
                          _alertCount('$info', 'Info', _accentBlue, compact: compact),
                        ]),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _alertCount(String n, String label, Color c, {bool compact = false}) => Column(children: [
        Text(n, style: TextStyle(color: c, fontFamily: 'Poppins', fontSize: compact ? 16 : 18, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: compact ? 9 : 10)),
      ]);

  Widget _eventsPanel() {
    final events = _live.todayEvents;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _panelHeader(_label('panel.events', "TODAY'S EVENTS"), ''),
        const SizedBox(height: 8),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    _live.hasData ? 'No events recorded today' : 'Map panel.events in PECC settings',
                    style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _glass(
                    accent: _accentBlue,
      child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
                        Text(events[i].time, style: const TextStyle(color: _accent, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
          Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(events[i].title, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (events[i].detail.isNotEmpty)
                              Text(events[i].detail, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
            ]),
          ),
                  ),
                ),
        ),
      ]),
    );
  }

  // ── Bottom charts (no SEC trend) ──────────────────────────────────────────
  static const _demoLoadKw = [
    420.0, 410.0, 400.0, 430.0, 500.0, 620.0, 760.0, 900.0, 1030.0, 1120.0, 1160.0, 1180.0,
    1140.0, 1080.0, 1020.0, 970.0, 930.0, 860.0, 780.0, 700.0, 620.0, 540.0, 500.0, 470.0,
  ];
  static const _demoMdKw = [
    550.0, 580.0, 610.0, 640.0, 700.0, 780.0, 900.0, 1030.0, 1180.0, 1320.0, 1460.0, 1600.0,
    1680.0, 1710.0, 1720.0, 1720.0, 1720.0, 1720.0, 1720.0, 1720.0, 1720.0, 1720.0, 1720.0, 1720.0,
  ];
  static const _demoSolarKw = [
    0.0, 0.0, 0.0, 0.0, 20.0, 60.0, 130.0, 220.0, 300.0, 350.0, 380.0, 370.0,
    340.0, 300.0, 240.0, 170.0, 90.0, 30.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  ];

  List<double> _chartKwData(List<double> live, List<double> demo) {
    if (live.length >= 2 && live.any((v) => v > 0)) return live;
    if (_live.hasData) return live;
    return live.length >= 4 ? live : demo;
  }

  List<String> _chartLabelData(List<String> live, int fallbackLen) {
    if (live.length >= 2) return live;
    return List.generate(fallbackLen, (i) => '${i.toString().padLeft(2, '0')}:00');
  }

  double _chartMaxX(int pointCount) {
    if (pointCount <= 1) return 1;
    return (pointCount - 1).toDouble();
  }

  int _daysInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  /// Parses chart labels like `14/7`, `14/07`, or `14 Jul`.
  /// When [requireMonth] is set, returns 0 for other months (so July chart skips June rows).
  int _parseMonthDay(String label, {int? requireMonth}) {
    final trimmed = label.trim();
    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})$').firstMatch(trimmed);
    if (slash != null) {
      final day = int.tryParse(slash.group(1)!) ?? 0;
      final month = int.tryParse(slash.group(2)!) ?? 0;
      if (requireMonth != null && month != requireMonth) return 0;
      return day;
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final day = int.tryParse(parts.last) ?? 0;
      if (requireMonth != null) {
        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        final key = parts.first.toLowerCase();
        final abbr = key.length >= 3 ? key.substring(0, 3) : key;
        final m = months[abbr];
        if (m != null && m != requireMonth) return 0;
      }
      return day;
    }
    final m = RegExp(r'(\d{1,2})').firstMatch(trimmed);
    return int.tryParse(m?.group(1) ?? '') ?? 0;
  }

  List<FlSpot> _pfMonthlyTrendSpots(List<double> values, List<String> sourceLabels) {
    if (values.isEmpty) return const [];
    final requireMonth = DateTime.now().month;
    final maxDay = _daysInCurrentMonth();
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      var day = (i < sourceLabels.length)
          ? _parseMonthDay(sourceLabels[i], requireMonth: requireMonth)
          : 0;
      if (day <= 0) day = i + 1;
      if (day < 1 || day > maxDay) continue;
      spots.add(FlSpot((day - 1).toDouble(), values[i]));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  List<double> _pfMonthlyTrendSolarFallback(List<double> trendSolar) {
    if (trendSolar.length >= 2 && trendSolar.any((v) => v > 0)) return trendSolar;
    final chartSolar = _live.chartSolarDailyKwh;
    if (chartSolar.length >= 2 && chartSolar.any((v) => v > 0)) return chartSolar;
    return trendSolar;
  }

  List<String> _pfMonthlyTrendLabelsFallback(List<String> trendLabels) {
    if (trendLabels.isNotEmpty) return trendLabels;
    if (_live.chartSolarDailyLabels.isNotEmpty) return _live.chartSolarDailyLabels;
    return _monthlyDayLabels();
  }

  List<String> _monthlyDayLabels() => List.generate(_daysInCurrentMonth(), (i) => '${i + 1}');

  List<FlSpot> _monthlyCalendarSpots(
    List<double> values,
    List<String> sourceLabels, {
    required double scale,
  }) {
    final requireMonth = DateTime.now().month;
    final maxDay = _daysInCurrentMonth();
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      var day = (i < sourceLabels.length)
          ? _parseMonthDay(sourceLabels[i], requireMonth: requireMonth)
          : 0;
      if (day <= 0) day = i + 1;
      if (day < 1 || day > maxDay) continue;
      final v = values[i];
      if (v <= 0) continue;
      spots.add(FlSpot((day - 1).toDouble(), v * scale));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  ({double min, double max}) _chartXBoundsMonthly() {
    final last = (_daysInCurrentMonth() - 1).toDouble();
    return (min: 0.0, max: last + 0.5);
  }

  ({double min, double max}) _chartXBounds(int pointCount, {bool monthly = false}) {
    if (pointCount <= 1) return (min: 0.0, max: 1.0);
    final last = (pointCount - 1).toDouble();
    if (monthly) return (min: 0.0, max: last + 1.0);
    return (min: -0.25, max: last + 0.55);
  }

  String _formatChartXLabel(String label, {required bool monthly}) {
    if (label.isEmpty) return '';
    if (!monthly) return _shortXLabel(label);
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return parts.last;
    final m = RegExp(r'(\d{1,2})').firstMatch(label);
    return m?.group(1) ?? label;
  }

  String _shortXLabel(String label) {
    if (label.length <= 5) return label;
    final m = RegExp(r'(\d{1,2}:\d{2})').firstMatch(label);
    return m?.group(1) ?? label;
  }

  int _xLabelStride(int count, {bool monthly = false}) {
    if (monthly) {
      if (count <= 10) return 2;
      if (count <= 20) return 4;
      return 5;
    }
    if (count <= 8) return 1;
    if (count <= 16) return 2;
    if (count <= 24) return 3;
    if (count <= 31) return 5;
    if (count <= 48) return 6;
    return (count / 6).ceil().clamp(4, 12);
  }

  double _maxPositive(List<double> values) {
    var max = 0.0;
    for (final v in values) {
      if (v > max) max = v;
    }
    return max;
  }

  List<LineChartBarData> _lineBarSegments(
    List<FlSpot> spots, {
    required Color color,
    required double barWidth,
    bool showFill = false,
    bool curved = true,
    List<int>? dashArray,
  }) {
    final bars = <LineChartBarData>[];
    var seg = <FlSpot>[];

    void flush() {
      if (seg.isEmpty) return;
      bars.add(LineChartBarData(
        spots: List<FlSpot>.from(seg),
        isCurved: curved && seg.length >= 2,
        preventCurveOverShooting: true,
        color: color,
        barWidth: barWidth,
        dashArray: dashArray,
        dotData: FlDotData(
          show: seg.length == 1,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 2.5,
            color: color,
            strokeWidth: 0,
          ),
        ),
        belowBarData: BarAreaData(
          show: showFill && seg.length >= 2,
          color: color.withOpacity(0.16),
        ),
      ));
      seg = [];
    }

    for (final s in spots) {
      if (s.y <= 0) {
        flush();
      } else {
        seg.add(s);
      }
    }
    flush();
    return bars;
  }

  double _chartMaxYMw(List<double> dataKw, {double? floorKw, bool extraHeadroom = false}) {
    final peakKw = _maxPositive(dataKw);
    final baseKw = floorKw != null && floorKw > peakKw ? floorKw : peakKw;
    if (baseKw <= 0) return 1.0;
    final mult = extraHeadroom ? 1.28 : 1.15;
    return (baseKw / 1000 * mult).clamp(0.15, 100.0);
  }

  double _chartMaxYMonthlyMwh(List<double> dataKwh) {
    final peak = _maxPositive(dataKwh);
    if (peak <= 0) return 1.0;
    // Generous headroom — monthly daily-energy series are large and flat, so
    // with only 15% headroom the filled curve towered over the whole card.
    return (peak / 1000 * 1.45).clamp(0.15, 500.0);
  }

  double _chartMaxYSolarKw(List<double> dataKw) {
    final peak = _maxOrZero(dataKw);
    if (peak <= 0) return 50.0;
    return (peak * 1.18).clamp(peak * 1.05, peak * 2.0);
  }

  Widget _chartArea(LineChart chart, {bool monthly = false}) => Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(2, monthly ? 10 : 4, 8, 6),
          child: chart,
        ),
      );

  List<FlSpot> _spots(List<double> values, {bool toMw = false}) {
    return List.generate(values.length, (i) => FlSpot(i.toDouble(), toMw ? values[i] / 1000 : values[i]));
  }

  double _maxOrZero(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double _niceStep(double maxY) {
    if (maxY <= 0.5) return 0.1;
    if (maxY <= 1.0) return 0.2;
    if (maxY <= 2.5) return 0.5;
    if (maxY <= 5.0) return 1.0;
    return (maxY / 5).ceilToDouble();
  }

  List<double> _solarForecast(List<double> actual) {
    if (actual.length < 4) return _live.hasData ? actual : _demoSolarKw;
    return List.generate(actual.length, (i) => actual[i] * (0.9 + (i % 4) * 0.02));
  }

  Widget _chartFooter({
    required String title,
    Widget? legend,
    required Widget chart,
    bool legendBesideTitle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (legendBesideTitle && legend != null)
        Row(children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            legend,
          ])
        else ...[
          Text(
            title,
            style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (legend != null) ...[const SizedBox(height: 2), legend],
        ],
        const SizedBox(height: 4),
        chart,
      ]),
    );
  }

  Widget _bottomCharts() {
    return Row(children: [
      Expanded(child: _panel(child: _loadChart())),
      const SizedBox(width: 10),
      Expanded(child: _panel(child: _mdChart())),
      const SizedBox(width: 10),
      Expanded(child: _panel(child: _solarChart())),
      const SizedBox(width: 10),
      Expanded(child: _panel(child: _blockBreakdown())),
    ]);
  }

  /// Power Flow mockup — Trend + By Block + Key Insights.
  Widget _powerFlowBottomCharts() {
    return Row(children: [
      Expanded(child: _panel(child: _powerFlowTrendChart())),
      const SizedBox(width: 12),
      Expanded(child: _panel(child: _powerFlowBlockBars())),
      const SizedBox(width: 12),
      Expanded(child: _panel(child: _powerFlowKeyInsights())),
    ]);
  }

  Widget _powerFlowTrendChart() {
    if (_pfIsMonthly) return _powerFlowTrendChartMonthly();

    final trendGrid = _pfTrendOr(_pfTrendGridLive, const <double>[]);
    final trendSolar = _pfTrendOr(_pfTrendSolarLive, const <double>[]);
    final trendTotal = _pfTrendTotalMerged(
        trendGrid, trendSolar, _pfTrendOr(_pfTrendTotalLive, const <double>[]));
    // Nothing measured yet. This used to fall back to a demo 24-hour curve, so
    // a lot whose every other figure read as a dash still showed a full day of
    // energy on the chart.
    if (!trendTotal.any((v) => v > 0) &&
        !trendGrid.any((v) => v > 0) &&
        !trendSolar.any((v) => v > 0)) {
      return _chartFooter(
        title: 'REAL-TIME ENERGY TREND',
        chart: Center(
          child: Text(
            'Awaiting live data',
            style: TextStyle(
                color: _sub.withOpacity(0.85),
                fontFamily: 'Poppins',
                fontSize: 14),
          ),
        ),
      );
    }
    final maxY = (_maxPositive(trendTotal) * 1.12).clamp(1000.0, 30000.0);
    final yStep = 6000.0;
    final now = DateTime.now();
    // Fractional hour for "now" marker (e.g. 10:48 → 10.8).
    final nowX = (now.hour + now.minute / 60.0).clamp(0.0, 23.0);
    final totalSpots = _spots(trendTotal);
    final gridSpots = _spots(trendGrid);
    final solarSpots = _spots(trendSolar);

    String fmtKwh(double v) {
      if (v >= 1000) return v.toStringAsFixed(0);
      if (v >= 100) return v.toStringAsFixed(1);
      return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 3);
    }

    String hourLabel(double x) {
      final h = x.floor().clamp(0, 23);
      final m = ((x - h) * 60).round().clamp(0, 59);
      // Snap to hour labels for hourly series; keep mm for now-line / fine hover.
      if (m == 0) return '${h.toString().padLeft(2, '0')}:00';
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    return _chartFooter(
      title: 'REAL-TIME ENERGY TREND',
      legend: Row(mainAxisSize: MainAxisSize.min, children: [
        _legendLine('Total', _white),
        const SizedBox(width: 10),
        _legendLine('Grid', _accentBlue),
        const SizedBox(width: 10),
        _legendLine('Solar', _accentG),
      ]),
      legendBesideTitle: true,
      chart: _chartArea(
        LineChart(
          LineChartData(
            minX: 0,
            maxX: 23,
            minY: 0,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yStep,
              getDrawingHorizontalLine: (_) => FlLine(color: _border1.withOpacity(0.65), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              verticalLines: [
                VerticalLine(
                  x: nowX,
                  color: _white.withOpacity(0.55),
                  strokeWidth: 1.2,
                  dashArray: const [5, 4],
                  label: VerticalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    style: TextStyle(
                      color: _white.withOpacity(0.75),
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (_) => hourLabel(nowX),
                  ),
                ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                axisNameWidget: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    'kWh',
                    style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                axisNameSize: 16,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: yStep,
                  getTitlesWidget: (v, _) {
                    if (v <= 0 || v > maxY) return const SizedBox.shrink();
                    final k = (v / 1000).round();
                    return Text('${k}k', style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 4,
                  getTitlesWidget: (v, _) {
                    final h = v.round();
                    if (h < 0 || h > 24 || h % 4 != 0) return const SizedBox.shrink();
                    final label = h == 24 ? '24:00' : '${h.toString().padLeft(2, '0')}:00';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: gridSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _accentBlue,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: solarSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _accentG,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: _accentG.withOpacity(0.12)),
              ),
              LineChartBarData(
                spots: totalSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _white,
                barWidth: 2.6,
                dotData: const FlDotData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((i) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: _accentBlue.withOpacity(0.85), strokeWidth: 1.2),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3.2,
                        color: bar.color ?? _white,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xF0101628),
                tooltipPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                tooltipRoundedRadius: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) {
                  if (spots.isEmpty) return [];
                  // Sort: Total (white) first, then Solar (green), then Grid (blue) — match mockup.
                  final ordered = [...spots]..sort((a, b) {
                      int rank(Color? c) {
                        if (c == _white) return 0;
                        if (c == _accentG) return 1;
                        if (c == _accentBlue) return 2;
                        return 3;
                      }
                      return rank(a.bar.color).compareTo(rank(b.bar.color));
                    });
                  final time = hourLabel(ordered.first.x);
                  return [
                    for (var i = 0; i < ordered.length; i++)
                      LineTooltipItem(
                        i == 0
                            ? '${fmtKwh(ordered[i].y)}\n'
                            : '${fmtKwh(ordered[i].y)}${i == ordered.length - 1 ? '\n$time' : '\n'}',
                        TextStyle(
                          color: ordered[i].bar.color ?? _white,
                          fontFamily: 'Poppins',
                          fontSize: i == ordered.length - 1 ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                  ];
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _powerFlowTrendChartMonthly() {
    final trendGrid = _pfTrendOr(_pfTrendGridLive, const <double>[]);
    var trendSolar = _pfTrendOr(_pfTrendSolarLive, const <double>[]);
    trendSolar = _pfMonthlyTrendSolarFallback(trendSolar);
    final sourceLabels = _pfMonthlyTrendLabelsFallback(_pfTrendLabelsLive);
    final trendTotal = _pfTrendTotalMerged(trendGrid, trendSolar, _pfTrendOr(_pfTrendTotalLive, const <double>[]));
    final xLabels = _monthlyDayLabels();
    final peakKwh = _maxPositive([
      ...trendTotal,
      ...trendGrid,
      ...trendSolar,
    ]);
    final maxY = peakKwh > 0 ? (peakKwh * 1.12).clamp(1000.0, 300000.0) : 1000.0;
    final yStep = (maxY / 5).clamp(1000.0, 50000.0);
    final totalSpots = _pfMonthlyTrendSpots(trendTotal, sourceLabels);
    final gridSpots = _pfMonthlyTrendSpots(trendGrid, sourceLabels);
    final solarSpots = _pfMonthlyTrendSpots(trendSolar, sourceLabels);
    final xBounds = _chartXBoundsMonthly();

    String fmtKwh(double v) {
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
      if (v >= 100) return v.toStringAsFixed(0);
      return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    }

    return _chartFooter(
      title: 'ENERGY TREND (Daily, This Month)',
      legend: Row(mainAxisSize: MainAxisSize.min, children: [
        _legendLine('Total', _white),
        const SizedBox(width: 10),
        _legendLine('Grid', _accentBlue),
        const SizedBox(width: 10),
        _legendLine('Solar', _accentG),
      ]),
      legendBesideTitle: true,
      chart: _chartArea(
        LineChart(
          LineChartData(
            minX: xBounds.min,
            maxX: xBounds.max,
            minY: 0,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yStep,
              getDrawingHorizontalLine: (_) => FlLine(color: _border1.withOpacity(0.65), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                axisNameWidget: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    'kWh',
                    style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                axisNameSize: 16,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: yStep,
                  getTitlesWidget: (v, _) {
                    if (v <= 0 || v > maxY) return const SizedBox.shrink();
                    return Text(fmtKwh(v), style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                    final stride = _xLabelStride(xLabels.length, monthly: true);
                    if (i != 0 && i != xLabels.length - 1 && i % stride != 0) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 4),
                      child: Text(
                        xLabels[i],
                        style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: gridSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _accentBlue,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: solarSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _accentG,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: _accentG.withOpacity(0.12)),
              ),
              LineChartBarData(
                spots: totalSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: _white,
                barWidth: 2.6,
                dotData: const FlDotData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xF0101628),
                tooltipPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                tooltipRoundedRadius: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) {
                  if (spots.isEmpty) return [];
                  final ordered = [...spots]..sort((a, b) {
                      int rank(Color? c) {
                        if (c == _white) return 0;
                        if (c == _accentG) return 1;
                        if (c == _accentBlue) return 2;
                        return 3;
                      }
                      return rank(a.bar.color).compareTo(rank(b.bar.color));
                    });
                  final day = ordered.first.x.round() + 1;
                  return [
                    for (var i = 0; i < ordered.length; i++)
                      LineTooltipItem(
                        i == 0
                            ? '${fmtKwh(ordered[i].y)} kWh\n'
                            : '${fmtKwh(ordered[i].y)} kWh${i == ordered.length - 1 ? '\nDay $day' : '\n'}',
                        TextStyle(
                          color: ordered[i].bar.color ?? _white,
                          fontFamily: 'Poppins',
                          fontSize: i == ordered.length - 1 ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                  ];
                },
              ),
            ),
          ),
        ),
        monthly: true,
      ),
    );
  }

  Widget _powerFlowBlockBars() {
    // Live bars when block*.total mapped; daily mock only when not monthly.
    final rows = <(String, double, String, String)>[];
    if (_pfIsMonthly) {
      final sorted = [..._live.pfBlocksMonthly.where((b) => b.totalRaw > 0)]
        ..sort((a, b) => b.totalRaw.compareTo(a.totalRaw));
      final plant = sorted.fold<double>(0, (s, b) => s + b.totalRaw);
      for (final b in sorted) {
        final pct = plant > 0 ? '${(b.totalRaw / plant * 100).toStringAsFixed(1)}%' : '—';
        rows.add((
          b.label.replaceFirst('BLOCK ', 'Block '),
          b.totalRaw,
          '${b.totalKwh} kWh',
          pct,
        ));
      }
    } else if (_live.pfBlocks.any((b) => b.totalRaw > 0)) {
      final sorted = [..._live.pfBlocks.where((b) => b.totalRaw > 0)]
        ..sort((a, b) => b.totalRaw.compareTo(a.totalRaw));
      final plant = sorted.fold<double>(0, (s, b) => s + b.totalRaw);
      for (final b in sorted) {
        final pct = plant > 0 ? '${(b.totalRaw / plant * 100).toStringAsFixed(1)}%' : '—';
        rows.add((
          b.label.replaceFirst('BLOCK ', 'Block '),
          b.totalRaw,
          '${b.totalKwh} kWh',
          pct,
        ));
      }
    }
    const cardKey = 'pf.blockBars';
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _sub;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    final titleSize = style.labelSize > 0 ? style.labelSize : 11.0;
    final rowLabelSize = style.labelSize > 0 ? style.labelSize : 11.0;
    final rowValueSize = style.valueSize > 0 ? style.valueSize.clamp(9.0, 14.0) : 10.0;
    if (rows.isEmpty) {
    return _editableCard(
      cardKey: cardKey,
      title: 'ENERGY CONSUMPTION BY BLOCK',
      card: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'ENERGY CONSUMPTION BY BLOCK',
            style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: titleSize, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                'Awaiting mapped block data',
                style: TextStyle(color: _sub.withOpacity(0.85), fontFamily: 'Poppins', fontSize: 11),
              ),
            ),
          ),
        ]),
      ),
      );
    }
    final maxV = rows.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    return _editableCard(
      cardKey: cardKey,
      title: 'ENERGY CONSUMPTION BY BLOCK',
      card: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'ENERGY CONSUMPTION BY BLOCK',
          style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: titleSize, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
        Expanded(
      child: Row(children: [
                  SizedBox(
                    width: 58,
                    child: Text(rows[i].$1, style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: rowLabelSize), maxLines: 1),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) {
                        final w = c.maxWidth * (rows[i].$2 / maxV).clamp(0.08, 1.0);
                        return Stack(children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(color: _border1.withOpacity(0.55), borderRadius: BorderRadius.circular(4)),
                          ),
                          Container(
                            width: w,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _accentBlue,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: _accentBlue.withOpacity(0.35), blurRadius: 8)],
                            ),
                          ),
                        ]);
                      },
                    ),
                  ),
          const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${rows[i].$3}  ${rows[i].$4}',
                      style: TextStyle(color: valueColor, fontFamily: 'Poppins', fontSize: rowValueSize, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ]),
      ),
    );
  }

  Widget _powerFlowKeyInsights() {
    final live = _pfIsMonthly ? _live.pfInsightsMonthly : _live.pfInsights;
    final items = <(IconData, Color, String)>[];
    if (live.isNotEmpty) {
      const icons = <(IconData, Color)>[
        (Icons.wb_sunny_outlined, _accentG),
        (Icons.settings_suggest_outlined, _accentBlue),
        (Icons.electrical_services_outlined, _accentO),
        (Icons.attach_money, _accentP),
      ];
      for (var i = 0; i < live.length; i++) {
        final style = icons[i % icons.length];
        items.add((style.$1, style.$2, live[i]));
      }
    }
    // The three percentages that used to sit here — 52.7%, 70.6%, 81.5% —
    // were written into the source. They read as findings about the plant and
    // were nothing of the kind, so with no live insight the list stays empty
    // and the panel says "Awaiting live insights" instead.
    final count = items.isEmpty ? 0 : items.length.clamp(1, 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'KEY INSIGHTS',
          style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: count == 0
              ? Center(
                  child: Text(
                    'Awaiting live insights',
                    style: TextStyle(color: _sub.withOpacity(0.85), fontFamily: 'Poppins', fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: count,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: _cardBg.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: items[i].$2.withOpacity(0.4)),
                    ),
                    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
      decoration: BoxDecoration(
                              color: items[i].$2.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(items[i].$1, color: items[i].$2, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              items[i].$3,
                              style: const TextStyle(
                                color: _white,
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _loadChart() {
    final isMonthly = _displayMode == 1;
    final series = isMonthly ? _live.chartLoadDailyKwh : _live.chartLoadKw;
    final data = _chartKwData(series, _demoLoadKw);
    final sourceLabels = isMonthly ? _live.chartLoadDailyLabels : _live.chartLoadLabels;
    final xLabels = isMonthly ? _monthlyDayLabels() : _chartLabelData(_live.chartLoadLabels, data.length);
    final maxY = isMonthly ? _chartMaxYMonthlyMwh(data) : _chartMaxYMw(data);
    final yStep = _niceStep(maxY);
    final spots = isMonthly
        ? _monthlyCalendarSpots(data, sourceLabels, scale: 1 / 1000)
        : List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i] / 1000));
    final xBounds = isMonthly ? _chartXBoundsMonthly() : _chartXBounds(spots.length);
    final lineBars = isMonthly
        ? _lineBarSegments(spots, color: _accentBlue, barWidth: 1.6, showFill: true)
        : [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: _accentBlue,
              barWidth: 1.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [_accentBlue.withOpacity(0.30), _accentBlue.withOpacity(0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ];
    return _chartFooter(
      title: isMonthly
          ? _label('chart.loadProfile', 'ACTUAL POWER (Daily, This Month)')
          : _label('chart.loadProfile', 'ACTUAL POWER'),
      chart: _chartArea(
          LineChart(
            LineChartData(
              minX: xBounds.min,
              maxX: xBounds.max,
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yStep,
                getDrawingHorizontalLine: (_) => FlLine(color: _border1.withOpacity(0.8), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _titlesData(yStep, isMw: true, xLabels: xLabels, maxY: maxY, monthly: isMonthly, yUnit: isMonthly ? 'MWh' : 'kWh'),
              lineBarsData: lineBars,
              lineTouchData: _tooltip(
                (v) => isMonthly ? '${v.toStringAsFixed(2)} MWh' : '${(v * 1000).toStringAsFixed(0)} kWh',
                xLabels,
                monthlySourceLabels: isMonthly ? sourceLabels : null,
              ),
            ),
          ),
          monthly: isMonthly,
        ),
    );
  }

  Widget _mdChart() {
    final isMonthly = _displayMode == 1;
    final dataKw = _chartKwData(isMonthly ? _live.chartMdDailyMaxKw : _live.chartMdKw, _demoMdKw);
    final sourceLabels = isMonthly ? _live.chartMdDailyLabels : _live.chartMdLabels;
    final xLabels = isMonthly
        ? _monthlyDayLabels()
        : _chartLabelData(_live.chartMdLabels, dataKw.length);
    final contractKw = _live.chartContractKw > 0 ? _live.chartContractKw : 2000.0;
    final maxY = _chartMaxYMw(dataKw, floorKw: contractKw, extraHeadroom: isMonthly);
    final yStep = _niceStep(maxY);
    final spots = isMonthly
        ? _monthlyCalendarSpots(dataKw, sourceLabels, scale: 1 / 1000)
        : _spots(dataKw, toMw: true);
    final xBounds = isMonthly ? _chartXBoundsMonthly() : _chartXBounds(spots.length);
    final lineBars = isMonthly
        ? _lineBarSegments(spots, color: _accentP, barWidth: 1.6, showFill: true, curved: true)
        : [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: _accentP,
              barWidth: 1.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: _accentP.withOpacity(0.16)),
            ),
          ];
    return _chartFooter(
      title: isMonthly
          ? _label('chart.mdProfile.actual', 'ACTUAL MD (Daily, This Month)')
          : _label('chart.mdProfile.actual', 'ACTUAL MD'),
      legendBesideTitle: isMonthly,
      legend: Row(mainAxisSize: MainAxisSize.min, children: [
        _legendLine('Actual MD', _accentP),
        const SizedBox(width: 6),
        _legendLine('Contract', _accentP.withOpacity(0.5), dashed: true),
      ]),
      chart: _chartArea(
          LineChart(
            LineChartData(
              minX: xBounds.min,
              maxX: xBounds.max,
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yStep,
                getDrawingHorizontalLine: (_) => FlLine(color: _border1.withOpacity(0.8), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _titlesData(yStep, isMw: true, xLabels: xLabels, maxY: maxY, monthly: isMonthly, yUnit: 'kW'),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: (contractKw / 1000).clamp(0, maxY),
                  color: _accentP.withOpacity(0.55),
                  dashArray: [8, 5],
                  strokeWidth: 1.5,
                ),
              ]),
              lineBarsData: lineBars,
              lineTouchData: _tooltip(
                (v) {
                final pct = contractKw > 0 ? (v * 1000 / contractKw * 100) : 0.0;
                return '${v.toStringAsFixed(2)} MW (${pct.toStringAsFixed(0)}%)';
              },
                xLabels,
                monthlySourceLabels: isMonthly ? sourceLabels : null,
              ),
            ),
          ),
          monthly: isMonthly,
        ),
    );
  }

  Widget _solarChart() {
    final isMonthly = _displayMode == 1;
    final actual = _chartKwData(isMonthly ? _live.chartSolarDailyKwh : _live.chartSolarKw, _demoSolarKw);
    final sourceLabels = isMonthly ? _live.chartSolarDailyLabels : _live.chartSolarLabels;
    final xLabels = isMonthly ? _monthlyDayLabels() : _chartLabelData(_live.chartSolarLabels, actual.length);
    final forecast = _solarForecast(actual);
    final maxY = isMonthly ? _chartMaxYMonthlyMwh(actual) : _chartMaxYSolarKw(actual);
    final yStep = _niceStep(maxY);
    final actualSpots = isMonthly
        ? _monthlyCalendarSpots(actual, sourceLabels, scale: 1 / 1000)
        : _spots(actual);
    final forecastSpots = isMonthly
        ? _monthlyCalendarSpots(forecast, sourceLabels, scale: 1 / 1000)
        : _spots(forecast);
    final xBounds = isMonthly ? _chartXBoundsMonthly() : _chartXBounds(actualSpots.length);
    final actualBars = isMonthly
        ? _lineBarSegments(actualSpots, color: _accentG, barWidth: 1.6, showFill: true)
        : [
            LineChartBarData(
              spots: actualSpots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: _accentG,
              barWidth: 1.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [_accentG.withOpacity(0.30), _accentG.withOpacity(0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ];
    return _chartFooter(
      title: isMonthly
          ? _label('chart.solar', 'SOLAR GENERATION (Daily, This Month)')
          : _label('chart.solar', 'SOLAR GENERATION'),
      legend: Row(children: [
        _legendLine('Solar', _accentG),
          const SizedBox(width: 8),
        _legendLine('Forecast', _accentG.withOpacity(0.55), dashed: true),
      ]),
      chart: _chartArea(
          LineChart(
            LineChartData(
              minX: xBounds.min,
              maxX: xBounds.max,
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yStep,
                getDrawingHorizontalLine: (_) => FlLine(color: _border1.withOpacity(0.8), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _titlesData(yStep, isMw: isMonthly, xLabels: xLabels, maxY: maxY, monthly: isMonthly, yUnit: isMonthly ? 'MWh' : 'kW'),
              lineBarsData: [
                ...actualBars,
                if (!isMonthly)
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: _accentG.withOpacity(0.75),
                    barWidth: 1.4,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
              lineTouchData: _tooltip(
                (v) => isMonthly ? '${v.toStringAsFixed(2)} MWh' : '${v.toStringAsFixed(0)} kW',
                xLabels,
                monthlySourceLabels: isMonthly ? sourceLabels : null,
              ),
            ),
          ),
          monthly: isMonthly,
        ),
    );
  }

  FlTitlesData _titlesData(
    double yStep, {
    required bool isMw,
    required double maxY,
    List<String> xLabels = const [],
    bool monthly = false,
    String? yUnit,
  }) {
    final stride = _xLabelStride(xLabels.isNotEmpty ? xLabels.length : 24, monthly: monthly);
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: monthly ? 28 : 32,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.round();
            if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
            if (monthly) {
              if (i == 0 || i == xLabels.length - 1) {
                // always show 1st and last day of month
              } else if (i % stride != 0) {
                return const SizedBox.shrink();
              }
            } else if (i % stride != 0 && i != xLabels.length - 1) {
              return const SizedBox.shrink();
            }
            final label = monthly ? xLabels[i] : _formatChartXLabel(xLabels[i], monthly: false);
            if (label.isEmpty) return const SizedBox.shrink();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 4),
              child: Text(
                label,
                style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 52,
          interval: yStep,
          getTitlesWidget: (value, meta) {
            if (value < -0.01 || value > maxY + 0.01) return const SizedBox.shrink();
            final num = isMw ? value.toStringAsFixed(1) : value.toInt().toString();
            final unit = yUnit ?? (isMw ? (monthly ? 'MWh' : 'MW') : 'kW');
            final text = '$num $unit';
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 2),
              child: Text(
                text,
                style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
    );
  }

  LineTouchData _tooltip(
    String Function(double y) valueFormatter,
    List<String> xLabels, {
    List<String>? monthlySourceLabels,
  }) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => const Color(0xE6101628),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        getTooltipItems: (spots) {
          return spots.map((s) {
            final i = s.x.round();
            String time;
            if (monthlySourceLabels != null && monthlySourceLabels.isNotEmpty) {
              final day = i + 1;
              time = monthlySourceLabels.firstWhere(
                (l) => _parseMonthDay(l) == day,
                orElse: () => 'Day $day',
              );
            } else {
              time = i >= 0 && i < xLabels.length ? xLabels[i] : '${i.toString().padLeft(2, '0')}:00';
            }
            return LineTooltipItem(
              '${valueFormatter(s.y)}\n$time',
              const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _legendLine(String label, Color c, {bool dashed = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 14,
          height: 2.5,
      decoration: BoxDecoration(
            color: dashed ? Colors.transparent : c,
            borderRadius: BorderRadius.circular(2),
            border: dashed ? Border.all(color: c, width: 1.2) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10)),
      ]);

  Widget _blockBreakdown() {
    final rows = _live.blockBreakdown;
  double _parseKwh(String display) {
    final m = RegExp(r'([\d,]+(?:\.\d+)?)').firstMatch(display);
    return double.tryParse(m?.group(1)?.replaceAll(',', '') ?? '') ?? 0;
  }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _label('table.blockBreakdown', 'ENERGY CONSUMPTION BY BLOCK'),
          style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'No data — map flow.blockA/B/C in settings',
                    style: TextStyle(color: _sub.withOpacity(0.8), fontFamily: 'Poppins', fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final values = rows.map((r) => _parseKwh(r.kwhDisplay)).toList();
                    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
                    final maxY = maxV > 0 ? maxV * 1.15 : 1.0;
                    final yStep = _niceStep(maxY / 1000) * 1000;
                    final yInterval = yStep > 0 ? yStep : maxY / 4;
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (_) => FlLine(color: _border1.withOpacity(0.55), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: yInterval,
                              getTitlesWidget: (v, _) {
                                if (v <= 0 || v > maxY) return const SizedBox.shrink();
                                final k = (v / 1000).round();
                                return Text('${k}k', style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final i = v.round();
                                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    rows[i].label.replaceFirst('Block ', 'B'),
                                    style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < rows.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: values[i],
                                  width: 28,
                                  color: _accentBlue,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(color: _border1, height: 1),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              _v(_live.blockBreakdownTotal),
              style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Shared UI ─────────────────────────────────────────────────────────────
  Widget _panel({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(color: _panelBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border1)),
          child: child,
        ),
      );

  Widget _panelHeader(String title, String suffix) => Row(children: [
        Text(title, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        if (suffix.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(suffix, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12)),
        ],
      ]);

  Widget _glass({required Color accent, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(Colors.white.withOpacity(0.02), _cardBg.withOpacity(0.88)),
                Color.alphaBlend(Colors.black.withOpacity(0.30), _cardBg.withOpacity(0.88)),
              ],
            ),
            border: Border.all(color: accent.withOpacity(0.45)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _chip(String delta, bool down) {
    final color = down ? _accentG : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(down ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 11),
        const SizedBox(width: 3),
        Text(delta, style: TextStyle(color: color, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Painters ─────────────────────────────────────────────────────────────────
class _Spark extends CustomPainter {
  final Color color;
  _Spark(this.color);
  static const _pts = [0.5, 0.35, 0.55, 0.3, 0.6, 0.25, 0.45, 0.2];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    for (int i = 0; i < _pts.length; i++) {
      final x = size.width * (i / (_pts.length - 1));
      final y = size.height * _pts[i];
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    canvas.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _Spark old) => old.color != color;
}

/// Blue grid supply lines only — GRID (TNB) bus up into each block (no top solar bus).
class _PowerFlowGridLinesPainter extends CustomPainter {
  final List<Rect> blockRects;
  final Rect gridRect;
  final double supplyBusY;
  final bool gridOnRight;
  final double pulse;

  _PowerFlowGridLinesPainter({
    required this.blockRects,
    required this.gridRect,
    required this.supplyBusY,
    this.gridOnRight = false,
    this.pulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (blockRects.isEmpty) return;

    final s = (size.width / 1260).clamp(0.88, 1.18);
    const bright = Color(0xFF00E5FF);  // neon cyan
    const bodyW  = 16.0;
    const arrowSz = 18.0;

    final startX = gridOnRight ? gridRect.left : gridRect.right;
    final trunkY = supplyBusY;
    final lastBlock = blockRects.last;
    final lastX = lastBlock.center.dx;
    final R = 18.0 * s;

    // Tap point on building row — just below card (feeder stops before overlapping card body).
    double feedTipY(Rect b) => b.bottom + 6 * s;

    // Horizontal trunk along dedicated bus, then risers into each block.
    final trunkLine = gridOnRight
        ? (Path()
          ..moveTo(startX, trunkY)
          ..lineTo(lastX + R, trunkY)
          ..quadraticBezierTo(lastX, trunkY, lastX, trunkY - R)
          ..lineTo(lastX, feedTipY(lastBlock) + arrowSz * s))
        : (Path()
          ..moveTo(startX, trunkY)
          ..lineTo(lastX - R, trunkY)
          ..quadraticBezierTo(lastX, trunkY, lastX, trunkY - R)
          ..lineTo(lastX, feedTipY(lastBlock) + arrowSz * s));

    final branches = <Path>[trunkLine];
    final branchOffsets = <double>[0.0];

    for (int i = 0; i < blockRects.length - 1; i++) {
      final b = blockRects[i];
      final x = b.center.dx;
      final tipY = feedTipY(b);

      final branch = gridOnRight
          ? (Path()
            ..moveTo(x + R, trunkY)
            ..quadraticBezierTo(x, trunkY, x, trunkY - R)
            ..lineTo(x, tipY + arrowSz * s))
          : (Path()
            ..moveTo(x - R, trunkY)
            ..quadraticBezierTo(x, trunkY, x, trunkY - R)
            ..lineTo(x, tipY + arrowSz * s));

      branches.add(branch);
      branchOffsets.add(gridOnRight ? startX - (x + R) : (x - R) - startX);
    }

    // ── For each path: draw glassy neon tube ────────────────────────────────
    for (int i = 0; i < branches.length; i++) {
      final path = branches[i];
      final offset = branchOffsets[i];

      // 1. Neon Glow Halo
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bodyW * s + 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = bright.withOpacity(0.13));

      // 2. Glass tube body
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bodyW * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = bright.withOpacity(0.32));

      // 3. Spine highlight
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withOpacity(0.38));

      // 4. Glassy reflection sweep (Synchronized!)
      final metrics = path.computeMetrics().toList();
      const gap = 200.0;
      const sweepLen = 100.0;
      final shift = pulse * gap;
      
      for (final m in metrics) {
        final len = m.length;
        if (len < 20) continue;
        
        // Subtract the physical offset so the dash arrives at the branch 
        // at the exact moment it travels that far along the trunk.
        var dist = (shift - offset) % gap - gap;
        
        while (dist < len) {
          final start = dist;
          final end = dist + sweepLen;
          if (end > 0 && start < len) {
            final extract = m.extractPath(start.clamp(0.0, len), end.clamp(0.0, len));
            // Wide soft glare
            canvas.drawPath(extract, Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = bodyW * s * 0.8
              ..strokeCap = StrokeCap.round
              ..color = bright.withOpacity(0.50)
              ..imageFilter = ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0));
            // Intense white core
            canvas.drawPath(extract, Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = bodyW * s * 0.35
              ..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.82));
          }
          dist += gap;
        }
      }
    }

    // ── Arrowheads pointing UP at each block ──────────────────────────────────
    for (final b in blockRects) {
      final x = b.center.dx;
      final tipY = b.bottom + 2 * s;
      
      // Energy Flow style chevron arrowhead (concave/V-notched)
      final angle = -1.5708; // -pi/2 (pointing UP)
      final tip = Offset(x, tipY);
      final wing = arrowSz * s * 1.25;
      final tail = arrowSz * s * 0.55;
      
      // Calculate points
      final p1 = tip + Offset(math.cos(angle + 2.5) * wing, math.sin(angle + 2.5) * wing);
      final p2 = tip + Offset(math.cos(angle - 2.5) * wing, math.sin(angle - 2.5) * wing);
      final notch = tip + Offset(math.cos(angle + 3.14159) * tail, math.sin(angle + 3.14159) * tail);
      
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(notch.dx, notch.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      // Outer soft glow
      canvas.drawPath(head, Paint()
        ..color = bright.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0));
        
      // Solid fill
      canvas.drawPath(head, Paint()
        ..color = bright
        ..style = PaintingStyle.fill);
        
      // Bright white tip highlight
      final tipHighlight = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(tip.dx, tip.dy + tail * 0.8)
        ..close();
      canvas.drawPath(tipHighlight, Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _PowerFlowGridLinesPainter old) =>
      old.gridRect != gridRect ||
      old.blockRects != blockRects ||
      old.gridOnRight != gridOnRight ||
      old.pulse != pulse;
}

/// Neon wireframe transmission tower (Power Flow mockup GRID style).
class _TransmissionTowerPainter extends CustomPainter {
  final Color color;
  final double glow;
  _TransmissionTowerPainter({required this.color, this.glow = 0.7});

  void _stroke(Canvas canvas, Path path, {double width = 1.8}) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.22 * glow)
      ..style = PaintingStyle.stroke
        ..strokeWidth = width + 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
          ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _dot(Canvas canvas, Offset o, {double r = 2.4}) {
    canvas.drawCircle(o, r + 2.2, Paint()..color = color.withOpacity(0.25 * glow)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(o, r, Paint()..color = color);
    canvas.drawCircle(o, r * 0.45, Paint()..color = Colors.white.withOpacity(0.9));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final top = h * 0.06;
    final bottom = h * 0.98;

    // Outer tapered legs
    final leftLeg = Path()
      ..moveTo(cx - w * 0.07, top + h * 0.10)
      ..lineTo(cx - w * 0.36, bottom);
    final rightLeg = Path()
      ..moveTo(cx + w * 0.07, top + h * 0.10)
      ..lineTo(cx + w * 0.36, bottom);
    _stroke(canvas, leftLeg, width: 2.0);
    _stroke(canvas, rightLeg, width: 2.0);

    // Peak
    final peak = Path()
      ..moveTo(cx - w * 0.07, top + h * 0.10)
      ..lineTo(cx, top)
      ..lineTo(cx + w * 0.07, top + h * 0.10);
    _stroke(canvas, peak, width: 1.8);

    // Cross-arms (3 levels) with insulator hangs
    final arms = <double>[0.16, 0.32, 0.48];
    final armW = <double>[0.38, 0.32, 0.26];
    for (var i = 0; i < arms.length; i++) {
      final y = top + h * arms[i];
      final hw = w * armW[i];
      _stroke(canvas, Path()..moveTo(cx - hw, y)..lineTo(cx + hw, y), width: 1.7);
      // Insulator drops
      for (final side in [-1.0, 1.0]) {
        final x = cx + side * hw;
        _stroke(canvas, Path()..moveTo(x, y)..lineTo(x, y + h * 0.07), width: 1.4);
        _dot(canvas, Offset(x, y + h * 0.07), r: 2.1);
      }
    }

    // Lattice X braces between arms / legs
    final ys = [0.16, 0.32, 0.48, 0.64, 0.80].map((t) => top + h * t).toList();
    for (var i = 0; i < ys.length - 1; i++) {
      final y0 = ys[i];
      final y1 = ys[i + 1];
      final t0 = (y0 - top) / (bottom - top);
      final t1 = (y1 - top) / (bottom - top);
      final half0 = w * (0.07 + 0.29 * t0);
      final half1 = w * (0.07 + 0.29 * t1);
      _stroke(
        canvas,
        Path()
          ..moveTo(cx - half0 * 0.55, y0)
          ..lineTo(cx + half1 * 0.55, y1)
          ..moveTo(cx + half0 * 0.55, y0)
          ..lineTo(cx - half1 * 0.55, y1),
        width: 1.35,
      );
      // Mid horizontal tie
      _stroke(canvas, Path()..moveTo(cx - half0 * 0.55, y0)..lineTo(cx + half0 * 0.55, y0), width: 1.2);
    }

    // Tip light
    _dot(canvas, Offset(cx, top), r: 2.6);
  }

  @override
  bool shouldRepaint(covariant _TransmissionTowerPainter old) => old.color != color || old.glow != glow;
}

class _FlowLinesPainter extends CustomPainter {
  final Map<String, ({Offset cardBottom, Offset cardTop, Offset center, Size size})> layouts;
  final String hubKey;
  final int tab;
  final double pulse;
  final Map<String, double> intensities;

  _FlowLinesPainter({
    required this.layouts,
    required this.hubKey,
    required this.tab,
    required this.pulse,
    this.intensities = const {},
  });

  // ── Path helpers ──────────────────────────────────────────────────────────

  /// Rounded L-route: block top → horizontal bus bar → up into hub bottom.
  Path _blockToHubPath(Offset from, Offset to,
      {bool straight = false, double busFactor = 0.42}) {
    if (straight) {
      return Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
    const r = 18.0;
    final busY = to.dy + (from.dy - to.dy) * busFactor;
    final goLeft = to.dx < from.dx;
    final path = Path()..moveTo(from.dx, from.dy);
    // up from block top → bus-bar level
    path.lineTo(from.dx, busY + r);
    path.quadraticBezierTo(from.dx, busY, from.dx + (goLeft ? -r : r), busY);
    // horizontal along bus bar toward hub
    path.lineTo(to.dx + (goLeft ? r : -r), busY);
    path.quadraticBezierTo(to.dx, busY, to.dx, busY - r);
    // vertical up into hub bottom
    path.lineTo(to.dx, to.dy);
    return path;
  }

  Path _straightPath(Offset from, Offset to) => Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(to.dx, to.dy);

  ({Offset from, Offset to}) _blockEndpoints(
    ({Offset cardBottom, Offset cardTop, Offset center, Size size}) block,
    ({Offset cardBottom, Offset cardTop, Offset center, Size size}) hub,
    String key,
  ) {
    final xShift = switch (key) {
      'blockA' => -hub.size.width * 0.30,
      'blockC' => hub.size.width * 0.30,
      _ => 0.0,
    };
    final hubX = key == 'blockB' ? hub.center.dx : hub.center.dx + xShift;
    final fromX = key == 'blockB' ? hub.center.dx : block.center.dx;
    return (
      from: Offset(fromX, block.cardTop.dy),
      to: Offset(hubX, hub.cardBottom.dy),
    );
  }

  ({Offset from, Offset to}) _solarEndpoints(
    ({Offset cardBottom, Offset cardTop, Offset center, Size size}) solar,
    ({Offset cardBottom, Offset cardTop, Offset center, Size size}) hub,
  ) {
    return (
      from: Offset(solar.center.dx - solar.size.width * 0.50, solar.center.dy),
      to: Offset(hub.center.dx + hub.size.width * 0.50, hub.center.dy),
    );
  }

  // ── Arrow tip ─────────────────────────────────────────────────────────────

  void _drawArrowHead(Canvas canvas, Offset tip, double angle,
      Color bright, Color mid, {double size = 18.0, double opacity = 1.0}) {
    final wing = size * 1.25;
    final tail = size * 0.55;
    // Concave / V-notched arrowhead — same bold look as reference.
    final p1 = tip + Offset(math.cos(angle + 2.5) * wing, math.sin(angle + 2.5) * wing);
    final p2 = tip + Offset(math.cos(angle - 2.5) * wing, math.sin(angle - 2.5) * wing);
    final notch = tip +
        Offset(math.cos(angle + math.pi) * tail, math.sin(angle + math.pi) * tail);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    // Outer soft glow
    canvas.drawPath(head, Paint()..color = mid.withOpacity(0.28 * opacity));
    // Solid fill
    canvas.drawPath(
      head,
      Paint()
        ..color = bright.withOpacity(0.95 * opacity)
        ..style = PaintingStyle.fill,
    );
    // Bright white tip
    canvas.drawCircle(tip, size * 0.20,
        Paint()..color = Colors.white.withOpacity(0.95 * opacity));
  }

  // ── Thick ribbon ──────────────────────────────────────────────────────────

  void _drawRibbon(
    Canvas canvas,
    Path path,
    Offset gradFrom,
    Offset gradTo,
    Color bright,
    Color core, {
    required Offset arrowTip,
    required double arrowAngle,
    double bodyW = 22.0,
    double arrowSize = 20.0,
    double opacity = 1.0,
  }) {
    // 1. Neon Glow Halo (Ambient light from the tube)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bodyW + 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = bright.withOpacity(0.15 * opacity),
    );

    // 2. Glass Tube Body (Translucent neon base)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bodyW
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = bright.withOpacity(0.35 * opacity),
    );

    // 3. Glass Tube Edge Highlights (Creates cylindrical illusion)
    // We simulate edges by drawing a slightly thinner stroke inside with a darker/base color,
    // which leaves the outer edges looking thicker and more illuminated like glass walls.
    // Wait, adding opacity makes it brighter. Instead, we add a very thin bright spine highlight.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withOpacity(0.4 * opacity),
    );

    // 4. Glassy Reflection Animation (Sweeping glare along the tube)
    final metrics = path.computeMetrics().toList();
    const gap = 200.0;
    const sweepLen = 100.0;
    final shift = pulse * gap; // Flawless seamless loop

    for (final m in metrics) {
      final len = m.length;
      if (len < 20) continue;
      
      var dist = shift - gap;
      while (dist < len) {
        final start = dist;
        final end = dist + sweepLen;
        
        if (end > 0 && start < len) {
          final extract = m.extractPath(start.clamp(0.0, len), end.clamp(0.0, len));
          
          // Wide soft glare
          canvas.drawPath(
            extract,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = bodyW * 0.8
              ..strokeCap = StrokeCap.round
              ..color = bright.withOpacity(0.5 * opacity)
              ..imageFilter = ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          );
          
          // Intense white core reflection
          canvas.drawPath(
            extract,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = bodyW * 0.35
              ..strokeCap = StrokeCap.round
              ..color = Colors.white.withOpacity(0.85 * opacity),
          );
        }
        dist += gap;
      }
    }

    // 5. Arrowhead on top
    _drawArrowHead(canvas, arrowTip, arrowAngle, bright, core,
        size: arrowSize, opacity: opacity);
  }

  // ── paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final hub = layouts[hubKey];
    if (hub == null) return;

    // Cyan block lines (matching reference image)
    const blockBright = Color(0xFF7EEEFF);
    const blockCore = Color(0xFF00AADD);
    // Green solar line
    const solarBright = Color(0xFF80FFB8);
    const solarCore = Color(0xFF00C864);

    void drawBlocks({double opacity = 1.0}) {
      const blockKeys = ['blockA', 'blockB', 'blockC'];
      for (final key in blockKeys) {
        final l = layouts[key];
        if (l == null) continue;
        final intensity = intensities[key] ?? 0.5;
        final pts = _blockEndpoints(l, hub, key);
        final busFactor =
            key == 'blockA' ? 0.38 : (key == 'blockC' ? 0.48 : 0.42);
        final path = _blockToHubPath(pts.from, pts.to,
            straight: key == 'blockB', busFactor: busFactor);
        _drawRibbon(
          canvas, path, pts.from, pts.to, blockBright, blockCore,
          arrowTip: pts.to,
          arrowAngle: -math.pi / 2,
          bodyW: 20.0 + intensity * 4.0,
          arrowSize: 20.0 + intensity * 3.0,
          opacity: opacity,
        );
      }
    }

    void drawSolar({double opacity = 1.0}) {
      final solar = layouts['solar'];
      if (solar == null) return;
      final intensity = intensities['solar'] ?? 0.5;
      final pts = _solarEndpoints(solar, hub);
      final path = _straightPath(pts.from, pts.to);
      _drawRibbon(
        canvas, path, pts.from, pts.to, solarBright, solarCore,
        arrowTip: pts.to,
        arrowAngle: math.pi,
        bodyW: 14.0 + intensity * 3.0,
        arrowSize: 16.0 + intensity * 2.0,
        opacity: opacity,
      );
    }

    if (tab == 0) {
      drawSolar();
      drawBlocks();
    } else if (tab == 2) {
      drawBlocks(opacity: 0.12);
      drawSolar(opacity: 1.0);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowLinesPainter old) =>
      old.tab != tab ||
      old.pulse != pulse ||
      old.layouts != layouts ||
      old.intensities != intensities;
}


class _AnimatedIsometricGridPainter extends CustomPainter {
  final double pulse;
  
  _AnimatedIsometricGridPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0A0F20);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.35)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;

    canvas.save();
    // Center the grid
    canvas.translate(size.width / 2, size.height / 2);
    
    // Isometric projection: scale Y by ~0.5, then rotate by 45 degrees
    canvas.scale(1.0, 0.55);
    canvas.rotate(math.pi / 4);

    const double cellSize = 55.0;
    const int lines = 24;
    
    // Animate translation along X and Y to make it look like the grid is moving continuously
    // A full cell shift happens every pulse loop (0.0 to 1.0)
    final shift = pulse * cellSize;
    canvas.translate(shift, shift); // Moving forward

    for (int i = -lines; i <= lines; i++) {
      final double offset = i * cellSize;
      final double edge = lines * cellSize;
      
      // Draw vertical lines
      final p1 = Offset(offset, -edge);
      final p2 = Offset(offset, edge);
      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy), linePaint);
      if (i % 4 == 0) canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy), glowPaint);

      // Draw horizontal lines
      final p3 = Offset(-edge, offset);
      final p4 = Offset(edge, offset);
      canvas.drawPath(Path()..moveTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy), linePaint);
      if (i % 4 == 0) canvas.drawPath(Path()..moveTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy), glowPaint);
    }
    
    canvas.restore();
    
    // Vignette mask for depth fade-out at the edges
    final grad = RadialGradient(
      colors: [Colors.transparent, const Color(0xFF060810).withOpacity(0.95), const Color(0xFF060810)],
      stops: const [0.2, 0.8, 1.0],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = grad);
  }

  @override
  bool shouldRepaint(covariant _AnimatedIsometricGridPainter old) => old.pulse != pulse;
}

class _AmbientParticlesPainter extends CustomPainter {
  final double pulse;
  _AmbientParticlesPainter({required this.pulse});

  static const _pts = <(double x, double y, double phase)>[
    (0.18, 0.62, 0.0),
    (0.35, 0.48, 0.2),
    (0.52, 0.72, 0.45),
    (0.68, 0.38, 0.65),
    (0.82, 0.58, 0.85),
    (0.42, 0.28, 0.35),
    (0.58, 0.18, 0.55),
    (0.28, 0.82, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final t = (pulse + p.$3) % 1.0;
      final x = size.width * p.$1 + 6 * (t - 0.5);
      final y = size.height * p.$2 + 4 * (0.5 - t);
      final alpha = 0.12 + 0.28 * (0.5 - (t - 0.5).abs());
      canvas.drawCircle(Offset(x, y), 2.2 + t, Paint()..color = const Color(0xFF31ECFC).withOpacity(alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientParticlesPainter old) => old.pulse != pulse;
}

class _LiveCountText extends StatefulWidget {
  final String value;
  final TextStyle style;
  final TextAlign? textAlign;
  final int tick;

  const _LiveCountText({required this.value, required this.style, this.textAlign, this.tick = 0});

  @override
  State<_LiveCountText> createState() => _LiveCountTextState();
}

class _LiveCountTextState extends State<_LiveCountText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _from = 0;
  double _to = 0;
  int _decimals = 0;
  bool _useCommas = false;
  String _prefix = '';
  String _suffix = '';
  int _lastTick = 0;
  String _lastValue = '';

  bool _hasNumber(String raw) => raw != '—' && raw.isNotEmpty && RegExp(r'\d').hasMatch(raw);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _lastTick = widget.tick;
    _lastValue = widget.value;
    _parse(widget.value);
    _startAnimation(fromZero: _hasNumber(widget.value));
  }

  void _startAnimation({required bool fromZero}) {
    if (!_hasNumber(widget.value)) {
      _from = 0;
      _to = 0;
      _ctrl.value = 1;
      return;
    }
    if (fromZero) {
      _from = 0;
      _ctrl.forward(from: 0);
    } else {
      _from = _to;
      _ctrl.value = 1;
    }
  }

  void _parse(String raw) {
    _prefix = '';
    _suffix = '';
    _decimals = 0;
    _useCommas = false;
    _to = 0;
    if (!_hasNumber(raw)) return;
    final m = RegExp(r'(\d[\d,]*(?:\.\d+)?)').firstMatch(raw);
    if (m == null) return;
    final numStr = m.group(1)!;
    _prefix = raw.substring(0, m.start);
    _suffix = raw.substring(m.end);
    _useCommas = numStr.contains(',');
    final dot = numStr.indexOf('.');
    _decimals = dot >= 0 ? numStr.length - dot - 1 : 0;
    _to = double.tryParse(numStr.replaceAll(',', '')) ?? 0;
  }

  String _format(double v) {
    if (!_hasNumber(widget.value)) return widget.value;
    String out;
    if (_decimals > 0) {
      out = v.toStringAsFixed(_decimals);
      if (_useCommas) {
        final p = out.split('.');
        out = '${_LotCountFmt.thousands(p[0])}.${p[1]}';
      }
    } else {
      final s = v.round().toString();
      out = _useCommas ? _LotCountFmt.thousands(s) : s;
    }
    return '$_prefix$out$_suffix';
  }

  @override
  void didUpdateWidget(covariant _LiveCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valueChanged = oldWidget.value != widget.value;
    final tickChanged = oldWidget.tick != widget.tick;
    if (!valueChanged && !tickChanged) return;
    if (tickChanged && !valueChanged) return;

    final wasEmpty = !_hasNumber(oldWidget.value);
    final nowHas = _hasNumber(widget.value);
    if (wasEmpty && nowHas) {
      _from = 0;
      _parse(widget.value);
      _ctrl.forward(from: 0);
    } else if (nowHas && valueChanged) {
      _parse(widget.value);
      if (tickChanged) {
        _from = _to;
        _ctrl.value = 1;
      } else {
        _from = _from + (_to - _from) * Curves.easeOutCubic.transform(_ctrl.value);
        _ctrl.forward(from: 0);
      }
    } else if (!nowHas) {
      _parse(widget.value);
      _from = 0;
      _to = 0;
      _ctrl.value = 1;
    }
    _lastTick = widget.tick;
    _lastValue = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasNumber(widget.value)) {
      return Text(widget.value, style: widget.style, textAlign: widget.textAlign);
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Text(_format(_from + (_to - _from) * t), style: widget.style, textAlign: widget.textAlign);
      },
    );
  }
}

class _LotCountFmt {
  static String thousands(String d) {
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && (d.length - i) % 3 == 0) b.write(',');
      b.write(d[i]);
    }
    return b.toString();
  }
}

class _TowerElectricPulsePainter extends CustomPainter {
  final double pulse;

  _TowerElectricPulsePainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cyan = Color(0xFF00E5FF);

    // 1) Pulsing electrical aura glow at tower head & base
    final glowOp = (0.25 + 0.35 * math.sin(pulse * math.pi * 2)).clamp(0.1, 0.6);
    final auraPaint = Paint()
      ..color = cyan.withOpacity(glowOp * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), w * 0.35, auraPaint);

    // 2) Moving electrical sparks travelling up the tower body
    final sparkPaint = Paint()
      ..color = cyan.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final sparkGlow = Paint()
      ..color = cyan.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < 4; i++) {
      final progress = (pulse + i * 0.25) % 1.0;
      final sparkY = h * 0.85 - progress * (h * 0.55);
      final sparkX = w * 0.35 + math.sin(progress * math.pi * 4 + i) * (w * 0.08);
      canvas.drawCircle(Offset(sparkX, sparkY), 3.0 + (1 - progress) * 2.0, sparkGlow);
      canvas.drawCircle(Offset(sparkX, sparkY), 2.0, sparkPaint);
    }

    // 3) Electrical arc flashes across top cross-arms
    final arcProgress = (pulse * 3) % 1.0;
    if (arcProgress > 0.4 && arcProgress < 0.8) {
      final arcPaint = Paint()
        ..color = cyan.withOpacity((1.0 - ((arcProgress - 0.6).abs() * 5)).clamp(0.0, 0.9))
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(w * 0.15, h * 0.28)
        ..lineTo(w * 0.30, h * 0.27)
        ..lineTo(w * 0.45, h * 0.29)
        ..lineTo(w * 0.55, h * 0.28);
      canvas.drawPath(path, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TowerElectricPulsePainter old) => old.pulse != pulse;
}

class _IsometricSubstationPainter extends CustomPainter {
  final double pulse;

  _IsometricSubstationPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const cyan = Color(0xFF00E5FF);
    const orange = Color(0xFFF59E0B);
    const electricBlue = Color(0xFF38BDF8);

    final s = w / 300.0; // Scale factor

    // ── 1. Glassmorphic Hologram Isometric Base Platform ─────────────────────
    final platPath = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.95, h * 0.65)
      ..lineTo(w * 0.5, h * 0.95)
      ..lineTo(w * 0.05, h * 0.75)
      ..close();

    // Soft glass fill — lets the background aerial photo shine through
    final platPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.40)
      ..style = PaintingStyle.fill;
    canvas.drawPath(platPath, platPaint);

    final platGlow = Paint()
      ..color = cyan.withOpacity(0.45)
      ..strokeWidth = 2.0 * s
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;
    canvas.drawPath(platPath, platGlow);

    final platBorder = Paint()
      ..color = cyan.withOpacity(0.8)
      ..strokeWidth = 1.2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawPath(platPath, platBorder);

    // Platform 3D Edge
    final edgePath = Path()
      ..moveTo(w * 0.05, h * 0.75)
      ..lineTo(w * 0.5, h * 0.95)
      ..lineTo(w * 0.95, h * 0.65)
      ..lineTo(w * 0.95, h * 0.68)
      ..lineTo(w * 0.5, h * 0.98)
      ..lineTo(w * 0.05, h * 0.78)
      ..close();
    canvas.drawPath(edgePath, Paint()..color = const Color(0xFF020617).withOpacity(0.55)..style = PaintingStyle.fill);

    // ── 2. Animated Holographic Floor Circuit Traces ───────────────────────
    final trace1 = Path()
      ..moveTo(w * 0.20, h * 0.72)
      ..lineTo(w * 0.35, h * 0.79)
      ..lineTo(w * 0.45, h * 0.74)
      ..lineTo(w * 0.65, h * 0.83);

    final trace2 = Path()
      ..moveTo(w * 0.45, h * 0.74)
      ..lineTo(w * 0.52, h * 0.70)
      ..lineTo(w * 0.72, h * 0.79);

    final circuitPaint = Paint()
      ..color = cyan.withOpacity(0.7)
      ..strokeWidth = 2.0 * s
      ..style = PaintingStyle.stroke;
    canvas.drawPath(trace1, circuitPaint);
    canvas.drawPath(trace2, circuitPaint);

    final circuitGlow = Paint()
      ..color = cyan.withOpacity(0.4)
      ..strokeWidth = 6.0 * s
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.stroke;
    canvas.drawPath(trace1, circuitGlow);
    canvas.drawPath(trace2, circuitGlow);

    // Moving pulse dots on circuits
    final dotPaint = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.fill;
    final dotGlow = Paint()..color = cyan.withOpacity(0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final metrics1 = trace1.computeMetrics().toList();
    if (metrics1.isNotEmpty) {
      final m1 = metrics1.first;
      for (int i = 0; i < 3; i++) {
        final t = (pulse + i * 0.33) % 1.0;
        final pos = m1.getTangentForOffset(t * m1.length)?.position;
        if (pos != null) {
          canvas.drawCircle(pos, 4.0 * s, dotGlow);
          canvas.drawCircle(pos, 2.2 * s, dotPaint);
        }
      }
    }

    // ── 3. Cylinder Storage Tank (Left) ──────────────────────────────────────
    final tankCenter = Offset(w * 0.20, h * 0.65);
    final tankW = 28.0 * s;
    final tankH = 42.0 * s;
    final tankRect = Rect.fromCenter(center: tankCenter, width: tankW, height: tankH);
    final tankPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8), Color(0xFF334155)],
      ).createShader(tankRect);
    canvas.drawRRect(RRect.fromRectAndRadius(tankRect, Radius.circular(tankW * 0.4)), tankPaint);

    final ribPaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 1.2 * s;
    for (int i = 1; i <= 3; i++) {
      final y = tankRect.top + tankH * (i / 4.0);
      canvas.drawLine(Offset(tankRect.left, y), Offset(tankRect.right, y), ribPaint);
    }

    // ── 4. Slatted Industrial Building (Bottom Right) ────────────────────────
    final bldgPath = Path()
      ..moveTo(w * 0.50, h * 0.85)
      ..lineTo(w * 0.82, h * 0.70)
      ..lineTo(w * 0.82, h * 0.82)
      ..lineTo(w * 0.50, h * 0.97)
      ..close();
    canvas.drawPath(bldgPath, Paint()..color = const Color(0xFFE2E8F0).withOpacity(0.95));

    final bldgTop = Path()
      ..moveTo(w * 0.50, h * 0.85)
      ..lineTo(w * 0.68, h * 0.76)
      ..lineTo(w * 0.82, h * 0.70)
      ..lineTo(w * 0.64, h * 0.79)
      ..close();
    canvas.drawPath(bldgTop, Paint()..color = const Color(0xFFCBD5E1).withOpacity(0.95));

    final slatPaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 1.4 * s;
    for (int i = 1; i < 8; i++) {
      final t = i / 8.0;
      final topPt = Offset(w * 0.50 + (w * 0.32) * t, h * 0.85 - (h * 0.15) * t);
      final botPt = Offset(w * 0.50 + (w * 0.32) * t, h * 0.97 - (h * 0.15) * t);
      canvas.drawLine(topPt, botPt, slatPaint);
    }

    // ── 5. 3D Transformer Box (Top Right) ──────────────────────────────────
    final transRect = Rect.fromLTWH(w * 0.62, h * 0.42, 44.0 * s, 38.0 * s);
    final transShader = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1), Color(0xFF64748B)],
    ).createShader(transRect);
    canvas.drawRRect(RRect.fromRectAndRadius(transRect, Radius.circular(5 * s)), Paint()..shader = transShader);
    canvas.drawRRect(RRect.fromRectAndRadius(transRect, Radius.circular(5 * s)), Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = 1.2 * s);

    // Glowing cyan/green LED display screen on transformer
    final meterPaint = Paint()..color = cyan.withOpacity(0.9)..style = PaintingStyle.fill;
    final meterGlow = Paint()..color = cyan.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final meterRect1 = Rect.fromLTWH(w * 0.65, h * 0.45, 13.0 * s, 7.0 * s);
    final meterRect2 = Rect.fromLTWH(w * 0.73, h * 0.45, 13.0 * s, 7.0 * s);

    canvas.drawRect(meterRect1, meterGlow);
    canvas.drawRect(meterRect1, meterPaint);
    canvas.drawRect(meterRect2, meterGlow);
    canvas.drawRect(meterRect2, Paint()..color = const Color(0xFF10B981));

    // ── 6. 3D Metallic Transmission Lattice Tower (Top Center/Left) ──────────
    final towerTopPt = Offset(w * 0.42, h * 0.08);
    final towerBotL  = Offset(w * 0.32, h * 0.58);
    final towerBotR  = Offset(w * 0.52, h * 0.58);

    // Tower aura glow
    final towerAura = Paint()
      ..color = electricBlue.withOpacity((0.15 + 0.15 * math.sin(pulse * math.pi * 2)).clamp(0.05, 0.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(w * 0.42, h * 0.30), 55.0 * s, towerAura);

    final legPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.4 * s
      ..style = PaintingStyle.stroke;

    final legGlow = Paint()
      ..color = electricBlue.withOpacity(0.4)
      ..strokeWidth = 4.5 * s
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(towerTopPt, towerBotL, legGlow);
    canvas.drawLine(towerTopPt, towerBotR, legGlow);
    canvas.drawLine(towerBotL, towerBotR, legGlow);

    canvas.drawLine(towerTopPt, towerBotL, legPaint);
    canvas.drawLine(towerTopPt, towerBotR, legPaint);
    canvas.drawLine(towerBotL, towerBotR, legPaint);

    final crossPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 1.2 * s;
    for (int i = 1; i <= 5; i++) {
      final t1 = (i - 1) / 5.0;
      final t2 = i / 5.0;
      final p1L = Offset(towerTopPt.dx + (towerBotL.dx - towerTopPt.dx) * t1, towerTopPt.dy + (towerBotL.dy - towerTopPt.dy) * t1);
      final p1R = Offset(towerTopPt.dx + (towerBotR.dx - towerTopPt.dx) * t1, towerTopPt.dy + (towerBotR.dy - towerTopPt.dy) * t1);
      final p2L = Offset(towerTopPt.dx + (towerBotL.dx - towerTopPt.dx) * t2, towerTopPt.dy + (towerBotL.dy - towerTopPt.dy) * t2);
      final p2R = Offset(towerTopPt.dx + (towerBotR.dx - towerTopPt.dx) * t2, towerTopPt.dy + (towerBotR.dy - towerTopPt.dy) * t2);

      canvas.drawLine(p1L, p2R, crossPaint);
      canvas.drawLine(p1R, p2L, crossPaint);
      canvas.drawLine(p2L, p2R, crossPaint);
    }

    // 3 Tiers of Metallic Cross-Arms
    final armPaint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 2.8 * s;
    final insPaint = Paint()..color = orange..style = PaintingStyle.fill;
    final insGlow  = Paint()..color = orange.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.9)
      ..strokeWidth = 1.4 * s
      ..style = PaintingStyle.stroke;

    final armY = [h * 0.18, h * 0.28, h * 0.38];
    final armW = [50.0 * s, 72.0 * s, 92.0 * s];

    for (int i = 0; i < 3; i++) {
      final y = armY[i];
      final halfW = armW[i] / 2;
      final cx = towerTopPt.dx;

      // Cross arm bar
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), armPaint);

      // Insulator strings (orange discs with glowing halos)
      canvas.drawCircle(Offset(cx - halfW, y + 6 * s), 4.0 * s, insGlow);
      canvas.drawCircle(Offset(cx - halfW, y + 6 * s), 2.5 * s, insPaint);
      canvas.drawCircle(Offset(cx + halfW, y + 6 * s), 4.0 * s, insGlow);
      canvas.drawCircle(Offset(cx + halfW, y + 6 * s), 2.5 * s, insPaint);

      // Sagging 3D power lines extending to transformer
      final linePathRight = Path()
        ..moveTo(cx + halfW, y + 6 * s)
        ..quadraticBezierTo(cx + halfW + 30 * s, y + 15 * s, w * 0.65, h * 0.42);

      canvas.drawPath(linePathRight, linePaint);

      // Moving electrical sparks travelling along lines
      final sparkProgress = (pulse + i * 0.33) % 1.0;
      final lineMetrics = linePathRight.computeMetrics().toList();
      if (lineMetrics.isNotEmpty) {
        final mR = lineMetrics.first;
        final sparkPos = mR.getTangentForOffset(sparkProgress * mR.length)?.position;
        if (sparkPos != null) {
          canvas.drawCircle(sparkPos, 4.5 * s, Paint()..color = cyan.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
          canvas.drawCircle(sparkPos, 2.2 * s, Paint()..color = const Color(0xFFFFFFFF));
        }
      }
    }

    // Electrical arc flashes on insulators
    final arcP = (pulse * 4) % 1.0;
    if (arcP > 0.5 && arcP < 0.85) {
      final flashPaint = Paint()
        ..color = cyan.withOpacity((1.0 - ((arcP - 0.68).abs() * 6)).clamp(0.0, 1.0))
        ..strokeWidth = 2.0 * s
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(towerTopPt.dx - 36 * s, armY[1] + 4 * s), Offset(towerTopPt.dx - 36 * s, armY[1] + 12 * s), flashPaint);
      canvas.drawLine(Offset(towerTopPt.dx + 36 * s, armY[1] + 4 * s), Offset(towerTopPt.dx + 36 * s, armY[1] + 12 * s), flashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricSubstationPainter old) => old.pulse != pulse;
}

