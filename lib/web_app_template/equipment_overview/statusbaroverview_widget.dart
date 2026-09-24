import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/card_widget/card_widget.dart';

class StatusbaroverviewWidget extends StatefulWidget {
  final int running;
  final int alarm;
  final int idle;
  final int offline;
  final int stopped;

  const StatusbaroverviewWidget({
    super.key,
    required this.running,
    required this.alarm,
    required this.idle,
    required this.offline,
    required this.stopped,
  });

  @override
  State<StatusbaroverviewWidget> createState() =>
      _StatusbaroverviewWidgetState();
}

class _StatusbaroverviewWidgetState extends State<StatusbaroverviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _statusCard(
          label: 'RUNNING',
          count: widget.running,
          icon: Icons.bolt_rounded,
          color: const Color(0xFF00FF6A),
        ),
        _statusCard(
          label: 'IDLE',
          count: widget.idle,
          icon: Icons.hourglass_bottom_rounded,
          color: const Color(0xFFFBBC05),
        ),
        _statusCard(
          label: 'STOPPED',
          count: widget.stopped,
          icon: Icons.do_not_disturb_on_rounded,
          color: const Color(0xFFFF1515),
        ),
        _statusCard(
          label: 'ALARM',
          count: widget.alarm,
          icon: Icons.crisis_alert_rounded,
          color: const Color(0xFFE64A19),
        ),
        _statusCard(
          label: 'OFFLINE',
          count: widget.offline,
          icon: Icons.wifi_off_rounded,
          color: const Color(0xFF90A4AE),
        ),
      ],
    );
  }

  Widget _statusCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: CardWidget(
          glowColor: color,
          topPadMultiplier: 0.45,
          bottomPadMultiplier: 0.45,
          armLenMultiplier: 0.4,
          blurSigma: 4,
          builder: (context, s) {
            final isLight = Theme.of(context).brightness == Brightness.light;
            return Column(
              children: [
                // Top neon scan line
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        color.withOpacity(0.9),
                        color.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon in sharp cyber
                      //punk box
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          border: Border.all(
                            color: color.withOpacity(0.38),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isLight ? null : [
                            BoxShadow(
                              color: color.withOpacity(0.28),
                              blurRadius: 14,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20,
                          shadows: isLight ? null : [
                            Shadow(color: color, blurRadius: 14),
                          ],
                        ),
                      ),
                      SizedBox(width: s.pad * 0.55),
                      // Label + Count
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.poppins(
                                color: color.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  shadows: isLight ? null : [
                                    Shadow(color: color.withOpacity(0.6), blurRadius: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom neon scan line (dimmer)
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        color.withOpacity(0.3),
                        color.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
