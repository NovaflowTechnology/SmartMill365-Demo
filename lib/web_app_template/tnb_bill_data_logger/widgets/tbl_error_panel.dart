import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

const Color _cCyan = Color(0xFF00E5FF);
const Color _cRed = Color(0xFFF87171);

/// Centered "failed to load" card with a retry action, shown in place of
/// the page body when the initial fetch errors out.
class TblErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TblErrorPanel({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2040).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cRed.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _cRed, size: 32),
            const SizedBox(height: 10),
            Text('FAILED TO LOAD', style: GoogleFonts.poppins(color: _cRed, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _cCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cCyan.withOpacity(0.5)),
                ),
                child: Text('RETRY', style: GoogleFonts.poppins(color: _cCyan, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
