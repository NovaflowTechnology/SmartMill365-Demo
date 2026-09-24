import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/md_prediction/services/md_prediction_service.dart';

// ---------------------------------------------------------------------------
// Active Equipment Panel
// ---------------------------------------------------------------------------
// Shows all active facility meters with their impact category, live kW usage,
// and highlights "ADJUSTABLE" machines when an MD overflow risk is predicted.

class ActiveEquipmentPanel extends StatelessWidget {
  final List<ActiveEquipmentData> equipment;
  final double contractLimitKw;
  final bool isOverLimit;
  final bool showHeader;

  const ActiveEquipmentPanel({
    super.key,
    required this.equipment,
    required this.contractLimitKw,
    required this.isOverLimit,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (equipment.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          _buildHeader(),
          const SizedBox(height: 12),
        ],
        ...equipment.map((e) => _EquipmentRow(
              data: e,
              contractLimitKw: contractLimitKw,
              isOverLimit: isOverLimit,
            )),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF00C6FF),
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x6600C6FF), blurRadius: 6, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'ACTIVE EQUIPMENT',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00C6FF),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 0.5,
            color: const Color(0xFF00C6FF).withOpacity(0.25),
          ),
        ),
        const SizedBox(width: 12),
        _CategoryLegend(color: const Color(0xFF10B981), label: 'ADJUSTABLE'),
        const SizedBox(width: 12),
        _CategoryLegend(color: const Color(0xFF64748B), label: 'PRODUCTION'),
        const SizedBox(width: 12),
        _CategoryLegend(color: const Color(0xFFF59E0B), label: 'AUXILIARY'),
        const SizedBox(width: 12),
        _CategoryLegend(color: const Color(0xFF6366F1), label: 'BACKUP'),
      ],
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _CategoryLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EquipmentRow extends StatelessWidget {
  final ActiveEquipmentData data;
  final double contractLimitKw;
  final bool isOverLimit;

  static const _categoryColors = {
    'ADJUSTABLE': Color(0xFF10B981),
    'PRODUCTION': Color(0xFF64748B),
    'AUXILIARY':  Color(0xFFF59E0B),
    'BACKUP':     Color(0xFF6366F1),
  };

  const _EquipmentRow({
    required this.data,
    required this.contractLimitKw,
    required this.isOverLimit,
  });

  Color get _catColor =>
      _categoryColors[data.impactCategory] ?? const Color(0xFF64748B);

  bool get _isHighlighted =>
      isOverLimit && data.impactCategory == 'ADJUSTABLE';

  double get _usageFraction {
    if (contractLimitKw <= 0 || data.currentKw <= 0) return 0.0;
    return (data.currentKw / contractLimitKw).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isHighlighted
                  ? const Color(0xFFFF4444).withOpacity(0.06)
                  : const Color(0xFF0D1B2E).withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHighlighted
                    ? const Color(0xFFFF4444).withOpacity(0.4)
                    : _catColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: _isHighlighted
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF4444).withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Category dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHighlighted
                        ? const Color(0xFFFF4444)
                        : _catColor,
                    boxShadow: [
                      BoxShadow(
                        color: (_isHighlighted
                                ? const Color(0xFFFF4444)
                                : _catColor)
                            .withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Meter name + location
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.meterName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isHighlighted
                              ? const Color(0xFFFF4444)
                              : Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${data.meterId}${data.plant.isNotEmpty ? " · ${data.plant}" : ""}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_isHighlighted
                            ? const Color(0xFFFF4444)
                            : _catColor)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (_isHighlighted
                              ? const Color(0xFFFF4444)
                              : _catColor)
                          .withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _isHighlighted ? 'SHUTDOWN?' : data.impactCategory,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _isHighlighted
                          ? const Color(0xFFFF4444)
                          : _catColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // kW + progress bar
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        data.currentKw > 0
                            ? '${data.currentKw.toStringAsFixed(1)} kW'
                            : '—',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isHighlighted
                              ? const Color(0xFFFF4444)
                              : const Color(0xFF00C6FF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MiniProgressBar(
                        fraction: _usageFraction,
                        color: _isHighlighted
                            ? const Color(0xFFFF4444)
                            : _catColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double fraction;
  final Color color;
  const _MiniProgressBar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      return Container(
        height: 3,
        width: c.maxWidth,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 0),
              ],
            ),
          ),
        ),
      );
    });
  }
}
