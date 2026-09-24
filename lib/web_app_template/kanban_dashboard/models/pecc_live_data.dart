import 'package:flutter/material.dart' show Color;

/// One configured card on a summary panel, already reduced to text.
class PeccPanelCardLive {
  final String key;
  final String label;
  final String value;

  /// The site this figure belongs to, for ranked panels. Empty for totals,
  /// which belong to the group rather than to any one site.
  final String site;

  const PeccPanelCardLive({
    required this.key,
    required this.label,
    required this.value,
    this.site = '',
  });
}

/// Live kWh + costing values resolved from PECC settings mappings.
class PeccLiveData {
  final String totalCostMtd;
  final String totalEnergyMtd;
  final String specificCost;
  final List<PeccCostDriverLive> costDrivers;
  final String energyToday;
  final String energyCostToday;
  /// First 4 cost-driver pins (legacy group ECC).
  final List<PeccPinLive> pins;
  /// Group map pin index → live value (e.g. index 6 = Lot 237).
  final Map<int, PeccPinLive> pinsByIndex;

  /// Which site leads on each ranked metric, for the right rail.
  ///
  /// Keyed by the ranking's id — cost, saving, solar, efficiency, carbon —
  /// each holding the winning site's name and its figure. The rail used to
  /// print "LOT 237 / RM 28,900" as a literal, so it named a winner even when
  /// no site had reported anything.
  final Map<String, ({String site, String value})> rankings;

  /// Panel id — left, right, bottomRight, hero — to the cards configured on
  /// it. Each card names a pin metric and how to reduce it across the sites,
  /// so what the dashboard shows follows the configuration rather than a
  /// decision taken in the widget.
  final Map<String, List<PeccPanelCardLive>> panelCards;

  /// Today's solar for the group, and its share of today's energy.
  final String solarToday;
  final String solarSharePct;

  /// Group totals the left rail shows, summed across the pins.
  ///
  /// These were literals in the widget — "RM 68,500" and "578 tCO2e" were
  /// printed on the live dashboard whatever the meters said, and solar was a
  /// permanent dash. A figure nobody can trace to a site is worse than no
  /// figure, because it looks like it was measured.
  final String groupSolar;
  final String groupMdCharges;
  final String groupCarbon;

  /// The pin indices the configuration actually defines, in order.
  ///
  /// The map used to draw a fixed six — pin[0..2] and pin[4..6] — so a pin
  /// added in settings was saved and resolved but never appeared on the
  /// picture. Empty means "use the built-in six", which keeps an untouched
  /// dashboard exactly as it was.
  final List<int> pinOrder;

  /// Group map pin index → where it sits on the aerial photo, as fractions of
  /// the photo's width and height. Only holds the pins somebody has positioned
  /// from settings; anything absent keeps the position built into the widget,
  /// so the original sites do not jump when this arrives.
  final Map<int, ({double x, double y})> pinPositions;

  final bool hasData;

  // Lot 237 Energy Command Center
  final String heroTotalEnergyToday;
  final String heroSolarToday;
  final String heroEnergyCostToday;
  final String heroCarbonToday;
  final List<PeccHeroDelta> heroDeltas;
  final String sidebarCurrentLoad;
  final String sidebarCurrentLoadSub;
  final String sidebarMaxDemand;
  final String sidebarMaxDemandSub;
  final double sidebarMdBarPct;
  final String sidebarPowerFactor;
  final String sidebarPowerFactorSub;
  final String sidebarSolarContribution;
  final String sidebarSolarSub;
  final String sidebarPlantHealth;
  final String sidebarPlantHealthSub;
  final Map<String, String> flowValues;
  final Map<String, String> flowPcts;
  final String plantMdPct;

  // Lot 237 mode support (Daily vs Monthly)
  // Daily mode: 30-min SQL demand-style (power-load-24h).
  // Monthly mode: daily-interval SQL energy-style (Overall_daily_energy_consumption).
  final Map<String, String> flowValuesMonthly;
  final Map<String, String> flowPctsMonthly;

  /// Monthly-mode series (daily interval).
  /// - `chartLoadDailyKwh`: plant/main device daily kWh bars/line
  /// - `chartMdDailyMaxKw`: daily max demand (kW) for this month
  /// - `chartSolarDailyKwh`: solar device daily kWh
  final List<double> chartLoadDailyKwh;
  final List<double> chartMdDailyMaxKw;
  final List<double> chartSolarDailyKwh;
  /// X-axis labels aligned with chart series (daily = HH:mm, monthly = date).
  final List<String> chartLoadLabels;
  final List<String> chartMdLabels;
  final List<String> chartSolarLabels;
  final List<String> chartLoadDailyLabels;
  final List<String> chartMdDailyLabels;
  final List<String> chartSolarDailyLabels;
  final int alertCritical;
  final int alertWarning;
  final int alertInfo;
  final List<PeccLotEvent> todayEvents;
  final List<double> chartLoadProfile;
  final List<double> chartMdProfile;
  final List<double> chartSolarProfile;
  /// Raw kW series for footer fl_chart (power-load-24h / hourly).
  final List<double> chartLoadKw;
  /// Per-bucket max_demand_kW (30-min SQL) — not cumulative.
  final List<double> chartMdKw;
  final List<double> chartMdCumulativeKw;
  final List<double> chartSolarKw;
  final double chartContractKw;
  final List<PeccBlockRow> blockBreakdown;
  final String blockBreakdownTotal;
  final String lastUpdated;

  // Power Flow (Lot 237) — live wiring; UI falls back to mock when empty.
  final String heroGridImportToday;
  final List<PeccHeroDelta> powerFlowHeroDeltas;
  final String pfPlantTotalKwh;
  final String pfPlantSolarKwh;
  final String pfPlantSolarPct;
  final String pfPlantGridKwh;
  final String pfPlantGridPct;
  final String pfTnbKwh;
  final String pfTnbHz;
  final String pfTnbPf;
  final List<PeccPowerFlowBlock> pfBlocks;
  final List<String> pfInsights;
  final List<double> pfTrendTotal;
  final List<double> pfTrendGrid;
  final List<double> pfTrendSolar;
  final List<PeccBlockRow> pfBlockBars;

  // Power Flow — Monthly (MTD) counterparts for Daily/Monthly toggle.
  final List<PeccHeroDelta> powerFlowHeroDeltasMonthly;
  final String pfPlantTotalKwhMonthly;
  final String pfPlantSolarKwhMonthly;
  final String pfPlantSolarPctMonthly;
  final String pfPlantGridKwhMonthly;
  final String pfPlantGridPctMonthly;
  final String pfTnbKwhMonthly;
  final String pfHeroCostMonthly;
  final String pfHeroCarbonMonthly;
  final List<PeccPowerFlowBlock> pfBlocksMonthly;
  final List<String> pfInsightsMonthly;
  final List<double> pfTrendTotalMonthly;
  final List<double> pfTrendGridMonthly;
  final List<double> pfTrendSolarMonthly;
  final List<String> pfTrendMonthlyLabels;

  const PeccLiveData({
    this.pinOrder = const [],
    this.pinPositions = const {},
    this.rankings = const {},
    this.panelCards = const {},
    this.solarToday = '—',
    this.solarSharePct = '—',
    this.groupSolar = '—',
    this.groupMdCharges = '—',
    this.groupCarbon = '—',
    this.totalCostMtd = '—',
    this.totalEnergyMtd = '—',
    this.specificCost = '—',
    this.costDrivers = const [],
    this.energyToday = '—',
    this.energyCostToday = '—',
    this.pins = const [],
    this.pinsByIndex = const {},
    this.hasData = false,
    this.heroTotalEnergyToday = '—',
    this.heroSolarToday = '—',
    this.heroEnergyCostToday = '—',
    this.heroCarbonToday = '—',
    this.heroDeltas = const [],
    this.sidebarCurrentLoad = '—',
    this.sidebarCurrentLoadSub = '—',
    this.sidebarMaxDemand = '—',
    this.sidebarMaxDemandSub = '—',
    this.sidebarMdBarPct = 0,
    this.sidebarPowerFactor = '—',
    this.sidebarPowerFactorSub = '—',
    this.sidebarSolarContribution = '—',
    this.sidebarSolarSub = '—',
    this.sidebarPlantHealth = '—',
    this.sidebarPlantHealthSub = '—',
    this.flowValues = const {},
    this.flowPcts = const {},
    this.plantMdPct = '—',
    this.flowValuesMonthly = const {},
    this.flowPctsMonthly = const {},
    this.alertCritical = 0,
    this.alertWarning = 0,
    this.alertInfo = 0,
    this.todayEvents = const [],
    this.chartLoadProfile = const [],
    this.chartMdProfile = const [],
    this.chartSolarProfile = const [],
    this.chartLoadKw = const [],
    this.chartMdKw = const [],
    this.chartMdCumulativeKw = const [],
    this.chartSolarKw = const [],
    this.chartLoadDailyKwh = const [],
    this.chartMdDailyMaxKw = const [],
    this.chartSolarDailyKwh = const [],
    this.chartLoadLabels = const [],
    this.chartMdLabels = const [],
    this.chartSolarLabels = const [],
    this.chartLoadDailyLabels = const [],
    this.chartMdDailyLabels = const [],
    this.chartSolarDailyLabels = const [],
    this.chartContractKw = 2100,
    this.blockBreakdown = const [],
    this.blockBreakdownTotal = '—',
    this.lastUpdated = '—',
    this.heroGridImportToday = '—',
    this.powerFlowHeroDeltas = const [],
    this.pfPlantTotalKwh = '—',
    this.pfPlantSolarKwh = '—',
    this.pfPlantSolarPct = '—',
    this.pfPlantGridKwh = '—',
    this.pfPlantGridPct = '—',
    this.pfTnbKwh = '—',
    this.pfTnbHz = '—',
    this.pfTnbPf = '—',
    this.pfBlocks = const [],
    this.pfInsights = const [],
    this.pfTrendTotal = const [],
    this.pfTrendGrid = const [],
    this.pfTrendSolar = const [],
    this.pfBlockBars = const [],
    this.powerFlowHeroDeltasMonthly = const [],
    this.pfPlantTotalKwhMonthly = '—',
    this.pfPlantSolarKwhMonthly = '—',
    this.pfPlantSolarPctMonthly = '—',
    this.pfPlantGridKwhMonthly = '—',
    this.pfPlantGridPctMonthly = '—',
    this.pfTnbKwhMonthly = '—',
    this.pfHeroCostMonthly = '—',
    this.pfHeroCarbonMonthly = '—',
    this.pfBlocksMonthly = const [],
    this.pfInsightsMonthly = const [],
    this.pfTrendTotalMonthly = const [],
    this.pfTrendGridMonthly = const [],
    this.pfTrendSolarMonthly = const [],
    this.pfTrendMonthlyLabels = const [],
  });

  static const empty = PeccLiveData();

  static bool _isPlaceholder(String v) => v.isEmpty || v == '—';

  static String _pickStr(String newer, String older) =>
      !_isPlaceholder(newer) ? newer : older;

  static List<double> _pickSeries(List<double> newer, List<double> older) {
    final newHas = newer.length >= 2 && newer.any((v) => v > 0);
    final oldHas = older.length >= 2 && older.any((v) => v > 0);
    if (newHas && (!oldHas || newer.length >= older.length)) return newer;
    if (oldHas) return older;
    return newer.length >= older.length ? newer : older;
  }

  static List<String> _pickLabels(List<String> newer, List<String> older) {
    if (newer.length >= 2) return newer;
    if (older.length >= 2) return older;
    return newer.isNotEmpty ? newer : older;
  }

  static Map<String, String> _pickMap(Map<String, String> newer, Map<String, String> older) =>
      newer.isNotEmpty ? newer : older;

  /// Overlay [newer] onto this snapshot without wiping fields that are still loading.
  PeccLiveData mergeWith(PeccLiveData newer) {
    return PeccLiveData(
      totalCostMtd: _pickStr(newer.totalCostMtd, totalCostMtd),
      totalEnergyMtd: _pickStr(newer.totalEnergyMtd, totalEnergyMtd),
      specificCost: _pickStr(newer.specificCost, specificCost),
      costDrivers: newer.costDrivers.isNotEmpty ? newer.costDrivers : costDrivers,
      energyToday: _pickStr(newer.energyToday, energyToday),
      energyCostToday: _pickStr(newer.energyCostToday, energyCostToday),
      pins: newer.pins.isNotEmpty ? newer.pins : pins,
      pinsByIndex: newer.pinsByIndex.isNotEmpty ? newer.pinsByIndex : pinsByIndex,
      // Easy to miss, and the reason configured pin positions appeared to do
      // nothing: this merge runs on every refresh, and any field it forgets is
      // silently dropped from the snapshot the widgets actually read.
      pinOrder: newer.pinOrder.isNotEmpty ? newer.pinOrder : pinOrder,
      pinPositions:
          newer.pinPositions.isNotEmpty ? newer.pinPositions : pinPositions,
      rankings: newer.rankings.isNotEmpty ? newer.rankings : rankings,
      panelCards: newer.panelCards.isNotEmpty ? newer.panelCards : panelCards,
      solarToday: _pickStr(newer.solarToday, solarToday),
      solarSharePct: _pickStr(newer.solarSharePct, solarSharePct),
      groupSolar: _pickStr(newer.groupSolar, groupSolar),
      groupMdCharges: _pickStr(newer.groupMdCharges, groupMdCharges),
      groupCarbon: _pickStr(newer.groupCarbon, groupCarbon),
      hasData: newer.hasData || hasData,
      heroTotalEnergyToday: _pickStr(newer.heroTotalEnergyToday, heroTotalEnergyToday),
      heroSolarToday: _pickStr(newer.heroSolarToday, heroSolarToday),
      heroEnergyCostToday: _pickStr(newer.heroEnergyCostToday, heroEnergyCostToday),
      heroCarbonToday: _pickStr(newer.heroCarbonToday, heroCarbonToday),
      heroDeltas: newer.heroDeltas.isNotEmpty ? newer.heroDeltas : heroDeltas,
      sidebarCurrentLoad: _pickStr(newer.sidebarCurrentLoad, sidebarCurrentLoad),
      sidebarCurrentLoadSub: _pickStr(newer.sidebarCurrentLoadSub, sidebarCurrentLoadSub),
      sidebarMaxDemand: _pickStr(newer.sidebarMaxDemand, sidebarMaxDemand),
      sidebarMaxDemandSub: _pickStr(newer.sidebarMaxDemandSub, sidebarMaxDemandSub),
      sidebarMdBarPct: newer.sidebarMdBarPct > 0 ? newer.sidebarMdBarPct : sidebarMdBarPct,
      sidebarPowerFactor: _pickStr(newer.sidebarPowerFactor, sidebarPowerFactor),
      sidebarPowerFactorSub: _pickStr(newer.sidebarPowerFactorSub, sidebarPowerFactorSub),
      sidebarSolarContribution: _pickStr(newer.sidebarSolarContribution, sidebarSolarContribution),
      sidebarSolarSub: _pickStr(newer.sidebarSolarSub, sidebarSolarSub),
      sidebarPlantHealth: _pickStr(newer.sidebarPlantHealth, sidebarPlantHealth),
      sidebarPlantHealthSub: _pickStr(newer.sidebarPlantHealthSub, sidebarPlantHealthSub),
      flowValues: _pickMap(newer.flowValues, flowValues),
      flowPcts: _pickMap(newer.flowPcts, flowPcts),
      plantMdPct: _pickStr(newer.plantMdPct, plantMdPct),
      flowValuesMonthly: _pickMap(newer.flowValuesMonthly, flowValuesMonthly),
      flowPctsMonthly: _pickMap(newer.flowPctsMonthly, flowPctsMonthly),
      alertCritical: newer.alertCritical,
      alertWarning: newer.alertWarning,
      alertInfo: newer.alertInfo,
      todayEvents: newer.todayEvents.isNotEmpty ? newer.todayEvents : todayEvents,
      chartLoadProfile: _pickSeries(newer.chartLoadProfile, chartLoadProfile),
      chartMdProfile: _pickSeries(newer.chartMdProfile, chartMdProfile),
      chartSolarProfile: _pickSeries(newer.chartSolarProfile, chartSolarProfile),
      chartLoadKw: _pickSeries(newer.chartLoadKw, chartLoadKw),
      chartMdKw: _pickSeries(newer.chartMdKw, chartMdKw),
      chartMdCumulativeKw: _pickSeries(newer.chartMdCumulativeKw, chartMdCumulativeKw),
      chartSolarKw: _pickSeries(newer.chartSolarKw, chartSolarKw),
      chartLoadDailyKwh: _pickSeries(newer.chartLoadDailyKwh, chartLoadDailyKwh),
      chartMdDailyMaxKw: _pickSeries(newer.chartMdDailyMaxKw, chartMdDailyMaxKw),
      chartSolarDailyKwh: _pickSeries(newer.chartSolarDailyKwh, chartSolarDailyKwh),
      chartLoadLabels: _pickLabels(newer.chartLoadLabels, chartLoadLabels),
      chartMdLabels: _pickLabels(newer.chartMdLabels, chartMdLabels),
      chartSolarLabels: _pickLabels(newer.chartSolarLabels, chartSolarLabels),
      chartLoadDailyLabels: _pickLabels(newer.chartLoadDailyLabels, chartLoadDailyLabels),
      chartMdDailyLabels: _pickLabels(newer.chartMdDailyLabels, chartMdDailyLabels),
      chartSolarDailyLabels: _pickLabels(newer.chartSolarDailyLabels, chartSolarDailyLabels),
      chartContractKw: newer.chartContractKw > 0 ? newer.chartContractKw : chartContractKw,
      blockBreakdown: newer.blockBreakdown.isNotEmpty ? newer.blockBreakdown : blockBreakdown,
      blockBreakdownTotal: _pickStr(newer.blockBreakdownTotal, blockBreakdownTotal),
      lastUpdated: _pickStr(newer.lastUpdated, lastUpdated),
      heroGridImportToday: _pickStr(newer.heroGridImportToday, heroGridImportToday),
      powerFlowHeroDeltas:
          newer.powerFlowHeroDeltas.isNotEmpty ? newer.powerFlowHeroDeltas : powerFlowHeroDeltas,
      pfPlantTotalKwh: _pickStr(newer.pfPlantTotalKwh, pfPlantTotalKwh),
      pfPlantSolarKwh: _pickStr(newer.pfPlantSolarKwh, pfPlantSolarKwh),
      pfPlantSolarPct: _pickStr(newer.pfPlantSolarPct, pfPlantSolarPct),
      pfPlantGridKwh: _pickStr(newer.pfPlantGridKwh, pfPlantGridKwh),
      pfPlantGridPct: _pickStr(newer.pfPlantGridPct, pfPlantGridPct),
      pfTnbKwh: _pickStr(newer.pfTnbKwh, pfTnbKwh),
      pfTnbHz: _pickStr(newer.pfTnbHz, pfTnbHz),
      pfTnbPf: _pickStr(newer.pfTnbPf, pfTnbPf),
      pfBlocks: newer.pfBlocks.isNotEmpty ? newer.pfBlocks : pfBlocks,
      pfInsights: newer.pfInsights.isNotEmpty ? newer.pfInsights : pfInsights,
      pfTrendTotal: _pickSeries(newer.pfTrendTotal, pfTrendTotal),
      pfTrendGrid: _pickSeries(newer.pfTrendGrid, pfTrendGrid),
      pfTrendSolar: _pickSeries(newer.pfTrendSolar, pfTrendSolar),
      pfBlockBars: newer.pfBlockBars.isNotEmpty ? newer.pfBlockBars : pfBlockBars,
      powerFlowHeroDeltasMonthly: newer.powerFlowHeroDeltasMonthly.isNotEmpty
          ? newer.powerFlowHeroDeltasMonthly
          : powerFlowHeroDeltasMonthly,
      pfPlantTotalKwhMonthly: _pickStr(newer.pfPlantTotalKwhMonthly, pfPlantTotalKwhMonthly),
      pfPlantSolarKwhMonthly: _pickStr(newer.pfPlantSolarKwhMonthly, pfPlantSolarKwhMonthly),
      pfPlantSolarPctMonthly: _pickStr(newer.pfPlantSolarPctMonthly, pfPlantSolarPctMonthly),
      pfPlantGridKwhMonthly: _pickStr(newer.pfPlantGridKwhMonthly, pfPlantGridKwhMonthly),
      pfPlantGridPctMonthly: _pickStr(newer.pfPlantGridPctMonthly, pfPlantGridPctMonthly),
      pfTnbKwhMonthly: _pickStr(newer.pfTnbKwhMonthly, pfTnbKwhMonthly),
      pfHeroCostMonthly: _pickStr(newer.pfHeroCostMonthly, pfHeroCostMonthly),
      pfHeroCarbonMonthly: _pickStr(newer.pfHeroCarbonMonthly, pfHeroCarbonMonthly),
      pfBlocksMonthly: newer.pfBlocksMonthly.isNotEmpty ? newer.pfBlocksMonthly : pfBlocksMonthly,
      pfInsightsMonthly: newer.pfInsightsMonthly.isNotEmpty ? newer.pfInsightsMonthly : pfInsightsMonthly,
      pfTrendTotalMonthly: _pickSeries(newer.pfTrendTotalMonthly, pfTrendTotalMonthly),
      pfTrendGridMonthly: _pickSeries(newer.pfTrendGridMonthly, pfTrendGridMonthly),
      pfTrendSolarMonthly: _pickSeries(newer.pfTrendSolarMonthly, pfTrendSolarMonthly),
      pfTrendMonthlyLabels: _pickLabels(newer.pfTrendMonthlyLabels, pfTrendMonthlyLabels),
    );
  }
}

class PeccPowerFlowBlock {
  final String label;
  final String totalKwh;
  final String gridKwh;
  final String gridPct;
  final String solarKwh;
  final String solarPct;
  final double totalRaw;

  const PeccPowerFlowBlock({
    required this.label,
    required this.totalKwh,
    required this.gridKwh,
    required this.gridPct,
    required this.solarKwh,
    required this.solarPct,
    this.totalRaw = 0,
  });
}

class PeccHeroDelta {
  final String text;
  final bool favorable;

  const PeccHeroDelta({this.text = '—', this.favorable = false});
}

class PeccLotEvent {
  final String time;
  final String title;
  final String detail;

  const PeccLotEvent({required this.time, required this.title, this.detail = ''});
}

class PeccBlockRow {
  final String label;
  final String kwhDisplay;
  final double fraction;

  const PeccBlockRow({required this.label, required this.kwhDisplay, required this.fraction});
}

class PeccCostDriverLive {
  final String label;
  final String costDisplay;
  final String pctDisplay;

  const PeccCostDriverLive({
    required this.label,
    required this.costDisplay,
    this.pctDisplay = '',
  });
}

/// One card inside a map pin, already formatted for display.
///
/// The value arrives as text rather than a number because each metric has its
/// own rounding and unit — RM with thousands separators, MWh to one decimal,
/// power factor to three — and that formatting lives with the data, not with
/// the widget that happens to draw it.
class PeccPinMetric {
  final String metricKey;
  final String label;
  final String value;
  final String unit;
  final String colorKey;

  /// The figure behind [value], unrounded and in the metric's base unit (RM,
  /// kWh, kW, kg CO2e, or the power factor itself). Zero when the pin has no
  /// reading. Kept so the centre card can add up exactly what the pins show.
  final double amount;

  const PeccPinMetric({
    required this.metricKey,
    required this.label,
    required this.value,
    required this.unit,
    required this.colorKey,
    this.amount = 0,
  });
}

class PeccPinLive {
  final String costDisplay;
  final String energyDisplay;

  /// Cards configured for this pin in settings. Empty for a pin nobody has
  /// configured, and the card then falls back to the cost/energy pair above,
  /// so an existing dashboard is unchanged until someone opts in.
  final List<PeccPinMetric> metrics;

  /// The numbers behind [costDisplay] and [energyDisplay], for totals.
  final double costRm;
  final double energyKwh;

  const PeccPinLive({
    required this.costDisplay,
    required this.energyDisplay,
    this.metrics = const [],
    this.costRm = 0,
    this.energyKwh = 0,
  });
}

// ── Group hero (centre card) customisation ─────────────────────────────────
//
// A copy of the vocabulary the pin cards already speak (`_PinMetricOption` in
// the PECC settings page), so the hero card and a pin can never disagree
// about a metric's label, unit or how it reduces across sites. Duplicated
// rather than shared because the settings page's copy is private to its own
// library — the same reason the preview widget keeps its own colour/icon maps.
class HeroMetricInfo {
  final String label;
  final String unit;

  /// How this metric combines across the lots that are summed. Fixed per
  /// metric, not a per-card choice — the same rule pin cards already use, so
  /// the hero card cannot be asked for the sum of a power factor.
  final String agg; // 'sum' | 'avg' | 'max'
  final int decimals;

  const HeroMetricInfo(this.label, this.unit, this.agg, this.decimals);
}

const heroMetrics = <String, HeroMetricInfo>{
  'cost': HeroMetricInfo('Energy Cost', 'RM', 'sum', 0),
  'energy': HeroMetricInfo('Total Energy', 'kWh', 'sum', 0),
  'max_demand': HeroMetricInfo('Max Demand', 'kW', 'max', 0),
  'md_charges': HeroMetricInfo('MD Charges', 'RM', 'sum', 0),
  'solar': HeroMetricInfo('Solar Generation', 'kWh', 'sum', 0),
  'carbon': HeroMetricInfo('Carbon', 'tCO2e', 'sum', 1),
  'pf': HeroMetricInfo('Power Factor', '', 'avg', 3),
};

/// Named colours for the hero card's two figures — the same small palette
/// the pin cards already use, so a colour picked here reads as the same
/// colour on a pin.
const heroColors = <String, Color>{
  'white': Color(0xFFFFFFFF),
  'cyan': Color(0xFF22D3EE),
  'green': Color(0xFF10B981),
  'amber': Color(0xFFF59E0B),
  'purple': Color(0xFF9A6BFF),
  'red': Color(0xFFFF5D6C),
};

/// Renders a metric's raw amount the way every other figure on this
/// dashboard is written — RM with thousands separators, kWh switching to MWh
/// past 1000, carbon in tonnes, power factor to three places. Zero (no
/// reading) reads as a dash rather than a number nobody measured.
String heroFormatMetric(String metricKey, double amount) {
  if (amount <= 0) return '—';
  switch (metricKey) {
    case 'cost':
    case 'md_charges':
      return 'RM ${_heroThousands(amount.round().toString())}';
    case 'energy':
    case 'solar':
      if (amount >= 1000) {
        return '${_heroThousands((amount / 1000).toStringAsFixed(1))} MWh';
      }
      return '${_heroThousands(amount.round().toString())} kWh';
    case 'carbon':
      return '${(amount / 1000).toStringAsFixed(1)} tCO2e';
    case 'max_demand':
      return '${_heroThousands(amount.round().toString())} kW';
    case 'pf':
      return amount.toStringAsFixed(3);
    default:
      return _heroThousands(amount.round().toString());
  }
}

String _heroThousands(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// One figure the hero card shows — its name, which metric it totals, how it
/// is coloured and sized. An empty [metricKey] means "not chosen", and the
/// hero card then falls back to its original built-in figure for that slot
/// rather than showing something nobody configured.
class HeroFigureConfig {
  const HeroFigureConfig({
    this.name = '',
    this.nameSize = 0,
    this.metricKey = '',
    this.colorKey = '',
    this.valueSize = 0,
  });

  final String name;

  /// 0 keeps the built-in size for this slot.
  final double nameSize;
  final String metricKey;

  /// A key into [heroColors]. Empty keeps the slot's built-in colour.
  final String colorKey;
  final double valueSize;

  bool get isSet => metricKey.trim().isNotEmpty;

  HeroFigureConfig copyWith({
    String? name,
    double? nameSize,
    String? metricKey,
    String? colorKey,
    double? valueSize,
  }) =>
      HeroFigureConfig(
        name: name ?? this.name,
        nameSize: nameSize ?? this.nameSize,
        metricKey: metricKey ?? this.metricKey,
        colorKey: colorKey ?? this.colorKey,
        valueSize: valueSize ?? this.valueSize,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'nameSize': nameSize,
        'metricKey': metricKey,
        'colorKey': colorKey,
        'valueSize': valueSize,
      };

  static HeroFigureConfig fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HeroFigureConfig();
    return HeroFigureConfig(
      name: json['name']?.toString() ?? '',
      nameSize: (json['nameSize'] as num?)?.toDouble() ?? 0,
      metricKey: json['metricKey']?.toString() ?? '',
      colorKey: json['colorKey']?.toString() ?? '',
      valueSize: (json['valueSize'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// What the group map's centre card shows and how big it is drawn.
///
/// Unset ([isCustom] false) means nobody has customised it — the card then
/// keeps the exact layout it has always had (total cost, total energy, the
/// group's name), the same figure every dashboard showed before this existed.
/// Customising it picks one metric for the main figure and one for the sub
/// figure, each summed (or averaged / maxed, per the metric) across the lots
/// chosen — not a second, different way of drawing the card.
class HeroCardConfig {
  const HeroCardConfig({
    this.title = '',
    this.titleSize = 0,
    this.main = const HeroFigureConfig(),
    this.sub = const HeroFigureConfig(),
    this.includedPins = const [],
    this.widthPx,
    this.heightPx,
  });

  final String title;
  final double titleSize;
  final HeroFigureConfig main;
  final HeroFigureConfig sub;

  /// Pin indices to sum. Empty means every lot currently on the map — adding
  /// a lot later is then included automatically rather than left out because
  /// it did not exist when this was configured.
  final List<int> includedPins;

  /// Pixel overrides for the card's box. Null keeps the built-in size.
  final double? widthPx;
  final double? heightPx;

  bool get isCustom => main.isSet || sub.isSet;

  HeroCardConfig copyWith({
    String? title,
    double? titleSize,
    HeroFigureConfig? main,
    HeroFigureConfig? sub,
    List<int>? includedPins,
    double? Function()? widthPx,
    double? Function()? heightPx,
  }) =>
      HeroCardConfig(
        title: title ?? this.title,
        titleSize: titleSize ?? this.titleSize,
        main: main ?? this.main,
        sub: sub ?? this.sub,
        includedPins: includedPins ?? this.includedPins,
        widthPx: widthPx != null ? widthPx() : this.widthPx,
        heightPx: heightPx != null ? heightPx() : this.heightPx,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'titleSize': titleSize,
        'main': main.toJson(),
        'sub': sub.toJson(),
        'includedPins': includedPins,
        if (widthPx != null) 'widthPx': widthPx,
        if (heightPx != null) 'heightPx': heightPx,
      };

  static HeroCardConfig fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HeroCardConfig();
    return HeroCardConfig(
      title: json['title']?.toString() ?? '',
      titleSize: (json['titleSize'] as num?)?.toDouble() ?? 0,
      main: HeroFigureConfig.fromJson(json['main'] as Map<String, dynamic>?),
      sub: HeroFigureConfig.fromJson(json['sub'] as Map<String, dynamic>?),
      includedPins: (json['includedPins'] as List<dynamic>? ?? const [])
          .map((e) => e is num ? e.toInt() : int.tryParse(e.toString()))
          .whereType<int>()
          .toList(),
      widthPx: (json['widthPx'] as num?)?.toDouble(),
      heightPx: (json['heightPx'] as num?)?.toDouble(),
    );
  }

  /// One figure's total: the sum (or average / max, per the metric) of
  /// [figure]'s metric across whichever of [includedPins] are actually on the
  /// map. Averages divide by the lots that reported a reading, not every lot
  /// asked for — a lot with no reading contributes nothing rather than
  /// pulling the average toward zero. Reporting count is returned alongside
  /// so a caller can say "no lot reports this yet" rather than drawing 0.
  static ({double amount, int reporting}) resolveFigure(
    PeccLiveData live,
    List<int> pinOrder,
    HeroFigureConfig figure,
    List<int> includedPins,
  ) {
    if (!figure.isSet) return (amount: 0, reporting: 0);
    final targets =
        includedPins.isEmpty ? pinOrder : includedPins.where(pinOrder.contains).toList();
    var sum = 0.0;
    var reporting = 0;
    for (final idx in targets) {
      final pin = live.pinsByIndex[idx];
      if (pin == null) continue;
      double v;
      switch (figure.metricKey) {
        case 'cost':
          v = pin.costRm;
          break;
        case 'energy':
          v = pin.energyKwh;
          break;
        default:
          v = 0;
          for (final m in pin.metrics) {
            if (m.metricKey == figure.metricKey) {
              v = m.amount;
              break;
            }
          }
      }
      if (v > 0) {
        sum += v;
        reporting++;
      }
    }
    if (reporting == 0) return (amount: 0, reporting: 0);
    final agg = heroMetrics[figure.metricKey]?.agg ?? 'sum';
    return (amount: agg == 'avg' ? sum / reporting : sum, reporting: reporting);
  }
}

// ── Per-card text styling ──────────────────────────────────────────────────
//
// The hero card above lets someone choose WHAT a card shows. Most cards on
// the per-factory dashboards already know what they show — a Grid Import
// card reads the grid meter and always will — what varies is how big the
// label and figure are drawn and what colour they take. This is that
// narrower, much smaller knob, meant to cover any card on any dashboard the
// same way: one style per card key, so adding it to a new card is reading
// [CardStyleSet.of] with that card's own key rather than a new setting.
class CardTextStyle {
  const CardTextStyle({
    this.labelSize = 0,
    this.labelColorKey = '',
    this.valueSize = 0,
    this.valueColorKey = '',
  });

  /// 0 keeps the card's own built-in size.
  final double labelSize;

  /// A key into [heroColors]. Empty keeps the card's own built-in colour.
  final String labelColorKey;
  final double valueSize;
  final String valueColorKey;

  bool get isSet =>
      labelSize > 0 ||
      labelColorKey.isNotEmpty ||
      valueSize > 0 ||
      valueColorKey.isNotEmpty;

  CardTextStyle copyWith({
    double? labelSize,
    String? labelColorKey,
    double? valueSize,
    String? valueColorKey,
  }) =>
      CardTextStyle(
        labelSize: labelSize ?? this.labelSize,
        labelColorKey: labelColorKey ?? this.labelColorKey,
        valueSize: valueSize ?? this.valueSize,
        valueColorKey: valueColorKey ?? this.valueColorKey,
      );

  Map<String, dynamic> toJson() => {
        'labelSize': labelSize,
        'labelColorKey': labelColorKey,
        'valueSize': valueSize,
        'valueColorKey': valueColorKey,
      };

  static CardTextStyle fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CardTextStyle();
    return CardTextStyle(
      labelSize: (json['labelSize'] as num?)?.toDouble() ?? 0,
      labelColorKey: json['labelColorKey']?.toString() ?? '',
      valueSize: (json['valueSize'] as num?)?.toDouble() ?? 0,
      valueColorKey: json['valueColorKey']?.toString() ?? '',
    );
  }
}

/// Every card's style on one dashboard, keyed by the same card key the
/// dashboard already uses for its label (e.g. `hero[0]`) — one saved map,
/// so a new card only needs its own key, never a new field in this class.
class CardStyleSet {
  const CardStyleSet(this.byKey);

  final Map<String, CardTextStyle> byKey;

  static const empty = CardStyleSet({});

  CardTextStyle of(String key) => byKey[key] ?? const CardTextStyle();

  CardStyleSet withStyle(String key, CardTextStyle style) =>
      CardStyleSet({...byKey, key: style});

  Map<String, dynamic> toJson() =>
      {for (final e in byKey.entries) e.key: e.value.toJson()};

  static CardStyleSet fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty;
    return CardStyleSet({
      for (final e in json.entries)
        if (e.value is Map)
          e.key: CardTextStyle.fromJson((e.value as Map).cast<String, dynamic>()),
    });
  }
}
