part of 'plant_energy_command_center_setting_widget.dart';

// ── Data models ────────────────────────────────────────────────────────────────

class _WidgetMapping {
  final String key;
  String label;
  final String locationKey;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String unit;
  final bool isCalculated;
  final String calculatedLabel;
  String selectedDevice = '';
  String selectedField  = '';
  List<String> availableFields;
  final TextEditingController labelCtrl;

  /// Where this widget sits on the centre picture, as percentages of its width
  /// and height. Only the floor-map machines use it. Blank keeps the built-in
  /// anchor, so swapping the picture is what prompts moving them — not a code
  /// change and a release.
  final TextEditingController xCtrl = TextEditingController();
  final TextEditingController yCtrl = TextEditingController();

  /// True for widgets drawn on top of the centre picture, the only ones a
  /// position means anything for. Floor-map machines and the flow-diagram
  /// cards (Block A/B/C, Plant Total, Solar, Grid TNB) both qualify — both
  /// are positioned dots/cards over a background image.
  bool get isPlaceable => key.startsWith('consumer[') || key.startsWith('flow.');

  /// Cards this machine shows on the floor map. Same shape as a map pin's, so
  /// the two screens are configured the same way rather than each inventing
  /// its own vocabulary. Empty keeps the single value the badge always showed.
  List<_PinMetric> metrics = [];

  /// Whether the card table under this row is open in the settings UI.
  bool expanded = false;

  _WidgetMapping({
    required this.key,
    required this.label,
    required this.locationKey,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.unit,
    this.isCalculated    = false,
    this.calculatedLabel = '',
    this.availableFields = const [],
  }) : labelCtrl = TextEditingController(text: label);

  bool get isMapped =>
      isCalculated || (selectedDevice.isNotEmpty && selectedField.isNotEmpty);

  void dispose() {
    labelCtrl.dispose();
    xCtrl.dispose();
    yCtrl.dispose();
    for (final m in metrics) {
      m.dispose();
    }
  }
}

class _Section {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final List<_WidgetMapping> widgets;

  /// True for the floor-map machines, the one section a user can grow. Every
  /// other section is a fixed set of dashboard slots, so adding a row there
  /// would create a widget with nowhere to appear.
  bool get canAddMachines => title.startsWith('Machine Consumers');

  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.widgets,
  });

  int  get mappedCount => widgets.where((w) => w.isMapped).length;
  bool get allMapped   => mappedCount == widgets.length;
}

// ── Pin Mapping model (Group PEC settings — channel mapping table) ────────────

/// Metric field options for the CHANNEL MAPPING — METRIC FIELD dropdown.
class _MetricOption {
  final String key;
  final String label;
  final String unit;
  const _MetricOption({required this.key, required this.label, required this.unit});
}

const _kPinMetrics = <_MetricOption>[
  _MetricOption(key: 'cost_mtd_total',    label: 'Current Month Accrual (RM)', unit: 'RM'),
  _MetricOption(key: 'max_demand_kW',     label: 'Maximum Demand (kW)',        unit: 'kW'),
  _MetricOption(key: 'peak_usage_kWh',    label: 'Peak Usage (kWh)',           unit: 'kWh'),
  _MetricOption(key: 'off_peak_usage_kWh',label: 'Off-Peak Usage (kWh)',       unit: 'kWh'),
  _MetricOption(
    key:   'cost_mtd_total + kwh_mld_total',
    label: 'Current Month Accrual + Max Demand',
    unit:  'RM / MWh',
  ),
];

/// The card metrics a pin can show on the group dashboard.
///
/// Each entry is one card in the pin's popup: an icon in its own colour, a
/// label, a value and a unit. Previously a pin rendered exactly two hardcoded
/// figures — cost and energy — so adding Max Demand or Solar to a site meant a
/// code change. These are the raw DPM-backed values the data service can
/// already resolve per device.
class _PinMetricOption {
  final String key;
  final String label;
  final String unit;
  final IconData icon;

  /// How this metric is aggregated over the period, and it is a property of
  /// the metric rather than a choice: a max demand is the highest half-hour,
  /// a power factor is an average, energy and cost accumulate. Offering these
  /// as a dropdown would let someone ask for the sum of a power factor.
  final String agg;

  /// Decimal places the value is shown with. Cost and energy read better whole,
  /// power factor is meaningless rounded to an integer.
  final int decimals;

  const _PinMetricOption({
    required this.key,
    required this.label,
    required this.unit,
    required this.icon,
    required this.agg,
    this.decimals = 0,
  });
}

/// The metrics every pin exposes.
///
/// These keys are the vocabulary the whole dashboard speaks: each summary
/// panel picks one of them and aggregates it across pins, so a pin is the
/// single place a site's figures come from. They are also written into saved
/// configuration, which is why they are short, stable names rather than
/// anything describing how a value happens to be computed today.
const _kPinCardMetrics = <_PinMetricOption>[
  _PinMetricOption(
      key: 'cost',
      label: 'Energy Cost (RM)',
      unit: 'RM',
      icon: Icons.attach_money,
      agg: 'sum'),
  _PinMetricOption(
      key: 'energy',
      label: 'Total Energy (kWh)',
      unit: 'kWh',
      icon: Icons.bolt,
      agg: 'sum',
      decimals: 1),
  _PinMetricOption(
      key: 'max_demand',
      label: 'Max Demand (kW)',
      unit: 'kW',
      icon: Icons.show_chart,
      agg: 'max'),
  _PinMetricOption(
      key: 'md_charges',
      label: 'MD Charges (RM)',
      unit: 'RM',
      icon: Icons.receipt_long_outlined,
      agg: 'sum'),
  _PinMetricOption(
      key: 'solar',
      label: 'Solar Generation (kWh)',
      unit: 'kWh',
      icon: Icons.solar_power_outlined,
      agg: 'sum'),
  _PinMetricOption(
      key: 'carbon',
      label: 'Carbon (tCO2e)',
      unit: 'tCO2e',
      icon: Icons.cloud_outlined,
      agg: 'sum',
      decimals: 1),
  _PinMetricOption(
      key: 'pf',
      label: 'Power Factor',
      unit: '',
      icon: Icons.speed,
      agg: 'avg',
      decimals: 3),
];

/// Decimal places a card may be shown with. The metric's own default is used
/// unless someone picks otherwise.
const _kPinMetricDecimals = <int>[0, 1, 2, 3];

/// Named colours, so what is stored is a name rather than an ARGB value the
/// dashboard would have to agree with by coincidence.
const _kPinMetricColors = <String, Color>{
  'cyan':   Color(0xFF22D3EE),
  'green':  Color(0xFF10B981),
  'amber':  Color(0xFFF59E0B),
  'purple': Color(0xFF9A6BFF),
  'red':    Color(0xFFFF5D6C),
};

/// The most cards one pin may show. The popup stops being readable well before
/// this, but the limit exists so a mis-click cannot grow it without bound.
const int kMaxPinMetrics = 8;

/// One card configured on a pin.
class _PinMetric {
  String metricKey;
  String colorKey;

  /// Null means "whatever this metric normally uses", so changing the metric
  /// brings its own sensible default rather than keeping the last one.
  int? decimals;

  final TextEditingController labelCtrl;

  _PinMetric({
    required this.metricKey,
    this.colorKey = 'cyan',
    this.decimals,
    String label = '',
  }) : labelCtrl = TextEditingController(text: label);

  _PinMetricOption? get option {
    for (final o in _kPinCardMetrics) {
      if (o.key == metricKey) return o;
    }
    return null;
  }

  /// The label to draw. Falls back to the metric's own name so a card is never
  /// nameless just because the field was left blank.
  String get effectiveLabel {
    final typed = labelCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return option?.label ?? '';
  }

  String get unit => option?.unit ?? '';
  String get agg => option?.agg ?? 'sum';
  int get effectiveDecimals => decimals ?? option?.decimals ?? 0;
  IconData get icon => option?.icon ?? Icons.insights;
  Color get color => _kPinMetricColors[colorKey] ?? _kPinMetricColors['cyan']!;
  bool get isMapped => metricKey.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'metricKey': metricKey,
        'colorKey': colorKey,
        'label': labelCtrl.text.trim(),
        'decimals': effectiveDecimals,
        // Written for the dashboard to read back; not editable, since it
        // belongs to the metric rather than to this card.
        'agg': agg,
      };

  static _PinMetric fromJson(Map<String, dynamic> j) => _PinMetric(
        metricKey: j['metricKey']?.toString() ?? '',
        colorKey: j['colorKey']?.toString() ?? 'cyan',
        decimals: j['decimals'] is num ? (j['decimals'] as num).toInt() : null,
        label: j['label']?.toString() ?? '',
      );

  void dispose() => labelCtrl.dispose();
}

/// What a summary panel does with the pins underneath it.
///
/// Every panel on the group dashboard reads the same seven pin metrics; what
/// differs is the operation. Naming that here keeps the columns each panel
/// shows honest — a ranking panel has no aggregation to choose, and a trend
/// has no ranking direction.
enum _PanelKind {
  /// Adds the metric up across every mapped pin.
  total,

  /// Orders the pins by the metric and shows the best or worst.
  rank,

  /// Adds up across pins, plotted over time.
  series,
}

const _kPanelAggregations = <String>['sum', 'avg', 'max', 'min'];
const _kPanelRankBy = <String>['highest', 'lowest'];
const _kPanelDirections = <String>['higher is better', 'lower is better'];
const _kPanelIntervals = <String>['daily', 'weekly', 'monthly'];

/// One card, tile or series inside a summary panel.
class _PanelCard {
  /// Stable id, so a saved row survives a label being renamed.
  final String key;

  final TextEditingController labelCtrl;

  /// Which pin metric this reads. Always one of the pin vocabulary — a panel
  /// never maps its own device, which is the whole point of the pins being the
  /// single source of truth.
  String metricKey;

  String agg;
  String rankBy;
  String direction;
  String interval;

  /// The unit shown beside the value on the dashboard.
  ///
  /// Left empty it follows the metric — energy reads kWh, cost reads RM — which
  /// is what every existing configuration does. Typed in, it wins: the same
  /// figure can then be presented as MWh, RM '000, or whatever the customer
  /// reports in, without changing what is measured.
  final TextEditingController unitCtrl;

  _PanelCard({
    required this.key,
    required String label,
    required this.metricKey,
    this.agg = 'sum',
    this.rankBy = 'highest',
    this.direction = 'lower is better',
    this.interval = 'monthly',
    String unit = '',
  })  : labelCtrl = TextEditingController(text: label),
        unitCtrl = TextEditingController(text: unit);

  _PinMetricOption? get option {
    for (final o in _kPinCardMetrics) {
      if (o.key == metricKey) return o;
    }
    return null;
  }

  /// What the metric would call itself, before any override.
  String get defaultUnit => option?.unit ?? '';

  String get unit {
    final typed = unitCtrl.text.trim();
    return typed.isNotEmpty ? typed : defaultUnit;
  }
  String get effectiveLabel {
    final typed = labelCtrl.text.trim();
    return typed.isNotEmpty ? typed : (option?.label ?? '');
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': labelCtrl.text.trim(),
        'metricKey': metricKey,
        'agg': agg,
        'rankBy': rankBy,
        'direction': direction,
        'interval': interval,
        // Only the override is stored. Saving the metric's own unit would
        // freeze it, so a metric that later reports differently would keep
        // showing the old label.
        'unit': unitCtrl.text.trim(),
      };

  static _PanelCard fromJson(Map<String, dynamic> j, _PanelCard fallback) =>
      _PanelCard(
        key: j['key']?.toString() ?? fallback.key,
        label: j['label']?.toString() ?? '',
        metricKey: j['metricKey']?.toString() ?? fallback.metricKey,
        agg: j['agg']?.toString() ?? fallback.agg,
        rankBy: j['rankBy']?.toString() ?? fallback.rankBy,
        direction: j['direction']?.toString() ?? fallback.direction,
        interval: j['interval']?.toString() ?? fallback.interval,
        unit: j['unit']?.toString() ?? '',
      );

  void dispose() {
    labelCtrl.dispose();
    unitCtrl.dispose();
  }
}

/// A summary panel on the group dashboard, and the cards it shows.
class _PanelSpec {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final _PanelKind kind;
  final IconData icon;
  List<_PanelCard> cards;

  _PanelSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.kind,
    required this.icon,
    required this.cards,
  });

  void dispose() {
    for (final c in cards) {
      c.dispose();
    }
  }
}

/// The panels as the dashboard draws them today, used as defaults so an
/// untouched configuration matches what is already on screen.
List<_PanelSpec> defaultPanelSpecs() => [
      _PanelSpec(
        id: 'left',
        title: 'Left Panel — Financial & Energy Summary',
        subtitle: 'Group totals shown down the left of the live dashboard',
        badge: 'SUM of all Cost Driver sites',
        kind: _PanelKind.total,
        icon: Icons.view_sidebar_outlined,
        cards: [
          _PanelCard(key: 'left.cost', label: 'Energy Cost (MTD)', metricKey: 'cost'),
          _PanelCard(key: 'left.solar', label: 'Solar Saving (MTD)', metricKey: 'solar'),
          _PanelCard(key: 'left.md', label: 'MD Charges (MTD)', metricKey: 'md_charges'),
          _PanelCard(key: 'left.energy', label: 'Total Energy (MTD)', metricKey: 'energy'),
          _PanelCard(key: 'left.carbon', label: 'Carbon Emission (MTD)', metricKey: 'carbon'),
        ],
      ),
      _PanelSpec(
        id: 'right',
        title: 'Right Panel — Performance Summary',
        subtitle:
            'Best / worst site rankings shown down the right of the live dashboard',
        badge: 'RANK across sites',
        kind: _PanelKind.rank,
        icon: Icons.leaderboard_outlined,
        cards: [
          _PanelCard(
              key: 'right.cost',
              label: 'Highest Cost (MTD)',
              metricKey: 'cost',
              rankBy: 'highest',
              direction: 'lower is better'),
          _PanelCard(
              key: 'right.saving',
              label: 'Highest Saving (MTD)',
              metricKey: 'solar',
              rankBy: 'highest',
              direction: 'higher is better'),
          _PanelCard(
              key: 'right.solar',
              label: 'Best Solar Generation (MTD)',
              metricKey: 'solar',
              rankBy: 'highest',
              direction: 'higher is better'),
          _PanelCard(
              key: 'right.carbon',
              label: 'Carbon Emission (MTD)',
              metricKey: 'carbon',
              rankBy: 'highest',
              direction: 'lower is better'),
        ],
      ),
      _PanelSpec(
        id: 'bottomLeft',
        title: 'Bottom-Left — Energy Cost Trend',
        subtitle: 'Monthly total cost across all sites, plotted over the year',
        badge: 'SUM of all sites · time series',
        kind: _PanelKind.series,
        icon: Icons.show_chart,
        cards: [
          _PanelCard(
              key: 'trend.cost',
              label: 'Energy Cost',
              metricKey: 'cost',
              interval: 'monthly'),
        ],
      ),
      _PanelSpec(
        id: 'bottomRight',
        title: "Bottom-Right — Today at a Glance",
        subtitle: "Today's group totals shown below the chart",
        badge: 'SUM of all sites · today only',
        kind: _PanelKind.total,
        icon: Icons.today_outlined,
        cards: [
          _PanelCard(key: 'glance.energy', label: 'Energy Today', metricKey: 'energy'),
          _PanelCard(key: 'glance.cost', label: 'Energy Cost Today', metricKey: 'cost'),
          _PanelCard(key: 'glance.solar', label: 'Solar Generated Today', metricKey: 'solar'),
          _PanelCard(key: 'glance.share', label: 'Solar Contribution', metricKey: 'solar'),
        ],
      ),
      _PanelSpec(
        id: 'hero',
        title: 'Center Hero — Group Headline',
        subtitle: 'The big number in the middle of the aerial view',
        badge: 'SUM of all sites',
        kind: _PanelKind.total,
        icon: Icons.center_focus_strong_outlined,
        cards: [
          _PanelCard(key: 'hero.cost', label: 'Energy Cost This Month', metricKey: 'cost'),
          _PanelCard(key: 'hero.energy', label: 'Total Energy', metricKey: 'energy'),
          _PanelCard(key: 'hero.solar', label: 'Solar Saving (MTD)', metricKey: 'solar'),
        ],
      ),
    ];

/// One row in the revamped pin mapping table.
class _PinMapping {
  final String key;          // e.g. 'pin[0]'
  final int    pinIndex;     // 0-based
  final String defaultLabel; // e.g. 'Cost Driver 1' / 'LOT 53A'
  final bool   isCostDriver; // true → no DATA SCOPE dropdown
  final bool   isCurrentSite;// true → badge "current site"
  final TextEditingController displayNameCtrl;

  /// The TNB meter id (TnbMeter.id) selected for DATA SCOPE.
  String selectedSiteId   = '';
  /// meterLabel of the selected site.
  String selectedSiteLabel = '';
  /// Metric field key.
  String selectedMetric   = '';

  /// Cards this pin shows on the dashboard. Empty means the pin keeps the old
  /// two-figure layout, so a site nobody has configured yet is untouched.
  List<_PinMetric> metrics = [];

  /// The solar device for this site, if it has one.
  ///
  /// A cost driver points at the site's incoming meter, which measures grid
  /// energy — summing it and calling the result solar generation reported the
  /// opposite of what was being measured. Solar has to come from a solar
  /// device, and only the configuration knows which one belongs to which site.
  String selectedSolarDevice = '';

  /// Whether the metric table under this row is open in the settings UI.
  bool expanded = false;

  /// Where this pin sits on the aerial photo, as percentages of its width and
  /// height. Held as text because these are typed in; blank means "use the
  /// built-in position", which keeps the six original pins exactly where they
  /// have always been until somebody moves them.
  final TextEditingController xCtrl = TextEditingController();
  final TextEditingController yCtrl = TextEditingController();

  /// True for a pin the user added, which may be removed again. The six that
  /// ship with the dashboard stay, because other settings still address them
  /// by key.
  final bool isRemovable;

  _PinMapping({
    required this.key,
    required this.pinIndex,
    required this.defaultLabel,
    this.isCostDriver  = false,
    this.isCurrentSite = false,
    this.isRemovable   = false,
    String? initialDisplayName,
  }) : displayNameCtrl = TextEditingController(text: initialDisplayName ?? defaultLabel);

  bool get isMapped {
    if (isCostDriver) return selectedMetric.isNotEmpty;
    return selectedSiteId.isNotEmpty && selectedMetric.isNotEmpty;
  }

  String get unit {
    if (selectedMetric.isEmpty) return '—';
    try {
      return _kPinMetrics.firstWhere((m) => m.key == selectedMetric).unit;
    } catch (_) {
      return '—';
    }
  }

  void dispose() {
    displayNameCtrl.dispose();
    xCtrl.dispose();
    yCtrl.dispose();
    for (final m in metrics) {
      m.dispose();
    }
  }
}

// ── Factory Overview (Block B) card filters — lot237_dashboard_v6.html ─────────

class _FoDeviceGroup {
  String id;
  String name;
  List<String> members;

  _FoDeviceGroup({
    required this.id,
    required this.name,
    List<String>? members,
  }) : members = members ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members,
      };

  factory _FoDeviceGroup.fromJson(Map<String, dynamic> j) => _FoDeviceGroup(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        members: (j['members'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(),
      );
}

/// Per-card filter: data source group + include/exclude overrides + display opts.
class _FoCardFilter {
  final String key; // summary | forecast | cost | consumers | distribution
  final String title;
  final String subtitle;
  final String kind; // metrics | fields | rank | pie
  String groupId;
  List<String> include;
  List<String> exclude;
  // metrics / fields
  List<String> metrics;
  List<String> fields;
  bool showSpark;
  bool showChart;
  bool showBar;
  bool showTotal;
  int topN;
  int legendN;
  double tariff;
  String currency;

  _FoCardFilter({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.groupId = 'g_all',
    List<String>? include,
    List<String>? exclude,
    List<String>? metrics,
    List<String>? fields,
    this.showSpark = true,
    this.showChart = true,
    this.showBar = true,
    this.showTotal = true,
    this.topN = 10,
    this.legendN = 14,
    this.tariff = 0.365,
    this.currency = 'RM',
  })  : include = include ?? [],
        exclude = exclude ?? [],
        metrics = metrics ?? [],
        fields = fields ?? [];

  Map<String, dynamic> toJson() => {
        'group': groupId,
        'include': include,
        'exclude': exclude,
        'metrics': metrics,
        'fields': fields,
        'showSpark': showSpark,
        'showChart': showChart,
        'showBar': showBar,
        'showTotal': showTotal,
        'topN': topN,
        'legendN': legendN,
        'tariff': tariff,
        'currency': currency,
      };

  void applyJson(Map<String, dynamic> j) {
    groupId = j['group']?.toString() ?? groupId;
    include = (j['include'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    exclude = (j['exclude'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    if (j['metrics'] is List) {
      metrics = (j['metrics'] as List).map((e) => e.toString()).toList();
    }
    if (j['fields'] is List) {
      fields = (j['fields'] as List).map((e) => e.toString()).toList();
    }
    showSpark = j['showSpark'] as bool? ?? showSpark;
    showChart = j['showChart'] as bool? ?? showChart;
    showBar = j['showBar'] as bool? ?? showBar;
    showTotal = j['showTotal'] as bool? ?? showTotal;
    topN = (j['topN'] as num?)?.toInt() ?? topN;
    legendN = (j['legendN'] as num?)?.toInt() ?? legendN;
    tariff = (j['tariff'] as num?)?.toDouble() ?? tariff;
    currency = j['currency']?.toString() ?? currency;
  }
}
