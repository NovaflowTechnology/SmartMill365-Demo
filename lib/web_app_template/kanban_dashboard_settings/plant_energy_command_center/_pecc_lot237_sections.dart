part of 'plant_energy_command_center_setting_widget.dart';

// Lot 237 Energy Command Center — widget keys match kanban_dashboard_setting_lot237_v3.html
// Energy Flow Diagram (flow.*) is preserved so Energy Flow tab data wiring stays intact.
extension _PeccLot237Sections on _PlantEnergyCommandCenterSettingWidgetState {
  static const _lotPower = [
    'Total Energy (kWh)',
    'Daily Energy (kWh)',
    'Active Power (kW)',
    'Max Demand 30-min (kW)',
    'Power Factor (%)',
    'Reactive Power (kVAR)',
    'Current (A)',
    'Voltage (V)',
  ];

  static const _lotSolar = [
    'Daily Generation (kWh)',
    'Current Power (kW)',
    'Lifetime Generation (kWh)',
    'Energy Saving (RM, calc.)',
  ];

  static const _lotGridMeta = [
    'Power Factor (%)',
    'Frequency (Hz)',
    'Active Power (kW)',
    'Daily Energy (kWh)',
    'Total Energy (kWh)',
  ];

  void _initLot237Sections() {
    _sections = [
      // ── Hero KPI Row (4-card banner — daily/monthly toggle on dashboard) ──
      _Section(
        title: 'Hero KPI Row',
        subtitle: 'Total Energy Consumption + Solar mapped; Cost & Carbon auto-calculated',
        icon: Icons.dashboard_outlined,
        iconBg: const Color(0x1A22D3EE),
        iconColor: const Color(0xFF22D3EE),
        widgets: [
          _WidgetMapping(
            key: 'hero[0]',
            label: 'Total Energy Consumption',
            locationKey: 'hero[0]',
            icon: Icons.bolt,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'hero[1]',
            label: 'Total Solar Generation',
            locationKey: 'hero[1]',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _lotSolar,
          ),
          _WidgetMapping(
            key: 'hero[3]',
            label: 'Total Energy Cost',
            locationKey: 'hero[3]',
            icon: Icons.attach_money,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'RM',
            isCalculated: true,
            calculatedLabel:
                '— Calculated (Grid Import peak/off-peak × TNB tariff; solar kWh not billed) —',
          ),
          _WidgetMapping(
            key: 'hero[4]',
            label: 'Total Carbon Emission',
            locationKey: 'hero[4]',
            icon: Icons.cloud_outlined,
            iconBg: const Color(0x1AA78BFA),
            iconColor: const Color(0xFFA78BFA),
            unit: 'tCO₂e',
            isCalculated: true,
            calculatedLabel:
                '— Calculated (Grid Import kWh × Emission Factor from Carbon settings) —',
          ),
        ],
      ),

      // The Plant Total Card section was removed. Its three keys —
      // plantCard.total / solarUsed / gridImport — were read by nothing: not
      // the data service, not the dashboard. The centre of the flow map takes
      // its figures from the Hero KPIs and the meter groups, so this asked for
      // three mappings that could never change what anyone saw.

      // ── Block A / B / C (Power Flow cards) ────────────────────────────────
      _Section(
        title: 'Block Cards — A / B / C (centre of the flow map)',
        subtitle:
            'The three BLOCK cards in the middle of the dashboard. Each needs '
            'three meters: Total Consumption, Grid Import and Solar Generation. '
            'Leave a block unmapped and its card reads — on the dashboard.',
        icon: Icons.factory_outlined,
        iconBg: const Color(0x1A4F9EFF),
        iconColor: const Color(0xFF4F9EFF),
        widgets: [
          for (final b in const [
            ('A', 'blockA'),
            ('B', 'blockB'),
            ('C', 'blockC'),
          ]) ...[
            _WidgetMapping(
              key: '${b.$2}.total',
              label: 'Block ${b.$1} — Total Consumption',
              locationKey: '${b.$2}.total',
              icon: Icons.factory_outlined,
              iconBg: const Color(0x1A4F9EFF),
              iconColor: const Color(0xFF4F9EFF),
              unit: 'kWh',
              availableFields: _lotPower,
            ),
            _WidgetMapping(
              key: '${b.$2}.gridImport',
              label: 'Block ${b.$1} — Grid Import',
              locationKey: '${b.$2}.gridImport',
              icon: Icons.electrical_services_outlined,
              iconBg: const Color(0x1A4F9EFF),
              iconColor: const Color(0xFF4F9EFF),
              unit: 'kWh',
              availableFields: _lotPower,
            ),
            _WidgetMapping(
              key: '${b.$2}.solar',
              label: 'Block ${b.$1} — Solar Generation',
              locationKey: '${b.$2}.solar',
              icon: Icons.wb_sunny_outlined,
              iconBg: const Color(0x1A34D399),
              iconColor: const Color(0xFF34D399),
              unit: 'kWh',
              availableFields: _lotSolar,
            ),
          ],
        ],
      ),

      // ── GRID (TNB) meter card ─────────────────────────────────────────────
      _Section(
        title: 'Grid (TNB) Meter Card',
        subtitle: 'TNB incomer meter — map kWh, Hz, and PF from VDPM002 (or plant grid meter)',
        icon: Icons.cell_tower,
        iconBg: const Color(0x1A4F9EFF),
        iconColor: const Color(0xFF4F9EFF),
        widgets: [
          _WidgetMapping(
            key: 'tnb.kwh',
            label: 'Grid Import (TNB)',
            locationKey: 'tnb.kwh',
            icon: Icons.cell_tower,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'tnb.freq',
            label: 'Grid Frequency',
            locationKey: 'tnb.freq',
            icon: Icons.wifi_tethering,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'Hz',
            availableFields: _lotGridMeta,
          ),
          _WidgetMapping(
            key: 'tnb.pf',
            label: 'Power Factor',
            locationKey: 'tnb.pf',
            icon: Icons.show_chart,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: '—',
            availableFields: _lotGridMeta,
          ),
        ],
      ),

      // ── Energy Flow Summary (right sidebar) ───────────────────────────────
      _Section(
        title: 'Energy Flow Summary (Right Sidebar)',
        subtitle: 'Reuses Hero KPIs · % of Total Consumption',
        icon: Icons.list_alt_outlined,
        iconBg: const Color(0x1A34D399),
        iconColor: const Color(0xFF34D399),
        widgets: [
          _WidgetMapping(
            key: 'flowSummary[0]',
            label: 'Solar Generation',
            locationKey: 'flowSummary[0]',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Reuses hero[1] · % = Solar ÷ Total Consumption —',
          ),
          _WidgetMapping(
            key: 'flowSummary[1]',
            label: 'Solar Used (Total)',
            locationKey: 'flowSummary[1]',
            icon: Icons.eco_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel:
                '— Same as Solar Generation (assumes zero curtailment/export today) —',
          ),
          _WidgetMapping(
            key: 'flowSummary[2]',
            label: 'Grid Import (Total)',
            locationKey: 'flowSummary[2]',
            icon: Icons.electrical_services_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Reuses hero[0] · % = Grid ÷ Total Consumption —',
          ),
          _WidgetMapping(
            key: 'flowSummary[3]',
            label: 'Total Consumption',
            locationKey: 'flowSummary[3]',
            icon: Icons.bolt,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Calculated (Grid + Solar) · always 100% —',
          ),
        ],
      ),

      // ── Energy Mix donut ──────────────────────────────────────────────────
      _Section(
        title: 'Energy Mix Donut',
        subtitle: 'Center total + Solar / Grid slices (reuse heroes)',
        icon: Icons.pie_chart_outline,
        iconBg: const Color(0x1AA78BFA),
        iconColor: const Color(0xFFA78BFA),
        widgets: [
          _WidgetMapping(
            key: 'donut.center',
            label: 'Donut Center Total',
            locationKey: 'donut.center',
            icon: Icons.pie_chart,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Calculated (Grid + Solar) —',
          ),
          _WidgetMapping(
            key: 'donut.solar',
            label: 'Solar Used slice',
            locationKey: 'donut.solar',
            icon: Icons.circle,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Reuses hero[1] · slice % = Solar ÷ Total —',
          ),
          _WidgetMapping(
            key: 'donut.grid',
            label: 'Grid Import slice',
            locationKey: 'donut.grid',
            icon: Icons.circle,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Reuses hero[0] · slice % = Grid ÷ Total —',
          ),
        ],
      ),

      // ── Bottom charts (Power Flow) ────────────────────────────────────────
      _Section(
        title: 'Bottom Charts',
        subtitle: 'Real-Time Trend, Consumption by Block, Timestamp',
        icon: Icons.bar_chart,
        iconBg: const Color(0x1A4F9EFF),
        iconColor: const Color(0xFF4F9EFF),
        widgets: [
          _WidgetMapping(
            key: 'trend.total',
            label: 'Real-Time Trend — Total Consumption (grid + solar)',
            locationKey: 'trend.total',
            icon: Icons.show_chart,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel:
                '— Calculated (Grid Import + Solar Generation, per interval) —',
          ),
          _WidgetMapping(
            key: 'trend.grid',
            label: 'Real-Time Trend — Grid Import',
            locationKey: 'trend.grid',
            icon: Icons.show_chart,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'trend.solar',
            label: 'Real-Time Trend — Solar Generation',
            locationKey: 'trend.solar',
            icon: Icons.show_chart,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _lotSolar,
          ),
          _WidgetMapping(
            key: 'chart.blockBars',
            label: 'Consumption by Block — bars',
            locationKey: 'chart.blockBars',
            icon: Icons.bar_chart,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel:
                '— Calculated (Block A/B/C totals, ranked desc, % = block ÷ plant total) —',
          ),
          _WidgetMapping(
            key: 'chart.timestamp',
            label: 'Timestamp / Last Updated',
            locationKey: 'chart.timestamp',
            icon: Icons.schedule,
            iconBg: const Color(0x1AA78BFA),
            iconColor: const Color(0xFFA78BFA),
            unit: '—',
            isCalculated: true,
            calculatedLabel: '— System clock / refresh timestamp —',
          ),
        ],
      ),

      // ── Key Insights (INS-01 … INS-04) ─────────────────────────────────────
      _Section(
        title: 'Key Insights (Today)',
        subtitle: 'Insight Rules Lot 237 — formulas, thresholds & edge cases',
        icon: Icons.tips_and_updates_outlined,
        iconBg: const Color(0x1AFB923C),
        iconColor: const Color(0xFFFB923C),
        widgets: [
          _WidgetMapping(
            key: 'insight[0]',
            label: 'INS-01 Solar Coverage',
            locationKey: 'insight[0]',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: '%',
            isCalculated: true,
            calculatedLabel:
                '— Ratio: solar_pct = Solar÷Total×100 · Total = Grid+Solar · show if Total≥500 kWh · skip if Total=0 · '
                'EN: "Solar is covering {solar_pct}% of total consumption" —',
          ),
          _WidgetMapping(
            key: 'insight[1]',
            label: 'INS-02 Highest Consuming Block',
            locationKey: 'insight[1]',
            icon: Icons.trending_up,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: '%',
            isCalculated: true,
            calculatedLabel:
                '— Ranking argmax(blockTotal÷plantTotal)×100 · show if Plant≥500 kWh · '
                'tie-break A→B→C · EN: "{block_name} has the highest energy consumption ({block_pct}%)" —',
          ),
          _WidgetMapping(
            key: 'insight[2]',
            label: 'INS-03 Most Grid-Dependent Block',
            locationKey: 'insight[2]',
            icon: Icons.electrical_services_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: '%',
            isCalculated: true,
            calculatedLabel:
                '— Ranking argmax(blockGrid÷blockTotal)×100 using block*.gridImport (direct-metered) · '
                'show if Plant≥500 kWh · suppress if all 100% grid · tie-break A→B→C · '
                'EN: "{block_name} is the most grid-dependent ({grid_dependency_pct}%)" —',
          ),
          _WidgetMapping(
            key: 'insight[3]',
            label: 'INS-04 Cost Change vs Yesterday',
            locationKey: 'insight[3]',
            icon: Icons.attach_money,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: '%',
            isCalculated: true,
            calculatedLabel:
                '— DoD: (CostToday÷CostYesterday−1)×100 · show only if |change|≥15% · '
                'skip if CostYesterday=0 · EN: "Energy cost {increased_or_decreased} by {cost_change_pct}% compared to yesterday" —',
          ),
        ],
      ),

      // ── Energy Flow tab (UNCHANGED keys — do not remove) ──────────────────
      _Section(
        title: 'Energy Flow Diagram (3D)',
        subtitle:
            'Energy Flow tab only — Block A/B/C, Plant Total, Solar Plant (existing live wiring)',
        icon: Icons.account_tree_outlined,
        iconBg: const Color(0x1A22D3EE),
        iconColor: const Color(0xFF22D3EE),
        widgets: [
          _WidgetMapping(
            key: 'flow.blockA',
            label: 'Block A',
            locationKey: 'flow.blockA',
            icon: Icons.factory_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'flow.blockB',
            label: 'Block B',
            locationKey: 'flow.blockB',
            icon: Icons.factory_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'flow.blockC',
            label: 'Block C',
            locationKey: 'flow.blockC',
            icon: Icons.factory_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'flow.plantTotal',
            label: 'Plant Total',
            locationKey: 'flow.plantTotal',
            icon: Icons.summarize_outlined,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'kWh',
            availableFields: _lotPower,
          ),
          _WidgetMapping(
            key: 'flow.solar',
            label: 'Solar Plant',
            locationKey: 'flow.solar',
            icon: Icons.solar_power,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _lotSolar,
          ),
          _WidgetMapping(
            key: 'flow.gridTnb',
            label: 'Grid (TNB) — Position',
            locationKey: 'flow.gridTnb',
            icon: Icons.electrical_services_outlined,
            iconBg: const Color(0x1AEAB308),
            iconColor: const Color(0xFFEAB308),
            unit: '',
            isCalculated: true,
            calculatedLabel:
                'Value comes from the Grid (TNB) Meter Card above — this only moves where its card sits on the Power Flow diagram.',
          ),
        ],
      ),
    ];
  }
}
