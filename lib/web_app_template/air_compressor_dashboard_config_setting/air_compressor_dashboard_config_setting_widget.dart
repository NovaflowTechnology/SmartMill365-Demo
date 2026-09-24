import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/components/page_header/breadcrumb_item.dart';
import '/components/page_header/page_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../master_facility_setting/models/facility_data.dart';
import '../master_facility_setting/services/facility_service.dart';
import '../air_compressor_monitoring/air_compressor_dashboard_config.dart';
import '../air_compressor_monitoring/air_compressor_monitoring_model.dart' show kAcCastPoints;
import 'widgets/settings_section_card.dart';
import 'widgets/mapping_completion_ring.dart';
import 'widgets/config_lineage_row.dart';
import 'widgets/device_field_row.dart';
import 'widgets/multi_device_field.dart';
import 'widgets/synced_reference_chip.dart';
import 'widgets/demand_load_row.dart';

/// Settings > Utility Monitoring > Air Compressor Dashboard Setting.
///
/// Maps each Air Compressor Monitoring dashboard card to a source Device ID
/// from Master Facility Setting. Saved config is read back by
/// `AirCompressorMonitoringWidget` on load.
class AirCompressorDashboardConfigSettingWidget extends StatefulWidget {
  const AirCompressorDashboardConfigSettingWidget({super.key});

  @override
  State<AirCompressorDashboardConfigSettingWidget> createState() => _AirCompressorDashboardConfigSettingWidgetState();
}

class _AirCompressorDashboardConfigSettingWidgetState extends State<AirCompressorDashboardConfigSettingWidget> {
  // Fixed plant scope — matches the dashboard's own single-fixed-page scope.
  static const String _plant = 'Lot 237';

  bool _loading = true;
  bool _saving = false;

  List<FacilityData> _devices = [];

  List<String> _totalPowerDeviceIds = [];
  String? _totalPowerField;
  String? _headerFlowDeviceId;
  String? _headerFlowField;
  String? _headerPressureDeviceId;
  String? _headerPressureField;
  String? _ac1DeviceId;
  String? _ac1Field;
  String? _ac2DeviceId;
  String? _ac2Field;
  late final TextEditingController _seBandLowCtrl;
  late final TextEditingController _seBandHighCtrl;
  late final TextEditingController _minFlowCtrl;
  late final TextEditingController _nightStartCtrl;
  late final TextEditingController _nightEndCtrl;
  late final TextEditingController _nextMaintenanceCtrl;
  String? _availabilityDeviceId;
  String? _downtimeDeviceId;
  String? _dewPointDeviceId;
  bool _roleAssignmentAuto = true;
  String? _ac1RoleOverride;
  String? _ac2RoleOverride;

  // One requirement-pressure/flow controller pair + Device ID + metric
  // field per entry in kAcCastPoints, indices aligned 1:1 with that list.
  late final List<TextEditingController> _demandReqPressureCtrls;
  late final List<TextEditingController> _demandReqFlowCtrls;
  late List<String?> _demandDeviceIds;
  late List<String?> _demandFields;

  @override
  void initState() {
    super.initState();
    _seBandLowCtrl = TextEditingController();
    _seBandHighCtrl = TextEditingController();
    _minFlowCtrl = TextEditingController();
    _nightStartCtrl = TextEditingController();
    _nightEndCtrl = TextEditingController();
    _nextMaintenanceCtrl = TextEditingController();
    _demandReqPressureCtrls = [for (var i = 0; i < kAcCastPoints.length; i++) TextEditingController()];
    _demandReqFlowCtrls = [for (var i = 0; i < kAcCastPoints.length; i++) TextEditingController()];
    _demandDeviceIds = List<String?>.filled(kAcCastPoints.length, null);
    _demandFields = List<String?>.filled(kAcCastPoints.length, null);
    _bootstrap();
  }

  @override
  void dispose() {
    _seBandLowCtrl.dispose();
    _seBandHighCtrl.dispose();
    _minFlowCtrl.dispose();
    _nightStartCtrl.dispose();
    _nightEndCtrl.dispose();
    _nextMaintenanceCtrl.dispose();
    for (final c in _demandReqPressureCtrls) {
      c.dispose();
    }
    for (final c in _demandReqFlowCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyConfigToFields(AirCompressorDashboardConfig c) {
    _totalPowerDeviceIds = [...c.totalPowerDeviceIds];
    _totalPowerField = c.totalPowerField;
    _headerFlowDeviceId = c.headerFlowDeviceId;
    _headerFlowField = c.headerFlowField;
    _headerPressureDeviceId = c.headerPressureDeviceId;
    _headerPressureField = c.headerPressureField;
    _ac1DeviceId = c.ac1DeviceId;
    _ac1Field = c.ac1Field;
    _ac2DeviceId = c.ac2DeviceId;
    _ac2Field = c.ac2Field;
    _seBandLowCtrl.text = c.seBandLow?.toStringAsFixed(1) ?? '';
    _seBandHighCtrl.text = c.seBandHigh?.toStringAsFixed(1) ?? '';
    _minFlowCtrl.text = c.minFlowThreshold?.toStringAsFixed(0) ?? '';
    _nightStartCtrl.text = c.nightWindowStart;
    _nightEndCtrl.text = c.nightWindowEnd;
    _nextMaintenanceCtrl.text = c.nextMaintenanceLabel ?? '';
    _availabilityDeviceId = c.availabilityDeviceId;
    _downtimeDeviceId = c.downtimeDeviceId;
    _dewPointDeviceId = c.dewPointDeviceId;
    _roleAssignmentAuto = c.roleAssignmentAuto;
    _ac1RoleOverride = c.ac1RoleOverride;
    _ac2RoleOverride = c.ac2RoleOverride;

    for (var i = 0; i < kAcCastPoints.length; i++) {
      final saved = c.demandLoads.where((d) => d.label == kAcCastPoints[i].label).firstOrNull;
      _demandReqPressureCtrls[i].text = saved?.reqPressure?.toStringAsFixed(1) ?? '';
      _demandReqFlowCtrls[i].text = saved?.reqFlow?.toStringAsFixed(1) ?? '';
      _demandDeviceIds[i] = saved?.deviceId;
      _demandFields[i] = saved?.field;
    }
  }

  Future<void> _bootstrap() async {
    // Local cache first (instant paint), then reconcile with the backend
    // (client-scoped via x-client-id) once it responds — same pattern as
    // CarbonDashboardConfigSettingWidget.
    final results = await Future.wait([
      FacilityService.getFacilities(),
      AirCompressorDashboardConfigStore.load(_plant),
    ]);
    if (!mounted) return;
    final facilities = (results[0] as List<FacilityData>).where((f) => f.meterId.trim().isNotEmpty).toList()
      ..sort((a, b) => a.meterId.compareTo(b.meterId));
    setState(() {
      _devices = facilities;
      _applyConfigToFields(results[1] as AirCompressorDashboardConfig);
      _loading = false;
    });

    final uid = AppStateNotifier.instance.uid ?? '';
    final remote = await AirCompressorDashboardConfigService.fetch(uid, _plant);
    if (remote != null) {
      if (mounted) setState(() => _applyConfigToFields(remote));
      await AirCompressorDashboardConfigStore.save(_plant, remote);
    }
  }

  AirCompressorDashboardConfig get _currentConfig => AirCompressorDashboardConfig(
        totalPowerDeviceIds: _totalPowerDeviceIds,
        totalPowerField: _totalPowerField,
        headerFlowDeviceId: _headerFlowDeviceId,
        headerFlowField: _headerFlowField,
        headerPressureDeviceId: _headerPressureDeviceId,
        headerPressureField: _headerPressureField,
        ac1DeviceId: _ac1DeviceId,
        ac1Field: _ac1Field,
        ac2DeviceId: _ac2DeviceId,
        ac2Field: _ac2Field,
        seBandLow: _seBandLowCtrl.text.trim().isEmpty ? null : double.tryParse(_seBandLowCtrl.text.trim()),
        seBandHigh: _seBandHighCtrl.text.trim().isEmpty ? null : double.tryParse(_seBandHighCtrl.text.trim()),
        minFlowThreshold: _minFlowCtrl.text.trim().isEmpty ? null : double.tryParse(_minFlowCtrl.text.trim()),
        nightWindowStart: _nightStartCtrl.text.trim().isEmpty ? '22:00' : _nightStartCtrl.text.trim(),
        nightWindowEnd: _nightEndCtrl.text.trim().isEmpty ? '06:00' : _nightEndCtrl.text.trim(),
        nextMaintenanceLabel: _nextMaintenanceCtrl.text.trim().isEmpty ? null : _nextMaintenanceCtrl.text.trim(),
        availabilityDeviceId: _availabilityDeviceId,
        downtimeDeviceId: _downtimeDeviceId,
        dewPointDeviceId: _dewPointDeviceId,
        roleAssignmentAuto: _roleAssignmentAuto,
        ac1RoleOverride: _ac1RoleOverride,
        ac2RoleOverride: _ac2RoleOverride,
        demandLoads: [
          for (var i = 0; i < kAcCastPoints.length; i++)
            AcDemandLoadConfig(
              label: kAcCastPoints[i].label,
              reqPressure: _demandReqPressureCtrls[i].text.trim().isEmpty ? null : double.tryParse(_demandReqPressureCtrls[i].text.trim()),
              reqFlow: _demandReqFlowCtrls[i].text.trim().isEmpty ? null : double.tryParse(_demandReqFlowCtrls[i].text.trim()),
              deviceId: _demandDeviceIds[i],
              field: _demandFields[i],
            ),
        ],
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    final config = _currentConfig;
    final uid = AppStateNotifier.instance.uid ?? '';
    final results = await Future.wait([
      AirCompressorDashboardConfigStore.save(_plant, config).then((_) => true),
      AirCompressorDashboardConfigService.save(uid, _plant, config),
    ]);
    if (!mounted) return;
    setState(() => _saving = false);
    final savedRemotely = results[1];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedRemotely
              ? 'Air Compressor dashboard configuration saved & applied.'
              : 'Saved locally — could not reach the server, will retry on next save.',
        ),
      ),
    );
  }

  void _reset() {
    setState(() => _applyConfigToFields(AirCompressorDashboardConfig.empty()));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: t.primaryBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: t.primaryBackground,
          image: DecorationImage(fit: BoxFit.cover, image: Image.asset('assets/images/backgroundanimated.gif').image),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                breadcrumbs: [
                  BreadcrumbItem(label: 'Settings', icon: Icons.settings),
                  BreadcrumbItem(label: 'Utility Monitoring'),
                  BreadcrumbItem(label: 'Air Compressor Dashboard Setting'),
                ],
                title: 'Air Compressor Dashboard Setting',
                subtitle: 'Map each Air Compressor Monitoring card to a source Device ID · $_plant',
              ),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(FlutterFlowTheme t) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mappedCount = _currentConfig.mappedCount;
    final percent = mappedCount / AirCompressorDashboardConfig.totalSlots * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ConfigLineageRow(steps: [
            LineageStep(label: 'Device Discovery', sublabel: 'scanned source', state: LineageStepState.done),
            LineageStep(label: 'Master Facility Setting', sublabel: 'AC1, AC2 → Lot 237', state: LineageStepState.done),
            LineageStep(label: 'Dashboard Setting', sublabel: 'you are here', state: LineageStepState.here),
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              MappingCompletionRing(percent: percent),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$mappedCount of ${AirCompressorDashboardConfig.totalSlots} slots mapped',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
                  ),
                  Text('Insight rules stay DB-managed — everything else maps to a Device ID here',
                      style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSubtle)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Top KPI
          SettingsSectionCard(
            index: 1,
            title: 'Top Panel — KPI',
            description: 'Master source for Total Power, Header Flow, Header Pressure',
            statusLabel: 'Master',
            statusColor: t.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MultiDeviceField(
                  label: 'Total Power',
                  formula: 'Σ of selected compressors · MASTER',
                  devices: _devices,
                  selectedIds: _totalPowerDeviceIds,
                  onChanged: (ids) => setState(() => _totalPowerDeviceIds = ids),
                  addLabel: '+ Add compressor (AC)',
                  fieldOptions: kAcPowerMetricFields,
                  selectedField: _totalPowerField,
                  onFieldChanged: (v) => setState(() => _totalPowerField = v),
                ),
                DeviceFieldRow(
                  label: 'Header Flow',
                  formula: 'MASTER source',
                  devices: _devices,
                  value: _headerFlowDeviceId,
                  onChanged: (v) => setState(() => _headerFlowDeviceId = v),
                  fieldOptions: kAcFlowMetricFields,
                  selectedField: _headerFlowField,
                  onFieldChanged: (v) => setState(() => _headerFlowField = v),
                ),
                DeviceFieldRow(
                  label: 'Header Pressure',
                  formula: 'MASTER source',
                  devices: _devices,
                  value: _headerPressureDeviceId,
                  onChanged: (v) => setState(() => _headerPressureDeviceId = v),
                  fieldOptions: kAcPressureMetricFields,
                  selectedField: _headerPressureField,
                  onFieldChanged: (v) => setState(() => _headerPressureField = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withOpacity(isLight ? 0.06 : 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFA78BFA)),
                            const SizedBox(width: 6),
                            Text('Specific Energy',
                                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA78BFA).withOpacity(isLight ? 0.12 : 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.4)),
                              ),
                              child: Text('kW/(m³/min)',
                                  style: GoogleFonts.robotoMono(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFA78BFA))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Power ÷ Header Flow. Header Flow has no live backend yet, so this KPI shows "N/A" '
                          'until that telemetry exists.',
                          style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFA78BFA), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Distribution
          SettingsSectionCard(
            index: 2,
            title: 'Air Compressor Distribution to Header',
            description: 'Per-AC device · header synced from Panel 1',
            statusLabel: '2 slots',
            statusColor: t.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DeviceFieldRow(
                  label: 'AC1',
                  formula: 'Power, Load %, Flow',
                  devices: _devices,
                  value: _ac1DeviceId,
                  onChanged: (v) => setState(() => _ac1DeviceId = v),
                  fieldOptions: kAcPowerMetricFields,
                  selectedField: _ac1Field,
                  onFieldChanged: (v) => setState(() => _ac1Field = v),
                ),
                DeviceFieldRow(
                  label: 'AC2',
                  formula: 'Power, Load %, Flow',
                  devices: _devices,
                  value: _ac2DeviceId,
                  onChanged: (v) => setState(() => _ac2DeviceId = v),
                  fieldOptions: kAcPowerMetricFields,
                  selectedField: _ac2Field,
                  onFieldChanged: (v) => setState(() => _ac2Field = v),
                ),
                const SizedBox(height: 6),
                const SyncedReferenceChip(
                  title: 'Header Flow & Pressure',
                  sourceLabel: 'synced from Panel 1 · Top KPI',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Demand Side
          SettingsSectionCard(
            index: 3,
            title: 'Demand Side',
            description: 'Per-cast requirement + live data',
            statusLabel: '${_demandDeviceIds.where((id) => id != null).length} / ${kAcCastPoints.length} live',
            statusColor: t.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(flex: 2, child: Text('LOAD', style: _tableHeaderStyle(t))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: Text('REQ. PRESSURE', style: _tableHeaderStyle(t))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: Text('REQ. FLOW', style: _tableHeaderStyle(t))),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: Text('LIVE FLOW DEVICE', style: _tableHeaderStyle(t))),
                    const SizedBox(width: 24),
                  ],
                ),
                Divider(height: 14, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
                for (var i = 0; i < kAcCastPoints.length; i++)
                  DemandLoadRow(
                    label: kAcCastPoints[i].label,
                    reqPressureCtrl: _demandReqPressureCtrls[i],
                    reqFlowCtrl: _demandReqFlowCtrls[i],
                    devices: _devices,
                    deviceId: _demandDeviceIds[i],
                    onDeviceChanged: (v) => setState(() => _demandDeviceIds[i] = v),
                    fieldOptions: kAcFlowMetricFields,
                    selectedField: _demandFields[i],
                    onFieldChanged: (v) => setState(() => _demandFields[i] = v),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Requirement = each load\'s rated pressure/flow from its datasheet (manual). Live flow shows once a Device ID is mapped — otherwise the dashboard shows "No data".',
                  style: GoogleFonts.poppins(fontSize: 10, color: t.txtSubtle, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Trend charts
          SettingsSectionCard(
            index: 4,
            title: 'Bottom Panel — Trend Charts',
            description: 'SE trend + header-flow leakage parameters',
            statusLabel: 'Configured',
            statusColor: t.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SyncedReferenceChip(title: 'Total Power, Header Flow, Header Pressure', sourceLabel: 'synced from Panel 1 · Top KPI'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    _paramField(t, isLight, 'SE band low', _seBandLowCtrl, 'kW/(m³/min)', hint: 'e.g. 5.0'),
                    _paramField(t, isLight, 'SE band high', _seBandHighCtrl, 'kW/(m³/min)', hint: 'e.g. 6.0'),
                    _paramField(t, isLight, 'Leak min-flow', _minFlowCtrl, 'm³/min', hint: 'e.g. 15'),
                    _paramField(t, isLight, 'Night window start', _nightStartCtrl, 'HH:mm'),
                    _paramField(t, isLight, 'Night window end', _nightEndCtrl, 'HH:mm'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Efficiency
          SettingsSectionCard(
            index: 5,
            title: 'Right Panel — Compressor Efficiency',
            description: 'Role + benchmark judgement',
            statusLabel: _roleAssignmentAuto ? 'Auto' : 'Manual',
            statusColor: t.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role (Base-load / Peak) is judged against the SE band high set in Panel 4 by default — switch to Manual to force a role per compressor instead.',
                  style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _toggleButton(
                        t, isLight, 'Auto — by Specific Energy', _roleAssignmentAuto, () => setState(() => _roleAssignmentAuto = true)),
                    const SizedBox(width: 8),
                    _toggleButton(t, isLight, 'Manual', !_roleAssignmentAuto, () => setState(() => _roleAssignmentAuto = false)),
                  ],
                ),
                if (!_roleAssignmentAuto) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      _roleDropdown(t, isLight, 'AC1 role', _ac1RoleOverride, (v) => setState(() => _ac1RoleOverride = v)),
                      _roleDropdown(t, isLight, 'AC2 role', _ac2RoleOverride, (v) => setState(() => _ac2RoleOverride = v)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. System status
          SettingsSectionCard(
            index: 6,
            title: 'Right Panel — System Status',
            description: 'Status sources',
            statusLabel: '${[
                  _availabilityDeviceId,
                  _downtimeDeviceId,
                  _dewPointDeviceId
                ].where((v) => v != null).length + (_nextMaintenanceCtrl.text.trim().isNotEmpty ? 1 : 0)} / 4',
            statusColor: t.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leakage Status stays rule-computed (night window + min-flow from Panel 4) — System Status isn\'t backed by a device. The rest can be mapped below.',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSubtle, height: 1.5),
                ),
                const SizedBox(height: 10),
                DeviceFieldRow(
                  label: 'Availability',
                  formula: 'uptime %',
                  devices: _devices,
                  value: _availabilityDeviceId,
                  onChanged: (v) => setState(() => _availabilityDeviceId = v),
                ),
                DeviceFieldRow(
                  label: 'Total downtime',
                  formula: 'hours',
                  devices: _devices,
                  value: _downtimeDeviceId,
                  onChanged: (v) => setState(() => _downtimeDeviceId = v),
                ),
                DeviceFieldRow(
                  label: 'Dew point',
                  formula: '°C',
                  devices: _devices,
                  value: _dewPointDeviceId,
                  onChanged: (v) => setState(() => _dewPointDeviceId = v),
                ),
                const SizedBox(height: 6),
                _paramField(t, isLight, 'Next maintenance', _nextMaintenanceCtrl, 'free text', width: 260),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 7. AI Insight
          SettingsSectionCard(
            index: 7,
            title: 'Right Panel — AI Insight',
            description: 'Insight rules are managed in the database',
            statusLabel: 'DB-managed',
            statusColor: t.primary,
            child: Text(
              'Insight rules aren\'t edited here — keeping them in one place means the dashboard always shows exactly what the rule engine computes.',
              style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          _actionBar(t),
        ],
      ),
    );
  }

  Widget _toggleButton(FlutterFlowTheme t, bool isLight, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.primary : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1A2E)),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: selected ? t.primary : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48))),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : t.txtMuted,
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown(FlutterFlowTheme t, bool isLight, String label, String? value, ValueChanged<String?> onChanged) {
    const roles = ['Base-load', 'Peak'];
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: t.txtMuted)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                isDense: true,
                value: value != null && roles.contains(value) ? value : null,
                hint: Text('– select –', style: GoogleFonts.poppins(fontSize: 11, color: t.txtSubtle)),
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: t.txtMuted),
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                dropdownColor: isLight ? Colors.white : const Color(0xFF111827),
                items: [for (final r in roles) DropdownMenuItem(value: r, child: Text(r))],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle(FlutterFlowTheme t) =>
      GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: t.txtSubtle);

  Widget _paramField(FlutterFlowTheme t, bool isLight, String label, TextEditingController ctrl, String unit,
      {double width = 150, String? hint}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: t.txtMuted)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
            ),
            child: TextField(
              controller: ctrl,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(fontSize: 11.5, color: t.txtSubtle),
                suffixText: unit == 'free text' || unit == 'HH:mm' ? null : unit,
                suffixStyle: GoogleFonts.poppins(fontSize: 9.5, color: t.txtMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar(FlutterFlowTheme t) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : _reset,
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
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: t.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Save & Apply to Dashboard',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}
