import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class LineageStep {
  const LineageStep({required this.label, required this.sublabel, required this.state});

  final String label;
  final String sublabel;
  final LineageStepState state;
}

enum LineageStepState { done, here }

/// Static "how this config gets here" trail: Device Discovery → Master
/// Facility Setting → Dashboard Setting (here). Simplified from the
/// reference mockup's 4 steps — this app maps whole Device IDs (Master
/// Facility Setting), not individual fields, so there's no separate
/// "Device Field Mapping" step to show.
class ConfigLineageRow extends StatelessWidget {
  const ConfigLineageRow({super.key, required this.steps});

  final List<LineageStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF071228).withOpacity(0.9);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: t.txtSubtle),
                ),
              _StepChip(step: steps[i], t: t, isLight: isLight),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.step, required this.t, required this.isLight});

  final LineageStep step;
  final FlutterFlowTheme t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final done = step.state == LineageStepState.done;
    final accent = done ? t.success : t.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: accent.withOpacity(isLight ? 0.12 : 0.18), borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Icon(done ? Icons.check_rounded : Icons.radio_button_checked_rounded, size: 13, color: accent),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step.label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: done ? (isLight ? t.txtPrimary : Colors.white) : accent),
            ),
            Text(step.sublabel, style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle)),
          ],
        ),
      ],
    );
  }
}
