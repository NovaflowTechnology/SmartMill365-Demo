import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

const Color _cCyan = Color(0xFF00E5FF);

/// 14D / 30D / 90D display-range segmented control.
class TblRangeToggle extends StatelessWidget {
  static const List<int> rangeOptions = [14, 30, 90];

  final int selectedDays;
  final ValueChanged<int> onChanged;

  const TblRangeToggle({super.key, required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: isLight ? theme.alternate : _cCyan.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (final days in rangeOptions) _buildOption(theme, days)],
      ),
    );
  }

  Widget _buildOption(FlutterFlowTheme theme, int days) {
    final selected = selectedDays == days;
    return GestureDetector(
      onTap: () => onChanged(days),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? _cCyan.withOpacity(0.14) : Colors.transparent),
        child: Text(
          '${days}D',
          style: GoogleFonts.poppins(
            color: selected ? _cCyan : theme.secondaryText,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
