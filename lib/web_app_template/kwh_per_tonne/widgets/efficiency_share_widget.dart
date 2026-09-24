import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cast_line_models.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class EfficiencyShareWidget extends StatelessWidget {
  final EfficiencyShareModel share;

  const EfficiencyShareWidget({Key? key, required this.share})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
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
            'RELATIVE ENERGY EFFICIENCY SHARE',
            style: GoogleFonts.poppins(
              color: theme.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (share.lessEfficientRatio * 100).toInt(),
                  child: Container(
                    height: 36,
                    color: const Color(0xFF29B6F6),
                    child: Center(
                      child: Text(
                        share.lessEfficientLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: (100 - (share.lessEfficientRatio * 100).toInt()),
                  child: Container(
                    height: 36,
                    color: const Color(0xFF00C853),
                    child: Center(
                      child: Text(
                        share.optimalLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
