import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/energy_data_logger_1/energy_data_logger_1_model.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

class EnergyDataLogger1View extends StatefulWidget {
  const EnergyDataLogger1View({super.key});

  @override
  State<EnergyDataLogger1View> createState() => _EnergyDataLogger1ViewState();
}

class _EnergyDataLogger1ViewState extends State<EnergyDataLogger1View> {
  // ── Facility-sourced device data ──────────────────────────────────────────
  List<FacilityData> _allMeters = [];
  List<String> _plants = ['All Plants'];
  List<String> _areas = ['All Areas'];
  List<FacilityData> _filteredDevices = [];

  String _selectedPlant = 'All Plants';
  String _selectedArea = 'All Areas';
  FacilityData? _selectedDevice;

  // ── Date range ────────────────────────────────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;

  // ── Table data ────────────────────────────────────────────────────────────
  List<dynamic> dataList = [];
  List<dynamic> originalData = [];
  int currentDataPage = 0;
  static const int _perPage = 100;

  bool _isLoading = false;
  bool _isLoadingFacilities = false;
  String lastUpdateTime = '';

  final ScrollController _scrollController = ScrollController();
  late EnergyDataLogger1Model _model;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EnergyDataLogger1Model());
    _loadFacilities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  // ── Facilities (device list) ──────────────────────────────────────────────

  Future<void> _loadFacilities() async {
    setState(() => _isLoadingFacilities = true);
    try {
      final all = await FacilityService.getFacilities();
      final meters = all
          .where((f) =>
              f.equipmentType.toLowerCase().contains('digital power meter'))
          .toList();

      final plantSet = <String>{'All Plants'};
      for (final f in meters) {
        if (f.plant.isNotEmpty && f.plant != '-') plantSet.add(f.plant);
      }

      if (mounted) {
        setState(() {
          _allMeters = meters;
          _plants = plantSet.toList();
          _filteredDevices = meters;
          _rebuildAreas();
          if (meters.isNotEmpty && _selectedDevice == null) {
            _selectedDevice = meters.first;
          }
          _isLoadingFacilities = false;
        });
        if (_selectedDevice != null) fetchData();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFacilities = false);
    }
  }

  void _rebuildAreas() {
    final source = _selectedPlant == 'All Plants'
        ? _allMeters
        : _allMeters.where((f) => f.plant == _selectedPlant).toList();

    final areaSet = <String>{'All Areas'};
    for (final f in source) {
      if (f.productionArea.isNotEmpty && f.productionArea != '-') {
        areaSet.add(f.productionArea);
      }
    }
    _areas = areaSet.toList();
    if (!_areas.contains(_selectedArea)) _selectedArea = 'All Areas';
    _rebuildFilteredDevices();
  }

  void _rebuildFilteredDevices() {
    _filteredDevices = _allMeters.where((f) {
      if (_selectedPlant != 'All Plants' && f.plant != _selectedPlant) {
        return false;
      }
      if (_selectedArea != 'All Areas' && f.productionArea != _selectedArea) {
        return false;
      }
      return true;
    }).toList();

    if (_selectedDevice != null &&
        !_filteredDevices.any((f) => f.meterId == _selectedDevice!.meterId)) {
      _selectedDevice =
          _filteredDevices.isNotEmpty ? _filteredDevices.first : null;
    }
  }

  // ── Data fetch ────────────────────────────────────────────────────────────

  String _fmtApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _fetchLimit() {
    final effFrom = _fromDate ?? _toDate;
    final effTo = _toDate ?? _fromDate;
    if (effFrom == null && effTo == null) return 500;
    final from = effFrom ?? effTo!;
    final to = effTo ?? effFrom!;
    final days = to.difference(from).inDays.abs() + 1;
    return (days * 96 + 100).clamp(500, 50000);
  }

  Future<void> fetchData() async {
    if (_selectedDevice == null) return;
    setState(() => _isLoading = true);
    try {
      final params = <String, String>{
        'device_id': _selectedDevice!.meterId,
        'limit': '${_fetchLimit()}',
      };
      final effFrom = _fromDate ?? _toDate;
      final effTo = _toDate ?? _fromDate;
      if (effFrom != null) params['from'] = _fmtApiDate(effFrom);
      if (effTo != null) params['to'] = _fmtApiDate(effTo);

      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/energyDetails/data-logger')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: AppConfig.headers);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> fetched = body is List ? body : [];
        final mapped = fetched.map((row) {
          final m = row as Map<String, dynamic>;
          return {
            'timestamp': m['timestamp'],
            'device': m['device_id'] ?? _selectedDevice!.meterId,
            'kwh': m['energy_consumption_kWh'],
            'power': m['power_kW'],
            'carbon': m['carbon_emission_kgCO2'],
            'energy': '',
          };
        }).toList();
        if (mounted) {
          setState(() {
            originalData = mapped;
            dataList = _applyDateFilter(mapped);
            currentDataPage = 0;
            lastUpdateTime =
                DateTime.now().toLocal().toString().substring(0, 19);
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _applyDateFilter(List<dynamic> source) {
    if (_fromDate == null && _toDate == null) return List.from(source);
    final effFrom = _fromDate ?? _toDate;
    final effTo = _toDate ?? _fromDate;
    return source.where((d) {
      final ts = DateTime.tryParse(d['timestamp']?.toString() ?? '');
      if (ts == null) return true;
      final tsDay = DateTime(ts.year, ts.month, ts.day);
      if (effFrom != null &&
          tsDay.isBefore(DateTime(effFrom.year, effFrom.month, effFrom.day))) {
        return false;
      }
      if (effTo != null &&
          tsDay.isAfter(DateTime(effTo.year, effTo.month, effTo.day))) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _extractDate(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _extractTime(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _fmt(String? v) {
    if (v == null || v == '0.000') return v == '0.000' ? '0' : '';
    return v;
  }

  // ── Table rows ────────────────────────────────────────────────────────────

  List<DataRow> _buildRows() {
    final page = dataList
        .skip(currentDataPage * _perPage)
        .take(_perPage)
        .toList();

    return page.map((d) {
      final ts = d['timestamp']?.toString() ?? '';
      return DataRow(cells: [
        DataCell(Text(_extractTime(ts),
            style: const TextStyle(
                color: Color(0xFF31ECFC), fontWeight: FontWeight.w600))),
        DataCell(Text(_extractDate(ts))),
        DataCell(Text(d['device']?.toString() ?? '')),
        DataCell(Text(_fmt(d['kwh']?.toString()))),
        DataCell(Text(_fmt(d['power']?.toString()))),
        DataCell(Text(_fmt(d['carbon']?.toString()))),
        DataCell(Text((d['energy'] ?? '').toString())),
      ]);
    }).toList();
  }

  // ── Filter bar helpers ────────────────────────────────────────────────────

  Widget _filterChip({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required FlutterFlowTheme t,
  }) {
    final isActive = value != items.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: t.secondaryText)),
        const SizedBox(width: 6),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? t.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? t.primary.withOpacity(0.5)
                  : t.primary.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              dropdownColor: t.secondaryBackground,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 15,
                  color: isActive ? t.primary : t.secondaryText),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? t.primary : t.primaryText),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: t.primaryText)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _deviceChip(FlutterFlowTheme t) {
    final isActive = _selectedDevice != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Device',
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: t.secondaryText)),
        const SizedBox(width: 6),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(
            color: isActive ? t.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? t.primary.withOpacity(0.5)
                  : t.primary.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDevice?.meterId,
              dropdownColor: t.secondaryBackground,
              isDense: true,
              isExpanded: true,
              hint: Text('Select Device',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: t.secondaryText)),
              icon: Icon(Icons.keyboard_arrow_down,
                  size: 15,
                  color: isActive ? t.primary : t.secondaryText),
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.primary),
              selectedItemBuilder: (_) => _filteredDevices
                  .map((f) => Text(
                        '${f.meterName} (${f.meterId})',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.primary),
                      ))
                  .toList(),
              items: _filteredDevices
                  .map((f) => DropdownMenuItem(
                        value: f.meterId,
                        child: Text(
                          '${f.meterName} (${f.meterId})',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: t.primaryText),
                        ),
                      ))
                  .toList(),
              onChanged: (id) {
                final device =
                    _filteredDevices.firstWhere((f) => f.meterId == id);
                setState(() {
                  _selectedDevice = device;
                  currentDataPage = 0;
                });
                fetchData();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
    required FlutterFlowTheme t,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final isSet = value != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: t.secondaryText)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2020),
              lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color:
                  isSet ? t.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSet
                    ? t.primary.withOpacity(0.5)
                    : t.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSet ? _fmtDate(value) : 'Any date',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          isSet ? FontWeight.w600 : FontWeight.w400,
                      color: isSet ? t.primary : t.secondaryText),
                ),
                const SizedBox(width: 5),
                Icon(Icons.calendar_today_outlined,
                    size: 13,
                    color: isSet ? t.primary : t.secondaryText),
                if (isSet) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onPicked(null),
                    child: Icon(Icons.close,
                        size: 12, color: t.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final txtPrimary = isLight ? t.primaryText : Colors.white;

    final totalPages =
        dataList.isNotEmpty ? (dataList.length / _perPage).ceil() : 0;
    if (currentDataPage >= totalPages && totalPages > 0) {
      currentDataPage = totalPages - 1;
    }

    final pageStart = dataList.isEmpty
        ? 0
        : currentDataPage * _perPage + 1;
    final pageEnd = dataList.isEmpty
        ? 0
        : (currentDataPage * _perPage + _perPage).clamp(0, dataList.length);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard / Energy Data Logger',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade400)),
                        const SizedBox(height: 2),
                        Text('Energy Data Logger',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: txtPrimary)),
                        Text(
                          'Digital Power Meters — sourced from Master Facilities',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: t.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Refresh
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: (_isLoading || _isLoadingFacilities)
                        ? null
                        : () {
                            _loadFacilities();
                          },
                    icon: (_isLoading || _isLoadingFacilities)
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: t.primary))
                        : Icon(Icons.refresh_rounded,
                            color: t.secondaryText, size: 20),
                  ),
                  const SizedBox(width: 4),
                  // Last update
                  if (lastUpdateTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Updated: $lastUpdateTime',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: t.secondaryText),
                      ),
                    ),
                ],
              ),
            ),

            // ── Filter bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _isLoadingFacilities
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: t.primary),
                        ),
                        const SizedBox(width: 10),
                        Text('Loading facilities…',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: t.secondaryText)),
                      ],
                    )
                  : Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _filterChip(
                          label: 'Plant',
                          value: _selectedPlant,
                          items: _plants,
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedPlant = v;
                              _rebuildAreas();
                              currentDataPage = 0;
                            });
                            if (_selectedDevice != null) fetchData();
                          },
                          t: t,
                        ),
                        _filterChip(
                          label: 'Production Area',
                          value: _selectedArea,
                          items: _areas,
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedArea = v;
                              _rebuildFilteredDevices();
                              currentDataPage = 0;
                            });
                            if (_selectedDevice != null) fetchData();
                          },
                          t: t,
                        ),
                        _deviceChip(t),
                        _datePicker(
                          label: 'From',
                          value: _fromDate,
                          onPicked: (d) {
                            setState(() {
                              _fromDate = d;
                              if (d != null &&
                                  _toDate != null &&
                                  _toDate!.isBefore(d)) {
                                _toDate = d;
                              }
                            });
                            fetchData();
                          },
                          t: t,
                          lastDate: _toDate ??
                              DateTime.now()
                                  .add(const Duration(days: 365)),
                        ),
                        _datePicker(
                          label: 'To',
                          value: _toDate,
                          onPicked: (d) {
                            setState(() => _toDate = d);
                            fetchData();
                          },
                          t: t,
                          firstDate: _fromDate ?? DateTime(2020),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            // ── Table ────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: t.primary, strokeWidth: 2),
                            const SizedBox(height: 12),
                            Text('Loading data…',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: t.secondaryText)),
                          ],
                        ),
                      )
                    : dataList.isEmpty
                        ? Center(
                            child: Text(
                              _selectedDevice == null
                                  ? 'No devices found. Check Master Facilities.'
                                  : 'No data for selected device and date range.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: t.secondaryText),
                            ),
                          )
                        : Column(
                            children: [
                              // Row count info
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      'Showing $pageStart–$pageEnd of ${dataList.length} entries',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: t.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              // Data table
                              Expanded(
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  controller: _scrollController,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    controller: _scrollController,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                          t.primary.withOpacity(0.08),
                                        ),
                                        border: TableBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          top: BorderSide(
                                              width: 0.5,
                                              color: t.primary
                                                  .withOpacity(0.3)),
                                          horizontalInside: BorderSide(
                                              width: 0.5,
                                              color: t.primary
                                                  .withOpacity(0.15)),
                                          verticalInside: BorderSide(
                                              width: 0.5,
                                              color: t.primary
                                                  .withOpacity(0.15)),
                                          bottom: BorderSide(
                                              width: 0.5,
                                              color: t.primary
                                                  .withOpacity(0.3)),
                                          left: BorderSide(
                                              width: 0.5,
                                              color: t.primary
                                                  .withOpacity(0.3)),
                                          right: BorderSide(
                                              width: 0.5,
                                              color: t.primary
                                                  .withOpacity(0.3)),
                                        ),
                                        headingTextStyle:
                                            GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: t.primary),
                                        dataTextStyle: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: t.primaryText),
                                        columns: const [
                                          DataColumn(label: Text('Time')),
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Device ID')),
                                          DataColumn(label: Text('kWh')),
                                          DataColumn(
                                              label: Text(
                                                  'Power\n(kWh/hr)')),
                                          DataColumn(
                                              label: Text(
                                                  'Carbon\n(kgCO₂e)')),
                                          DataColumn(
                                              label: Text('Energy Cost')),
                                        ],
                                        rows: _buildRows(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Pagination
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_perPage entries per page',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: t.secondaryText),
                                    ),
                                    Row(
                                      children: [
                                        _pageBtn(
                                          icon: Icons.chevron_left,
                                          enabled: currentDataPage > 0,
                                          onTap: () => setState(
                                              () => currentDataPage--),
                                          t: t,
                                        ),
                                        ...List.generate(
                                          totalPages.clamp(0, 10),
                                          (i) => _pageNumBtn(i,
                                              currentDataPage == i, t),
                                        ),
                                        _pageBtn(
                                          icon: Icons.chevron_right,
                                          enabled: currentDataPage <
                                              totalPages - 1,
                                          onTap: () => setState(
                                              () => currentDataPage++),
                                          t: t,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),

        // ── Loading overlay ──────────────────────────────────────────────────
        if (_isLoadingFacilities)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                    color: FlutterFlowTheme.of(context).primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required FlutterFlowTheme t,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: enabled
              ? t.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: enabled
                  ? t.primary.withOpacity(0.3)
                  : t.primary.withOpacity(0.1)),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? t.primary : t.secondaryText),
      ),
    );
  }

  Widget _pageNumBtn(int page, bool active, FlutterFlowTheme t) {
    return GestureDetector(
      onTap: () => setState(() => currentDataPage = page),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? t.primary : t.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? t.primary : t.primary.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? (Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.black)
                  : t.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
