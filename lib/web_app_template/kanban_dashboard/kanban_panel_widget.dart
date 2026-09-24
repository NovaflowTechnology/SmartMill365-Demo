import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class KanbanPanelWidget extends StatelessWidget {
  const KanbanPanelWidget({required this.onAdd, this.child});

  final VoidCallback onAdd;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : const Color(0xFF060E30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLight ? theme.cardStroke : const Color(0xFF1A2550),
          width: 0.8,
        ),
      ),
      child: child != null
          ? child!
          : Center(
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  color: isLight ? theme.txtMuted : const Color(0xFF4A5580),
                  size: 28,
                ),
                splashRadius: 24,
                tooltip: 'Add widget',
                onPressed: onAdd,
              ),
            ),
    );
  }
}
