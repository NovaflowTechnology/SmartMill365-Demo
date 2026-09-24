import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

class EquipmentMdRankingChart extends StatefulWidget {
  final String title;
  final String selectedEventDate;
  final String selectedEventStart;
  final String selectedEventEnd;

  final List<Map<String, dynamic>> rankingData;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  // Opens the "Configure Charts" device-selection dialog. Optional — only
  // the standalone Max Demand Monitoring page wires this up; Kanban
  // Dashboard's live panel builder and settings preview builder render this
  // same chart without it, and simply get no gear icon.
  final VoidCallback? onConfigure;
  final void Function(String date, String start, String end) onDateChanged;

  const EquipmentMdRankingChart({
    super.key,
    required this.title,
    required this.selectedEventDate,
    required this.selectedEventStart,
    required this.selectedEventEnd,
    required this.rankingData,
    required this.isLoading,
    required this.onRefresh,
    this.onConfigure,
    required this.onDateChanged,
    this.errorMessage,
  });

  @override
  State<EquipmentMdRankingChart> createState() => _EquipmentMdRankingChartState();
}

class _EquipmentMdRankingChartState extends State<EquipmentMdRankingChart> {
  DateTime? _pickedDate;

  static const int _highlightCount = 2;
  static const Color _highlightColor = Color(0xFFEF5350);
  static const Color _defaultColor = Color(0xFF26C6DA);

  // ── Safe numeric read ──────────────────────────────────────────────────────
  double _pf(Map<String, dynamic> item) => ((item['power_factor_avg']) as num?)?.toDouble() ?? (item['peak_demand_kW'] as num).toDouble();

  double _pct(Map<String, dynamic> item) => (item['percentage'] as num?)?.toDouble() ?? 0.0;

  // ── Date helpers ───────────────────────────────────────────────────────────
  String _fmt(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _display(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _displayYmd(String ymd) {
    final dt = DateTime.tryParse(ymd);
    return dt == null ? ymd : _display(dt);
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _openDatePicker(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      builder: (ctx, child) {
        final isLt = Theme.of(ctx).brightness == Brightness.light;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isLt
                ? ColorScheme.light(primary: theme.primary, onPrimary: Colors.white)
                : ColorScheme.dark(
                    primary: theme.primary,
                    onPrimary: Colors.white,
                    surface: const Color.fromRGBO(0, 4, 51, 1),
                    onSurface: Colors.white,
                  ),
            dialogBackgroundColor: isLt ? Colors.white : const Color.fromRGBO(0, 4, 51, 1),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _pickedDate = picked);
      final date = _fmt(picked);
      widget.onDateChanged(date, '$date 00:00:00', '$date 23:59:59');
    }
  }

  void _clearDateFilter() {
    setState(() => _pickedDate = null);
    widget.onDateChanged('', '', '');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  // ── Card content ───────────────────────────────────────────────────────────
  // LayoutBuilder detects whether the parent gives us a bounded height.
  //   • Bounded  → Column fills the space; Expanded absorbs leftover height.
  //   • Unbounded → Column shrinks to content; chart gets a fixed fallback height.
  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool heightBounded = constraints.maxHeight.isFinite;

        // Fixed chart height used only when the parent is unbounded.
        const double fallbackChartHeight = 300.0;

        Widget chartBody = _buildChartContent(context, sizing);

        return Column(
          // Fill available height when bounded; shrink to content otherwise.
          mainAxisSize: heightBounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: sizing.accentW,
                            height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withOpacity(0.9),
                                  blurRadius: sizing.pad * 0.7,
                                  spreadRadius: sizing.accentW * 0.3,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: sizing.pad * 0.5),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${widget.title} (Peak Contribution)',
                                style: GoogleFonts.poppins(
                                  fontSize: sizing.titleFs.clamp(12.0, 16.0),
                                  fontWeight: FontWeight.w700,
                                  color: isLight ? theme.txtPrimary : Colors.white,
                                  letterSpacing: 0.6,
                                  shadows: isLight ? null : [
                                    Shadow(
                                      color: theme.primary.withOpacity(0.7),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (_pickedDate != null)
                        Text(
                          'Filtered: ${_display(_pickedDate!)}',
                          style: GoogleFonts.poppins(color: theme.primary, fontSize: sizing.bodyFs.clamp(9.0, 12.0)),
                        )
                      else if (widget.selectedEventDate.isNotEmpty)
                        Text(
                          'Event: ${_displayYmd(widget.selectedEventDate)}',
                          style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 12.0)),
                        ),
                    ],
                  ),
                ),
                if (widget.onConfigure != null)
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: theme.secondaryText, size: 20),
                    onPressed: widget.onConfigure,
                    tooltip: 'Configure equipment shown',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (widget.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, color: theme.secondaryText, size: 20),
                    onPressed: widget.onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Date picker row ──────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openDatePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isLight ? theme.secondaryBackground : const Color(0xFF0D1B4B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _pickedDate != null ? theme.primary : theme.secondaryText.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 14, color: _pickedDate != null ? theme.primary : theme.secondaryText),
                        const SizedBox(width: 6),
                        Text(
                          _pickedDate == null ? 'Filter by date' : _display(_pickedDate!),
                          style: GoogleFonts.poppins(
                            fontSize: sizing.bodyFs.clamp(9.0, 12.0),
                            color: _pickedDate != null ? theme.primary : theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_pickedDate != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B4B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Legend ───────────────────────────────────────────────────────
            Row(
              children: [
                _dot(_highlightColor),
                const SizedBox(width: 6),
                Text('Top contributor', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 12.0))),
                const SizedBox(width: 16),
                _dot(_defaultColor),
                const SizedBox(width: 6),
                Text('Other equipment', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 12.0))),
              ],
            ),
            const SizedBox(height: 16),

            // ── Chart body ───────────────────────────────────────────────────
            // When bounded: Expanded fills leftover height → chart scrolls.
            // When unbounded: SizedBox gives a concrete height → no assertion.
            heightBounded ? Expanded(child: chartBody) : SizedBox(height: fallbackChartHeight, child: chartBody),
          ],
        );
      },
    );
  }

  Widget _dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  // ── Chart content dispatcher ───────────────────────────────────────────────
  Widget _buildChartContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load data', style: GoogleFonts.poppins(color: Colors.red, fontSize: 14)),
            const SizedBox(height: 8),
            Text(widget.errorMessage!, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final visibleData = widget.rankingData.toList();

    if (visibleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, color: theme.secondaryText.withOpacity(0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              widget.selectedEventDate.isEmpty
                  ? 'Select a date or click a\nMax Demand event row to view data'
                  : 'No data available for selected period',
              style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildHorizontalBarChart(context, visibleData, sizing);
  }

  // ── Horizontal bar chart ───────────────────────────────────────────────────
  Widget _buildHorizontalBarChart(
    BuildContext context,
    List<Map<String, dynamic>> data,
    CardSizing sizing,
  ) {
    final theme = FlutterFlowTheme.of(context);

    final double topValue = _pf(data.first);
    final double maxValue = topValue > 0 ? topValue * 1.15 : 1.0;

    const double barHeight = 20.0;
    const double rowHeight = 28.0;
    const double labelWidth = 110.0;
    const double valueWidth = 88.0;
    const double gaps = 8.0 + 6.0;

    return LayoutBuilder(builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth;
      final double maxBarWidth = (availableWidth - labelWidth - valueWidth - gaps).clamp(0.0, availableWidth);

      final bool bounded = constraints.maxHeight.isFinite;

      return ListView.builder(
        physics: bounded ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        shrinkWrap: !bounded,
        itemCount: data.length,
        itemExtent: rowHeight,
        itemBuilder: (context, i) {
          final item = data[i];
          final double pf = _pf(item);
          final double pct = _pct(item);
          final Color barColor = i < _highlightCount ? _highlightColor : _defaultColor;
          final double barWidth = (maxBarWidth * (pf / maxValue)).clamp(0.0, maxBarWidth);
          final String deviceId = item['device_id']?.toString() ?? '';
          final String deviceName = (item['device_name'] as String?)?.trim() ?? '';
          final String label = deviceName.isNotEmpty ? deviceName : deviceId;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Device label — name when Master Facilities has one, else the
              // raw meterId (e.g. unregistered/virtual meters).
              SizedBox(
                width: labelWidth,
                child: Tooltip(
                  message: deviceName.isNotEmpty ? '$deviceName ($deviceId)' : deviceId,
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(9.0, 11.0)),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Value + percentage
              Flexible(
                child: Text(
                  '${pf.toStringAsFixed(1)} kW (${pct.toStringAsFixed(1)}%)',
                  style: GoogleFonts.poppins(
                    color: barColor,
                    fontSize: sizing.bodyFs.clamp(9.0, 11.0),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
