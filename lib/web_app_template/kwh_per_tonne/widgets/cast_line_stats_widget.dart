import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cast_line_models.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CastLineStatsWidget extends StatelessWidget {
  final CastLineModel castLine;
  final Color valueColor;

  const CastLineStatsWidget({
    Key? key,
    required this.castLine,
    required this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
     decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 4, 51, 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE SEC (KWH/TONNE)',
            style: GoogleFonts.poppins(
              color: theme.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                castLine.kwhPerTonne.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 41,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kWh/T',
                  style: GoogleFonts.poppins(
                    color: theme.secondaryText,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 12),
          _statRow(context, 'Main Extruder Drive', castLine.mainExtruderDrive, 'kW'),
          _statRow(context, 'Heating Zones', castLine.heatingZones, 'kW'),
          _statRow(context, 'Auxiliaries/Fans', castLine.auxiliariesFans, 'kW'),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, double value, String unit) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(color: theme.primaryText, fontSize: 17)),
          Text('${value.toStringAsFixed(1)} $unit',
              style: GoogleFonts.poppins(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 17)),
        ],
      ),
    );
  }
}