import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'cubit/sankey_setting_cubit.dart';
import 'models/sankey_setting_data.dart';

// ─── constants ────────────────────────────────────────────────────────────────
const double _kTier = 160.0;
const double _kDev = 130.0;
const double _kField = 244.0;
const double _kCol = _kTier + _kDev + _kField; // 514
const double _kTableRightGuard = 24.0;
const double _kRowH = 32.0; 
const double _kRowUnit = 160.0; // Increased to 160 to fix overflow while staying relatively compact
const int _kMaxFields =
    9; // equals the number of options in _MapFieldDrop._opts

// ─── helpers ──────────────────────────────────────────────────────────────────
TextStyle _p(Color c, double sz, {FontWeight w = FontWeight.w400}) => TextStyle(
    fontFamily: 'Poppins', color: c, fontSize: sz, fontWeight: w, height: 1.3);

Color _colorFromHexOrDefault(String hex, Color fallback) {
  final raw = hex.trim();
  if (raw.isEmpty) return fallback;
  final cleaned = raw.startsWith('#') ? raw.substring(1) : raw;
  if (cleaned.length == 6) {
    final v = int.tryParse('FF$cleaned', radix: 16);
    if (v != null) return Color(v);
  } else if (cleaned.length == 8) {
    final v = int.tryParse(cleaned, radix: 16);
    if (v != null) return Color(v);
  }
  return fallback;
}

String _toHex(Color c) {
  final r = c.red.toRadixString(16).padLeft(2, '0');
  final g = c.green.toRadixString(16).padLeft(2, '0');
  final b = c.blue.toRadixString(16).padLeft(2, '0');
  return '#${(r + g + b).toUpperCase()}';
}

/// True when the app is running in light mode — mirrors equipment_overview pattern.
bool _isLight(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.light;

/// Card surface colour — matches master_facility_setting pattern:
///   Dark : t.primaryBackground  (#0C153D navy) — DataTableWidget sits on this directly
///   Light: t.secondaryBackground — slightly elevated surface on a white page
/// t.secondaryBackground (#3C339A purple in dark) is ONLY used for dialogs/snackbars.
Color _cardBg(FlutterFlowTheme t, {bool isLight = false}) =>
    isLight ? t.secondaryBackground : t.primaryBackground;

/// Border colour — more visible in light mode.
Color _borderCol(FlutterFlowTheme t, {bool isLight = false}) =>
    isLight ? t.alternate : t.primary.withOpacity(0.15);

/// Header strip colour — matches DataTableWidget _headerRow.
Color _headerBg(FlutterFlowTheme t, {bool isLight = false}) => isLight
    ? t.alternate.withOpacity(0.5)
    : t.primaryBackground.withOpacity(0.6);

// ─────────────────────────────────────────────────────────────────────────────
class EnergySankeySettingWidget extends StatelessWidget {
  const EnergySankeySettingWidget({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SankeySettingCubit()..load(),
        child: const _Body(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  const _Body();

  SankeySettingLoaded? _loaded(SankeySettingState st) {
    if (st is SankeySettingLoaded) return st;
    if (st is SankeySettingSaving)
      return SankeySettingLoaded(
          tiers: st.tiers, nodesByTier: st.nodesByTier, devices: st.devices);
    if (st is SankeySettingSaved)
      return SankeySettingLoaded(
          tiers: st.tiers, nodesByTier: st.nodesByTier, devices: st.devices);
    if (st is SankeySettingSaveError)
      return SankeySettingLoaded(
          tiers: st.tiers, nodesByTier: st.nodesByTier, devices: st.devices);
    return null;
  }

  void _snack(BuildContext ctx, String msg, {required bool ok}) {
    final t = FlutterFlowTheme.of(ctx);
    final il = _isLight(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: _p(t.primaryText, 13)),
      backgroundColor: _cardBg(t, isLight: il),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: Duration(seconds: ok ? 2 : 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SankeySettingCubit, SankeySettingState>(
      // Only re-run the listener for snackbar states.
      listenWhen: (_, curr) =>
          curr is SankeySettingSaved || curr is SankeySettingSaveError,
      listener: (ctx, st) {
        if (st is SankeySettingSaved) _snack(ctx, 'Saved!', ok: true);
        if (st is SankeySettingSaveError) _snack(ctx, st.message, ok: false);
      },
      // Skip the UI rebuild for the transient SankeySettingSaved flash
      // (the listener already shows the snackbar; rebuilding would lag).
      buildWhen: (prev, curr) => curr is! SankeySettingSaved,
      builder: (ctx, st) {
        final t = FlutterFlowTheme.of(ctx);
        final cubit = ctx.read<SankeySettingCubit>();

        if (st is SankeySettingInitial || st is SankeySettingLoading) {
          return Container(
            color: t.primaryBackground,
            child: Center(
                child: CircularProgressIndicator(
                    color: t.primary, strokeWidth: 2)),
          );
        }
        if (st is SankeySettingError) {
          return Container(
            color: t.primaryBackground,
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, color: t.error, size: 40),
              const SizedBox(height: 12),
              Text(st.message, style: _p(t.secondaryText, 13)),
              const SizedBox(height: 16),
              _blueBtn(t, 'Retry', cubit.load),
            ])),
          );
        }

        final s = _loaded(st)!;
        final saving = st is SankeySettingSaving;

        return Container(
          color: t.primaryBackground,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ── header bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.primary.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.account_tree_outlined,
                      size: 20, color: t.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Energy Sankey Flow Setting',
                            style: _p(t.primaryText, 19, w: FontWeight.w700)),
                        Text(
                            'Configure energy flow hierarchy for Sankey diagram.',
                            style: _p(t.secondaryText, 12)),
                      ]),
                ),
                // Node Colors button
                TextButton.icon(
                  onPressed: () => showDialog(
                    context: ctx,
                    barrierDismissible: true,
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: _NodeColorsDialog(t: t),
                    ),
                  ),
                  icon: const Icon(Icons.palette_outlined,
                      size: 16, color: Color(0xFF00C6FF)),
                  label: Text(
                    'Node Colors',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF00C6FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: const Color(0xFF00C6FF).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: saving ? null : cubit.save,
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF00C6FF)))
                      : const Icon(Icons.save_outlined,
                          size: 16, color: Color(0xFF00C6FF)),
                  label: Text(saving ? 'Saving…' : 'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF00C6FF),
                        fontWeight: FontWeight.w500,
                      )),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: const Color(0xFF00C6FF).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child:
                  Divider(color: t.primary.withOpacity(0.15), thickness: 0.5),
            ),

            // ── scrollable body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HierarchyTiersCard(s: s, cubit: cubit, t: t),
                    const SizedBox(height: 20),
                    _DeviceMappingCard(s: s, cubit: cubit, t: t),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 1 — Hierarchy Tiers
// ─────────────────────────────────────────────────────────────────────────────
class _HierarchyTiersCard extends StatelessWidget {
  final SankeySettingLoaded s;
  final SankeySettingCubit cubit;
  final FlutterFlowTheme t;
  const _HierarchyTiersCard(
      {required this.s, required this.cubit, required this.t});

  void _addTier() {
    final nextOrder = s.tiers.isEmpty
        ? 0
        : s.tiers.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1;
    cubit.addTier('Tier ${s.tiers.length + 1}', nextOrder);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);
    final borderCol = _borderCol(t, isLight: isLight);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg(t, isLight: isLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Card header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: t.primary.withOpacity(0.25)),
              ),
              child:
                  Icon(Icons.account_tree_outlined, size: 17, color: t.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hierarchy Tiers',
                        style: _p(t.primaryText, 13, w: FontWeight.w700)),
                    Text('Define the levels of your energy flow.',
                        style: _p(t.secondaryText, 11)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.primary.withOpacity(0.2)),
              ),
              child: Text(
                '${s.tiers.length} tier${s.tiers.length == 1 ? '' : 's'}',
                style: _p(t.primary, 11, w: FontWeight.w600),
              ),
            ),
          ]),
        ),
        Divider(height: 1, thickness: 1, color: borderCol),

        // ── Tier rows ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (s.tiers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.layers_outlined,
                        size: 28, color: t.secondaryText.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text('No tiers configured.',
                        style: _p(t.secondaryText, 12)),
                    const SizedBox(height: 4),
                    Text('Add a tier to define your hierarchy.',
                        style: _p(t.secondaryText.withOpacity(0.6), 11)),
                  ]),
                ),
              ),
            for (int i = 0; i < s.tiers.length; i++) ...[
              _buildTierRow(context, i, isLight, borderCol),
              if (i < s.tiers.length - 1) const SizedBox(height: 6),
            ],
            const SizedBox(height: 12),
            _blueBtn(t, '+ Add Hierarchy Tier', _addTier),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTierRow(
      BuildContext context, int i, bool isLight, Color borderCol) {
    final tier = s.tiers[i];
    final dotColor =
        _colorFromHexOrDefault(tier.colorHex, t.primary.withOpacity(0.75));
    return Container(
      decoration: BoxDecoration(
        color: t.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        // Order badge
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: t.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text('${i + 1}',
              style: _p(t.primary, 10, w: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        // Color dot
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: dotColor.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1)
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Label input
        Expanded(
          child: TextFormField(
            initialValue: tier.label,
            onChanged: (val) => cubit.updateTierLabel(tier.id, val),
            style: _p(t.primaryText, 13),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Icon-only remove button
        Tooltip(
          message: 'Remove tier',
          child: InkWell(
            onTap: () => cubit.removeTier(tier.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFD92B47).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFD92B47).withOpacity(0.3)),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 13, color: Color(0xFFD92B47)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 2 — Node Colors (searchable, one-by-one color editor)
// ─────────────────────────────────────────────────────────────────────────────
enum _ColorItemType { tier, node }

class _ColorItem {
  final String id;
  final String label;
  final String colorHex;
  final _ColorItemType type;
  final String? tierId;
  const _ColorItem({
    required this.id,
    required this.label,
    required this.colorHex,
    required this.type,
    this.tierId,
  });
}

/// Dialog opened by the "Node Colors" header button.
/// Uses BlocBuilder so color dots update live after every pick.
class _NodeColorsDialog extends StatefulWidget {
  final FlutterFlowTheme t;
  const _NodeColorsDialog({required this.t});

  @override
  State<_NodeColorsDialog> createState() => _NodeColorsDialogState();
}

class _NodeColorsDialogState extends State<_NodeColorsDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  SankeySettingLoaded? _toLoaded(SankeySettingState st) {
    if (st is SankeySettingLoaded) return st;
    if (st is SankeySettingSaving)
      return SankeySettingLoaded(
          tiers: st.tiers, nodesByTier: st.nodesByTier, devices: st.devices);
    if (st is SankeySettingSaved)
      return SankeySettingLoaded(
          tiers: st.tiers, nodesByTier: st.nodesByTier, devices: st.devices);
    if (st is SankeySettingSaveError)
      return SankeySettingLoaded(
          tiers: st.tiers, nodesByTier: st.nodesByTier, devices: st.devices);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isLight = _isLight(context);

    return BlocBuilder<SankeySettingCubit, SankeySettingState>(
      builder: (ctx, st) {
        final cubit = ctx.read<SankeySettingCubit>();
        final s = _toLoaded(st);
        if (s == null) return const SizedBox.shrink();

        final allItems = <_ColorItem>[
          for (final tier in s.tiers)
            _ColorItem(
                id: tier.id,
                label: tier.label,
                colorHex: tier.colorHex,
                type: _ColorItemType.tier),
          for (final node in s.allNodes.where((n) => !n.removed))
            _ColorItem(
                id: node.id,
                label: node.label,
                colorHex: node.colorHex,
                type: _ColorItemType.node,
                tierId: node.tierId),
        ];

        final filtered = _query.isEmpty
            ? allItems
            : allItems
                .where((i) =>
                    i.label.toLowerCase().contains(_query.toLowerCase()))
                .toList();

        final borderCol = _borderCol(t, isLight: isLight);

        return Dialog(
          backgroundColor: _cardBg(t, isLight: isLight),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: responsiveDialogWidth(ctx, 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dialog header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: t.primary.withOpacity(0.25)),
                      ),
                      child: Icon(Icons.palette_outlined,
                          size: 16, color: t.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Node Colors',
                              style: _p(t.primaryText, 15,
                                  w: FontWeight.w700)),
                          Text('Tap the swatch to change a color.',
                              style: _p(t.secondaryText, 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close,
                          size: 18, color: t.secondaryText),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Search ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      style: _p(t.primaryText, 13),
                      decoration: InputDecoration(
                        hintText: 'Search node or tier…',
                        hintStyle: _p(t.secondaryText, 12),
                        prefixIcon: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.search,
                              size: 16, color: t.secondaryText),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                            minWidth: 36, minHeight: 38),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        filled: true,
                        fillColor: t.primaryBackground,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderCol),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: t.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: borderCol),

                // ── Node list ──────────────────────────────────────────────
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text('No results.',
                                style: _p(t.secondaryText, 13)),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 5),
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: t.primaryBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: isLight
                                        ? t.alternate
                                        : t.primary.withOpacity(0.12)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              child: Row(children: [
                                // TIER / NODE badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.type ==
                                            _ColorItemType.tier
                                        ? t.primary.withOpacity(0.18)
                                        : t.primary.withOpacity(0.07),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.type == _ColorItemType.tier
                                        ? 'TIER'
                                        : 'NODE',
                                    style: _p(t.secondaryText, 8,
                                            w: FontWeight.w700)
                                        .copyWith(letterSpacing: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Live color dot
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _colorFromHexOrDefault(
                                        item.colorHex,
                                        t.primary.withOpacity(0.6)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.black12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Label
                                Expanded(
                                  child: Text(item.label,
                                      style: _p(t.primaryText, 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                // Color swatch → opens HSV picker
                                _ColorSwatchButton(
                                  color: _colorFromHexOrDefault(
                                      item.colorHex,
                                      t.primary.withOpacity(0.75)),
                                  borderColor:
                                      t.primary.withOpacity(0.25),
                                  onPick: (c) {
                                    final hex = c == Colors.transparent
                                        ? ''
                                        : _toHex(c);
                                    if (item.type ==
                                        _ColorItemType.tier) {
                                      cubit.updateTierColor(
                                          item.id, hex);
                                    } else {
                                      final list = s.nodesInTier(
                                          item.tierId!);
                                      final idx = list.indexWhere(
                                          (n) => n.id == item.id);
                                      if (idx >= 0) {
                                        cubit.updateNodeAt(
                                            item.tierId!, idx,
                                            colorHex: hex);
                                      }
                                    }
                                  },
                                ),
                              ]),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 3 — Device Mapping
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceMappingCard extends StatefulWidget {
  final SankeySettingLoaded s;
  final SankeySettingCubit cubit;
  final FlutterFlowTheme t;
  const _DeviceMappingCard(
      {required this.s, required this.cubit, required this.t});

  @override
  State<_DeviceMappingCard> createState() => _DeviceMappingCardState();
}

class _DeviceMappingCardState extends State<_DeviceMappingCard> {
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final cubit = widget.cubit;
    final t = widget.t;

    final isLight = _isLight(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg(t, isLight: isLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderCol(t, isLight: isLight)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Card header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: t.primary.withOpacity(0.25)),
              ),
              child: Icon(Icons.device_hub_outlined, size: 17, color: t.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Device Mapping',
                        style: _p(t.primaryText, 13, w: FontWeight.w700)),
                    Text('Map devices and data fields to each node.',
                        style: _p(t.secondaryText, 11)),
                  ]),
            ),
            if (s.tiers.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '${s.tiers.length} tier${s.tiers.length == 1 ? '' : 's'}',
                  style: _p(t.primary, 11, w: FontWeight.w600),
                ),
              ),
          ]),
        ),
        Divider(
            height: 1,
            thickness: 1,
            color: _borderCol(t, isLight: _isLight(context))),
        // ── Body ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: s.tiers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.device_hub_outlined,
                          size: 30,
                          color: t.secondaryText.withOpacity(0.35)),
                      const SizedBox(height: 10),
                      Text('No hierarchy tiers configured.',
                          style: _p(t.secondaryText, 12)),
                      const SizedBox(height: 4),
                      Text('Add a tier above to start mapping devices.',
                          style:
                              _p(t.secondaryText.withOpacity(0.6), 11)),
                    ]),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScrollConfiguration(
                      behavior: _DragScrollBehavior(),
                      child: Scrollbar(
                        controller: _hScroll,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _hScroll,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: _NestedTable(s: s, cubit: cubit, t: t),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _blueBtn(t, '+ Add ${s.tiers[0].label}',
                        () => cubit.addNodeToTier(s.tiers[0].id)),
                  ],
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NestedTable — groups rows by Source, each node has multi-field mapping
// ─────────────────────────────────────────────────────────────────────────────
class _NestedTable extends StatelessWidget {
  final SankeySettingLoaded s;
  final SankeySettingCubit cubit;
  final FlutterFlowTheme t;
  const _NestedTable({required this.s, required this.cubit, required this.t});

  Widget _hdrCell(String label, double width,
      {bool borderRight = false,
      bool isLight = false,
      bool accentLeft = false}) {
    final borderCol = _borderCol(t, isLight: isLight);
    return Container(
      width: width,
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          right: borderRight
              ? BorderSide(color: borderCol)
              : BorderSide.none,
          left: accentLeft
              ? BorderSide(color: t.primary.withOpacity(0.6), width: 3)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.only(left: accentLeft ? 10 : 14, right: 10),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accentLeft) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: _p(
                accentLeft
                    ? t.primary.withOpacity(0.9)
                    : t.secondaryText.withOpacity(0.6),
                10,
                w: FontWeight.w700,
              ).copyWith(letterSpacing: 1.2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext ctx, String msg) {
    final il = _isLight(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: _p(t.primaryText, 12)),
      backgroundColor: _cardBg(t, isLight: il),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _setDevice(BuildContext ctx, String tierId, int rowIdx, String dev) {
    if (dev.isNotEmpty) {
      final allNodes = s.allNodes;
      for (final n in allNodes) {
        if (n.deviceId == dev) {
          // If it's the exact same node (same id), allowing it is fine (no change)
          // but usually this is called when user selects a NEW value.
          // We must check if the node that HAS this device is a DIFFERENT node.
          final tierList = s.nodesInTier(tierId);
          if (rowIdx < tierList.length && tierList[rowIdx].id != n.id) {
             _snack(ctx, 'Device "$dev" is already mapped to "${n.label}".');
             return;
          }
        }
      }
    }
    cubit.updateNodeAt(tierId, rowIdx, deviceId: dev);
  }

  /// Sets a specific field slot [fieldIdx] for the node at [rowIdx] in [tierId].
  void _setField(
      BuildContext ctx, String tierId, int rowIdx, int fieldIdx, String field) {
    if (field.isNotEmpty) {
      final tierList = s.nodesInTier(tierId);
      // Also check within the same node's other slots
      final currentFields = List<String>.from(tierList[rowIdx].fields);
      for (int j = 0; j < currentFields.length; j++) {
        if (j == fieldIdx) continue;
        if (currentFields[j] == field) {
          _snack(ctx, 'Data mapping "$field" is already used in this row.');
          return;
        }
      }
    }
    cubit.updateNodeFieldAt(tierId, rowIdx, fieldIdx, field);
  }

  /// Adds an empty field slot to a node (max _kMaxFields).
  void _addField(BuildContext ctx, String tierId, int rowIdx) {
    final tierList = s.nodesInTier(tierId);
    if (rowIdx >= tierList.length) return;
    final node = tierList[rowIdx];
    if (node.fields.length >= _kMaxFields) {
      _snack(ctx, 'Maximum $_kMaxFields data mappings per node.');
      return;
    }
    cubit.addNodeField(tierId, rowIdx);
  }

  /// Removes a field slot from a node.
  void _removeField(String tierId, int rowIdx, int fieldIdx) {
    cubit.removeNodeField(tierId, rowIdx, fieldIdx);
  }

  Future<bool> _confirmRemove(
      BuildContext ctx, FlutterFlowTheme t, String title, String body) async {
    final il = _isLight(ctx);
    final res = await showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      builder: (dCtx) => AlertDialog(
        backgroundColor: _cardBg(t, isLight: il),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _borderCol(t, isLight: il)),
        ),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: t.error, size: 20),
          const SizedBox(width: 10),
          Text(title, style: _p(t.primaryText, 15, w: FontWeight.w700)),
        ]),
        content: Text(body, style: _p(t.secondaryText, 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text('Cancel',
                style: _p(t.secondaryText, 12, w: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text('Remove', style: _p(Colors.white, 12, w: FontWeight.w600)),
          ),
        ],
      ),
    );
    return res == true;
  }



  int _calcRowSpan(SankeyNode node, List<SankeyTier> tiers, int ti, Map<String, SankeyNode> byId) {
    if (ti >= tiers.length - 1) return 1;
    final nextTierId = tiers[ti + 1].id;
    final children = node.targetIds
        .map((id) => byId[id])
        .whereType<SankeyNode>()
        .where((n) => n.tierId == nextTierId && !n.removed)
        .toList();

    if (children.isEmpty) return 1;
    int sum = 0;
    for (final c in children) {
      sum += _calcRowSpan(c, tiers, ti + 1, byId);
    }
    return sum;
  }

  Widget _buildFlatRow(BuildContext context, SankeyNode node, SankeyTier tier,
      String parentLabel, {bool isSource = false}) {
    final tierList = s.nodesInTier(tier.id);
    final rowIdx = tierList.indexWhere((x) => x.id == node.id);
    final used = s.usedDevices;
    final fields =
        node.fields.isEmpty ? <String>[''] : List<String>.from(node.fields);

    final isLight = _isLight(context);
    final borderCol = _borderCol(t, isLight: isLight);
    final cellBorder = BorderSide(color: borderCol);

    // ── Removed placeholder ──────────────────────────────────────────────────
    if (node.removed) {
      return Container(
        width: _kCol + (isSource ? 60 : 0),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: t.primary.withOpacity(0.02),
          border: Border(bottom: cellBorder),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: _addBtn(t, '+ Restore to $parentLabel',
            () => cubit.restoreNodeAt(tier.id, rowIdx)),
      );
    }

    final labelWidth = _kTier + (isSource ? 60 : 0);
    final nodeColor =
        _colorFromHexOrDefault(node.colorHex, t.primary.withOpacity(0.6));

    // ── Source node gets a stronger visual identity ──────────────────────────
    final rowBg = isSource
        ? t.primary.withOpacity(0.04)
        : (rowIdx.isEven ? t.primary.withOpacity(0.018) : Colors.transparent);

    return Container(
      width: _kCol + (isSource ? 60 : 0),
      // Vertical centering when stretched by IntrinsicHeight (fixes source alignment)
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: cellBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Label cell ────────────────────────────────────────────────────
          Container(
            width: labelWidth,
            decoration: BoxDecoration(
              border: Border(
                right: cellBorder,
                left: isSource
                    ? BorderSide(color: t.primary.withOpacity(0.5), width: 3)
                    : BorderSide.none,
              ),
            ),
            padding: EdgeInsets.only(
              left: isSource ? 10 : 12,
              right: 8,
              top: 10,
              bottom: 10,
            ),
            child: Row(children: [
              // Glowing color dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: nodeColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabelInput(
                  value: node.label,
                  t: t,
                  onChanged: (v) =>
                      cubit.updateNodeAt(tier.id, rowIdx, label: v),
                ),
              ),
              const SizedBox(width: 6),
              // Remove icon button
              Tooltip(
                message: isSource ? 'Remove source' : 'Remove node',
                child: InkWell(
                  onTap: () async {
                    final ok = await _confirmRemove(
                      context,
                      t,
                      isSource ? 'Remove Source?' : 'Remove node?',
                      isSource
                          ? 'This will remove this source and all its descendants.'
                          : 'Delete this node? Descendants will be preserved.',
                    );
                    if (ok) cubit.removeNodeById(node.id);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD92B47).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFD92B47).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.close,
                        size: 11, color: Color(0xFFD92B47)),
                  ),
                ),
              ),
            ]),
          ),

          // ── Device ID cell ────────────────────────────────────────────────
          Container(
            width: _kDev,
            decoration: BoxDecoration(border: Border(right: cellBorder)),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _DeviceDrop(
              value: node.deviceId,
              devices: s.devices,
              labels: s.deviceLabels,
              usedDevices: used,
              deviceValues: s.deviceValues,
              t: t,
              onChanged: (v) {
                if (rowIdx >= 0) _setDevice(context, tier.id, rowIdx, v);
              },
            ),
          ),

          // ── Data mapping cell ─────────────────────────────────────────────
          Container(
            width: _kField,
            clipBehavior: Clip.hardEdge,
            decoration:
                BoxDecoration(border: Border(right: cellBorder)),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int fi = 0; fi < fields.length; fi++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: _MapFieldDrop(
                            value: fields[fi],
                            values: s.deviceValues[node.deviceId],
                            t: t,
                            onChanged: (v) =>
                                _setField(context, tier.id, rowIdx, fi, v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: fields.length <= 1 ? 'Clear' : 'Remove',
                        child: InkWell(
                          onTap: () {
                            if (fields.length <= 1) {
                              _setField(context, tier.id, rowIdx, 0, '');
                            } else {
                              _removeField(tier.id, rowIdx, fi);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: t.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.close,
                                size: 10,
                                color: t.error.withOpacity(0.7)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                if (fields.length < _kMaxFields)
                  GestureDetector(
                    onTap: () => _addField(context, tier.id, rowIdx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: t.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 9, color: t.primary),
                          const SizedBox(width: 3),
                          Text('Add field',
                              style: _p(t.primary, 8.5,
                                  w: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tinyBtn(FlutterFlowTheme t, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? t.primary;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: c.withOpacity(0.85)),
            const SizedBox(width: 3),
            Text(label, style: _p(c.withOpacity(0.9), 8.5, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final tiers = s.tiers;
    if (tiers.isEmpty) return const SizedBox.shrink();

    final isLight = _isLight(context);
    // Guard a small right-side slack to avoid deep-recursive row width
    // accumulation causing debug RenderFlex overflow at the far edge.
    final totalW = tiers.length * _kCol + 60.0 + _kTableRightGuard;

    final byId = <String, SankeyNode>{
      for (final nd in s.allNodes) nd.id: nd
    };

    final borderCol = _borderCol(t, isLight: isLight);

    return Container(
      width: totalW,
      decoration: BoxDecoration(
        color: isLight ? t.secondaryBackground : t.primaryBackground,
        border: Border.all(color: borderCol),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip ──────────────────────────────────────────────
          Container(
            width: totalW,
            decoration: BoxDecoration(
              color: isLight
                  ? t.alternate.withOpacity(0.6)
                  : t.primary.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            child: Row(children: [
              _hdrCell('SOURCES', _kTier + 60,
                  borderRight: true, isLight: isLight),
              _hdrCell('DEVICE ID', _kDev,
                  borderRight: true, isLight: isLight),
              _hdrCell('DATA MAPPING', _kField,
                  borderRight: tiers.length > 1, isLight: isLight),
              for (int i = 1; i < tiers.length; i++) ...[
                _hdrCell(tiers[i].label.toUpperCase(), _kTier,
                    borderRight: true, isLight: isLight, accentLeft: true),
                _hdrCell('DEVICE ID', _kDev,
                    borderRight: true, isLight: isLight),
                _hdrCell('DATA MAPPING', _kField,
                    borderRight: i < tiers.length - 1, isLight: isLight),
              ],
            ]),
          ),

          // ── Body: Source-based groups ─────────────────────────────────
          if (s.nodesInTier(tiers[0].id).where((n) => !n.removed).isEmpty)
            Container(
              width: totalW,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: _addBtn(
                t,
                '+ Add your first ${tiers[0].label}',
                () => cubit.addNodeToTier(tiers[0].id),
              ),
            )
          else ...[
            for (final src in s.nodesInTier(tiers[0].id).where((n) => !n.removed))
              _buildSourceGroup(context, src, tiers, byId),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceGroup(BuildContext context, SankeyNode source,
      List<SankeyTier> tiers, Map<String, SankeyNode> byId) {
    final isLight = _isLight(context);
    final borderCol = _borderCol(t, isLight: isLight);
    final border = BorderSide(color: borderCol);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderCol, width: 1.5),
        ),
      ),
      child: _renderRecursiveBranch(
          context, source, tiers, 0, byId, border, isSource: true),
    );
  }

  Widget _renderRecursiveBranch(BuildContext context, SankeyNode parent,
      List<SankeyTier> tiers, int ti, Map<String, SankeyNode> byId, BorderSide border, {bool isSource = false}) {
    if (ti >= tiers.length) return const SizedBox.shrink();

    final isLight = _isLight(context);
    final tier = tiers[ti];
    
    // For the source root, we render it specifically.
    // For others, we render the 'parent' and then its children.
    
    // In this recursive model:
    // Column(
    //   children: [
    //      Row(
    //        [Node, _renderRecursiveBranch(children)]
    //      )
    //   ]
    // )

    final children = parent.targetIds
        .map((id) => byId[id])
        .whereType<SankeyNode>()
        .where((n) => n.tierId == tier.id) // Include removed nodes so their children can be rendered
        .toList();

    if (isSource) {
      final expectedWidth = (tiers.length - ti) * _kCol + 60.0;
      return IntrinsicHeight(
        child: SizedBox(
          width: expectedWidth,
          child: ClipRect(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFlatRow(context, parent, tier, 'Source', isSource: true),
                if (ti + 1 < tiers.length)
                  _renderRecursiveBranch(context, parent, tiers, ti + 1, byId, border),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children)
          IntrinsicHeight(
            child: SizedBox(
              width: (tiers.length - ti) * _kCol,
              child: ClipRect(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFlatRow(context, child, tier, parent.label, isSource: false),
                    if (ti + 1 < tiers.length)
                      _renderRecursiveBranch(context, child, tiers, ti + 1, byId, border),
                  ],
                ),
              ),
            ),
          ),
        
        // Add child button row
        if (ti < tiers.length)
          SizedBox(
            width: (tiers.length - ti) * _kCol,
            child: Row(
              children: [
                Container(
                  width: _kCol,
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.02),
                    border: Border(right: border),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: _addBtn(
                    t,
                    '+ Add to ${parent.label}',
                    () => cubit.addChildUnder(parent.id, tier.id),
                  ),
                ),
                if (ti + 1 < tiers.length)
                  for (int k = ti + 1; k < tiers.length; k++)
                    Container(
                      width: _kCol,
                      decoration: BoxDecoration(
                        border: Border(
                          right: k < tiers.length - 1
                              ? border
                              : BorderSide.none,
                        ),
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

}

class _LabelInput extends StatefulWidget {
  final String value;
  final FlutterFlowTheme t;
  final ValueChanged<String> onChanged;

  const _LabelInput({required this.value, required this.t, required this.onChanged});

  @override
  State<_LabelInput> createState() => _LabelInputState();
}

class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final ValueChanged<Color> onPick;

  const _ColorSwatchButton({
    required this.color,
    required this.borderColor,
    required this.onPick,
  });

  Future<void> _openPicker(BuildContext context) async {
    var hsv = HSVColor.fromColor(
        color == Colors.transparent ? const Color(0xFF2196F3) : color);
    final hexCtrl = TextEditingController(text: _toHex(hsv.toColor()));

    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          void update(HSVColor next) {
            setDialogState(() => hsv = next);
            hexCtrl.text = _toHex(hsv.toColor());
          }

          final surface = Theme.of(context).colorScheme.surface;
          final onSurface = Theme.of(context).colorScheme.onSurface;

          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            titlePadding:
                const EdgeInsets.fromLTRB(20, 18, 20, 0),
            contentPadding:
                const EdgeInsets.fromLTRB(20, 14, 20, 0),
            title: Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: hsv.toColor(),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black26),
                ),
              ),
              const SizedBox(width: 10),
              Text('Pick Color',
                  style: _p(onSurface, 14, w: FontWeight.w700)),
            ]),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SV square + Hue bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saturation / Value area
                      GestureDetector(
                        onPanDown: (d) {
                          final s = (d.localPosition.dx / 224).clamp(0.0, 1.0);
                          final v = 1.0 - (d.localPosition.dy / 160).clamp(0.0, 1.0);
                          update(hsv.withSaturation(s).withValue(v));
                        },
                        onPanUpdate: (d) {
                          final s = (d.localPosition.dx / 224).clamp(0.0, 1.0);
                          final v = 1.0 - (d.localPosition.dy / 160).clamp(0.0, 1.0);
                          update(hsv.withSaturation(s).withValue(v));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 224,
                            height: 160,
                            child: CustomPaint(painter: _SvPainter(hsv)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Hue bar
                      GestureDetector(
                        onPanDown: (d) {
                          final h = (d.localPosition.dy / 160).clamp(0.0, 1.0) * 360;
                          update(hsv.withHue(h));
                        },
                        onPanUpdate: (d) {
                          final h = (d.localPosition.dy / 160).clamp(0.0, 1.0) * 360;
                          update(hsv.withHue(h));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 18,
                            height: 160,
                            child: CustomPaint(painter: _HuePainter(hsv.hue)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Hex input
                  TextField(
                    controller: hexCtrl,
                    style: _p(onSurface, 13),
                    decoration: InputDecoration(
                      prefixText: '# ',
                      prefixStyle: _p(onSurface.withOpacity(0.45), 13),
                      hintText: 'RRGGBB',
                      hintStyle: _p(onSurface.withOpacity(0.3), 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: onSurface.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: onSurface.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      final cleaned = val.replaceAll('#', '').trim();
                      if (cleaned.length == 6) {
                        final v = int.tryParse('FF$cleaned', radix: 16);
                        if (v != null) {
                          update(HSVColor.fromColor(Color(v)));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text('Cancel',
                    style: _p(onSurface.withOpacity(0.55), 13)),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(Colors.transparent),
                child: Text('Clear',
                    style: _p(onSurface.withOpacity(0.55), 13)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(hsv.toColor()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hsv.toColor(),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Use',
                    style: _p(Colors.white, 13, w: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );

    hexCtrl.dispose();

    if (result != null) {
      if (result == Colors.transparent) {
        onPick(Colors.transparent);
      } else {
        onPick(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color == Colors.transparent ? Colors.black12 : color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Icon(Icons.palette_outlined, size: 12, color: Colors.black54),
      ),
    );
  }
}

class _LabelInputState extends State<_LabelInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_LabelInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !FocusScope.of(context).hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: _p(widget.t.primaryText, 12, w: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.t.primary.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.t.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          filled: true,
          fillColor: widget.t.primary.withOpacity(0.03),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device dropdown
// ─────────────────────────────────────────────────────────────────────────────
// Device dropdown — StatefulWidget with MEMOIZED items list.
// The devices list from the cubit is the same object reference between
// sibling dropdown-change emits (only nodesByTier changes, not devices).
// identical() short-circuits item rebuild on >95% of renders.
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceDrop extends StatefulWidget {
  final String value;
  final List<String> devices;
  final Map<String, String> labels;
  final Set<String> usedDevices;
  final FlutterFlowTheme t;
  final ValueChanged<String> onChanged;
  const _DeviceDrop({
    required this.value,
    required this.devices,
    required this.labels,
    required this.usedDevices,
    required this.t,
    required this.onChanged,
    this.deviceValues = const {},
  });

  final Map<String, Map<String, double>> deviceValues;

  @override
  State<_DeviceDrop> createState() => _DeviceDropState();
}

class _DeviceDropState extends State<_DeviceDrop> {
  late List<DropdownMenuItem<String>> _items;
  String? _lastValue;
  List<String>? _lastDevices;

  @override
  void initState() {
    super.initState();
    _rebuildItems();
  }

  @override
  void didUpdateWidget(_DeviceDrop old) {
    super.didUpdateWidget(old);
    // Only recreate the heavy list when the source data or usage changed.
    if (!identical(old.devices, widget.devices) ||
        !identical(old.usedDevices, widget.usedDevices) ||
        !identical(old.deviceValues, widget.deviceValues) ||
        old.value != widget.value) {
      _rebuildItems();
    }
  }

  void _rebuildItems() {
    _lastDevices = widget.devices;
    _lastValue = widget.value;
    final baseList = widget.devices.contains('')
        ? widget.devices
        : ['', ...widget.devices];

    // Filter out already used devices across all tables,
    // but ALWAYS keep the current selection in the list.
    final available = baseList.where((id) {
      if (id.isEmpty) return true;
      if (id == widget.value) return true;
      return !widget.usedDevices.contains(id);
    }).toList();

    final all = (widget.value.isNotEmpty && !available.contains(widget.value))
        ? [widget.value, ...available]
        : available;
    _items = all
        .map((id) {
          final label = widget.labels[id] ?? id;
          final val = widget.deviceValues[id]?['P(kW)'];
          final valStr = val != null ? ' (${val.toStringAsFixed(1)} kW)' : '';
          
          return DropdownMenuItem<String>(
              value: id,
              child: Text(id.isEmpty ? '- None -' : '$label$valStr',
                  style: _p(
                      id.isEmpty
                          ? widget.t.secondaryText
                          : widget.t.primaryText,
                      12),
                  overflow: TextOverflow.ellipsis),
            );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);
    final baseList =
        widget.devices.contains('') ? widget.devices : ['', ...widget.devices];
    final all = (widget.value.isNotEmpty && !baseList.contains(widget.value))
        ? [widget.value, ...baseList]
        : baseList;
    final safe = all.contains(widget.value) ? widget.value : null;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: widget.t.primaryBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isLight
                ? widget.t.alternate
                : widget.t.primary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safe,
          hint: Text('Mapping\u2026', style: _p(widget.t.secondaryText, 11)),
          dropdownColor: widget.t.secondaryBackground,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 12, color: widget.t.secondaryText),
          items: _items,
          onChanged: (v) {
            if (v != null) widget.onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data-mapping field dropdown — StatefulWidget with items built ONCE.
// _opts is a 9-entry static map that never changes, so we create the
// DropdownMenuItem list in initState and never touch it again.
// ─────────────────────────────────────────────────────────────────────────────
class _MapFieldDrop extends StatefulWidget {
  final String value;
  final Map<String, double>? values;
  final FlutterFlowTheme t;
  final ValueChanged<String> onChanged;
  const _MapFieldDrop({
    required this.value,
    this.values,
    required this.t,
    required this.onChanged,
  });

  static const _opts = <String, String>{
    '': '- None -',
    'P(kW)': 'Active Power',
    'PeakDemand': 'Peak Demand',
    'Edel': 'Energy Delivered',
    'Erec': 'Energy Received',
    'Eapp': 'Apparent Energy',
    'daily_kWh': 'Daily Usage',
    'monthly_kWh': 'Monthly Usage',
    'yearly_kWh': 'Yearly Usage',
  };

  static String normalize(String raw) {
    if (raw == '- None -') return '';
    if (raw.contains(' - ')) return raw.split(' - ').first.trim();
    if (raw.contains(' \u2014 ')) return raw.split(' \u2014 ').first.trim();
    return raw;
  }

  @override
  State<_MapFieldDrop> createState() => _MapFieldDropState();
}

class _MapFieldDropState extends State<_MapFieldDrop> {
  /// Cached items — options never change so we build them once.
  late List<DropdownMenuItem<String>> _items;

  @override
  void initState() {
    super.initState();
    _rebuildItems();
  }

  @override
  void didUpdateWidget(_MapFieldDrop old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || !identical(old.values, widget.values)) {
      _rebuildItems();
    }
  }

  void _rebuildItems() {
    _items = _MapFieldDrop._opts.entries
        .map((e) {
          final rawField = e.key;
          final label = e.value;
          final val = widget.values?[rawField];
          
          String suffix = '';
          if (val != null) {
             final unit = _unitFor(rawField);
             suffix = ' (${val.toStringAsFixed(1)} $unit)';
          }

          return DropdownMenuItem<String>(
              value: e.key,
              child: Text('$label$suffix',
                  style: _p(widget.t.primaryText, 11),
                  overflow: TextOverflow.ellipsis),
            );
        })
        .toList();
  }

  String _unitFor(String f) {
    if (f.contains('kWh')) return 'kWh';
    if (f == 'Edel' || f == 'Erec') return 'kWh';
    if (f == 'Eapp') return 'kVAh';
    return 'kW';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);
    final normalized = _MapFieldDrop.normalize(widget.value);
    final safe =
        _MapFieldDrop._opts.containsKey(normalized) ? normalized : null;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.t.primaryBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isLight
                ? widget.t.alternate
                : widget.t.primary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safe,
          hint: Text('Mapping\u2026', style: _p(widget.t.secondaryText, 11)),
          dropdownColor: widget.t.secondaryBackground,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 14, color: widget.t.secondaryText),
          items: _items,
          onChanged: (v) {
            if (v != null) widget.onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HSV color picker painters
// ─────────────────────────────────────────────────────────────────────────────
class _SvPainter extends CustomPainter {
  final HSVColor hsv;
  _SvPainter(this.hsv);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    // Saturation gradient: white → hue color (left → right)
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            LinearGradient(colors: [Colors.white, hueColor]).createShader(rect),
    );

    // Value gradient: transparent → black (top → bottom)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    // Picker circle indicator
    final cx = hsv.saturation * size.width;
    final cy = (1 - hsv.value) * size.height;
    canvas.drawCircle(Offset(cx, cy), 7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), 8,
        Paint()
          ..color = Colors.black38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_SvPainter o) =>
      o.hsv.hue != hsv.hue ||
      o.hsv.saturation != hsv.saturation ||
      o.hsv.value != hsv.value;
}

class _HuePainter extends CustomPainter {
  final double hue;
  _HuePainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Rainbow gradient top → bottom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ).createShader(rect),
    );

    // Indicator line
    final y = (hue / 360) * size.height;
    canvas.drawLine(Offset(0, y), Offset(size.width, y),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5);
    canvas.drawLine(Offset(0, y), Offset(size.width, y),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(_HuePainter o) => o.hue != hue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag-to-scroll behavior (enables mouse-drag panning on web)
// ─────────────────────────────────────────────────────────────────────────────
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared buttons
// ─────────────────────────────────────────────────────────────────────────────
Widget _blueBtn(FlutterFlowTheme t, String label, VoidCallback onTap) =>
    ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF13B8FF),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: _p(Colors.white, 10.5, w: FontWeight.w700)),
    );

Widget _addBtn(FlutterFlowTheme t, String label, VoidCallback? onTap) =>
    ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.add, size: 11,
          color: Colors.white.withOpacity(onTap != null ? 1 : 0.45)),
      label: Text(label,
          style: _p(
              Colors.white.withOpacity(onTap != null ? 1 : 0.45), 10,
              w: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: onTap != null
            ? const Color(0xFF13B8FF)
            : const Color(0xFF13B8FF).withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

Widget _redBtn(FlutterFlowTheme t, String label, VoidCallback onTap) =>
    ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: t.error,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: _p(Colors.white, 11, w: FontWeight.w600)),
    );

/// Compact red "Remove" button used inline in table cells and tier rows.
Widget _removeBtn(FlutterFlowTheme t, VoidCallback onTap) =>
    ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD92B47),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('Remove', style: _p(Colors.white, 9.5, w: FontWeight.w700)),
    );
