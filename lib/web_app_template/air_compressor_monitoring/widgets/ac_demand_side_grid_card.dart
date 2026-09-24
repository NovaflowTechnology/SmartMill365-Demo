import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';

/// "Demand Side (7 CAST)" card — one small tile per cast/consumer, each
/// showing its flow reading or a "No data" placeholder while Phase 1 demand
/// metering isn't wired up yet.
class AcDemandSideGridCard extends StatelessWidget {
  const AcDemandSideGridCard({super.key, required this.points});

  final List<AcCastPoint> points;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    const amber = Color(0xFFF59E0B);

    return DashboardCard(
      title: 'DEMAND SIDE (${points.length} CAST)',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: amber.withOpacity(isLight ? 0.12 : 0.18), borderRadius: BorderRadius.circular(5)),
        child: Text('SPEC PENDING', style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, color: amber)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final perRow = constraints.maxWidth < 480
            ? 2
            : constraints.maxWidth < 720
                ? 4
                : points.length;
        final tileW = (constraints.maxWidth - (perRow - 1) * 8) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in points) SizedBox(width: tileW, child: _CastTile(point: p, t: t, isLight: isLight)),
          ],
        );
      }),
    );
  }
}

class _CastTile extends StatelessWidget {
  const _CastTile({required this.point, required this.t, required this.isLight});

  final AcCastPoint point;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            point.label,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            point.hasData ? '${point.value!.toStringAsFixed(1)} m³/min' : '-- m³/min',
            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: t.txtSubtle),
          ),
          if (point.reqPressure != null || point.reqFlow != null) ...[
            const SizedBox(height: 2),
            Text(
              'Req: ${point.reqPressure?.toStringAsFixed(1) ?? '--'} bar · ${point.reqFlow?.toStringAsFixed(1) ?? '--'} m³/min',
              style: GoogleFonts.poppins(fontSize: 8, color: t.txtSubtle),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFE8EFF6) : const Color(0xFF1A2D4F),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              point.hasData ? 'Live' : 'No data',
              style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w600, color: t.txtMuted),
            ),
          ),
        ],
      ),
    );
  }
}
