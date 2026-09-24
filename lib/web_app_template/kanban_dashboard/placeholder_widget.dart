// ─────────────────────────────────────────────────────────────────────────────
// _Placeholder — shown for unmapped widgetTypes
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/cell_state_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class PlaceholderWidget extends StatelessWidget {
  final String widgetName;
  final String widgetType;
  final CellStateModel state;

  const PlaceholderWidget({
    required this.widgetName,
    required this.widgetType,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    return Container(
      color: isLight ? theme.primaryBackground : const Color(0xFF050F40),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widgetName.isNotEmpty ? widgetName : widgetType,
            style: TextStyle(
              color: isLight ? theme.primary : const Color(0xFF6A8AFF),
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widgetType,
            style: TextStyle(
              color: isLight ? theme.txtTertiary : const Color(0xFF3A5ACC),
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          if (state.isLoading)
            Center(
              child: CircularProgressIndicator(
                color: isLight ? theme.primary.withOpacity(0.4) : Colors.white24,
                strokeWidth: 2,
              ),
            )
          else if (state.error != null)
            Center(
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            )
          else
            Center(
              child: Icon(
                Icons.bar_chart_outlined,
                color: isLight ? theme.txtSubtle : const Color(0xFF1A3A7A),
                size: 40,
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}