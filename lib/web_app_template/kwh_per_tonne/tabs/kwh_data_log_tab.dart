import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../kwh_theme.dart';

// Below the tablet breakpoint, 11 Expanded columns squeeze into unreadable
// slivers — switch to fixed column widths inside a horizontally-scrolling
// table instead, same treatment as the Max Demand records table.
const double _colDate    = 80;
const double _colMachine = 130;
const double _colProduct = 130;
const double _colDept    = 90;
const double _colKwh     = 65;
const double _colTonnes  = 70;
const double _colKwhT    = 65;
const double _colVar     = 75;
const double _colCost    = 85;
const double _colStatus  = 95;
const double _colActions = 75;

class KwhDataLogTab extends StatefulWidget {
  final List<Map<String, dynamic>> enriched;
  final double criticalPct;
  final double warningPct;
  final String currency;
  final Future<void> Function(Map<String, dynamic> entry) onDelete;
  final bool editingEnabled; // Thresholds dialog → "Enable editing entries"
  final void Function(Map<String, dynamic> entry) onEdit; // hands the row to the Add Data tab's form

  const KwhDataLogTab({
    super.key,
    required this.enriched,
    required this.criticalPct,
    required this.warningPct,
    required this.currency,
    required this.onDelete,
    required this.editingEnabled,
    required this.onEdit,
  });

  @override
  State<KwhDataLogTab> createState() => _KwhDataLogTabState();
}

class _KwhDataLogTabState extends State<KwhDataLogTab> {
  String _search    = '';
  String _sortField = 'date';
  bool   _sortAsc   = false;

  List<Map<String, dynamic>> get _rows {
    var list = widget.enriched.where((e) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return (e['machine']?.toString().toLowerCase().contains(q) ?? false) ||
             (e['product']?.toString().toLowerCase().contains(q) ?? false) ||
             (e['processDepartment']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'kwhT':     cmp = (a['kwhT']       as double).compareTo(b['kwhT']       as double); break;
        case 'variance': cmp = (a['variancePct'] as double).compareTo(b['variancePct'] as double); break;
        default:         cmp = (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? '');
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _toggleSort(String field) => setState(() {
    if (_sortField == field) { _sortAsc = !_sortAsc; } else { _sortField = field; _sortAsc = false; }
  });

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> e, bool isLight, FlutterFlowTheme theme) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isLight ? theme.secondaryBackground : KwhColors.cardBg,
        title: Text('Delete entry?', style: GoogleFonts.poppins(color: isLight ? theme.primaryText : Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Delete ${e['machine']} on ${e['date']}?', style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : Colors.white54, fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: Text('Delete', style: GoogleFonts.poppins(color: KwhColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) await widget.onDelete(e);
  }

  Widget _cell(bool narrow, double width, {required int flex, required Widget child}) =>
      narrow ? SizedBox(width: width, child: child) : Expanded(flex: flex, child: child);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);
    final rows    = _rows;

    final searchField = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: isLight ? theme.secondaryBackground : KwhColors.cardBg, border: Border.all(color: KwhColors.border), borderRadius: BorderRadius.circular(4)),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: GoogleFonts.poppins(fontSize: 17, color: isLight ? theme.primaryText : Colors.white),
        decoration: InputDecoration(
          hintText: 'Search machine, product, dept...',
          border: InputBorder.none,
          hintStyle: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.secondaryText : Colors.white38),
          icon: Icon(Icons.search, size: 16, color: isLight ? theme.secondaryText : Colors.white38),
        ),
      ),
    );

    final entryCount = Text('${rows.length} of ${widget.enriched.length} entries', style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.secondaryText : Colors.white38));

    final sortChips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [('Date', 'date'), ('kWh/t', 'kwhT'), ('Variance', 'variance')].map((s) =>
        GestureDetector(
          onTap: () => _toggleSort(s.$2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _sortField == s.$2 ? KwhColors.cyan : (isLight ? theme.primaryBackground : KwhColors.darkInput),
              border: Border.all(color: _sortField == s.$2 ? KwhColors.cyan : KwhColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(s.$1, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600,
              color: _sortField == s.$2 ? Colors.black : (isLight ? theme.secondaryText : Colors.white54))),
          ),
        )).toList(),
    );

    return Column(children: [
      // ── Toolbar ─────────────────────────────────────────────────────────
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < kBreakpointMedium) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            searchField,
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
              entryCount,
              sortChips,
            ]),
          ]);
        }
        return Row(children: [
          Expanded(flex: 3, child: searchField),
          const SizedBox(width: 12),
          entryCount,
          const Spacer(),
          sortChips,
        ]);
      })),

      // ── Table (header + rows) ────────────────────────────────────────────
      // Below the tablet breakpoint, 11 Expanded columns squeeze into
      // unreadable slivers — switch to fixed column widths inside a
      // horizontally-scrolling table instead.
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < kBreakpointMedium;

        final headerRow = Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: KwhColors.border), bottom: BorderSide(color: KwhColors.border))),
          child: Row(children: [
            _cell(narrow, _colDate,    flex: 1, child: Text('DATE',     style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colMachine, flex: 2, child: Text('MACHINE',  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colProduct, flex: 2, child: Text('PRODUCT',  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colDept,    flex: 1, child: Text('DEPT',     style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colKwh,     flex: 1, child: Text('KWH',      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colTonnes,  flex: 1, child: Text('TONNES',   style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colKwhT,    flex: 1, child: Text('KWH/T',    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colVar,     flex: 1, child: Text('VARIANCE', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colCost,    flex: 1, child: Text('COST',     style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colStatus,  flex: 1, child: Text('STATUS',   style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 0.8))),
            _cell(narrow, _colActions, flex: 1, child: const SizedBox()),
          ]),
        );

        final table = Column(children: [
          headerRow,
          Expanded(child: rows.isEmpty
            ? Center(child: Text('No entries found.', style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : Colors.white38)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: rows.length,
                itemBuilder: (ctx, i) => _dataRow(rows[i], isLight, theme, ctx, narrow),
              )),
        ]);

        if (!narrow) return table;
        const totalW = _colDate + _colMachine + _colProduct + _colDept + _colKwh + _colTonnes + _colKwhT + _colVar + _colCost + _colStatus + _colActions;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: totalW + 40, height: constraints.maxHeight, child: table),
        );
      })),
    ]);
  }

  Widget _dataRow(Map<String, dynamic> e, bool isLight, FlutterFlowTheme theme, BuildContext context, bool narrow) {
    final v  = e['variancePct'] as double;
    final vc = v > widget.criticalPct ? KwhColors.red : v > widget.warningPct ? KwhColors.amber : KwhColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: KwhColors.border.withOpacity(0.5)))),
      child: Row(children: [
        _cell(narrow, _colDate, flex: 1,    child: Text(e['date']?.toString()              ?? '',  style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        _cell(narrow, _colMachine, flex: 2, child: Text(e['machine']?.toString()           ?? '',  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: isLight ? theme.primaryText : Colors.white))),
        _cell(narrow, _colProduct, flex: 2, child: Text(e['product']?.toString()           ?? '',  style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        _cell(narrow, _colDept, flex: 1,    child: Text(e['processDepartment']?.toString() ?? '',  style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        _cell(narrow, _colKwh, flex: 1,     child: Text((e['kwh']    as num?)?.toStringAsFixed(0) ?? '0', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        _cell(narrow, _colTonnes, flex: 1,  child: Text((e['tonnes'] as num?)?.toStringAsFixed(1) ?? '0', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        _cell(narrow, _colKwhT, flex: 1,    child: Text((e['kwhT']   as double).toStringAsFixed(2),       style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: vc))),
        _cell(narrow, _colVar, flex: 1,     child: Text('${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%',   style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: vc))),
        _cell(narrow, _colCost, flex: 1,    child: Text('${widget.currency} ${(e['cost'] as double).toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.primaryText : Colors.white70))),
        _cell(narrow, _colStatus, flex: 1, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: vc.withOpacity(0.12), borderRadius: BorderRadius.circular(3)),
            child: Text(e['statusLabel'] as String, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: vc)),
          ),
        )),
        _cell(narrow, _colActions, flex: 1, child: Align(
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.editingEnabled) ...[
              GestureDetector(
                onTap: () => widget.onEdit(e),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: KwhColors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.edit_outlined, size: 15, color: KwhColors.cyan),
                ),
              ),
              const SizedBox(width: 6),
            ],
            GestureDetector(
              onTap: () => _confirmDelete(context, e, isLight, theme),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: KwhColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.delete_outline, size: 15, color: KwhColors.red),
              ),
            ),
          ]),
        )),
      ]),
    );
  }
}
