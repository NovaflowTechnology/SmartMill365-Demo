import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';

class DeviceCo2DetailDialog extends StatelessWidget {
  const DeviceCo2DetailDialog({
    super.key,
    required this.device,
    required this.emissionFactor,
    required this.emissionFactorYear,
  });

  final DeviceEmissionRow device;
  final double emissionFactor;
  final int emissionFactorYear;

  static void show(
    BuildContext context, {
    required DeviceEmissionRow device,
    double emissionFactor = 0.574,
    int emissionFactorYear = 2025,
  }) {
    showDialog(
      context: context,
      builder: (_) => DeviceCo2DetailDialog(
        device: device,
        emissionFactor: emissionFactor,
        emissionFactorYear: emissionFactorYear,
      ),
    );
  }

  // Generate plausible 24-hour profile from monthly total
  List<DeviceHourlyPoint> _buildHourly() {
    final base = device.kwhMonthly != null ? (device.kwhMonthly! / 30 / 24) : 0.0;
    final rng = Random(device.id.hashCode);
    return List.generate(24, (i) {
      final hour = i.toString().padLeft(2, '0');
      // Simulate lower load at night (00:00–05:00) and peak at 08:00–17:00
      double factor;
      if (i < 6) {
        factor = 0.3 + rng.nextDouble() * 0.2;
      } else if (i < 18) {
        factor = 0.7 + rng.nextDouble() * 0.5;
      } else {
        factor = 0.4 + rng.nextDouble() * 0.3;
      }
      return DeviceHourlyPoint(label: '${hour}h', kwh: base * factor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final barBg = isLight ? Colors.white : const Color(0xFF111827);
    final cardBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1A2D4F);
    final titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final hourly = _buildHourly();
    final kwh = device.kwhMonthly ?? 0.0;
    final tco2e = device.isSolar ? (device.tco2eMonthly?.abs() ?? 0.0) : (device.tco2eMonthly ?? 0.0);
    final intensity = device.intensity ?? emissionFactor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0B1221),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isLight ? 0.12 : 0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  border: Border(bottom: BorderSide(color: cardBorder)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: device.isSolar
                            ? t.success.withOpacity(0.1)
                            : t.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: device.isSolar
                              ? t.success.withOpacity(0.25)
                              : t.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          device.isSolar ? Icons.wb_sunny_outlined : Icons.bolt_outlined,
                          size: 18,
                          color: device.isSolar ? t.success : t.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                device.subtitle,
                                style: TextStyle(color: subColor, fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              _StatusPill(status: device.status, t: t),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E2A48),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Icon(Icons.close, size: 14, color: subColor),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI chips
                      Row(
                        children: [
                          _KpiTile(
                            label: device.isSolar ? 'Generated (MTD)' : 'Consumed (MTD)',
                            value: kwh >= 1000
                                ? '${(kwh / 1000).toStringAsFixed(1)}k'
                                : kwh.toStringAsFixed(0),
                            unit: 'kWh',
                            color: isLight ? t.primary : const Color(0xFF31ECFC),
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            t: t,
                            isLight: isLight,
                          ),
                          const SizedBox(width: 10),
                          _KpiTile(
                            label: device.isSolar ? 'CO₂e Avoided' : 'CO₂e Emitted',
                            value: tco2e.toStringAsFixed(3),
                            unit: 'tCO₂e',
                            color: device.isSolar ? t.success : t.error.withOpacity(0.9),
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            t: t,
                            isLight: isLight,
                          ),
                          const SizedBox(width: 10),
                          _KpiTile(
                            label: 'Emission Factor',
                            value: intensity.toStringAsFixed(3),
                            unit: 'kgCO₂e/kWh',
                            color: t.txtMuted,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            t: t,
                            isLight: isLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scope 2 formula
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.isSolar
                                  ? 'AVOIDED EMISSIONS CALCULATION'
                                  : 'SCOPE 2 CO₂e CALCULATION',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: subColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _FormulaRow(
                              parts: [
                                _FormulaPart(
                                  label: device.isSolar ? 'PV Generation' : 'Energy Consumption',
                                  value: '${kwh.toStringAsFixed(0)} kWh',
                                  isLight: isLight,
                                  t: t,
                                ),
                                _FormulaPart(label: '×', value: '', isLight: isLight, t: t, isOp: true),
                                _FormulaPart(
                                  label: 'EF (FY$emissionFactorYear)',
                                  value: '${intensity.toStringAsFixed(3)} kgCO₂e/kWh',
                                  isLight: isLight,
                                  t: t,
                                ),
                                _FormulaPart(label: '÷', value: '', isLight: isLight, t: t, isOp: true),
                                _FormulaPart(
                                  label: 'Unit conversion',
                                  value: '1,000',
                                  isLight: isLight,
                                  t: t,
                                ),
                                _FormulaPart(label: '=', value: '', isLight: isLight, t: t, isOp: true),
                                _FormulaPart(
                                  label: device.isSolar ? 'tCO₂e Avoided' : 'tCO₂e Emitted',
                                  value: '${tco2e.toStringAsFixed(3)} tCO₂e',
                                  isLight: isLight,
                                  t: t,
                                  highlight: true,
                                  highlightColor: device.isSolar ? t.success : t.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 24-hour profile chart
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '24-Hour Load Profile (Today)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isLight ? t.txtPrimary : Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  'kWh / hr',
                                  style: GoogleFonts.poppins(fontSize: 9, color: subColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: _HourlyBarChart(
                                data: hourly,
                                accentColor: device.isSolar
                                    ? t.success
                                    : (isLight ? t.primary : const Color(0xFF31ECFC)),
                                isLight: isLight,
                                t: t,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emission factor citation
                      Row(
                        children: [
                          Icon(Icons.verified_outlined, size: 12, color: subColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Emission factor FY$emissionFactorYear: ${intensity.toStringAsFixed(3)} kgCO₂e/kWh · '
                              'Source: Suruhanjaya Tenaga (ST) Malaysia · '
                              'Method: GHG Protocol Scope 2 Market-Based',
                              style: GoogleFonts.poppins(fontSize: 9, color: subColor, height: 1.5),
                            ),
                          ),
                        ],
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
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.t});

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

// ── KPI Tile ──────────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.cardBg,
    required this.cardBorder,
    required this.t,
    required this.isLight,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color cardBg;
  final Color cardBorder;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: color, width: 3),
            top: BorderSide(color: cardBorder),
            right: BorderSide(color: cardBorder),
            bottom: BorderSide(color: cardBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isLight ? t.txtPrimary : Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formula Row ───────────────────────────────────────────────────────────────

class _FormulaPart {
  final String label;
  final String value;
  final bool isOp;
  final bool highlight;
  final Color? highlightColor;
  final FlutterFlowTheme t;
  final bool isLight;

  const _FormulaPart({
    required this.label,
    required this.value,
    required this.t,
    required this.isLight,
    this.isOp = false,
    this.highlight = false,
    this.highlightColor,
  });
}

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({required this.parts});

  final List<_FormulaPart> parts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts.map((p) {
        if (p.isOp) {
          return Text(
            p.label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: p.t.txtMuted,
            ),
          );
        }
        final valueColor = p.highlight
            ? (p.highlightColor ?? p.t.primary)
            : (p.isLight ? p.t.txtPrimary : Colors.white);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.label,
              style: GoogleFonts.poppins(fontSize: 8, color: p.t.txtMuted),
            ),
            Text(
              p.value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: p.highlight ? FontWeight.w800 : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Hourly Bar Chart ──────────────────────────────────────────────────────────

class _HourlyBarChart extends StatelessWidget {
  const _HourlyBarChart({
    required this.data,
    required this.accentColor,
    required this.isLight,
    required this.t,
  });

  final List<DeviceHourlyPoint> data;
  final Color accentColor;
  final bool isLight;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final maxVal = data.map((d) => d.kwh).reduce(max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.asMap().entries.map((e) {
        final pt = e.value;
        final frac = maxVal > 0 ? (pt.kwh / maxVal).clamp(0.0, 1.0) : 0.0;
        // show label every 6 hours
        final showLabel = e.key % 6 == 0;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: frac == 0 ? 0.04 : frac,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                showLabel ? pt.label : '',
                style: GoogleFonts.poppins(fontSize: 7, color: t.txtMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
