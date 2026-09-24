import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import 'carbon_flow_diagram.dart' show DashboardCard;

/// "Intensity by Production Line" table card with a unit selector.
class IntensityByLineCard extends StatelessWidget {
  const IntensityByLineCard({
    super.key,
    required this.periodLabel,
    required this.rows,
  });

  final String periodLabel;
  final List<ProductionLineIntensity> rows;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DashboardCard(
      title: 'INTENSITY BY PRODUCTION LINE',
      subtitle: periodLabel,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1A2E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E2D48)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('kgCO₂e / ton', style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: t.txtMuted)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: t.txtMuted),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                _headerCell('LINE', flex: 3, t: t),
                _headerCell('PRODUCTION (ton)', flex: 3, t: t, align: TextAlign.right),
                _headerCell('INTENSITY', flex: 2, t: t, align: TextAlign.right),
                _headerCell('vs TARGET', flex: 3, t: t, align: TextAlign.right),
              ],
            ),
          ),
          Divider(height: 1, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.line,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.productionTon.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      r.intensity.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _VsTargetBadge(percent: r.vsTargetPercent, t: t),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _headerCell(String label, {required int flex, required FlutterFlowTheme t, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: t.txtSubtle),
      ),
    );
  }
}

class _VsTargetBadge extends StatelessWidget {
  const _VsTargetBadge({required this.percent, required this.t});

  final double percent;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    final aboveTarget = percent > 0;
    final color = aboveTarget ? t.error : t.success;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(aboveTarget ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
