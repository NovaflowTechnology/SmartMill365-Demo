import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class KanbanFormFieldWidget extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final double labelWidth;

  const KanbanFormFieldWidget({
    required this.label,
    required this.child,
    this.required = false,
    this.labelWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (required)
                Text('* ',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      fontFamily: 'Poppins',
                      color: FlutterFlowTheme.of(context).primaryText,
                      font: GoogleFonts.poppins(),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}