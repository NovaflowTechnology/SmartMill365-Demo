import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import 'package:smartmachine365/models/user_scope.dart';
import 'package:smartmachine365/services/scope_resolver.dart';

/// A plant or production area picker that only offers what the signed-in user
/// is allowed to see.
///
/// Every dashboard filter goes through this rather than building its own list,
/// because a scope rule has to hold identically on every screen and the surest
/// way to get that is one implementation. A filter written twice is a filter
/// that will disagree once.
///
/// Three behaviours worth knowing about, all of them chosen to avoid a screen
/// that looks broken when it is actually just restricted:
///
///  * one option only — it is selected automatically and the control is locked,
///    since a dropdown with a single entry is a decision nobody gets to make
///  * no options at all — an explicit message, not an empty dropdown. A user
///    whose grants no longer match anything would otherwise see a blank
///    control and report it as a bug
///  * a value outside the allowed set — dropped rather than displayed, so a
///    stale saved selection cannot show data the user may not see
enum ScopeLevel { plant, area }

class ScopedFilterDropdown extends StatelessWidget {
  final ScopeLevel level;

  /// Currently selected id, or empty for "all".
  final String value;

  final ValueChanged<String> onChanged;

  /// Restricts areas to one plant. Ignored for [ScopeLevel.plant].
  final String? withinPlantId;

  /// Label for the entry that means "no filter". Null hides it, which is what
  /// a locked single-option control wants.
  final String? allLabel;

  final String hint;

  const ScopedFilterDropdown({
    super.key,
    required this.level,
    required this.value,
    required this.onChanged,
    this.withinPlantId,
    this.allLabel,
    this.hint = 'Select...',
  });

  UserScope get _scope => AppStateNotifier.instance.dataScope;

  List<ScopeNode> get _options => level == ScopeLevel.plant
      ? ScopeResolver.visiblePlants(_scope)
      : ScopeResolver.visibleAreas(_scope, withinPlantId: withinPlantId);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final options = _options;

    if (options.isEmpty) {
      return _message(
        theme,
        level == ScopeLevel.plant
            ? 'No plant assigned to your account.'
            : 'No production area assigned to your account.',
      );
    }

    // Exactly one choice is not a choice. Select it and lock the control, and
    // tell the caller so its queries carry the right scope from the first
    // frame rather than after the user touches a dropdown they cannot change.
    final locked = options.length == 1 && allLabel == null;
    if (locked && value != options.first.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(options.first.id);
      });
    }

    // A saved selection the user is no longer allowed to see is discarded
    // rather than rendered — otherwise a revoked grant would still show its
    // old plant in the control.
    final allowed = options.any((o) => o.id == value);
    final effective = locked
        ? options.first.id
        : (allowed ? value : (allLabel != null ? '' : ''));

    return Opacity(
      opacity: locked ? 0.75 : 1,
      child: IgnorePointer(
        ignoring: locked,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.primary.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effective.isEmpty ? null : effective,
              isExpanded: true,
              isDense: true,
              hint: Text(allLabel ?? hint,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: theme.secondaryText)),
              icon: Icon(
                  locked ? Icons.lock_outline : Icons.keyboard_arrow_down,
                  size: 16,
                  color: theme.secondaryText),
              dropdownColor: theme.primaryBackground,
              items: [
                if (allLabel != null)
                  DropdownMenuItem(
                    value: '',
                    child: Text(allLabel!,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: theme.primaryText)),
                  ),
                for (final o in options)
                  DropdownMenuItem(
                    value: o.id,
                    child: Text(o.name.isEmpty ? o.id : o.name,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: theme.primaryText),
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: locked ? null : (v) => onChanged(v ?? ''),
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(FlutterFlowTheme theme, String text) => Container(
        height: 40,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x14F59E0B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x4DF59E0B)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 15, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFFF59E0B)),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
}
