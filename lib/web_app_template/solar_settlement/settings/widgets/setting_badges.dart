import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';

const _violet = Color(0xFFA78BFA);
const _blue = Color(0xFF3B8EFF);

/// Where a setting's value comes from. Shown on every row, because a price
/// typed here and a value borrowed from another module are edited in very
/// different places, and a reader should never have to guess which.
enum SourceKind { raw, module, price, manual, referenced }

extension SourceKindStyle on SourceKind {
  String get label => switch (this) {
        SourceKind.raw => 'RAW',
        SourceKind.module => 'MODULE',
        SourceKind.price => 'PRICE',
        SourceKind.manual => 'MANUAL',
        SourceKind.referenced => 'LINKED',
      };

  Color get color => switch (this) {
        SourceKind.raw => SettlementColors.cyan,
        SourceKind.module => _violet,
        SourceKind.price => SettlementColors.green,
        SourceKind.manual => SettlementColors.amber,
        SourceKind.referenced => _blue,
      };
}

class SourceTag extends StatelessWidget {
  const SourceTag(this.kind, {super.key});

  final SourceKind kind;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final c = kind.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(p.isLight ? 0.12 : 0.16),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(kind.label,
          style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: c)),
    );
  }
}

enum StatusKind { ok, warn, linked, error }

/// A row's state in one glyph: set, needs attention, linked elsewhere, or
/// wrong.
class StatusDot extends StatelessWidget {
  const StatusDot(this.kind, {super.key, this.tooltip});

  final StatusKind kind;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (kind) {
      StatusKind.ok => (SettlementColors.green, Icons.check_rounded),
      StatusKind.warn => (SettlementColors.amber, Icons.priority_high_rounded),
      StatusKind.linked => (_blue, Icons.link_rounded),
      StatusKind.error => (SettlementColors.red, Icons.close_rounded),
    };
    final dot = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Icon(icon, size: 15, color: color),
    );
    return tooltip == null ? dot : Tooltip(message: tooltip!, child: dot);
  }
}

/// A value that lives in another module, stated with the link colour so it
/// reads as a reference and not as something editable here.
class LinkedText extends StatelessWidget {
  const LinkedText(this.text, {super.key, this.icon = Icons.link_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: _blue),
      const SizedBox(width: 6),
      Flexible(
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w500, color: _blue)),
      ),
    ]);
  }
}

/// Explanatory text in a table cell.
class QuietText extends StatelessWidget {
  const QuietText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Text(text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
            fontSize: 12.5, color: color ?? p.mutedText, height: 1.35));
  }
}

/// A row's name, with an optional line saying what it feeds.
class SettingNameCell extends StatelessWidget {
  const SettingNameCell(this.title, {super.key, this.sub, this.dot});

  final String title;
  final String? sub;

  /// Colour dot before the title — used for the peak and non-peak tiers so
  /// they carry the same colour here as on the dashboard.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          if (dot != null) ...[
            Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
          ),
        ]),
        if (sub != null && sub!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(sub!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11.5, color: p.mutedText)),
          ),
      ],
    );
  }
}

/// The page's buttons. [primary] fills with the accent; [ghost] has no box.
class SettingButton extends StatelessWidget {
  const SettingButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.ghost = false,
    this.busy = false,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool ghost;
  final bool busy;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final accent = color ?? p.accent;
    final enabled = onTap != null && !busy;
    final fg = primary
        ? (p.isLight ? Colors.white : const Color(0xFF04121F))
        : (ghost ? p.subText : accent);
    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: primary
                ? accent
                : ghost
                    ? Colors.transparent
                    : accent.withOpacity(p.isLight ? 0.08 : 0.12),
            borderRadius: BorderRadius.circular(9),
            border: ghost
                ? null
                : Border.all(color: accent.withOpacity(primary ? 1 : 0.5)),
            boxShadow: primary && !p.isLight
                ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 12)]
                : const [],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (busy)
              SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            else if (icon != null)
              Icon(icon, size: 17, color: fg),
            if (busy || icon != null) const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
          ]),
        ),
      ),
    );
  }
}
