import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/models/user_scope.dart';
import 'package:smartmachine365/services/scope_resolver.dart';

/// Picks the plants and production areas a user may see.
///
/// Two shapes, chosen from the data rather than from a flag: a tree when the
/// area master records which plant each area belongs to, and two flat lists
/// when it does not. Most areas currently leave that link empty, so the flat
/// form is what admins will see today; filling the link in upgrades this
/// screen on its own.
///
/// Granting nothing means no restriction. Every account predates this feature,
/// so "empty" has to keep meaning "everything" — the alternative locks out a
/// whole customer the day it ships. The banner says so plainly, because a
/// permission screen that quietly means the opposite of what it looks like is
/// worse than no screen at all.
class DataScopePicker extends StatefulWidget {
  final UserScope initial;
  final ValueChanged<UserScope> onChanged;

  const DataScopePicker({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<DataScopePicker> createState() => _DataScopePickerState();
}

class _DataScopePickerState extends State<DataScopePicker> {
  late final Set<String> _plants = widget.initial.plantIds.toSet();
  late final Set<String> _areas = widget.initial.areaIds.toSet();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ScopeResolver.load();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load the facility list: $e';
          _loading = false;
        });
      }
    }
  }

  void _emit() => widget.onChanged(
        UserScope(plantIds: _plants.toList(), areaIds: _areas.toList()),
      );

  void _togglePlant(String id, bool on) {
    setState(() {
      if (on) {
        _plants.add(id);
      } else {
        _plants.remove(id);
        // Its areas go with it. Leaving them behind would grant an area inside
        // a plant the user cannot open — a state the dashboards would then have
        // to guess how to render.
        for (final a in ScopeResolver.areasOfPlant(id)) {
          _areas.remove(a.id);
        }
      }
    });
    _emit();
  }

  void _toggleArea(String id, bool on, {String parentId = ''}) {
    setState(() {
      if (on) {
        _areas.add(id);
        // Granting an area implies its plant, so the two cannot disagree.
        if (parentId.isNotEmpty) _plants.add(parentId);
      } else {
        _areas.remove(id);
      }
    });
    _emit();
  }

  void _clearAll() {
    setState(() {
      _plants.clear();
      _areas.clear();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _error!,
          style: GoogleFonts.poppins(
              fontSize: 12.5, color: const Color(0xFFFF5D6C)),
        ),
      );
    }

    final unrestricted = _plants.isEmpty && _areas.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _banner(theme, unrestricted),
        const SizedBox(height: 12),
        if (ScopeResolver.hasHierarchy) _tree(theme) else _flat(theme),
      ],
    );
  }

  Widget _banner(FlutterFlowTheme theme, bool unrestricted) {
    final color =
        unrestricted ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final text = unrestricted
        ? 'No restriction — this user can see every plant and production area.'
        : '${_plants.length} plant(s), ${_areas.length} area(s) selected.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(children: [
        Icon(unrestricted ? Icons.public : Icons.lock_outline,
            size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(fontSize: 12.5, color: color)),
        ),
        if (!unrestricted)
          TextButton(
            onPressed: _clearAll,
            child: Text('Remove restriction',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  // Tree: plants with their areas nested underneath.
  Widget _tree(FlutterFlowTheme theme) {
    final orphans = ScopeResolver.orphanAreas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final plant in ScopeResolver.plants) ...[
          _checkRow(
            theme,
            label: plant.name.isEmpty ? plant.id : plant.name,
            sub: plant.id,
            checked: _plants.contains(plant.id),
            onChanged: (v) => _togglePlant(plant.id, v),
            bold: true,
          ),
          for (final area in ScopeResolver.areasOfPlant(plant.id))
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: _checkRow(
                theme,
                label: area.name.isEmpty ? area.id : area.name,
                sub: area.id,
                checked: _areas.contains(area.id),
                // An area cannot be granted before its plant, or the tree would
                // show a tick under an unticked parent.
                enabled: _plants.contains(plant.id),
                onChanged: (v) => _toggleArea(area.id, v, parentId: plant.id),
              ),
            ),
        ],
        if (orphans.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionLabel(theme, 'AREAS WITH NO PLANT RECORDED'),
          for (final area in orphans)
            _checkRow(
              theme,
              label: area.name.isEmpty ? area.id : area.name,
              sub: area.id,
              checked: _areas.contains(area.id),
              onChanged: (v) => _toggleArea(area.id, v),
            ),
        ],
      ],
    );
  }

  // Flat: two independent lists, used while the plant links are missing.
  Widget _flat(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(theme, 'PLANTS'),
        for (final plant in ScopeResolver.plants)
          _checkRow(
            theme,
            label: plant.name.isEmpty ? plant.id : plant.name,
            sub: plant.id,
            checked: _plants.contains(plant.id),
            onChanged: (v) => _togglePlant(plant.id, v),
          ),
        const SizedBox(height: 14),
        _sectionLabel(theme, 'PRODUCTION AREAS'),
        for (final area in ScopeResolver.areas)
          _checkRow(
            theme,
            label: area.name.isEmpty ? area.id : area.name,
            sub: area.id,
            checked: _areas.contains(area.id),
            onChanged: (v) => _toggleArea(area.id, v, parentId: area.parentId),
          ),
      ],
    );
  }

  Widget _sectionLabel(FlutterFlowTheme theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: theme.txtTertiary)),
      );

  Widget _checkRow(
    FlutterFlowTheme theme, {
    required String label,
    required String sub,
    required bool checked,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    bool bold = false,
  }) {
    return InkWell(
      onTap: enabled ? () => onChanged(!checked) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          SizedBox(
            width: 26,
            height: 30,
            child: Checkbox(
              value: checked,
              onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: enabled ? theme.primaryText : theme.txtMuted,
              )),
          const SizedBox(width: 8),
          Text(sub,
              style:
                  GoogleFonts.poppins(fontSize: 11, color: theme.txtTertiary)),
        ]),
      ),
    );
  }
}
