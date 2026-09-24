import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/card_widget/card_widget.dart';

class SecMachineCardWidget extends StatelessWidget {
  final String machineName;

  /// Equipment type shown as a subtitle under the machine name, e.g. "Die Casting Machine".
  final String machineType;
  final String meterId;
  final double secValue;
  final double targetSec;
  final bool isLoading;

  /// False when this machine has no entries yet in the kWh/Tonne Data Log —
  /// `secValue`/variance would otherwise be a meaningless placeholder, so the
  /// card shows a "pending production data" notice instead of the gauge.
  final bool hasProductionData;

  /// Device-discovery connectivity fields (FacilityData.onlineStatus / lastSeen).
  /// Empty string is treated as "live" — most facilities don't populate this yet.
  final String onlineStatus;
  final String lastSeen;

  /// Today's cumulative readings. Default to 0 when not wired up by the caller.
  final double cumulativeKwh;
  final double cumulativeTonnage;

  /// No backing data source exists yet for equipment run time; callers can
  /// pass a real "hh:mm" once available, otherwise a placeholder is shown.
  final String runTimeLabel;

  /// Variance thresholds (%) that drive the HIGH/MEDIUM/LOW severity pill,
  /// matching the fleet-wide warning/critical tolerances set in the overview tab.
  final double warningPct;
  final double criticalPct;

  final VoidCallback? onMenuTap;

  const SecMachineCardWidget({
    super.key,
    required this.machineName,
    this.machineType = '',
    required this.meterId,
    required this.secValue,
    required this.targetSec,
    this.isLoading = false,
    this.hasProductionData = true,
    this.onlineStatus = '',
    this.lastSeen = '',
    this.cumulativeKwh = 0,
    this.cumulativeTonnage = 0,
    this.runTimeLabel = '--:--',
    this.warningPct = 10,
    this.criticalPct = 20,
    this.onMenuTap,
  });

  /// A target of 0 means the machine hasn't had "Target kWh / Tonne"
  /// configured yet in Equipment Settings (energy module) — treated as a
  /// distinct "not configured" state rather than a variance of 0%/"GOOD".
  bool get _hasTarget => targetSec > 0;

  double get _variancePct => _hasTarget ? ((secValue - targetSec) / targetSec * 100) : 0.0;

  bool get _isOverTarget => _variancePct > 0;

  Color get _glowColor {
    if (!_hasTarget) return const Color(0xFF9CA3AF);
    return _isOverTarget ? const Color(0xFFFF4444) : const Color(0xFF00D4FF);
  }

  String get _severityLabel {
    if (!_hasTarget) return 'NOT SET';
    if (!_isOverTarget) return 'GOOD';
    if (_variancePct > criticalPct) return 'HIGH';
    if (_variancePct > warningPct) return 'MEDIUM';
    return 'LOW';
  }

  Color get _severityColor {
    switch (_severityLabel) {
      case 'NOT SET':
        return const Color(0xFF9CA3AF);
      case 'HIGH':
        return const Color(0xFFFF4444);
      case 'MEDIUM':
        return const Color(0xFFFFC107);
      case 'LOW':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF00C853);
    }
  }

  bool get _isLive {
    final v = onlineStatus.trim().toLowerCase();
    return v.isEmpty || v == 'online' || v == 'active';
  }

  String get _updatedLabel {
    final dt = DateTime.tryParse(lastSeen);
    if (dt == null) return 'just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      glowColor: _glowColor,
      topPadMultiplier: 1.0,
      bottomPadMultiplier: 1.0,
      armLenMultiplier: 0.7,
      builder: (context, s) {
        if (isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: _glowColor.withOpacity(0.6),
              strokeWidth: s.strokeW * 3,
            ),
          );
        }

        final isLight = Theme.of(context).brightness == Brightness.light;
        final theme = FlutterFlowTheme.of(context);
        final varColor = !_hasTarget ? const Color(0xFFFFC107) : (_isOverTarget ? const Color(0xFFFF4444) : const Color(0xFF00C853));
        final dimText = isLight ? theme.secondaryText : Colors.white38;
        final mainText = isLight ? theme.primaryText : Colors.white;
        final boxBorder = isLight ? theme.alternate : Colors.white12;
        final scaleMax = [secValue, targetSec, 1.0].reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(s, dimText, mainText),
            SizedBox(height: s.pad * 0.5),

            // ── Total efficiency gauge ────────────────────────────────────
            Expanded(
              flex: 5,
              child: _box(
                border: boxBorder,
                child: _EfficiencyGauge(
                  s: s,
                  secValue: secValue,
                  targetSec: targetSec,
                  scaleMax: scaleMax,
                  dimText: dimText,
                  mainText: mainText,
                  hasProductionData: hasProductionData,
                ),
              ),
            ),
            SizedBox(height: s.pad * 0.4),

            // ── Variance banner ───────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: s.pad * 0.5, vertical: s.pad * 0.25),
                decoration: BoxDecoration(
                  color: varColor.withOpacity(0.08),
                  border: Border.all(color: varColor.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: !_hasTarget
                  ? Row(children: [
                      Container(
                        padding: EdgeInsets.all(s.pad * 0.2),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: varColor.withOpacity(0.18)),
                        child: Icon(Icons.warning_amber_rounded, size: s.bodyFs, color: varColor),
                      ),
                      SizedBox(width: s.pad * 0.4),
                      Expanded(
                        child: Text(
                          'Target not configured — set it in Equipment Settings',
                          style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.85, fontWeight: FontWeight.w600, color: mainText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ])
                  : Row(children: [
                  Container(
                    padding: EdgeInsets.all(s.pad * 0.2),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: varColor.withOpacity(0.18)),
                    child: Icon(
                      _isOverTarget ? Icons.trending_up : Icons.check_circle_rounded,
                      size: s.bodyFs,
                      color: varColor,
                    ),
                  ),
                  SizedBox(width: s.pad * 0.4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('VARIANCE',
                            style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.75, fontWeight: FontWeight.w700, color: varColor, letterSpacing: 0.8)),
                        Text(
                          '${_isOverTarget ? '+' : ''}${_variancePct.toStringAsFixed(2)}%',
                          style: GoogleFonts.poppins(fontSize: s.labelFs * 1.05, fontWeight: FontWeight.w700, color: varColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s.pad * 0.5),
                  Expanded(
                    child: Text(
                      _isOverTarget ? 'Above Target' : 'Below Target',
                      style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.85, color: mainText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: s.pad * 0.4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: s.pad * 0.4, vertical: s.pad * 0.15),
                    decoration: BoxDecoration(
                      color: _severityColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _severityLabel,
                      style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.75, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ),
                ]),
              ),
            ),
            SizedBox(height: s.pad * 0.4),

            // ── Footer: today's energy | today's production | run time ────
            Expanded(
              flex: 2,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _footerStat(
                        s: s,
                        icon: Icons.bolt,
                        iconColor: const Color(0xFF00D4FF),
                        label: "TODAY'S ENERGY",
                        value: cumulativeKwh.toStringAsFixed(1),
                        unit: 'kWh',
                        dimText: dimText,
                        mainText: mainText,
                      ),
                    ),
                    VerticalDivider(width: s.pad * 0.6, thickness: 1, color: boxBorder),
                    Expanded(
                      child: _footerStat(
                        s: s,
                        icon: Icons.factory,
                        iconColor: const Color(0xFF00C853),
                        label: "TODAY'S PRODUCTION",
                        value: cumulativeTonnage.toStringAsFixed(1),
                        unit: 'tonne',
                        dimText: dimText,
                        mainText: mainText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: s.pad * 0.3),

            // ── Note ─────────────────────────────────────────────────────────
            Row(children: [
              Icon(Icons.info_outline, size: s.bodyFs * 0.9, color: dimText),
              SizedBox(width: s.pad * 0.25),
              Expanded(
                child: Text(
                  'Note: Efficiency = Cumulative kWh Today ÷ Cumulative Tonnage Today',
                  style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.75, color: dimText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _box({required Color border, required Widget child}) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      );

  Widget _footerStat({
    required CardSizing s,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required Color dimText,
    required Color mainText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(icon, size: s.bodyFs, color: iconColor),
          SizedBox(width: s.pad * 0.25),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.7, fontWeight: FontWeight.w600, color: iconColor, letterSpacing: 0.4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        SizedBox(height: s.pad * 0.15),
        // Fixed size (no per-column FittedBox) so the three stats read at the
        // same scale regardless of how wide their value/label text is —
        // independent scaling made e.g. "08:30 hh:mm" render smaller than
        // "123.4 kWh" whenever one column had less spare width than another.
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: [
            TextSpan(text: value, style: GoogleFonts.poppins(fontSize: s.labelFs, fontWeight: FontWeight.w700, color: mainText)),
            TextSpan(text: ' $unit', style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.8, color: dimText)),
          ]),
        ),
      ],
    );
  }

  // ── Header: icon + name/subtitle + LIVE/updated (top-right) ────────────────
  Widget _buildHeader(CardSizing s, Color dimText, Color mainText) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(s.pad * 0.3),
            decoration: BoxDecoration(
              border: Border.all(color: _glowColor.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.bolt, size: s.labelFs, color: _glowColor),
          ),
          SizedBox(width: s.pad * 0.4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  machineName,
                  style: GoogleFonts.poppins(
                    fontSize: s.labelFs,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (machineType.isNotEmpty) ...[
                  SizedBox(height: s.pad * 0.1),
                  Text(
                    machineType,
                    style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.85, color: dimText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: s.pad * 0.4),
          Row(children: [
            Container(
              width: s.bodyFs * 0.35,
              height: s.bodyFs * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLive ? const Color(0xFF00C853) : Colors.white24,
              ),
            ),
            SizedBox(width: s.pad * 0.25),
            Text(
              _isLive ? 'LIVE' : 'OFFLINE',
              style: GoogleFonts.poppins(
                fontSize: s.bodyFs * 0.85,
                fontWeight: FontWeight.w700,
                color: _isLive ? const Color(0xFF00C853) : Colors.white24,
              ),
            ),
            SizedBox(width: s.pad * 0.3),
            Text('|', style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.85, color: dimText)),
            SizedBox(width: s.pad * 0.3),
            Text(
              'Updated: $_updatedLabel',
              style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.85, color: dimText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
          if (onMenuTap != null) ...[
            SizedBox(width: s.pad * 0.3),
            GestureDetector(
              onTap: onMenuTap,
              child: Icon(Icons.more_vert, size: s.labelFs, color: dimText),
            ),
          ],
        ],
      );
}

// ── Total efficiency gauge box ──────────────────────────────────────────────
class _EfficiencyGauge extends StatelessWidget {
  final CardSizing s;
  final double secValue;
  final double targetSec;
  final double scaleMax;
  final Color dimText;
  final Color mainText;

  /// False when this machine has no kWh/Tonne log entries dated today —
  /// shown as a "pending production data" notice instead of secValue.
  final bool hasProductionData;

  const _EfficiencyGauge({
    required this.s,
    required this.secValue,
    required this.targetSec,
    required this.scaleMax,
    required this.dimText,
    required this.mainText,
    this.hasProductionData = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetSec > 0;
    final targetRatio = (hasTarget && scaleMax > 0) ? (targetSec / scaleMax).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'TOTAL EFFICIENCY',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.8, fontWeight: FontWeight.w600, color: dimText, letterSpacing: 1.0),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Expanded(
          child: Center(
            child: hasProductionData
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        TextSpan(
                            text: secValue.toStringAsFixed(1),
                            style: GoogleFonts.poppins(fontSize: s.w * 0.11, fontWeight: FontWeight.w700, color: mainText, height: 1.1)),
                        TextSpan(text: ' kWh/tonne', style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.85, fontWeight: FontWeight.w500, color: dimText)),
                      ]),
                    ),
                  )
                : LayoutBuilder(builder: (context, cons) {
                    // Wrap at the box's actual width first (so the message reads
                    // as two lines), then let FittedBox scale that block down —
                    // without this, FittedBox's unbounded measurement pass would
                    // lay the text out on one line and shrink it to near-illegible.
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: cons.maxWidth.isFinite ? cons.maxWidth - s.pad : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pending_actions_rounded, size: s.w * 0.06, color: const Color(0xFFFFC107)),
                            SizedBox(height: s.pad * 0.25),
                            Text(
                              'Pending production data — no entries logged yet for this machine',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.8, fontWeight: FontWeight.w600, color: const Color(0xFFFFC107)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
          ),
        ),
        Text(
          'Current Unit Consumption (Cumulative)',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.7, color: dimText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: s.pad * 0.25),
        LayoutBuilder(builder: (ctx, cons) {
          final w = cons.maxWidth;
          final markerLeft = (w * targetRatio - 1).clamp(0.0, w - 2);
          return SizedBox(
            width: double.infinity,
            height: 8,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFFFFC107), Color(0xFFFF4444)]),
                ),
              ),
              if (hasTarget)
                Positioned(
                  left: markerLeft,
                  top: -2,
                  child: Container(width: 2, height: 12, color: Colors.white),
                ),
            ]),
          );
        }),
        SizedBox(height: s.pad * 0.2),
        Row(children: [
          Expanded(
            child: Text('0', style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.7, color: dimText), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(
              hasTarget ? 'TARGET ${targetSec.toStringAsFixed(1)}' : 'TARGET NOT SET',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.7, fontWeight: FontWeight.w600, color: hasTarget ? const Color(0xFF00C853) : const Color(0xFFFFC107)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              scaleMax.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: s.bodyFs * 0.7, color: dimText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ],
    );
  }
}
