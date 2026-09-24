import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CalculationFormulaPanel extends StatefulWidget {
  final double activeGridFactor;
  final String facilityName;

  const CalculationFormulaPanel({
    super.key,
    required this.activeGridFactor,
    this.facilityName = 'Kedah Facility',
  });

  @override
  State<CalculationFormulaPanel> createState() =>
      _CalculationFormulaPanelState();
}

class _CalculationFormulaPanelState extends State<CalculationFormulaPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0D1832).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE2E8F0)
              : t.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header toggle
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: t.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SCOPE 2 CALCULATION FORMULA (ACTIVE FACTOR APPLIED)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isLight
                          ? const Color(0xFF64748B)
                          : t.secondaryText.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: t.secondaryText.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: isLight
                  ? const Color(0xFFE2E8F0)
                  : t.primary.withOpacity(0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formula boxes row
                  LayoutBuilder(builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;
                    return isNarrow
                        ? _formulaColumnLayout(t, isLight)
                        : _formulaRowLayout(t, isLight);
                  }),
                  const SizedBox(height: 14),
                  // Sample calculations
                  _sampleCalcLine(t, isLight),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formulaRowLayout(dynamic t, bool isLight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _formulaBox('DEVICE KWH', 'X,XXX kWh', t, isLight)),
        _operatorText('×', t),
        Expanded(
            child: _formulaBox(
                'ACTIVE GRID FACTOR',
                widget.activeGridFactor.toStringAsFixed(3),
                t,
                isLight,
                accent: true)),
        _operatorText('÷', t),
        Expanded(
            child: _formulaBox('UNIT CONVERT', '1,000', t, isLight)),
        _operatorText('=', t),
        Expanded(
            child: _formulaBox('SCOPE 2 TCO₂E', 'X.XXX tCO₂e', t, isLight,
                isResult: true)),
      ],
    );
  }

  Widget _formulaColumnLayout(dynamic t, bool isLight) {
    return Column(
      children: [
        _formulaBox('DEVICE KWH', 'X,XXX kWh', t, isLight),
        const SizedBox(height: 4),
        _operatorText('× (ACTIVE GRID FACTOR: ${widget.activeGridFactor.toStringAsFixed(3)})', t,
            isCenter: true),
        const SizedBox(height: 4),
        _operatorText('÷ 1,000', t, isCenter: true),
        const SizedBox(height: 4),
        _operatorText('=', t, isCenter: true),
        const SizedBox(height: 4),
        _formulaBox('SCOPE 2 TCO₂E', 'X.XXX tCO₂e', t, isLight,
            isResult: true),
      ],
    );
  }

  Widget _formulaBox(
    String label,
    String value,
    dynamic t,
    bool isLight, {
    bool accent = false,
    bool isResult = false,
  }) {
    final bgColor = isResult
        ? (isLight
            ? t.primary.withOpacity(0.07)
            : t.primary.withOpacity(0.1))
        : accent
            ? (isLight
                ? t.secondary.withOpacity(0.07)
                : t.secondary.withOpacity(0.1))
            : (isLight
                ? Colors.white
                : const Color(0xFF0B1530).withOpacity(0.6));

    final borderColor = isResult
        ? t.primary.withOpacity(isLight ? 0.25 : 0.3)
        : accent
            ? t.secondary.withOpacity(isLight ? 0.25 : 0.3)
            : (isLight
                ? const Color(0xFFE2E8F0)
                : t.primary.withOpacity(0.1));

    final valueColor = isResult
        ? t.primary
        : accent
            ? t.secondary
            : (isLight ? const Color(0xFF1E293B) : t.primaryText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isLight
                  ? const Color(0xFF64748B)
                  : t.secondaryText.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _operatorText(String op, dynamic t,
      {bool isCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        op,
        textAlign: isCenter ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: t.secondaryText.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _sampleCalcLine(dynamic t, bool isLight) {
    final factor = widget.activeGridFactor;
    final td9Daily = (1910 * factor / 1000);
    final msbMonthly = (2431810 * factor / 1000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF1F5F9)
            : t.primaryBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE2E8F0)
              : t.primary.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 0,
        children: [
          _calcSpan(
              'TD9 daily: ', '1,910 kwh × $factor ÷ 1000 = ${td9Daily.toStringAsFixed(3)} tCO₂e', t, isLight),
          Text(
            '   |   ',
            style: TextStyle(
                color: t.secondaryText.withOpacity(0.25), fontSize: 13),
          ),
          _calcSpan(
              'MSB monthly: ',
              '2,431,810 kwh × $factor ÷ 1000 = ${msbMonthly.toStringAsFixed(1)} tCO₂e',
              t,
              isLight),
        ],
      ),
    );
  }

  Widget _calcSpan(String prefix, String value, dynamic t, bool isLight) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Poppins',
          color: t.secondaryText.withOpacity(0.55),
        ),
        children: [
          TextSpan(
            text: prefix,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: t.secondaryText.withOpacity(0.55),
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
