import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import '/flutter_flow/flutter_flow_theme.dart';

typedef TableRecord = Map<String, dynamic>;
typedef CellBuilder = Widget? Function(String key, String value, TableRecord row);

// ── Column width constants ────────────────────────────────────────────────────
const double kCheckboxColumnWidth = 44.0;
const double kNumberColumnWidth   = 44.0;
const double kActionColumnWidth   = 80.0;

double minTableWidth(List<TableColumn> columns) =>
    kCheckboxColumnWidth +
    kNumberColumnWidth +
    kActionColumnWidth +
    columns.fold(0.0, (sum, c) => sum + c.width);

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip model
// ─────────────────────────────────────────────────────────────────────────────

class TableFilter {
  final String label;
  final List<String> options;
  final String? value;
  final void Function(String value) onChanged;
  final IconData icon;

  const TableFilter({
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.icon = Icons.tune,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar action button model
// ─────────────────────────────────────────────────────────────────────────────

class TableAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool iconOnly;
  final bool isLoading;

  const TableAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.iconOnly  = false,
    this.isLoading = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DataTableWidget
// All colors, fonts, sizes from FlutterFlowTheme.of(context):
//   t.primaryBackground  #0C153D  — bg, row fill
//   t.secondaryBackground #3C339A — dropdown menus
//   t.primary            #31ECFC  — cyan  accents, borders, active states
//   t.secondary          #39D2C0  — teal  edit button
//   t.tertiary           #6D5FED  — purple  primary-col icon badge
//   t.primaryText        #FFFFFF  — main text
//   t.secondaryText      #95A1AC  — labels, subtitles, dim text
//   t.success            #24A891  — active status
//   t.error              #E74852  — inactive status, delete button
// ─────────────────────────────────────────────────────────────────────────────

class DataTableWidget extends StatefulWidget {
  final List<TableColumn> columns;
  final List<TableRecord> rows;
  final int     perPage;
  final String  primaryKey;
  final String? primaryColumnKey;
  final String? primarySubtitleKey;
  final IconData primaryIcon;
  final String? sortKey;
  final CellBuilder? cellBuilder;
  final void Function(TableRecord row)? onEdit;
  final void Function(TableRecord row)? onDelete;
  final void Function(Set<String> selectedIds)? onSelectionChanged;
  final bool showSelection;
  final bool showFilterDropdown;
  final List<TableFilter> filters;
  final List<TableAction> actions;

  /// When non-empty, the free-text search box matches a row if ANY of these
  /// keys contains the query (e.g. ['meterName','meterId'] searches both the
  /// Display Name and the Device ID). Falls back to the single search-by
  /// column when empty.
  final List<String> searchKeys;

  /// Label of the currently active non-primary action button.
  /// Matching action gets the highlighted ghost-button style.
  final String? activeActionLabel;

  /// Optional per-row action builder. If provided and returns a non-null Widget,
  /// that widget replaces the default edit/delete icons for that row.
  final Widget? Function(TableRecord row)? actionBuilder;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.perPage             = 13,
    this.primaryKey          = 'id',
    this.primaryColumnKey,
    this.primarySubtitleKey,
    this.primaryIcon         = Icons.inventory_2_outlined,
    this.sortKey,
    this.cellBuilder,
    this.onEdit,
    this.onDelete,
    this.onSelectionChanged,
    this.showSelection       = true,
    this.showFilterDropdown  = true,
    this.filters             = const [],
    this.actions             = const [],
    this.searchKeys          = const [],
    this.activeActionLabel,
    this.actionBuilder,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> with TickerProviderStateMixin {
  final _hScroll       = ScrollController();
  final _hScrollHeader = ScrollController();
  final _vScroll       = ScrollController();
  double _hOffset = 0;

  late List<TableRecord> _rows;

  int  _page          = 0;
  late int _perPage;
  bool _sortAscending = true;
  final Set<String> _selectedIds = {};
  bool _selectAll   = false;
  int? _hoveredRow;

  final _searchCtrl = TextEditingController();
  bool _showSearch  = false;
  late String _filterBy;
  Timer? _debounce;

  // Animation controller for spinning icons
  late AnimationController _spinCtrl;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _effectivePrimaryKey =>
      widget.primaryColumnKey ?? widget.columns.first.key;

  String get _effectiveSortKey =>
      widget.sortKey ?? _effectivePrimaryKey;

  double get _checkboxW =>
      widget.showSelection ? kCheckboxColumnWidth : 0;

  Map<String, TableColumn> get _uniqueColumns {
    final map = <String, TableColumn>{};
    for (final c in widget.columns) map.putIfAbsent(c.key, () => c);
    return map;
  }

  @override
  void initState() {
    super.initState();
    _perPage = widget.perPage;
    _rows = List.from(widget.rows);
    final keys = widget.columns.map((c) => c.key).toSet();
    _filterBy = keys.contains(_effectivePrimaryKey)
        ? _effectivePrimaryKey
        : widget.columns.first.key;
    _hScroll.addListener(_syncHeader);
    _hScrollHeader.addListener(_syncBody);

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(DataTableWidget old) {
    super.didUpdateWidget(old);
    if (old.rows != widget.rows) {
      // Parent (e.g. a cubit-driven filter chip) pushed a new row list.
      // Reset pagination to the first page and re-apply any active search
      // query against the new list — otherwise the chip filter appeared to
      // do nothing when a search was active or the user was on page 2+.
      setState(() {
        _rows = List.from(widget.rows);
        _page = 0;
      });
      final q = _searchCtrl.text;
      if (q.isNotEmpty) _search(q);
    }

    final anyLoading = widget.actions.any((a) => a.isLoading);
    if (anyLoading && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!anyLoading && _spinCtrl.isAnimating) {
      _spinCtrl.stop();
    }
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _hScrollHeader.dispose();
    _vScroll.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  void _syncHeader() {
    if (_hScrollHeader.hasClients &&
        _hScrollHeader.offset != _hScroll.offset) {
      _hScrollHeader.jumpTo(_hScroll.offset);
    }
    if (_hScroll.hasClients) _hOffset = _hScroll.offset;
  }

  void _syncBody() {
    if (_hScroll.hasClients && _hScroll.offset != _hScrollHeader.offset) {
      _hScroll.jumpTo(_hScrollHeader.offset);
    }
  }

  void _scrollBy(double delta) {
    if (!_hScroll.hasClients) return;
    final max = _hScroll.position.maxScrollExtent;
    final target = (_hOffset + delta).clamp(0.0, max);
    _hOffset = target;
    _hScroll.animateTo(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _search(String query) {
    final q = query.toLowerCase();
    setState(() {
      _rows = widget.rows.where((r) {
        // Multi-key search: match if ANY of the configured keys contains the
        // query. Falls back to the single search-by column otherwise.
        if (widget.searchKeys.isNotEmpty) {
          return widget.searchKeys.any((k) =>
              (r[k] ?? '').toString().toLowerCase().contains(q));
        }
        final val = (r[_filterBy] ?? '').toString().toLowerCase();
        return val.contains(q);
      }).toList();
      _page = 0;
    });
  }

  void _sort() => setState(() {
        _sortAscending = !_sortAscending;
        _rows.sort((a, b) {
          final av = (a[_effectiveSortKey] ?? '').toString().toLowerCase();
          final bv = (b[_effectiveSortKey] ?? '').toString().toLowerCase();
          return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
        });
      });

  void _toggleSelectAll(List<TableRecord> paged) {
    setState(() {
      if (_selectAll) {
        _selectedIds.clear();
        _selectAll = false;
      } else {
        for (final r in paged) {
          _selectedIds.add(r[widget.primaryKey]?.toString() ?? '');
        }
        _selectAll = true;
      }
    });
    widget.onSelectionChanged?.call(Set.from(_selectedIds));
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectAll = false;
      } else {
        _selectedIds.add(id);
      }
    });
    widget.onSelectionChanged?.call(Set.from(_selectedIds));
  }

  // ── Small widgets ─────────────────────────────────────────────────────────

  /// Ghost-border toolbar button
  Widget _ghostBtn({
    required IconData icon,
    required String   label,
    VoidCallback? onTap,
    bool active   = false,
    bool iconOnly = false,
    bool isLoading = false,
  }) {
    final t = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding:
            EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 14),
        decoration: BoxDecoration(
          color: active
              ? t.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? t.primary.withOpacity(0.4)
                : t.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: isLoading ? 0.6 : 1.0,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isLoading)
              RotationTransition(
                turns: _spinCtrl,
                child: Icon(icon, size: 15, color: t.primary),
              )
            else
              Icon(icon,
                  size: 15,
                  color: active ? t.primary : t.secondaryText),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: t.labelMedium.override(
                    fontFamily: t.labelMediumFamily,
                    color: active ? t.primary : t.secondaryText,
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    font: t.labelMedium,
                  )),
            ],
          ]),
        ),
      ),
    );
  }

  /// Filled primary toolbar button
  Widget _primaryBtn({
    required IconData icon,
    required String   label,
    VoidCallback? onTap,
    bool iconOnly = false,
    bool isLoading = false,
  }) {
    final t = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding:
            EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 16),
        decoration: BoxDecoration(
          color: t.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Opacity(
          opacity: isLoading ? 0.7 : 1.0,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isLoading)
              RotationTransition(
                turns: _spinCtrl,
                child: Icon(icon, size: 16, color: t.primaryBackground),
              )
            else
              Icon(icon, size: 16, color: t.primaryBackground),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: t.labelLarge.override(
                    fontFamily: t.labelLargeFamily,
                    color: t.primaryBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    font: t.labelLarge,
                  )),
            ],
          ]),
        ),
      ),
    );
  }

  /// Filter chip dropdown — uniform fixed width so a set of chips lines up in a
  /// neat grid (they Wrap onto extra rows when the width runs out).
  Widget _filterChipWidget(TableFilter f, {double width = 240}) {
    final t        = FlutterFlowTheme.of(context);
    final selected = f.value ?? f.options.first;
    final isActive = selected != f.options.first;

    return SizedBox(
      width: width,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? t.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? t.primary.withOpacity(0.4)
                : t.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value:
                f.options.contains(selected) ? selected : f.options.first,
            dropdownColor: t.secondaryBackground,
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down,
                size: 16,
                color: isActive ? t.primary : t.secondaryText),
            // Compact display (mirrors Energy Details): show the filter label
            // as a placeholder while unfiltered, and the selected value once
            // active — never "label · value", which is what made the chips too
            // wide and forced truncation.
            selectedItemBuilder: (_) => f.options.map((o) {
              final isAll  = o == f.options.first;
              final text   = isAll ? f.label : o;
              final active = !isAll;
              return Row(children: [
                Icon(f.icon,
                    size: 13,
                    color: active
                        ? t.primary
                        : t.secondaryText.withOpacity(0.6)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium.override(
                        fontFamily: t.labelMediumFamily,
                        color: active
                            ? t.primary
                            : t.secondaryText.withOpacity(0.75),
                        fontSize: 14,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        font: t.labelMedium,
                      )),
                ),
              ]);
            }).toList(),
            items: f.options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: t.bodyMedium.override(
                          fontFamily: t.bodyMediumFamily,
                          color: t.primaryText,
                          fontSize: 15,
                          font: t.bodyMedium,
                        )),
                  ))
              .toList(),
            onChanged: (v) {
              if (v != null) f.onChanged(v);
            },
          ),
        ),
      ),
    );
  }

  /// Status badge — uses t.success / t.error
  Widget _statusBadge(String s) {
    final t        = FlutterFlowTheme.of(context);
    final isActive = s.toLowerCase() == 'active';
    final color    = isActive ? t.success : t.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
      ),
      child: Text(s,
          style: t.labelSmall.override(
            fontFamily: t.labelSmallFamily,
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            font: t.labelSmall,
          )),
    );
  }

  /// Pagination prev/next arrow button
  Widget _pageArrow({
    required IconData    icon,
    required bool        enabled,
    required VoidCallback onTap,
  }) {
    final t = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? t.primaryBackground.withOpacity(0.6)
              : t.primaryBackground.withOpacity(0.2),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: enabled
                ? t.primary.withOpacity(0.2)
                : t.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Icon(icon,
            size: 15,
            color: enabled ? t.secondaryText : t.secondaryText.withOpacity(0.3)),
      ),
    );
  }

  /// Pagination page number button
  Widget _pageNumBtn(int i, int total) {
    final t  = FlutterFlowTheme.of(context);
    final on = _page == i;

    if (total > 5 &&
        i != 0 &&
        i != total - 1 &&
        (i - _page).abs() > 1) {
      if (i == 1 || i == total - 2) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('…',
              style: TextStyle(
                  color: t.secondaryText.withOpacity(0.4),
                  fontSize: 14)),
        );
      }
      if ((i - _page).abs() > 2) return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => setState(() => _page = i),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          // Active page — t.primary (cyan) fill
          color: on ? t.primary : t.primaryBackground.withOpacity(0.4),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: on
                ? t.primary
                : t.primary.withOpacity(0.12),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text('${i + 1}',
            style: t.labelMedium.override(
              fontFamily: t.labelMediumFamily,
              // Navy text on cyan, secondaryText on inactive
              color: on ? t.primaryBackground : t.secondaryText,
              fontSize: 14,
              fontWeight:
                  on ? FontWeight.w800 : FontWeight.w500,
              font: t.labelMedium,
            )),
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _toolbar() {
    final t          = FlutterFlowTheme.of(context);
    final uniqueCols = _uniqueColumns;
    final safeFilter = uniqueCols.containsKey(_filterBy)
        ? _filterBy
        : uniqueCols.keys.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips get their own full-width band above the action
          // buttons. They're laid out as an even-width responsive grid: as many
          // per row as fit at a comfortable min width, each stretched to evenly
          // fill the row (no ragged gaps, no truncated labels), wrapping to
          // extra rows only when needed.
          if (widget.filters.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, c) {
                const spacing = 8.0;
                const minChipW = 230.0;
                const maxChipW = 320.0;
                final maxW = c.maxWidth;
                var perRow =
                    ((maxW + spacing) / (minChipW + spacing)).floor();
                if (perRow < 1) perRow = 1;
                if (perRow > widget.filters.length) {
                  perRow = widget.filters.length;
                }
                var chipW = (maxW - spacing * (perRow - 1)) / perRow;
                if (chipW > maxChipW) chipW = maxChipW;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: widget.filters
                      .map((f) => _filterChipWidget(f, width: chipW))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          // Search / sort / action row. A Wrap (not a Row+Spacer — Spacer
          // has no meaning outside a Flex) so the action cluster drops to its
          // own line instead of overflowing when the search-by dropdown plus
          // every button can't fit on one line, as happens on a phone.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Search-by dropdown
              if (widget.showFilterDropdown)
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: t.primary.withOpacity(0.2), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: safeFilter,
                      dropdownColor: t.secondaryBackground,
                      style: t.labelMedium.override(
                        fontFamily: t.labelMediumFamily,
                        color: t.secondaryText,
                        fontSize: 14,
                        font: t.labelMedium,
                      ),
                      icon: Icon(Icons.keyboard_arrow_down,
                          size: 16, color: t.secondaryText),
                      items: uniqueCols.values
                          .map((c) => DropdownMenuItem(
                                value: c.key,
                                child: Text(c.label,
                                    style: t.bodyMedium.override(
                                      fontFamily: t.bodyMediumFamily,
                                      color: t.primaryText,
                                      fontSize: 15,
                                      font: t.bodyMedium,
                                    )),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _filterBy = v);
                        // Re-run the active search against the newly-selected
                        // column so results refresh immediately. Without this
                        // the dropdown appeared to do nothing whenever the
                        // search box already had text in it.
                        _search(_searchCtrl.text);
                      },
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Search field + search/sort buttons + custom actions
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Animated search field
                  if (_showSearch)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 200,
                      height: 36,
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: t.primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: t.primary.withOpacity(0.3), width: 1),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 10),
                        Icon(Icons.search,
                            size: 15, color: t.secondaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: t.bodyMedium.override(
                              fontFamily: t.bodyMediumFamily,
                              color: t.primaryText,
                              fontSize: 14,
                              font: t.bodyMedium,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search…',
                              hintStyle: t.labelMedium.override(
                                fontFamily: t.labelMediumFamily,
                                color: t.secondaryText.withOpacity(0.5),
                                fontSize: 14,
                                font: t.labelMedium,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              _debounce?.cancel();
                              _debounce = Timer(
                                  const Duration(milliseconds: 300),
                                  () => _search(v));
                            },
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _searchCtrl.clear();
                            _search('');
                            setState(() => _showSearch = false);
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.close,
                                size: 14,
                                color: t.secondaryText.withOpacity(0.6)),
                          ),
                        ),
                      ]),
                    ),

                  _ghostBtn(
                    icon: Icons.search,
                    label: 'Search',
                    active: _showSearch,
                    onTap: () => setState(() => _showSearch = !_showSearch),
                  ),
                  _ghostBtn(
                    icon: Icons.swap_vert_rounded,
                    label: 'Sort',
                    onTap: _sort,
                  ),

                  // Custom action buttons
                  if (widget.actions.isNotEmpty) ...[
                    Container(
                      width: 1,
                      height: 22,
                      color: t.primary.withOpacity(0.15),
                    ),
                    ...widget.actions.map((a) {
                      // Non-primary actions: highlight if label matches activeActionLabel
                      final isActive = !a.isPrimary &&
                          widget.activeActionLabel != null &&
                          a.label == widget.activeActionLabel;
                      return a.isPrimary
                          ? _primaryBtn(
                              icon: a.icon,
                              label: a.label,
                              onTap: a.onTap,
                              iconOnly: a.iconOnly,
                              isLoading: a.isLoading,
                            )
                          : _ghostBtn(
                              icon: a.icon,
                              label: a.label,
                              onTap: a.onTap,
                              iconOnly: a.iconOnly,
                              active: isActive,
                              isLoading: a.isLoading,
                            );
                    }),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header row ────────────────────────────────────────────────────────────

  Widget _headerRow(
    double tableW,
    List<TableRecord> paged,
    List<double> colWidths,
  ) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      width: tableW,
      decoration: BoxDecoration(
        color: t.primaryBackground.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(
              color: t.primary.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(children: [
        // Checkbox
        if (widget.showSelection)
          SizedBox(
            width: kCheckboxColumnWidth,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: Checkbox(
                  value: _selectAll,
                  onChanged: (_) => _toggleSelectAll(paged),
                  side: BorderSide(
                      color: t.secondaryText.withOpacity(0.4),
                      width: 1.5),
                  activeColor: t.primary,
                  checkColor: t.primaryBackground,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3)),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        // Row number
        SizedBox(
          width: kNumberColumnWidth,
          child: Center(
            child: Text('#',
                style: t.labelSmall.override(
                  fontFamily: t.labelSmallFamily,
                  color: t.secondaryText.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  font: t.labelSmall,
                )),
          ),
        ),
        // Data columns
        ...List.generate(widget.columns.length, (i) {
          final c = widget.columns[i];
          final w = colWidths[i];
          return InkWell(
            onTap: c.sortable ? _sort : null,
            child: SizedBox(
              width: w,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 12),
                child: Row(children: [
                  if (c.sortable)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(Icons.swap_vert,
                          size: 13,
                          color: t.secondaryText
                              .withOpacity(0.4)),
                    ),
                  Flexible(
                    child: Text(c.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelMedium.override(
                          fontFamily: t.labelMediumFamily,
                          // secondaryText for header labels
                          color: t.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          font: t.labelMedium,
                        )),
                  ),
                  if (c.sortable)
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 11,
                      color: t.secondaryText.withOpacity(0.4),
                    ),
                ]),
              ),
            ),
          );
        }),
        // Actions header
        SizedBox(
          width: kActionColumnWidth,
          child: Center(
            child: Icon(Icons.more_horiz,
                size: 16,
                color: t.secondaryText.withOpacity(0.3)),
          ),
        ),
      ]),
    );
  }

  // ── Cell builder ──────────────────────────────────────────────────────────

  Widget _buildCell(
    TableColumn col,
    TableRecord row,
    double cellWidth,
  ) {
    final t     = FlutterFlowTheme.of(context);
    final value = row[col.key]?.toString() ?? '';

    // Custom cell override
    final custom = widget.cellBuilder?.call(col.key, value, row);
    if (custom != null) {
      return SizedBox(
        width: cellWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 8),
          child: custom,
        ),
      );
    }

    // Primary column — icon + name + subtitle
    if (col.key == _effectivePrimaryKey) {
      final subtitle = widget.primarySubtitleKey != null
          ? row[widget.primarySubtitleKey!]?.toString() ?? ''
          : '';
      return SizedBox(
        width: cellWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon badge — t.primary (cyan) tint for better visibility
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: t.primary.withOpacity(0.2), width: 1),
                ),
                child: Center(
                  child: Icon(widget.primaryIcon,
                      size: 17, color: t.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: value,
                      waitDuration: const Duration(milliseconds: 400),
                      child: Text(value,
                          style: t.bodyMedium.override(
                            fontFamily: t.bodyMediumFamily,
                            color: t.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            font: t.bodyMedium,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Tooltip(
                        message: subtitle,
                        waitDuration: const Duration(milliseconds: 400),
                        child: Text(subtitle,
                            style: t.labelSmall.override(
                              fontFamily: t.labelSmallFamily,
                              color: t.secondaryText,
                              fontSize: 13,
                              font: t.labelSmall,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Status column
    if (col.key == 'status') {
      return SizedBox(
        width: cellWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 10),
          child: _statusBadge(value),
        ),
      );
    }

    // Default text cell — tooltip shows the full value when it's truncated
    return SizedBox(
      width: cellWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 11),
        child: Tooltip(
          message: value,
          waitDuration: const Duration(milliseconds: 400),
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.override(
                fontFamily: t.bodySmallFamily,
                // primaryText at 70% — readable but not competing with primary col
                color: t.primaryText.withOpacity(0.7),
                fontSize: 14,
                font: t.bodySmall,
              )),
        ),
      ),
    );
  }

  // ── Data row ──────────────────────────────────────────────────────────────

  Widget _dataRow(
    TableRecord row,
    int         idx,
    double      tableW,
    List<double> colWidths,
  ) {
    final t   = FlutterFlowTheme.of(context);
    final id  = row[widget.primaryKey]?.toString() ?? '';
    final sel = _selectedIds.contains(id);
    final hov = _hoveredRow == idx;
    final num = _page * _perPage + idx + 1;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRow = idx),
      onExit:  (_) => setState(() => _hoveredRow = null),
      child: Container(
        width: tableW,
        decoration: BoxDecoration(
          color: sel
              ? t.primary.withOpacity(0.07)
              : hov
                  ? t.primary.withOpacity(0.04)
                  : Colors.transparent,
          border: Border(
            bottom: BorderSide(
                color: t.primary.withOpacity(0.07), width: 0.5),
          ),
        ),
        child: Row(children: [
          // Checkbox
          if (widget.showSelection)
            SizedBox(
              width: kCheckboxColumnWidth,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Checkbox(
                    value: sel,
                    onChanged: (_) => _toggleSelect(id),
                    side: BorderSide(
                        color: t.secondaryText.withOpacity(0.4),
                        width: 1.5),
                    activeColor: t.primary,
                    checkColor: t.primaryBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3)),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
          // Row number
          SizedBox(
            width: kNumberColumnWidth,
            child: Text('$num',
                textAlign: TextAlign.center,
                style: t.labelSmall.override(
                  fontFamily: t.labelSmallFamily,
                  color: t.secondaryText.withOpacity(0.4),
                  fontSize: 13,
                  font: t.labelSmall,
                )),
          ),
          // Data cells
          ...List.generate(widget.columns.length,
              (i) => _buildCell(widget.columns[i], row, colWidths[i])),
          // Actions
          SizedBox(
            width: kActionColumnWidth,
            child: widget.actionBuilder?.call(row) ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onEdit != null) ...[
                      IconButton(
                        onPressed: () => widget.onEdit!(row),
                        // t.secondary (teal) for edit
                        icon: Icon(Icons.edit_outlined,
                            size: 17, color: t.secondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (widget.onDelete != null)
                      IconButton(
                        onPressed: () => widget.onDelete!(row),
                        // t.error for delete
                        icon: Icon(Icons.delete_outline,
                            size: 17, color: t.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                      ),
                  ],
                ),
          ),
        ]),
      ),
    );
  }

  // ── Pagination bar ────────────────────────────────────────────────────────

  Widget _paginationBar(int total, List<TableRecord> paged) {
    final t = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Left — selection count + entry count
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
            if (_selectedIds.isNotEmpty && widget.showSelection) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: t.primary.withOpacity(0.3), width: 1),
                ),
                child: Text('${_selectedIds.length} selected',
                    style: t.labelSmall.override(
                      fontFamily: t.labelSmallFamily,
                      color: t.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      font: t.labelSmall,
                    )),
              ),
              const SizedBox(width: 10),
            ],
            Row(
              children: [
                Text('Show ',
                    style: t.labelMedium.override(
                        fontFamily: t.labelMediumFamily,
                        color: t.secondaryText,
                        fontSize: 13,
                        font: t.labelMedium)),
                DropdownButtonHideUnderline(
                  // DropdownButton2 (not the stock DropdownButton) anchors its
                  // menu directly to the button. The stock widget instead
                  // centers the *selected item* over the button, which shoves
                  // the whole menu far up the screen when the button sits near
                  // the bottom of the viewport (as this pagination bar does).
                  child: DropdownButton2<int>(
                    value: _perPage,
                    isDense: true,
                    style: TextStyle(color: t.primaryText, fontSize: 13),
                    // Always include the current value — callers may pass a
                    // perPage not in this default list (e.g. 10, 20), which
                    // would otherwise crash DropdownButton's value assertion.
                    items: ({13, 50, 100, 200, _perPage}.toList()..sort())
                        .map((n) => DropdownMenuItem(
                      value: n,
                      child: Text('$n', style: TextStyle(color: t.primaryText, fontSize: 13)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() { _perPage = v; _page = 0; });
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.zero,
                      height: 28,
                      width: 56,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1B2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(height: 36),
                  ),
                ),
                Text(' entries  ·  Showing ${paged.length} of ${_rows.length}',
                    style: t.labelMedium.override(
                        fontFamily: t.labelMediumFamily,
                        color: t.secondaryText,
                        fontSize: 13,
                        font: t.labelMedium)),
              ],
            ),
          ]),
          // Right — page buttons
          Row(children: [
            _pageArrow(
              icon: Icons.chevron_left,
              enabled: _page > 0,
              onTap: () => setState(() => _page--),
            ),
            const SizedBox(width: 4),
            for (int i = 0; i < total; i++) ...[
              _pageNumBtn(i, total),
              const SizedBox(width: 4),
            ],
            _pageArrow(
              icon: Icons.chevron_right,
              enabled: _page < total - 1,
              onTap: () => setState(() => _page++),
            ),
          ]),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t     = FlutterFlowTheme.of(context);
    final total = _rows.isEmpty
        ? 0
        : (_rows.length / _perPage).ceil();
    if (_page >= total && total > 0) _page = total - 1;
    final paged =
        _rows.skip(_page * _perPage).take(_perPage).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final availableW = constraints.maxWidth;
      final fixedW     = _checkboxW + kNumberColumnWidth + kActionColumnWidth;
      final naturalCols =
          widget.columns.fold(0.0, (s, c) => s + c.width);
      final naturalW   = naturalCols + fixedW;
      final tableW     = naturalW < availableW ? availableW : naturalW;
      final budget     = tableW - fixedW;
      final finalWidths = naturalCols > 0
          ? widget.columns
              .map((c) => c.width / naturalCols * budget)
              .toList()
          : widget.columns.map((c) => c.width).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.primaryBackground.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: t.primary.withOpacity(0.1), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(children: [
                  // Horizontal-scrollable header with < > scroll buttons
                  Stack(
                    children: [
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        }),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _hScrollHeader,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: tableW,
                            child: _headerRow(tableW, paged, finalWidths),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ScrollBtn(icon: Icons.chevron_left,  onTap: () => _scrollBy(-200)),
                            _ScrollBtn(icon: Icons.chevron_right, onTap: () => _scrollBy(200)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Body
                  Expanded(
                    child: _rows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 44,
                                    color: t.secondaryText
                                        .withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text('No records found.',
                                    style: t.labelLarge.override(
                                      fontFamily: t.labelLargeFamily,
                                      color: t.secondaryText
                                          .withOpacity(0.4),
                                      fontSize: 16,
                                      font: t.labelLarge,
                                    )),
                              ],
                            ),
                          )
                        : ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context)
                                .copyWith(dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            }),
                            child: Scrollbar(
                              controller: _hScroll,
                              thumbVisibility: true,
                              trackVisibility: true,
                              scrollbarOrientation:
                                  ScrollbarOrientation.bottom,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _hScroll,
                                physics: const ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: tableW,
                                  child: Scrollbar(
                                    controller: _vScroll,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: _vScroll,
                                      itemCount: paged.length,
                                      itemBuilder: (_, i) => _dataRow(
                                        paged[i],
                                        i,
                                        tableW,
                                        finalWidths,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ]),
              ),
            ),
          ),
          _paginationBar(total, paged),
        ],
      );
    });
  }
}

class _ScrollBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ScrollBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: double.infinity,
        color: const Color(0xFF0D1B2A).withOpacity(0.85),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }
}