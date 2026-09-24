import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

const Color _cCyan = Color(0xFF00E5FF);

/// Meter picker chrome shared with the Bill Simulator — a cyan accent bar
/// beside a borderless [DropdownButton] inside a bordered pill.
class TblCyberpunkDropdown extends StatelessWidget {
  final String? value;
  final List<String> options;
  final String hint;
  final double width;
  final ValueChanged<String?> onChanged;
  final String Function(String)? labelBuilder;

  const TblCyberpunkDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.hint,
    required this.width,
    required this.onChanged,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    final safeValue = (value != null && options.contains(value)) ? value : null;

    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
        border: Border.all(color: isLight ? theme.alternate : _cCyan.withOpacity(0.5), width: 1.2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: _cCyan.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: isLight ? theme.primary : _cCyan,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
              boxShadow: [BoxShadow(color: (isLight ? theme.primary : _cCyan).withOpacity(0.8), blurRadius: 6)],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: safeValue,
                  isExpanded: true,
                  dropdownColor: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
                  menuMaxHeight: 300,
                  hint: Text(
                    hint,
                    style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : _cCyan.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: GoogleFonts.poppins(color: isLight ? theme.txtPrimary : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: isLight ? theme.primary : _cCyan, size: 22),
                  items: options
                      .map((opt) => DropdownMenuItem<String>(
                            value: opt,
                            child: Text(
                              labelBuilder?.call(opt) ?? opt,
                              style: GoogleFonts.poppins(color: isLight ? theme.txtPrimary : Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
