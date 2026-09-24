import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class KanbanTextFieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;

  const KanbanTextFieldWidget({this.controller, this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: FlutterFlowTheme.of(context).primaryText,
          fontSize: 13,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFF001055),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),
      ),
    );
  }
}
