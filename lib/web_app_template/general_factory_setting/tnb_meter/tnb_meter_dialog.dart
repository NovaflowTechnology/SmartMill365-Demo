import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'tnb_meter_models.dart';
import 'tnb_meter_service.dart';
import 'tnb_meter_dashboard_config.dart';

class TnbMeterDialog extends StatefulWidget {
  final TnbMeter? meter;
  final List<Map<String, dynamic>> plants;
  final List<Map<String, dynamic>> areas;
  final List<Map<String, dynamic>> tariffs;
  final List<TnbMeter> existingMeters;
  final VoidCallback onSaved;

  const TnbMeterDialog({
    super.key,
    this.meter,
    required this.plants,
    required this.areas,
    required this.tariffs,
    required this.existingMeters,
    required this.onSaved,
  });

  @override
  State<TnbMeterDialog> createState() => _TnbMeterDialogState();
}

class _TnbMeterDialogState extends State<TnbMeterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _influxCtrl;
  late final TextEditingController _solarCtrl;
  late final TextEditingController _mdCtrl;

  String? _selectedPlantId;
  String? _selectedTariffCategoryId;
  String? _selectedTariffType;
  DateTime _effectiveFrom = DateTime.now();
  DateTime? _effectiveTo;
  Set<String> _selectedAreaIds = {};
  bool _isActive = true;
  bool _saving = false;

  // DPM devices from Master Facilities Setting — the meter links to one of
  // these Device IDs (stored in the same influxDbTag field, e.g. "VDPM002").
  List<Map<String, String>> _dpmOptions = [];

  // ── Max Demand Monitoring widget-channel-mapping config ───────────────────
  // All 3 widgets read from this meter's own DPM ID (influxDbTag) — what's
  // configurable here is the display label per widget and, for Power Load
  // Distribution, the time window each bucket average is computed over.
  late final TextEditingController _trendLabelCtrl;
  late final TextEditingController _dailyLabelCtrl;
  late List<TnbDistributionBucket> _buckets;

  Timer? _previewDebounce;
  bool _loadingTrendPreview = false;
  bool _loadingDailyPreview = false;
  bool _loadingDistributionPreview = false;
  int? _trendPreviewCount;
  int? _dailyPreviewCount;
  Map<String, double>? _distributionPreview;

  bool get _isEdit => widget.meter != null;

  @override
  void initState() {
    super.initState();
    final m = widget.meter;
    _codeCtrl = TextEditingController(text: m?.meterCode ?? '');
    _labelCtrl = TextEditingController(text: m?.meterLabel ?? '');
    _accountCtrl = TextEditingController(text: m?.tnbAccountNo ?? '');
    _influxCtrl = TextEditingController(text: m?.influxDbTag ?? '');
    _solarCtrl = TextEditingController(text: m?.solarDeviceId ?? '');
    _mdCtrl = TextEditingController(text: m != null && m.contractMdKw > 0 ? m.contractMdKw.toStringAsFixed(0) : '');
    _selectedPlantId = m?.plantId.isNotEmpty == true ? m!.plantId : null;
    _selectedTariffCategoryId = m?.tariffCategoryId.isNotEmpty == true ? m!.tariffCategoryId : null;
    _selectedTariffType = m?.tariffType.isNotEmpty == true ? m!.tariffType : null;
    if (m != null) {
      _effectiveFrom = m.effectiveFrom;
      _effectiveTo = m.effectiveTo;
      _selectedAreaIds = m.boundAreaIds.toSet();
      _isActive = m.isActive;
    }
    final dashboardConfig = m?.dashboardConfig ?? TnbMeterDashboardConfig.defaults();
    _trendLabelCtrl = TextEditingController(text: dashboardConfig.powerLoadTrendLabel);
    _dailyLabelCtrl = TextEditingController(text: dashboardConfig.dailyMaxDemandLabel);
    _buckets = List.of(
      dashboardConfig.distributionBuckets.isNotEmpty ? dashboardConfig.distributionBuckets : TnbMeterDashboardConfig.defaultBuckets,
    );
    _loadDpmOptions();
    _refreshAllPreviews();
  }

  Future<void> _loadDpmOptions() async {
    try {
      final facilities = await FacilityService.getFacilities();
      final seen = <String>{};
      final opts = <Map<String, String>>[];
      for (final f in facilities) {
        final id = f.meterId.trim();
        if (id.isEmpty || id == '-' || !seen.add(id)) continue;
        final name = f.meterName.trim();
        opts.add({
          'id': id,
          'label': name.isNotEmpty && name != '-' ? '$id — $name' : id,
        });
      }
      opts.sort((a, b) => a['id']!.compareTo(b['id']!));
      if (mounted) setState(() => _dpmOptions = opts);
    } catch (_) {}
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _labelCtrl.dispose();
    _accountCtrl.dispose();
    _influxCtrl.dispose();
    _solarCtrl.dispose();
    _mdCtrl.dispose();
    _trendLabelCtrl.dispose();
    _dailyLabelCtrl.dispose();
    _previewDebounce?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Widget-channel-mapping preview helpers ────────────────────────────────
  void _scheduleRefreshPreviews() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 400), _refreshAllPreviews);
  }

  Future<void> _refreshAllPreviews() async {
    final deviceId = _dpmSelectedValue ?? '';
    if (deviceId.isEmpty) {
      if (mounted) {
        setState(() {
          _trendPreviewCount = null;
          _dailyPreviewCount = null;
          _distributionPreview = null;
        });
      }
      return;
    }
    setState(() {
      _loadingTrendPreview = true;
      _loadingDailyPreview = true;
      _loadingDistributionPreview = true;
    });
    final results = await Future.wait([
      TnbMeterService.previewPowerLoadTrendPointCount(deviceId),
      TnbMeterService.previewDailyMaxDemandBarCount(deviceId),
      TnbMeterService.previewDistributionAverages(deviceId, _buckets),
    ]);
    if (!mounted) return;
    setState(() {
      _trendPreviewCount = results[0] as int?;
      _dailyPreviewCount = results[1] as int?;
      _distributionPreview = results[2] as Map<String, double>?;
      _loadingTrendPreview = false;
      _loadingDailyPreview = false;
      _loadingDistributionPreview = false;
    });
  }

  Future<void> _refreshDistributionPreview() async {
    final deviceId = _dpmSelectedValue ?? '';
    if (deviceId.isEmpty) return;
    setState(() => _loadingDistributionPreview = true);
    final result = await TnbMeterService.previewDistributionAverages(deviceId, _buckets);
    if (!mounted) return;
    setState(() {
      _distributionPreview = result;
      _loadingDistributionPreview = false;
    });
  }

  TimeOfDay _parseHHmm(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  String _formatHHmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickBucketTime(int index, bool isStart) async {
    final bucket = _buckets[index];
    final initial = _parseHHmm(isStart ? bucket.startTime : bucket.endTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _buckets[index] = isStart ? bucket.copyWith(startTime: _formatHHmm(picked)) : bucket.copyWith(endTime: _formatHHmm(picked));
    });
    _refreshDistributionPreview();
  }

  String _plantName(String id) {
    final p = widget.plants.where((p) => p['id']?.toString() == id).firstOrNull;
    return p?['name']?.toString() ?? id;
  }

  String _plantIdForArea(String areaId) {
    final a = widget.areas.where((a) => a['id']?.toString() == areaId).firstOrNull;
    return a?['factory_id']?.toString() ?? '';
  }

  String? _boundToMeter(String areaId) {
    for (final m in widget.existingMeters) {
      if (m.isActive && m.boundAreaIds.contains(areaId)) {
        if (_isEdit && m.id == widget.meter!.id) continue;
        return m.meterCode;
      }
    }
    return null;
  }

  Map<String, List<Map<String, dynamic>>> get _areasGroupedByPlant {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final a in widget.areas) {
      final pid = a['factory_id']?.toString() ?? '';
      if (pid.isEmpty) continue;
      if (_selectedPlantId != null && pid != _selectedPlantId) continue;
      groups.putIfAbsent(pid, () => []).add(a);
    }
    return groups;
  }

  int get _totalBoundEquipment {
    int count = 0;
    for (final areaId in _selectedAreaIds) {
      final area = widget.areas.where((a) => a['id']?.toString() == areaId).firstOrNull;
      count += (area?['equipment_count'] as num?)?.toInt() ?? 0;
    }
    return count;
  }

  String get _derivedPlant {
    if (_selectedAreaIds.isEmpty) return '';
    final plantIds = _selectedAreaIds.map(_plantIdForArea).toSet();
    return plantIds.map(_plantName).join(', ');
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _effectiveFrom : (_effectiveTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _effectiveFrom = picked;
        } else {
          _effectiveTo = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final meter = TnbMeter(
      id: widget.meter?.id ?? '',
      plantId: _selectedPlantId ?? '',
      meterCode: _codeCtrl.text.trim(),
      meterLabel: _labelCtrl.text.trim(),
      tnbAccountNo: _accountCtrl.text.trim(),
      influxDbTag: _influxCtrl.text.trim(),
      solarDeviceId: _solarCtrl.text.trim(),
      tariffCategoryId: _selectedTariffCategoryId ?? '',
      tariffType: _selectedTariffType ?? '',
      contractMdKw: double.tryParse(_mdCtrl.text.trim()) ?? 0,
      effectiveFrom: _effectiveFrom,
      effectiveTo: _effectiveTo,
      boundAreaIds: _selectedAreaIds.toList(),
      isActive: _isActive,
      dashboardConfig: TnbMeterDashboardConfig(
        powerLoadTrendLabel: _trendLabelCtrl.text.trim().isNotEmpty ? _trendLabelCtrl.text.trim() : '24-Hour Power Load Trend',
        dailyMaxDemandLabel: _dailyLabelCtrl.text.trim().isNotEmpty ? _dailyLabelCtrl.text.trim() : 'Daily Maximum Demand This Month',
        distributionBuckets: _buckets,
      ),
    );

    bool ok;
    if (_isEdit) {
      ok = await TnbMeterService.updateMeter(widget.meter!.id, meter);
    } else {
      ok = await TnbMeterService.createMeter(meter);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      widget.onSaved();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save meter.'), backgroundColor: Color(0xFFDC2626)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final screenW = MediaQuery.of(context).size.width;
    final dialogWidth = screenW < 600 ? screenW * 0.95 : 520.0;

    final bgColor = isLight ? Colors.white : theme.primaryBackground;
    final borderColor = isLight ? const Color(0xFFE3E8EF) : theme.cardStroke;
    final sectionLabelColor = isLight ? const Color(0xFF92702A) : const Color(0xFFD4A843);
    final sectionDividerColor = isLight ? const Color(0xFFE8DCC8) : const Color(0xFF5C4A2A);

    return Dialog(
      alignment: Alignment.centerRight,
      insetPadding: const EdgeInsets.only(right: 0, top: 0, bottom: 0),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(-4, 0)),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(theme, isLight, borderColor),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('IDENTIFICATION', sectionLabelColor, sectionDividerColor),
                      const SizedBox(height: 16),
                      _buildIdentificationSection(theme, isLight),
                      const SizedBox(height: 28),
                      _sectionLabel('TARIFF & CONTRACT', sectionLabelColor, sectionDividerColor),
                      const SizedBox(height: 16),
                      _buildTariffSection(theme, isLight),
                      const SizedBox(height: 28),
                      _sectionLabel('SCOPE BINDING — PRODUCTION AREAS THIS METER BILLS', sectionLabelColor, sectionDividerColor),
                      const SizedBox(height: 8),
                      Text(
                        'Select the Production Areas whose Equipment will be billed under this meter. '
                        'An Area can only be bound to one active meter at a time.',
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _buildScopeBinding(theme, isLight),
                      const SizedBox(height: 28),
                      _sectionLabel('MAX DEMAND MONITORING — WIDGET CHANNEL MAPPING', sectionLabelColor, sectionDividerColor),
                      const SizedBox(height: 8),
                      Text(
                        'These widgets on the Max Demand Monitoring dashboard read from this meter\'s DPM ID (set above). '
                        'Customize their display labels and, for Power Load Distribution, the time window each bucket average covers.',
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardConfigSection(theme, isLight),
                      const SizedBox(height: 28),
                      _sectionLabel('STATUS', sectionLabelColor, sectionDividerColor),
                      const SizedBox(height: 16),
                      _buildStatusSection(theme, isLight),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(theme, isLight, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme, bool isLight, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit TNB meter' : 'Add new TNB meter',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.txtPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEdit ? 'Update meter configuration and scope' : 'Register a new billing account and bind its scope',
                  style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.close, size: 16, color: theme.txtMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(FlutterFlowTheme theme, bool isLight, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: theme.txtSecondary),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D4739),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save meter', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color, Color dividerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Divider(color: dividerColor, height: 1),
      ],
    );
  }

  Widget _buildIdentificationSection(FlutterFlowTheme theme, bool isLight) {
    return Column(
      children: [
        _dropdownField(
          theme,
          isLight,
          label: 'Plant',
          required: true,
          value: _selectedPlantId,
          items: widget.plants.map((p) {
            final id = p['id']?.toString() ?? '';
            final name = p['name']?.toString() ?? '';
            return DropdownMenuItem(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
          }).toList(),
          helpText: 'The plant this meter belongs to.',
          onChanged: (v) => setState(() {
            _selectedPlantId = v;
            _selectedAreaIds.clear();
          }),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _formField(
                theme,
                isLight,
                label: 'Meter code',
                required: true,
                controller: _codeCtrl,
                hint: 'e.g. 53_LineA',
                helpText: 'Format: PLANT_IDENTIFIER. Used in InfluxDB tags.',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _formField(
                theme,
                isLight,
                label: 'Meter label',
                required: true,
                controller: _labelCtrl,
                hint: 'e.g. Line A meter',
                helpText: 'Human-readable, shown in dashboards.',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _formField(
                theme,
                isLight,
                label: 'TNB account no',
                controller: _accountCtrl,
                hint: 'e.g. 123456793',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dropdownField(
                theme,
                isLight,
                label: 'DPM ID config',
                // The dropdown widget itself needs a non-null value to show
                // the "No Device Linked" item as selected; _dpmSelectedValue
                // (used everywhere else) stays null-based for "not linked".
                value: _dpmSelectedValue ?? _noDeviceValue,
                items: _dpmItems,
                helpText: 'Link a DPM Device ID from Master Facilities Setting.',
                onChanged: (v) {
                  setState(() => _influxCtrl.text = (v == null || v == _noDeviceValue) ? '' : v);
                  _scheduleRefreshPreviews();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _dropdownField(
          theme,
          isLight,
          label: 'Solar mapping',
          value: _solarSelectedValue ?? _noDeviceValue,
          items: _solarItems,
          helpText: 'Link the Device ID that measures this site\'s solar generation — feeds Solar Savings (Avoided Cost) on the Bill Simulator.',
          onChanged: (v) {
            setState(() => _solarCtrl.text = (v == null || v == _noDeviceValue) ? '' : v);
          },
        ),
      ],
    );
  }

  // Current linked DPM id — kept in _influxCtrl (same saved field as before).
  String? get _dpmSelectedValue {
    final v = _influxCtrl.text.trim();
    return v.isEmpty ? null : v;
  }

  // Current linked solar device id — kept in _solarCtrl.
  String? get _solarSelectedValue {
    final v = _solarCtrl.text.trim();
    return v.isEmpty ? null : v;
  }

  List<DropdownMenuItem<String>> get _solarItems {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: _noDeviceValue,
        child: Text('— No Solar Device —', style: GoogleFonts.poppins(fontSize: 13, fontStyle: FontStyle.italic)),
      ),
      ..._dpmOptions.map((o) => DropdownMenuItem(
            value: o['id'],
            child: Text(o['label']!, overflow: TextOverflow.ellipsis),
          )),
    ];
    final current = _solarSelectedValue;
    if (current != null && !_dpmOptions.any((o) => o['id'] == current)) {
      items.insert(1, DropdownMenuItem(value: current, child: Text('$current (not found)', overflow: TextOverflow.ellipsis)));
    }
    return items;
  }

  // Sentinel dropdown value for "no device linked" — DropdownButtonFormField
  // needs a real (non-null) String among its items to represent this choice;
  // '' can't collide with a real DPM id since those are always non-empty.
  static const String _noDeviceValue = '';

  List<DropdownMenuItem<String>> get _dpmItems {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: _noDeviceValue,
        child: Text('— No Device Linked —', style: GoogleFonts.poppins(fontSize: 13, fontStyle: FontStyle.italic)),
      ),
      ..._dpmOptions.map((o) => DropdownMenuItem(
            value: o['id'],
            child: Text(o['label']!, overflow: TextOverflow.ellipsis),
          )),
    ];
    // Keep a legacy value (e.g. old free-text tag, or a stale DPM id that no
    // longer exists in Master Facilities) selectable so editing an existing
    // meter doesn't crash the dropdown — and so it's visible and clearable
    // instead of silently appearing unlinked while still saved underneath.
    final current = _dpmSelectedValue;
    if (current != null && !_dpmOptions.any((o) => o['id'] == current)) {
      items.insert(1, DropdownMenuItem(value: current, child: Text('$current (not found)', overflow: TextOverflow.ellipsis)));
    }
    return items;
  }

  Widget _buildTariffSection(FlutterFlowTheme theme, bool isLight) {
    final tariffItems = widget.tariffs.map((t) {
      final id = t['id']?.toString() ?? '';
      final cat = t['tariffCategory']?.toString() ?? '';
      final name = t['tariffName']?.toString() ?? '';
      final label = name.isNotEmpty ? '$cat — $name' : cat;
      return DropdownMenuItem(value: id, child: Text(label, overflow: TextOverflow.ellipsis));
    }).toList();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dropdownField(
                theme,
                isLight,
                label: 'Tariff type',
                required: true,
                value: _selectedTariffCategoryId,
                items: tariffItems,
                helpText: 'From Tariff Setting master list.',
                onChanged: (v) {
                  final t = widget.tariffs.where((t) => t['id']?.toString() == v).firstOrNull;
                  setState(() {
                    _selectedTariffCategoryId = v;
                    _selectedTariffType = t?['tariffCategory']?.toString() ?? v ?? '';
                  });
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _formField(
                theme,
                isLight,
                label: 'Contract MD',
                required: true,
                controller: _mdCtrl,
                hint: '',
                suffix: 'kW',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _dateField(
                theme,
                isLight,
                label: 'Effective from',
                required: true,
                value: _effectiveFrom,
                onTap: () => _pickDate(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dateField(
                theme,
                isLight,
                label: 'Effective to',
                value: _effectiveTo,
                helpText: 'Leave blank if this is the current contract.',
                onTap: () => _pickDate(false),
                onClear: _effectiveTo != null ? () => setState(() => _effectiveTo = null) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Widget-channel-mapping section (24h Trend / Daily Max Demand / Distribution) ──
  Widget _buildDashboardConfigSection(FlutterFlowTheme theme, bool isLight) {
    final deviceId = _dpmSelectedValue ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTrendPanel(theme, isLight, deviceId),
        const SizedBox(height: 12),
        _buildDailyMaxDemandPanel(theme, isLight, deviceId),
        const SizedBox(height: 12),
        _buildDistributionPanel(theme, isLight, deviceId),
      ],
    );
  }

  Widget _mappingPanel({
    required FlutterFlowTheme theme,
    required bool isLight,
    required String title,
    required int mappedCount,
    required int totalCount,
    required List<Widget> children,
  }) {
    final panelBg = isLight ? const Color(0xFFF7F8FA) : const Color(0xFF14151A);
    final panelBorder = isLight ? const Color(0xFFE3E8EF) : const Color(0xFF2A2C33);
    final mapped = mappedCount == totalCount && totalCount > 0;
    final badgeBg = mapped ? (isLight ? const Color(0xFFECFDF5) : const Color(0xFF0D3328)) : (isLight ? const Color(0xFFFEF2F2) : const Color(0xFF3D1F1F));
    final badgeText =
        mapped ? (isLight ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)) : (isLight ? const Color(0xFFB91C1C) : const Color(0xFFF87171));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: panelBorder))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: theme.txtSecondary, letterSpacing: 0.6),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '$mappedCount/$totalCount mapped',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: badgeText),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _singleWidgetRow({
    required FlutterFlowTheme theme,
    required bool isLight,
    required TextEditingController labelCtrl,
    required String hint,
    required String channelMapping,
    required String livePreview,
    required bool loadingPreview,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _formField(theme, isLight, label: 'Widget title', controller: labelCtrl, hint: hint),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Channel mapping', style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted)),
              const SizedBox(height: 4),
              Text(
                channelMapping,
                style: GoogleFonts.poppins(fontSize: 12, color: theme.txtSecondary, fontFeatures: [const FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Unit  ', style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted)),
                  Text('kW', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: theme.txtSecondary)),
                  const SizedBox(width: 16),
                  Text('Live preview  ', style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted)),
                  loadingPreview
                      ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.txtMuted))
                      : Text(livePreview, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: theme.txtPrimary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendPanel(FlutterFlowTheme theme, bool isLight, String deviceId) {
    final mapped = deviceId.isNotEmpty ? 1 : 0;
    final channel = deviceId.isNotEmpty ? '$deviceId · power_kw (5m avg, 24h)' : '— set DPM ID config above';
    final preview = deviceId.isEmpty ? '—' : (_trendPreviewCount != null ? '$_trendPreviewCount pts · 24h' : 'No data');
    return _mappingPanel(
      theme: theme,
      isLight: isLight,
      title: '24-HOUR POWER LOAD TREND',
      mappedCount: mapped,
      totalCount: 1,
      children: [
        _singleWidgetRow(
          theme: theme,
          isLight: isLight,
          labelCtrl: _trendLabelCtrl,
          hint: '24-Hour Power Load Trend',
          channelMapping: channel,
          livePreview: preview,
          loadingPreview: _loadingTrendPreview,
        ),
      ],
    );
  }

  Widget _buildDailyMaxDemandPanel(FlutterFlowTheme theme, bool isLight, String deviceId) {
    final mapped = deviceId.isNotEmpty ? 1 : 0;
    final channel = deviceId.isNotEmpty ? '$deviceId · max_demand_kW (daily)' : '— set DPM ID config above';
    final preview = deviceId.isEmpty ? '—' : (_dailyPreviewCount != null ? '$_dailyPreviewCount bars · MTD' : 'No data');
    return _mappingPanel(
      theme: theme,
      isLight: isLight,
      title: 'DAILY MAXIMUM DEMAND THIS MONTH',
      mappedCount: mapped,
      totalCount: 1,
      children: [
        _singleWidgetRow(
          theme: theme,
          isLight: isLight,
          labelCtrl: _dailyLabelCtrl,
          hint: 'Daily Maximum Demand This Month',
          channelMapping: channel,
          livePreview: preview,
          loadingPreview: _loadingDailyPreview,
        ),
      ],
    );
  }

  Widget _timeChip(FlutterFlowTheme theme, bool isLight, String hhmm) {
    final borderColor = isLight ? const Color(0xFFD1D5DB) : theme.cardStroke;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF3F4F6) : theme.primaryBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(hhmm, style: GoogleFonts.poppins(fontSize: 12, color: theme.txtPrimary, fontFeatures: [const FontFeature.tabularFigures()])),
    );
  }

  Widget _bucketRow(FlutterFlowTheme theme, bool isLight, int index, String deviceId) {
    final bucket = _buckets[index];
    final avg = _distributionPreview?[bucket.key];
    final preview = deviceId.isEmpty ? '—' : (avg != null ? '~${avg.toStringAsFixed(0)} kW avg' : 'No data');
    final borderColor = isLight ? const Color(0xFFE3E8EF) : theme.cardStroke;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 78,
            child: Text(bucket.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: theme.txtPrimary)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(onTap: () => _pickBucketTime(index, true), child: _timeChip(theme, isLight, bucket.startTime)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('–', style: GoogleFonts.poppins(fontSize: 12, color: theme.txtMuted)),
              ),
              InkWell(onTap: () => _pickBucketTime(index, false), child: _timeChip(theme, isLight, bucket.endTime)),
            ],
          ),
          Text('AVG(power_kw)', style: GoogleFonts.poppins(fontSize: 11, color: theme.txtTertiary)),
          _loadingDistributionPreview
              ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.txtMuted))
              : Text(preview, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: theme.txtPrimary)),
        ],
      ),
    );
  }

  Widget _buildDistributionPanel(FlutterFlowTheme theme, bool isLight, String deviceId) {
    final mapped = deviceId.isNotEmpty ? _buckets.length : 0;
    return _mappingPanel(
      theme: theme,
      isLight: isLight,
      title: 'POWER LOAD DISTRIBUTION',
      mappedCount: mapped,
      totalCount: _buckets.length,
      children: [
        for (int i = 0; i < _buckets.length; i++) _bucketRow(theme, isLight, i, deviceId),
        const SizedBox(height: 4),
        Text(
          'Buckets use AVG(power_kw) within each window (not SUM). Boundaries are editable per row above — '
          'the dashboard splits every day into these same windows for this meter.',
          style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildScopeBinding(FlutterFlowTheme theme, bool isLight) {
    final grouped = _areasGroupedByPlant;
    final boundBg = isLight ? const Color(0xFFFFF8EB) : const Color(0xFF3D3520);
    final boundBorder = isLight ? const Color(0xFFEDD9A3) : const Color(0xFF5C4A2A);
    final infoBg = isLight ? const Color(0xFFECFDF5) : const Color(0xFF0D3328);
    final infoBorder = isLight ? const Color(0xFFA7E8C5) : const Color(0xFF166534);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...grouped.entries.map((entry) {
          final plantId = entry.key;
          final areas = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF3F4F6) : theme.primaryBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: isLight ? const Color(0xFFE3E8EF) : theme.cardStroke),
                ),
                child: Text(
                  _plantName(plantId).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.txtMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...areas.map((area) {
                final areaId = area['id']?.toString() ?? '';
                final areaName = area['name']?.toString() ?? '';
                final eqCount = (area['equipment_count'] as num?)?.toInt() ?? 0;
                final isSelected = _selectedAreaIds.contains(areaId);
                final boundTo = _boundToMeter(areaId);
                final isBound = boundTo != null;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBound ? boundBg : (isLight ? Colors.white : theme.primaryBackground),
                    border: Border(
                      left: BorderSide(color: isBound ? boundBorder : (isLight ? const Color(0xFFE3E8EF) : theme.cardStroke)),
                      right: BorderSide(color: isBound ? boundBorder : (isLight ? const Color(0xFFE3E8EF) : theme.cardStroke)),
                      bottom: BorderSide(color: isBound ? boundBorder : (isLight ? const Color(0xFFE3E8EF) : theme.cardStroke)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedAreaIds.add(areaId);
                              } else {
                                _selectedAreaIds.remove(areaId);
                              }
                            });
                          },
                          activeColor: const Color(0xFF2D4739),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              areaName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isLight ? const Color(0xFF92702A) : const Color(0xFFD4A843),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _plantName(plantId),
                                  style: GoogleFonts.poppins(fontSize: 11, color: theme.txtTertiary),
                                ),
                                if (isBound) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '⊙ bound to $boundTo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isLight ? const Color(0xFF92702A) : const Color(0xFFD4A843),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$eqCount eq',
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.txtMuted),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          );
        }),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: infoBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: infoBorder),
          ),
          child: Column(
            children: [
              _infoRow('Plant (auto-derived)', _derivedPlant.isNotEmpty ? _derivedPlant : '— select areas above —', theme),
              const SizedBox(height: 4),
              _infoRow('Equipment count (live)', '$_totalBoundEquipment devices', theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, FlutterFlowTheme theme) {
    return Row(
      children: [
        Text('⊙ ', style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary)),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: theme.txtSecondary)),
      ],
    );
  }

  Widget _buildStatusSection(FlutterFlowTheme theme, bool isLight) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: theme.txtPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'When inactive, this meter is hidden from dashboards. History is preserved.',
                style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary),
              ),
            ],
          ),
        ),
        Switch(
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
          activeColor: const Color(0xFF2D4739),
        ),
      ],
    );
  }

  Widget _formField(
    FlutterFlowTheme theme,
    bool isLight, {
    required String label,
    bool required = false,
    required TextEditingController controller,
    String hint = '',
    String? helpText,
    String? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final borderColor = isLight ? const Color(0xFFD1D5DB) : theme.cardStroke;
    final fillColor = isLight ? Colors.white : theme.primaryBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required, theme),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(fontSize: 13, color: theme.txtPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted),
            filled: true,
            fillColor: fillColor,
            suffixText: suffix,
            suffixStyle: GoogleFonts.poppins(fontSize: 13, color: theme.txtMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D4739), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(helpText, style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted)),
        ],
      ],
    );
  }

  Widget _dropdownField(
    FlutterFlowTheme theme,
    bool isLight, {
    required String label,
    bool required = false,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    String? helpText,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final borderColor = isLight ? const Color(0xFFD1D5DB) : theme.cardStroke;
    final fillColor = isLight ? Colors.white : theme.primaryBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required, theme),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 20, color: theme.txtMuted),
          dropdownColor: isLight ? Colors.white : theme.primaryBackground,
          style: GoogleFonts.poppins(fontSize: 13, color: theme.txtPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D4739), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(helpText, style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted)),
        ],
      ],
    );
  }

  Widget _dateField(
    FlutterFlowTheme theme,
    bool isLight, {
    required String label,
    bool required = false,
    DateTime? value,
    String? helpText,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final borderColor = isLight ? const Color(0xFFD1D5DB) : theme.cardStroke;
    final fillColor = isLight ? Colors.white : theme.primaryBackground;
    final fmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required, theme),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? fmt.format(value) : 'dd/mm/yyyy',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: value != null ? theme.txtPrimary : theme.txtMuted,
                    ),
                  ),
                ),
                if (onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.clear, size: 16, color: theme.txtMuted),
                  ),
                if (onClear != null) const SizedBox(width: 4),
                Icon(Icons.calendar_today_outlined, size: 16, color: theme.txtMuted),
              ],
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(helpText, style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted)),
        ],
      ],
    );
  }

  Widget _fieldLabel(String label, bool required, FlutterFlowTheme theme) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: theme.txtPrimary),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFDC2626)),
            ),
        ],
      ),
    );
  }
}
