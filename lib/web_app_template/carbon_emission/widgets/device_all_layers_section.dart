import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import '../../../../utils/report_exporter_saver_io.dart'
    if (dart.library.html) '../../../../utils/report_exporter_saver_web.dart' as saver;

class DeviceAllLayersSection extends StatefulWidget {
  const DeviceAllLayersSection({
    super.key,
    required this.devices,
    this.onBursaSource,
  });

  final List<DeviceEmissionRow> devices;
  final VoidCallback? onBursaSource;

  @override
  State<DeviceAllLayersSection> createState() => _DeviceAllLayersSectionState();
}

class _DeviceAllLayersSectionState extends State<DeviceAllLayersSection> {
  bool _exportingCsv = false;

  // Group devices by category, preserving order
  static const _categoryOrder = [
    DeviceCategory.stretchFilmLine,
    DeviceCategory.castFilmLine,
    DeviceCategory.blownFilmLine,
    DeviceCategory.utilitiesOthers,
    DeviceCategory.solarGeneration,
  ];

  static String _categoryLabel(DeviceCategory c) => switch (c) {
        DeviceCategory.stretchFilmLine => 'STRETCH FILM LINES',
        DeviceCategory.castFilmLine => 'CAST FILM LINES',
        DeviceCategory.blownFilmLine => 'BLOWN FILM LINES',
        DeviceCategory.utilitiesOthers => 'UTILITIES & OTHERS',
        DeviceCategory.solarGeneration => 'SOLAR GENERATION',
      };

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    try {
      final buf = StringBuffer();
      buf.writeln('Device CO2e Detail — All Time Layers');
      buf.writeln('EF: 0.574 kgCO2e/kWh (ST Malaysia FY2025)');
      buf.writeln('');
      buf.writeln(
        'Category,Device,Status,Live kW,Live CO2 Rate (tCO2e/hr),'
        'Daily kWh,Daily tCO2e,Monthly kWh,Monthly tCO2e,'
        'Site kWh,Site tCO2e,Intensity',
      );
      for (final cat in _categoryOrder) {
        final rows = widget.devices.where((d) => d.category == cat).toList();
        for (final d in rows) {
          buf.writeln(
            '${_categoryLabel(cat)},${d.name},${d.status.name.toUpperCase()},'
            '${d.liveKw ?? '—'},${d.liveCo2Rate ?? '—'},'
            '${d.dailyKwh ?? '—'},${d.dailyTco2e ?? '—'},'
            '${d.kwhMonthly ?? '—'},${d.tco2eMonthly ?? '—'},'
            '${d.siteKwh ?? '—'},${d.siteTco2e ?? '—'},'
            '${d.intensity ?? '—'}',
          );
        }
      }
      await saver.saveExcelBytes(
        bytes: utf8.encode(buf.toString()),
        fileName: 'device_co2_all_layers.csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.85);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1A2D4F);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device CO₂e Detail — All Time Layers',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLight ? t.txtPrimary : Colors.white,
                        ),
                      ),
                      Text(
                        'Live · Daily · Monthly · Site-to-date',
                        style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted),
                      ),
                    ],
                  ),
                ),
                // Bursa Report Source button
                if (widget.onBursaSource != null)
                  _ActionBtn(
                    label: '+ Bursa Report Source',
                    icon: Icons.add_chart_outlined,
                    onTap: widget.onBursaSource!,
                    primary: true,
                    t: t,
                    isLight: isLight,
                  ),
                const SizedBox(width: 6),
                _ActionBtn(
                  label: _exportingCsv ? 'Exporting…' : 'CSV',
                  icon: Icons.download_outlined,
                  onTap: _exportingCsv ? () {} : _exportCsv,
                  t: t,
                  isLight: isLight,
                ),
              ],
            ),
          ),

          // ── Column Headers ─────────────────────────────────────────────────
          _buildColumnHeaders(t, isLight),
          Divider(height: 1, color: cardBorder),

          // ── Rows grouped by category ───────────────────────────────────────
          ..._categoryOrder.map((cat) {
            final rows = widget.devices.where((d) => d.category == cat).toList();
            if (rows.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategoryHeader(label: _categoryLabel(cat), t: t, isLight: isLight),
                ...rows.map((d) => _DeviceLayerRow(device: d, t: t, isLight: isLight)),
                Divider(height: 1, color: cardBorder),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(FlutterFlowTheme t, bool isLight) {
    final s = GoogleFonts.poppins(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: t.txtMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text('DEVICE', style: s)),
          SizedBox(width: 68, child: Text('STATUS', style: s)),
          SizedBox(width: 72, child: Text('LIVE POWER', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text('LIVE CO₂ RATE', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 68, child: Text('DAILY kWh', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 74, child: Text('DAILY tCO₂e', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 76, child: Text('MTH kWh', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 82, child: Text('MTH tCO₂e', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 72, child: Text('SITE kWh', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text('SITE tCO₂e', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 58, child: Text('INTENSITY', style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ── Category Header ───────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.label,
    required this.t,
    required this.isLight,
  });

  final String label;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: isLight ? const Color(0xFFF0F4FA) : const Color(0xFF0C1825),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: isLight ? t.txtSecondary : const Color(0xFF6B8CAE),
        ),
      ),
    );
  }
}

// ── Device Layer Row ──────────────────────────────────────────────────────────

class _DeviceLayerRow extends StatelessWidget {
  const _DeviceLayerRow({
    required this.device,
    required this.t,
    required this.isLight,
  });

  final DeviceEmissionRow device;
  final FlutterFlowTheme t;
  final bool isLight;

  String _fmtKwh(double? v) {
    if (v == null) return '—';
    if (v == 0) return '0';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  String _fmtTco2e(double? v) {
    if (v == null) return '—';
    if (v == 0) return '0.000';
    return v.toStringAsFixed(3);
  }

  String _fmtRate(double? v) {
    if (v == null) return '—';
    return v.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = device.status == DeviceStatus.offline;
    final isSolar = device.isSolar;

    final nameColor = isSolar
        ? t.success
        : (isLight ? t.txtPrimary : Colors.white);

    final tco2eColor = isSolar
        ? t.success
        : (isLight ? t.primary : const Color(0xFF31ECFC));

    return InkWell(
      hoverColor: isLight
          ? const Color(0xFFF8FAFD)
          : const Color(0xFF0D1E38).withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            // Device name + subtitle
            SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSolar ? '✦ ${device.name}' : device.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: nameColor,
                    ),
                  ),
                  Text(
                    device.subtitle,
                    style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
                  ),
                ],
              ),
            ),
            // Status badge
            SizedBox(
              width: 68,
              child: _StatusBadge(status: device.status, t: t),
            ),
            // Live power
            SizedBox(
              width: 72,
              child: isOffline
                  ? Text('—', style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted), textAlign: TextAlign.right)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          device.liveKw != null ? '${device.liveKw!.toStringAsFixed(1)} kW' : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isLight ? t.txtSecondary : Colors.white70,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          'active power',
                          style: GoogleFonts.poppins(fontSize: 8, color: t.txtMuted),
                        ),
                      ],
                    ),
            ),
            // Live CO₂ rate
            SizedBox(
              width: 80,
              child: isOffline
                  ? Text('—', style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted), textAlign: TextAlign.right)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtRate(device.liveCo2Rate),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSolar ? t.success : (isLight ? t.txtSecondary : Colors.white70),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          'tCO₂e/hr',
                          style: GoogleFonts.poppins(fontSize: 8, color: t.txtMuted),
                        ),
                      ],
                    ),
            ),
            // Daily kWh
            SizedBox(
              width: 68,
              child: Text(
                isOffline ? '—' : _fmtKwh(device.dailyKwh),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isLight ? t.txtSecondary : Colors.white70,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Daily tCO₂e
            SizedBox(
              width: 74,
              child: Text(
                isOffline ? '—' : _fmtTco2e(device.dailyTco2e),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSolar ? t.success : (isLight ? t.txtSecondary : Colors.white70),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Monthly kWh
            SizedBox(
              width: 76,
              child: Text(
                isOffline ? '—' : _fmtKwh(device.kwhMonthly),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isLight ? t.txtSecondary : Colors.white70,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Monthly tCO₂e — highlighted
            SizedBox(
              width: 82,
              child: Text(
                isOffline ? '—' : _fmtTco2e(device.tco2eMonthly),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tco2eColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Site kWh
            SizedBox(
              width: 72,
              child: Text(
                isOffline ? '—' : _fmtKwh(device.siteKwh),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isLight ? t.txtSecondary : Colors.white70,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Site tCO₂e
            SizedBox(
              width: 80,
              child: Text(
                isOffline ? '—' : _fmtTco2e(device.siteTco2e),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSolar ? t.success : (isLight ? t.txtSecondary : Colors.white70),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Intensity
            SizedBox(
              width: 58,
              child: _IntensityBar(
                value: device.intensity,
                t: t,
                isLight: isLight,
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

// ── Intensity Bar ─────────────────────────────────────────────────────────────

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({
    required this.value,
    required this.t,
    required this.isLight,
  });

  final double? value;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text(
        '—',
        style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted),
        textAlign: TextAlign.right,
      );
    }
    // Intensity scale: 0–60 kgCO₂e/tonne
    final frac = (value! / 60.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value!.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isLight ? t.txtSecondary : Colors.white70,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 2),
        LayoutBuilder(builder: (_, c) {
          final barW = c.maxWidth.clamp(0.0, 52.0);
          return Stack(
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
                width: barW * frac,
                decoration: BoxDecoration(
                  color: isLight ? t.primary.withOpacity(0.7) : const Color(0xFF31ECFC).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.t,
    required this.isLight,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final FlutterFlowTheme t;
  final bool isLight;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? t.primary.withOpacity(0.1)
        : (isLight ? Colors.white : const Color(0xFF0D1A2E));
    final border = primary
        ? t.primary.withOpacity(0.3)
        : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E2D48));
    final fg = primary
        ? (isLight ? t.primary : const Color(0xFF7AB8F5))
        : (isLight ? t.txtSecondary : Colors.white70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
