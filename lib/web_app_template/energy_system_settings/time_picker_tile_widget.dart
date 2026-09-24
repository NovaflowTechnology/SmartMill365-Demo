import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class TimePickerTileWidget extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const TimePickerTileWidget({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 13,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
            Row(
              children: [
                Text(
                  _formatTimeDisplay(time),
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
