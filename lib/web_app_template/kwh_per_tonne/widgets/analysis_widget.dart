import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cast_line_models.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class AnalysisWidget extends StatelessWidget {
  final AnalysisModel analysis;

  const AnalysisWidget({Key? key, required this.analysis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
       color: const Color.fromRGBO(0, 4, 51, 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.secondaryText, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 17),
                children: [
                  TextSpan(text: '${analysis.analysisText} '),
                  TextSpan(
                    text: analysis.suggestion,
                    style: GoogleFonts.poppins(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}