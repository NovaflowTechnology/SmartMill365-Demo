import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

/// Report title/date block on the left, plant selector + Download Report
/// button on the right (space-between; stacks vertically below ~700px wide).
class ReportHeader extends StatelessWidget {
  final String reportDateLabel;
  final String periodLabel;
  final List<String> plantOptions;
  final String selectedPlant;
  final ValueChanged<String> onPlantChanged;
  final bool isGenerating;
  final VoidCallback onDownload;

  /// True while a newly-selected period's report data is still being
  /// fetched. The download button stays disabled during this window so it
  /// can't capture the previous period's still-on-screen numbers.
  final bool isLoadingReport;

  /// Historical report month picker (e.g. "Jun 2026", "Jul 2026"), rendered
  /// to the left of the plant dropdown. [periodOptions] is most-recent-first.
  final List<String> periodOptions;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  /// True when [selectedPeriod] is showing a closed month's permanent,
  /// locked snapshot (auto-logged at month rollover) rather than a live
  /// recompute — shown as a small badge so it's clear why the numbers won't
  /// change even if settings are edited later.
  final bool isPeriodLocked;

  /// Opens the plant-photo/footer-logo image settings editor. Optional so
  /// callers that don't support it (none currently) can omit the button.
  final VoidCallback? onConfigureImages;

  /// Opens the "View Logs" dialog listing past report generations. Optional
  /// so callers that don't support it can omit the button.
  final VoidCallback? onViewLogs;

  const ReportHeader({
    super.key,
    required this.reportDateLabel,
    required this.periodLabel,
    required this.plantOptions,
    required this.selectedPlant,
    required this.onPlantChanged,
    required this.periodOptions,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.isPeriodLocked = false,
    required this.isGenerating,
    required this.onDownload,
    this.isLoadingReport = false,
    this.onConfigureImages,
    this.onViewLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(builder: (context, constraints) {
      final titleBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MAX DEMAND INSIGHT REPORT',
            style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isLight ? theme.txtPrimary : Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Report Date: $reportDateLabel   •   Period: $periodLabel',
            style:
                GoogleFonts.poppins(fontSize: 13.5, color: theme.secondaryText),
          ),
        ],
      );
      final controlsBlock = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _periodDropdown(context),
          const SizedBox(width: 12),
          _plantDropdown(context),
          const SizedBox(width: 12),
          _downloadButton(context),
          if (onViewLogs != null) ...[
            const SizedBox(width: 12),
            _iconButton(context, icon: Icons.history_rounded, onTap: onViewLogs!),
          ],
          if (onConfigureImages != null) ...[
            const SizedBox(width: 12),
            _iconButton(context, icon: Icons.settings_outlined, onTap: onConfigureImages!),
          ],
        ],
      );

      final isWide = constraints.maxWidth > 700;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: titleBlock),
            const SizedBox(width: 16),
            controlsBlock
          ],
        );
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleBlock, const SizedBox(height: 12), controlsBlock]);
    });
  }

  /// Historical report month picker — same bordered dropdown treatment as
  /// [_plantDropdown], just narrower since labels are short ("Jul 2026").
  Widget _periodDropdown(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    const cyan = Color(0xFF00D4FF);
    return Container(
      width: 150,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
        border: Border.all(
            color: isLight ? theme.alternate : cyan.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Lock icon in place of the usual calendar icon while viewing a
          // closed month's permanent snapshot — same slot, so the dropdown
          // doesn't shift width when the badge toggles on/off.
          Tooltip(
            message: isPeriodLocked
                ? 'Locked historical record — this month is closed and won\'t change'
                : '',
            child: Icon(
              isPeriodLocked
                  ? Icons.lock_rounded
                  : Icons.calendar_month_rounded,
              size: 16,
              color: isPeriodLocked
                  ? (isLight ? theme.primary : cyan)
                  : (isLight ? theme.secondaryText : cyan.withOpacity(0.8)),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: periodOptions.contains(selectedPeriod) ? selectedPeriod : null,
                hint: Text(selectedPeriod,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: isLight ? theme.txtPrimary : Colors.white)),
                dropdownColor:
                    isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: isLight ? theme.primary : cyan),
                items: periodOptions
                    .map((p) => DropdownMenuItem<String>(
                          value: p,
                          child: Text(p,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: isLight ? theme.txtPrimary : Colors.white)),
                        ))
                    .toList(),
                onChanged: (p) {
                  if (p != null) onPeriodChanged(p);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plantDropdown(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    const cyan = Color(0xFF00D4FF);
    return Container(
      width: 220,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
        border: Border.all(
            color: isLight ? theme.alternate : cyan.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedPlant,
          dropdownColor:
              isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isLight ? theme.primary : cyan),
          items: plantOptions
              .map((p) => DropdownMenuItem<String>(
                    value: p,
                    child: Text(p,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: isLight ? theme.txtPrimary : Colors.white)),
                  ))
              .toList(),
          onChanged: (p) {
            if (p != null) onPlantChanged(p);
          },
        ),
      ),
    );
  }

  /// Icon-only twin of [_downloadButton]'s bordered box treatment — shared
  /// by the "View Logs" and "Configure Images" buttons.
  Widget _iconButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    const cyan = Color(0xFF00D4FF);
    final accent = isLight ? theme.primary : cyan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
            border: Border.all(
                color: isLight ? theme.alternate : accent.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
      ),
    );
  }

  /// Same bordered/filter-chip treatment as [_plantDropdown] — a dark box
  /// with a thin accent border — instead of a solid filled button, so the
  /// two header controls read as one consistent style.
  Widget _downloadButton(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    const cyan = Color(0xFF00D4FF);
    final accent = isLight ? theme.primary : cyan;
    final isBusy = isGenerating || isLoadingReport;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onDownload,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: isBusy ? 0.6 : 1.0,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isLight
                  ? theme.secondaryBackground
                  : const Color(0xFF071A2E),
              border: Border.all(
                  color: isLight ? theme.alternate : accent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isBusy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: accent))
                    : Icon(Icons.download_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Download Report',
                  style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isLight ? theme.txtPrimary : Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
