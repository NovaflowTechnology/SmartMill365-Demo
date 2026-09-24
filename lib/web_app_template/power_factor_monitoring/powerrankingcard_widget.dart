import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';

import 'powerrankingcard_model.dart';
export 'powerrankingcard_model.dart';

class PowerrankingcardWidget extends StatefulWidget {
  final String order;
  final String title;
  final bool isLoading;
  final ValueChanged<String> onOrderChanged;
  final List<dynamic> rankingDevices;

  const PowerrankingcardWidget({
    super.key,
    required this.order,
    required this.title,
    required this.isLoading,
    required this.rankingDevices,
    required this.onOrderChanged,
  });

  @override
  State<PowerrankingcardWidget> createState() => _PowerrankingcardWidgetState();
}

class _PowerrankingcardWidgetState extends State<PowerrankingcardWidget> {
  late PowerrankingcardModel _model;

  static const List<Color> _barColors = [
    Color(0xFF06B6D4),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFF14B8A6),
  ];

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerrankingcardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String addCommas(String numberStr) {
    List<String> parts = numberStr.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match m) => ',',
    );
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = widget.rankingDevices
        .where((device) => device['device'].toString() != 'MSB')
        .toList();

    double maxEnergy = 0;
    for (final device in filteredDevices) {
      final val = (device['total_energy'] as num).toDouble();
      if (val > maxEnergy) maxEnergy = val;
    }

    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: sizing.accentW,
                      height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.9),
                            blurRadius: sizing.pad * 0.7,
                            spreadRadius: sizing.accentW * 0.3,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: sizing.pad * 0.5),
                    Text(
                      widget.title.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: sizing.titleFs.clamp(11.0, 13.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: widget.order == 'asc'
                      ? const Icon(Icons.arrow_circle_up, size: 24)
                      : const Icon(Icons.arrow_circle_down, size: 24),
                  onPressed: () {
                    final newOrder = widget.order == 'asc' ? 'desc' : 'asc';
                    widget.onOrderChanged(newOrder);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Column Headers ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      'Equipment',
                      style: GoogleFonts.poppins(
                        color: theme.info,
                        fontSize: sizing.bodyFs.clamp(9.0, 11.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Energy (kWh)',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        color: theme.info,
                        fontSize: sizing.bodyFs.clamp(9.0, 11.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Device Rows ──────────────────────────────────────
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: filteredDevices.asMap().entries.map((entry) {
                          final i = entry.key;
                          final device = entry.value;
                          final double energy = (device['total_energy'] as num).toDouble();
                          final double normalizedValue = maxEnergy > 0 ? (energy / maxEnergy).clamp(0.0, 1.0) : 0.0;
                          final Color barColor = _barColors[i % _barColors.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildDeviceRow(
                              context: context,
                              rank: i + 1,
                              deviceName: device['device'].toString(),
                              energyLabel: addCommas(energy.toStringAsFixed(4)),
                              normalizedValue: normalizedValue,
                              barColor: barColor,
                              sizing: sizing,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceRow({
    required BuildContext context,
    required int rank,
    required String deviceName,
    required String energyLabel,
    required double normalizedValue,
    required Color barColor,
    required CardSizing sizing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: barColor, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: barColor),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    deviceName,
                    style: GoogleFonts.poppins(
                      fontSize: sizing.bodyFs.clamp(10.0, 12.0),
                      fontWeight: FontWeight.w500,
                      color: barColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Text(
                energyLabel,
                style: GoogleFonts.poppins(fontSize: sizing.bodyFs.clamp(9.0, 11.0), fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 44,
            width: constraints.maxWidth,
            child: CustomPaint(painter: _GlowBarPainter(value: normalizedValue, barColor: barColor)),
          ),
        ),
      ],
    );
  }
}

// ── Glow Bar Painter ─────────────────────────────────────────────────────────
class _GlowBarPainter extends CustomPainter {
  final double value;
  final Color barColor;

  _GlowBarPainter({required this.value, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double barHeight = 10.0;
    const double radius = 2.0;
    final double barTop = (size.height - barHeight) / 2;
    final double filledWidth = value * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, barTop, size.width, barHeight), const Radius.circular(radius)),
      Paint()..color = const Color(0xFF0D1B2A)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, barTop, size.width, barHeight), const Radius.circular(radius)),
      Paint()..color = barColor.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    const int segments = 20;
    final Paint tickPaint = Paint()..color = barColor.withOpacity(0.12)..strokeWidth = 1;
    for (int i = 1; i < segments; i++) {
      final double x = (size.width / segments) * i;
      canvas.drawLine(Offset(x, barTop + 1), Offset(x, barTop + barHeight - 1), tickPaint);
    }

    final Paint bracketPaint = Paint()..color = barColor.withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, barTop - 3), Offset(0, barTop + barHeight + 3), bracketPaint);
    canvas.drawLine(Offset(0, barTop - 3), Offset(6, barTop - 3), bracketPaint);
    canvas.drawLine(Offset(0, barTop + barHeight + 3), Offset(6, barTop + barHeight + 3), bracketPaint);
    canvas.drawLine(Offset(size.width, barTop - 3), Offset(size.width, barTop + barHeight + 3), bracketPaint);
    canvas.drawLine(Offset(size.width, barTop - 3), Offset(size.width - 6, barTop - 3), bracketPaint);
    canvas.drawLine(Offset(size.width, barTop + barHeight + 3), Offset(size.width - 6, barTop + barHeight + 3), bracketPaint);

    if (value <= 0) return;

    final Rect filledRect = Rect.fromLTWH(0, barTop, filledWidth, barHeight);
    final RRect filledRRect = RRect.fromRectAndRadius(filledRect, const Radius.circular(radius));

    canvas.drawRRect(filledRRect, Paint()..color = barColor.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28));
    canvas.drawRRect(filledRRect, Paint()..color = barColor.withOpacity(0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawRRect(filledRRect, Paint()..color = barColor.withOpacity(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawRRect(filledRRect, Paint()..color = barColor.withOpacity(1.0)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawRRect(
      filledRRect,
      Paint()..shader = LinearGradient(
        colors: [barColor.withOpacity(0.8), barColor, const Color(0xFFAAF0FF), Colors.white],
        stops: const [0.0, 0.55, 0.82, 1.0],
      ).createShader(filledRect),
    );

    final Paint segDivPaint = Paint()..color = Colors.black.withOpacity(0.2)..strokeWidth = 1;
    for (int i = 1; i < segments; i++) {
      final double x = (size.width / segments) * i;
      if (x < filledWidth) canvas.drawLine(Offset(x, barTop + 1), Offset(x, barTop + barHeight - 1), segDivPaint);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, barTop, filledWidth, barHeight * 0.45), const Radius.circular(radius)),
      Paint()..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.35), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, barTop, filledWidth, barHeight * 0.45)),
    );

    if (filledWidth > 12) {
      canvas.drawOval(
        Rect.fromLTWH(filledWidth - 10, barTop - 5, 16, barHeight + 10),
        Paint()..color = Colors.white.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawOval(
        Rect.fromLTWH(filledWidth - 6, barTop, 10, barHeight),
        Paint()..color = Colors.white.withOpacity(0.95)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    final double markerX = (filledWidth - 2).clamp(0.0, size.width - 3);
    final RRect markerRRect = RRect.fromRectAndRadius(Rect.fromLTWH(markerX, barTop - 3, 2, barHeight + 6), const Radius.circular(1));
    canvas.drawRRect(markerRRect, Paint()..color = Colors.white.withOpacity(1.0)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawRRect(markerRRect, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_GlowBarPainter oldDelegate) => oldDelegate.value != value || oldDelegate.barColor != barColor;
}
