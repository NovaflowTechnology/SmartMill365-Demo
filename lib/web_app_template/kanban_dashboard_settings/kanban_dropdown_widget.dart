import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class KanbanDropdownWidget extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const KanbanDropdownWidget({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF001055),
        style: TextStyle(
          color: FlutterFlowTheme.of(context).primaryText,
          fontSize: 13,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
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
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
      ),
    );
  }
}