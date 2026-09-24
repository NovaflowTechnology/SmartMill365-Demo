import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '../kwh_theme.dart';

// ── Card container ────────────────────────────────────────────────────────────
Widget kwhCard(bool isLight, FlutterFlowTheme theme, {required Widget child, Color? borderColor}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : KwhColors.cardBg,
        border: Border.all(color: borderColor ?? (isLight ? theme.alternate : KwhColors.border)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );

// ── Label text style ──────────────────────────────────────────────────────────
TextStyle kwhLblStyle(bool isLight, FlutterFlowTheme theme) => GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: isLight ? theme.secondaryText : Colors.white38,
      letterSpacing: 1.2,
    );

// ── Field wrapper (label + child) ─────────────────────────────────────────────
// crossAxisAlignment.stretch so every field's box (text input, dropdown,
// locked display, etc.) fills the full column width — without it, plain
// Containers/dropdowns shrink-wrap their content while TextFields greedily
// fill the row, leaving fields in the same row visibly different widths.
Widget kwhField(String label, bool isLight, FlutterFlowTheme theme, Widget child) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: kwhLblStyle(isLight, theme)),
      const SizedBox(height: 6),
      child,
    ]);

// ── Text input ────────────────────────────────────────────────────────────────
Widget kwhTextField(TextEditingController ctrl, String hint, bool isLight, FlutterFlowTheme theme,
        {bool enabled = true, Widget? suffixIcon, TextInputType keyboardType = TextInputType.number}) =>
    TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 17, color: enabled ? (isLight ? theme.primaryText : Colors.white) : (isLight ? theme.secondaryText : Colors.white54)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 17, color: isLight ? theme.secondaryText : Colors.white38),
        filled: true,
        fillColor: enabled ? (isLight ? theme.primaryBackground : KwhColors.darkInput) : (isLight ? theme.alternate : KwhColors.border.withOpacity(0.15)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: suffixIcon,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.border)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.cyan)),
      ),
    );

// ── Cyberpunk-style dropdown ───────────────────────────────────────────────────
// Matches the `_buildCyberpunkDropdown` widget used on the other dashboard
// pages (energy comparison/details, equipment overview/details, max demand
// monitoring, TNB bill simulator) — glowing left accent bar, cyan/theme-primary
// border, hint text that's replaced by the selected value. Kept here (rather
// than duplicated per-file like those pages do) since this module already
// centralizes its shared styling in this file.
Widget kwhCyberpunkDropdown({
  required bool isLight,
  required FlutterFlowTheme theme,
  required String? value,
  required List<String> options,
  required String hint,
  required double width,
  required void Function(String?) onChanged,
  String Function(String)? labelBuilder,
}) {
  const cyan = KwhColors.cyan;
  final safeValue = (value != null && options.contains(value)) ? value : null;
  return Container(
    width: width,
    height: 40,
    decoration: BoxDecoration(
      color: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
      border: Border.all(color: isLight ? theme.alternate : cyan.withOpacity(0.5), width: 1.2),
      borderRadius: BorderRadius.circular(6),
      boxShadow: [BoxShadow(color: cyan.withOpacity(0.08), blurRadius: 8)],
    ),
    child: Row(
      children: [
        Container(
          width: 3,
          decoration: BoxDecoration(
            color: isLight ? theme.primary : cyan,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
            boxShadow: [BoxShadow(color: (isLight ? theme.primary : cyan).withOpacity(0.8), blurRadius: 6)],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                dropdownColor: isLight ? theme.secondaryBackground : const Color(0xFF071A2E),
                menuMaxHeight: 300,
                hint: Text(hint, style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : cyan.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                style: GoogleFonts.poppins(color: isLight ? theme.txtPrimary : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: isLight ? theme.primary : cyan, size: 22),
                items: options.map((opt) => DropdownMenuItem<String>(
                  value: opt,
                  child: Text(labelBuilder?.call(opt) ?? opt, style: GoogleFonts.poppins(color: isLight ? theme.txtPrimary : Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Dropdown (fixed value, no "All"/hint state) ───────────────────────────────
// Thin wrapper around kwhCyberpunkDropdown for fields that always resolve to a
// real value (Machine/Shift/Department/compare items) rather than an optional
// filter. `width` defaults to fill the parent, matching the stretch-aligned
// field columns (kwhField/_fieldReq) most callers sit in — pass an explicit
// pixel width when used inline in a non-stretching Row instead.
Widget kwhDrop(List<String> items, String value, void Function(String?) onChanged, bool isLight, FlutterFlowTheme theme, {double width = double.infinity}) {
  final val = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
  return kwhCyberpunkDropdown(
    isLight: isLight,
    theme: theme,
    value: val,
    options: items,
    hint: 'Select',
    width: width,
    onChanged: onChanged,
  );
}

// ── Filter chips row ──────────────────────────────────────────────────────────
Widget kwhChips(String label, List<String> opts, String sel, void Function(String) onSel, bool isLight, FlutterFlowTheme theme) =>
    Row(children: [
      Text('$label  ', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? theme.secondaryText : Colors.white38, letterSpacing: 1)),
      ...opts.map((o) {
        final isSel = o == sel;
        return GestureDetector(
          onTap: () => onSel(o),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSel ? KwhColors.cyan : (isLight ? theme.primaryBackground : KwhColors.darkInput),
              border: Border.all(color: isSel ? KwhColors.cyan : (isLight ? theme.alternate : KwhColors.border)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(o, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isSel ? Colors.black : (isLight ? theme.secondaryText : Colors.white54))),
          ),
        );
      }),
    ]);

// ── Solid button ──────────────────────────────────────────────────────────────
Widget kwhBtn(String label, {required VoidCallback onTap, required Color bg, required Color tc}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: tc)),
      ),
    );

// ── Action / toggle button ────────────────────────────────────────────────────
Widget kwhActionBtn(String label, {required VoidCallback onTap, bool active = false, Color? color, required bool isLight, required FlutterFlowTheme theme}) {
  final bg = active ? (color ?? KwhColors.cyan) : (isLight ? theme.secondaryBackground : KwhColors.cardBg);
  final tc = active ? (color == KwhColors.amber ? Colors.black : Colors.white) : (isLight ? theme.secondaryText : Colors.white54);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, border: Border.all(color: isLight ? theme.alternate : KwhColors.border)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: tc)),
    ),
  );
}

// ── Mode toggle button (Compare tab) ──────────────────────────────────────────
Widget kwhModeBtn(String mode, String current, VoidCallback onTap, bool isLight, FlutterFlowTheme theme) {
  final sel = current == mode;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: sel ? KwhColors.cyan : (isLight ? theme.primaryBackground : KwhColors.darkInput),
        border: Border.all(color: sel ? KwhColors.cyan : KwhColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(mode, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: sel ? Colors.black : (isLight ? theme.secondaryText : Colors.white54))),
    ),
  );
}

// ── Status message (error / success) ─────────────────────────────────────────
Widget kwhMsg(String text, Color color, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.poppins(fontSize: 16, color: color)),
      ]),
    );

// ── Empty state placeholder ───────────────────────────────────────────────────
Widget kwhEmpty(bool isLight, FlutterFlowTheme theme) =>
    Center(child: Text('No data', style: GoogleFonts.poppins(color: isLight ? theme.secondaryText : Colors.white38)));

Widget kwhLineLegend(Color c, String label, bool isLight, FlutterFlowTheme theme) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 20, height: 2, color: c),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.secondaryText : Colors.white54)),
    ]);

// ── Chart legends ─────────────────────────────────────────────────────────────
Widget kwhDashLegend(Color c, String label, bool isLight, FlutterFlowTheme theme) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(3, (_) => Row(children: [Container(width: 4, height: 2, color: c), const SizedBox(width: 2)])),
      const SizedBox(width: 2),
      Text(label, style: GoogleFonts.poppins(fontSize: 15, color: isLight ? theme.secondaryText : Colors.white54)),
    ]);

// ── Status dot ────────────────────────────────────────────────────────────────
Widget kwhDot(Color c, String label, bool isLight, FlutterFlowTheme theme) => Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white54)),
    ]);

// ── Large status number ───────────────────────────────────────────────────────
Widget kwhStatusNum(String v, Color c) =>
    Text(v, style: GoogleFonts.poppins(fontSize: 33, fontWeight: FontWeight.w700, color: c));

// ── Small colour badge ────────────────────────────────────────────────────────
Widget kwhBadge(String t, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
      child: Text(t, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
    );

// ── Bullet point line ─────────────────────────────────────────────────────────
Widget kwhBullet(String text, Color color, bool isLight, FlutterFlowTheme theme) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 16, color: isLight ? theme.primaryText : Colors.white70))),
      ]),
    );

// ── Stat column (label + big value) ──────────────────────────────────────────
Widget kwhStatCol(String lbl, String val, bool isLight, FlutterFlowTheme theme, {bool big = false}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: kwhLblStyle(isLight, theme)),
      Text(val, style: GoogleFonts.poppins(fontSize: big ? 24 : 20, fontWeight: FontWeight.w700, color: isLight ? theme.primaryText : Colors.white)),
    ]);

// ── Stat box card ─────────────────────────────────────────────────────────────
Widget kwhStatBox(String label, String value, String sub, Color color, bool isLight, FlutterFlowTheme theme) =>
    kwhCard(isLight, theme, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: kwhLblStyle(isLight, theme)),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.w700, color: color)),
      Text(sub,   style: GoogleFonts.poppins(fontSize: 14, color: isLight ? theme.secondaryText : Colors.white38)),
    ]));

// ── Threshold text field (used in thresholds dialog) ─────────────────────────
Widget kwhTField(String label, TextEditingController ctrl, bool isLight, FlutterFlowTheme theme) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: kwhLblStyle(isLight, theme)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(fontSize: 18, color: isLight ? theme.primaryText : Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: isLight ? theme.primaryBackground : KwhColors.darkInput,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: KwhColors.cyan)),
        ),
      ),
    ]);
