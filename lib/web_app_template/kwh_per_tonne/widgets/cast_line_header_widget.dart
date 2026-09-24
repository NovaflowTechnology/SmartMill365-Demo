import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cast_line_models.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CastLineHeaderWidget extends StatelessWidget {
  final CastLineModel castLine;
  final Color backgroundColor;

  const CastLineHeaderWidget({
    Key? key,
    required this.castLine,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
          // Title
          Text(
            castLine.title,
            style: GoogleFonts.poppins(
              color: backgroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitle
          Text(
            castLine.subtitle,
            style: GoogleFonts.poppins(
              color: theme.secondaryText,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),

          // kWh/Tonne value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'kWh/Tonne',
                style: GoogleFonts.poppins(
                  color: theme.secondaryText,
                  fontSize: 17,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    castLine.kwhPerTonne.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      color: backgroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 33,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      'kWh/t',
                      style: GoogleFonts.poppins(
                        color: theme.secondaryText,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Optimal badge
          if (castLine.isOptimal) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00C853).withOpacity(0.6)),
              ),
              child: Text(
                '✓ OPTIMAL',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00C853),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.6)),
              ),
              child: Text(
                '⚠ NEEDS IMPROVEMENT',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFC107),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}