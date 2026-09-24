import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';

/// "System Status" card — a 2-column key/value grid plus a "Next
/// Maintenance" footer row.
class AcSystemStatusCard extends StatelessWidget {
  const AcSystemStatusCard({super.key, required this.status});

  final AcSystemStatus status;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DashboardCard(
      title: 'SYSTEM STATUS',
      trailing: Icon(Icons.info_outline_rounded, size: 13, color: t.txtSubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'System Status',
                  value: status.systemStatus ?? 'N/A',
                  color: status.systemStatus == null ? t.txtSubtle : (status.systemStatusGood ? t.success : t.error),
                  t: t,
                  isLight: isLight,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Leakage Status',
                  value: status.leakageStatus ?? 'N/A',
                  color: status.leakageStatus == null ? t.txtSubtle : (status.leakageDetected ? const Color(0xFFF59E0B) : t.success),
                  t: t,
                  isLight: isLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.verified_rounded,
                  label: 'Availability',
                  value: status.availabilityPercent != null ? '${status.availabilityPercent!.toStringAsFixed(1)}%' : 'N/A',
                  color: status.availabilityPercent != null ? (isLight ? t.txtPrimary : Colors.white) : t.txtSubtle,
                  t: t,
                  isLight: isLight,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Total Downtime',
                  value: status.totalDowntimeHr != null ? '${status.totalDowntimeHr!.toStringAsFixed(1)} hr' : 'N/A',
                  color: status.totalDowntimeHr != null ? (isLight ? t.txtPrimary : Colors.white) : t.txtSubtle,
                  t: t,
                  isLight: isLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Dew Point',
                  value: status.dewPointC != null ? '${status.dewPointC!.toStringAsFixed(1)}°C' : 'N/A',
                  color: status.dewPointC != null ? (isLight ? t.txtPrimary : Colors.white) : t.txtSubtle,
                  t: t,
                  isLight: isLight,
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 14, color: t.txtMuted),
              const SizedBox(width: 6),
              Text('Next Maintenance: ', style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted)),
              Text(
                status.nextMaintenance,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.t,
    required this.isLight,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: t.txtMuted),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ],
    );
  }
}
