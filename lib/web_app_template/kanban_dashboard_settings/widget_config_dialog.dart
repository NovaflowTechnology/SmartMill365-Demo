import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

// -----------------------------------------------------------------------------
// Data model
// -----------------------------------------------------------------------------
class KanbanCellConfig {
  final int cellIndex;
  final String widgetType;
  final String widgetName;
  String size;
  Map<String, dynamic> config;

  KanbanCellConfig({
    required this.cellIndex,
    required this.widgetType,
    required this.widgetName,
    this.size = '1x1',
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  Map<String, dynamic> toJson() => {
        'cellIndex': cellIndex,
        'widgetType': widgetType,
        'widgetName': widgetName,
        'size': size,
        'config': config,
      };
}

// -----------------------------------------------------------------------------
// Widget registry - YOUR registry, unchanged
// -----------------------------------------------------------------------------
class WidgetMeta {
  final String type;
  final String name;
  final String description;
  final List<String> availableSizes;
  final List<String> displayMsgOptions;

  const WidgetMeta({
    required this.type,
    required this.name,
    required this.description,
    this.availableSizes = const ['1x1', '1x2', '2x1'],
    this.displayMsgOptions = const [],
  });
}

const List<WidgetMeta> kWidgetRegistry = [
  WidgetMeta(
    type: 'EQUIPMENT_MD_RANKING',
    name: 'Current Equipment MD Ranking',
    description: 'Display current equipment MD ranking',
    availableSizes: ['1x1', '1x2', '2x1'],
    displayMsgOptions: ['Production', 'Product', 'Routing', 'Delivery date', 'Quantity', 'Remaining', 'Delayed Est.', 'Equipment', 'Progress'],
  ),
  WidgetMeta(
    type: 'DAILY_CHART',
    name: 'Daily Chart',
    description: 'Insight to daily energy consumption',
    displayMsgOptions: ['Status', 'Service Provider', 'Product', 'Count'],
  ),
  WidgetMeta(
    type: 'HOURLY_CHART',
    name: 'Hourly Chart',
    description: 'Insight to hourly energy consumption',
    displayMsgOptions: ['Status', 'Service Provider', 'Product', 'Count'],
  ),
  WidgetMeta(
    type: 'MONTHLY_CHART',
    name: 'Monthly Chart',
    description: 'Insight to monthly energy consumption',
    displayMsgOptions: ['Status', 'Service Provider', 'Product', 'Count'],
  ),
  WidgetMeta(
    type: 'YEAR_OVER_YEAR_CHART',
    name: 'Year-over-Year Chart',
    description: 'Insight to year-over-year energy consumption',
    displayMsgOptions: ['Period'],
  ),
  WidgetMeta(
    type: 'LAST_24_HOURS_POWER_LOAD',
    name: 'Last 24 Hours Power Load',
    description: 'Insight to power load for the last 24 hours',
    displayMsgOptions: ['Period'],
  ),
  WidgetMeta(
    type: '24_HOURS_POWER_LOAD_TREND',
    name: '24 Hours Power Load Trend',
    description: 'Insight to power load trend for the last 24 hours',
    displayMsgOptions: ['Period'],
  ),
  WidgetMeta(
    type: 'DAILY_MAX_DEMAND_THIS_MONTH',
    name: 'Daily Max Demand This Month',
    description: 'Insight to daily max demand for this month',
    displayMsgOptions: ['Period'],
  ),
  WidgetMeta(
    type: 'POWER_LOAD_DISTRIBUTION_TODAY',
    name: 'Power Load Distribution Today',
    description: 'Insight to power load distribution for today',
    displayMsgOptions: ['Period'],
  ),
  WidgetMeta(
    type: 'YEAR_ON_YEAR_ANALYSIS',
    name: 'Year-on-Year Analysis',
    description: 'Insight to year-on-year analysis (Last year vs This year)',
    displayMsgOptions: ['Period'],
  ),
  WidgetMeta(
    type: 'EQUIPMENT_LOAD_CORRELATION',
    name: 'Equipment Load Correlation',
    description: 'Insight to equipment load correlation (Peak Window Focus)',
    displayMsgOptions: ['Period'],
  ),
];

WidgetMeta? getWidgetMeta(String type) {
  try {
    return kWidgetRegistry.firstWhere((w) => w.type == type);
  } catch (_) {
    return null;
  }
}

// -----------------------------------------------------------------------------
// Sort condition
// -----------------------------------------------------------------------------
class SortCondition {
  String field;
  String direction;
  SortCondition({this.field = '', this.direction = 'DESC'});
  Map<String, dynamic> toJson() => {'field': field, 'direction': direction};
}

// =============================================================================
// WidgetConfigDialog
//  onSaved returns the saved KanbanCellConfig so the caller updates
//    its local list immediately - no extra HTTP reload needed.
// =============================================================================
class WidgetConfigDialog extends StatefulWidget {
  final int cellIndex;
  final WidgetMeta widgetMeta;
  final String uid;
  final String templateId;
  final KanbanCellConfig? existingConfig;

  /// Called with the fully-saved cell config on success.
  final void Function(KanbanCellConfig saved)? onSaved;

  const WidgetConfigDialog({
    Key? key,
    required this.cellIndex,
    required this.widgetMeta,
    required this.uid,
    required this.templateId,
    this.existingConfig,
    this.onSaved,
  }) : super(key: key);

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  final _unitNameController = TextEditingController();
  String _size = '1x1';
  String _factory = '';
  String _productionArea = '';
  String _statisticRange = 'ALL';
  List<String> _selectedDisplayMsg = [];
  List<SortCondition> _sortConditions = [SortCondition()];
  final List<String> _statisticRangeOptions = ['ALL', 'TODAY', 'THIS_WEEK', 'THIS_MONTH'];

  @override
  void initState() {
    super.initState();
    _unitNameController.text = widget.widgetMeta.name;

    if (widget.existingConfig != null) {
      final c = widget.existingConfig!;
      _unitNameController.text = c.widgetName;
      _size = c.size;
      _factory = c.config['factory'] ?? '';
      _productionArea = c.config['productionArea'] ?? '';
      _statisticRange = c.config['statisticRange'] ?? 'ALL';
      _selectedDisplayMsg = List<String>.from(c.config['displayMsg'] ?? []);
      final rawSort = c.config['sortConditions'] as List?;
      if (rawSort != null && rawSort.isNotEmpty) {
        _sortConditions = rawSort.map((s) => SortCondition(field: s['field'] ?? '', direction: s['direction'] ?? 'DESC')).toList();
      }
    }
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    super.dispose();
  }

  // -- Build config object from current form state --------------------------
  KanbanCellConfig _buildConfig() => KanbanCellConfig(
        cellIndex: widget.cellIndex,
        widgetType: widget.widgetMeta.type,
        widgetName: _unitNameController.text.trim(),
        size: _size,
        config: {
          'factory': _factory,
          'productionArea': _productionArea,
          'statisticRange': _statisticRange,
          'displayMsg': _selectedDisplayMsg,
          'sortConditions': _sortConditions.where((s) => s.field.isNotEmpty).map((s) => s.toJson()).toList(),
        },
      );

  void _save() {
    if (_unitNameController.text.trim().isEmpty) {
      _showError('Unit Name is required');
      return;
    }

    final cellConfig = _buildConfig();
    widget.onSaved?.call(cellConfig);
    Navigator.of(context, rootNavigator: true).pop(true);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
      );
    }
  }

  void _toggleDisplayMsg(String msg) {
    setState(() {
      if (_selectedDisplayMsg.contains(msg)) {
        _selectedDisplayMsg.remove(msg);
      } else {
        _selectedDisplayMsg.add(msg);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.widgetMeta;
    final theme = FlutterFlowTheme.of(context);

    return Dialog(
      backgroundColor: theme.primaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: SizedBox(
        width: responsiveDialogWidth(context, 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Configure Widget', style: GoogleFonts.poppins(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w500)),
                          Text('Cell ${widget.cellIndex + 1} - ${meta.name}', style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryText, size: 20),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Name
                    _FormRow(
                      label: 'Unit Name',
                      required: true,
                      child: _StyledTextField(controller: _unitNameController, hint: 'Enter unit name'),
                    ),
                    const SizedBox(height: 12),

                    // Description banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBE6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFE58F)),
                      ),
                      child: Text('Description: ${meta.description}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF614700), fontFamily: 'Poppins')),
                    ),
                    const SizedBox(height: 12),

                    // Size radio
                    _FormRow(
                      label: 'Size',
                      child: Row(
                        children: meta.availableSizes.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Radio<String>(
                                value: s,
                                groupValue: _size,
                                onChanged: (v) => setState(() => _size = v!),
                                activeColor: theme.primary,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              Text(s.toUpperCase().replaceAll('X', 'X'),
                                  style: TextStyle(color: theme.primaryText, fontSize: 12, fontFamily: 'Poppins')),
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parameter Msg
                    Text('Parameter Msg:', style: GoogleFonts.poppins(color: theme.primaryText, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),

                    _FormRow(
                      label: 'Factory',
                      child: _StyledDropdown(
                        value: _factory.isEmpty ? null : _factory,
                        hint: '',
                        items: const ['Factory A', 'Factory B', 'Factory C'],
                        onChanged: (v) => setState(() => _factory = v ?? ''),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FormRow(
                      label: 'Production Area',
                      child: _StyledTextField(initialValue: _productionArea, hint: 'Default all', onChanged: (v) => _productionArea = v),
                    ),
                    const SizedBox(height: 8),
                    _FormRow(
                      label: 'Statistic Range',
                      child: _StyledDropdown(
                        value: _statisticRange,
                        items: _statisticRangeOptions,
                        onChanged: (v) => setState(() => _statisticRange = v ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Display Msg chips
                    if (meta.displayMsgOptions.isNotEmpty) ...[
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(
                          width: 110,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: RichText(
                              text: TextSpan(children: [
                                const TextSpan(text: '* ', style: TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Poppins')),
                                TextSpan(text: 'Display Msg', style: TextStyle(color: theme.secondaryText, fontSize: 12, fontFamily: 'Poppins')),
                              ]),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: meta.displayMsgOptions.map((msg) {
                                final selected = _selectedDisplayMsg.contains(msg);
                                return GestureDetector(
                                  onTap: () => _toggleDisplayMsg(msg),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: selected ? theme.primary.withOpacity(0.15) : const Color(0xFF001055),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: selected ? theme.primary : theme.primary.withOpacity(0.3)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text(msg,
                                          style: TextStyle(color: selected ? theme.primary : theme.primaryText, fontSize: 11, fontFamily: 'Poppins')),
                                      if (selected) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.close, size: 12, color: theme.primary),
                                      ],
                                    ]),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.sort, size: 14, color: theme.primary),
                                label: Text('Sorting', style: TextStyle(color: theme.primary, fontSize: 11, fontFamily: 'Poppins')),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                    ],

                    // Sort conditions
                    ..._sortConditions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final sort = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(
                            width: 110,
                            child:
                                Text('Sort Condition ${idx + 1}:', style: TextStyle(color: theme.secondaryText, fontSize: 12, fontFamily: 'Poppins')),
                          ),
                          Expanded(
                            child: _StyledDropdown(
                              value: sort.field.isEmpty ? null : sort.field,
                              hint: 'Select field',
                              items: meta.displayMsgOptions,
                              onChanged: (v) => setState(() => sort.field = v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RadioPill(label: 'Desc.', selected: sort.direction == 'DESC', onTap: () => setState(() => sort.direction = 'DESC')),
                          const SizedBox(width: 8),
                          _RadioPill(label: 'Asc.', selected: sort.direction == 'ASC', onTap: () => setState(() => sort.direction = 'ASC')),
                          const SizedBox(width: 8),
                          if (idx == _sortConditions.length - 1)
                            _SmallIconButton(icon: Icons.add, onTap: () => setState(() => _sortConditions.add(SortCondition())))
                          else
                            _SmallIconButton(icon: Icons.remove, onTap: () => setState(() => _sortConditions.removeAt(idx))),
                        ]),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryText,
                        side: BorderSide(color: theme.primary.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Save Widget', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reusable sub-widgets
// -----------------------------------------------------------------------------
class _FormRow extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;
  const _FormRow({required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
        width: 110,
        child: RichText(
          text: TextSpan(children: [
            if (required) const TextSpan(text: '* ', style: TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Poppins')),
            TextSpan(text: '$label:', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText, fontSize: 12, fontFamily: 'Poppins')),
          ]),
        ),
      ),
      Expanded(child: child),
    ]);
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final ValueChanged<String>? onChanged;
  const _StyledTextField({this.controller, this.initialValue, this.hint, this.onChanged});

  InputDecoration _dec(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: t.secondaryText, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF001055),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: t.primary.withOpacity(0.4))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: t.primary.withOpacity(0.4))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: t.primary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontSize: 13, fontFamily: 'Poppins');
    if (controller != null) {
      return TextField(controller: controller, onChanged: onChanged, style: style, decoration: _dec(context));
    }
    return TextFormField(initialValue: initialValue, onChanged: onChanged, style: style, decoration: _dec(context));
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _StyledDropdown({this.value, this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      hint: hint != null ? Text(hint!, style: TextStyle(color: t.secondaryText, fontSize: 12)) : null,
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(color: t.primaryText, fontSize: 12, fontFamily: 'Poppins'))))
          .toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF001055),
      isDense: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF001055),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: t.primary.withOpacity(0.4))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: t.primary.withOpacity(0.4))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: t.primary)),
      ),
    );
  }
}

class _RadioPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.primary, width: 1.5)),
          child: selected ? Center(child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: t.primary))) : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: t.primaryText, fontSize: 12, fontFamily: 'Poppins')),
      ]),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(border: Border.all(color: t.primary.withOpacity(0.5)), borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 16, color: t.primary),
      ),
    );
  }
}
