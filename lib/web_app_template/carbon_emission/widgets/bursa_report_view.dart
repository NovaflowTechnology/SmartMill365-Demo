import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import '../../../../utils/report_exporter_saver_io.dart'
    if (dart.library.html) '../../../../utils/report_exporter_saver_web.dart' as saver;

class BursaReportView extends StatefulWidget {
  const BursaReportView({
    super.key,
    required this.rows,
    required this.facilityName,
    required this.reportYear,
    required this.emissionFactorVersion,
  });

  final List<BursaReportRow> rows;
  final String facilityName;
  final int reportYear;
  final String emissionFactorVersion;

  @override
  State<BursaReportView> createState() => _BursaReportViewState();
}

class _BursaReportViewState extends State<BursaReportView> {
  bool _exportingCsv = false;

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    try {
      final buf = StringBuffer();
      buf.writeln('Bursa ESG Carbon Disclosure Report — ${widget.facilityName} FY${widget.reportYear}');
      buf.writeln('Emission Factor: ${widget.emissionFactorVersion}');
      buf.writeln('');
      buf.writeln('Month,Scope 1 (tCO2e),Scope 2 Gross (tCO2e),Solar Avoided (tCO2e),Scope 2 Net (tCO2e),Total GHG (tCO2e)');
      for (final r in widget.rows) {
        buf.writeln(
          '${r.month},${r.scope1.toStringAsFixed(3)},${r.scope2Gross.toStringAsFixed(3)},'
          '${r.solarAvoided.toStringAsFixed(3)},${r.scope2Net.toStringAsFixed(3)},${r.totalNet.toStringAsFixed(3)}',
        );
      }
      await saver.saveExcelBytes(
        bytes: utf8.encode(buf.toString()),
        fileName: 'bursa_carbon_report_${widget.reportYear}.csv',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Bursa Info Banner ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFFFFBEB) : const Color(0xFF1A1500),
            border: Border.all(
              color: isLight ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFFF59E0B).withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bursa Malaysia / SC Sustainability Statement — Scope 2 GHG Data',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reporting Entity: Thong Guan Plastic & Paper Industries Sdn Bhd — Kedah Facility  ·  '
                      'Method: GHG Protocol Corporate Standard  ·  '
                      'Factor: ST Malaysia (0.574 kgCO₂e/kWh FY2025)  ·  '
                      'Data: Direct metering via DELAB PQM1000  ·  '
                      'Coverage: 100% installed capacity',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: isLight ? const Color(0xFF92400E) : const Color(0xFFD97706),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── GHG Emissions Summary Table ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table title row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'GHG Emissions Summary Table — Scope 2',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLight ? t.txtPrimary : Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: t.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'IFRS S2  ·  GHG Protocol',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isLight ? t.primary : const Color(0xFF7AB8F5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Column headers
              _buildColHeaders(t, isLight, cardBorder),

              // ── A. Electricity Consumption ─────────────────────────────────
              _SectionHeader(label: 'A. ELECTRICITY CONSUMPTION', t: t, isLight: isLight),
              _DataRow(
                label: 'Total Electricity Consumed',
                sublabel: 'Purchased from TNB grid  ·  kWh',
                fy22: '28,650,000', fy22sub: 'kWh',
                fy23: '29,100,000', fy23sub: 'kWh', fy23revised: false,
                fy24: '29,400,000', fy24sub: 'kWh',
                ytd: '14,590,860', ytdsub: 'kWh (Jan–May)',
                ytdHighlight: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _DataRow(
                label: 'Solar Self-Generation (Avoided)',
                sublabel: 'On-site PV generation  ·  kWh',
                fy22: '—', fy22sub: 'Not installed',
                fy23: '180,000', fy23sub: 'kWh', fy23revised: false,
                fy24: '252,630', fy24sub: 'kWh',
                ytd: '210,525', ytdsub: 'kWh (Jan–May)',
                ytdHighlight: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),

              // ── B. Scope 2 GHG Emissions ───────────────────────────────────
              _SectionHeader(label: 'B. SCOPE 2 GHG EMISSIONS (MARKET-BASED)', t: t, isLight: isLight),
              _DataRow(
                label: 'Grid Emission Factor Used',
                sublabel: 'Source: Suruhanjaya Tenaga (ST) Malaysia',
                fy22: '0.601', fy22sub: 'kgCO₂e/kWh',
                fy23: '0.585', fy23sub: 'kgCO₂e/kWh', fy23revised: true,
                fy24: '0.581', fy24sub: 'kgCO₂e/kWh',
                ytd: '0.574', ytdsub: 'kgCO₂e/kWh',
                ytdHighlight: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _DataRow(
                label: 'Gross Scope 2 Emissions',
                sublabel: 'Total purchased electricity × factor',
                fy22: '17,218.7', fy22sub: 'tCO₂e',
                fy23: '17,023.5', fy23sub: 'tCO₂e', fy23revised: true,
                fy24: '17,081.4', fy24sub: 'tCO₂e',
                ytd: '8,374.9', ytdsub: 'tCO₂e (Jan–May)',
                ytdHighlight: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _DataRow(
                label: 'Solar Avoided Emissions',
                sublabel: 'On-site PV generation × factor (offset)',
                fy22: '—', fy22sub: '',
                fy23: '105.3', fy23sub: 'tCO₂e avoided', fy23revised: false,
                fy24: '146.8', fy24sub: 'tCO₂e avoided',
                ytd: '120.8', ytdsub: 'tCO₂e avoided',
                ytdHighlight: true, ytdSolar: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _NetEmissionRow(t: t, isLight: isLight, cardBorder: cardBorder),

              // ── C. Emission Intensity ──────────────────────────────────────
              _SectionHeader(label: 'C. EMISSION INTENSITY (BURSA REQUIRED)', t: t, isLight: isLight),
              _DataRow(
                label: 'Intensity — per tonne product',
                sublabel: 'Net tCO₂e ÷ production output',
                fy22: '24.6', fy22sub: 'kgCO₂e / tonne',
                fy23: '24.1', fy23sub: 'kgCO₂e / tonne', fy23revised: false,
                fy24: '23.9', fy24sub: 'kgCO₂e / tonne',
                ytd: '23.7', ytdsub: 'kgCO₂e / tonne',
                ytdHighlight: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _DataRow(
                label: 'Intensity — per RM million revenue',
                sublabel: 'Net tCO₂e ÷ revenue (RM mil)',
                fy22: '17.9', fy22sub: 'tCO₂e / RM mil',
                fy23: '13.6', fy23sub: 'tCO₂e / RM mil', fy23revised: false,
                fy24: '13.7', fy24sub: 'tCO₂e / RM mil',
                ytd: '—', ytdsub: 'Revenue YTD pending',
                ytdHighlight: false,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _YoyRow(t: t, isLight: isLight, cardBorder: cardBorder),

              // ── D. Data Quality ────────────────────────────────────────────
              _SectionHeader(label: 'D. DATA QUALITY STATEMENT', t: t, isLight: isLight),
              _SpanningRow(
                label: 'Measurement Method',
                value: 'Direct metering — DELAB PQM1000 digital power meters installed at all 14 distribution points. 15-minute interval data. Coverage: 100% of installed capacity at Kedah facility.',
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _DataRow(
                label: 'Data Completeness',
                sublabel: '',
                fy22: '97.3%', fy22sub: '',
                fy23: '98.1%', fy23sub: '', fy23revised: false,
                fy24: '99.2%', fy24sub: '',
                ytd: '99.6%', ytdsub: '',
                ytdHighlight: true,
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _SpanningRow(
                label: 'Reporting Boundary',
                value: 'Operational control — Thong Guan Plastic & Paper Industries Sdn Bhd, Kedah facility only. Excludes Suzhou (China), Thailand, Denmark, and Sabah operations.',
                t: t, isLight: isLight, cardBorder: cardBorder,
              ),
              _DataRow(
                label: 'Restatements',
                sublabel: '',
                fy22: '—', fy22sub: '',
                fy23: 'FY2023 restated Aug 2024: factor 0.591→0.585 (ST revised)', fy23sub: '', fy23revised: false,
                fy24: '—', fy24sub: '',
                ytd: '—', ytdsub: '',
                ytdHighlight: false,
                t: t, isLight: isLight, cardBorder: cardBorder,
                fy23SmallText: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Bottom action buttons ──────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _BottomBtn(
              label: 'Preview Bursa Statement',
              icon: Icons.visibility_outlined,
              onTap: () {},
              t: t, isLight: isLight,
            ),
            const SizedBox(width: 8),
            _BottomBtn(
              label: 'Export Excel',
              icon: Icons.table_chart_outlined,
              onTap: _exportCsv,
              loading: _exportingCsv,
              t: t, isLight: isLight,
            ),
            const SizedBox(width: 8),
            _BottomBtn(
              label: 'Export PDF — Bursa Format',
              icon: Icons.picture_as_pdf_outlined,
              onTap: () {},
              primary: true,
              t: t, isLight: isLight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColHeaders(FlutterFlowTheme t, bool isLight, Color border) {
    final s = GoogleFonts.poppins(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: t.txtMuted,
    );
    final sYtd = GoogleFonts.poppins(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: isLight ? t.primary : const Color(0xFF31ECFC),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 220, child: SizedBox()),
          Expanded(child: Text('DISCLOSURE ITEM', style: s)),
          SizedBox(width: 130, child: Text('FY2022', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 150, child: Text('FY2023  RESTATED', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 130, child: Text('FY2024', style: s, textAlign: TextAlign.right)),
          SizedBox(width: 130, child: Text('FY2025 (YTD)', style: sYtd, textAlign: TextAlign.right)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.t, required this.isLight});
  final String label;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

// ── Data Row ──────────────────────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.sublabel,
    required this.fy22,
    required this.fy22sub,
    required this.fy23,
    required this.fy23sub,
    required this.fy23revised,
    required this.fy24,
    required this.fy24sub,
    required this.ytd,
    required this.ytdsub,
    required this.ytdHighlight,
    required this.t,
    required this.isLight,
    required this.cardBorder,
    this.ytdSolar = false,
    this.fy23SmallText = false,
  });

  final String label, sublabel;
  final String fy22, fy22sub;
  final String fy23, fy23sub;
  final bool fy23revised;
  final String fy24, fy24sub;
  final String ytd, ytdsub;
  final bool ytdHighlight;
  final bool ytdSolar;
  final bool fy23SmallText;
  final FlutterFlowTheme t;
  final bool isLight;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    final ytdColor = ytdSolar
        ? t.success
        : ytdHighlight
            ? (isLight ? t.primary : const Color(0xFF31ECFC))
            : (isLight ? t.txtPrimary : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLight ? t.txtPrimary : Colors.white,
                    )),
                if (sublabel.isNotEmpty)
                  Text(sublabel,
                      style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
              ],
            ),
          ),
          // Disclosure item description (empty spacer)
          const Expanded(child: SizedBox()),
          // FY2022
          SizedBox(
            width: 130,
            child: _ValCell(value: fy22, sub: fy22sub, color: isLight ? t.txtPrimary : Colors.white, t: t),
          ),
          // FY2023
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ValCell(
                    value: fy23,
                    sub: fy23SmallText ? fy23 : fy23sub,
                    color: isLight ? t.txtPrimary : Colors.white,
                    t: t,
                    overrideValue: fy23SmallText ? '' : null,
                    smallValue: fy23SmallText,
                  ),
                ),
                if (fy23revised)
                  Padding(
                    padding: const EdgeInsets.only(top: 1, left: 2),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: t.warning.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: t.warning.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text('✓',
                            style: TextStyle(fontSize: 7, color: t.warning)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // FY2024
          SizedBox(
            width: 130,
            child: _ValCell(value: fy24, sub: fy24sub, color: isLight ? t.txtPrimary : Colors.white, t: t),
          ),
          // FY2025 YTD
          SizedBox(
            width: 130,
            child: _ValCell(value: ytd, sub: ytdsub, color: ytdColor, t: t, bold: ytdHighlight),
          ),
          // Expand icon placeholder
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Net Emission Row (highlighted) ────────────────────────────────────────────

class _NetEmissionRow extends StatelessWidget {
  const _NetEmissionRow({required this.t, required this.isLight, required this.cardBorder});
  final FlutterFlowTheme t;
  final bool isLight;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    final cyan = isLight ? t.primary : const Color(0xFF31ECFC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF0F7FF) : cyan.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Scope 2 Emissions',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cyan,
                    )),
                Text('Gross − Solar Avoided  ·  Bursa disclosure figure',
                    style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(width: 130, child: _ValCell(value: '17,218.7', sub: 'tCO₂e', color: isLight ? t.txtPrimary : Colors.white, t: t)),
          SizedBox(width: 150, child: _ValCell(value: '16,918.2', sub: 'tCO₂e', color: isLight ? t.txtPrimary : Colors.white, t: t)),
          SizedBox(width: 130, child: _ValCell(value: '16,934.6', sub: 'tCO₂e', color: isLight ? t.txtPrimary : Colors.white, t: t)),
          SizedBox(
            width: 130,
            child: _ValCell(
              value: '8,254.1',
              sub: 'tCO₂e (Jan–May · Net-Final)',
              color: cyan,
              t: t,
              bold: true,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── YoY Change Row ────────────────────────────────────────────────────────────

class _YoyRow extends StatelessWidget {
  const _YoyRow({required this.t, required this.isLight, required this.cardBorder});
  final FlutterFlowTheme t;
  final bool isLight;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YoY Change — Net Scope 2',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLight ? t.txtPrimary : Colors.white,
                    )),
                Text('vs prior year full year',
                    style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
          // FY2022 — Baseline
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Text('Baseline',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    )),
              ),
            ),
          ),
          // FY2023
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.arrow_drop_down, size: 14, color: t.success),
                Text('-1.7%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.success,
                    )),
              ],
            ),
          ),
          // FY2024
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.arrow_drop_up, size: 14, color: t.error),
                Text('+0.1%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.error,
                    )),
              ],
            ),
          ),
          // YTD
          SizedBox(
            width: 130,
            child: Text('YTD only',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted)),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Spanning Row ──────────────────────────────────────────────────────────────

class _SpanningRow extends StatelessWidget {
  const _SpanningRow({
    required this.label,
    required this.value,
    required this.t,
    required this.isLight,
    required this.cardBorder,
  });
  final String label, value;
  final FlutterFlowTheme t;
  final bool isLight;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLight ? t.txtPrimary : Colors.white,
                )),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Value Cell ────────────────────────────────────────────────────────────────

class _ValCell extends StatelessWidget {
  const _ValCell({
    required this.value,
    required this.sub,
    required this.color,
    required this.t,
    this.bold = false,
    this.overrideValue,
    this.smallValue = false,
  });
  final String value, sub;
  final Color color;
  final FlutterFlowTheme t;
  final bool bold;
  final String? overrideValue;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    final displayValue = overrideValue ?? value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (displayValue.isNotEmpty)
          Text(
            displayValue,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: smallValue ? 9 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        if (sub.isNotEmpty)
          Text(sub,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 9, color: t.txtMuted)),
      ],
    );
  }
}

// ── Bottom Button ─────────────────────────────────────────────────────────────

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.t,
    required this.isLight,
    this.loading = false,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final FlutterFlowTheme t;
  final bool isLight;
  final bool loading;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? t.primary : (isLight ? Colors.white : const Color(0xFF0D1A2E));
    final border = primary ? t.primary : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E2D48));
    final fg = primary ? Colors.white : (isLight ? t.txtSecondary : Colors.white70);

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: fg))
                : Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}
