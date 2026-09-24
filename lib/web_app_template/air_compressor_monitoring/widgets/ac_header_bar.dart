import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

const List<String> kAcTimeRanges = ['15m', '1h', '6h', '1D', '7D'];

/// Breadcrumb + live clock + time-range chips + icon buttons + status chips
/// header for the Air Compressor Monitoring dashboard.
class AcHeaderBar extends StatelessWidget {
  const AcHeaderBar({
    super.key,
    required this.liveTime,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final DateTime liveTime;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('SF365', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: t.txtMuted)),
                  _breadcrumbChevron(t),
                  Text('LOT 237B', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: t.txtMuted)),
                  _breadcrumbChevron(t),
                  Text(
                    'Compressed Air Command Center',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLight ? t.txtPrimary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF0D1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: t.txtMuted),
                  const SizedBox(width: 7),
                  Text(
                    DateFormat('dd MMM yyyy HH:mm:ss').format(liveTime),
                    style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF0D1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final range in kAcTimeRanges)
                    _RangeChip(
                      label: range,
                      selected: range == selectedRange,
                      onTap: () => onRangeChanged(range),
                      t: t,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _iconButton(Icons.download_rounded, t, isLight),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _iconButton(Icons.notifications_none_rounded, t, isLight),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(color: Color(0xFFE74852), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('12', style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            _iconButton(Icons.help_outline_rounded, t, isLight),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('WT', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _breadcrumbChevron(FlutterFlowTheme t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.chevron_right_rounded, size: 15, color: t.txtSubtle),
      );

  Widget _iconButton(IconData icon, FlutterFlowTheme t, bool isLight) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: Icon(icon, size: 17, color: t.txtMuted),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.selected, required this.onTap, required this.t});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : t.txtMuted),
        ),
      ),
    );
  }
}
