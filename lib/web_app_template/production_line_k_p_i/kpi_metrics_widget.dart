import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class KpiMetricsWidget extends StatelessWidget {
  final int totalMachines;
  final double averageOee;
  final int totalOutput;
  final double uptime;

  const KpiMetricsWidget({
    super.key,
    this.totalMachines = 30,
    this.averageOee = 78.5,
    this.totalOutput = 24580,
    this.uptime = 92.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              context,
              'Total Machines',
              totalMachines.toString(),
              '',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKpiCard(
              context,
              'Average OEE',
              '${averageOee.toStringAsFixed(1)}%',
              '',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKpiCard(
              context,
              'Total Output',
              _formatNumber(totalOutput),
              '',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKpiCard(
              context,
              'Uptime',
              '${uptime.toStringAsFixed(1)}%',
              '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).alternate, // Using theme color instead of Colors.white
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Slightly more visible shadow for dark theme
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  fontFamily: 'Poppins',
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 14,
                  font: GoogleFonts.poppins(),
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineLarge.override(
                  fontFamily: 'Poppins',
                  color: FlutterFlowTheme.of(context).primary, // Using theme primary color instead of hardcoded blue
                  fontSize: 32,
                  font: GoogleFonts.poppins(),
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 12,
                    font: GoogleFonts.poppins(),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}
