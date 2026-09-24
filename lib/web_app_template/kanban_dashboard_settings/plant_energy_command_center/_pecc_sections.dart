part of 'plant_energy_command_center_setting_widget.dart';

// ── Section initialisation data ────────────────────────────────────────────────
// Called once from initState(). Each _WidgetMapping defines one card on the
// live Kanban dashboard. Calculated entries auto-resolve at runtime; all others
// must have a Device + Field selected before the config can be published.

extension _PeccSections on _PlantEnergyCommandCenterSettingWidgetState {
  static const _power = [
    'Total Energy (kWh)',
    'Active Power (kW)',
    'Max Demand 30-min (kW)',
    'Power Factor (%)',
    'Reactive Power (kVAR)',
    'Current (A)',
    'Voltage (V)',
  ];

  static const _solar = [
    'Energy Saving (RM, calc.)',
    'Daily Generation (kWh)',
    'Lifetime Generation (kWh)',
    'Current Power (kW)',
  ];

  /// A production block inside Lot 237 — Block A, B or C.
  ///
  /// All three get the same screen. The layout was written for Block B, but
  /// nothing in it is about Block B: the machine rows ship as "Top Consumer
  /// #1..#6" and every real name, device and meter group comes from the saved
  /// configuration, which is keyed per plant. So one setting page serves every
  /// block, and setting up another block is a matter of pointing its filters
  /// at that block's meters.
  ///
  /// Blocks only. Lot 237 as a whole keeps its own layout — an earlier attempt
  /// to standardise those two rendered Block B's screen against keys Lot 237
  /// does not have and came up empty.
  bool get _isLot237BlockScope {
    final lower = _eccIdentity.toLowerCase().trim();
    // Written the long way because the saved plant names are inconsistent:
    // "Lot 237 Block B" in the facility master, "block b" in older configs.
    for (final block in const ['a', 'b', 'c']) {
      if (lower == 'lot 237 block $block' ||
          lower == 'lot237block$block' ||
          lower == 'lot 237 - block $block' ||
          lower == 'block $block') {
        return true;
      }
    }
    return false;
  }

  bool get _isLot48Scope {
    final name = _eccIdentity;
    return name.toLowerCase() == 'lot 48';
  }

  // Any specific factory's own settings, as opposed to the group/"All
  // plants" view — a non-empty identity always means one factory, whether
  // that's Lot 237, Lot 48, a Lot 237 block, or any other real plant.
  bool get _isPerFactoryScope => _eccIdentity.trim().isNotEmpty;

  /// Any real, specific plant other than Lot 48 or a Lot 237 block — the same
  /// rule pecc_data_service.dart's resolve() uses to decide which plants read
  /// the flexi hero[0]/flow.*/sidebar[]/chart.* keys. The settings page has to
  /// agree with that rule, or a plant whose saved doc actually has those keys
  /// (auto-provisioned or hand-built) still shows the wrong editor — the old
  /// group/cost_drivers layout — because nothing here knew to expect them.
  bool get _isFlexiPlantScope =>
      _eccIdentity.trim().isNotEmpty && !_isLot48Scope && !_isLot237BlockScope;

  /// Which centres show the meter-group data setup (STEP 1 Meter Groups +
  /// STEP 2 Dashboard Panels) on their SETTINGS page.
  ///
  /// This gates the settings UI only — it does not touch [_reinitSections] or
  /// the dashboard viewer, so a centre keeps its own widget mappings and its
  /// own dashboard. An earlier attempt standardised the layout itself, which
  /// made Lot 237 render Block B's screen against keys it does not have and
  /// come up empty; the two dashboards are different and stay that way.
  bool get _usesMeterGroupLayout => _isLot237BlockScope || _isFlexiPlantScope;

  void _reinitSections() {
    if (_isLot237BlockScope) {
      _initLot237BlockBSections();
    } else if (_isLot48Scope) {
      _initLot48Sections();
    } else if (_isFlexiPlantScope) {
      // Lot 237 itself, and every other real plant (including one that was
      // just auto-provisioned) — same editor, same key vocabulary. Only the
      // group/"All plants" view (empty identity) still gets its own layout.
      _initLot237Sections();
    } else {
      _initGroupSections();
    }
  }

  void _initSections() => _reinitSections();

  void _initGroupSections() {
    // ── 6 visible pins — DB has 8 (pin[0-7]) but we skip:
    //    pin[3] = Cost Driver 4 — "Others"  (removed)
    //    pin[7] = LOT 237C                  (removed)
    _pins = [
      _PinMapping(key: 'pin[0]', pinIndex: 0, defaultLabel: 'Cost Driver 1'),
      _PinMapping(key: 'pin[1]', pinIndex: 1, defaultLabel: 'Cost Driver 2'),
      _PinMapping(key: 'pin[2]', pinIndex: 2, defaultLabel: 'Cost Driver 3'),
      _PinMapping(key: 'pin[4]', pinIndex: 4, defaultLabel: 'LOT 53A'),
      _PinMapping(key: 'pin[5]', pinIndex: 5, defaultLabel: 'LOT 53B'),
      _PinMapping(key: 'pin[6]', pinIndex: 6, defaultLabel: 'LOT 237', isCurrentSite: true),
    ];

    _sections = [
      // ── Hero Summary ──────────────────────────────────────────────────────
      _Section(
        title: 'Hero Summary (Top Banner)',
        subtitle: 'Total Energy Cost, Total Energy, Solar Saving, Specific Cost',
        icon: Icons.monetization_on_outlined,
        iconBg: const Color(0x1A22D3EE),
        iconColor: const Color(0xFF22D3EE),
        widgets: [
          _WidgetMapping(
            key: 'hero.total_cost',
            label: 'Total Energy Cost (MTD)',
            locationKey: 'hero.total_cost',
            icon: Icons.attach_money,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'RM',
            isCalculated: true,
            calculatedLabel: '— Calculated (sum of cost drivers) —',
          ),
          _WidgetMapping(
            key: 'hero.total_energy',
            label: 'Total Energy',
            locationKey: 'hero.total_energy',
            icon: Icons.bolt,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'MWh',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'hero.solar_saving',
            label: 'Solar Saving',
            locationKey: 'hero.solar_saving',
            icon: Icons.eco_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'RM',
            availableFields: _solar,
          ),
          _WidgetMapping(
            key: 'hero.specific_cost',
            label: 'Specific Cost',
            locationKey: 'hero.specific_cost',
            icon: Icons.calculate_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'RM/MWh',
            isCalculated: true,
            calculatedLabel: '— Calculated (Total Cost ÷ Total Energy) —',
          ),
        ],
      ),

      // ── Cost Drivers ──────────────────────────────────────────────────────
      // Note: Kept in _sections list so it saves/loads automatically,
      // but hidden from the normal sections rendering list.
      _Section(
        title: 'Cost Drivers (Left Panel)',
        subtitle: 'Up to 4 cards — each maps to one metered circuit or device',
        icon: Icons.factory_outlined,
        iconBg: const Color(0x1A4F9EFF),
        iconColor: const Color(0xFF4F9EFF),
        widgets: [
          _WidgetMapping(
            key: 'cost_drivers[0]',
            label: 'Cost Driver 1',
            locationKey: 'cost_drivers[0]',
            icon: Icons.factory_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'RM',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'cost_drivers[1]',
            label: 'Cost Driver 2',
            locationKey: 'cost_drivers[1]',
            icon: Icons.ac_unit_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'RM',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'cost_drivers[2]',
            label: 'Cost Driver 3',
            locationKey: 'cost_drivers[2]',
            icon: Icons.compress_outlined,
            iconBg: const Color(0x1AFB923C),
            iconColor: const Color(0xFFFB923C),
            unit: 'RM',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'cost_drivers[3]',
            label: 'Cost Driver 4 — "Others"',
            locationKey: 'cost_drivers[3]',
            icon: Icons.more_horiz,
            iconBg: const Color(0x1AA78BFA),
            iconColor: const Color(0xFFA78BFA),
            unit: 'RM',
            isCalculated: true,
            calculatedLabel: '— Calculated (Remainder) —',
          ),
        ],
      ),

      // ── Plant Performance ─────────────────────────────────────────────────
      _Section(
        title: 'Plant Performance (Right Panel)',
        subtitle: 'Energy Intensity, Solar Coverage, Carbon Emission, Max Demand, MD Charges',
        icon: Icons.insights_outlined,
        iconBg: const Color(0x1AA78BFA),
        iconColor: const Color(0xFFA78BFA),
        widgets: [
          _WidgetMapping(
            key: 'performance[0]',
            label: 'Energy Intensity',
            locationKey: 'performance[0]',
            icon: Icons.track_changes_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'RM/MWh',
            isCalculated: true,
            calculatedLabel: '— Calculated (Total Cost ÷ Total Energy) —',
          ),
          _WidgetMapping(
            key: 'performance[1]',
            label: 'Solar Coverage',
            locationKey: 'performance[1]',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: '%',
            isCalculated: true,
            calculatedLabel: '— Calculated (Solar ÷ Total Energy) —',
          ),
          _WidgetMapping(
            key: 'performance[2]',
            label: 'Carbon Emission',
            locationKey: 'performance[2]',
            icon: Icons.cloud_outlined,
            iconBg: const Color(0x1AA78BFA),
            iconColor: const Color(0xFFA78BFA),
            unit: 'tCO₂e',
            isCalculated: true,
            calculatedLabel: '— Calculated (Emission Factor × Energy) —',
          ),
          _WidgetMapping(
            key: 'performance[3]',
            label: 'Max Demand',
            locationKey: 'performance[3]',
            icon: Icons.speed_outlined,
            iconBg: const Color(0x1AFB923C),
            iconColor: const Color(0xFFFB923C),
            unit: 'kW',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'performance[4]',
            label: 'MD Charges (MTD)',
            locationKey: 'performance[4]',
            icon: Icons.bolt_outlined,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'RM',
            availableFields: _power,
          ),
        ],
      ),

      // ── Today at a Glance ─────────────────────────────────────────────────
      _Section(
        title: 'Today at a Glance (Bottom Row)',
        subtitle: '5 daily summary metrics shown below the chart',
        icon: Icons.today_outlined,
        iconBg: const Color(0x1AFBBF24),
        iconColor: const Color(0xFFFBBF24),
        widgets: [
          _WidgetMapping(
            key: 'glance[0]',
            label: 'Energy Today',
            locationKey: 'glance[0]',
            icon: Icons.bolt,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'glance[1]',
            label: 'Energy Cost Today',
            locationKey: 'glance[1]',
            icon: Icons.monetization_on_outlined,
            iconBg: const Color(0x1AA78BFA),
            iconColor: const Color(0xFFA78BFA),
            unit: 'RM',
            isCalculated: true,
            calculatedLabel: '— Calculated (Energy Today × Tariff) —',
          ),
          _WidgetMapping(
            key: 'glance[2]',
            label: 'Solar Generated',
            locationKey: 'glance[2]',
            icon: Icons.eco_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _solar,
          ),
          _WidgetMapping(
            key: 'glance[3]',
            label: 'Solar Contribution',
            locationKey: 'glance[3]',
            icon: Icons.percent,
            iconBg: const Color(0x1AFB923C),
            iconColor: const Color(0xFFFB923C),
            unit: '%',
            isCalculated: true,
            calculatedLabel: '— Calculated (Solar ÷ Total Energy Today) —',
          ),
          _WidgetMapping(
            key: 'glance[4]',
            label: 'Carbon Today',
            locationKey: 'glance[4]',
            icon: Icons.cloud_outlined,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'tCO₂e',
            isCalculated: true,
            calculatedLabel: '— Calculated (Emission Factor × Energy Today) —',
          ),
        ],
      ),
      // ── Data Config Setting ───────────────────────────────────────────────
      _Section(
        title: 'Data Config Setting',
        subtitle: 'Map each KPI to a device field — Energy cost, Energy consumption, Max demand, PF, MD charges, Carbon emission',
        icon: Icons.tune_outlined,
        iconBg: const Color(0x1A22D3EE),
        iconColor: const Color(0xFF22D3EE),
        widgets: [
          _WidgetMapping(
            key: 'data_config.energy_cost',
            label: 'Energy cost',
            locationKey: 'data_config.energy_cost',
            icon: Icons.attach_money,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'RM',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'data_config.energy_consumption',
            label: 'Energy consumption',
            locationKey: 'data_config.energy_consumption',
            icon: Icons.bolt,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'data_config.max_demand',
            label: 'Max demand',
            locationKey: 'data_config.max_demand',
            icon: Icons.speed_outlined,
            iconBg: const Color(0x1AFB923C),
            iconColor: const Color(0xFFFB923C),
            unit: 'kW',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'data_config.pf',
            label: 'PF',
            locationKey: 'data_config.pf',
            icon: Icons.electric_bolt_outlined,
            iconBg: const Color(0x1AFBBF24),
            iconColor: const Color(0xFFFBBF24),
            unit: '',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'data_config.md_charges',
            label: 'MD charges',
            locationKey: 'data_config.md_charges',
            icon: Icons.receipt_long_outlined,
            iconBg: const Color(0x1AA78BFA),
            iconColor: const Color(0xFFA78BFA),
            unit: 'RM',
            availableFields: _power,
          ),
          _WidgetMapping(
            key: 'data_config.carbon_emission',
            label: 'Carbon emission',
            locationKey: 'data_config.carbon_emission',
            icon: Icons.cloud_outlined,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'tCO₂e',
            isCalculated: true,
            calculatedLabel: '— Calculated (Emission Factor × Energy) —',
          ),
        ],
      ),
    ];
  }
}
