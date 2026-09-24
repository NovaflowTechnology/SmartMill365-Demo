import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import '../../../../utils/report_exporter_saver_io.dart'
    if (dart.library.html) '../../../../utils/report_exporter_saver_web.dart' as saver;

class DeviceAllLayersPage extends StatefulWidget {
  const DeviceAllLayersPage({
    super.key,
    required this.devices,
    this.onBursaSource,
  });

  final List<DeviceEmissionRow> devices;
  final VoidCallback? onBursaSource;

  static void show(
    BuildContext context, {
    required List<DeviceEmissionRow> devices,
    VoidCallback? onBursaSource,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DeviceAllLayersPage(
          devices: devices,
          onBursaSource: onBursaSource,
        ),
      ),
    );
  }

  @override
  State<DeviceAllLayersPage> createState() => _DeviceAllLayersPageState();
}

class _DeviceAllLayersPageState extends State<DeviceAllLayersPage> {
  bool _exportingCsv = false;

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
        'YTD kWh,YTD tCO2e,Intensity',
      );
      for (final cat in _categoryOrder) {
        final rows = widget.devices.where((d) => d.category == cat);
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
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
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
    final cardBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF071228);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1A2D4F);

    return Scaffold(
      backgroundColor: t.primaryBackground,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: t.primaryBackground,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.asset('assets/images/backgroundanimated.gif').image,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withOpacity(0.95) : const Color(0xFF071228).withOpacity(0.95),
                  border: Border(bottom: BorderSide(color: cardBorder)),
                ),
                child: Row(
                  children: [
                    // Back button
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1A2E),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 12,
                                color: isLight ? t.txtSecondary : Colors.white70),
                            const SizedBox(width: 4),
                            Text('Back',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isLight ? t.txtSecondary : Colors.white70,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device CO₂e Detail — All Time Layers',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isLight ? t.txtPrimary : Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Live  ·  Daily  ·  Monthly  ·  YTD  ·  kWh  ·  tCO₂e',
                            style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    if (widget.onBursaSource != null)
                      _HeaderBtn(
                        label: '+ Bursa Report Source',
                        icon: Icons.add_chart_outlined,
                        primary: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onBursaSource?.call();
                        },
                        t: t, isLight: isLight,
                      ),
                    const SizedBox(width: 8),
                    _HeaderBtn(
                      label: _exportingCsv ? 'Exporting…' : 'CSV',
                      icon: Icons.download_outlined,
                      onTap: _exportingCsv ? () {} : _exportCsv,
                      t: t, isLight: isLight,
                    ),
                  ],
                ),
              ),

              // ── Table ────────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildColumnHeaders(t, isLight, cardBorder),
                        Divider(height: 1, color: cardBorder),
                        ..._categoryOrder.map((cat) {
                          final rows = widget.devices
                              .where((d) => d.category == cat)
                              .toList();
                          if (rows.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CategoryHeader(label: _categoryLabel(cat), t: t, isLight: isLight),
                              ...rows.map((d) => _DeviceRow(device: d, t: t, isLight: isLight)),
                              Divider(height: 1, color: cardBorder),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Column flex values (proportional to original pixel widths) ──────────────
  // DEVICE=160, STATUS=72, LIVE_PWR=90, LIVE_CO2=90, DAILY_KWH=76,
  // DAILY_TCO2=80, MTH_KWH=84, MTH_TCO2=88, YTD_KWH=80, YTD_TCO2=84, INTENS=64
  // Total ≈ 968  →  used directly as flex integers.

  Widget _buildColumnHeaders(FlutterFlowTheme t, bool isLight, Color border) {
    final s = GoogleFonts.poppins(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: t.txtMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 160, child: Text('DEVICE', style: s)),
          Expanded(flex: 72,  child: Text('STATUS', style: s)),
          Expanded(flex: 90,  child: Text('LIVE POWER',     style: s, textAlign: TextAlign.right)),
          Expanded(flex: 90,  child: Text('LIVE CO₂e RATE', style: s, textAlign: TextAlign.right)),
          Expanded(flex: 76,  child: Text('DAILY KWH',      style: s, textAlign: TextAlign.right)),
          Expanded(flex: 80,  child: Text('DAILY TCO₂E',    style: s, textAlign: TextAlign.right)),
          Expanded(flex: 84,  child: Text('MONTHLY KWH',    style: s, textAlign: TextAlign.right)),
          Expanded(flex: 88,  child: Text('MONTHLY TCO₂E',  style: s, textAlign: TextAlign.right)),
          Expanded(flex: 80,  child: Text('YTD KWH',        style: s, textAlign: TextAlign.right)),
          Expanded(flex: 84,  child: Text('YTD TCO₂E',      style: s, textAlign: TextAlign.right)),
          Expanded(flex: 64,  child: Text('INTENSITY',      style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ── Category Header ───────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.t, required this.isLight});
  final String label;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0C1825),
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

// ── Device Row ────────────────────────────────────────────────────────────────

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.t, required this.isLight});
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
    return v.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = device.status == DeviceStatus.offline;
    final isSolar = device.isSolar;
    final nameColor = isSolar ? t.success : (isLight ? t.txtPrimary : Colors.white);
    final tco2eColor = isSolar ? t.success : (isLight ? t.primary : const Color(0xFF31ECFC));

    return InkWell(
      hoverColor: isLight
          ? const Color(0xFFF8FAFD)
          : const Color(0xFF0D1E38).withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            // ── DEVICE (flex 160) ──────────────────────────────────────────
            Expanded(
              flex: 160,
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
                  Text(device.subtitle,
                      style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
                ],
              ),
            ),

            // ── STATUS (flex 72) ───────────────────────────────────────────
            Expanded(
              flex: 72,
              child: _StatusBadge(status: device.status, t: t),
            ),

            // ── LIVE POWER (flex 90) ───────────────────────────────────────
            Expanded(
              flex: 90,
              child: isOffline
                  ? _cell('—', '—', t)
                  : _cell(
                      device.liveKw != null ? '${device.liveKw!.toStringAsFixed(1)} kW' : '—',
                      'active power',
                      t,
                      color: isLight ? t.txtSecondary : Colors.white70,
                    ),
            ),

            // ── LIVE CO₂e RATE (flex 90) ───────────────────────────────────
            Expanded(
              flex: 90,
              child: isOffline
                  ? _cell('—', '—', t)
                  : _cell(
                      device.liveCo2Rate != null ? device.liveCo2Rate!.toStringAsFixed(4) : '—',
                      'tCO₂e/hr',
                      t,
                      color: isSolar ? t.success : (isLight ? t.txtSecondary : Colors.white70),
                    ),
            ),

            // ── DAILY KWH (flex 76) ────────────────────────────────────────
            Expanded(
              flex: 76,
              child: _cell(isOffline ? '—' : _fmtKwh(device.dailyKwh), 'kWh', t,
                  color: isLight ? t.txtSecondary : Colors.white70),
            ),

            // ── DAILY TCO₂E (flex 80) ──────────────────────────────────────
            Expanded(
              flex: 80,
              child: _cell(
                isOffline ? '—' : _fmtTco2e(device.dailyTco2e),
                'tCO₂e',
                t,
                color: isSolar ? t.success : (isLight ? t.txtSecondary : Colors.white70),
              ),
            ),

            // ── MONTHLY KWH (flex 84) ──────────────────────────────────────
            Expanded(
              flex: 84,
              child: _cell(isOffline ? '—' : _fmtKwh(device.kwhMonthly), 'kWh', t,
                  color: isLight ? t.txtSecondary : Colors.white70),
            ),

            // ── MONTHLY TCO₂E — highlighted (flex 88) ─────────────────────
            Expanded(
              flex: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOffline ? '—' : _fmtTco2e(device.tco2eMonthly),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tco2eColor,
                    ),
                  ),
                  Text('tCO₂e',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 8, color: t.txtMuted)),
                ],
              ),
            ),

            // ── YTD KWH (flex 80) ──────────────────────────────────────────
            Expanded(
              flex: 80,
              child: _cell(isOffline ? '—' : _fmtKwh(device.siteKwh), 'kWh', t,
                  color: isLight ? t.txtSecondary : Colors.white70),
            ),

            // ── YTD TCO₂E (flex 84) ────────────────────────────────────────
            Expanded(
              flex: 84,
              child: _cell(
                isOffline ? '—' : _fmtTco2e(device.siteTco2e),
                'tCO₂e',
                t,
                color: isSolar ? t.success : (isLight ? t.txtSecondary : Colors.white70),
              ),
            ),

            // ── INTENSITY (flex 64) ────────────────────────────────────────
            Expanded(
              flex: 64,
              child: device.intensity == null
                  ? Text('—',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted))
                  : _IntensityBar(value: device.intensity!, t: t, isLight: isLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String value, String sub, FlutterFlowTheme t, {Color? color}) {
    final c = color ?? (isLight ? t.txtSecondary : Colors.white70);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c,
            )),
        if (sub.isNotEmpty && sub != '—')
          Text(sub,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 8, color: t.txtMuted)),
      ],
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
          child: Text(label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              )),
        ),
      ],
    );
  }
}

// ── Intensity Bar ─────────────────────────────────────────────────────────────

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.value, required this.t, required this.isLight});
  final double value;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final frac = (value / 60.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isLight ? t.txtSecondary : Colors.white70,
            )),
        const SizedBox(height: 2),
        LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth.clamp(0.0, double.infinity); // fills flex cell
          return Stack(children: [
            Container(
              height: 3, width: w,
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFE2EAF5) : const Color(0xFF122040),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              height: 3, width: w * frac,
              decoration: BoxDecoration(
                color: isLight
                    ? t.primary.withOpacity(0.7)
                    : const Color(0xFF31ECFC).withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ]);
        }),
      ],
    );
  }
}

// ── Header Button ─────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({
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
    final bg = primary ? t.primary.withOpacity(0.1) : (isLight ? Colors.white : const Color(0xFF0D1A2E));
    final border = primary ? t.primary.withOpacity(0.3) : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E2D48));
    final fg = primary ? (isLight ? t.primary : const Color(0xFF7AB8F5)) : (isLight ? t.txtSecondary : Colors.white70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                )),
          ],
        ),
      ),
    );
  }
}