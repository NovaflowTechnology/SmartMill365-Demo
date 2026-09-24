part of 'plant_energy_command_center_setting_widget.dart';

// Lot 237 B — Meter Groups + Dashboard Panels
// Mirrors lot237_dashboard_v6.html STEP 1 / STEP 3 panel config.

extension _PeccLot237BlockBFilters on _PlantEnergyCommandCenterSettingWidgetState {
  static const _summaryMetrics = <(String, String, String)>[
    ('totalConsumption', 'Total Consumption', 'kWh'),
    ('currentDemand', 'Current Demand', 'kW'),
    ('peakDemand', 'Peak Demand', 'kW'),
    ('estimatedEOD', 'Estimated EOD', 'kWh'),
    ('avgPF', 'Average PF', ''),
    ('totalCurrent', 'Total Current', 'A'),
    ('carbonTotal', 'Carbon Total', 'kgCO₂e'),
    ('deviceCount', 'Device Count', 'units'),
  ];

  static const _flowSummaryMetrics = <(String, String, String)>[
    ('solarGeneration', 'Solar Generation', 'kWh'),
    ('solarUsed', 'Solar Used (Total)', 'kWh'),
    ('gridImport', 'Grid Import (Total)', 'kWh'),
    ('totalConsumption', 'Total Consumption', 'kWh'),
  ];

  static const _plantHealthMetrics = <(String, String, String)>[
    ('currentLoad', 'Current Load', 'kWh'),
    ('maxDemand', 'Max Demand (MD)', 'kW'),
    ('powerFactor', 'Power Factor', ''),
    ('solarContribution', 'Solar Contribution', '%'),
  ];

  static const _flowMapMetrics = <(String, String, String)>[
    ('plantTotal', 'Plant Total node', 'kWh'),
    ('blockA', 'Block A node', 'kWh'),
    ('blockB', 'Block B node', 'kWh'),
    ('blockC', 'Block C node', 'kWh'),
    ('solar', 'Solar node', 'kWh'),
  ];

  static const _blockCardMetrics = <(String, String, String)>[
    ('blockTotal', 'Total Consumption', 'kWh'),
    ('blockGridImport', 'Grid Import', 'kWh'),
    ('blockSolar', 'Solar Generation', 'kWh'),
  ];

  List<(String, String, String)> _metricsCatalogFor(_FoCardFilter c) {
    switch (c.key) {
      case 'flowSummary':
        return _flowSummaryMetrics;
      case 'plantHealth':
        return _plantHealthMetrics;
      case 'flowMap':
        return _flowMapMetrics;
      case 'blockCards':
        return _blockCardMetrics;
      default:
        return _summaryMetrics;
    }
  }

  List<_FoDeviceGroup> _defaultFoGroups() {
    final ids = _foDeviceIds();
    final prod = ids.take(math.min(18, ids.length)).toList();
    final util = ids.length > 18
        ? ids.sublist(18, math.min(28, ids.length))
        : <String>[];
    return [
      _FoDeviceGroup(id: 'g_all', name: 'All Meters', members: List.of(ids)),
      _FoDeviceGroup(id: 'g_prod', name: 'Production Meters', members: prod),
      _FoDeviceGroup(id: 'g_util', name: 'Utility Meters', members: util),
    ];
  }

  List<_FoCardFilter> _defaultFoCards() => [
        _FoCardFilter(
          key: 'summary',
          title: 'Left Panel — Energy Summary',
          subtitle:
              'Numbers on the left Energy Summary card. Total Consumption & Current Demand = SUM of meters below. Peak Demand = highest single meter.',
          kind: 'metrics',
          metrics: const [
            'totalConsumption',
            'currentDemand',
            'peakDemand',
            'estimatedEOD',
          ],
        ),
        _FoCardFilter(
          key: 'forecast',
          title: 'Left Panel — Demand Forecast',
          subtitle: '24h load curve from selected meters (Expected Peak = highest hour).',
          kind: 'fields',
          fields: const ['expectedPeak', 'peakWindow'],
        ),
        _FoCardFilter(
          key: 'cost',
          title: 'Left Panel — Cost Estimation',
          subtitle: 'Estimated cost = tariff × SUM of energy (kWh) from meters below.',
          kind: 'fields',
          fields: const ['estimatedCost', 'previousPeriod', 'variance'],
        ),
        _FoCardFilter(
          key: 'consumers',
          title: 'Right Panel — Top Energy Consumers',
          subtitle:
              'Ranked by energy (kWh) — same metric as the pie chart. Use the same Meter Group as Energy Distribution to keep ranks aligned.',
          kind: 'rank',
          topN: 10,
        ),
        _FoCardFilter(
          key: 'distribution',
          title: 'Right Panel — Energy Distribution',
          subtitle:
              'Pie = each meter’s share of total energy (kWh). Use the same Meter Group as Top Consumers so #1 matches the largest slice.',
          kind: 'pie',
          legendN: 14,
        ),
      ];

  /// Lot 237's dashboard has no left panel: its aggregate panels are the two on
  /// the right (Energy Flow Summary, Energy Mix) and the three along the bottom.
  /// Listing Block B's left-panel cards here would offer settings for panels
  /// that do not exist on this dashboard.
  List<_FoCardFilter> _lot237Cards() => [
        // ── ENERGY FLOW tab ──────────────────────────────────────────────
        _FoCardFilter(
          key: 'plantHealth',
          title: 'Energy Flow · Left Panel — Plant Health',
          subtitle:
              'Current Load, Max Demand, Power Factor and Solar Contribution for the meters below.',
          kind: 'metrics',
          metrics: const ['currentLoad', 'maxDemand', 'powerFactor', 'solarContribution'],
        ),
        _FoCardFilter(
          key: 'flowMap',
          title: 'Energy Flow · Centre — Plant & Block Nodes',
          subtitle:
              'The PLANT TOTAL, BLOCK A/B/C and SOLAR nodes on the Energy Flow map. Each node is a SUM of its meters.',
          kind: 'metrics',
          metrics: const ['plantTotal', 'blockA', 'blockB', 'blockC', 'solar'],
        ),

        _FoCardFilter(
          key: 'alerts',
          title: 'Energy Flow · Right Panel — Alerts & Events',
          subtitle:
              "Which meters are watched for Current Alerts and Today's Events. "
              'Thresholds come from the alert rules, not from this panel.',
          kind: 'fields',
          fields: const ['critical', 'warning', 'info'],
        ),

        // ── POWER FLOW tab ───────────────────────────────────────────────
        _FoCardFilter(
          key: 'blockCards',
          title: 'Power Flow · Centre — Block A / B / C Cards',
          subtitle:
              'The three block cards with their Grid Import and Solar Generation split.',
          kind: 'metrics',
          metrics: const ['blockTotal', 'blockGridImport', 'blockSolar'],
        ),
        _FoCardFilter(
          key: 'flowSummary',
          title: 'Power Flow · Right Panel — Energy Flow Summary',
          subtitle:
              'Solar Generation, Solar Used, Grid Import and Total Consumption — each a SUM of the meters below.',
          kind: 'metrics',
          metrics: const [
            'solarGeneration',
            'solarUsed',
            'gridImport',
            'totalConsumption',
          ],
        ),
        _FoCardFilter(
          key: 'energyMix',
          title: 'Power Flow · Right Panel — Energy Mix',
          subtitle: 'Donut split of Solar Used against Grid Import for the meters below.',
          kind: 'pie',
          legendN: 2,
        ),
        _FoCardFilter(
          key: 'trend',
          title: 'Power Flow · Bottom — Real-Time Energy Trend',
          subtitle: '24h curve. Total, Grid and Solar lines are summed from the meters below.',
          kind: 'fields',
          fields: const ['total', 'grid', 'solar'],
        ),
        _FoCardFilter(
          key: 'insights',
          title: 'Power Flow · Bottom — Key Insights',
          subtitle:
              'Sentences derived from the meters below (solar coverage, highest block, grid dependency).',
          kind: 'fields',
          fields: const ['solarCoverage', 'highestBlock', 'gridDependency', 'costChange'],
        ),

        // ── shared by both tabs ──────────────────────────────────────────
        _FoCardFilter(
          key: 'blockChart',
          title: 'Both tabs · Bottom — Energy Consumption by Block',
          subtitle: 'One bar per block, ranked by energy (kWh). Shown on both tabs.',
          kind: 'rank',
          topN: 4,
        ),
      ];

  // Lot 237 itself, and every other real plant, get Lot 237's own card set —
  // only an actual Lot 237 block keeps the block-specific default.
  List<_FoCardFilter> _cardsForScope() =>
      _isFlexiPlantScope ? _lot237Cards() : _defaultFoCards();

  void _initFoFilters() {
    _foGroups = _defaultFoGroups();
    _foCards = _cardsForScope();
  }

  void _resetFoFilters() {
    _initFoFilters();
  }

  List<String> _foDeviceIds() {
    // Real devices only — Master Facility / energy devices / TNB tags — and
    // only those within the selected PRODUCTION AREA, so a device group offers
    // and enables just the meters in that area. Members already saved outside
    // the area stay in the group (they're rendered from g.members, not here).
    return List.of(_devicesInScope);
  }

  List<String> _resolveFoDevices(_FoCardFilter c) {
    _FoDeviceGroup? g;
    for (final x in _foGroups) {
      if (x.id == c.groupId) {
        g = x;
        break;
      }
    }
    g ??= _foGroups.isNotEmpty ? _foGroups.first : null;
    final ids = <String>{...(g?.members ?? const <String>[])};
    for (final id in c.include) {
      ids.add(id);
    }
    for (final id in c.exclude) {
      ids.remove(id);
    }
    // Narrow to the selected PRODUCTION AREA so a dashboard panel counts only
    // meters from that area. Meters with no area recorded are kept, so an
    // unclassified meter is never silently dropped from a panel's total. The
    // card's own include/exclude choices are untouched — this filters what the
    // panel counts, it does not rewrite the saved selection, so clearing the
    // area brings every previously chosen meter back.
    if (_selectedProductionArea.isNotEmpty) {
      ids.removeWhere((id) {
        final area = _deviceProductionAreas[id];
        return area != null && area.isNotEmpty && area != _selectedProductionArea;
      });
    }
    return ids.toList()..sort();
  }

  void _applyFoFiltersConfig(Map<String, dynamic> settings) {
    // Prefer top-level groups/cards (new API). Fall back to branding.factoryOverview
    // because the currently deployed Cloud Function only persists branding/sections/pins
    // (and may return empty groups:[] / cards:{} which must NOT shadow the nested copy).
    final branding = settings['branding'] is Map
        ? Map<String, dynamic>.from(settings['branding'] as Map)
        : <String, dynamic>{};
    final nested = branding['factoryOverview'] is Map
        ? Map<String, dynamic>.from(branding['factoryOverview'] as Map)
        : <String, dynamic>{};

    final topGroups = settings['groups'] as List<dynamic>?;
    final nestedGroups = nested['groups'] as List<dynamic>?;
    final groupsRaw = (topGroups != null && topGroups.isNotEmpty)
        ? topGroups
        : nestedGroups;
    if (groupsRaw != null && groupsRaw.isNotEmpty) {
      _foGroups = groupsRaw
          .whereType<Map>()
          .map((e) => _FoDeviceGroup.fromJson(Map<String, dynamic>.from(e)))
          .where((g) => g.id.isNotEmpty)
          .toList();
    }
    if (_foGroups.isEmpty) _foGroups = _defaultFoGroups();

    final topCards = settings['cards'] is Map
        ? Map<String, dynamic>.from(settings['cards'] as Map)
        : null;
    final nestedCards = nested['cards'] is Map
        ? Map<String, dynamic>.from(nested['cards'] as Map)
        : null;
    final cardsRaw =
        (topCards != null && topCards.isNotEmpty) ? topCards : nestedCards;
    if (_foCards.isEmpty) _foCards = _cardsForScope();
    if (cardsRaw != null && cardsRaw.isNotEmpty) {
      for (final card in _foCards) {
        final raw = cardsRaw[card.key];
        if (raw is Map) {
          card.applyJson(Map<String, dynamic>.from(raw));
        }
      }
    }
  }

  Map<String, dynamic> _foCardsPayload() => {
        for (final c in _foCards) c.key: c.toJson(),
      };

  List<Map<String, dynamic>> _foGroupsPayload() =>
      _foGroups.map((g) => g.toJson()).toList();

  // ── UI ─────────────────────────────────────────────────────────────────────

  Widget _buildFoFiltersSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x1A38C6E8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x5938C6E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_settingsPageTitle — choose which meters feed each panel.',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Step 1: create Meter Groups. Step 2: assign a group to each live panel '
                '(Energy Summary, Top Consumers, pie chart, …). Then Save Configuration. '
                'Open this command centre on the Kanban Dashboard to see live values.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFFB8D4E8), height: 1.45),
              ),
            ],
          ),
        ),
        _buildFoGroupsCard(context, theme),
        const SizedBox(height: 16),
        _buildFoCardFiltersGrid(context, theme),
      ],
    );
  }

  Widget _buildFoGroupsCard(BuildContext context, FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kCyber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('STEP 1',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF061018),
                        letterSpacing: 1)),
              ),
              const SizedBox(width: 10),
              Text('Meter Groups',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    final n = _foGroups.length + 1;
                    _foGroups.add(_FoDeviceGroup(
                      id: 'g_custom_$n',
                      name: 'Meter Group $n',
                      members: [],
                    ));
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add Meter Group',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'A Meter Group is a named list of meter IDs (e.g. DPM047). '
            'Each dashboard panel in Step 2 points to one group. '
            'Click a chip to remove a meter; use + to add.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: theme.txtTertiary, height: 1.45),
          ),
          const SizedBox(height: 14),
          if (_foGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _isLoadingDevices
                    ? 'Loading meters…'
                    : 'No meter groups yet — tap Add Meter Group, or Refresh to reload meters.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: theme.txtTertiary),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _foGroups.map((g) => _foGroupCard(theme, g)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _foGroupCard(FlutterFlowTheme theme, _FoDeviceGroup g) {
    final allIds = _foDeviceIds();
    final outside = allIds.where((id) => !g.members.contains(id)).toList();
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF132038), Color(0xFF0E1A2E)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCyber.withOpacity(0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: const Color(0xFF38C6E8)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: g.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                              ),
                              onChanged: (v) =>
                                  g.name = v.trim().isEmpty ? g.name : v.trim(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text('${g.members.length}',
                                style: GoogleFonts.shareTechMono(
                                    fontSize: 10, color: const Color(0xFF5F7797))),
                          ),
                          if (g.id != 'g_all')
                            IconButton(
                              icon: const Icon(Icons.close, size: 14, color: Color(0xFF8AA0BD)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () {
                                setState(() {
                                  _foGroups.removeWhere((x) => x.id == g.id);
                                  for (final c in _foCards) {
                                    if (c.groupId == g.id) c.groupId = 'g_all';
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0x80060E1A),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0x335A82B4)),
                        ),
                        child: allIds.isEmpty && g.members.isEmpty
                            ? Text(
                                _isLoadingDevices
                                    ? 'Loading devices…'
                                    : 'No devices found. Check Master Facility / Energy devices.',
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5, color: const Color(0xFF8AA0BD)),
                              )
                            : Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: [
                                  ...g.members.map((id) => InkWell(
                                        onTap: () => setState(() => g.members.remove(id)),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1F38C6E8),
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(
                                                color: const Color(0x5938C6E8)),
                                          ),
                                          child: Text(id,
                                              style: GoogleFonts.shareTechMono(
                                                  fontSize: 10,
                                                  color: const Color(0xFFA8E8F8))),
                                        ),
                                      )),
                                  if (outside.isNotEmpty)
                                    PopupMenuButton<String>(
                                      tooltip: 'Add device',
                                      onSelected: (id) => setState(() {
                                        if (!g.members.contains(id)) g.members.add(id);
                                      }),
                                      itemBuilder: (_) => outside
                                          .take(80)
                                          .map((id) =>
                                              PopupMenuItem(value: id, child: Text(id)))
                                          .toList(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: const Color(0x4D5A82B4)),
                                        ),
                                        child: Text('+ add',
                                            style: GoogleFonts.shareTechMono(
                                                fontSize: 10,
                                                color: const Color(0xFF5F7797))),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoCardFiltersGrid(BuildContext context, FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cyberCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kCyber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('STEP 2',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF061018),
                        letterSpacing: 1)),
              ),
              const SizedBox(width: 10),
              Text('Dashboard Panels',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Each live panel picks one Meter Group from Step 1. Optionally '
            'exclude/include individual meters. Save, then open this command '
            'centre to see the numbers.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: theme.txtTertiary, height: 1.45),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth > 1100 ? 3 : (box.maxWidth > 720 ? 2 : 1);
              return Wrap(
                spacing: 13,
                runSpacing: 13,
                children: _foCards
                    .map((c) => SizedBox(
                          width: cols == 1
                              ? box.maxWidth
                              : (box.maxWidth - 13 * (cols - 1)) / cols,
                          child: _foFilterCard(theme, c),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _foFilterCard(FlutterFlowTheme theme, _FoCardFilter c) {
    final resolved = _resolveFoDevices(c);
    final allIds = _foDeviceIds();
    _FoDeviceGroup? g;
    for (final x in _foGroups) {
      if (x.id == c.groupId) {
        g = x;
        break;
      }
    }
    g ??= _foGroups.isNotEmpty ? _foGroups.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xB308111E),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: kCyber.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.title,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(c.key,
                    style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF5F7797))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.subtitle,
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF5F7797), height: 1.4)),
          const SizedBox(height: 12),
          Text('METER GROUP',
              style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F7797))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _foGroups.any((x) => x.id == c.groupId) ? c.groupId : (_foGroups.isNotEmpty ? _foGroups.first.id : null),
            dropdownColor: const Color(0xFF0C1B30),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF0A1524),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: kCyber.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: kCyber.withOpacity(0.25)),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            items: _foGroups
                .map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text('${g.name} (${g.members.length} meters)'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                c.groupId = v;
                c.include = [];
                c.exclude = [];
              });
            },
          ),
          const SizedBox(height: 10),
          Text('METERS IN THIS PANEL',
              style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F7797))),
          const SizedBox(height: 2),
          Text(
              'Blue = counted. Click blue → red (exclude from this panel only). '
              'Grey = not in the group — click → green (force-include). '
              'Energy Summary totals SUM every counted meter.',
              style: GoogleFonts.poppins(
                  fontSize: 10, fontStyle: FontStyle.italic, color: const Color(0xFF5F7797), height: 1.35)),
          const SizedBox(height: 7),
          // Legend
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _foChipLegend(const Color(0xFFA8E8F8), 'Counted'),
              _foChipLegend(const Color(0xFFFFB3AD), 'Excluded'),
              _foChipLegend(const Color(0xFF9FF0C4), 'Force-included'),
              _foChipLegend(const Color(0xFF5F7797), 'Not in group'),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x80060E1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kCyber.withOpacity(0.18)),
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: allIds.map((id) {
                  final inGroup = g?.members.contains(id) ?? false;
                  final forced = c.include.contains(id);
                  final excl = c.exclude.contains(id);
                  Color bg;
                  Color border;
                  Color fg;
                  if (excl) {
                    bg = const Color(0x2EE5544B);
                    border = const Color(0x80E5544B);
                    fg = const Color(0xFFFFB3AD);
                  } else if (forced) {
                    bg = const Color(0x2E3EC77E);
                    border = const Color(0x803EC77E);
                    fg = const Color(0xFF9FF0C4);
                  } else if (inGroup) {
                    bg = const Color(0x1F38C6E8);
                    border = const Color(0x5938C6E8);
                    fg = const Color(0xFFA8E8F8);
                  } else {
                    bg = Colors.white.withOpacity(0.03);
                    border = const Color(0x335A82B4);
                    fg = const Color(0xFF5F7797);
                  }
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (inGroup) {
                          if (excl) {
                            c.exclude.remove(id);
                          } else {
                            c.exclude.add(id);
                          }
                        } else {
                          if (forced) {
                            c.include.remove(id);
                          } else {
                            c.include.add(id);
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: border),
                      ),
                      child: Text(id,
                          style: GoogleFonts.shareTechMono(fontSize: 10, color: fg)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
              'Using ${resolved.length} meter(s) for this panel'
              '${c.kind == 'metrics' || c.kind == 'fields' || c.kind == 'pie' ? ' — panel totals SUM these meters' : ' — ranked individually'}',
              style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF5F7797))),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 10),
          if (c.kind == 'metrics') ..._foMetricsBlock(c),
          if (c.kind == 'rank') ..._foRankBlock(c),
          if (c.kind == 'pie') ..._foPieBlock(c),
          if (c.kind == 'fields') ..._foFieldsBlock(c),
        ],
      ),
    );
  }

  Widget _foChipLegend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: c.withOpacity(0.35),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF5F7797))),
      ],
    );
  }

  List<Widget> _foMetricsBlock(_FoCardFilter c) {
    return [
      Text('METRIC ROWS',
          style: GoogleFonts.poppins(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5F7797))),
      const SizedBox(height: 7),
      ..._metricsCatalogFor(c).map((m) {
        final on = c.metrics.contains(m.$1);
        return InkWell(
          onTap: () => setState(() {
            if (on) {
              c.metrics.remove(m.$1);
            } else {
              c.metrics.add(m.$1);
            }
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: on ? const Color(0x1A38C6E8) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: on ? const Color(0x5938C6E8) : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? kCyber.withOpacity(0.25) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: on ? kCyber : Colors.white24),
                  ),
                  child: on
                      ? const Icon(Icons.check, size: 11, color: Color(0xFF38C6E8))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.$2,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                ),
                Text(m.$3.isEmpty ? '—' : m.$3,
                    style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF5F7797))),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 6),
      _foToggle('Show sparklines', c.showSpark, (v) => setState(() => c.showSpark = v)),
    ];
  }

  List<Widget> _foRankBlock(_FoCardFilter c) {
    return [
      Text('DISPLAY',
          style: GoogleFonts.poppins(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5F7797))),
      const SizedBox(height: 7),
      Row(
        children: [
          Text('TOP N',
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5F7797))),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: TextFormField(
              initialValue: '${c.topN}',
              keyboardType: TextInputType.number,
              style: GoogleFonts.shareTechMono(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF0A1524),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: kCyber.withOpacity(0.25)),
                ),
              ),
              onChanged: (v) {
                final n = int.tryParse(v) ?? c.topN;
                c.topN = n.clamp(1, 30);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _foToggle('Show bars', c.showBar, (v) => setState(() => c.showBar = v)),
    ];
  }

  List<Widget> _foPieBlock(_FoCardFilter c) {
    return [
      Text('DISPLAY',
          style: GoogleFonts.poppins(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5F7797))),
      const SizedBox(height: 7),
      Row(
        children: [
          Text('LEGEND ENTRIES',
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5F7797))),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: TextFormField(
              initialValue: '${c.legendN}',
              keyboardType: TextInputType.number,
              style: GoogleFonts.shareTechMono(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF0A1524),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: kCyber.withOpacity(0.25)),
                ),
              ),
              onChanged: (v) {
                final n = int.tryParse(v) ?? c.legendN;
                c.legendN = n.clamp(0, 30);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _foToggle('Show total banner', c.showTotal, (v) => setState(() => c.showTotal = v)),
      const SizedBox(height: 4),
      Text('Pie draws all resolved devices; legend lists the top N.',
          style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5F7797))),
    ];
  }

  List<Widget> _foFieldsBlock(_FoCardFilter c) {
    final catalog = c.key == 'alerts'
        ? const [
            ('critical', 'Critical'),
            ('warning', 'Warning'),
            ('info', 'Info'),
          ]
        : c.key == 'trend'
        ? const [
            ('total', 'Total line'),
            ('grid', 'Grid line'),
            ('solar', 'Solar line'),
          ]
        : c.key == 'insights'
        ? const [
            ('solarCoverage', 'Solar coverage'),
            ('highestBlock', 'Highest consuming block'),
            ('gridDependency', 'Most grid-dependent block'),
            ('costChange', 'Cost change vs yesterday'),
          ]
        : c.key == 'cost'
        ? const [
            ('estimatedCost', 'Estimated Cost'),
            ('previousPeriod', 'Previous Period'),
            ('variance', 'Variance %'),
          ]
        : const [
            ('expectedPeak', 'Expected Peak'),
            ('peakWindow', 'Peak Window'),
            ('confidence', 'Confidence'),
          ];
    return [
      Text('FIELDS',
          style: GoogleFonts.poppins(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5F7797))),
      const SizedBox(height: 7),
      ...catalog.map((f) {
        final on = c.fields.contains(f.$1);
        return InkWell(
          onTap: () => setState(() {
            if (on) {
              c.fields.remove(f.$1);
            } else {
              c.fields.add(f.$1);
            }
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: on ? const Color(0x1A38C6E8) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: on ? const Color(0x5938C6E8) : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(on ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16, color: on ? kCyber : Colors.white38),
                const SizedBox(width: 8),
                Text(f.$2, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        );
      }),
      if (c.key == 'forecast') ...[
        const SizedBox(height: 6),
        _foToggle('Show forecast chart', c.showChart, (v) => setState(() => c.showChart = v)),
      ],
      if (c.key == 'cost') ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: c.tariff.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.shareTechMono(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'TARIFF / kWh',
                  labelStyle: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5F7797)),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF0A1524),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (v) => c.tariff = double.tryParse(v) ?? c.tariff,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: c.currency,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'CURRENCY',
                  labelStyle: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5F7797)),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF0A1524),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (v) => c.currency = v.trim().isEmpty ? c.currency : v.trim(),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  Widget _foToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 18,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF1A6B86) : const Color(0xFF132036),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value ? const Color(0xFF38C6E8) : const Color(0xFF2A3F5C),
              ),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: value ? const Color(0xFF38C6E8) : const Color(0xFF8AA0BD),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
