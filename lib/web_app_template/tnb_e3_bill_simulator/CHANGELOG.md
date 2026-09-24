# TNB E3 Bill Simulator — Change Log

> **Purpose:** Track every change made to this folder so that concurrent work does not cause lost updates.
> **Rule:** Any developer (or AI assistant) editing a file in this folder **must** add an entry here before committing.

---

## Folder Structure

```
tnb_e3_bill_simulator/
├── CHANGELOG.md                          ← this file (read first, update last)
├── tnb_e3_bill_simulator_widget.dart     ← main page widget, layout & data logic
├── models/
│   └── tnb_e3_bill_simulator_model.dart  ← all data models & static string constants
└── widgets/
    ├── tnb_cyber_deco.dart               ← shared corner-bracket painter (CyberpunkBrackets)
    ├── tnb_header_card.dart              ← top header: title, accrual amount, refresh button
    ├── tnb_breakdown_table.dart          ← scrollable bill breakdown table
    ├── tnb_summary_cards.dart            ← 3-card column: solar savings, PF risk, billing cycle
    ├── tnb_pf_surcharge_card.dart        ← PF surcharge risk card with segmented bar
    └── tnb_footer.dart                   ← disclaimer + version stamp
```

---

## Change History

### [2026-03-30] — UI Standardisation & Bug Fixes

#### tnb_e3_bill_simulator_widget.dart
- **Font:** Replaced all `GoogleFonts.orbitron()` and `GoogleFonts.rajdhani()` calls with `GoogleFonts.poppins()` to match the Max Demand Monitoring widget style.
- **ICPT rate format:** Changed static placeholder rate from `'0.000'` → `'0.0'` and dynamic `icptRate.toStringAsFixed(3)` → `icptRate.toStringAsFixed(1)` to match other zero-value displays in the table.
- **Breadcrumb:** Replaced custom cyan Row with `›` separators with the standard `titleLarge` + `headlineMedium` pattern used by other widgets (Max Demand Monitoring etc.):
  ```dart
  Text('Dashboard/Billing/TNB E3 Bill Simulator',
    style: FlutterFlowTheme.of(context).titleLarge.override(fontFamily: 'Poppins', fontSize: 12))
  Text('TNB E3 Bill Simulator',
    style: FlutterFlowTheme.of(context).headlineMedium.override(fontFamily: 'Poppins'))
  ```

#### widgets/tnb_breakdown_table.dart
- **Font:** All `orbitron` / `rajdhani` → `poppins`.
- **Overflow fix:** Replaced direct `items.map(...)` spread + `const Spacer()` with `Expanded(child: ListView(...))` so rows scroll instead of overflowing the card bottom.
- **Arm length:** `CyberpunkBrackets armLength` reduced from `sw * 0.0126` → `sw * 0.0088` (−30%).

#### widgets/tnb_header_card.dart
- **Font:** All `orbitron` / `rajdhani` → `poppins`.
- **Arm length:** `CyberpunkBrackets armLength` reduced from `sw * 0.0126` → `sw * 0.0088` (−30%).

#### widgets/tnb_pf_surcharge_card.dart
- **Font:** All `orbitron` / `rajdhani` → `poppins`.
- **Overflow fix:** Wrapped inner `Column` with `SingleChildScrollView`; changed `mainAxisSize: MainAxisSize.max` → `mainAxisSize: MainAxisSize.min`.
- **Arm length:** `CyberpunkBrackets armLength` changed to `armLen * 0.7` (−30%).

#### widgets/tnb_summary_cards.dart
- **Font:** All `orbitron` / `rajdhani` → `poppins`.
- **Arm length:** Both `CyberpunkBrackets armLength` calls changed to `armLen * 0.7` (−30%).

#### widgets/tnb_footer.dart
- **Font:** All `orbitron` / `rajdhani` → `poppins`.
- **Arm length:** `CyberpunkBrackets armLength` changed to `armLen * 0.7` (−30%).

#### widgets/tnb_cyber_deco.dart
- **Bracket style:** Replaced custom thick neon paint logic with the exact `_BracketPainter` style from `CardWidget` (`lib/components/card_widget/card_widget.dart`):
  - Glow layer: `color.withOpacity(0.50)`, `strokeWidth × 4`, `MaskFilter.blur(normal, 7)`
  - Line layer: `Colors.white.withOpacity(0.95)`, `strokeWidth × 2`
- **Stroke normalisation:** Painter now self-calculates stroke as `(W * 0.002).clamp(0.0, 1.2)` from the card's own rendered width (`W`). This ensures all cards — narrow (summary/PF) and wide (breakdown/header/footer) — render brackets at the same visual weight regardless of card size.
- **Reason:** Previous approach passed `strokeWidth` based on full screen width (`sw`), making brackets excessively thick on wide cards.

---

### [2026-03-30] — Code Cleanup (dead param, dead code, efficiency)

#### widgets/tnb_cyber_deco.dart
- **Removed `strokeWidth` parameter** from `CyberpunkBracketPainter` and `CyberpunkBrackets` — it was completely ignored by the painter (stroke is self-calculated from canvas width). Passing it was misleading and caused `shouldRepaint` to compare a value that had no effect on rendering.

#### widgets/tnb_header_card.dart / tnb_breakdown_table.dart / tnb_summary_cards.dart / tnb_pf_surcharge_card.dart / tnb_footer.dart
- **Removed `strokeWidth:` argument** from all `CyberpunkBrackets(...)` call sites.

#### widgets/tnb_breakdown_table.dart
- **Cached theme lookup**: `FlutterFlowTheme.of(context)` was called once per row inside `_buildRow`. Changed signature to accept pre-resolved `FlutterFlowTheme theme` and call site passes it once.

#### tnb_e3_bill_simulator_widget.dart
- **Removed dead debug comment block** (lines ~280-282): commented-out hardcoded override `pfValue = 0.50` and misspelled "Harcord Override" label.
- **Static regex**: `RegExp(r'(\d{1,3})...')` inside `_fmt()` was compiled on every call. Extracted to `static final _fmtRegex` so it compiles once.

---

## How to Add an Entry

```
### [YYYY-MM-DD] — Short description of change

#### file/path/changed.dart
- **What:** One-line description of what changed.
- **Why:** Reason / ticket / request.
- **Impact:** Any other files or widgets affected.
```

---

## Known Issues / Pending

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | tnb_breakdown_table.dart | If item list is empty, `ListView` shows blank space — no empty-state widget yet | Open |
| 2 | tnb_pf_surcharge_card.dart | `SingleChildScrollView` disables natural card height expansion — may clip on very small viewports | Open |
