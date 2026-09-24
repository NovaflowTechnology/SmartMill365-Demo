import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';

/// What the unsaved prices would do to this month's settlement, pinned to the
/// bottom of the page so the effect of a change is in view while making it.
///
/// Always dark, whatever the theme: it is a status strip over the page rather
/// than a panel on it, and it has to stand apart from the panels scrolling
/// behind it.
class ImpactBar extends StatelessWidget {
  const ImpactBar({
    super.key,
    required this.title,
    required this.peakKwh,
    required this.offPeakKwh,
    required this.savedPeakRm,
    required this.draftPeakRm,
    required this.savedOffPeakRm,
    required this.draftOffPeakRm,
    required this.loading,
    required this.message,
    required this.messageOk,
    required this.saving,
    required this.onSave,
  });

  final String title;
  final double? peakKwh;
  final double? offPeakKwh;

  /// Null when that side has no price — nothing saved yet, or nothing entered.
  final double? savedPeakRm;
  final double? draftPeakRm;
  final double? savedOffPeakRm;
  final double? draftOffPeakRm;
  final bool loading;
  final String message;
  final bool messageOk;
  final bool saving;
  final VoidCallback? onSave;

  static const _bg = Color(0xFF06152A);
  static const _muted = Color(0xFF8EA3C0);
  static const _faint = Color(0xFF5D7699);
  static const _up = Color(0xFF7EE2B8);

  static double? _sum(double? a, double? b) =>
      a == null && b == null ? null : (a ?? 0) + (b ?? 0);

  @override
  Widget build(BuildContext context) {
    final savedTotal = _sum(savedPeakRm, savedOffPeakRm);
    final draftTotal = _sum(draftPeakRm, draftOffPeakRm);

    final figures = [
      _Figure(
        label: title,
        saved: savedTotal,
        draft: draftTotal,
        big: true,
        loading: loading,
      ),
      _Figure(
        label: 'Peak · ${SettlementFormat.kwh(peakKwh)}',
        saved: savedPeakRm,
        draft: draftPeakRm,
        loading: loading,
        dot: SettlementColors.peak,
      ),
      _Figure(
        label: 'Non-Peak · ${SettlementFormat.kwh(offPeakKwh)}',
        saved: savedOffPeakRm,
        draft: draftOffPeakRm,
        loading: loading,
        dot: SettlementColors.offPeak,
      ),
    ];

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(messageOk ? Icons.verified_outlined : Icons.warning_amber_rounded,
            size: 16,
            color: messageOk ? _up : SettlementColors.amber),
        const SizedBox(width: 8),
        Flexible(
          child: Text(message,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _muted, height: 1.4)),
        ),
      ],
    );

    final save = SettingButton(
      label: 'Save settings',
      icon: Icons.save_outlined,
      primary: true,
      busy: saving,
      color: SettlementColors.cyan,
      onTap: onSave,
    );

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
            top: BorderSide(color: SettlementColors.cyan.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, c) {
          final pad = c.maxWidth < 620 ? 14.0 : 24.0;
          if (c.maxWidth < 1100) {
            return Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(spacing: 26, runSpacing: 8, children: figures),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: status), save]),
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(pad, 13, pad, 13),
            child: Row(children: [
              for (final f in figures) ...[f, const SizedBox(width: 32)],
              Expanded(child: status),
              const SizedBox(width: 16),
              save,
            ]),
          );
        }),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.saved,
    required this.draft,
    required this.loading,
    this.big = false,
    this.dot,
  });

  final String label;
  final double? saved;
  final double? draft;
  final bool loading;
  final bool big;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final changed = saved != null &&
        draft != null &&
        (saved! - draft!).abs() >= 0.005;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null) ...[
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: ImpactBar._muted)),
        ]),
        const SizedBox(height: 2),
        if (loading)
          Text('calculating…',
              style: GoogleFonts.poppins(
                  fontSize: big ? 17 : 15, color: ImpactBar._faint))
        else
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (changed) ...[
              Text(SettlementFormat.rm(saved),
                  style: GoogleFonts.poppins(
                      fontSize: big ? 13 : 12,
                      color: ImpactBar._faint,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: ImpactBar._faint)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Icon(Icons.arrow_forward,
                    size: 14, color: ImpactBar._faint),
              ),
            ],
            Text(SettlementFormat.rm(draft),
                style: GoogleFonts.poppins(
                    fontSize: big ? 19 : 16,
                    fontWeight: FontWeight.w700,
                    color: changed ? ImpactBar._up : Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
      ],
    );
  }
}
