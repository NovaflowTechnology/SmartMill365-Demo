import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';

class DeviceRankingSection extends StatefulWidget {
  const DeviceRankingSection({
    super.key,
    required this.devices,
    required this.trendData,
    required this.onShowAllLayers,
    required this.factorVersionNote,
    this.onDeviceTap,
  });

  final List<DeviceEmissionRow> devices;
  final List<MonthlyTrendPoint> trendData;
  final VoidCallback onShowAllLayers;
  final String factorVersionNote;
  final void Function(DeviceEmissionRow)? onDeviceTap;

  @override
  State<DeviceRankingSection> createState() => _DeviceRankingSectionState();
}

class _DeviceRankingSectionState extends State<DeviceRankingSection> {
  String _sortBy = 'kwh';
  bool _sortDesc = true;

  List<DeviceEmissionRow> get _sorted {
    final normal = widget.devices.where((d) => !d.isSolar).toList();
    final solar = widget.devices.where((d) => d.isSolar).toList();
    normal.sort((a, b) {
      final av = _sortBy == 'kwh' ? (a.kwhMonthly ?? -1) : (a.tco2eMonthly ?? -double.infinity);
      final bv = _sortBy == 'kwh' ? (b.kwhMonthly ?? -1) : (b.tco2eMonthly ?? -double.infinity);
      return _sortDesc ? bv.compareTo(av) : av.compareTo(bv);
    });
    return [...normal, ...solar];
  }

  void _toggleSort(String key) => setState(() {
        if (_sortBy == key) {
          _sortDesc = !_sortDesc;
        } else {
          _sortBy = key;
          _sortDesc = true;
        }
      });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final sorted = _sorted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Device Ranking Table ──────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1A2D4F),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Emission Ranking',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLight ? t.txtPrimary : Colors.white,
                              ),
                            ),
                            Text(
                              'Month running total · tap row for detail',
                              style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted),
                            ),
                          ],
                        ),
                      ),
                      _SortDropdown(
                        sortBy: _sortBy,
                        sortDesc: _sortDesc,
                        onChanged: _toggleSort,
                        t: t,
                        isLight: isLight,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onShowAllLayers,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: t.primary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'All Time Layers',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: t.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildColumnHeader(t, isLight),
                Divider(
                  height: 1,
                  color: isLight ? const Color(0xFFE8EFF6) : const Color(0xFF112040),
                ),
                ...sorted.asMap().entries.map((e) {
                  final isLast = e.key == sorted.length - 1;
                  return Column(
                    children: [
                      _DeviceRowWidget(
                        rank: e.key + 1,
                        row: e.value,
                        t: t,
                        isLight: isLight,
                        onTap: widget.onDeviceTap != null ? () => widget.onDeviceTap!(e.value) : null,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: isLight ? const Color(0xFFF3F6FA) : const Color(0xFF0C1A30),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── Monthly CO₂e Trend Chart ──────────────────────────────────────
        SizedBox(
          width: 220,
          child: _MonthlyTrendPanel(
            t: t,
            isLight: isLight,
            trendData: widget.trendData,
            factorVersionNote: widget.factorVersionNote,
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeader(FlutterFlowTheme t, bool isLight) {
    final style = GoogleFonts.poppins(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: t.txtMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('#', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(child: Text('DEVICE', style: style)),
          SizedBox(width: 68, child: Text('STATUS', style: style)),
          SizedBox(width: 70, child: Text('kWh', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text('tCO₂e', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text('SHARE%', style: style)),
          SizedBox(width: 52, child: Text('INTENSITY', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ── Sort Dropdown ─────────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.sortBy,
    required this.sortDesc,
    required this.onChanged,
    required this.t,
    required this.isLight,
  });

  final String sortBy;
  final bool sortDesc;
  final void Function(String) onChanged;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final label = 'Sort: ${sortBy == 'kwh' ? 'kWh' : 'tCO₂e'} ${sortDesc ? '↓' : '↑'}';
    return PopupMenuButton<String>(
      onSelected: onChanged,
      color: isLight ? Colors.white : const Color(0xFF0D1E38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF1F5FB) : const Color(0xFF0D1E38),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLight ? const Color(0xFFD4DCE8) : const Color(0xFF1E3257),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isLight ? t.txtSecondary : Colors.white70,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down, size: 13, color: t.txtMuted),
          ],
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'kwh',
          child: Text(
            'Sort by kWh',
            style: GoogleFonts.poppins(fontSize: 12, color: isLight ? t.txtPrimary : Colors.white),
          ),
        ),
        PopupMenuItem(
          value: 'tco2e',
          child: Text(
            'Sort by tCO₂e',
            style: GoogleFonts.poppins(fontSize: 12, color: isLight ? t.txtPrimary : Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── Device Row ────────────────────────────────────────────────────────────────

class _DeviceRowWidget extends StatelessWidget {
  const _DeviceRowWidget({
    required this.rank,
    required this.row,
    required this.t,
    required this.isLight,
    this.onTap,
  });

  final int rank;
  final DeviceEmissionRow row;
  final FlutterFlowTheme t;
  final bool isLight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSolar = row.isSolar;
    final kwh = row.kwhMonthly;
    final tco2e = row.tco2eMonthly;
    final share = row.sharePercent;
    final intensity = row.intensity;

    String fmtKwh(double? v) {
      if (v == null) return '—';
      if (v == 0) return '0';
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
      return v.toStringAsFixed(0);
    }

    String fmtTco2e(double? v) {
      if (v == null) return '—';
      return v.toStringAsFixed(3);
    }

    return InkWell(
      onTap: onTap,
      hoverColor: isLight ? const Color(0xFFF8FAFD) : const Color(0xFF0D1E38).withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: t.txtMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSolar ? t.success : (isLight ? t.txtPrimary : Colors.white),
                    ),
                  ),
                  Text(
                    row.subtitle,
                    style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 68,
              child: _StatusBadge(status: row.status, t: t),
            ),
            SizedBox(
              width: 70,
              child: Text(
                fmtKwh(kwh),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isLight ? t.txtSecondary : Colors.white70,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                fmtTco2e(tco2e),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSolar ? t.success : (isLight ? t.primary : const Color(0xFF31ECFC)),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: isSolar
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Avoided',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: t.success,
                          ),
                        ),
                      ),
                    )
                  : share != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _ShareBar(percent: share, t: t, isLight: isLight),
                        )
                      : const SizedBox(),
            ),
            SizedBox(
              width: 52,
              child: Text(
                intensity != null ? intensity.toStringAsFixed(1) : '—',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: t.txtMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.t});

  final DeviceStatus status;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case DeviceStatus.live:
        color = t.success;
        label = 'LIVE';
      case DeviceStatus.idle:
        color = t.txtMuted;
        label = 'IDLE';
      case DeviceStatus.offline:
        color = t.error;
        label = 'OFFLINE';
      case DeviceStatus.stale:
        color = t.warning;
        label = 'STALE';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Share Bar ─────────────────────────────────────────────────────────────────

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.percent, required this.t, required this.isLight});

  final double percent;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    // Fixed width: parent is Padding(left:6) inside SizedBox(width:80) → 74px,
    // clamped to 60 matches the old LayoutBuilder clamp(0, 60).
    const barW = 60.0;
    final fill = (percent / 100).clamp(0.0, 1.0) * barW;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isLight ? t.txtSecondary : Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            Container(
              height: 3,
              width: barW,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFE2EAF5) : const Color(0xFF122040),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              height: 3,
              width: fill,
              decoration: BoxDecoration(
                color: t.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Monthly Trend Panel ───────────────────────────────────────────────────────

class _MonthlyTrendPanel extends StatelessWidget {
  const _MonthlyTrendPanel({
    required this.t,
    required this.isLight,
    required this.trendData,
    required this.factorVersionNote,
  });

  final FlutterFlowTheme t;
  final bool isLight;
  final List<MonthlyTrendPoint> trendData;
  final String factorVersionNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1A2D4F),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Monthly CO',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLight ? t.txtPrimary : Colors.white,
                ),
              ),
              TextSpan(
                text: '₂',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isLight ? t.txtPrimary : Colors.white,
                ),
              ),
              TextSpan(
                text: 'e Trend',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLight ? t.txtPrimary : Colors.white,
                ),
              ),
            ]),
          ),
          Text(
            'Gross vs Solar Avoided · tCO₂e',
            style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: _BarChart(data: trendData, t: t, isLight: isLight),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(
                color: isLight ? t.primary : const Color(0xFF31ECFC),
                label: 'Gross CO₂e',
                t: t,
              ),
              const SizedBox(width: 10),
              _LegendDot(color: t.warning, label: 'Solar Avoided', t: t),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            factorVersionNote,
            style: GoogleFonts.poppins(fontSize: 8, color: t.txtSubtle, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.t});

  final Color color;
  final String label;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
      ],
    );
  }
}

// ── Simple Bar Chart ──────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, required this.t, required this.isLight});

  final List<MonthlyTrendPoint> data;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxGross = data.map((d) => d.grossTco2e).reduce(max);
    const barAreaHeight = 90.0;
    const labelHeight = 14.0;

    return LayoutBuilder(builder: (ctx, constraints) {
      final totalW = constraints.maxWidth;
      final barW = (totalW / data.length) * 0.65;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final point = e.value;
          final grossFrac = (maxGross > 0 ? point.grossTco2e / maxGross : 0.0).clamp(0.0, 1.0);
          final barH = (barAreaHeight * grossFrac).clamp(2.0, barAreaHeight);
          final isLast = e.key == data.length - 1;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 2),
              child: SizedBox(
                height: barAreaHeight + labelHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: barW,
                        height: barH,
                        decoration: BoxDecoration(
                          color: isLight ? t.primary.withOpacity(0.75) : const Color(0xFF31ECFC).withOpacity(0.7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: labelHeight - 3,
                      child: Text(
                        point.month,
                        style: GoogleFonts.poppins(fontSize: 8, color: t.txtMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
