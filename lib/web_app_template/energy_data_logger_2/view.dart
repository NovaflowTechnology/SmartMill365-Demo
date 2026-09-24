import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/components/data_table/data_table_widget.dart';
import '/components/data_table/table_column.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import 'package:smartmachine365/utils/report_exporter_saver_io.dart'
    if (dart.library.html) 'package:smartmachine365/utils/report_exporter_saver_web.dart' as csv_saver;

// ─── Column definitions ───────────────────────────────────────────────────────

// Columns map 1:1 to mySQL table Overall_hourly_energy_generation
// (filtered by device_id); Display Name & Status come from Master
// Facilities joined on Device ID.
const _columns = <TableColumn>[
  TableColumn('Date and Time', 'dateTime', 150, sortable: true),
  TableColumn('Display Name', 'meterName', 140, sortable: true),
  TableColumn('Device ID', 'meterId', 110),
  TableColumn('Status', 'status', 90),
  TableColumn('kWh', 'kwh', 80),
  TableColumn('kW', 'kw', 75),
  TableColumn('kVAR', 'kvar', 80),
  TableColumn('kVA', 'kva', 80),
  TableColumn('MD (kW)', 'mdKw', 90),
  TableColumn('PF', 'pf', 60),
  TableColumn('Hz', 'hz', 70),
  TableColumn('kgCO2e', 'kgco2e', 90),
];

const _exportHeaders = [
  'Date and Time',
  'Display Name',
  'Device ID',
  'Status',
  'kWh',
  'kW',
  'kVAR',
  'kVA',
  'MD (kW)',
  'PF',
  'Hz',
  'kgCO2e',
];
const _exportKeys = [
  'dateTime',
  'meterName',
  'meterId',
  'status',
  'kwh',
  'kw',
  'kvar',
  'kva',
  'mdKw',
  'pf',
  'hz',
  'kgco2e',
];

// ─── Constants ────────────────────────────────────────────────────────────────

const _md30Threshold = 1800;
const _pfTarget = 0.90;
const _kwhTonBaseline = 425;

const _cPower = Color(0xFF4A90D9);
const _cEnergy = Color(0xFF27AE60);
const _cEfficiency = Color(0xFFF0A500);
const _cAlarms = Color(0xFFE05C5C);

// ─── Stable dummy energy values per meter (based on meterId hash) ─────────────
// Fallback only — used when the MySQL hourly table has no rows for the client.

Map<String, dynamic> _dummyEnergy(String meterId) {
  int h = 5381;
  for (final c in meterId.codeUnits) {
    h = ((h << 5) + h + c) & 0x7FFFFFFF;
  }
  final phase = (h % 1000) / 1000.0 * 2 * math.pi;
  final kw = (600 + (math.sin(phase) * 500).abs()).round().clamp(150, 1850);
  final pf = double.parse((0.78 + 0.15 * ((math.sin(phase * 2) + 1) / 2)).toStringAsFixed(2));
  final kwh = kw;
  final md = (kw * (1.01 + 0.03 * math.sin(phase * 3))).round();
  // Derived from P & PF: S = P/PF, Q = sqrt(S² − P²)
  final kva = pf > 0 ? (kw / pf) : kw.toDouble();
  final kvar = math.sqrt(math.max(0, kva * kva - kw * kw));
  final hz = 49.9 + 0.2 * ((math.sin(phase * 4) + 1) / 2);
  final kgco2 = kwh * 0.585; // MY grid emission factor

  return {
    // All values shown with 2 decimal places (client request).
    'kwh': kwh.toStringAsFixed(2),
    'kw': kw.toStringAsFixed(2),
    'kvar': kvar.toStringAsFixed(2),
    'kva': kva.toStringAsFixed(2),
    'mdKw': md.toStringAsFixed(2),
    'pf': pf.toStringAsFixed(2),
    'hz': hz.toStringAsFixed(2),
    'kgco2e': kgco2.toStringAsFixed(2),
    // raw numbers used by KPI computations
    '_kwhNum': kwh.toDouble(),
    '_mdNum': md.toDouble(),
    '_pfNum': pf,
  };
}

// ─── View ─────────────────────────────────────────────────────────────────────

class EnergyDataLogger2View extends StatefulWidget {
  const EnergyDataLogger2View({super.key});

  @override
  State<EnergyDataLogger2View> createState() => _EnergyDataLogger2ViewState();
}

class _EnergyDataLogger2ViewState extends State<EnergyDataLogger2View> {
  // ── Filter state ──────────────────────────────────────────────────────────
  String _plant = 'All Plants';
  String _productionArea = 'All Areas';
  String _device = 'All Devices';
  DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<FacilityData> _allMeters = [];
  // Raw hourly readings from mySQL Overall_hourly_energy_generation.
  List<Map<String, dynamic>> _hourlyRows = [];
  List<String> _plants = ['All Plants'];
  List<String> _productionAreas = ['All Areas'];
  List<String> _devices = ['All Devices'];
  bool _isLoading = false;
  String? _error;
  bool _isExporting = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        FacilityService.getFacilities(),
        _fetchHourlyRows(),
      ]);
      final all = results[0] as List<FacilityData>;
      final hourly = results[1] as List<Map<String, dynamic>>;
      final meters = all.where((f) => f.equipmentType.toLowerCase().contains('digital power meter')).toList();

      final plantSet = <String>{'All Plants'};
      for (final f in meters) {
        if (f.plant.isNotEmpty && f.plant != '-') plantSet.add(f.plant);
      }

      if (mounted) {
        setState(() {
          _allMeters = meters;
          _hourlyRows = hourly;
          _plants = plantSet.toList();
          _isLoading = false;
          _rebuildAreas();
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
    }
  }

  /// When no date is picked, default to the last 7 days. Without this, the API
  /// returns only the newest ~500 rows — one snapshot per meter at the same hour.
  ({DateTime from, DateTime to, bool userFiltered}) _queryDates() {
    if (_fromDate != null || _toDate != null) {
      final from = _fromDate ?? _toDate!;
      final to = _toDate ?? _fromDate!;
      return (from: from, to: to, userFiltered: true);
    }
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 6));
    return (from: start, to: end, userFiltered: false);
  }

  // Size the API row window from the date span × filtered device count so a
  // multi-day range is not truncated to the newest ~100 rows per device.
  int _dataLoggerFetchLimit() {
    final q = _queryDates();
    final days = q.to.difference(q.from).inDays.abs() + 1;
    final deviceCount = _device != 'All Devices'
        ? 1
        : (_filtered.isNotEmpty ? _filtered.length : math.max(_allMeters.length, 1));
    return math.min(days * deviceCount * 96 + 100, 200000);
  }

  // Fetch hourly readings from the backend (mySQL table
  // Overall_hourly_energy_generation, filtered by device_id server-side).
  // Returns [] on any failure so the table falls back to dummy rows.
  Future<List<Map<String, dynamic>>> _fetchHourlyRows() async {
    try {
      final params = <String, String>{
        'limit': '${_dataLoggerFetchLimit()}',
      };
      String d(DateTime v) =>
          '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
      final q = _queryDates();
      params['from'] = d(q.from);
      params['to'] = d(q.to);
      // Oldest-first when the user picks a range so page 1 starts at From date,
      // not the last day in the range (DESC + all devices = only today visible).
      if (q.userFiltered) params['order'] = 'asc';

      // Solar page shows everything in Overall_hourly_energy_generation —
      // no device_id filter; the table has only generation meters anyway.
      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/energyDetails/data-logger-generation')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri, headers: AppConfig.headers);
      if (res.statusCode != 200) return [];
      final body = json.decode(res.body);
      if (body is! List) return [];
      return body.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _rebuildAreas() {
    final src = _plant == 'All Plants' ? _allMeters : _allMeters.where((f) => f.plant == _plant).toList();
    final areaSet = <String>{'All Areas'};
    for (final f in src) {
      if (f.productionArea.isNotEmpty && f.productionArea != '-') {
        areaSet.add(f.productionArea);
      }
    }
    _productionAreas = areaSet.toList();
    if (!_productionAreas.contains(_productionArea)) _productionArea = 'All Areas';
    _rebuildDevices();
  }

  void _rebuildDevices() {
    final src = _allMeters.where((f) {
      if (_plant != 'All Plants' && f.plant != _plant) return false;
      if (_productionArea != 'All Areas' && f.productionArea != _productionArea) return false;
      return true;
    }).toList();
    final deviceSet = <String>{'All Devices'};
    for (final f in src) {
      final name = f.meterName.isNotEmpty && f.meterName != '-' ? f.meterName : null;
      if (name != null) deviceSet.add(name);
    }
    _devices = deviceSet.toList();
    if (!_devices.contains(_device)) _device = 'All Devices';
  }

  // ── Filtered meters ───────────────────────────────────────────────────────

  List<FacilityData> get _filtered => _allMeters.where((f) {
        if (_plant != 'All Plants' && f.plant != _plant) return false;
        if (_productionArea != 'All Areas' && f.productionArea != _productionArea) return false;
        if (_device != 'All Devices' && f.meterName != _device) return false;
        return true;
      }).toList();

  // ── Table rows ─────────────────────────────────────────────────────────────
  // Real rows: mySQL Overall_hourly_energy_generation joined to Master
  // Facilities on device_id (Display Name & Status come from the facility).
  // Falls back to one dummy row per meter when the table has no data.

  static String _numStr(dynamic v, {int dp = 1}) {
    if (v == null) return '–';
    final n = v is num ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) return '–';
    return dp == 0 ? n.round().toString() : n.toStringAsFixed(dp);
  }

  static DateTime? _parseTs(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _fmtDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _passesTimeRange(DateTime ts) {
    if (_fromTime == null && _toTime == null) return true;
    final cur = ts.hour * 60 + ts.minute;
    final from = _fromTime != null ? _mins(_fromTime!) : null;
    final to = _toTime != null ? _mins(_toTime!) : null;

    if (from != null && to != null) {
      if (from <= to) {
        return cur >= from && cur <= to;
      }
      // Overnight window support (e.g. 22:00 → 06:00).
      return cur >= from || cur <= to;
    }
    if (from != null) return cur >= from;
    return cur <= to!;
  }

  List<TableRecord> get _tableRows {
    final facilities = _filtered;

    if (_hourlyRows.isNotEmpty) {
      // Join hourly readings → facility by Device ID (fallback: display name).
      final byId = <String, FacilityData>{};
      for (final f in facilities) {
        if (f.meterId.isNotEmpty) byId[f.meterId] = f;
        if (f.meterName.isNotEmpty) byId.putIfAbsent(f.meterName, () => f);
      }
      final rows = <TableRecord>[];
      final seen = <String>{};
      for (final r in _hourlyRows) {
        final deviceId = r['device_id']?.toString() ?? '';
        final dedupeKey = '$deviceId|${r['timestamp']}';
        if (seen.contains(dedupeKey)) continue;
        seen.add(dedupeKey);
        final f = byId[deviceId];
        // Show every generation-table row; only hide unregistered devices when
        // the user narrowed the plant/area/device dropdowns.
        final userFiltered = _plant != 'All Plants' ||
            _productionArea != 'All Areas' ||
            _device != 'All Devices';
        if (f == null && userFiltered) continue;
        final ts = _parseTs(r['timestamp']);
        // Only apply client-side date filter when the user picked dates.
        if (_fromDate != null || _toDate != null) {
          final effFrom = _fromDate ?? _toDate;
          final effTo = _toDate ?? _fromDate;
          if (ts != null) {
            final tsDay = DateTime(ts.year, ts.month, ts.day);
            if (effFrom != null &&
                tsDay.isBefore(DateTime(effFrom.year, effFrom.month, effFrom.day))) continue;
            if (effTo != null &&
                tsDay.isAfter(DateTime(effTo.year, effTo.month, effTo.day))) continue;
          }
        }
        if (ts != null && !_passesTimeRange(ts)) continue;
        // MySQL DECIMAL columns arrive as strings in JSON — parse either form.
        double numOf(dynamic v) =>
            v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
        final kwh = numOf(r['energy_generated_kWh'] ?? r['energy_consumption_kWh']);
        final md = numOf(r['max_demand_kW']);
        final pf = numOf(r['power_factor']);
        rows.add(<String, dynamic>{
          '_rowKey': '$deviceId|${r['timestamp']}',
          'dateTime': ts != null ? _fmtDateTime(ts) : '–',
          'meterName': (f != null && f.meterName.isNotEmpty) ? f.meterName : deviceId,
          'meterId': deviceId,
          'status': (f != null && f.status.isNotEmpty) ? f.status : 'Active',
          // All values shown with 2 decimal places (client request).
          'kwh': _numStr(r['energy_generated_kWh'] ?? r['energy_consumption_kWh'], dp: 2),
          'kw': _numStr(r['power_kW'], dp: 2),
          'kvar': _numStr(r['reactive_power_kVAR'], dp: 2),
          'kva': _numStr(r['apparent_power_kVA'], dp: 2),
          'mdKw': _numStr(r['max_demand_kW'], dp: 2),
          'pf': _numStr(r['power_factor'], dp: 2),
          'hz': _numStr(r['frequency_Hz'], dp: 2),
          'kgco2e': _numStr(r['carbon_emission_kgCO2'], dp: 2),
          '_kwhNum': kwh,
          '_mdNum': md,
          '_pfNum': pf,
          '_facilityId': f?.id ?? '',
          '_ts': ts,
        });
      }
      // User date range → oldest first; default window → newest first.
      final oldestFirst = _fromDate != null || _toDate != null;
      rows.sort((a, b) {
        final at = a['_ts'] as DateTime?;
        final bt = b['_ts'] as DateTime?;
        if (at == null || bt == null) return 0;
        return oldestFirst ? at.compareTo(bt) : bt.compareTo(at);
      });
      if (rows.isNotEmpty) return rows;
    }

    // Dummy fallback — one stable row per meter.
    return facilities.map((f) {
      final meterId = f.meterId.isNotEmpty ? f.meterId : f.meterName;
      final d = _dummyEnergy(meterId);
      final date = _parseDate(f.registrationDate) ?? _dummyDate(meterId);
      final effFrom = _fromDate ?? _toDate;
      final effTo = _toDate ?? _fromDate;
      final day = DateTime(date.year, date.month, date.day);
      if (effFrom != null &&
          day.isBefore(DateTime(effFrom.year, effFrom.month, effFrom.day))) return null;
      if (effTo != null &&
          day.isAfter(DateTime(effTo.year, effTo.month, effTo.day))) return null;
      if (!_passesTimeRange(date)) return null;
      return <String, dynamic>{
        '_rowKey': meterId,
        'dateTime': _fmtDateTime(date),
        'meterName': f.meterName.isNotEmpty ? f.meterName : '–',
        'meterId': f.meterId.isNotEmpty ? f.meterId : '–',
        'status': f.status.isNotEmpty ? f.status : 'Inactive',
        ...d,
        '_facilityId': f.id ?? '',
      };
    }).whereType<TableRecord>().toList();
  }

  /// Human-readable summary of what was actually loaded (not the filter range).
  String get _loadedDataSummary {
    final rows = _tableRows;
    if (rows.isEmpty) return 'No readings loaded';
    final days = <DateTime>{};
    final meters = <String>{};
    for (final r in rows) {
      meters.add(r['meterId']?.toString() ?? '');
      final ts = r['_ts'] as DateTime?;
      if (ts != null) days.add(DateTime(ts.year, ts.month, ts.day));
    }
    final sorted = days.toList()..sort();
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final range = sorted.isEmpty
        ? '—'
        : sorted.length == 1
            ? fmt(sorted.first)
            : '${fmt(sorted.first)} – ${fmt(sorted.last)}';
    final perMeter = meters.isEmpty ? 0 : (rows.length / meters.length).round();
    return '${rows.length} readings · $range · ${sorted.length} day(s) · ${meters.length} meter(s) · ~$perMeter rows/meter';
  }

  // ── KPI values from merged rows ───────────────────────────────────────────

  int get _totalKwh => _tableRows.fold(0.0, (double s, r) => s + (r['_kwhNum'] as double? ?? 0)).round();
  int get _peakMd30 => _tableRows.fold(0.0, (double s, r) => math.max(s, r['_mdNum'] as double? ?? 0)).round();
  double get _avgPF {
    final rows = _tableRows.where((r) => (r['_pfNum'] as double? ?? 0) > 0).toList();
    if (rows.isEmpty) return 0.91;
    return rows.fold(0.0, (s, r) => s + (r['_pfNum'] as double? ?? 0)) / rows.length;
  }

  // ── Custom cell builder ───────────────────────────────────────────────────

  Widget? _cellBuilder(String key, String value, TableRecord row) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final defText = isLight ? const Color(0xFF1F2937) : Colors.white70;

    switch (key) {
      case 'dateTime':
        if (value == '–') return null;
        return Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: t.primaryText));

      case 'meterId':
        return Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: t.primary));

      // PF — coloured against target
      case 'pf':
        final v = double.tryParse(value) ?? 0;
        final color = v >= _pfTarget
            ? _cEnergy
            : v >= 0.85
                ? _cEfficiency
                : _cAlarms;
        return Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color));

      // MD (kW) — coloured against threshold
      case 'mdKw':
        final v = double.tryParse(value) ?? 0;
        Color color;
        if (v > _md30Threshold) {
          color = _cAlarms;
        } else if (v > _md30Threshold * 0.88) {
          color = _cEfficiency;
        } else {
          color = defText;
        }
        return Text(value,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: v > _md30Threshold ? FontWeight.w700 : FontWeight.w400, color: color));

      // Plain numeric fields
      case 'kwh':
      case 'kw':
      case 'kvar':
      case 'kva':
      case 'hz':
      case 'kgco2e':
        return Text(value, style: GoogleFonts.poppins(fontSize: 12, color: defText));

      default:
        return null;
    }
  }

  // ── CSV export ────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final t = FlutterFlowTheme.of(context);
    try {
      String cell(String v) => '"${v.replaceAll('"', '""')}"';
      final rows = _tableRows;
      final lines = <String>[
        _exportHeaders.map(cell).join(','),
        ...rows.map((r) => _exportKeys.map((k) => cell((r[k] ?? '').toString())).join(',')),
      ];
      final bytes = utf8.encode('﻿${lines.join('\r\n')}');
      final now = DateTime.now();
      final ts = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      await csv_saver.saveExcelBytes(
        bytes: bytes,
        fileName: 'SolarGenerationData_$ts.csv',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exported ${rows.length} rows to CSV'),
        backgroundColor: t.success,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: t.error,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Row edit ──────────────────────────────────────────────────────────────

  void _onEditRow(TableRecord row) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditDialog(row: row, onSaved: _loadData),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(t, isLight),
              const SizedBox(height: 14),
              _buildFilterBar(t),
              const SizedBox(height: 12),
              _buildKpiRow(t, isLight),
              const SizedBox(height: 10),
              _buildLegendRow(t, isLight),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Error banner
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _cAlarms.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cAlarms.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: _cAlarms),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to load data: $_error', style: GoogleFonts.poppins(fontSize: 11, color: _cAlarms))),
                  TextButton(
                    onPressed: _loadData,
                    child: Text('Retry', style: GoogleFonts.poppins(fontSize: 11, color: t.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

        // Table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((_fromDate != null || _toDate != null) && _device == 'All Devices' && _tableRows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'All devices: each time slot lists every meter (~${_filtered.length} rows/slot). '
                      'Select one Device to browse the month hour-by-hour.  ·  $_loadedDataSummary',
                      style: GoogleFonts.poppins(fontSize: 10, color: t.secondaryText),
                    ),
                  ),
                Expanded(
                  child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: t.primary, strokeWidth: 2),
                        const SizedBox(height: 12),
                        Text('Loading meters…', style: GoogleFonts.poppins(fontSize: 12, color: t.secondaryText)),
                      ],
                    ),
                  )
                : DataTableWidget(
                    columns: _columns,
                    rows: _tableRows,
                    primaryKey: '_rowKey',
                    primaryColumnKey: 'meterName',
                    primarySubtitleKey: 'meterId',
                    primaryIcon: Icons.electric_meter_outlined,
                    sortKey: 'dateTime',
                    searchKeys: const ['meterName', 'meterId'],
                    perPage: 20,
                    showFilterDropdown: false,
                    showSelection: true,
                    cellBuilder: _cellBuilder,
                    onEdit: _onEditRow,
                    actions: const [],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Text(
            '$_loadedDataSummary'
            '  ·  MD30 threshold: ${_fmt(_md30Threshold)} kW  ·  PF target: ≥${_pfTarget.toStringAsFixed(2)}'
            '  ·  kWh/t baseline: $_kwhTonBaseline'
            '  ·  Source: Master Facilities / Edge Gateway'
            '  ·  Energy readings are real-time estimates',
            style: GoogleFonts.poppins(fontSize: 10, color: t.secondaryText),
          ),
        ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(FlutterFlowTheme t, bool isLight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard / Solar Generation Data', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400)),
              const SizedBox(height: 2),
              Text('Solar Generation Data',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isLight ? t.primaryText : Colors.white)),
              Text('Digital Power Meters — sourced from Master Facilities', style: GoogleFonts.poppins(fontSize: 11, color: t.secondaryText)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _loadData,
          icon: _isLoading
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: t.primary))
              : Icon(Icons.refresh_rounded, color: t.secondaryText, size: 20),
        ),
        const SizedBox(width: 4),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportCsv,
          icon: _isExporting
              ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download_outlined, size: 14),
          label: Text('Export CSV', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: t.primary,
            foregroundColor: isLight ? t.primaryBackground : Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── KPI cards (static/dummy) ──────────────────────────────────────────────

  Widget _buildKpiRow(FlutterFlowTheme t, bool isLight) {
    final peakVal = _peakMd30;
    final peakExceeded = peakVal > _md30Threshold;
    final avgPf = _avgPF;
    final pfOk = avgPf >= _pfTarget;

    return Row(
      children: [
        _KpiCard(label: 'TOTAL KWH', value: _fmt(_totalKwh), sub: '+4.2% vs yesterday', subColor: _cEnergy, isLight: isLight, t: t),
        const SizedBox(width: 8),
        _KpiCard(
            label: 'PEAK MD30',
            value: '${_fmt(peakVal)} kW',
            valueColor: peakExceeded ? _cAlarms : null,
            sub: 'Threshold ${_fmt(_md30Threshold)} kW',
            subColor: peakExceeded ? _cAlarms : null,
            isLight: isLight,
            t: t),
        const SizedBox(width: 8),
        _KpiCard(
            label: 'AVG POWER FACTOR',
            value: avgPf.toStringAsFixed(2),
            sub: pfOk ? 'Above 0.90 target' : 'Below 0.90 target',
            subColor: pfOk ? _cEnergy : _cAlarms,
            isLight: isLight,
            t: t),
        const SizedBox(width: 8),
        _KpiCard(label: 'KWH / TON', value: '412', sub: '-3.1% vs baseline', subColor: _cAlarms, isLight: isLight, t: t),
        const SizedBox(width: 8),
        _KpiCard(label: 'DATA QUALITY', value: '99.3%', sub: 'All meters healthy', subColor: _cEnergy, isLight: isLight, t: t),
      ],
    );
  }

  // ── Legend row ────────────────────────────────────────────────────────────

  Widget _buildLegendRow(FlutterFlowTheme t, bool isLight) {
    return Row(
      children: [
        _LegendChip(color: _cPower, label: 'Power parameters', isLight: isLight),
        const SizedBox(width: 8),
        _LegendChip(color: _cEnergy, label: 'Energy & MD', isLight: isLight),
        const SizedBox(width: 8),
        _LegendChip(color: _cEfficiency, label: 'Efficiency & operations', isLight: isLight),
        const SizedBox(width: 8),
        _LegendChip(color: _cAlarms, label: 'Alarms & status', isLight: isLight),
        const Spacer(),
        Text(
          'Red = threshold exceeded  ·  Amber = approaching  ·  Green = normal',
          style: GoogleFonts.poppins(fontSize: 10, color: t.secondaryText),
        ),
      ],
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(FlutterFlowTheme t) {
    final hasFilter = _plant != 'All Plants' ||
        _productionArea != 'All Areas' ||
        _device != 'All Devices' ||
        _fromDate != null ||
        _toDate != null ||
        _fromTime != null ||
        _toTime != null;
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterDropdown(
            label: 'Plant',
            value: _plant,
            items: _plants,
            t: t,
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _plant = v;
                  _rebuildAreas();
                });
                _loadData();
              }
            }),
        _FilterDropdown(
            label: 'Prod Area',
            value: _productionArea,
            items: _productionAreas,
            t: t,
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _productionArea = v;
                  _rebuildDevices();
                });
                _loadData();
              }
            }),
        _FilterDropdown(
            label: 'Device',
            value: _device,
            items: _devices,
            t: t,
            onChanged: (v) {
              if (v != null) {
                setState(() => _device = v);
                _loadData();
              }
            }),
        _DateBtn(
            label: 'From',
            value: _fromDate,
            t: t,
            lastDate: _toDate ?? DateTime.now().add(const Duration(days: 365)),
            onPicked: (d) {
              setState(() {
                _fromDate = d;
                if (d != null && _toDate != null && _toDate!.isBefore(d)) _toDate = d;
              });
              _loadData(); // refetch hourly rows for the new range
            }),
        _DateBtn(
            label: 'To',
            value: _toDate,
            t: t,
            firstDate: _fromDate ?? DateTime(2020),
            onPicked: (d) {
              setState(() => _toDate = d);
              _loadData();
            }),
        _TimeBtn(
            label: 'From Time',
            value: _fromTime,
            t: t,
            onPicked: (v) {
              setState(() {
                _fromTime = v;
                if (v != null && _toTime != null) {
                  // Keep both controls independent but linked to one filter result.
                  // No auto-swap; overnight range is supported in _passesTimeRange.
                }
              });
            }),
        _TimeBtn(
            label: 'To Time',
            value: _toTime,
            t: t,
            onPicked: (v) {
              setState(() => _toTime = v);
            }),
        if (hasFilter)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _plant = 'All Plants';
                _productionArea = 'All Areas';
                _device = 'All Devices';
                _fromDate = null;
                _toDate = null;
                _fromTime = null;
                _toTime = null;
                _rebuildAreas();
              });
              _loadData();
            },
            icon: Icon(Icons.clear_all, size: 15, color: t.secondaryText),
            label: Text('Clear', style: GoogleFonts.poppins(fontSize: 12, color: t.secondaryText)),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Stable dummy date spread across the past 90 days, seeded by meterId hash.
  static DateTime _dummyDate(String meterId) {
    int h = 5381;
    for (final c in meterId.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    return DateTime.now().subtract(Duration(days: h % 90));
  }

  static DateTime? _parseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '-' || s == '–') return null;
    // DD/MM/YY or DD/MM/YYYY
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        var y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          if (y < 100) y += 2000;
          return DateTime(y, m, d);
        }
      }
    }
    // ISO 8601 fallback: YYYY-MM-DD
    return DateTime.tryParse(s);
  }

  static String _fmt(int v) {
    if (v < 1000) return v.toString();
    final s = v.toString();
    final b = StringBuffer();
    final r = s.length % 3;
    if (r > 0) b.write(s.substring(0, r));
    for (var i = r; i < s.length; i += 3) {
      if (b.isNotEmpty) b.write(',');
      b.write(s.substring(i, i + 3));
    }
    return b.toString();
  }
}

// ─── KPI card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color? valueColor, subColor;
  final bool isLight;
  final FlutterFlowTheme t;

  const _KpiCard(
      {required this.label, required this.value, required this.sub, this.valueColor, this.subColor, required this.isLight, required this.t});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isLight ? const Color(0xFFE5EAF2) : const Color(0xFF1E2A3A)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
              const SizedBox(height: 4),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold, color: valueColor ?? (isLight ? const Color(0xFF111827) : Colors.white))),
              const SizedBox(height: 2),
              Text(sub,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 10, color: subColor ?? (isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)))),
            ],
          ),
        ),
      );
}

// ─── Legend chip ──────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLight;
  const _LegendChip({required this.color, required this.label, required this.isLight});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: isLight ? const Color(0xFF374151) : Colors.white70)),
          ],
        ),
      );
}

// ─── Filter dropdown ──────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final FlutterFlowTheme t;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({required this.label, required this.value, required this.items, required this.t, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isActive = items.isNotEmpty && items.indexOf(value) != 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: t.secondaryText)),
        const SizedBox(width: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? t.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? t.primary.withOpacity(0.4) : t.primary.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              dropdownColor: t.secondaryBackground,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: isActive ? t.primary : t.secondaryText),
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? t.primary : t.primaryText),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, style: GoogleFonts.poppins(fontSize: 13, color: t.primaryText)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Date picker button ───────────────────────────────────────────────────────

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime? value;
  final FlutterFlowTheme t;
  final ValueChanged<DateTime?> onPicked;
  final DateTime? firstDate, lastDate;

  const _DateBtn({required this.label, required this.value, required this.t, required this.onPicked, this.firstDate, this.lastDate});

  @override
  Widget build(BuildContext context) {
    final isSet = value != null;
    final str = isSet
        ? '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/${value!.year}'
        : 'Any date';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: t.secondaryText)),
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
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isSet ? t.primary.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSet ? t.primary.withOpacity(0.4) : t.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(str,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: isSet ? FontWeight.w600 : FontWeight.w400, color: isSet ? t.primary : t.secondaryText)),
                const SizedBox(width: 6),
                Icon(Icons.calendar_today_outlined, size: 13, color: isSet ? t.primary : t.secondaryText),
                if (isSet) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onPicked(null),
                    child: Icon(Icons.close, size: 12, color: t.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final FlutterFlowTheme t;
  final ValueChanged<TimeOfDay?> onPicked;

  const _TimeBtn({
    required this.label,
    required this.value,
    required this.t,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = value != null;
    final str = isSet
        ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
        : 'Any time';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: t.secondaryText)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isSet ? t.primary.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSet ? t.primary.withOpacity(0.4) : t.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(str,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: isSet ? FontWeight.w600 : FontWeight.w400, color: isSet ? t.primary : t.secondaryText)),
                const SizedBox(width: 6),
                Icon(Icons.schedule_outlined, size: 13, color: isSet ? t.primary : t.secondaryText),
                if (isSet) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onPicked(null),
                    child: Icon(Icons.close, size: 12, color: t.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Row edit dialog ──────────────────────────────────────────────────────────

class _EditDialog extends StatefulWidget {
  final TableRecord row;
  final VoidCallback onSaved;
  const _EditDialog({required this.row, required this.onSaved});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _timeCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;

  List<Map<String, dynamic>> _factories = [];
  List<Map<String, dynamic>> _areas = [];
  List<EquipmentItem> _equipments = [];

  String? _plant, _area, _equip, _grid;
  DateTime? _regDate;
  static const _gridOptions = ['-', 'Grid', 'Solar', 'Genset', 'Renewable', 'Other'];

  @override
  void initState() {
    super.initState();
    _plant = _s(widget.row['plant']);
    _area = _s(widget.row['productionArea']);
    _equip = _s(widget.row['equipmentNameId']);
    _grid = _s(widget.row['gridType']) ?? '-';
    _timeCtrl.text = _s(widget.row['registrationTime']) ?? '';
    _regDate = _EnergyDataLogger2ViewState._parseDate(widget.row['registrationDate']?.toString() ?? '');
    _loadDropdowns();
  }

  String? _s(dynamic v) {
    final s = v?.toString() ?? '';
    return (s.isEmpty || s == '–' || s == '-') ? null : s;
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final res = await Future.wait([
        FacilityService.getFactories(),
        FacilityService.getProductionAreas(),
        FacilityService.getEquipments(),
      ]);
      if (!mounted) return;
      setState(() {
        _factories = (res[0] as List<Map<String, dynamic>>).where((f) => f['id'] != '0').toList();
        _areas = (res[1] as List<Map<String, dynamic>>).where((a) => a['id'] != '0').toList();
        _equipments = res[2] as List<EquipmentItem>;
        _loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadError = e.toString();
        });
    }
  }

  T? _first<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  Future<bool> _submit() async {
    final id = widget.row['_facilityId']?.toString() ?? '';
    if (id.isEmpty) return false;
    try {
      final patch = <String, dynamic>{
        'plant': _plant ?? '-',
        'productionArea': _area ?? '-',
        'equipmentNameId': _equip ?? '-',
        'gridType': _grid ?? '-',
      };
      final time = _timeCtrl.text.trim();
      if (time.isNotEmpty) patch['registrationTime'] = time;
      if (_regDate != null) {
        patch['registrationDate'] = '${_regDate!.year}-${_regDate!.month.toString().padLeft(2, '0')}-${_regDate!.day.toString().padLeft(2, '0')}';
      }
      await FacilityService.patchFacility(id, patch);
      widget.onSaved();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final meterName = widget.row['meterName']?.toString() ?? '';
    final meterId = widget.row['meterId']?.toString() ?? '';

    final fill = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final border = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    final txt = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final hint = isLight ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    final ic = isLight ? const Color(0xFF94A3B8) : const Color(0xFF8B949E);

    Widget fLabel(String text) =>
        Text(text.toUpperCase(), style: TextStyle(color: hint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7));

    Widget ddW<T>({
      required String hintText,
      required T? value,
      required List<T> items,
      required String Function(T) lbl,
      required ValueChanged<T?> onChange,
    }) =>
        Container(
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              dropdownColor: isLight ? Colors.white : const Color(0xFF1E2432),
              icon: Icon(Icons.keyboard_arrow_down, size: 18, color: ic),
              hint: Text(hintText, style: TextStyle(color: hint, fontSize: 13)),
              style: TextStyle(color: txt, fontSize: 13),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(lbl(item), style: TextStyle(color: txt, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: onChange,
            ),
          ),
        );

    InputDecoration inputDeco(String h) => InputDecoration(
          hintText: h,
          hintStyle: TextStyle(color: hint, fontSize: 12),
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
          focusedBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF7A68FF), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    final factoryObj = _first(_factories, (x) => x['name'] == _plant);
    final areaObj = _first(_areas, (x) => x['name'] == _area);
    final equipObj = _first(_equipments, (x) => x.displayLabel == _equip);

    return CustomDialog(
      formKey: _formKey,
      icon: Icons.tune_outlined,
      title: 'Edit Meter Settings',
      subtitle: 'Editing: $meterName ($meterId)',
      submitLabel: 'SAVE CHANGES',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Facility Settings',
          subtitle: 'Update plant, production area, equipment and grid type.',
          children: _loading
              ? [const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7A68FF))))]
              : [
                  fLabel('Plant'),
                  const SizedBox(height: 6),
                  ddW<Map<String, dynamic>>(
                      hintText: 'Select plant…',
                      value: factoryObj,
                      items: _factories,
                      lbl: (x) => x['name']?.toString() ?? '',
                      onChange: (x) => setState(() => _plant = x?['name']?.toString())),
                  const SizedBox(height: 16),
                  fLabel('Production Area'),
                  const SizedBox(height: 6),
                  ddW<Map<String, dynamic>>(
                      hintText: 'Select area…',
                      value: areaObj,
                      items: _areas,
                      lbl: (x) => x['name']?.toString() ?? '',
                      onChange: (x) => setState(() => _area = x?['name']?.toString())),
                  const SizedBox(height: 16),
                  fLabel('Equipment Name / ID'),
                  const SizedBox(height: 6),
                  ddW<EquipmentItem>(
                      hintText: 'Select equipment…',
                      value: equipObj,
                      items: _equipments,
                      lbl: (x) => x.displayLabel,
                      onChange: (x) => setState(() => _equip = x?.displayLabel)),
                  const SizedBox(height: 16),
                  fLabel('Grid Type'),
                  const SizedBox(height: 6),
                  ddW<String>(
                      hintText: 'Select grid type…', value: _grid, items: _gridOptions, lbl: (x) => x, onChange: (x) => setState(() => _grid = x)),
                  const SizedBox(height: 16),
                  fLabel('Registration Time'),
                  const SizedBox(height: 6),
                  TextFormField(controller: _timeCtrl, style: TextStyle(color: txt, fontSize: 14), decoration: inputDeco('e.g. 08:30')),
                  const SizedBox(height: 16),
                  fLabel('Registration Date'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _regDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _regDate = picked);
                    },
                    child: Container(
                      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: ic),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _regDate != null
                                  ? '${_regDate!.day.toString().padLeft(2, '0')}/${_regDate!.month.toString().padLeft(2, '0')}/${_regDate!.year}'
                                  : 'Select date…',
                              style: TextStyle(color: _regDate != null ? txt : hint, fontSize: 13),
                            ),
                          ),
                          if (_regDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _regDate = null),
                              child: Icon(Icons.close, size: 14, color: ic),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 10),
                    Text(_loadError!, style: const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
                  ],
                ],
        ),
      ],
    );
  }
}
