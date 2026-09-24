part of 'plant_energy_command_center_setting_widget.dart';

// ── Cyberpunk sci-fi palette + shared shells ────────────────────────────────────
// Neon-edge styling shared across the whole PECC settings UI so every field,
// card and button reads like the other sci-fi modules (Energy Details, MD
// Prediction). Fills stay on the theme's primaryBackground; the "glow" comes
// from the neon border + soft shadow, with sharp (small-radius) corners.
const Color kCyber  = Color(0xFF00E5FF); // primary neon cyan
const Color kCyber2 = Color(0xFF3B8EFF); // secondary blue

// Field shell: input boxes, dropdowns, text fields.
BoxDecoration cyberField(FlutterFlowTheme theme, {Color accent = kCyber}) =>
    BoxDecoration(
      color: theme.primaryBackground,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
      boxShadow: [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 8)],
    );

// Card shell: section panels, progress card, branding card.
BoxDecoration cyberCard(FlutterFlowTheme theme, {Color accent = kCyber}) =>
    BoxDecoration(
      color: theme.primaryBackground,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: accent.withOpacity(0.22), width: 1),
      boxShadow: [BoxShadow(color: accent.withOpacity(0.06), blurRadius: 16, spreadRadius: -2)],
    );

// ── Status icon chip ───────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final bool isMapped;
  final bool isCalculated;
  const _StatusIcon({required this.isMapped, this.isCalculated = false});

  @override
  Widget build(BuildContext context) {
    if (isCalculated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEAB308).withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.6), width: 1),
          boxShadow: [BoxShadow(color: const Color(0xFFEAB308).withOpacity(0.18), blurRadius: 7)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome, size: 13, color: Color(0xFFEAB308)),
          const SizedBox(width: 5),
          Text('AUTO',
              style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                  color: const Color(0xFFEAB308),
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }
    final color = isMapped ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bg    = isMapped ? const Color(0x2210B981) : const Color(0x22F59E0B);
    final icon  = isMapped ? Icons.check_circle_outline : Icons.radio_button_unchecked;
    final label = isMapped ? 'MAPPED' : 'UNMAPPED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 7)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11.5, letterSpacing: 0.6, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Device dropdown ────────────────────────────────────────────────────────────

class _DeviceDropdown extends StatelessWidget {
  final List<String> devices;
  final String value;
  final bool isLoading;
  final void Function(String?) onChanged;
  final Map<String, String> displayNames;

  const _DeviceDropdown({
    required this.devices,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
    this.displayNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading) {
      return _shell(
        theme: theme,
        child: Row(children: [
          const SizedBox(
            width: 13, height: 13,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: kCyber),
          ),
          const SizedBox(width: 8),
          Text('Loading devices…',
              style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
        ]),
      );
    }

    // Never lose a saved mapping: if the stored device id isn't in the
    // current source lists (e.g. removed from Master Facilities / no SQL
    // rows yet), keep it as a selectable item instead of blanking the row.
    final allDevices = (value.isNotEmpty && !devices.contains(value))
        ? [value, ...devices]
        : devices;

    final items = [
      DropdownMenuItem<String>(
        value: '',
        child: Text('Select device…',
            style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
      ),
      ...allDevices.map((d) {
        final label = displayNames[d];
        return DropdownMenuItem<String>(
          value: d,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null && label.isNotEmpty)
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              Text(d,
                  style: GoogleFonts.poppins(
                      fontSize: label != null && label.isNotEmpty ? 10 : 13,
                      color: label != null && label.isNotEmpty
                          ? theme.txtTertiary
                          : theme.primaryText),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }),
    ];

    return _shell(
      theme: theme,
      padding: EdgeInsets.zero,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? '' : value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kCyber),
          padding: const EdgeInsets.only(left: 12, right: 10),
          items: items,
          onChanged: onChanged,
          dropdownColor: theme.secondaryBackground,
          menuMaxHeight: 360,
          selectedItemBuilder: (_) {
            // Show selected item as "Display Name (ID)" on one clean line.
            final allD = ['', ...allDevices];
            return allD.map((d) {
              if (d.isEmpty) {
                return Text('Select device…',
                    style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted));
              }
              final label = displayNames[d];
              final display = (label != null && label.isNotEmpty) ? '$label ($d)' : d;
              return Text(display,
                  style: GoogleFonts.poppins(fontSize: 12.5, color: theme.primaryText, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis);
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _shell({required FlutterFlowTheme theme, required Widget child, EdgeInsets? padding}) {
    return Container(
      height: 40,
      decoration: cyberField(theme),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        // Left neon accent bar — sci-fi edge cue.
        Container(width: 3, height: 40, color: kCyber.withOpacity(0.8)),
        Expanded(
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
        ),
      ]),
    );
  }
}

// ── Field dropdown ─────────────────────────────────────────────────────────────

class _FieldDropdown extends StatelessWidget {
  final List<String> fields;
  final String value;
  final void Function(String?) onChanged;

  const _FieldDropdown({
    required this.fields,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final items = [
      DropdownMenuItem<String>(
        value: '',
        child: Text('Select field…',
            style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
      ),
      ...fields.map((f) => DropdownMenuItem<String>(
            value: f,
            child: Text(f,
                style: GoogleFonts.poppins(fontSize: 13, color: theme.primaryText),
                overflow: TextOverflow.ellipsis),
          )),
    ];

    return Container(
      height: 40,
      decoration: cyberField(theme, accent: kCyber2),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Container(width: 3, height: 40, color: kCyber2.withOpacity(0.8)),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? '' : value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kCyber2),
              padding: const EdgeInsets.only(left: 12, right: 10),
              items: items,
              onChanged: onChanged,
              dropdownColor: theme.secondaryBackground,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Site (DATA SCOPE) dropdown ──────────────────────────────────────────────────

class _SiteDropdown extends StatelessWidget {
  final List<Map<String, String>> sites;
  final String value;
  final bool isLoading;
  final void Function(String?, String) onChanged;

  const _SiteDropdown({
    required this.sites,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading) {
      return Container(
        height: 40,
        decoration: cyberField(theme),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 15, height: 15,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: kCyber),
        ),
      );
    }

    final items = [
      DropdownMenuItem<String>(
        value: '',
        child: Text('Select DPM Config ID...',
            style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
      ),
      ...sites.map((s) => DropdownMenuItem<String>(
            value: s['id'],
            child: Text(s['label'] ?? s['id'] ?? '',
                style: GoogleFonts.poppins(fontSize: 13, color: theme.primaryText),
                overflow: TextOverflow.ellipsis),
          )),
    ];

    final hasMatch = sites.any((s) => s['id'] == value || s['dbId'] == value);
    final resolvedValue = hasMatch 
        ? (sites.firstWhere((s) => s['id'] == value || s['dbId'] == value)['id'] ?? '')
        : '';

    return Container(
      height: 40,
      decoration: cyberField(theme),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Container(width: 3, height: 40, color: kCyber.withOpacity(0.8)),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: resolvedValue,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kCyber),
              padding: const EdgeInsets.only(left: 12, right: 10),
              items: items,
              onChanged: (id) {
                final match = sites.firstWhere((s) => s['id'] == id, orElse: () => const {});
                final label = match['label'] ?? '';
                onChanged(id, label);
              },
              dropdownColor: theme.secondaryBackground,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Metric (METRIC FIELD) dropdown ──────────────────────────────────────────────

class _MetricDropdown extends StatelessWidget {
  final String value;
  final void Function(String?) onChanged;

  const _MetricDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final items = [
      DropdownMenuItem<String>(
        value: '',
        child: Text('—',
            style: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted)),
      ),
      ..._kPinMetrics.map((m) => DropdownMenuItem<String>(
            value: m.key,
            child: Text(m.label,
                style: GoogleFonts.poppins(fontSize: 13, color: theme.primaryText),
                overflow: TextOverflow.ellipsis),
          )),
    ];

    final hasMatch = _kPinMetrics.any((m) => m.key == value);
    final resolvedValue = hasMatch ? value : '';

    return Container(
      height: 40,
      decoration: cyberField(theme, accent: kCyber2),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Container(width: 3, height: 40, color: kCyber2.withOpacity(0.8)),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: resolvedValue,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kCyber2),
              padding: const EdgeInsets.only(left: 12, right: 10),
              items: items,
              onChanged: onChanged,
              dropdownColor: theme.secondaryBackground,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Outlined button ────────────────────────────────────────────────────────────

class _OutlinedBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _OutlinedBtn({
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border.all(color: kCyber.withOpacity(0.5), width: 1.2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: kCyber.withOpacity(0.12), blurRadius: 8)],
        ),
        child: isLoading
            ? const SizedBox(
                width: 15, height: 15,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: kCyber),
              )
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 16, color: kCyber),
                const SizedBox(width: 7),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        letterSpacing: 0.3,
                        color: kCyber,
                        fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }
}

// ── Primary button ─────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [kCyber, kCyber2],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: kCyber.withOpacity(0.45),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 15, height: 15,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF06182B)),
              )
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 16, color: const Color(0xFF06182B)),
                const SizedBox(width: 7),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        letterSpacing: 0.3,
                        color: const Color(0xFF06182B),
                        fontWeight: FontWeight.w700)),
              ]),
      ),
    );
  }
}

/// A mapping row that takes several meters instead of one.
///
/// The block cards read a whole block, and a block is rarely one meter — so
/// this shows a pill per selected Device ID with a remove action, plus an add
/// menu of the ones not yet picked. The block's total is the sum, worked out on
/// the dashboard rather than typed in anywhere.
///
/// The selection is stored in the same `selectedDevice` field as a single-meter
/// row, comma separated, so nothing about how a configuration is saved, loaded
/// or migrated has to change.
class _MultiDeviceChips extends StatelessWidget {
  const _MultiDeviceChips({
    required this.devices,
    required this.value,
    required this.onChanged,
    required this.displayNames,
    this.isLoading = false,
    this.addLabel = '+ Add meter',
  });

  final List<String> devices;
  final String value;
  final ValueChanged<String> onChanged;
  final Map<String, String> displayNames;
  final bool isLoading;
  final String addLabel;

  List<String> get _selected => value
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selected = _selected;
    final remaining =
        devices.where((d) => !selected.contains(d)).toList(growable: false);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final id in selected)
          Container(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.primary.withOpacity(0.45)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(displayNames[id] ?? id,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText)),
              IconButton(
                icon: const Icon(Icons.close, size: 13),
                color: theme.secondaryText,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 22, minHeight: 22),
                tooltip: 'Remove',
                onPressed: () => onChanged(
                    (selected..remove(id)).join(',')),
              ),
            ]),
          ),
        if (isLoading)
          Text('Loading meters…',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: theme.txtTertiary))
        else if (remaining.isEmpty && selected.isEmpty)
          Text('No meters available',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: theme.txtTertiary))
        else if (remaining.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: addLabel,
            onSelected: (id) => onChanged([...selected, id].join(',')),
            itemBuilder: (_) => [
              for (final id in remaining)
                PopupMenuItem<String>(
                  value: id,
                  child: Text(displayNames[id] ?? id,
                      style: GoogleFonts.poppins(fontSize: 12.5)),
                ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: theme.primary.withOpacity(0.45),
                    style: BorderStyle.solid),
              ),
              child: Text(addLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primary)),
            ),
          ),
      ],
    );
  }
}
