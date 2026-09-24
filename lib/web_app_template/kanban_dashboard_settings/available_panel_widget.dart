import 'package:flutter/material.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';

// ─── Registry: add new widget types here ─────────────────────────────────────
class WidgetCatalogItem {
  final String widgetType;
  final String displayName;
  final String description;
  final IconData icon;

  const WidgetCatalogItem({
    required this.widgetType,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}

const List<WidgetCatalogItem> kAvailableWidgets = [
  WidgetCatalogItem(
    widgetType: 'EQUIPMENT_MD_RANKING',
    displayName: 'Equipment MD Ranking',
    description: 'Displays max demand ranking chart by equipment.',
    icon: Icons.bar_chart_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'DAILY_CHART',
    displayName: 'Daily Chart',
    description: 'Insight to daily energy consumption.',
    icon: Icons.today_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'HOURLY_CHART',
    displayName: 'Hourly Chart',
    description: 'Insight to hourly energy consumption.',
    icon: Icons.access_time_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'MONTHLY_CHART',
    displayName: 'Monthly Chart',
    description: 'Insight to monthly energy consumption.',
    icon: Icons.calendar_month_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'YEAR_OVER_YEAR_CHART',
    displayName: 'Year-over-Year Chart',
    description: 'Insight to year-over-year energy consumption.',
    icon: Icons.compare_arrows_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'LAST_24_HOURS_POWER_LOAD',
    displayName: 'Last 24 Hours Power Load',
    description: 'Insight to power load for the last 24 hours.',
    icon: Icons.electric_bolt_rounded,
  ),
  WidgetCatalogItem(
    widgetType: '24_HOURS_POWER_LOAD_TREND',
    displayName: '24 Hours Power Load Trend',
    description: 'Insight to power load trend for the last 24 hours.',
    icon: Icons.trending_up_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'DAILY_MAX_DEMAND_THIS_MONTH',
    displayName: 'Daily Max Demand This Month',
    description: 'Insight to daily max demand for this month.',
    icon: Icons.speed_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'POWER_LOAD_DISTRIBUTION_TODAY',
    displayName: 'Power Load Distribution Today',
    description: 'Insight to power load distribution for today.',
    icon: Icons.donut_large_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'YEAR_ON_YEAR_ANALYSIS',
    displayName: 'Year-on-Year Analysis',
    description: 'Insight to year-on-year analysis (Last year vs This year).',
    icon: Icons.analytics_rounded,
  ),
  WidgetCatalogItem(
    widgetType: 'EQUIPMENT_LOAD_CORRELATION',
    displayName: 'Equipment Load Correlation',
    description: 'Insight to equipment load correlation (Peak Window Focus).',
    icon: Icons.device_hub_rounded,
  ),
];

// ─── Panel ────────────────────────────────────────────────────────────────────
class AvailablePanelWidget extends StatefulWidget {
  const AvailablePanelWidget({super.key});

  @override
  State<AvailablePanelWidget> createState() => _AvailablePanelWidgetState();
}

class _AvailablePanelWidgetState extends State<AvailablePanelWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WidgetCatalogItem> get _filtered => kAvailableWidgets
      .where((w) =>
          w.displayName.toLowerCase().contains(_query) || w.description.toLowerCase().contains(_query) || w.widgetType.toLowerCase().contains(_query))
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final filtered = _filtered;

    return LayoutBuilder(builder: (context, constraints) {
      final useFixedWidth = constraints.maxWidth > 300;
      return SizedBox(
        width: useFixedWidth ? 240 : double.infinity,
        height: 500,
        child: CardWidget(
          glowColor: theme.primary,
          blurSigma: 2,
          topPadMultiplier: 0.6,
          bottomPadMultiplier: 0.6,
          armLenMultiplier: 0.5,
          builder: (context, sizing) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.widgets_outlined, color: theme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Available Widgets',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${kAvailableWidgets.length} widget${kAvailableWidgets.length == 1 ? '' : 's'} available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 10),

              // ── Search ───────────────────────────────────────────────────────
              SizedBox(
                height: 34,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: theme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search widgets...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: theme.secondaryText,
                    ),
                    prefixIcon: Icon(Icons.search, size: 15, color: theme.secondaryText),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: Icon(Icons.close, size: 14, color: theme.secondaryText),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.primary.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Divider ──────────────────────────────────────────────────────
              Divider(color: theme.primary.withOpacity(0.2), height: 1),
              const SizedBox(height: 8),

              // ── Widget list (scrollable, fills remaining height) ─────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No widgets found',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: theme.secondaryText,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) => _WidgetCatalogTile(item: filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Individual tile ──────────────────────────────────────────────────────────
class _WidgetCatalogTile extends StatelessWidget {
  final WidgetCatalogItem item;
  const _WidgetCatalogTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(item.icon, color: theme.primary, size: 16),
          ),
          const SizedBox(width: 10),
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: theme.secondaryText,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.primary.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    item.widgetType,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      color: theme.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
