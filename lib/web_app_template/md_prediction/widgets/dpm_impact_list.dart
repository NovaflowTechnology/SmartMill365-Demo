import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/md_prediction/services/md_prediction_service.dart';

// ---------------------------------------------------------------------------
// DPM Impact Model
// ---------------------------------------------------------------------------

class DpmImpact {
  final ActiveEquipmentData equipment;
  final double impactKw;
  final double loadFraction;

  const DpmImpact({
    required this.equipment,
    required this.impactKw,
    required this.loadFraction,
  });

  String get impactLabel => '${impactKw.toStringAsFixed(0)} kW';
  bool get isAdjustable => equipment.impactCategory == 'ADJUSTABLE';
  bool get isRunning => impactKw > 0.5;
}

// ---------------------------------------------------------------------------
// DPM Impact List — matches Khor's example design
// ---------------------------------------------------------------------------

class DpmImpactList extends StatefulWidget {
  final List<DpmImpact> impacts;
  final double predictedPeak;
  final double exceedKw;
  final bool isOverLimit;

  const DpmImpactList({
    super.key,
    required this.impacts,
    required this.predictedPeak,
    this.exceedKw = 0.0,
    required this.isOverLimit,
  });

  @override
  State<DpmImpactList> createState() => _DpmImpactListState();
}

class _DpmImpactListState extends State<DpmImpactList> {
  bool _acknowledged = false;
  DateTime? _snoozedUntil;

  bool get _isSnoozed =>
      _snoozedUntil != null && DateTime.now().isBefore(_snoozedUntil!);

  bool get _showWarning =>
      widget.isOverLimit && !_acknowledged && !_isSnoozed;

  void _snooze(Duration d) {
    setState(() => _snoozedUntil = DateTime.now().add(d));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.impacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off_outlined,
                color: Colors.white.withOpacity(0.2), size: 28),
            const SizedBox(height: 8),
            Text(
              'No equipment data yet',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      );
    }

    final running    = widget.impacts.where((d) => d.isRunning).toList();
    final adjustable = running.where((d) => d.isAdjustable).toList();
    final totalKw    = running.fold(0.0, (s, d) => s + d.impactKw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Stats row: RUNNING | ADJUSTABLE | TOTAL KW NOW ────────────────
        _buildStatsRow(running.length, adjustable.length, totalKw),
        const SizedBox(height: 10),

        // ── "CURRENTLY RUNNING" label ──────────────────────────────────────
        Text(
          'CURRENTLY RUNNING',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),

        // ── Equipment rows ─────────────────────────────────────────────────
        ...widget.impacts.map((d) => _DpmRow(
              impact: d,
              isOverLimit: widget.isOverLimit,
            )),

        // ── Amber warning banner ──────────────────────────────────────────
        if (_showWarning) ...[
          const SizedBox(height: 10),
          _buildWarningBanner(),
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildStatsRow(int running, int adjustable, double totalKw) {
    return Row(
      children: [
        _StatCell(label: 'RUNNING', value: '$running'),
        _StatDivider(),
        _StatCell(
          label: 'ADJUSTABLE',
          value: '$adjustable',
          valueColor: const Color(0xFF10B981),
        ),
        _StatDivider(),
        _StatCell(
          label: 'TOTAL KW NOW',
          value: totalKw.toStringAsFixed(0),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFFFFC107).withOpacity(0.35), width: 1),
      ),
      child: Text(
        'This block is forecast to exceed your contract MD limit. '
        'If actual MD does exceed, this block alone will set the TNB demand '
        'surcharge for the entire month.',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: const Color(0xFFFFC107),
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            label: 'Acknowledge',
            onTap: () => setState(() => _acknowledged = true),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ActionBtn(
            label: 'Snooze 5 min',
            onTap: () => _snooze(const Duration(minutes: 5)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ActionBtn(
            label: 'Snooze 15 min',
            onTap: () => _snooze(const Duration(minutes: 15)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white.withOpacity(0.9),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: Colors.white.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// DPM Row — matches Khor's example
// ---------------------------------------------------------------------------

class _DpmRow extends StatelessWidget {
  final DpmImpact impact;
  final bool isOverLimit;

  static const _catColors = {
    'ADJUSTABLE': Color(0xFF10B981),
    'PRODUCTION': Color(0xFF64748B),
    'AUXILIARY':  Color(0xFF22D3EE),
    'BACKUP':     Color(0xFFF97316),
  };

  const _DpmRow({required this.impact, required this.isOverLimit});

  Color get _catColor =>
      _catColors[impact.equipment.impactCategory] ?? const Color(0xFF64748B);

  bool get _isShutdownCandidate =>
      isOverLimit && impact.isAdjustable && impact.isRunning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _isShutdownCandidate
              ? const Color(0xFFFF4444).withOpacity(0.05)
              : const Color(0xFF0D1B2E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: impact.isRunning
                  ? (_isShutdownCandidate
                      ? const Color(0xFFFF4444)
                      : _catColor)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // ── Status dot ───────────────────────────────────────────────
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: impact.isRunning
                    ? (_isShutdownCandidate
                        ? const Color(0xFFFF4444)
                        : _catColor)
                    : Colors.white.withOpacity(0.18),
                boxShadow: impact.isRunning
                    ? [
                        BoxShadow(
                          color: (_isShutdownCandidate
                                  ? const Color(0xFFFF4444)
                                  : _catColor)
                              .withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 10),

            // ── Name + specs + running duration ───────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${impact.equipment.meterId} · ${impact.equipment.meterName}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isShutdownCandidate
                          ? const Color(0xFFFF6B6B)
                          : impact.isRunning
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.35),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _buildSubtitle(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.35),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── kW value ──────────────────────────────────────────────────
            if (impact.isRunning)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  impact.impactLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isShutdownCandidate
                        ? const Color(0xFFFF4444)
                        : Colors.white.withOpacity(0.85),
                  ),
                ),
              ),

            // ── Category badge ────────────────────────────────────────────
            _CategoryBadge(
              category: _isShutdownCandidate
                  ? 'SHUTDOWN?'
                  : impact.equipment.impactCategory,
              isRunning: impact.isRunning,
              color: _isShutdownCandidate
                  ? const Color(0xFFFF4444)
                  : _catColor,
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (impact.equipment.meterId.isNotEmpty) parts.add(impact.equipment.meterId);
    if (impact.equipment.specs.isNotEmpty) parts.add(impact.equipment.specs);
    if (impact.isRunning && impact.equipment.runningSince != null) {
      final mins =
          DateTime.now().difference(impact.equipment.runningSince!).inMinutes;
      if (mins >= 60) {
        final h = mins ~/ 60;
        final m = mins % 60;
        parts.add('running ${h}h ${m.toString().padLeft(2, '0')}m');
      } else if (mins > 0) {
        parts.add('running ${mins} min');
      }
    } else if (!impact.isRunning) {
      if (impact.equipment.plant.isNotEmpty) parts.add(impact.equipment.plant);
    }
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Category Badge — ADJUSTABLE = filled green pill; others = plain text
// ---------------------------------------------------------------------------

class _CategoryBadge extends StatelessWidget {
  final String category;
  final bool isRunning;
  final Color color;
  const _CategoryBadge(
      {required this.category, required this.isRunning, required this.color});

  bool get _isAdjustable => category == 'ADJUSTABLE' || category == 'SHUTDOWN?';

  @override
  Widget build(BuildContext context) {
    if (!isRunning) {
      // Idle — show plain dimmed text
      return Text(
        'IDLE',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.2),
          letterSpacing: 0.5,
        ),
      );
    }

    if (_isAdjustable) {
      // Filled pill — prominent green (or red for shutdown)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    // PRODUCTION / AUXILIARY / BACKUP — plain text, no box
    return Text(
      category,
      style: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: color.withOpacity(0.65),
        letterSpacing: 0.5,
      ),
    );
  }
}
