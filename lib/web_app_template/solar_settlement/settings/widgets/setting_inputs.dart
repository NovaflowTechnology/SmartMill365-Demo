import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../solar_settlement_theme.dart';

/// One choice in a [SettingDropdown].
class SettingOption<T> {
  const SettingOption(this.value, this.label, {this.enabled = true});

  final T value;
  final String label;

  /// A disabled option is still listed, so a reader can see a choice exists
  /// and is not available yet, instead of wondering whether it was forgotten.
  final bool enabled;
}

const double _kFieldHeight = 42;

BoxDecoration _fieldDecoration(SettlementPalette p,
        {bool enabled = true, Color? borderColor}) =>
    BoxDecoration(
      color: enabled
          ? p.panel
          : (p.isLight ? Colors.black.withOpacity(0.04) : Colors.black26),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor ?? p.border),
    );

/// The select used across the setting page. Null [onChanged] draws it locked,
/// which is how a value owned by another module is shown.
class SettingDropdown<T> extends StatelessWidget {
  const SettingDropdown({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.hint = 'Select',
  });

  final T? value;
  final List<SettingOption<T>> options;
  final ValueChanged<T>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final enabled = onChanged != null;
    final hasValue = options.any((o) => o.value == value);
    final style = GoogleFonts.poppins(
        fontSize: 13.5, color: enabled ? p.text : p.subText);
    return Container(
      height: _kFieldHeight,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: _fieldDecoration(p, enabled: enabled),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: hasValue ? value : null,
          dropdownColor: p.card,
          borderRadius: BorderRadius.circular(10),
          icon: Icon(enabled ? Icons.keyboard_arrow_down : Icons.lock_outline,
              size: enabled ? 19 : 14, color: p.subText),
          style: style,
          hint: Text(hint,
              style: GoogleFonts.poppins(fontSize: 13.5, color: p.mutedText),
              overflow: TextOverflow.ellipsis),
          items: [
            for (final o in options)
              DropdownMenuItem<T>(
                value: o.value,
                enabled: o.enabled,
                child: Text(
                  o.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: o.enabled ? p.text : p.mutedText),
                ),
              ),
          ],
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged!(v);
                }
              : null,
        ),
      ),
    );
  }
}

/// A text or number field that keeps its own controller in step with the
/// value it is given.
///
/// With [defaultValue] set, a value that differs from it is outlined and gets
/// a reset arrow — the same convention the kanban settings use for renamed
/// labels, so a customised label is visible at a glance.
class SettingTextField extends StatefulWidget {
  const SettingTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.prefix,
    this.numeric = false,
    this.defaultValue,
    this.enabled = true,
    this.bare = false,
    this.textAlign = TextAlign.left,
    this.onBlur,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final String? prefix;
  final bool numeric;
  final String? defaultValue;
  final bool enabled;

  /// No box of its own, for use inside a composite control.
  final bool bare;
  final TextAlign textAlign;
  final VoidCallback? onBlur;

  @override
  State<SettingTextField> createState() => _SettingTextFieldState();
}

class _SettingTextFieldState extends State<SettingTextField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  void _onFocus() {
    if (_focus.hasFocus) return;
    widget.onBlur?.call();
    // Once focus leaves, the field shows the value as the page holds it —
    // rounded to its decimals, or back to the default when cleared.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.value != _c.text) _c.text = widget.value;
    });
  }

  void _reset() {
    _c.text = widget.defaultValue!;
    widget.onChanged(widget.defaultValue!);
  }

  @override
  void didUpdateWidget(covariant SettingTextField old) {
    super.didUpdateWidget(old);
    // Never while typing: "0." parses to 0, and writing that back would eat
    // the decimal point the user is halfway through entering.
    if (!_focus.hasFocus && widget.value != _c.text) {
      _c.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    final customised =
        widget.defaultValue != null && widget.value != widget.defaultValue;
    final field = TextField(
      controller: _c,
      focusNode: _focus,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      textAlign: widget.textAlign,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: widget.numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: widget.numeric ? FontWeight.w600 : FontWeight.w400,
          color: widget.enabled ? p.text : p.subText),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: widget.hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: p.mutedText),
        prefixText: widget.prefix == null ? null : '${widget.prefix}  ',
        prefixStyle: GoogleFonts.poppins(fontSize: 12.5, color: p.mutedText),
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
      ),
    );
    if (widget.bare) return field;
    return Container(
      height: _kFieldHeight,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: _fieldDecoration(p,
          enabled: widget.enabled,
          borderColor: customised ? p.accent.withOpacity(0.75) : null),
      child: Row(children: [
        Expanded(child: field),
        if (customised)
          IconButton(
            tooltip: 'Reset to default',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.restart_alt, size: 17, color: p.accent),
            onPressed: _reset,
          ),
      ]),
    );
  }
}

/// How many decimals a figure is shown with. Formatting only — values are
/// always stored and multiplied at full precision.
class DecimalsSelect extends StatelessWidget {
  const DecimalsSelect({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = const [0, 1, 2],
    this.inline = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final List<int> options;

  /// Drawn without a border, as the tail of a [RateInput].
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return PopupMenuButton<int>(
      tooltip: 'Decimal places',
      onSelected: onChanged,
      color: p.card,
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem<int>(
            value: o,
            height: 38,
            child: Text('$o decimal${o == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(fontSize: 13, color: p.text)),
          ),
      ],
      child: Container(
        height: inline ? _kFieldHeight - 2 : 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: inline
            ? BoxDecoration(
                color: p.accent.withOpacity(p.isLight ? 0.05 : 0.07),
                border: Border(left: BorderSide(color: p.border)),
              )
            : BoxDecoration(
                color: p.panel,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: p.border),
              ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: p.subText)),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: p.subText.withOpacity(0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('dp',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.subText)),
          ),
          Icon(Icons.arrow_drop_down, size: 16, color: p.subText),
        ]),
      ),
    );
  }
}

/// A price with its currency in front and its decimal places behind, in one
/// box — the rate and how it is displayed are edited together.
class RateInput extends StatelessWidget {
  const RateInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.decimals,
    required this.onDecimals,
    this.prefix = 'RM',
    this.hint = '0.00',
    this.decimalOptions = const [0, 1, 2, 3, 4],
    this.enabled = true,
    this.onBlur,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int decimals;
  final ValueChanged<int> onDecimals;
  final String? prefix;
  final String hint;
  final List<int> decimalOptions;
  final bool enabled;
  final VoidCallback? onBlur;

  @override
  Widget build(BuildContext context) {
    final p = SettlementPalette(context);
    return Container(
      height: _kFieldHeight,
      clipBehavior: Clip.antiAlias,
      decoration: _fieldDecoration(p, enabled: enabled),
      child: Row(children: [
        const SizedBox(width: 12),
        Expanded(
          child: SettingTextField(
            value: value,
            onChanged: onChanged,
            prefix: prefix,
            hint: hint,
            numeric: true,
            enabled: enabled,
            bare: true,
            onBlur: onBlur,
          ),
        ),
        DecimalsSelect(
          value: decimals,
          onChanged: onDecimals,
          options: decimalOptions,
          inline: true,
        ),
      ]),
    );
  }
}
