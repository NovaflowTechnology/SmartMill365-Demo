import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/pecc_live_data.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/plant_energy_command_center/card_style_dialog.dart';
import 'package:smartmachine365/services/app_config.dart';

/// Scale-to-fit 16:9 preview of the Energy Command Center dashboard.
class EccInterfacePreviewWidget extends StatefulWidget {
  final String orgName;
  final String orgSubLabel;
  final String dashTitle;
  final String dashSubtitle;
  final String locationBadge;
  final List<String> costDriverLabels;
  final String bgImageUrl;

  /// The client's logo. Empty falls back to the initials badge, which is what
  /// this header has always drawn.
  final String logoUrl;
  final bool dashboardMode;
  final PeccLiveData? liveData;
  /// Called with the pin's lot label (e.g. "LOT 237") when a map pin is
  /// tapped — used to drill into that factory's command center. Null → pins
  /// aren't clickable (preview mode / inside a factory view).
  final void Function(String lotLabel)? onLotTap;

  /// Where the centre card sits, as fractions of the map panel — its top-left
  /// corner, the same rule the pins follow. Null keeps its built-in place.
  final (double, double)? heroPosition;

  /// What the centre card shows and how large it is drawn. Null, or one whose
  /// figures are both unset, keeps the card's original built-in layout.
  final HeroCardConfig? heroConfig;

  /// Opens the centre card's settings when tapped — wired from the live
  /// dashboard, not any settings page, so editing only ever happens where the
  /// card is actually seen.
  final VoidCallback? onHeroTap;

  /// Saved font size / colour per card, keyed the same way as
  /// [widgetLabels] (`stat[0]`, `pin[2]`, ...). Empty keeps every card's
  /// built-in look.
  final CardStyleSet cardStyles;

  /// True only for a Super Admin viewing the live dashboard — the same gate
  /// [onHeroTap] is wired behind. False everywhere else, including every
  /// settings-page preview, so nothing there grows a pencil badge.
  final bool canEditCards;

  /// Persists one card's style. Returns whether the save succeeded so the
  /// dialog can show an error and leave the card unchanged on failure.
  final Future<bool> Function(String key, CardTextStyle style)? onSaveCardStyle;

  const EccInterfacePreviewWidget({
    super.key,
    required this.orgName,
    required this.orgSubLabel,
    required this.dashTitle,
    required this.dashSubtitle,
    required this.locationBadge,
    required this.costDriverLabels,
    this.bgImageUrl = '',
    this.logoUrl = '',
    this.dashboardMode = false,
    this.liveData,
    this.onLotTap,
    this.heroPosition,
    this.heroConfig,
    this.onHeroTap,
    this.cardStyles = CardStyleSet.empty,
    this.canEditCards = false,
    this.onSaveCardStyle,
  });

  @override
  State<EccInterfacePreviewWidget> createState() => _EccInterfacePreviewWidgetState();
}

class _EccInterfacePreviewWidgetState extends State<EccInterfacePreviewWidget> with TickerProviderStateMixin {
  static const double _dw = 1920;
  static const double _dh = 1080;

  // ── palette — aligned to the app's primary dark theme background ──────────
  // Dark blue-black theme (matches the reference mockup) — a deep navy that's
  // nearly black, keeping a blue undertone rather than flat charcoal. Accent
  // colours (sparklines, icons, status, glows) are unchanged.
  static const _bg = Color(0xFF0A0F20);
  static const _bg2 = Color(0xFF060810);
  static const _panelBg = Color(0xB3091020);
  static const _cardBg = Color(0xFF0D1428);
  static const _border1 = Color(0xFF1C2A48);
  static const _accent = Color(0xFF31ECFC);
  static const _accentBlue = Color(0xFF3B8EFF);
  static const _accentG = Color(0xFF10B981);
  static const _accentO = Color(0xFFF59E0B);
  static const _accentP = Color(0xFFEAB308);
  static const _accentC = Color(0xFF06B6D4);
  static const _red = Color(0xFFEF4444);
  static const _white = Colors.white;
  static const _sub = Color(0xFF8892A4);
  static const _navBg = Color(0xFF060810);

  // ── financial & energy summary (left rail) — live kWh + cost when mapped ───
  // Placeholders only — every value here is replaced from live data in
  // [_financial]. They read as dashes so a screen that never got data cannot
  // be mistaken for one that did.
  static const _defaultFinancial = [
    _Stat('ENERGY COST', '(MTD)', '—', '6.4%', false, _accentBlue, Icons.attach_money),
    _Stat('SOLAR SAVING', '(MTD)', '—', '—', true, _accentG, Icons.eco),
    _Stat('MD CHARGES', '(MTD)', '—', '4.7%', false, _accentO, Icons.bar_chart),
    _Stat('TOTAL ENERGY', '(MTD)', '—', '7.8%', false, _accentP, Icons.bolt),
    _Stat('CARBON EMISSION', '(MTD)', '—', '10.1%', true, _accentC, Icons.cloud),
  ];

  // ── performance summary (right rail) ───────────────────────────────────────
  // Placeholders. Every one is replaced from live rankings in [_rankings];
  // they name no site and show no figure, so an unmapped dashboard cannot be
  // read as having a winner.
  static const _ranked = [
    _Rank('HIGHEST COST', '(MTD)', '—', '—', _red, Icons.bar_chart),
    _Rank('HIGHEST SAVING', '(MTD)', '—', '—', _accentG, Icons.eco),
    _Rank('BEST SOLAR GENERATION', '(MTD)', '—', '—', _accentO, Icons.wb_sunny),
    _Rank('BEST EFFICIENCY', '(MTD)', '—', '—', _accentBlue, Icons.speed),
  ];

  /// The right rail, filled from whichever site leads each metric.
  List<_Rank> get _rankings {
    final live = widget.liveData;
    if (live == null || live.rankings.isEmpty) return _ranked;
    const ids = ['cost', 'saving', 'solar', 'efficiency'];
    final out = <_Rank>[];
    for (var i = 0; i < _ranked.length; i++) {
      final r = live.rankings[ids[i]];
      out.add(r == null
          ? _ranked[i]
          : _Rank(_ranked[i].label, _ranked[i].sub, r.site, r.value,
              _ranked[i].color, _ranked[i].icon));
    }
    return out;
  }
  static const _carbonFooter = _Stat('CARBON EMISSION', '(MTD)', '—', '10.1%', true, _accentC, Icons.cloud);

  /// The same figure as the left rail's carbon card. It was a separate literal,
  /// so the two disagreed on one screen — 578 on the right while the left read
  /// what the meters actually reported.
  _Stat get _carbonFooterLive {
    final live = widget.liveData;
    if (live == null) return _carbonFooter;
    return _Stat('CARBON EMISSION', '(MTD)', live.groupCarbon,
        _carbonFooter.delta, _carbonFooter.pos, _accentC, Icons.cloud);
  }

  // ── today at a glance — live energy + cost today when mapped ─────────────
  // Placeholders only — solar and its share used to be printed as literals,
  // so the bottom row claimed 25.6 MWh and 20% on a dashboard with no solar
  // meter mapped at all.
  static const _defaultGlance = [
    _G(Icons.bolt, '—', 'Energy Today', _accentBlue),
    _G(Icons.account_balance_wallet, '—', 'Energy Cost Today', _accentP),
    _G(Icons.eco, '—', 'Solar Generated Today', _accentG),
    _G(Icons.percent, '—', 'Solar Contribution', _accentO),
  ];

  List<_Stat> get _financial {
    final live = widget.liveData;
    if (live == null) return _defaultFinancial;
    final stats = List<_Stat>.from(_defaultFinancial);
    if (live.totalCostMtd != '—') {
      stats[0] = _Stat('ENERGY COST', '(MTD)', live.totalCostMtd, stats[0].delta, stats[0].pos, _accentBlue, Icons.attach_money);
    }
    if (live.totalEnergyMtd != '—') {
      stats[3] = _Stat('TOTAL ENERGY', '(MTD)', live.totalEnergyMtd, stats[3].delta, stats[3].pos, _accentP, Icons.bolt);
    }
    // Solar, MD charges and carbon used to keep their placeholder values here,
    // so the dashboard printed "RM 68,500" and "578 tCO2e" no matter what the
    // meters said. They come from the pins now, and read as a dash when the
    // sites genuinely report nothing.
    stats[1] = _Stat('SOLAR SAVING', '(MTD)', live.groupSolar, stats[1].delta,
        stats[1].pos, _accentG, Icons.eco);
    stats[2] = _Stat('MD CHARGES', '(MTD)', live.groupMdCharges,
        stats[2].delta, stats[2].pos, _accentO, Icons.bar_chart);
    stats[4] = _Stat('CARBON EMISSION', '(MTD)', live.groupCarbon,
        stats[4].delta, stats[4].pos, _accentC, Icons.cloud);
    return stats;
  }

  List<_G> get _glance {
    final live = widget.liveData;
    if (live == null) return _defaultGlance;
    final items = List<_G>.from(_defaultGlance);
    if (live.energyToday != '—') {
      items[0] = _G(Icons.bolt, live.energyToday, 'Energy Today', _accentBlue);
    }
    if (live.energyCostToday != '—') {
      items[1] = _G(Icons.account_balance_wallet, live.energyCostToday, 'Energy Cost Today', _accentP);
    }
    items[2] = _G(Icons.eco, live.solarToday, 'Solar Generated Today', _accentG);
    items[3] =
        _G(Icons.percent, live.solarSharePct, 'Solar Contribution', _accentO);
    return items;
  }

  // Maps visual card position (0-5) to DB pin index.
  // DB has 8 pins; we skip index 3 (Cost Driver 4) and 7 (LOT 237C).
  /// The six the dashboard shipped with, used only when configuration says
  /// nothing.
  static const _defaultPinDataIndices = [0, 1, 2, 4, 5, 6];

  /// The pins to draw, in order, from configuration. A pin added in settings
  /// appears here; before this the list was fixed, so the new pin was saved and
  /// resolved but never reached the picture.
  List<int> get _pinDataIndices {
    final order = widget.liveData?.pinOrder ?? const [];
    return order.isEmpty ? _defaultPinDataIndices : order;
  }

  String _pinCostAt(int visualIndex) {
    final live = widget.liveData;
    if (live != null) {
      final dataIdx = _pinDataIndices[visualIndex];
      final byIdx = live.pinsByIndex[dataIdx];
      if (byIdx != null && byIdx.costDisplay != '—') return byIdx.costDisplay;
    }
    return '—';
  }

  /// Cards configured for this pin in settings, or empty when nobody has
  /// configured any — in which case the card keeps its cost/energy pair.
  List<PeccPinMetric> _pinMetricsAt(int visualIndex) {
    final live = widget.liveData;
    if (live == null) return const [];
    final byIdx = live.pinsByIndex[_pinDataIndices[visualIndex]];
    return byIdx?.metrics ?? const [];
  }

  /// How many pins to draw. Follows configuration once sites can be added,
  /// and falls back to the six this dashboard shipped with.
  int get _pinCount => _pinDataIndices.length;

  /// The decorative per-pin arrays below were all written for exactly six
  /// pins. Now that pins can be added, reading them by index would throw, so
  /// every one is read through a wrap that falls back to a sane default.
  String _labelAt(List<String> labels, int i) =>
      i < labels.length ? labels[i] : '';
  String _deltaAt(int i) => i < _pinDeltas.length ? _pinDeltas[i] : '—';
  bool _posAt(int i) => i < _pinPos.length ? _pinPos[i] : false;
  _StatusKind _statusAt(int i) =>
      i < _pinStatus.length ? _pinStatus[i] : _StatusKind.ok;

  /// True when this pin has been given a position in settings.
  bool _isPlaced(int visualIndex) {
    if (visualIndex >= _pinDataIndices.length) return true;
    return widget.liveData?.pinPositions
            .containsKey(_pinDataIndices[visualIndex]) ??
        false;
  }

  /// Where a pin sits, preferring what settings says over the layout built in
  /// below. Sites can now be added from settings, and a new one has no
  /// built-in position to fall back on — it has to come from configuration.
  (double, double) _positionFor(int visualIndex) {
    final configured =
        widget.liveData?.pinPositions[_pinDataIndices[visualIndex]];
    if (configured != null) return (configured.x, configured.y);
    if (visualIndex < _pinPositions.length) return _pinPositions[visualIndex];
    // An added pin nobody has placed yet. Laid out on a small grid rather than
    // all at one spot: parking every extra pin in the middle stacked them
    // exactly on top of each other, so twelve pins looked like seven.
    final extra = visualIndex - _pinPositions.length;
    const perRow = 4;
    final col = extra % perRow;
    final row = extra ~/ perRow;
    return (0.30 + col * 0.14, 0.34 + row * 0.16);
  }

  /// Settings stores a colour name rather than an ARGB value, so the two sides
  /// cannot drift apart by one of them editing a hex code.
  static const _metricColors = <String, Color>{
    'cyan': Color(0xFF22D3EE),
    'green': Color(0xFF10B981),
    'amber': Color(0xFFF59E0B),
    'purple': Color(0xFF9A6BFF),
    'red': Color(0xFFFF5D6C),
  };

  /// Keyed by the pin metric vocabulary shared with settings and the
  /// resolver, so all three sides stay in step.
  static const _metricIcons = <String, IconData>{
    'cost': Icons.attach_money,
    'energy': Icons.bolt,
    'max_demand': Icons.show_chart,
    'md_charges': Icons.receipt_long_outlined,
    'solar': Icons.solar_power_outlined,
    'carbon': Icons.cloud_outlined,
    'pf': Icons.speed,
  };

  String _pinEnergyAt(int visualIndex) {
    final live = widget.liveData;
    if (live != null) {
      final dataIdx = _pinDataIndices[visualIndex];
      final byIdx = live.pinsByIndex[dataIdx];
      if (byIdx != null && byIdx.energyDisplay != '—') return byIdx.energyDisplay;
    }
    return '—';
  }

  // Placeholders shown until a pin is mapped to a TNB meter that reports data.
  // These used to be invented figures (RM 12,500 / 420 MWh …) which made an
  // unmapped dashboard look live — the same trap as a fault device ID showing
  // energy. An unmapped pin now reads N/A until its TNB meter is linked.
  static const _defaultPinValues = ['N/A', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A'];
  static const _defaultPinSub = ['—', '—', '—', '—', '—', '—'];
  static const _pinStatus = [_StatusKind.ok, _StatusKind.ok, _StatusKind.ok, _StatusKind.warn, _StatusKind.alert, _StatusKind.ok];
  // Also invented — there is no vs-last-month comparison behind these.
  static const _pinDeltas = ['—', '—', '—', '—', '—', '—'];
  static const _pinPos = [false, false, true, true, true, false];

  /// Card top-left = RED CIRCLE targets (white scribble / outer = wrong).
  /// Fractions of the center map panel (BoxFit.fill), from annotated screenshot.
  /// Width of the centre hero card. Pins 3 and 6 align to its edges.
  static const double _kHeroWidth = 300;

  /// Paired into three rows so left and right cards sit on the same baseline.
  /// Each row shares one y; only x differs. Previously every pin had its own y
  /// (0.14 / 0.41 / 0.75 / 0.26 / 0.54 / 0.76) so nothing lined up.
  static const _pinPositions = [
    (0.14, 0.20), // 1 LOT 50  — row 1 left
    (0.07, 0.47), // 2 LOT 52  — row 2 left, set back toward the panel edge
    (0.33, 0.75), // 3 LOT 48  — row 3, aligned to the centre card's left edge
    (0.78, 0.20), // 4 LOT 53A — row 1 right
    (0.85, 0.47), // 5 LOT 53B — row 2 right, set back toward the panel edge
    (0.62, 0.75), // 6 LOT 237 — row 3, aligned to the centre card's right edge
  ];

  /// Glow dots on the rooftop under each circled card.
  static const _pinAnchors = [
    (0.27, 0.28),
    (0.16, 0.52),
    (0.30, 0.88),
    (0.80, 0.38),
    (0.88, 0.66),
    (0.66, 0.88),
  ];

  static const double _pinCardW = 0.175;
  static const double _pinCardH = 0.125;

  List<String> get _pinLabels => List.generate(6, (i) {
        final custom = i < widget.costDriverLabels.length ? widget.costDriverLabels[i].trim() : '';
        final defaults = ['Cost Driver 1', 'Cost Driver 2', 'Cost Driver 3', 'LOT 53A', 'LOT 53B', 'LOT 237'];
        return custom.isNotEmpty ? custom : defaults[i];
      });

  // ── live animation drivers ──────────────────────────────────────────────
  // Breathing glow (borders, dots, neon lines) — slow ease in/out pulse.
  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);

  // One-shot "power on" intro — drives the KPI count-up and the trend line
  // drawing itself in. Plays once when the dashboard mounts.
  late final AnimationController _introCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  // Continuous flow — drives the sparkline traveling pulse and the radar ping.
  late final AnimationController _flowCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _introCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  // ── count-up: re-renders a KPI string with its number scaled by t (0..1),
  // preserving prefix (RM ), suffix ( MWh / %), decimals and thousands commas.
  static String _addThousands(String intDigits) {
    final buf = StringBuffer();
    for (int i = 0; i < intDigits.length; i++) {
      if (i > 0 && (intDigits.length - i) % 3 == 0) buf.write(',');
      buf.write(intDigits[i]);
    }
    return buf.toString();
  }

  String _countUp(String raw, double t) {
    if (t >= 1.0) return raw;
    final m = RegExp(r'\d[\d,]*(?:\.\d+)?').firstMatch(raw);
    if (m == null) return raw;
    final numStr = m.group(0)!;
    final dotIdx = numStr.indexOf('.');
    final decimals = dotIdx >= 0 ? numStr.length - dotIdx - 1 : 0;
    final hasComma = numStr.contains(',');
    final value = double.tryParse(numStr.replaceAll(',', '')) ?? 0;
    final cur = value * t;
    String out;
    if (decimals > 0) {
      out = cur.toStringAsFixed(decimals);
      if (hasComma) {
        final parts = out.split('.');
        out = '${_addThousands(parts[0])}.${parts[1]}';
      }
    } else {
      final intStr = cur.round().toString();
      out = hasComma ? _addThousands(intStr) : intStr;
    }
    return raw.replaceFirst(numStr, out);
  }

  /// A KPI value Text that counts up from 0 during the intro animation.
  Widget _kpiText(String value, TextStyle style, {TextAlign? textAlign, TextOverflow? overflow}) {
    return AnimatedBuilder(
      animation: _introCtrl,
      builder: (_, __) => Text(
        _countUp(value, Curves.easeOutCubic.transform(_introCtrl.value)),
        style: style,
        textAlign: textAlign,
        overflow: overflow,
      ),
    );
  }

  // ── root ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final inner = FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(width: _dw, height: _dh, child: _dash()),
    );

    // In live dashboard mode the widget fills the whole Scaffold. Use
    // BoxFit.contain (not fill) so the fixed 1920×1080 design keeps its exact
    // proportions instead of being stretched/distorted on non-16:9 screens.
    if (widget.dashboardMode) {
      return Container(
        color: const Color(0xFF060810),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(width: _dw, height: _dh, child: _dash()),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _dw / _dh,
          // Gradient border shell — outer gradient shows through the 1.5px padding gap
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  _accent.withOpacity(0.65),
                  _accentC.withOpacity(0.35),
                  _accentP.withOpacity(0.25),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.45),
                  blurRadius: 64,
                  spreadRadius: -4,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: _accent.withOpacity(0.18),
                  blurRadius: 120,
                  spreadRadius: 12,
                ),
                BoxShadow(
                  color: _accentP.withOpacity(0.12),
                  blurRadius: 80,
                  spreadRadius: 5,
                  offset: const Offset(-8, 0),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: Stack(children: [
                inner,
                // Top-edge glass highlight reflection
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              border: Border(
                left: BorderSide(color: _accent.withOpacity(0.18), width: 0.5),
                right: BorderSide(color: _accent.withOpacity(0.18), width: 0.5),
              ),
            ),
          ),
          Container(
            width: 170,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _accent.withOpacity(0.12), width: 0.5),
              boxShadow: [
                BoxShadow(color: _accent.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
              ],
            ),
          ),
        ])),
      ],
    );
  }

  // ── dashboard skeleton ────────────────────────────────────────────────────
  Widget _dash() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bg, _bg2]),
        ),
        child: Column(children: [
          SizedBox(height: 84, child: _header()),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(width: 340, child: _glassPanel(_financialPanel())),
              const SizedBox(width: 12),
              Expanded(child: _center()),
              const SizedBox(width: 12),
              SizedBox(width: 340, child: _glassPanel(_perfPanel())),
            ]),
          )),
          SizedBox(height: 200, child: _bottom()),
          SizedBox(height: 30, child: _footer()),
        ]),
      );

  // ── glass panel wrapper ──────────────────────────────────────────────────
  Widget _glassPanel(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border1.withOpacity(0.6), width: 0.8),
            ),
            child: child,
          ),
        ),
      );

  // ── header ────────────────────────────────────────────────────────────────
  /// Customers this build can be switched between, loaded once.
  List<Map<String, String>> _clients = const [];
  bool _clientsLoaded = false;

  Future<void> _loadClients() async {
    if (_clientsLoaded) return;
    _clientsLoaded = true;
    final list = await AppConfig.availableClients();
    if (mounted && list.length > 1) setState(() => _clients = list);
  }

  /// Switches the whole console to another customer.
  ///
  /// One site can serve more than one, and someone administering both needs to
  /// move between them without signing out. Hidden entirely when there is only
  /// one customer, so a single-customer site gains no control it cannot use.
  Widget _customerSwitcher() {
    _loadClients();
    if (_clients.length < 2) return const SizedBox.shrink();
    final current = AppConfig.clientId;
    final name =
        AppConfig.clientName.isNotEmpty ? AppConfig.clientName : current;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        tooltip: 'Switch customer',
        color: _cardBg,
        offset: const Offset(0, 44),
        onSelected: (id) {
          if (id == current) return;
          final picked = _clients.firstWhere((c) => c['id'] == id,
              orElse: () => {'id': id, 'name': id});
          AppConfig.switchClient(id, picked['name'] ?? id);
        },
        itemBuilder: (_) => [
          for (final c in _clients)
            PopupMenuItem<String>(
              value: c['id'],
              child: Row(children: [
                Icon(c['id'] == current ? Icons.check : Icons.business_outlined,
                    color: c['id'] == current ? _white : _sub, size: 15),
                const SizedBox(width: 8),
                Text(c['name'] ?? '',
                    style: TextStyle(
                        color: c['id'] == current ? _white : _sub,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.business_outlined, color: _sub, size: 15),
            const SizedBox(width: 7),
            Text(name.toUpperCase(),
                style: const TextStyle(
                    color: _white,
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down, color: _sub, size: 16),
          ]),
        ),
      ),
    );
  }


  Widget _header() {
    final org = widget.orgName.trim().isEmpty ? 'THONG GUAN GROUP' : widget.orgName.trim().toUpperCase();
    final sub = widget.orgSubLabel.trim().isEmpty ? 'ENERGY COST MANAGEMENT CENTER' : widget.orgSubLabel.trim().toUpperCase();
    final title = widget.dashTitle.trim().toUpperCase();
    final sttl = widget.dashSubtitle.trim().isEmpty ? 'Plant CEO Dashboard' : widget.dashSubtitle.trim();
    final badge = widget.locationBadge.trim().isEmpty ? 'LOT 237' : widget.locationBadge.trim().toUpperCase();
    final initials = org.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();

    return Container(
      decoration: const BoxDecoration(
        color: _navBg,
        border: Border(bottom: BorderSide(color: _border1, width: 0.6)),
      ),
      child: Stack(children: [
        // Cyberpunk diagonal accent strip
        Positioned.fill(child: CustomPaint(painter: _HeaderAccentPainter())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(children: [
            // Logo — the uploaded mark when there is one, otherwise the
            // initials badge this header has always drawn. contain, not cover,
            // so a wide logo is not cropped down to its middle.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: widget.logoUrl.trim().isEmpty
                      ? const Color(0xFFCC1A1A)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: widget.logoUrl.trim().isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.network(
                        widget.logoUrl.trim(),
                        fit: BoxFit.contain,
                        // A logo that fails to load must not leave an empty
                        // square where the brand should be.
                        errorBuilder: (_, __, ___) => Text(initials,
                            style: const TextStyle(
                                color: _white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: 17)),
                      ),
                    )
                  : Text(initials, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(org, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
              Text(sub, style: const TextStyle(color: _accent, fontFamily: 'Poppins', fontSize: 9.5, letterSpacing: 0.6)),
            ]),
            const Spacer(),
            // Centre title
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: 2)),
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _AnimatedDot(controller: _pulseCtrl, color: _accentG, size: 8),
                const SizedBox(width: 5),
                const Text('Online', style: TextStyle(color: _accentG, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Text(sttl, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12)),
              ]),
            ]),
            const Spacer(),
            _customerSwitcher(),
            // Time
            const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('08:32 AM', style: TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20)),
              Text('10 Jun 2026', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 11)),
            ]),
            const SizedBox(width: 20),
            // Bell
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border1)),
                child: const Icon(Icons.notifications_outlined, color: _white, size: 19),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: _red),
                  alignment: Alignment.center,
                  child: const Text('3', style: TextStyle(color: _white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
              ),
            ]),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border1)),
              child: const Icon(Icons.fullscreen, color: _white, size: 20),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(border: Border.all(color: _accent.withOpacity(0.55)), borderRadius: BorderRadius.circular(7)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(badge, style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down, color: _sub, size: 14),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── financial & energy summary panel (left) ─────────────────────────────────
  Widget _financialPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FINANCIAL & ENERGY SUMMARY',
            style: TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, letterSpacing: 0.6)),
        const SizedBox(height: 12),
        Expanded(
          child: Column(children: [
            for (int i = 0; i < _financial.length; i++) ...[
              Expanded(child: _statCard(_financial[i], 'stat[$i]')),
              if (i < _financial.length - 1) const SizedBox(height: 10),
            ],
          ]),
        ),
      ]),
    );
  }

  // Calm frosted-glass card — flat tinted glass panel, no neon pulse/spark,
  // matching the reference design's simpler left-panel summary cards.
  Widget _statCard(_Stat s, [String cardKey = '']) {
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _sub;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return _editableCard(
      cardKey: cardKey,
      title: s.label,
      card: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
          // Dark navy base — a faint lighter top for glass sheen, darker at the
          // bottom. The soft accent glow is layered on top (see Stack below).
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(Colors.white.withOpacity(0.03), _cardBg),
              Color.alphaBlend(Colors.black.withOpacity(0.32), _cardBg),
            ],
          ),
        ),
        child: Stack(children: [
          // Soft accent glow radiating from the icon corner (top-left), fading
          // into the dark navy — gives the card its subtle coloured-glass tone.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: RadialGradient(
                  center: const Alignment(-0.85, -0.9),
                  radius: 1.3,
                  colors: [s.color.withOpacity(0.16), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Glowing accent sparkline along the bottom — the card's colour accent.
          Positioned(
            left: 10, right: 10, bottom: 6, height: 18,
            child: AnimatedBuilder(
              animation: _flowCtrl,
              builder: (_, __) => CustomPaint(painter: _MiniSpark(s.color, progress: _flowCtrl.value)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _iconBadge(s.icon, s.color),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s.label, style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontSize: style.labelSize > 0 ? style.labelSize : 11, letterSpacing: 0.4)),
                  const SizedBox(width: 4),
                  Text(s.sub, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 11)),
                ]),
                const SizedBox(height: 2),
                _kpiText(s.value, TextStyle(color: valueColor, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: style.valueSize > 0 ? style.valueSize : 24)),
              ])),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                _chip(s.delta, s.pos),
                const SizedBox(height: 3),
                const Text('vs last month', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9)),
              ]),
            ]),
          ),
        ]),
      ),
      ),
    );
  }

  // ── center column: factory image + floating hero + numbered pins ───────────
  Widget _center() {
    final labels = _pinLabels;
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          Positioned.fill(
              child: widget.bgImageUrl.isNotEmpty
                  ? Image.network(
                      widget.bgImageUrl,
                      // Fill the map panel exactly so pin fractions stay on the
                      // same buildings across screen sizes (cover crops/shifts).
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => _buildingFallback(),
                    )
                  : _buildingFallback()),
          Positioned.fill(
              child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x33000000), Color(0xAA000000)],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          )),
          // Short connector stub + rooftop anchor dot beneath each lot pin —
          // matches the mockup's line-and-node style instead of a roaming ball.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final starts = [
                  for (final p in _pinPositions)
                    Offset(p.$1 * w + (_pinCardW * w * 0.5), p.$2 * h + (_pinCardH * h)),
                ];
                final ends = [
                  for (final a in _pinAnchors) Offset(a.$1 * w, a.$2 * h),
                ];
                final colors = [
                  for (final s in _pinStatus)
                    switch (s) { _StatusKind.ok => _accentG, _StatusKind.warn => _accentO, _StatusKind.alert => _red },
                ];
                return CustomPaint(
                  painter: _PinConnectorPainter(starts: starts, ends: ends, colors: colors, pulse: _pulseCtrl.value),
                );
              },
            ),
          ),
          // Numbered location pins — tappable in dashboard mode to drill into
          // that factory's command center.
          // Pins 3 (LOT 48) and 6 (LOT 237) sit just OUTSIDE the hero card and
          // butt against it: LOT 48's right edge meets the hero's left edge,
          // LOT 237's left edge meets the hero's right edge. The hero is a fixed
          // 300px centred on the panel, so both meeting points are the same
          // distance (w + heroWidth) / 2 — measured from the right for LOT 48
          // and from the left for LOT 237. Anchoring each card by the edge that
          // must touch also sidesteps the cards being IntrinsicWidth, so their
          // rendered width never has to be known here.
          for (int i = 0; i < _pinCount; i++)
            Positioned(
              // A pin placed from settings goes exactly where it was put. Only
              // the two that have never been moved keep butting against the
              // hero card, which is the arrangement described above.
              left: _isPlaced(i)
                  ? _positionFor(i).$1 * w
                  : (i == 2 ? null : (i == 5 ? (w + _kHeroWidth) / 2 : _positionFor(i).$1 * w)),
              right: (!_isPlaced(i) && i == 2) ? (w + _kHeroWidth) / 2 : null,
              // A pin low on the photo is anchored by its bottom edge so the
              // card grows upward. Anchoring everything from the top clipped
              // the lower pins against the panel: a configured card is as tall
              // as the number of metrics on it, which the fixed layout never
              // had to account for when every pin was two lines.
              top: _positionFor(i).$2 <= 0.5 ? _positionFor(i).$2 * h : null,
              bottom: _positionFor(i).$2 > 0.5
                  ? (1 - _positionFor(i).$2) * h - 40
                  : null,
              child: Builder(builder: (_) {
                final pinLabel = _labelAt(labels, i);
                final pinCardKey = 'pin[$i]';
                final pinCard = _pinCard(i + 1, pinLabel, _pinCostAt(i), _pinEnergyAt(i), _deltaAt(i), _posAt(i), _statusAt(i),
                    metrics: _pinMetricsAt(i), cardKey: pinCardKey);
                final tappable = widget.onLotTap == null
                    ? pinCard
                    : MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => widget.onLotTap!(pinLabel),
                          child: pinCard,
                        ),
                      );
                final badge = _editBadge(pinCardKey, pinLabel);
                if (badge == null) return tappable;
                return Stack(clipBehavior: Clip.none, children: [tappable, badge]);
              }),
            ),
          // Floating center hero card. Once settings give it a position it is
          // placed like a pin: top-left at the point, and anchored by its
          // bottom edge in the lower half so it grows upward, not off the panel.
          if (widget.heroPosition == null)
            Align(
              alignment: const Alignment(0, -0.62),
              child: _centerHero(),
            )
          else
            Positioned(
              left: widget.heroPosition!.$1 * w,
              top: widget.heroPosition!.$2 <= 0.5
                  ? widget.heroPosition!.$2 * h
                  : null,
              bottom: widget.heroPosition!.$2 > 0.5
                  ? (1 - widget.heroPosition!.$2) * h
                  : null,
              child: _centerHero(),
            ),
        ]),
      );
    });
  }

  Widget _buildingFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1020), Color(0xFF0E1832), Color(0xFF070A14)],
          ),
        ),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.business_outlined, size: 72, color: _accent.withOpacity(0.15)),
          const SizedBox(height: 8),
          Text('Insert Factory Image', style: TextStyle(color: _white.withOpacity(0.25), fontFamily: 'Poppins', fontSize: 14)),
        ])),
      );

  Widget _centerHero() {
    final org = widget.orgName.trim().isEmpty ? 'TG GROUP' : widget.orgName.trim().toUpperCase();
    final config = widget.heroConfig;
    final custom = config != null && config.isCustom;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: config?.widthPx ?? _kHeroWidth,
          constraints: config?.heightPx != null
              ? BoxConstraints(minHeight: config!.heightPx!)
              : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Glassy depth like the summary cards: a light-to-dark vertical
            // gradient with a soft accent glow layered on top (see Stack below).
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(Colors.white.withOpacity(0.02), _cardBg.withOpacity(0.92)),
                Color.alphaBlend(Colors.black.withOpacity(0.50), _cardBg.withOpacity(0.92)),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 22, spreadRadius: -4, offset: const Offset(0, 10)),
            ],
          ),
          child: Stack(children: [
            // Soft accent glow radiating from the top-left — the glassy tone.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.95),
                    radius: 1.25,
                    colors: [_accent.withOpacity(0.20), Colors.transparent],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // Diagonal glass sheen highlight for extra glossiness.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.10), Colors.transparent],
                    stops: const [0.0, 0.45],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: custom
                    ? _heroCustomChildren(config)
                    : [
                        Text(org,
                            style: const TextStyle(
                                color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        _kpiText(
                            widget.liveData != null && widget.liveData!.totalCostMtd != '—'
                                ? widget.liveData!.totalCostMtd
                                : '—',
                            const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 30)),
                        const Text('ENERGY COST THIS MONTH',
                            style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9.5, letterSpacing: 0.6)),
                        const SizedBox(height: 10),
                        Container(height: 0.6, color: _border1),
                        const SizedBox(height: 10),
                        const Text('TOTAL ENERGY', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 9.5, letterSpacing: 0.6)),
                        _kpiText(
                            widget.liveData != null && widget.liveData!.totalEnergyMtd != '—'
                                ? widget.liveData!.totalEnergyMtd
                                : '—',
                            const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _accentG.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _accentG.withOpacity(0.45)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.eco, color: _accentG, size: 13),
                            SizedBox(width: 6),
                            // No live solar-saving figure is resolved yet, so this reads
                            // empty rather than repeating a hardcoded RM 142,800.
                            Text('SOLAR SAVING (MTD)  —',
                                style: TextStyle(color: _accentG, fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
              ),
            ),
          ]),
        ),
      ),
    );

    if (widget.onHeroTap == null) return card;
    // A small pencil in the corner is what makes the card readable as
    // clickable at all — nothing else about its look changes when it can be
    // edited, so an admin who has never opened settings still sees a card,
    // not a button.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onHeroTap,
        child: Stack(clipBehavior: Clip.none, children: [
          card,
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.edit_outlined, size: 13, color: _white),
            ),
          ),
        ]),
      ),
    );
  }

  /// Title, main figure and sub figure for a customised centre card — the
  /// same two-figure shape the card has always had, just naming and totalling
  /// what settings chose instead of cost and energy.
  List<Widget> _heroCustomChildren(HeroCardConfig config) {
    final live = widget.liveData;
    final pinOrder = live?.pinOrder ?? const [];
    final title = config.title.trim().isEmpty
        ? (widget.orgName.trim().isEmpty ? 'TG GROUP' : widget.orgName.trim().toUpperCase())
        : config.title.trim().toUpperCase();

    Widget figureBlock(HeroFigureConfig figure, {required bool big}) {
      if (!figure.isSet) return const SizedBox.shrink();
      final info = heroMetrics[figure.metricKey];
      final name = figure.name.trim().isEmpty
          ? (info?.label.toUpperCase() ?? '')
          : figure.name.trim().toUpperCase();
      final color = heroColors[figure.colorKey] ?? (big ? _white : _accent);
      final resolved = live == null
          ? (amount: 0.0, reporting: 0)
          : HeroCardConfig.resolveFigure(live, pinOrder, figure, config.includedPins);
      final value = resolved.reporting == 0
          ? '—'
          : heroFormatMetric(figure.metricKey, resolved.amount);
      return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _kpiText(
          value,
          TextStyle(
            color: color,
            fontFamily: 'Poppins',
            fontWeight: big ? FontWeight.w800 : FontWeight.w700,
            fontSize: figure.valueSize > 0 ? figure.valueSize : (big ? 30 : 17),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _sub,
                fontFamily: 'Poppins',
                fontSize: figure.nameSize > 0 ? figure.nameSize : 9.5,
                letterSpacing: 0.6)),
      ]);
    }

    return [
      Text(title,
          style: TextStyle(
              color: _white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: config.titleSize > 0 ? config.titleSize : 15,
              letterSpacing: 1)),
      const SizedBox(height: 6),
      figureBlock(config.main, big: true),
      if (config.sub.isSet) ...[
        const SizedBox(height: 10),
        Container(height: 0.6, color: _border1),
        const SizedBox(height: 10),
        figureBlock(config.sub, big: false),
      ],
    ];
  }

  Widget _pinCard(int index, String label, String value, String sub, String delta, bool pos, _StatusKind status,
      {List<PeccPinMetric> metrics = const [], String cardKey = ''}) {
    final color = switch (status) {
      _StatusKind.ok => _accentG,
      _StatusKind.warn => _accentO,
      _StatusKind.alert => _red,
    };
    final style = widget.cardStyles.of(cardKey);
    final labelColor = heroColors[style.labelColorKey] ?? _white;
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return IntrinsicWidth(
      child: IntrinsicHeight(
        child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(Colors.white.withOpacity(0.02), _cardBg.withOpacity(0.92)),
                Color.alphaBlend(Colors.black.withOpacity(0.50), _cardBg.withOpacity(0.92)),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.5), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.95),
                    radius: 1.25,
                    colors: [Colors.white.withOpacity(0.07), Colors.transparent],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.08), Colors.transparent],
                    stops: const [0.0, 0.45],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _accentBlue.withOpacity(0.85)),
                    alignment: Alignment.center,
                    child: Text('$index', style: const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(label,
                          style: TextStyle(color: labelColor, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: style.labelSize > 0 ? style.labelSize : 14),
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 5),
                  _statusDot(color, status),
                ]),
                const SizedBox(height: 6),
                // Configured cards take over the body of the pin entirely. The
                // cost/energy pair below is what every pin showed before any of
                // this existed, and stays the fallback so an unconfigured
                // dashboard is untouched.
                if (metrics.isNotEmpty)
                  for (int mi = 0; mi < metrics.length; mi++)
                    Padding(
                      padding: EdgeInsets.only(top: mi == 0 ? 2 : 6),
                      child: _pinMetricRow(metrics[mi], style: style),
                    )
                else ...[
                  _kpiText(value, TextStyle(color: valueColor, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: style.valueSize > 0 ? style.valueSize : 20)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(sub, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 11)),
                    const Spacer(),
                    _chip(delta, pos),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
      ),
        ),
      ),
    );
  }

  // ── performance summary panel (right) ───────────────────────────────────────
  Widget _perfPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PERFORMANCE SUMMARY',
            style: TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12.5, letterSpacing: 0.6)),
        const SizedBox(height: 12),
        Expanded(
          child: Column(children: [
            for (int i = 0; i < _rankings.length; i++) ...[
              Expanded(child: _rankCard(_rankings[i], 'rank[$i]')),
              const SizedBox(height: 10),
            ],
            Expanded(child: _statCard(_carbonFooterLive, 'statFooter.carbon')),
          ]),
        ),
      ]),
    );
  }

  Widget _rankCard(_Rank r, [String cardKey = '']) {
    final style = widget.cardStyles.of(cardKey);
    final valueColor = heroColors[style.valueColorKey] ?? _white;
    return _editableCard(
      cardKey: cardKey,
      title: '${r.label} ${r.location}',
      card: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
          // Dark navy base — soft accent glow layered on top (see Stack). Right
          // panel reads slightly more saturated than the left in the mockup.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(Colors.white.withOpacity(0.03), _cardBg),
              Color.alphaBlend(Colors.black.withOpacity(0.32), _cardBg),
            ],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: RadialGradient(
                  center: const Alignment(-0.85, -0.9),
                  radius: 1.3,
                  colors: [r.color.withOpacity(0.22), Colors.transparent],
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10, right: 10, bottom: 6, height: 16,
            child: AnimatedBuilder(
              animation: _flowCtrl,
              builder: (_, __) => CustomPaint(painter: _MiniSpark(r.color, progress: _flowCtrl.value)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              _iconBadge(r.icon, r.color, box: 38, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Text(r.label, style: TextStyle(color: r.color, fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const SizedBox(width: 3),
                    Text(r.sub, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10.5)),
                  ]),
                  Text(r.location, style: TextStyle(color: heroColors[style.labelColorKey] ?? _white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: style.labelSize > 0 ? style.labelSize : 14)),
                  _kpiText(r.value, TextStyle(color: valueColor, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: style.valueSize > 0 ? style.valueSize : 21)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: _sub, size: 16),
            ]),
          ),
        ]),
      ),
      ),
    );
  }

  // ── bottom panels — chart and "today at a glance" as two separate cards ────
  Widget _bottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(flex: 55, child: _glassPanel(_chartPanel())),
        const SizedBox(width: 16),
        Expanded(flex: 45, child: _glassPanel(_glancePanel())),
      ]),
    );
  }

  Widget _chartPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('ENERGY COST TREND',
              style: TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.6)),
          const SizedBox(width: 6),
          const Text('(MONTHLY)', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12)),
          const Spacer(),
          _pill('This Year', true),
          const SizedBox(width: 6),
          _pill('Last Year', false),
          const SizedBox(width: 8),
          _rmBtn(),
        ]),
        const SizedBox(height: 6),
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([_introCtrl, _pulseCtrl]),
            builder: (_, __) => CustomPaint(
              painter: _LinePainter(
                progress: Curves.easeInOut.transform(_introCtrl.value),
                pulse: _pulseCtrl.value,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _glancePanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TODAY AT A GLANCE',
            style: TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.6)),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < _glance.length; i++) ...[
                Expanded(child: _glanceCard(_glance[i])),
                if (i < _glance.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _glanceCard(_G g) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final t = _pulseCtrl.value;
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: g.color.withOpacity(0.78),
              boxShadow: [
                BoxShadow(color: g.color.withOpacity(0.35 + 0.25 * t), blurRadius: 16, spreadRadius: 1),
                BoxShadow(color: g.color.withOpacity(0.12 + 0.15 * t), blurRadius: 32, spreadRadius: 4),
              ],
            ),
            child: Icon(g.icon, color: _white, size: 27),
          );
        },
      ),
      const SizedBox(height: 8),
      _kpiText(g.value,
          const TextStyle(color: _white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
      Text(g.label, style: const TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 12), textAlign: TextAlign.center),
    ]);
  }

  // ── footer ────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 4),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.access_time, color: _sub, size: 11),
        SizedBox(width: 4),
        Text('Data updated: 08:30 AM', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10)),
        SizedBox(width: 3),
        Icon(Icons.refresh, color: _sub, size: 11),
      ]),
    );
  }

  // ── card font size / colour editing (Super Admin, live dashboard only) ────
  // Same pattern as the per-factory dashboard: a small pencil badge appears
  // on a card when [widget.canEditCards], and tapping it (or, for a card
  // that already has its own tap behaviour, just the badge) opens
  // [CardStyleDialog] for that card's key.
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

  /// For a card that already owns its tap gesture (a map pin drills into
  /// that lot's own command centre) — wrapping it in another full-card
  /// GestureDetector would put two tap handlers over the same area and the
  /// drill-down could stop working, so only the small corner badge gets a
  /// tap target here. The caller stacks it on top of its own card.
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

  // ── shared helpers ────────────────────────────────────────────────────────
  // Transparent circular icon badge with a gentle breathing glow (driven by the
  // shared pulse controller) — the only animated element on the summary cards.
  Widget _iconBadge(IconData icon, Color color, {double box = 42, double iconSize = 20}) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final t = _pulseCtrl.value; // 0..1 ease in/out
        return Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Mostly transparent fill — just a faint accent wash that breathes.
            color: color.withOpacity(0.05 + 0.06 * t),
            border: Border.all(color: color.withOpacity(0.40 + 0.25 * t), width: 1.2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.12 + 0.28 * t), blurRadius: 6 + 9 * t, spreadRadius: -1)],
          ),
          child: Icon(icon, color: color, size: iconSize),
        );
      },
    );
  }

  /// Status indicator dot. Healthy lots get a gentle breathing glow; warn/alert
  /// lots emit an expanding radar ping to pull the eye to problems.
  /// One metric, in its own panel.
  ///
  /// Each card is boxed rather than being a bare row: several stacked values
  /// with nothing between them read as one list of numbers, and the point here
  /// is that each is a separate measurement with its own colour and unit.
  Widget _pinMetricRow(PeccPinMetric m, {CardTextStyle? style}) {
    final color = _metricColors[m.colorKey] ?? _metricColors['cyan']!;
    final labelColor = style != null ? (heroColors[style.labelColorKey] ?? _sub) : _sub;
    final valueColor = style != null ? (heroColors[style.valueColorKey] ?? _white) : _white;
    final labelSize = style != null && style.labelSize > 0 ? style.labelSize.clamp(7.0, 12.0) : 8.5;
    final valueSize = style != null && style.valueSize > 0 ? style.valueSize.clamp(12.0, 24.0) : 16.5;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 11, 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
              border: Border.all(color: color.withOpacity(0.6), width: 1.3),
            ),
            alignment: Alignment.center,
            child: Icon(_metricIcons[m.metricKey] ?? Icons.insights,
                size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.label.toUpperCase(),
                  style: TextStyle(
                      color: labelColor,
                      fontFamily: 'Poppins',
                      fontSize: labelSize,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.value,
                      style: TextStyle(
                          color: valueColor,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: valueSize)),
                  if (m.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(m.unit,
                        style: TextStyle(
                            color: color,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5)),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDot(Color color, _StatusKind status) {
    if (status == _StatusKind.ok) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.35 + 0.4 * _pulseCtrl.value), blurRadius: 3 + 4 * _pulseCtrl.value)],
          ),
        ),
      );
    }
    return SizedBox(
      width: 9,
      height: 9,
      child: AnimatedBuilder(
        animation: _flowCtrl,
        builder: (_, __) => CustomPaint(
          painter: _RadarPing(color, _flowCtrl.value),
          child: Center(
            child: Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          ),
        ),
      ),
    );
  }

  Widget _chip(String pct, bool pos) {
    final c = pos ? _red : _accentG;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(pos ? Icons.arrow_upward : Icons.arrow_downward, color: c, size: 11),
      Text(pct, style: TextStyle(color: c, fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _pill(String label, bool active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? _accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? _accentBlue : _border1),
        ),
        child: Text(label, style: TextStyle(color: active ? _white : _sub, fontFamily: 'Poppins', fontSize: 10)),
      );

  Widget _rmBtn() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: _border1)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('RM', style: TextStyle(color: _sub, fontFamily: 'Poppins', fontSize: 10)),
          SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down, color: _sub, size: 11),
        ]),
      );
}

// ── small reusable glow dot used in the header "Online" indicator ─────────────
class _AnimatedDot extends StatelessWidget {
  final Animation<double> controller;
  final Color color;
  final double size;
  const _AnimatedDot({required this.controller, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color.withOpacity(0.5 + 0.4 * controller.value), blurRadius: 4 + 4 * controller.value, spreadRadius: 1)],
        ),
      ),
    );
  }
}

// ── data classes ──────────────────────────────────────────────────────────────

enum _StatusKind { ok, warn, alert }

class _Stat {
  final String label, sub, value, delta;
  final bool pos;
  final Color color;
  final IconData icon;
  const _Stat(this.label, this.sub, this.value, this.delta, this.pos, this.color, this.icon);
}

class _Rank {
  final String label, sub, location, value;
  final Color color;
  final IconData icon;
  const _Rank(this.label, this.sub, this.location, this.value, this.color, this.icon);
}

class _G {
  final IconData icon;
  final String value, label;
  final Color color;
  const _G(this.icon, this.value, this.label, this.color);
}

// ── header diagonal accent painter ─────────────────────────────────────────
class _HeaderAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final band1 = Path()
      ..moveTo(w * 0.30, 0)
      ..lineTo(w * 0.62, 0)
      ..lineTo(w * 0.56, h)
      ..lineTo(w * 0.24, h)
      ..close();
    canvas.drawPath(
      band1,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1E5FD9).withOpacity(0.22), const Color(0xFF1E5FD9).withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final line1 = Path()..moveTo(w * 0.30, 0)..lineTo(w * 0.24, h);
    final line2 = Path()..moveTo(w * 0.62, 0)..lineTo(w * 0.56, h);
    final linePaint = Paint()
      ..color = const Color(0xFF31ECFC).withOpacity(0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(line1, linePaint);
    canvas.drawPath(line2, linePaint);
  }

  @override
  bool shouldRepaint(_HeaderAccentPainter oldDelegate) => false;
}

// ── mini sparkline (static) ───────────────────────────────────────────────────
// Small glowing accent trend line drawn along the bottom of each summary card —
// this is the card's colour "glow" in the reference design. Static (no anim).
// Expanding radar ping behind an alert/warn status dot — two staggered rings
// growing outward and fading, for a continuous "attention" pulse.
class _RadarPing extends CustomPainter {
  final Color color;
  final double t; // 0..1
  const _RadarPing(this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (final phase in const [0.0, 0.5]) {
      final p = (t + phase) % 1.0;
      final radius = 4.0 + p * 9.0;
      final opacity = (1 - p) * 0.55;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPing old) => old.t != t || old.color != color;
}

class _MiniSpark extends CustomPainter {
  final Color color;
  final double progress; // 0..1 — position of the traveling telemetry pulse
  const _MiniSpark(this.color, {this.progress = 0});
  static const _pts = [0.45, 0.30, 0.55, 0.25, 0.60, 0.40, 0.32, 0.70, 0.50];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (int i = 0; i < _pts.length; i++) {
      final x = i / (_pts.length - 1) * size.width;
      final y = (1 - _pts[i]) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    // Wide soft halo.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Inner glow.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Crisp accent line on top.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    // Traveling telemetry pulse — a glowing dot running along the line.
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final m = metrics.first;
      final pos = m.getTangentForOffset(m.length * progress.clamp(0.0, 1.0))?.position;
      if (pos != null) {
        canvas.drawCircle(pos, 5, Paint()
          ..color = color.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(pos, 2.2, Paint()..color = Colors.white.withOpacity(0.95));
      }
    }
  }

  @override
  bool shouldRepaint(_MiniSpark oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

// ── per-pin connector stubs ───────────────────────────────────────────────────
// Short static line from each lot pin's card down to a small glowing anchor
// dot on the rooftop beneath it — matches the mockup's line-and-node style
// (each card wired to its own spot on the building, not a hub-and-spoke fan).
class _PinConnectorPainter extends CustomPainter {
  final List<Offset> starts;
  final List<Offset> ends;
  final List<Color> colors;
  final double pulse; // 0..1 breathing, for the anchor dot glow

  const _PinConnectorPainter({
    required this.starts,
    required this.ends,
    required this.colors,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < starts.length; i++) {
      final start = starts[i];
      final end = ends[i];
      final color = colors[i];

      canvas.drawLine(start, end, Paint()
        ..color = color.withOpacity(0.45)
        ..strokeWidth = 1.2);

      canvas.drawCircle(start, 2.5, Paint()..color = color.withOpacity(0.8));

      canvas.drawCircle(end, 7 + 2 * pulse, Paint()
        ..color = color.withOpacity(0.25 + 0.15 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(end, 3, Paint()..color = color.withOpacity(0.95));
      canvas.drawCircle(end, 3, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_PinConnectorPainter oldDelegate) => oldDelegate.pulse != pulse;
}

// ── line chart painter ────────────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final double progress; // 0..1 — left→right draw-in reveal
  final double pulse;    // 0..1 — highlighted marker breathing
  const _LinePainter({this.progress = 1, this.pulse = 0});
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _vals = [22.1, 23.4, 24.0, 23.6, 24.8, 26.3, 28.9, 0.0, 0.0, 0.0, 0.0, 0.0];
  static const _yAxis = ['50K', '40K', '30K', '20K', '10K', '0'];
  static const _maxV = 50.0;
  static const _accent = Color(0xFF3B8EFF);
  static const _sub = Color(0xFF8892A4);
  static const _hiIdx = 6; // Jul is highlighted

  @override
  void paint(Canvas canvas, Size size) {
    const lp = 40.0; // left padding for y-axis
    const bp = 20.0; // bottom padding for x labels
    const tp = 22.0; // top padding for value labels
    final cw = size.width - lp;
    final ch = size.height - bp - tp;

    final tp2 = TextPainter(textDirection: TextDirection.ltr);

    // Draw-in reveal — clip to a left→right growing window so the whole chart
    // wipes in on load. (No restore needed: paint runs fresh each frame.)
    canvas.clipRect(Rect.fromLTWH(0, 0, lp + cw * progress.clamp(0.0, 1.0) + 6, size.height));

    // ── Y-axis lines + labels — largest value at top, '0' at bottom ──
    for (int i = 0; i < _yAxis.length; i++) {
      final frac = i / (_yAxis.length - 1);
      final y = tp + frac * ch;
      canvas.drawLine(
          Offset(lp, y),
          Offset(size.width, y),
          Paint()
            ..color = const Color(0xFF1A3A75).withOpacity(0.5)
            ..strokeWidth = 0.5);
      tp2.text = TextSpan(text: _yAxis[i], style: const TextStyle(color: _sub, fontSize: 10, fontFamily: 'Poppins'));
      tp2.layout();
      tp2.paint(canvas, Offset(0, y - tp2.height / 2));
    }
    // 'RM' unit label sits above the topmost gridline, as its own marker.
    tp2.text = const TextSpan(text: 'RM', style: TextStyle(color: _sub, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600));
    tp2.layout();
    tp2.paint(canvas, Offset(0, tp - tp2.height - 4));

    // ── Known data points (solid) ──
    final solidPts = <Offset>[];
    for (int i = 0; i <= _hiIdx; i++) {
      solidPts.add(Offset(
        lp + i / (_vals.length - 1) * cw,
        tp + (1 - _vals[i] / _maxV) * ch,
      ));
    }

    // Fill under solid line
    final fill = Path()
      ..addPolygon(solidPts, false)
      ..lineTo(solidPts.last.dx, tp + ch)
      ..lineTo(solidPts.first.dx, tp + ch)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_accent.withOpacity(0.22), _accent.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(lp, tp, cw, ch)));

    // Solid line
    final solidPath = Path()..addPolygon(solidPts, false);
    canvas.drawPath(
        solidPath,
        Paint()
          ..color = _accent
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round);

    // ── Dotted future line (Aug-Dec, flat projection) ──
    final lastY = solidPts.last.dy;
    for (int i = _hiIdx + 1; i < _vals.length; i++) {
      final x = lp + i / (_vals.length - 1) * cw;
      final dropY = lastY + (i - _hiIdx) * (ch * 0.04);
      final prev = i == _hiIdx + 1 ? solidPts.last : Offset(lp + (i - 1) / (_vals.length - 1) * cw, lastY + (i - 1 - _hiIdx) * (ch * 0.04));
      canvas.drawLine(
          prev,
          Offset(x, dropY),
          Paint()
            ..color = _sub.withOpacity(0.5)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
    }

    // ── Dots + value labels ──
    final dotPaint = Paint()
      ..color = _accent
      ..style = PaintingStyle.fill;
    for (int i = 0; i <= _hiIdx; i++) {
      final pt = solidPts[i];
      final isHi = i == _hiIdx;

      if (isHi) {
        // Breathing pulse ring — expands & fades with the pulse value.
        canvas.drawCircle(pt, 6 + pulse * 6, Paint()..color = _accent.withOpacity(0.28 * (1 - pulse)));
        // Highlight ring
        canvas.drawCircle(pt, 6, Paint()..color = _accent.withOpacity(0.25));
        canvas.drawCircle(pt, 4.5, dotPaint);
        canvas.drawCircle(
            pt,
            4.5,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
        // Callout bubble
        const bw = 42.0;
        const bh = 17.0;
        final bx = pt.dx - bw / 2;
        final by = pt.dy - bh - 8;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(4)), Paint()..color = _accent);
        tp2.text =
            const TextSpan(text: '28.9K', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.bold));
        tp2.layout();
        tp2.paint(canvas, Offset(bx + (bw - tp2.width) / 2, by + (bh - tp2.height) / 2));
      } else {
        canvas.drawCircle(pt, 3, dotPaint);
        // Value label above dot
        final valStr = '${_vals[i]}K';
        tp2.text = TextSpan(text: valStr, style: const TextStyle(color: _sub, fontSize: 9.5, fontFamily: 'Poppins'));
        tp2.layout();
        tp2.paint(canvas, Offset(pt.dx - tp2.width / 2, pt.dy - tp2.height - 4));
      }
    }

    // ── Month labels ──
    for (int i = 0; i < _months.length; i++) {
      final x = lp + i / (_vals.length - 1) * cw;
      tp2.text = TextSpan(
          text: _months[i],
          style: TextStyle(
            color: i == _hiIdx ? _accent : _sub,
            fontSize: 10,
            fontFamily: 'Poppins',
            fontWeight: i == _hiIdx ? FontWeight.w600 : FontWeight.w400,
          ));
      tp2.layout();
      tp2.paint(canvas, Offset(x - tp2.width / 2, size.height - bp + 2));
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.progress != progress || o.pulse != pulse;
}
