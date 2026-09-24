import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartmachine365/web_app_template/kanban_dashboard/models/pecc_live_data.dart';

/// One lot the centre card can be told to include — just enough to draw a
/// checkbox row, not the full pin configuration.
class HeroLotOption {
  const HeroLotOption({required this.pinIndex, required this.label});

  final int pinIndex;
  final String label;
}

/// Settings for the group map's centre card: what it shows, which lots it
/// totals, and how big it is drawn.
///
/// Config only — this dialog has no live figures to show, the same as every
/// other table on the settings page (a pin's own metric cards work the same
/// way). What the numbers actually come out to is seen on the dashboard once
/// this is saved.
class HeroCardSettingsDialog extends StatefulWidget {
  const HeroCardSettingsDialog({
    super.key,
    required this.initial,
    required this.lots,
  });

  final HeroCardConfig initial;
  final List<HeroLotOption> lots;

  static Future<HeroCardConfig?> show(
    BuildContext context, {
    required HeroCardConfig initial,
    required List<HeroLotOption> lots,
  }) =>
      showDialog<HeroCardConfig>(
        context: context,
        builder: (_) => HeroCardSettingsDialog(initial: initial, lots: lots),
      );

  @override
  State<HeroCardSettingsDialog> createState() => _HeroCardSettingsDialogState();
}

class _HeroCardSettingsDialogState extends State<HeroCardSettingsDialog> {
  static const _cyan = Color(0xFF33C9DC);
  static const _bg = Color(0xFF081020);
  static const _panel = Color(0xFF0D1728);
  static const _row = Color(0xFF0C1626);
  static const _sub = Color(0xFF08151F);
  static const _border = Color(0xFF1C3050);
  static const _ink = Color(0xFFE8EEFC);
  static const _inkDim = Color(0xFF8CA2C4);
  static const _inkFaint = Color(0xFF5B6F90);

  late final _titleCtrl = TextEditingController(text: widget.initial.title);
  late double _titleSize = widget.initial.titleSize > 0 ? widget.initial.titleSize : 15;

  late final _mainNameCtrl = TextEditingController(text: widget.initial.main.name);
  late double _mainNameSize = widget.initial.main.nameSize > 0 ? widget.initial.main.nameSize : 11;
  late String _mainMetric = widget.initial.main.metricKey.isEmpty ? 'cost' : widget.initial.main.metricKey;
  late String _mainColor = widget.initial.main.colorKey.isEmpty ? 'white' : widget.initial.main.colorKey;
  late double _mainValueSize = widget.initial.main.valueSize > 0 ? widget.initial.main.valueSize : 30;
  late bool _mainOn = widget.initial.main.isSet;

  late final _subNameCtrl = TextEditingController(text: widget.initial.sub.name);
  late double _subNameSize = widget.initial.sub.nameSize > 0 ? widget.initial.sub.nameSize : 10;
  late String _subMetric = widget.initial.sub.metricKey.isEmpty ? 'energy' : widget.initial.sub.metricKey;
  late String _subColor = widget.initial.sub.colorKey.isEmpty ? 'cyan' : widget.initial.sub.colorKey;
  late double _subValueSize = widget.initial.sub.valueSize > 0 ? widget.initial.sub.valueSize : 13;
  late bool _subOn = widget.initial.sub.isSet;

  late Set<int> _includedPins = widget.initial.includedPins.isEmpty
      ? widget.lots.map((l) => l.pinIndex).toSet()
      : widget.initial.includedPins.toSet();

  late bool _customSize = widget.initial.widthPx != null || widget.initial.heightPx != null;
  late double _widthPx = widget.initial.widthPx ?? 300;
  late double _heightPx = widget.initial.heightPx ?? 220;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _mainNameCtrl.dispose();
    _subNameCtrl.dispose();
    super.dispose();
  }

  HeroCardConfig get _config => HeroCardConfig(
        title: _titleCtrl.text.trim(),
        titleSize: _titleSize,
        main: _mainOn
            ? HeroFigureConfig(
                name: _mainNameCtrl.text.trim(),
                nameSize: _mainNameSize,
                metricKey: _mainMetric,
                colorKey: _mainColor,
                valueSize: _mainValueSize,
              )
            : const HeroFigureConfig(),
        sub: _subOn
            ? HeroFigureConfig(
                name: _subNameCtrl.text.trim(),
                nameSize: _subNameSize,
                metricKey: _subMetric,
                colorKey: _subColor,
                valueSize: _subValueSize,
              )
            : const HeroFigureConfig(),
        includedPins: _includedPins.length == widget.lots.length ? const [] : _includedPins.toList(),
        widthPx: _customSize ? _widthPx : null,
        heightPx: _customSize ? _heightPx : null,
      );

  void _reset() {
    setState(() {
      _titleCtrl.text = '';
      _titleSize = 15;
      _mainOn = false;
      _mainNameCtrl.text = '';
      _mainNameSize = 11;
      _mainMetric = 'cost';
      _mainColor = 'white';
      _mainValueSize = 30;
      _subOn = false;
      _subNameCtrl.text = '';
      _subNameSize = 10;
      _subMetric = 'energy';
      _subColor = 'cyan';
      _subValueSize = 13;
      _includedPins = widget.lots.map((l) => l.pinIndex).toSet();
      _customSize = false;
      _widthPx = 300;
      _heightPx = 220;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 780),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
                  child: LayoutBuilder(builder: (context, c) {
                    final stacked = c.maxWidth < 760;
                    final form = _formColumn();
                    final preview = _previewPanel();
                    if (stacked) {
                      return Column(children: [form, const SizedBox(height: 16), preview]);
                    }
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 5, child: form),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: preview),
                    ]);
                  }),
                ),
              ),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2038),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.donut_large_outlined, size: 20, color: _cyan),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Center Card — Group Hero',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
              const SizedBox(height: 2),
              Text(
                'Pick a metric and which lots to include; the card shows the total across the '
                'selected lot pins.',
                style: GoogleFonts.poppins(fontSize: 11.5, color: _inkDim),
              ),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 19, color: _inkDim),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ]),
      );

  Widget _formColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            label: 'CARD TITLE',
            child: Row(children: [
              Expanded(
                child: _textField(_titleCtrl, hint: widget.initial.title.isEmpty ? 'Thong Guan Group' : null),
              ),
              const SizedBox(width: 12),
              _sizeSlider('Title size', _titleSize, 8, 20, (v) => setState(() => _titleSize = v)),
            ]),
          ),
          const SizedBox(height: 14),
          _figureBlock(
            tag: 'MAIN FIGURE',
            tagColor: _cyan,
            on: _mainOn,
            onToggle: (v) => setState(() => _mainOn = v),
            nameCtrl: _mainNameCtrl,
            nameHint: heroMetrics[_mainMetric]?.label ?? '',
            nameSize: _mainNameSize,
            onNameSize: (v) => setState(() => _mainNameSize = v),
            nameSizeRange: (8, 18),
            metric: _mainMetric,
            onMetric: (v) => setState(() => _mainMetric = v),
            color: _mainColor,
            onColor: (v) => setState(() => _mainColor = v),
            valueSize: _mainValueSize,
            onValueSize: (v) => setState(() => _mainValueSize = v),
            valueSizeRange: (18, 52),
          ),
          const SizedBox(height: 14),
          _figureBlock(
            tag: 'SUB FIGURE',
            tagColor: const Color(0xFF9DC0FF),
            on: _subOn,
            onToggle: (v) => setState(() => _subOn = v),
            nameCtrl: _subNameCtrl,
            nameHint: heroMetrics[_subMetric]?.label ?? '',
            nameSize: _subNameSize,
            onNameSize: (v) => setState(() => _subNameSize = v),
            nameSizeRange: (8, 16),
            metric: _subMetric,
            onMetric: (v) => setState(() => _subMetric = v),
            color: _subColor,
            onColor: (v) => setState(() => _subColor = v),
            valueSize: _subValueSize,
            onValueSize: (v) => setState(() => _subValueSize = v),
            valueSizeRange: (10, 24),
          ),
          const SizedBox(height: 14),
          _sizeBlock(),
          const SizedBox(height: 14),
          _sumExplainer(),
          const SizedBox(height: 12),
        ],
      );

  Widget _labeledField({required String label, required Widget child}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: _cyan)),
          const SizedBox(height: 6),
          child,
        ],
      );

  Widget _textField(TextEditingController ctrl, {String? hint}) => SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 13, color: _ink),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _row,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: _inkFaint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cyan)),
          ),
        ),
      );

  Widget _sizeSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) => SizedBox(
        width: 132,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _inkFaint)),
          Row(children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: (max - min).round(),
                  activeColor: _cyan,
                  inactiveColor: _border,
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(value.round().toString(),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: _inkDim)),
            ),
          ]),
        ]),
      );

  Widget _figureBlock({
    required String tag,
    required Color tagColor,
    required bool on,
    required ValueChanged<bool> onToggle,
    required TextEditingController nameCtrl,
    required String nameHint,
    required double nameSize,
    required ValueChanged<double> onNameSize,
    required (double, double) nameSizeRange,
    required String metric,
    required ValueChanged<String> onMetric,
    required String color,
    required ValueChanged<String> onColor,
    required double valueSize,
    required ValueChanged<double> onValueSize,
    required (double, double) valueSizeRange,
  }) {
    final info = heroMetrics[metric];
    final locked = info != null && info.agg != 'sum';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _sub,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF16273F)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF0F2038), borderRadius: BorderRadius.circular(6)),
            child: Text(tag,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: tagColor)),
          ),
          const Spacer(),
          Switch(
            value: on,
            activeColor: _cyan,
            onChanged: onToggle,
          ),
        ]),
        if (on) ...[
          const SizedBox(height: 8),
          _labeledField(
            label: 'DISPLAY NAME',
            child: Row(children: [
              Expanded(child: _textField(nameCtrl, hint: nameHint)),
              const SizedBox(width: 12),
              _sizeSlider('Name size', nameSize, nameSizeRange.$1, nameSizeRange.$2, onNameSize),
            ]),
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              flex: 2,
              child: _labeledField(
                label: 'METRIC TO SUM',
                child: _metricDropdown(metric, onMetric),
              ),
            ),
            const SizedBox(width: 10),
            _labeledField(label: 'COLOR', child: _colorSwatches(color, onColor)),
          ]),
          const SizedBox(height: 10),
          _sizeSlider('Value font size', valueSize, valueSizeRange.$1, valueSizeRange.$2, onValueSize),
          if (locked) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFFFB547)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  info.agg == 'max'
                      ? 'Combined as the highest reading, not a sum — site peaks don\'t coincide.'
                      : 'Combined as an average, not a sum.',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFFFB547)),
                ),
              ),
            ]),
          ],
        ],
      ]),
    );
  }

  Widget _metricDropdown(String value, ValueChanged<String> onChanged) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: _row, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: heroMetrics.containsKey(value) ? value : heroMetrics.keys.first,
            isExpanded: true,
            dropdownColor: _panel,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _inkDim),
            style: GoogleFonts.poppins(fontSize: 12.5, color: _ink),
            items: [
              for (final entry in heroMetrics.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                      '${entry.value.label}${entry.value.unit.isNotEmpty ? ' (${entry.value.unit})' : ''}'),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );

  Widget _colorSwatches(String value, ValueChanged<String> onChanged) => Wrap(
        spacing: 6,
        children: [
          for (final entry in heroColors.entries)
            GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: value == entry.key ? _cyan : Colors.white.withOpacity(0.25),
                    width: value == entry.key ? 2.5 : 1,
                  ),
                ),
              ),
            ),
        ],
      );

  /// Custom size — the one control the reference mockup did not have. Off by
  /// default, so an unconfigured card keeps its original fixed box.
  Widget _sizeBlock() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _sub,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF16273F)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF0F2038), borderRadius: BorderRadius.circular(6)),
              child: Text('CARD SIZE',
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _cyan)),
            ),
            const Spacer(),
            Switch(value: _customSize, activeColor: _cyan, onChanged: (v) => setState(() => _customSize = v)),
          ]),
          if (_customSize) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _sizeSlider('Width (px)', _widthPx, 220, 460, (v) => setState(() => _widthPx = v)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _sizeSlider('Min height (px)', _heightPx, 140, 420, (v) => setState(() => _heightPx = v)),
              ),
            ]),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Keeps the card\'s original fixed size.',
                  style: GoogleFonts.poppins(fontSize: 11, color: _inkFaint)),
            ),
        ]),
      );

  Widget _sumExplainer() {
    final metric = heroMetrics[_mainMetric];
    final verb = metric?.agg == 'max' ? 'MAX' : metric?.agg == 'avg' ? 'AVG' : 'SUM';
    final allOn = _includedPins.length == widget.lots.length;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1A8A98)),
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF0C2130),
          child: Row(children: [
            Text('Σ WHICH LOTS TO SUM',
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _cyan)),
            const Spacer(),
            Text('main metric shown below', style: GoogleFonts.poppins(fontSize: 11, color: _inkDim)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF16273F)))),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 11, color: _inkFaint),
              children: [
                TextSpan(text: verb, style: const TextStyle(color: _cyan, fontWeight: FontWeight.w700)),
                TextSpan(
                    text: '( each selected lot\'s ${metric?.label ?? '—'} ) → center main value'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(children: [
            Text('Tick the lot pins to include',
                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: _inkDim)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _includedPins = allOn
                  ? {}
                  : widget.lots.map((l) => l.pinIndex).toSet()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2038),
                  border: Border.all(color: const Color(0xFF1A8A98)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(allOn ? 'Clear all' : 'Select all',
                    style: GoogleFonts.poppins(fontSize: 11, color: _cyan)),
              ),
            ),
          ]),
        ),
        for (final lot in widget.lots)
          GestureDetector(
            onTap: () => setState(() {
              if (_includedPins.contains(lot.pinIndex)) {
                _includedPins.remove(lot.pinIndex);
              } else {
                _includedPins.add(lot.pinIndex);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF16273F)))),
              child: Opacity(
                opacity: _includedPins.contains(lot.pinIndex) ? 1 : 0.4,
                child: Row(children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _cyan.withOpacity(0.8), width: 1.5),
                    ),
                    child: _includedPins.contains(lot.pinIndex)
                        ? const Icon(Icons.check, size: 12, color: _cyan)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(lot.label, style: GoogleFonts.poppins(fontSize: 12.5, color: _ink))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _previewPanel() {
    final config = _config;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
        gradient: const RadialGradient(
          center: Alignment(0, -1),
          radius: 1.4,
          colors: [Color(0xFF12294A), _bg],
          stops: [0.0, 0.72],
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          child: Text('LIVE PREVIEW',
              style: GoogleFonts.poppins(fontSize: 10, color: _inkFaint, letterSpacing: 0.5)),
        ),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              (config.title.trim().isEmpty ? 'THONG GUAN GROUP' : config.title.trim()).toUpperCase(),
              style: TextStyle(color: _inkDim, fontSize: _titleSize, fontWeight: FontWeight.w600, letterSpacing: 0.7),
            ),
            const SizedBox(height: 12),
            if (_mainOn) ...[
              Text(
                (_mainNameCtrl.text.trim().isEmpty
                        ? (heroMetrics[_mainMetric]?.label ?? '')
                        : _mainNameCtrl.text.trim())
                    .toUpperCase(),
                style: TextStyle(color: _inkDim, fontSize: _mainNameSize, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text('—',
                  style: TextStyle(
                      color: heroColors[_mainColor] ?? Colors.white,
                      fontSize: _mainValueSize,
                      fontWeight: FontWeight.w700)),
            ],
            if (_subOn) ...[
              const SizedBox(height: 12),
              Text(
                (_subNameCtrl.text.trim().isEmpty
                        ? (heroMetrics[_subMetric]?.label ?? '')
                        : _subNameCtrl.text.trim())
                    .toUpperCase(),
                style: TextStyle(
                    color: heroColors[_subColor] ?? _cyan, fontSize: _subNameSize, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text('—',
                  style: TextStyle(
                      color: heroColors[_subColor] ?? _cyan, fontSize: _subValueSize, fontWeight: FontWeight.w700)),
            ],
            if (!_mainOn && !_subOn) ...[
              const SizedBox(height: 4),
              Text('Default layout — total cost + total energy',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: _inkFaint)),
            ],
            if (_customSize) ...[
              const SizedBox(height: 16),
              Text('${_widthPx.round()} × ${_heightPx.round()} px',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: _inkFaint)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _actions() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: _reset,
            style: TextButton.styleFrom(foregroundColor: _inkDim),
            child: Text('Reset', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_config),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF158091),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: Text('Save configuration',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}
