import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';

import '../../master_facility_setting/models/facility_data.dart';
import '../max_demand_chart_config.dart';

/// "Configure Chart" editor for a single Max Demand Monitoring equipment
/// chart — a checklist of that chart's own Master-Facilities-eligible
/// candidates. Each chart's gear icon opens its own instance of this dialog
/// (scoped via [target]) rather than one dialog covering both charts, so
/// the list shown always matches the chart the user actually clicked.
///
/// Same bounded scrollable checkbox-list pattern as
/// `report_image_config_dialog.dart`'s equipment checklist /
/// `carbon_dashboard_config_setting_widget.dart`'s device multi-selects.
class MaxDemandChartConfigDialog extends StatefulWidget {
  final MaxDemandChartTarget target;
  final Set<String> initialExcluded;
  final List<FacilityData> candidates;
  final String? plantLabel;

  const MaxDemandChartConfigDialog({
    super.key,
    required this.target,
    required this.initialExcluded,
    required this.candidates,
    this.plantLabel,
  });

  /// Shows the dialog and returns the chart's new excluded-device set on
  /// Save, or null if the user cancelled.
  static Future<Set<String>?> show(
    BuildContext context, {
    required MaxDemandChartTarget target,
    required Set<String> initialExcluded,
    required List<FacilityData> candidates,
    String? plantLabel,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (_) => MaxDemandChartConfigDialog(
        target: target,
        initialExcluded: initialExcluded,
        candidates: candidates,
        plantLabel: plantLabel,
      ),
    );
  }

  @override
  State<MaxDemandChartConfigDialog> createState() => _MaxDemandChartConfigDialogState();
}

class _MaxDemandChartConfigDialogState extends State<MaxDemandChartConfigDialog> {
  late Set<String> _excluded;
  final ScrollController _scrollController = ScrollController();

  String get _title =>
      widget.target == MaxDemandChartTarget.correlation ? 'Equipment Load Correlation' : 'Equipment MD Ranking';

  String get _emptyMessage {
    final plantSuffix = widget.plantLabel != null ? ' for ${widget.plantLabel}' : '';
    return widget.target == MaxDemandChartTarget.correlation
        ? 'No devices registered in Master Facility Setting for this chart$plantSuffix yet.'
        : 'No devices have "MD Ranking" enabled in Master Facility Setting$plantSuffix yet.';
  }

  @override
  void initState() {
    super.initState();
    _excluded = {...widget.initialExcluded};
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle(String id, bool included) {
    setState(() {
      if (included) {
        _excluded.remove(id);
      } else {
        _excluded.add(id);
      }
    });
  }

  void _save() => Navigator.of(context).pop(_excluded);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AlertDialog(
      backgroundColor: theme.secondaryBackground,
      title: Text(
        '$_title — Chart Settings',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: theme.primaryText),
      ),
      content: SizedBox(
        width: responsiveDialogWidth(context, 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uncheck any equipment that shouldn\'t appear on this chart.',
                style: GoogleFonts.poppins(fontSize: 12, color: theme.secondaryText),
              ),
              if (widget.plantLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Showing equipment for plant: ${widget.plantLabel}',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.primary),
                ),
              ],
              const SizedBox(height: 10),
              _checklist(theme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _checklist(FlutterFlowTheme theme) {
    if (widget.candidates.isEmpty) {
      return Text(_emptyMessage, style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: ListView(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 4, bottom: 4, right: 12),
          children: widget.candidates.map((f) {
            final id = f.meterId.trim();
            final included = !_excluded.contains(id);
            return CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: included,
              onChanged: (v) => _toggle(id, v ?? true),
              title: Text(
                f.meterName.isNotEmpty ? '${f.meterId} — ${f.meterName}' : f.meterId,
                style: GoogleFonts.poppins(fontSize: 13, color: theme.primaryText),
              ),
              subtitle: f.productionArea.isNotEmpty
                  ? Text(f.productionArea, style: GoogleFonts.poppins(fontSize: 11, color: theme.secondaryText))
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}
