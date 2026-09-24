import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cast_line_models.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class EfficiencyGapWidget extends StatelessWidget {
  final EfficiencyGapModel gap;

  const EfficiencyGapWidget({Key? key, required this.gap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 4, 51, 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE53935), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gap.message,
              style: GoogleFonts.poppins(
                color: const Color(0xFFE53935),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
