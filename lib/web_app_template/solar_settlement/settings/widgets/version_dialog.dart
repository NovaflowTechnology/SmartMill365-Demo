import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/settlement_pricing.dart';
import '../../models/settlement_config.dart';
import '../../solar_settlement_theme.dart';
import 'setting_badges.dart';
import 'setting_inputs.dart';

class VersionChoice {
  const VersionChoice({required this.version, required this.effectiveFrom});

  final int version;
  final DateTime effectiveFrom;
}

/// Picks which version the prices on the page will be saved as, and the month
/// it takes effect from. Nothing is published until the page is saved.
class VersionEditDialog extends StatefulWidget {
  const VersionEditDialog({
    super.key,
    required this.publishedVersion,
    required this.draftVersion,
    required this.effectiveFrom,
    required this.createNew,
    required this.plantName,
  });

  /// Highest version saved so far; zero when none is.
  final int publishedVersion;
  final int draftVersion;
  final DateTime effectiveFrom;
  final bool createNew;
  final String plantName;

  static Future<VersionChoice?> show(
    BuildContext context, {
    required int publishedVersion,
    required int draftVersion,
    required DateTime effectiveFrom,
    required bool createNew,
    required String plantName,
  }) =>
      showDialog<VersionChoice>(
        context: context,
        builder: (_) => VersionEditDialog(
          publishedVersion: publishedVersion,
          draftVersion: draftVersion,
          effectiveFrom: effectiveFrom,
          createNew: createNew,
          plantName: plantName,
        ),
      );

  @override
  State<VersionEditDialog> createState() => _VersionEditDialogState();
}

class _VersionEditDialogState extends State<VersionEditDialog> {
  late bool _createNew =
      widget.publishedVersion > 0 && widget.createNew;
  late DateTime _month = widget.effectiveFrom;

  int get _target => widget.publishedVersion == 0
      ? 1
      : _createNew
          ? widget.publishedVersion + 1
          : widget.draftVersion.clamp(1, widget.publishedVersion);

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final now = DateTime.now();
    final months = [
      for (var i = -24; i <= 12; i++) DateTime(now.year, now.month + i, 1),
    ];
    if (!months.any((m) => m == _month)) months.insert(0, _month);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: p.cardDecoration(raised: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DialogTitle(
                  icon: Icons.edit_calendar_outlined, title: 'Settlement version'),
              const SizedBox(height: 8),
              Text(
                'Prices change and past invoices must not change with them. '
                'A new version prices months from its effective date onward; '
                'earlier months keep the version they were settled under.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: p.subText, height: 1.45),
              ),
              const SizedBox(height: 18),
              if (widget.publishedVersion > 0)
                Wrap(spacing: 10, runSpacing: 10, children: [
                  _Choice(
                    selected: !_createNew,
                    label:
                        'Update ${SettlementPricing.versionLabel(widget.plantName, widget.draftVersion.clamp(1, widget.publishedVersion))}',
                    onTap: () => setState(() => _createNew = false),
                  ),
                  _Choice(
                    selected: _createNew,
                    label:
                        'Create ${SettlementPricing.versionLabel(widget.plantName, widget.publishedVersion + 1)}',
                    onTap: () => setState(() => _createNew = true),
                  ),
                ]),
              const SizedBox(height: 16),
              Text('EFFECTIVE FROM',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: p.mutedText)),
              const SizedBox(height: 6),
              SettingDropdown<DateTime>(
                value: _month,
                options: [
                  for (final m in months)
                    SettingOption(m, '01 ${SettlementFormat.monthLabel(m)}'),
                ],
                onChanged: (m) => setState(() => _month = m),
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                SettingButton(
                    label: 'Cancel',
                    ghost: true,
                    onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 10),
                SettingButton(
                  label:
                      'Use ${SettlementPricing.versionLabel(widget.plantName, _target)}',
                  primary: true,
                  onTap: () => Navigator.of(context).pop(
                      VersionChoice(version: _target, effectiveFrom: _month)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every version saved, newest first.
class VersionHistoryDialog extends StatelessWidget {
  const VersionHistoryDialog({
    super.key,
    required this.versions,
    required this.plantName,
  });

  final List<RateVersion> versions;
  final String plantName;

  static Future<void> show(
    BuildContext context, {
    required List<RateVersion> versions,
    required String plantName,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) =>
            VersionHistoryDialog(versions: versions, plantName: plantName),
      );

  String _tier(RateTier t) => t.mode == PricingMode.tnbFactor
      ? 'TNB × ${t.factor.toStringAsFixed(2)}'
      : 'RM ${t.price.toStringAsFixed(t.decimals)}';

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final sorted = [...versions]..sort((a, b) => b.version - a.version);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: p.cardDecoration(raised: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DialogTitle(icon: Icons.history, title: 'Version history'),
              const SizedBox(height: 14),
              if (sorted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No version has been saved yet.',
                      style: GoogleFonts.poppins(
                          fontSize: 13.5, color: p.mutedText)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: p.border),
                    itemBuilder: (_, i) {
                      final v = sorted[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    SettlementPricing.versionLabel(
                                        plantName, v.version),
                                    style: GoogleFonts.robotoMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: p.text)),
                                const SizedBox(height: 2),
                                Text(
                                  'Effective ${SettlementFormat.dayLabel(v.effectiveFrom)}'
                                  '${v.savedAt == null ? '' : '  ·  saved ${SettlementFormat.dayLabel(v.savedAt!.toLocal())}'}'
                                  '${v.savedBy.isEmpty ? '' : ' by ${v.savedBy}'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: p.mutedText),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Peak  ${_tier(v.peak)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: SettlementColors.peak)),
                              Text('Non-Peak  ${_tier(v.offPeak)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: SettlementColors.offPeak)),
                            ],
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: SettingButton(
                    label: 'Close', onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: p.iconChip(p.accent),
        child: Icon(icon, size: 18, color: p.accent),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
      ),
      IconButton(
        tooltip: 'Close',
        icon: Icon(Icons.close, size: 19, color: p.subText),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ]);
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.accent.withOpacity(0.14) : p.panel,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: selected ? p.accent : p.border,
              width: selected ? 1.4 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16, color: selected ? p.accent : p.subText),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? p.accent : p.text)),
        ]),
      ),
    );
  }
}
