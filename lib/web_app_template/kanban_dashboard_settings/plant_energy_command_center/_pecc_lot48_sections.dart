part of 'plant_energy_command_center_setting_widget.dart';

// Lot 48 Energy Command Center — single-block setup.
// All widget keys match the dashboard's live data resolution layer so existing
// PECC mappings from Lot 237 carry over where applicable.
extension _PeccLot48Sections on _PlantEnergyCommandCenterSettingWidgetState {
  // ── Shared field lists (local copies so this file is self-contained) ───────
  static const _l48Power = [
    'Total Energy (kWh)',
    'Active Power (kW)',
    'Max Demand 30-min (kW)',
    'Power Factor (%)',
    'Reactive Power (kVAR)',
    'Current (A)',
    'Voltage (V)',
  ];

  static const _l48Solar = [
    'Energy Saving (RM, calc.)',
    'Daily Generation (kWh)',
    'Lifetime Generation (kWh)',
    'Current Power (kW)',
  ];

  static const _l48GridMeta = [
    'Power Factor (%)',
    'Frequency (Hz)',
    'Active Power (kW)',
    'Daily Energy (kWh)',
    'Total Energy (kWh)',
  ];

  // ── Section initialiser ────────────────────────────────────────────────────
  void _initLot48Sections() {
    _sections = [
      // ── Hero KPI Row ──────────────────────────────────────────────────────
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
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'hero[1]',
            label: 'Total Solar Generation',
            locationKey: 'hero[1]',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _l48Solar,
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

      // ── Plant Total Card (Flow Diagram Center) ────────────────────────────
      _Section(
        title: 'Plant Total Card (Flow Diagram Center)',
        subtitle: 'Reuses Hero KPI mappings — map once, reuse everywhere',
        icon: Icons.summarize_outlined,
        iconBg: const Color(0x1A22D3EE),
        iconColor: const Color(0xFF22D3EE),
        widgets: [
          _WidgetMapping(
            key: 'plantCard.total',
            label: 'Total Consumption',
            locationKey: 'plantCard.total',
            icon: Icons.summarize_outlined,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Calculated (Grid + Solar) —',
          ),
          _WidgetMapping(
            key: 'plantCard.solarUsed',
            label: 'Solar Used',
            locationKey: 'plantCard.solarUsed',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Reuses hero[1] + % of Consumption —',
          ),
          _WidgetMapping(
            key: 'plantCard.gridImport',
            label: 'Grid Import',
            locationKey: 'plantCard.gridImport',
            icon: Icons.cell_tower,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            isCalculated: true,
            calculatedLabel: '— Reuses hero[0] Grid Import meter —',
          ),
        ],
      ),

      // ── Block Card (Single Block — Lot 48 uses only Block A) ──────────────
      _Section(
        title: 'Block Card — Lot 48 (Grid + Solar Split)',
        subtitle: 'Single Block Total / Grid Import / Solar from meters',
        icon: Icons.factory_outlined,
        iconBg: const Color(0x1A4F9EFF),
        iconColor: const Color(0xFF4F9EFF),
        widgets: [
          _WidgetMapping(
            key: 'blockA.total',
            label: 'Block A — Total Consumption',
            locationKey: 'blockA.total',
            icon: Icons.factory_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'blockA.gridImport',
            label: 'Block A — Grid Import',
            locationKey: 'blockA.gridImport',
            icon: Icons.electrical_services_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: 'kWh',
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'blockA.solar',
            label: 'Block A — Solar Generation',
            locationKey: 'blockA.solar',
            icon: Icons.wb_sunny_outlined,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _l48Solar,
          ),
        ],
      ),

      // ── Grid (TNB) Meter Card ─────────────────────────────────────────────
      _Section(
        title: 'Grid (TNB) Meter Card',
        subtitle: 'TNB incomer meter — map kWh, Hz, and PF from plant grid meter',
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
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'tnb.freq',
            label: 'Grid Frequency',
            locationKey: 'tnb.freq',
            icon: Icons.wifi_tethering,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'Hz',
            availableFields: _l48GridMeta,
          ),
          _WidgetMapping(
            key: 'tnb.pf',
            label: 'Power Factor',
            locationKey: 'tnb.pf',
            icon: Icons.show_chart,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: '—',
            availableFields: _l48GridMeta,
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

      // ── Energy Mix Donut ──────────────────────────────────────────────────
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

      // ── Bottom Charts ─────────────────────────────────────────────────────
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
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'trend.solar',
            label: 'Real-Time Trend — Solar Generation',
            locationKey: 'trend.solar',
            icon: Icons.show_chart,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _l48Solar,
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
                '— Calculated (Block total, % = block ÷ plant total) —',
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

      // ── Key Insights ──────────────────────────────────────────────────────
      _Section(
        title: 'Key Insights (Today)',
        subtitle: 'Insight Rules Lot 48 — formulas, thresholds & edge cases',
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
                '— Ratio: solar_pct = Solar÷Total×100 · Total = Grid+Solar · show if Total≥500 kWh —',
          ),
          _WidgetMapping(
            key: 'insight[1]',
            label: 'INS-02 Energy Consumption',
            locationKey: 'insight[1]',
            icon: Icons.trending_up,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: '%',
            isCalculated: true,
            calculatedLabel:
                '— Block energy consumption ratio (100% for single block) —',
          ),
          _WidgetMapping(
            key: 'insight[2]',
            label: 'INS-03 Grid Dependency',
            locationKey: 'insight[2]',
            icon: Icons.electrical_services_outlined,
            iconBg: const Color(0x1A4F9EFF),
            iconColor: const Color(0xFF4F9EFF),
            unit: '%',
            isCalculated: true,
            calculatedLabel:
                '— Grid import ratio = blockGrid÷blockTotal × 100 —',
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
                '— DoD: (CostToday÷CostYesterday−1)×100 · show only if |change|≥15% —',
          ),
        ],
      ),

      // ── Energy Flow Diagram (3D) — single block only ──────────────────────
      _Section(
        title: 'Energy Flow Diagram (3D)',
        subtitle: 'Energy Flow tab only — Block A, Plant Total, Solar Plant',
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
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'flow.plantTotal',
            label: 'Plant Total',
            locationKey: 'flow.plantTotal',
            icon: Icons.summarize_outlined,
            iconBg: const Color(0x1A22D3EE),
            iconColor: const Color(0xFF22D3EE),
            unit: 'kWh',
            availableFields: _l48Power,
          ),
          _WidgetMapping(
            key: 'flow.solar',
            label: 'Solar Plant',
            locationKey: 'flow.solar',
            icon: Icons.solar_power,
            iconBg: const Color(0x1A34D399),
            iconColor: const Color(0xFF34D399),
            unit: 'kWh',
            availableFields: _l48Solar,
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
