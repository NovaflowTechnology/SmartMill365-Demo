import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/emission_factor_record.dart';
import '/components/page_header/breadcrumb_item.dart';
import '/components/page_header/page_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../master_facility_setting/models/facility_data.dart';
import '../master_facility_setting/services/facility_service.dart';
import '../carbon_emission/carbon_dashboard_config.dart';

/// Settings > Energy & Billing > Carbon Dashboard Config.
///
/// Maps every card on the Carbon Intelligence Dashboard to a source Device
/// ID from Master Facility Setting (digital power meters flagged for carbon
/// calc) or Equipment Settings (equipment with the Energy module enabled).
/// Saved config is read back by `CarbonEmissionWidget` on load.
class CarbonDashboardConfigSettingWidget extends StatefulWidget {
  const CarbonDashboardConfigSettingWidget({super.key});

  @override
  State<CarbonDashboardConfigSettingWidget> createState() => _CarbonDashboardConfigSettingWidgetState();
}

class _CarbonDashboardConfigSettingWidgetState extends State<CarbonDashboardConfigSettingWidget> {
  bool _loading = true;
  // True only while switching between plants (after the initial load) — the
  // page shell stays visible/disabled instead of being replaced by the
  // full-page spinner, since the plant switcher itself lives in that shell.
  bool _configLoading = false;
  bool _saving = false;
  // True once a field has been edited since the current plant's config was
  // loaded/saved — guards against silently discarding edits on plant switch.
  bool _dirty = false;
  String? _error;

  List<FacilityData> _devices = [];
  List<EquipmentItem> _energyEquipment = [];
  // Each plant stores its own config, so exactly one plant is active at a
  // time (unlike a typical multi-select filter over shared data).
  String? _selectedPlant;
  double? _activeFactor;
  int? _activeFiscalYear;

  String? _netEmissionDeviceId;
  String? _carbonIntensityDeviceId;
  String? _totalConsumptionDeviceId;
  String? _solarDeviceId;
  late final TextEditingController _carbonPriceCtrl;
  String? _blockADeviceId;
  String? _blockBDeviceId;
  String? _blockCDeviceId;
  Set<String> _topContributorDeviceIds = {};
  Set<String> _productionLineEquipmentIds = {};

  @override
  void initState() {
    super.initState();
    _carbonPriceCtrl = TextEditingController();
    _bootstrap();
  }

  @override
  void dispose() {
    _carbonPriceCtrl.dispose();
    super.dispose();
  }

  // ── Plant switcher ──────────────────────────────────────────────────────
  // Every plant stores its own Device ID mapping, so this is a single-select
  // "which config am I editing" switch, not a multi-select filter over
  // shared data.
  List<String> get _plantOptions => {
        ..._devices.map((d) => d.plant),
        ..._energyEquipment.map((e) => e.factory),
      }.where((p) => p.isNotEmpty && p != '-').toList()
        ..sort();

  List<FacilityData> get _visibleDevices {
    if (_selectedPlant == null) return const [];
    if (_selectedPlant == kUnassignedPlantKey) return _devices;
    return _devices.where((d) => d.plant.isEmpty || d.plant == _selectedPlant).toList();
  }

  List<EquipmentItem> get _visibleEquipment {
    if (_selectedPlant == null) return const [];
    if (_selectedPlant == kUnassignedPlantKey) return _energyEquipment;
    return _energyEquipment.where((e) => e.factory.isEmpty || e.factory == _selectedPlant).toList();
  }

  void _applyConfigToFields(CarbonDashboardConfig c) {
    _netEmissionDeviceId = c.netEmissionDeviceId;
    _carbonIntensityDeviceId = c.carbonIntensityDeviceId;
    _totalConsumptionDeviceId = c.totalConsumptionDeviceId;
    _solarDeviceId = c.solarDeviceId;
    _carbonPriceCtrl.text = c.carbonPricePerTco2e?.toStringAsFixed(2) ?? '';
    _blockADeviceId = c.blockADeviceId;
    _blockBDeviceId = c.blockBDeviceId;
    _blockCDeviceId = c.blockCDeviceId;
    _topContributorDeviceIds = c.topContributorDeviceIds.toSet();
    _productionLineEquipmentIds = c.productionLineEquipmentIds.toSet();
  }

  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait([
        FacilityService.getFacilities(),
        FacilityService.getEquipments(),
        EmissionFactorRecord.collection.where('status', isEqualTo: 'active').limit(1).get(),
      ]);
      final facilities = (results[0] as List<FacilityData>)
          .where((f) => f.includeCarbonCalc && f.meterId.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.meterId.compareTo(b.meterId));
      final equipment = (results[1] as List<EquipmentItem>).where((e) => e.enableEnergy).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final factorSnap = results[2] as QuerySnapshot;
      double? factor;
      int? fiscalYear;
      if (factorSnap.docs.isNotEmpty) {
        final rec = EmissionFactorRecord.fromSnapshot(factorSnap.docs.first);
        factor = rec.factor;
        fiscalYear = rec.fiscalYear;
      }
      if (!mounted) return;
      setState(() {
        _devices = facilities;
        _energyEquipment = equipment;
        _activeFactor = factor;
        _activeFiscalYear = fiscalYear;
      });

      // "All Plants" is the default landing scope — same config bucket used
      // as the inherited default for any plant without its own saved config.
      await _loadPlantConfig(kUnassignedPlantKey, initial: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load facility / equipment data: $e';
        _loading = false;
      });
    }
  }

  /// Loads [plant]'s saved config — local cache first, then reconciled with
  /// the backend (client-scoped via x-client-id) once it responds. On
  /// [initial] load the full-page spinner is used; later switches only
  /// toggle [_configLoading] so the plant switcher itself stays visible.
  Future<void> _loadPlantConfig(String plant, {bool initial = false}) async {
    setState(() {
      _selectedPlant = plant;
      if (initial) {
        _loading = true;
      } else {
        _configLoading = true;
      }
    });

    final cached = await CarbonDashboardConfigStore.load(plant);
    if (mounted) setState(() => _applyConfigToFields(cached));

    final uid = AppStateNotifier.instance.uid ?? '';
    final remote = await CarbonDashboardConfigService.fetch(uid, plant);
    if (remote != null) {
      if (mounted) setState(() => _applyConfigToFields(remote));
      await CarbonDashboardConfigStore.save(plant, remote);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _configLoading = false;
      _dirty = false;
    });
  }

  static String _plantLabel(String? key) => key == kUnassignedPlantKey ? 'All Plants' : (key ?? '');

  /// Switches the active plant, confirming first if there are unsaved edits
  /// for the plant being left.
  Future<void> _onSelectPlant(String plant) async {
    if (plant == _selectedPlant) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: Text(
              '"${_plantLabel(_selectedPlant)}" has unsaved changes. Switching to "${_plantLabel(plant)}" will discard them.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
          ],
        ),
      );
      if (discard != true) return;
    }
    await _loadPlantConfig(plant);
  }

  Future<void> _save() async {
    final plant = _selectedPlant;
    if (plant == null) return;
    setState(() => _saving = true);
    final config = CarbonDashboardConfig(
      netEmissionDeviceId: _netEmissionDeviceId,
      carbonIntensityDeviceId: _carbonIntensityDeviceId,
      totalConsumptionDeviceId: _totalConsumptionDeviceId,
      solarDeviceId: _solarDeviceId,
      carbonPricePerTco2e: double.tryParse(_carbonPriceCtrl.text.trim()),
      blockADeviceId: _blockADeviceId,
      blockBDeviceId: _blockBDeviceId,
      blockCDeviceId: _blockCDeviceId,
      topContributorDeviceIds: _topContributorDeviceIds.toList(),
      productionLineEquipmentIds: _productionLineEquipmentIds.toList(),
    );
    final uid = AppStateNotifier.instance.uid ?? '';
    final results = await Future.wait([
      CarbonDashboardConfigStore.save(plant, config).then((_) => true),
      CarbonDashboardConfigService.save(uid, plant, config),
    ]);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    final savedRemotely = results[1];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedRemotely
              ? 'Carbon dashboard configuration saved for ${_plantLabel(plant)}.'
              : 'Saved locally — could not reach the server, will retry on next save.',
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _netEmissionDeviceId = null;
      _carbonIntensityDeviceId = null;
      _totalConsumptionDeviceId = null;
      _solarDeviceId = null;
      _carbonPriceCtrl.clear();
      _blockADeviceId = null;
      _blockBDeviceId = null;
      _blockCDeviceId = null;
      _topContributorDeviceIds.clear();
      _productionLineEquipmentIds.clear();
      _dirty = true;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────
  //
  // Full-width settings page (matches sibling pages like Master Billing
  // Config / Emission Factor Management) — NOT a centered modal-style card.
  // Sections stack as their own full-width panels edge-to-edge with the
  // page padding.

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);

    return Scaffold(
      backgroundColor: t.primaryBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: t.primaryBackground,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset('assets/images/backgroundanimated.gif').image,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                breadcrumbs: [
                  BreadcrumbItem(label: 'Settings', icon: Icons.settings),
                  BreadcrumbItem(label: 'Energy & Billing'),
                  BreadcrumbItem(label: 'Carbon Dashboard Config'),
                ],
                title: 'Carbon Dashboard Configuration',
                subtitle: 'Map each Carbon Intelligence Dashboard card to a source Device ID',
              ),
              Expanded(child: _body(t, isLight, borderColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(FlutterFlowTheme t, bool isLight, Color borderColor) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: t.error)),
      );
    }
    return AbsorbPointer(
      absorbing: _configLoading,
      child: Opacity(
        opacity: _configLoading ? 0.5 : 1,
        child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _emissionFactorBanner(t, isLight)),
              const SizedBox(width: 12),
              _plantSelector(t, isLight),
            ],
          ),
          const SizedBox(height: 20),
          _sectionPanel(
            t: t, isLight: isLight, borderColor: borderColor,
            title: 'KPI CARDS',
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
              return _fieldGrid(columns: columns, children: [
                _deviceField(
                  t: t, isLight: isLight,
                  label: 'Net Carbon Emission',
                  formula: 'Device ID × Emission Factor · tCO₂e (daily, monthly)',
                  value: _netEmissionDeviceId,
                  onChanged: (v) => setState(() {
                    _netEmissionDeviceId = v;
                    _dirty = true;
                  }),
                ),
                _deviceField(
                  t: t, isLight: isLight,
                  label: 'Carbon Intensity',
                  formula: 'Device ID ÷ Production Output · kgCO₂e/ton (daily, monthly)',
                  value: _carbonIntensityDeviceId,
                  onChanged: (v) => setState(() {
                    _carbonIntensityDeviceId = v;
                    _dirty = true;
                  }),
                ),
                _deviceField(
                  t: t, isLight: isLight,
                  label: 'Total Energy Consumption (Grid)',
                  formula: 'Device ID · kWh (daily, monthly)',
                  value: _totalConsumptionDeviceId,
                  onChanged: (v) => setState(() {
                    _totalConsumptionDeviceId = v;
                    _dirty = true;
                  }),
                ),
                _deviceField(
                  t: t, isLight: isLight,
                  label: 'Solar Avoided Emission',
                  formula: 'Device ID × Emission Factor · tCO₂e (daily, monthly)',
                  value: _solarDeviceId,
                  onChanged: (v) => setState(() {
                    _solarDeviceId = v;
                    _dirty = true;
                  }),
                ),
                _carbonPriceField(t, isLight),
              ]);
            }),
          ),
          const SizedBox(height: 20),
          _sectionPanel(
            t: t, isLight: isLight, borderColor: borderColor,
            title: 'CARBON FLOW — GRID IMPORT BY BLOCK',
            subtitle: 'Shown on the Carbon Flow diagram',
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 3 : 1;
              return _fieldGrid(columns: columns, children: [
                _deviceField(
                  t: t, isLight: isLight, label: 'Block A', formula: 'Grid import · tCO₂e',
                  value: _blockADeviceId,
                  onChanged: (v) => setState(() {
                    _blockADeviceId = v;
                    _dirty = true;
                  }),
                ),
                _deviceField(
                  t: t, isLight: isLight, label: 'Block B', formula: 'Grid import · tCO₂e',
                  value: _blockBDeviceId,
                  onChanged: (v) => setState(() {
                    _blockBDeviceId = v;
                    _dirty = true;
                  }),
                ),
                _deviceField(
                  t: t, isLight: isLight, label: 'Block C', formula: 'Grid import · tCO₂e',
                  value: _blockCDeviceId,
                  onChanged: (v) => setState(() {
                    _blockCDeviceId = v;
                    _dirty = true;
                  }),
                ),
              ]);
            }),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final contributors = _sectionPanel(
              t: t, isLight: isLight, borderColor: borderColor,
              title: 'TOP CARBON CONTRIBUTORS',
              subtitle: 'Selected Device ID × Emission Factor · tCO₂e (daily, monthly)',
              child: _deviceMultiSelect(
                t: t, isLight: isLight, borderColor: borderColor,
                selected: _topContributorDeviceIds,
                onToggle: (id) => setState(() {
                  if (!_topContributorDeviceIds.remove(id)) {
                    _topContributorDeviceIds.add(id);
                  }
                  _dirty = true;
                }),
              ),
            );
            final intensity = _sectionPanel(
              t: t, isLight: isLight, borderColor: borderColor,
              title: 'INTENSITY BY PRODUCTION LINE',
              subtitle: 'Equipment ID (Energy module enabled) ÷ Production Output · daily, monthly',
              child: _equipmentMultiSelect(t, isLight, borderColor),
            );

            if (constraints.maxWidth < 900) {
              return Column(children: [contributors, const SizedBox(height: 20), intensity]);
            }
            // Not IntrinsicHeight: the multi-select ListViews inside each panel
            // don't report a sane intrinsic height, which made the panels
            // overflow their borders and overlap the action bar below.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: contributors),
                const SizedBox(width: 20),
                Expanded(child: intensity),
              ],
            );
          }),
          const SizedBox(height: 24),
          _actionBar(t),
        ],
      ),
        ),
      ),
    );
  }

  /// Single-select plant switcher — picking a plant loads (and subsequent
  /// edits save to) that plant's own config, unlike a filter over shared data.
  Widget _plantSelector(FlutterFlowTheme t, bool isLight) {
    final options = _plantOptions;
    final cardBg = isLight ? Colors.white : const Color(0xFF111827);
    final borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.factory_outlined, size: 14, color: t.txtMuted),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlant,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: t.txtMuted),
              dropdownColor: cardBg,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
              items: [
                const DropdownMenuItem(value: kUnassignedPlantKey, child: Text('All Plants', overflow: TextOverflow.ellipsis)),
                for (final opt in options) DropdownMenuItem(value: opt, child: Text(opt, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) {
                if (v != null) unawaited(_onSelectPlant(v));
              },
            ),
          ),
          if (_configLoading) ...[
            const SizedBox(width: 8),
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: t.primary)),
          ],
        ],
      ),
    );
  }

  Widget _sectionPanel({
    required FlutterFlowTheme t,
    required bool isLight,
    required Color borderColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final cardBg = isLight ? Colors.white : const Color(0xFF111827);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionLabel(t, title),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtSubtle, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _fieldGrid({required int columns, required List<Widget> children}) {
    if (columns <= 1) {
      return Column(
        children: [for (final c in children) ...[c, const SizedBox(height: 16)]]
          ..removeLast(),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final gap = 20.0 * (columns - 1);
      final itemWidth = (constraints.maxWidth - gap) / columns;
      return Wrap(
        spacing: 20,
        runSpacing: 16,
        children: [for (final c in children) SizedBox(width: itemWidth, child: c)],
      );
    });
  }

  Widget _actionBar(FlutterFlowTheme t) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _saving || _loading ? null : _reset,
          icon: Icon(Icons.restart_alt_rounded, size: 16, color: t.error),
          label: Text('Reset', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: t.error)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: t.error.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _saving || _loading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: t.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Save & Apply', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _emissionFactorBanner(FlutterFlowTheme t, bool isLight) {
    final hasFactor = _activeFactor != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: (hasFactor ? t.success : t.warning).withOpacity(isLight ? 0.06 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (hasFactor ? t.success : t.warning).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(hasFactor ? Icons.eco_rounded : Icons.warning_amber_rounded, size: 15, color: hasFactor ? t.success : t.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasFactor
                  ? 'Active emission factor: ${_activeFactor!.toStringAsFixed(3)} tCO₂e/MWh (FY $_activeFiscalYear) — from Emission Factor Management'
                  : 'No active emission factor set — configure one in Emission Factor Management',
              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(FlutterFlowTheme t, String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: t.primary),
    );
  }

  Widget _deviceField({
    required FlutterFlowTheme t,
    required bool isLight,
    required String label,
    required String formula,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white)),
        const SizedBox(height: 2),
        Text(formula, style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle)),
        const SizedBox(height: 6),
        _dropdownShell(
          t: t,
          isLight: isLight,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value != null && _visibleDevices.any((d) => d.meterId == value) ? value : null,
              hint: Text(
                _visibleDevices.isEmpty ? 'No carbon-flagged devices found' : 'Select Device ID',
                style: GoogleFonts.poppins(fontSize: 11, color: t.txtSubtle),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: t.txtMuted),
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
              dropdownColor: isLight ? Colors.white : const Color(0xFF111827),
              items: [
                for (final d in _visibleDevices)
                  DropdownMenuItem(
                    value: d.meterId,
                    child: Text(
                      d.meterName.isNotEmpty ? '${d.meterId} — ${d.meterName}' : d.meterId,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _visibleDevices.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _carbonPriceField(FlutterFlowTheme t, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emission Cost — Carbon Price', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white)),
        const SizedBox(height: 2),
        Text('Net Carbon Emission × Carbon Price · RM (daily, monthly)', style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle)),
        const SizedBox(height: 6),
        _dropdownShell(
          t: t,
          isLight: isLight,
          child: TextField(
            controller: _carbonPriceCtrl,
            onChanged: (_) => _dirty = true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              prefixText: 'RM ',
              prefixStyle: GoogleFonts.poppins(fontSize: 11.5, color: t.txtMuted),
              hintText: 'e.g. 75.00 per tCO₂e',
              hintStyle: GoogleFonts.poppins(fontSize: 11, color: t.txtSubtle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownShell({required FlutterFlowTheme t, required bool isLight, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: child,
    );
  }

  Widget _deviceMultiSelect({
    required FlutterFlowTheme t,
    required bool isLight,
    required Color borderColor,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    if (_visibleDevices.isEmpty) {
      return Text('No carbon-flagged devices found in Master Facility Setting', style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSubtle));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Scrollbar(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final d in _visibleDevices)
              CheckboxListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected.contains(d.meterId),
                onChanged: (_) => onToggle(d.meterId),
                title: Text(
                  d.meterName.isNotEmpty ? '${d.meterId} — ${d.meterName}' : d.meterId,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                ),
                subtitle: d.productionArea.isNotEmpty
                    ? Text(d.productionArea, style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted))
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _equipmentMultiSelect(FlutterFlowTheme t, bool isLight, Color borderColor) {
    if (_visibleEquipment.isEmpty) {
      return Text(
        'No equipment with the Energy module enabled — enable it in Equipment Settings',
        style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSubtle),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Scrollbar(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final e in _visibleEquipment)
              CheckboxListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                value: _productionLineEquipmentIds.contains(e.equipmentId.isNotEmpty ? e.equipmentId : e.id),
                onChanged: (_) => setState(() {
                  final id = e.equipmentId.isNotEmpty ? e.equipmentId : e.id;
                  if (!_productionLineEquipmentIds.remove(id)) _productionLineEquipmentIds.add(id);
                  _dirty = true;
                }),
                title: Text(
                  e.displayLabel,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                ),
                subtitle: e.productionLine.isNotEmpty
                    ? Text(e.productionLine, style: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted))
                    : null,
              ),
          ],
        ),
      ),
    );
  }

}
