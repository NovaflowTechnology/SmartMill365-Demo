import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Sci-fi / cyberpunk styled top-center warning toast for the login flow.
///
/// Usage:
///   showCyberpunkWarningToast(context, 'Your message here');
void showCyberpunkWarningToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _CyberpunkWarningToast(
      message: message,
      duration: duration,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _CyberpunkWarningToast extends StatefulWidget {
  const _CyberpunkWarningToast({
    required this.message,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_CyberpunkWarningToast> createState() => _CyberpunkWarningToastState();
}

class _CyberpunkWarningToastState extends State<_CyberpunkWarningToast>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final AnimationController _glowController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final neonPrimary = theme.primary;
    final neonAccent = theme.primary;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 24,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _offset,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final glow = 0.4 + (_glowController.value * 0.5);
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 460),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0A0A1F).withOpacity(0.95),
                              const Color(0xFF14142B).withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: neonAccent.withOpacity(glow),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: neonAccent.withOpacity(glow * 0.7),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: neonPrimary.withOpacity(glow * 0.4),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left neon bar
                        Container(
                          width: 3,
                          height: 38,
                          decoration: BoxDecoration(
                            color: neonAccent,
                            boxShadow: [
                              BoxShadow(
                                color: neonAccent.withOpacity(0.9),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.warning_amber_rounded,
                          color: neonAccent,
                          size: 24,
                          shadows: [
                            Shadow(
                              color: neonAccent.withOpacity(0.9),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '// SYSTEM ALERT',
                                style: GoogleFonts.shareTechMono(
                                  color: neonAccent,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
