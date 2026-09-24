import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/counter_button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RowCounterWidget extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const RowCounterWidget({
    required this.label,
    required this.current,
    required this.max,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ($current/$max)',
          style: TextStyle(
            color: FlutterFlowTheme.of(context).primaryText,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            CounterButtonWidget(
              icon: Icons.add,
              onTap: onAdd,
              color: primary,
            ),
            const SizedBox(width: 8),
            CounterButtonWidget(
              icon: Icons.remove,
              onTap: onRemove,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}
