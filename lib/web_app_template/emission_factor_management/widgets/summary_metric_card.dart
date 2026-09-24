import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class SummaryMetricCard extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData? icon;
  final Color? accentColor;

  const SummaryMetricCard({
    super.key,
    required this.label,
    required this.valueWidget,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = accentColor ?? t.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : const Color(0xFF0D1B3E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE2E8F0)
              : accent.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withOpacity(0.05)
                : accent.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label row
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: t.secondaryText.withOpacity(0.6)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: t.secondaryText.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Value
          valueWidget,
          // Subtitle
          if (subtitleWidget != null) ...[
            const SizedBox(height: 5),
            subtitleWidget!,
          ] else if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: t.secondaryText.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
