import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../emission_factor_model.dart';

class ActivateConfirmDialog extends StatelessWidget {
  final EmissionFactor factor;
  final VoidCallback onConfirm;

  const ActivateConfirmDialog({
    super.key,
    required this.factor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final factorLabel = factor.factor != null
        ? '${factor.factor!.toStringAsFixed(3)} kgCO₂e/kWh'
        : '— kgCO₂e/kWh';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF0D1526),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight
                ? const Color(0xFFE2E8F0)
                : t.primary.withOpacity(0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, t, isLight, factorLabel),
            _buildWarningBanner(t, isLight),
            _buildInfoBox(t, isLight),
            _buildFooter(context, t, isLight),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic t,
    bool isLight,
    String factorLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activate Emission Factor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isLight ? const Color(0xFF0F172A) : t.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: t.secondaryText.withOpacity(0.75),
              ),
              children: [
                const TextSpan(text: 'You are about to activate the '),
                TextSpan(
                  text: factor.fiscalYearLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' emission factor ('),
                TextSpan(
                  text: factorLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ') for all Scope 2 calculations.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(dynamic t, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(isLight ? 0.08 : 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFFF59E0B),
                  ),
                  children: [
                    TextSpan(text: 'This will '),
                    TextSpan(
                      text: 'replace the current active factor',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' and trigger immediate recalculation of all Scope 2 CO₂e figures. Previous values will be tagged ',
                    ),
                    TextSpan(
                      text: 'Restated',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(dynamic t, bool isLight) {
    const bullets = [
      'Replace any existing Active factor for this FY',
      'Apply to all real-time Scope 2 CO₂e calculations immediately',
      'Recalculate all historical data for this FY (tagged Restated if replacing)',
      'Log this action permanently in the Audit Log',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight
              ? const Color(0xFFF1F5F9)
              : t.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLight
                ? const Color(0xFFE2E8F0)
                : t.primary.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: t.secondaryText.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  'Activating this factor will:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLight
                        ? const Color(0xFF334155)
                        : t.primaryText.withOpacity(0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: t.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isLight
                                ? const Color(0xFF475569)
                                : t.secondaryText.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, dynamic t, bool isLight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: t.secondaryText,
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text(
              'Confirm Activate',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor:
                  isLight ? Colors.white : const Color(0xFF0A0E1A),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
