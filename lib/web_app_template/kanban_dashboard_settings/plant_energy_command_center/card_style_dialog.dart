import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartmachine365/web_app_template/kanban_dashboard/models/pecc_live_data.dart';

/// Font size and colour for one card's label and its figure — nothing else.
///
/// Deliberately small: this does not let anyone change what a card shows,
/// only how it is drawn, so it is safe to put on any card without touching
/// what that card measures. Reused across every dashboard that adopts it —
/// [CardTextStyle] is the same shape everywhere, only the card key and the
/// title shown in this dialog differ.
class CardStyleDialog extends StatefulWidget {
  const CardStyleDialog({super.key, required this.title, required this.initial});

  final String title;
  final CardTextStyle initial;

  static Future<CardTextStyle?> show(
    BuildContext context, {
    required String title,
    required CardTextStyle initial,
  }) =>
      showDialog<CardTextStyle>(
        context: context,
        builder: (_) => CardStyleDialog(title: title, initial: initial),
      );

  @override
  State<CardStyleDialog> createState() => _CardStyleDialogState();
}

class _CardStyleDialogState extends State<CardStyleDialog> {
  static const _cyan = Color(0xFF33C9DC);
  static const _bg = Color(0xFF081020);
  static const _sub = Color(0xFF08151F);
  static const _border = Color(0xFF1C3050);
  static const _ink = Color(0xFFE8EEFC);
  static const _inkDim = Color(0xFF8CA2C4);
  static const _inkFaint = Color(0xFF5B6F90);

  late double _labelSize = widget.initial.labelSize > 0 ? widget.initial.labelSize : 14;
  late String _labelColor = widget.initial.labelColorKey.isEmpty ? 'white' : widget.initial.labelColorKey;
  late double _valueSize = widget.initial.valueSize > 0 ? widget.initial.valueSize : 36;
  late String _valueColor = widget.initial.valueColorKey.isEmpty ? 'white' : widget.initial.valueColorKey;

  CardTextStyle get _result => CardTextStyle(
        labelSize: _labelSize,
        labelColorKey: _labelColor,
        valueSize: _valueSize,
        valueColorKey: _valueColor,
      );

  void _reset() {
    setState(() {
      _labelSize = 14;
      _labelColor = 'white';
      _valueSize = 36;
      _valueColor = 'white';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2038),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(Icons.format_size, size: 18, color: _cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _inkDim),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Font size and colour for this card only.',
                  style: GoogleFonts.poppins(fontSize: 12, color: _inkDim)),
              const SizedBox(height: 18),
              _block(
                label: 'LABEL',
                size: _labelSize,
                min: 9,
                max: 18,
                onSize: (v) => setState(() => _labelSize = v),
                color: _labelColor,
                onColor: (v) => setState(() => _labelColor = v),
              ),
              const SizedBox(height: 14),
              _block(
                label: 'FIGURE',
                size: _valueSize,
                min: 18,
                max: 64,
                onSize: (v) => setState(() => _valueSize = v),
                color: _valueColor,
                onColor: (v) => setState(() => _valueColor = v),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                decoration: BoxDecoration(
                  color: _sub,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Column(children: [
                  Text(widget.title.toUpperCase(),
                      style: TextStyle(
                          color: heroColors[_labelColor] ?? _inkDim,
                          fontFamily: 'Poppins',
                          fontSize: _labelSize,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('12,345 kWh',
                      style: TextStyle(
                          color: heroColors[_valueColor] ?? Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: _valueSize)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: _reset,
                  style: TextButton.styleFrom(foregroundColor: _inkDim),
                  child: Text('Reset', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_result),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF158091),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  child: Text('Save', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block({
    required String label,
    required double size,
    required double min,
    required double max,
    required ValueChanged<double> onSize,
    required String color,
    required ValueChanged<String> onColor,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _cyan)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: size.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min).round(),
              activeColor: _cyan,
              inactiveColor: _border,
              onChanged: onSize,
            ),
          ),
        ),
        SizedBox(
          width: 26,
          child: Text(size.round().toString(),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: _inkDim)),
        ),
        const SizedBox(width: 10),
        for (final entry in heroColors.entries)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: GestureDetector(
              onTap: () => onColor(entry.key),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == entry.key ? _cyan : Colors.white.withOpacity(0.25),
                    width: color == entry.key ? 2.2 : 1,
                  ),
                ),
              ),
            ),
          ),
      ]),
    ]);
  }
}
