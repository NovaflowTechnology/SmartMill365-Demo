import 'dart:async';
import 'package:smartmachine365/utils/leak_probe.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import 'package:smartmachine365/utils/report_exporter_saver_io.dart'
    if (dart.library.html) 'package:smartmachine365/utils/report_exporter_saver_web.dart' as csv_saver;
import '../../flutter_flow/nav/router_tracker.dart';
import 'device_energy_comparison_model.dart';
import 'device_energy_comparison_pdf_exporter.dart';
export 'device_energy_comparison_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceRow {
  final String deviceId;
  final String deviceName;
  final double energyKwh;
  final double maxDemandKw;
  final double avgPowerKw;
  final double carbonKg;
  final double costRm;
  final int runningHours;
  final double pfAvg;
  final bool isOnline;

  /// False when the backend returned no energy for this meter — e.g. a device
  /// ID that isn't actually reporting. Such rows render as N/A, not as zeros
  /// that could be mistaken for a real reading.
  final bool hasData;

  const _DeviceRow({
    required this.deviceId,
    required this.deviceName,
    this.hasData = true,
    required this.energyKwh,
    required this.maxDemandKw,
    required this.avgPowerKw,
    required this.carbonKg,
    required this.costRm,
    required this.runningHours,
    required this.pfAvg,
    required this.isOnline,
  });

  double metricValue(String metric) {
    switch (metric) {
      case 'Max Demand (kW)':  return maxDemandKw;
      case 'Carbon (kgCO₂e)': return carbonKg;
      case 'Cost (RM)':        return costRm;
      default:                 return energyKwh;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cyberpunk constants (matches energy_details)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kCyan   = Color(0xFF00D4FF);
const Color _kGreen  = Color(0xFF00E676);
const Color _kCardDk = Color(0xFF071A2E);

// ─────────────────────────────────────────────────────────────────────────────
// Corner Bracket Painter & Cyberpunk Card Container
// ─────────────────────────────────────────────────────────────────────────────
class _CyberpunkBracketPainter extends CustomPainter {
  final Color  color;
  final double armLength;

  const _CyberpunkBracketPainter({
    required this.color,
    required this.armLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W  = size.width;
    final H  = size.height;
    final L  = armLength;
    final sw = (W * 0.002).clamp(0.8, 1.2);
    for (final c in [
      const _BC(Offset(0, 0),  1,  1),
      _BC(Offset(W, 0), -1,  1),
      _BC(Offset(W, H), -1, -1),
      _BC(Offset(0, H),  1, -1),
    ]) {
      final path = Path()
        ..moveTo(c.o.dx + c.dx * L, c.o.dy)
        ..lineTo(c.o.dx, c.o.dy)
        ..lineTo(c.o.dx, c.o.dy + c.dy * L);
      canvas.drawPath(path, Paint()
        ..color       = color.withOpacity(0.40)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw * 3.5
        ..strokeCap   = StrokeCap.square
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawPath(path, Paint()
        ..color       = Colors.white.withOpacity(0.90)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw * 1.8
        ..strokeCap   = StrokeCap.square);
    }
  }

  @override
  bool shouldRepaint(_CyberpunkBracketPainter o) =>
      o.color != color || o.armLength != armLength;
}

class _BC {
  final Offset o;
  final double dx, dy;
  const _BC(this.o, this.dx, this.dy);
}

class _CyberpunkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _CyberpunkCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);
    final cyan    = isLight ? theme.primary : _kCyan;
    final cardBg  = isLight ? theme.secondaryBackground : _kCardDk;

    return Stack(
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cyan.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: cyan.withOpacity(0.06),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CyberpunkBracketPainter(
                color: _kCyan,
                armLength: 14.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class DeviceEnergyComparisonWidget extends StatefulWidget {
  const DeviceEnergyComparisonWidget({
    super.key,
    this.initialDeviceId,
  });

  final String? initialDeviceId;

  @override
  State<DeviceEnergyComparisonWidget> createState() =>
      _DeviceEnergyComparisonWidgetState();
}

class _DeviceEnergyComparisonWidgetState
    extends State<DeviceEnergyComparisonWidget> {
  late DeviceEnergyComparisonModel _model;

  // ── Report PDF capture key & status ───────────────────────────────────────
  final GlobalKey _reportBoundaryKey = GlobalKey();
  bool   _isGeneratingPdf    = false;
  String _generatingPdfStatus = '';

  // ── Facility / filter state ───────────────────────────────────────────────
  List<FacilityData> _allFacilities = [];
  String _plant    = 'All';
  String _lot      = 'All';
  String _block    = 'All';
  String _prodLine = 'All';
  Set<String> _enabledDeviceGroups = {};
  Set<String> _enabledDevices = {};

  // ── Period / Metric ────────────────────────────────────────────────────────
  String _period = 'Month';
  String _metric = 'Energy (kWh)';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // ── Show / Sort ────────────────────────────────────────────────────────────
  String _showFilter   = 'All Devices';
  bool   _sortHigh     = true;
  int?   _hoveredRow;
  String? _selectedDeviceId;

  // ── Data state ────────────────────────────────────────────────────────────
  List<_DeviceRow> _devices     = [];
  bool             _isLoading   = true;
  String           _lastUpdate  = '';
  Timer?           _timer;
  int              _loadToken   = 0; // Incremented on each load & dispose to prevent race conditions & memory leaks

  static const _periods  = ['Day', 'Week', 'Month', 'Year', 'Custom'];
  static const _metrics  = ['Energy (kWh)', 'Max Demand (kW)', 'Carbon (kgCO₂e)', 'Cost (RM)'];
  static const _showOpts = ['All Devices', 'Top 10', 'Top 25', 'Top 50'];

  // ── Facility field extractors ──────────────────────────────────────────────
  String _facilityPlant(FacilityData f) {
    if (f.plant.isNotEmpty && f.plant != '-') return f.plant;
    if (f.factory.isNotEmpty && f.factory != '-') return f.factory;
    return '';
  }

  String _facilityZone(FacilityData f) {
    if (f.zone.isNotEmpty && f.zone != '-') return f.zone;
    if (f.zoneName.isNotEmpty && f.zoneName != '-') return f.zoneName;
    return '';
  }

  String _facilityArea(FacilityData f) {
    if (f.productionArea.isNotEmpty && f.productionArea != '-') return f.productionArea;
    if (f.lineName.isNotEmpty && f.lineName != '-') return f.lineName;
    return '';
  }

  String _facilityEquipment(FacilityData f) {
    if (f.equipmentNameId.isNotEmpty && f.equipmentNameId != '-') return f.equipmentNameId;
    if (f.machineName.isNotEmpty && f.machineName != '-') return f.machineName;
    return '';
  }

  String _facilityDeviceGroup(FacilityData f) {
    final eqType = f.equipmentType.trim();
    if (eqType.isNotEmpty && eqType != '-') return eqType;
    final cat = f.impactCategory.trim();
    if (cat.isNotEmpty && cat != '-') return cat;
    final area = _facilityArea(f).trim();
    if (area.isNotEmpty && area != '-') return area;
    return 'General Equipment';
  }

  List<String> get _allDeviceGroups {
    final s = _allFacilities.map(_facilityDeviceGroup).where((g) => g.isNotEmpty).toSet().toList()..sort();
    if (s.isEmpty) return ['General Equipment'];
    return s;
  }

  // ── Derived filter options ─────────────────────────────────────────────────
  List<String> get _plantOpts {
    final s = _allFacilities.map(_facilityPlant).where((p) => p.isNotEmpty).toSet().toList()..sort();
    return ['All', ...s];
  }

  List<String> get _lotOpts {
    var f = _allFacilities.toList();
    if (_plant != 'All') f = f.where((x) => _facilityPlant(x) == _plant).toList();
    final s = f.map(_facilityZone).where((z) => z.isNotEmpty).toSet().toList()..sort();
    return ['All', ...s];
  }

  List<String> get _blockOpts {
    var f = _allFacilities.toList();
    if (_plant != 'All') f = f.where((x) => _facilityPlant(x) == _plant).toList();
    if (_lot != 'All')   f = f.where((x) => _facilityZone(x) == _lot).toList();
    final s = f.map(_facilityArea).where((a) => a.isNotEmpty).toSet().toList()..sort();
    return ['All', ...s];
  }

  List<String> get _lineOpts {
    var f = _allFacilities.toList();
    if (_plant != 'All') f = f.where((x) => _facilityPlant(x) == _plant).toList();
    if (_lot != 'All')   f = f.where((x) => _facilityZone(x) == _lot).toList();
    if (_block != 'All') f = f.where((x) => _facilityArea(x) == _block).toList();
    final s = f.map(_facilityEquipment).where((e) => e.isNotEmpty).toSet().toList()..sort();
    return ['All', ...s];
  }

  List<FacilityData> get _filteredFacilities {
    var f = _allFacilities.where((x) {
      final st = x.status.trim().toLowerCase();
      return (st.isEmpty || st == 'active') && x.meterId.isNotEmpty && x.meterId != '-';
    }).toList();
    if (_plant != 'All')    f = f.where((x) => _facilityPlant(x) == _plant).toList();
    if (_lot != 'All')      f = f.where((x) => _facilityZone(x) == _lot).toList();
    if (_block != 'All')    f = f.where((x) => _facilityArea(x) == _block).toList();
    if (_prodLine != 'All') f = f.where((x) => _facilityEquipment(x) == _prodLine).toList();
    if (_enabledDeviceGroups.isNotEmpty && _enabledDeviceGroups.length < _allDeviceGroups.length) {
      f = f.where((x) => _enabledDeviceGroups.contains(_facilityDeviceGroup(x))).toList();
    }
    if (_enabledDevices.isNotEmpty && _enabledDevices.length < _allFacilities.length) {
      f = f.where((x) => _enabledDevices.contains(x.meterId)).toList();
    }
    final seen = <String>{};
    return f.where((x) => seen.add(x.meterId)).toList();
  }

  String _deviceDisplayName(FacilityData f) {
    // Priority: machineName → meterName → equipmentNameId → meterId
    final machine = f.machineName.trim();
    if (machine.isNotEmpty && machine != '-') return machine;
    final meter = f.meterName.trim();
    if (meter.isNotEmpty && meter != '-' && meter != f.meterId) return meter;
    final equip = f.equipmentNameId.trim();
    if (equip.isNotEmpty && equip != '-') return equip;
    return f.meterId;
  }

  // ── Sorted/filtered display list ───────────────────────────────────────────
  List<_DeviceRow> get _sorted {
    final list = List<_DeviceRow>.from(_devices);
    list.sort((a, b) {
      final c = a.metricValue(_metric).compareTo(b.metricValue(_metric));
      return _sortHigh ? -c : c;
    });
    if (_showFilter == 'Top 10') return list.take(10).toList();
    if (_showFilter == 'Top 25') return list.take(25).toList();
    if (_showFilter == 'Top 50') return list.take(50).toList();
    return list;
  }

  // ── KPI aggregates ─────────────────────────────────────────────────────────
  double get _totalEnergy  => _devices.fold(0, (s, d) => s + d.energyKwh);
  double get _totalCarbon  => _devices.fold(0, (s, d) => s + d.carbonKg);
  double get _totalCost    => _devices.fold(0, (s, d) => s + d.costRm);
  double get _peakDemand   => _devices.isEmpty ? 0 : _devices.map((d) => d.maxDemandKw).reduce(math.max);

  // ── Date range formatting ──────────────────────────────────────────────────
  String get _dateRangeStr {
    if (_period == 'Custom') {
      final fmt = DateFormat('dd MMM yyyy');
      return '${fmt.format(_dateRange.start)} ~ ${fmt.format(_dateRange.end)}';
    }
    final now = DateTime.now();
    if (_period == 'Day') {
      return DateFormat('dd MMM yyyy').format(now);
    } else if (_period == 'Week') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      return '${DateFormat('dd MMM').format(start)} ~ ${DateFormat('dd MMM yyyy').format(now)}';
    } else if (_period == 'Year') {
      return DateFormat('yyyy').format(now);
    }
    final startOfMonth = DateTime(now.year, now.month, 1);
    return '${DateFormat('dd MMM yyyy').format(startOfMonth)} ~ ${DateFormat('dd MMM yyyy').format(now)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    LeakProbe.register('DeviceEnergyComparison.State');
    _model      = createModel(context, () => DeviceEnergyComparisonModel());
    _lastUpdate = _nowStr();
    // Pre-select device if navigated from another page with a deviceId.
    final initId = widget.initialDeviceId ?? '';
    if (initId.isNotEmpty) {
      _selectedDeviceId = initId;
      _enabledDevices = {initId};
    }
    _loadFacilitiesThenData();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _loadData());
    routeTracker.addListener(_onRoute);
  }

  @override
  void dispose() {
    LeakProbe.unregister('DeviceEnergyComparison.State');
    _loadToken++; // Invalidate any pending async callbacks to prevent memory leaks
    routeTracker.removeListener(_onRoute);
    _timer?.cancel();
    _timer = null;
    _model.dispose();
    super.dispose();
  }

  void _onRoute() {
    if (routeTracker.currentRoute == '/DeviceEnergyComparison') {
      _loadFacilitiesThenData();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  String _nowStr() => DateTime.now().toLocal().toString().substring(0, 19);

  // ─────────────────────────────────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadFacilitiesThenData() async {
    try {
      final facs = await FacilityService.getFacilities();
      if (!mounted) return;
      setState(() {
        _allFacilities = facs;
        if (_enabledDeviceGroups.isEmpty) {
          _enabledDeviceGroups = _allDeviceGroups.toSet();
        }
        // Only default to all devices if no specific device was pre-selected.
        if (_enabledDevices.isEmpty) {
          _enabledDevices = facs.map((x) => x.meterId).toSet();
        }
        if (!_plantOpts.contains(_plant)) _plant = 'All';
        if (!_lotOpts.contains(_lot)) _lot = 'All';
        if (!_blockOpts.contains(_block)) _block = 'All';
        if (!_lineOpts.contains(_prodLine)) _prodLine = 'All';
      });
    } catch (e) {
      debugPrint('DeviceEnergyComparison: facility load error: $e');
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    final currentToken = ++_loadToken;
    if (!mounted) return;
    setState(() { _isLoading = true; _lastUpdate = _nowStr(); });

    final facilities = _filteredFacilities;
    if (facilities.isEmpty) {
      if (mounted && currentToken == _loadToken) {
        setState(() { _devices = []; _isLoading = false; });
      }
      return;
    }

    // High-performance parallel fetch across all devices concurrently
    final results = await Future.wait(
      facilities.map((f) => _fetchDevice(f)),
    );

    if (!mounted || currentToken != _loadToken) return;

    setState(() {
      _devices    = results.whereType<_DeviceRow>().toList();
      _isLoading  = false;
      _lastUpdate = _nowStr();
    });
  }

  Future<_DeviceRow?> _fetchDevice(FacilityData f) async {
    try {
      final base = AppConfig.dataApiBaseSafe;
      final mid  = Uri.encodeComponent(f.meterId);

      // Execute both HTTP requests in parallel for 2x per-device speedup
      final futures = await Future.wait([
        http.get(Uri.parse('$base/energyDetails/total/$mid'), headers: AppConfig.headers)
            .timeout(const Duration(seconds: 8)),
        http.get(Uri.parse('$base/energyDetails/current/$mid'), headers: AppConfig.headers)
            .timeout(const Duration(seconds: 6))
            .catchError((_) => http.Response('{}', 404)),
      ]).catchError((_) => [http.Response('[]', 500), http.Response('{}', 500)]);

      final totalRes = futures[0];
      final curRes   = futures[1];

      double dailyEnergy   = 0;
      double monthlyEnergy = 0;
      double yearlyEnergy  = 0;
      double dailyCarbon   = 0;

      if (totalRes.statusCode == 200) {
        final body = jsonDecode(totalRes.body);
        if (body is List) {
          for (final entry in body) {
            if (entry is! Map) continue;
            final period = (entry['period'] ?? '').toString().toLowerCase();
            final e      = entry['total_energy'];
            final val    = (e is num) ? e.toDouble() : double.tryParse('$e') ?? 0;
            final v      = val.isFinite ? val.abs() : 0.0;

            if (period == 'daily') {
              dailyEnergy = v;
              final em = entry['daily_emission'];
              if (em is num && em.toDouble().isFinite && em.toDouble() > 0) {
                dailyCarbon = em.toDouble().abs();
              }
            } else if (period == 'monthly') {
              monthlyEnergy = v;
            } else if (period == 'yearly') {
              yearlyEnergy = v;
            }
          }
        }
      }

      // Calculate Period Multiplier & Target Energy
      double daysMult = 30.0;
      if (_period == 'Day') {
        daysMult = 1.0;
      } else if (_period == 'Week') {
        daysMult = 7.0;
      } else if (_period == 'Year') {
        daysMult = 365.0;
      } else if (_period == 'Custom') {
        final d = _dateRange.duration.inDays;
        daysMult = (d <= 0 ? 30 : d).toDouble();
      } else { // Month (default)
        daysMult = 30.0;
      }

      // ── Energy Selection Logic ────────────────────────────────────────────
      double energy = 0;
      if (_period == 'Day') {
        energy = dailyEnergy > 0 ? dailyEnergy : (monthlyEnergy > 0 ? monthlyEnergy / 30.0 : yearlyEnergy / 365.0);
      } else if (_period == 'Week') {
        energy = dailyEnergy > 0 ? dailyEnergy * 7.0 : (monthlyEnergy > 0 ? monthlyEnergy / 4.28 : yearlyEnergy / 52.0);
      } else if (_period == 'Year') {
        energy = yearlyEnergy > 0 ? yearlyEnergy : (monthlyEnergy > 0 ? monthlyEnergy * 12.0 : dailyEnergy * 365.0);
      } else if (_period == 'Custom') {
        if (dailyEnergy > 0) {
          energy = dailyEnergy * daysMult;
        } else if (monthlyEnergy > 0) {
          energy = (monthlyEnergy / 30.0) * daysMult;
        } else if (yearlyEnergy > 0) {
          energy = (yearlyEnergy / 365.0) * daysMult;
        }
      } else { // Month
        energy = monthlyEnergy > 0 ? monthlyEnergy : (dailyEnergy > 0 ? dailyEnergy * 30.0 : yearlyEnergy / 12.0);
      }

      // A meter that returned nothing from the API genuinely has no data — an
      // unregistered / mistyped device ID must read as N/A, never as a number.
      // (Previously a hash of the meter ID seeded plausible-looking figures,
      // which made bad IDs such as "lot12" appear to be reporting.)
      final hasData = energy > 0;

      // ── Max Demand from /current ─────────────────────────────────────────
      double maxDemand = 0, pfAvg = 0;
      if (curRes.statusCode == 200) {
        final cur = jsonDecode(curRes.body);
        if (cur is Map) {
          final md = cur['max_demand_kW'] ?? cur['max_demand'] ?? cur['maxDemand'] ?? 0;
          maxDemand = (md is num) ? md.toDouble() : double.tryParse('$md') ?? 0;
          maxDemand = maxDemand.isFinite ? maxDemand.abs() : 0;
          final pf = cur['power_factor'] ?? cur['pf_avg'] ?? cur['avg_pf'];
          if (pf is num && pf > 0) pfAvg = pf.toDouble().clamp(0.0, 1.0);
        }
      }

      const emissionFactor = 0.626; // kgCO2e/kWh (TNB Malaysia grid average)
      const tariff         = 0.45;  // RM/kWh (TNB Industrial tariff midpoint)

      final carbon     = dailyCarbon > 0 ? dailyCarbon * daysMult : energy * emissionFactor;
      final cost       = energy * tariff;
      // maxDemand can be 0 here, so clamp with a lower bound that never exceeds it.
      final avgPower   = maxDemand > 0 ? (maxDemand * 0.68).clamp(0.0, maxDemand) : 0.0;
      final runningHrs = avgPower > 0 ? (energy / avgPower).round().clamp(0, 744) : 0;
      final online     = f.onlineStatus.toLowerCase() == 'online' || f.onlineStatus.isEmpty;

      return _DeviceRow(
        deviceId:     f.meterId,
        deviceName:   _deviceDisplayName(f),
        hasData:      hasData,
        energyKwh:    double.parse(energy.toStringAsFixed(1)),
        maxDemandKw:  double.parse(maxDemand.toStringAsFixed(1)),
        avgPowerKw:   double.parse(avgPower.toStringAsFixed(1)),
        carbonKg:     double.parse(carbon.toStringAsFixed(1)),
        costRm:       double.parse(cost.toStringAsFixed(1)),
        runningHours: runningHrs,
        pfAvg:        double.parse(pfAvg.toStringAsFixed(2)),
        isOnline:     online,
      );
    } catch (e) {
      debugPrint('DeviceEnergyComparison: fetch error for ${f.meterId}: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Colour & Formatting helpers
  // ─────────────────────────────────────────────────────────────────────────
  Color _barColor(int index, int total) {
    if (total == 0) return _kCyan;
    final r = index / total;
    if (r < 0.20) return const Color(0xFFFF4C4C);
    if (r < 0.50) return const Color(0xFFFF9800);
    if (r < 0.80) return const Color(0xFFFFD600);
    return const Color(0xFF00E676);
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  String _fmtComma(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get _metricUnit {
    switch (_metric) {
      case 'Max Demand (kW)':  return 'kW';
      case 'Carbon (kgCO₂e)': return 'kgCO₂e';
      case 'Cost (RM)':        return 'RM';
      default:                 return 'kWh';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(context);
    final cyan    = isLight ? theme.primary : _kCyan;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset('assets/images/backgroundanimated.gif').image,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: RepaintBoundary(
              key: _reportBoundaryKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumb(),
                  const SizedBox(height: 4),
                  _buildTitle(isLight, theme, cyan),
                  const SizedBox(height: 14),
                  _buildFilterBar(isLight, theme, cyan),
                  const SizedBox(height: 12),
                  _buildPeriodMetricRow(isLight, theme, cyan),
                  const SizedBox(height: 14),
                  _buildKpiStrip(isLight, theme, cyan),
                  const SizedBox(height: 14),
                  _buildChartCard(isLight, theme, cyan),
                  const SizedBox(height: 14),
                  _buildTableCard(isLight, theme, cyan),
                  const SizedBox(height: 10),
                  _buildFooter(isLight, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Breadcrumb ─────────────────────────────────────────────────────────────
  Widget _buildBreadcrumb() => Text(
        'Dashboard/DeviceEnergyComparison',
        style: FlutterFlowTheme.of(context).titleLarge.override(
              fontFamily: 'Poppins',
              color: FlutterFlowTheme.of(context).txtSecondary,
              fontSize: 12,
              letterSpacing: 0,
              font: GoogleFonts.poppins(),
            ),
      );

  // ── Title ──────────────────────────────────────────────────────────────────
  Widget _buildTitle(bool isLight, FlutterFlowTheme theme, Color cyan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Energy Comparison',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                      font: GoogleFonts.poppins(),
                    ),
              ),
              Text(
                'Compare all devices energy performance in the selected period',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isLight ? theme.secondaryText : Colors.white54),
              ),
            ],
          ),
        ),
        // Last update + Refresh
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Last Update: $_lastUpdate',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isLight ? theme.secondaryText : Colors.white54),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _loadData,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.refresh_rounded,
                    size: 16,
                    color: isLight ? theme.primaryText : Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
            // Live badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGreen.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('Live',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _kGreen,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final activeFacsCount = _allFacilities.where((x) {
      final st = x.status.trim().toLowerCase();
      return (st.isEmpty || st == 'active') && x.meterId.isNotEmpty && x.meterId != '-';
    }).length;

    final hasActiveFilter = _plant != 'All' ||
        _lot != 'All' ||
        _block != 'All' ||
        _prodLine != 'All' ||
        (_enabledDeviceGroups.isNotEmpty && _enabledDeviceGroups.length < _allDeviceGroups.length) ||
        (_enabledDevices.isNotEmpty && _enabledDevices.length < activeFacsCount);

    return _CyberpunkCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _cyberDrop(context, 'Plant',           _plant,    _plantOpts, (v) {
            if (v != null) setState(() { _plant = v; _lot = 'All'; _block = 'All'; _prodLine = 'All'; });
            _loadData();
          }),
          _cyberDrop(context, 'Lot / Zone',      _lot,      _lotOpts,   (v) {
            if (v != null) setState(() { _lot = v; _block = 'All'; _prodLine = 'All'; });
            _loadData();
          }),
          _cyberDrop(context, 'Block / Area',    _block,    _blockOpts, (v) {
            if (v != null) setState(() { _block = v; _prodLine = 'All'; });
            _loadData();
          }),
          _cyberDrop(context, 'Production Line', _prodLine, _lineOpts,  (v) {
            if (v != null) setState(() => _prodLine = v);
            _loadData();
          }),
          _buildToggleDevicesFilter(isLight, theme, cyan),
          _deviceGroupFilterBtn(isLight, theme, cyan),
          if (hasActiveFilter)
            InkWell(
              onTap: () {
                setState(() {
                  _plant = 'All';
                  _lot = 'All';
                  _block = 'All';
                  _prodLine = 'All';
                  _enabledDeviceGroups = _allDeviceGroups.toSet();
                  _enabledDevices = _allFacilities.map((x) => x.meterId).toSet();
                });
                _loadData();
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_alt_off_rounded, color: Colors.redAccent, size: 15),
                    const SizedBox(width: 6),
                    Text('Clear Filters',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleDevicesFilter(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final activeFacs = _allFacilities.where((x) {
      final st = x.status.trim().toLowerCase();
      return (st.isEmpty || st == 'active') && x.meterId.isNotEmpty && x.meterId != '-';
    }).toList();

    final totalCount = activeFacs.length;
    final selectedCount = _enabledDevices.isEmpty ? totalCount : _enabledDevices.length;
    final isAllSelected = selectedCount == totalCount;
    final label = isAllSelected ? 'Devices: All' : 'Devices ($selectedCount/$totalCount)';
    final cardBg = isLight ? theme.secondaryBackground : _kCardDk;

    return PopupMenuButton<String>(
      tooltip: 'Toggle Devices',
      color: cardBg,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 360, maxHeight: 380),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cyan.withOpacity(0.5), width: 1.2),
      ),
      onSelected: (val) {
        setState(() {
          if (_enabledDevices.contains(val)) {
            _enabledDevices.remove(val);
          } else {
            _enabledDevices.add(val);
          }
        });
        _loadData();
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toggle Devices',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isLight ? theme.primaryText : Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _enabledDevices = activeFacs.map((x) => x.meterId).toSet();
                      });
                      _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text('All', style: GoogleFonts.poppins(fontSize: 11, color: cyan, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _enabledDevices.clear();
                      });
                      _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text('None', style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        if (activeFacs.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            child: Text('No devices available', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
          )
        else
          for (final f in activeFacs)
            CheckedPopupMenuItem<String>(
              value: f.meterId,
              checked: _enabledDevices.contains(f.meterId),
              child: Text(
                _deviceDisplayName(f).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isLight ? theme.primaryText : Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(
            color: !isAllSelected ? cyan : (isLight ? theme.alternate : cyan.withOpacity(0.5)),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: cyan.withOpacity(0.08), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 16, color: cyan),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLight ? theme.primaryText : Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, color: cyan, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _deviceGroupFilterBtn(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final allGroups = _allDeviceGroups;
    final selectedCount = _enabledDeviceGroups.length;
    final isAllSelected = selectedCount == allGroups.length;
    final label = isAllSelected ? 'Device Groups (All)' : 'Device Groups ($selectedCount/${allGroups.length})';

    return InkWell(
      onTap: () => _showDeviceGroupDialog(isLight, theme, cyan),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isLight ? theme.secondaryBackground : _kCardDk,
          border: Border.all(
            color: !isAllSelected ? cyan : (isLight ? theme.alternate : cyan.withOpacity(0.5)),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: cyan.withOpacity(0.08), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 16, color: cyan),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLight ? theme.primaryText : Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, color: cyan, size: 18),
          ],
        ),
      ),
    );
  }

  void _showDeviceGroupDialog(bool isLight, FlutterFlowTheme theme, Color cyan) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allGroups = _allDeviceGroups;
            return AlertDialog(
              backgroundColor: isLight ? theme.secondaryBackground : _kCardDk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cyan.withOpacity(0.4)),
              ),
              title: Row(
                children: [
                  Icon(Icons.tune_rounded, color: cyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Device Group Enable / Disable',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isLight ? theme.primaryText : Colors.white,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _enabledDeviceGroups = allGroups.toSet();
                            });
                            setState(() {});
                            _loadData();
                          },
                          child: Text(
                            'Enable All',
                            style: GoogleFonts.poppins(color: cyan, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _enabledDeviceGroups.clear();
                            });
                            setState(() {});
                            _loadData();
                          },
                          child: Text(
                            'Disable All',
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: SingleChildScrollView(
                        child: Column(
                          children: allGroups.map((group) {
                            final checked = _enabledDeviceGroups.contains(group);
                            return CheckboxListTile(
                              dense: true,
                              activeColor: cyan,
                              checkColor: isLight ? Colors.white : Colors.black,
                              title: Text(
                                group,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isLight ? theme.primaryText : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: checked,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    _enabledDeviceGroups.add(group);
                                  } else {
                                    _enabledDeviceGroups.remove(group);
                                  }
                                });
                                setState(() {});
                                _loadData();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(color: cyan, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Period + Metric row ────────────────────────────────────────────────────
  Widget _buildPeriodMetricRow(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final cardBg = isLight ? theme.secondaryBackground : _kCardDk;

    return _CyberpunkCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cyan.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _periods.map((p) {
                final sel = p == _period;
                return GestureDetector(
                  onTap: () async {
                    if (p == 'Custom') {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: cyan,
                              onPrimary: Colors.black,
                              surface: _kCardDk,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateRange = picked;
                          _period    = 'Custom';
                        });
                        _loadData();
                      }
                    } else {
                      setState(() => _period = p);
                      _loadData();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? cyan : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(p,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? (isLight ? Colors.white : _kCardDk)
                                : (isLight ? theme.secondaryText : Colors.white54))),
                  ),
                );
              }).toList(),
            ),
          ),
          // Date Range Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cyan.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, size: 14, color: cyan),
                const SizedBox(width: 8),
                Text(
                  _dateRangeStr,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLight ? theme.primaryText : Colors.white),
                ),
              ],
            ),
          ),
          // Metric toggles
          ...(_metrics.map((m) {
            final sel = m == _metric;
            return GestureDetector(
              onTap: () => setState(() => _metric = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? cyan.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: sel ? cyan : cyan.withOpacity(0.25), width: 1.2),
                ),
                child: Text(m,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? cyan : (isLight ? theme.secondaryText : Colors.white54))),
              ),
            );
          })),
        ],
      ),
    );
  }

  // ── KPI strip ──────────────────────────────────────────────────────────────
  Widget _buildKpiStrip(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final pri = isLight ? theme.primaryText : Colors.white;
    final sec = isLight ? theme.secondaryText : Colors.white54;

    final totalEnergyBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Total Energy (kWh)',
            style: GoogleFonts.poppins(fontSize: 11, color: sec, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(_fmtComma(_totalEnergy),
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: pri)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.redAccent),
          Text('vs prev period',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600)),
        ]),
      ],
    );

    final iconButtons = Row(mainAxisSize: MainAxisSize.min, children: [
      _iconBtn(Icons.info_outline_rounded, sec),
      _iconBtn(Icons.bar_chart_rounded, sec),
      _iconBtn(Icons.open_in_full_rounded, sec),
    ]);

    return _CyberpunkCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: _isLoading
          ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kCyan)))
          : LayoutBuilder(builder: (context, constraints) {
              // Below this, 5 Expanded columns squeeze into unreadable
              // slivers — wrap the secondary tiles instead of forcing them
              // to share the row with the headline figure.
              if (constraints.maxWidth < kBreakpointMedium) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: totalEnergyBlock),
                        iconButtons,
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        SizedBox(width: 130, child: _kpiTile('Devices', '${_devices.length}', null, pri, sec)),
                        SizedBox(width: 130, child: _kpiTile('Max Demand', '${_fmt(_peakDemand)} kW', null, pri, sec)),
                        SizedBox(width: 130, child: _kpiTile('Carbon Emission', '${_fmtComma(_totalCarbon)} kgCO₂e', Icons.eco_rounded, pri, sec)),
                        SizedBox(width: 130, child: _kpiTile('Est. Cost', 'RM ${_fmtComma(_totalCost)}', Icons.attach_money_rounded, pri, sec)),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: totalEnergyBlock),
                  _div(),
                  Expanded(child: _kpiTile('Devices', '${_devices.length}', null, pri, sec)),
                  _div(),
                  Expanded(child: _kpiTile('Max Demand', '${_fmt(_peakDemand)} kW', null, pri, sec)),
                  _div(),
                  Expanded(child: _kpiTile('Carbon Emission', '${_fmtComma(_totalCarbon)} kgCO₂e', Icons.eco_rounded, pri, sec)),
                  _div(),
                  Expanded(child: _kpiTile('Est. Cost', 'RM ${_fmtComma(_totalCost)}', Icons.attach_money_rounded, pri, sec)),
                  iconButtons,
                ],
              );
            }),
    );
  }

  Widget _div() => Container(
        width: 1, height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: _kCyan.withOpacity(0.12),
      );

  Widget _kpiTile(String label, String value, IconData? icon, Color pri, Color sec) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Icon(icon, size: 12, color: _kCyan), const SizedBox(width: 4)],
          Flexible(child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: sec, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: pri)),
      ]);

  Widget _iconBtn(IconData i, Color c) => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(padding: const EdgeInsets.all(4), child: Icon(i, size: 15, color: c)),
      );

  // ── Chart card ─────────────────────────────────────────────────────────────
  Widget _buildChartCard(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final devices = _sorted;
    final pri     = isLight ? theme.primaryText : Colors.white;
    final sec     = isLight ? theme.secondaryText : Colors.white54;
    final maxVal  = devices.isEmpty ? 1.0 : devices.map((d) => d.metricValue(_metric)).reduce(math.max);
    final avg     = devices.isEmpty ? 0.0 : devices.fold<double>(0, (s, d) => s + d.metricValue(_metric)) / devices.length;

    return _CyberpunkCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title/subtitle always sit on their own line, with the filter
          // toolbar always on a row underneath — same shape at every screen
          // width instead of reflowing between "beside the title" and
          // "wrapped below" depending on how much room the title text needs.
          Text('Energy Usage Comparison ($_metricUnit)',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: pri)),
          Text('Ranked device consumption for $_period period  ·  Click bar to select',
              style: GoogleFonts.poppins(fontSize: 11, color: sec)),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniDrop(isLight, theme, '$_showFilter (${devices.length})', _showOpts, (v) {
                if (v != null) setState(() => _showFilter = v);
              }),
              _miniDrop(isLight, theme,
                  _sortHigh ? 'Highest to Lowest' : 'Lowest to Highest',
                  ['Highest to Lowest', 'Lowest to Highest'], (v) {
                if (v != null) setState(() => _sortHigh = v == 'Highest to Lowest');
              }),
              _downloadPdfBtn(cyan),
              _exportBtn(cyan),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 310,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kCyan))
                : devices.isEmpty
                    ? Center(child: Text('No data for selected filters', style: GoogleFonts.poppins(color: sec)))
                    : _BarChart(
                        devices: devices,
                        maxVal: maxVal,
                        avgVal: avg,
                        metric: _metric,
                        selectedDeviceId: _selectedDeviceId,
                        onSelectDevice: (id) {
                          setState(() {
                            _selectedDeviceId = (_selectedDeviceId == id) ? null : id;
                          });
                        },
                        barColorFn: _barColor,
                        fmtFn: _fmt,
                        txtPri: pri,
                        txtSec: sec,
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReportPdf() async {
    setState(() {
      _isGeneratingPdf = true;
      _generatingPdfStatus = 'Building PDF…';
    });
    try {
      final scopeList = <String>[];
      if (_plant != 'All') scopeList.add('Plant: $_plant');
      if (_lot != 'All') scopeList.add('Lot: $_lot');
      if (_block != 'All') scopeList.add('Block: $_block');
      if (_prodLine != 'All') scopeList.add('Line: $_prodLine');
      if (_enabledDeviceGroups.isNotEmpty && _enabledDeviceGroups.length < _allDeviceGroups.length) {
        scopeList.add('Groups: ${_enabledDeviceGroups.length}/${_allDeviceGroups.length}');
      }
      final scopeStr = scopeList.isEmpty ? 'All Facilities Scope' : scopeList.join(' | ');

      final pdfRows = _sorted.map((d) => DevicePdfRow(
        deviceId: d.deviceId,
        deviceName: d.deviceName,
        energyKwh: d.energyKwh,
        maxDemandKw: d.maxDemandKw,
        carbonKg: d.carbonKg,
        costRm: d.costRm,
        pfAvg: d.pfAvg,
        isOnline: d.isOnline,
      )).toList();

      await DeviceEnergyComparisonPdfExporter.exportPdf(
        scopeLabel: scopeStr,
        periodLabel: _period,
        dateRangeLabel: _dateRangeStr,
        metricLabel: _metric,
        totalEnergy: _totalEnergy,
        peakDemand: _peakDemand,
        totalCarbon: _totalCarbon,
        totalCost: _totalCost,
        devices: pdfRows,
      );
    } catch (e) {
      debugPrint('DeviceEnergyComparison: error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate PDF report.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _generatingPdfStatus = '';
        });
      }
    }
  }

  Widget _downloadPdfBtn(Color cyan) => InkWell(
        onTap: _isGeneratingPdf ? null : _downloadReportPdf,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cyan.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isGeneratingPdf
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cyan),
                    )
                  : Icon(Icons.picture_as_pdf_outlined, size: 14, color: cyan),
              const SizedBox(width: 6),
              Text(
                _isGeneratingPdf ? _generatingPdfStatus : 'Download Report',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cyan,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _exportBtn(Color cyan) => InkWell(
        onTap: _exportCsv,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cyan.withOpacity(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.file_download_outlined, size: 14, color: cyan),
            const SizedBox(width: 6),
            Text('Export CSV', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: cyan)),
          ]),
        ),
      );

  // ── Table card ─────────────────────────────────────────────────────────────
  Widget _buildTableCard(bool isLight, FlutterFlowTheme theme, Color cyan) {
    final devices  = _sorted;
    final pri      = isLight ? theme.primaryText : Colors.white;
    final sec      = isLight ? theme.secondaryText : Colors.white54;
    final hdrBg    = isLight ? const Color(0xFFF0F4F8) : const Color(0xFF040E1A);
    final altRowBg = isLight ? const Color(0xFFF7FAFB) : const Color(0xFF071828);
    final maxEnergy = devices.isEmpty ? 1.0 : devices.map((d) => d.energyKwh).reduce(math.max).clamp(1.0, double.infinity);

    // Column widths
    const double wRank   = 44;
    const double wDevice = 200;
    const double wEnergy = 130;
    const double wMd     = 110;
    const double wCarbon = 110;
    const double wCost   = 110;
    const double wPf     = 70;
    const double wStatus = 90;
    const double wAction = 60;

    Widget header() => Container(
      decoration: BoxDecoration(
        color: hdrBg,
        border: Border(bottom: BorderSide(color: _kCyan.withOpacity(0.25), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _th('No.',    wRank,   _kCyan.withOpacity(0.7)),
        _th('Device', wDevice, sec),
        _th('Energy (kWh)', wEnergy, sec),
        _th('Max Demand (kW)', wMd, sec),
        _th('Carbon (kgCO₂e)', wCarbon, sec),
        _th('Cost (RM)', wCost, sec),
        _th('PF', wPf, sec),
        _th('Status', wStatus, sec),
        _th('Detail', wAction, sec),
      ]),
    );

    Widget dataRow(int i, _DeviceRow d) {
      final isHov  = _hoveredRow == i;
      final isSel  = _selectedDeviceId == d.deviceId;
      final barRatio = maxEnergy > 0 ? (d.energyKwh / maxEnergy).clamp(0.0, 1.0) : 0.0;
      final barClr = _barColor(i, devices.length);
      final isTop3 = i < 3;
      final rankColors = [Colors.redAccent, Colors.orange, Colors.amber];

      return MouseRegion(
        onEnter: (_) => setState(() => _hoveredRow = i),
        onExit:  (_) => setState(() => _hoveredRow = null),
        child: GestureDetector(
          onTap: () => setState(() => _selectedDeviceId = (isSel ? null : d.deviceId)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: isSel
                  ? _kCyan.withOpacity(0.10)
                  : isHov
                      ? cyan.withOpacity(0.07)
                      : i.isOdd ? altRowBg : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSel ? _kCyan : (isHov ? cyan.withOpacity(0.5) : Colors.transparent),
                  width: 3,
                ),
                bottom: BorderSide(color: (isLight ? Colors.black : Colors.white).withOpacity(0.04)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Rank
              SizedBox(width: wRank, child: isTop3
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rankColors[i].withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('#${i + 1}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                    )
                  : Text('${i + 1}', style: GoogleFonts.poppins(fontSize: 12, color: sec))),

              // Device Display Name (Top) + Device ID (Bottom)
              SizedBox(
                width: wDevice,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLight ? theme.primaryText : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    d.deviceId,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _kCyan,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),

              // Energy + mini bar
              SizedBox(
                width: wEnergy,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.hasData ? _fmtComma(d.energyKwh) : 'N/A',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700,
                          color: d.hasData ? barClr : sec)),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 3,
                      child: Row(children: [
                        Flexible(
                          flex: (barRatio * 100).round().clamp(1, 100),
                          child: Container(color: barClr),
                        ),
                        Flexible(
                          flex: ((1 - barRatio) * 100).round().clamp(0, 99),
                          child: Container(color: barClr.withOpacity(0.12)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),

              // Max Demand
              SizedBox(width: wMd,
                  child: _dataCell(d.maxDemandKw > 0
                      ? '${d.maxDemandKw.toStringAsFixed(1)} kW'
                      : '—', pri, sec,
                      d.maxDemandKw > 0 ? Colors.orange : null)),

              // Carbon
              SizedBox(width: wCarbon,
                  child: _dataCell(d.hasData ? _fmtComma(d.carbonKg) : 'N/A', pri, sec,
                      d.hasData ? _kGreen.withOpacity(0.85) : null)),

              // Cost
              SizedBox(width: wCost,
                  child: _dataCell(d.hasData ? 'RM ${_fmtComma(d.costRm)}' : 'N/A', pri, sec,
                      d.hasData ? Colors.amber : null)),

              // PF
              SizedBox(width: wPf,
                  child: d.pfAvg > 0 ? _pfBadge(d.pfAvg, sec) : _dataCell('N/A', pri, sec, null)),

              // Status
              SizedBox(
                width: wStatus,
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: d.isOnline ? _kGreen : Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: (d.isOnline ? _kGreen : Colors.redAccent).withOpacity(0.7),
                        blurRadius: 5,
                      )],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(d.isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: d.isOnline ? _kGreen : Colors.redAccent)),
                ]),
              ),

              // Action
              SizedBox(
                width: wAction,
                child: InkWell(
                  onTap: () => context.pushNamed('EnergyDetails'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kCyan.withOpacity(0.35)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.show_chart_rounded, size: 12, color: _kCyan),
                      const SizedBox(width: 4),
                      Text('View', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _kCyan)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return _CyberpunkCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _isLoading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kCyan)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table header
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: header(),
                  ),
                  // Table rows
                  if (devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Column(children: [
                        Icon(Icons.devices_other_outlined, size: 36, color: sec),
                        const SizedBox(height: 10),
                        Text('No devices match the current filters',
                            style: GoogleFonts.poppins(fontSize: 13, color: sec)),
                      ])),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(devices.length, (i) => dataRow(i, devices[i])),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _dataCell(String val, Color pri, Color sec, Color? accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent ?? pri)),
        ],
      );

  Widget _pfBadge(double pf, Color sec) {
    final Color c = pf >= 0.95
        ? _kGreen
        : pf >= 0.85
            ? Colors.orange
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(pf.toStringAsFixed(2),
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isLight, FlutterFlowTheme theme) =>
      Text('* All times are in Malaysia Time (MYT, UTC+8)',
          style: GoogleFonts.poppins(
              fontSize: 11,
              color: isLight ? theme.secondaryText : Colors.white38));

  // ── Table helpers ──────────────────────────────────────────────────────────
  Widget _th(String t, double w, Color c) => SizedBox(
        width: w,
        child: Text(t, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      );

  // ── Cyberpunk dropdown — identical to energy_details ──────────────────────
  Widget _cyberDrop(BuildContext ctx, String hint, String value, List<String> opts,
      ValueChanged<String?> onChanged) {
    final isLight = Theme.of(ctx).brightness == Brightness.light;
    final theme   = FlutterFlowTheme.of(ctx);
    final cyan    = isLight ? theme.primary : _kCyan;
    final cardBg  = isLight ? theme.secondaryBackground : _kCardDk;
    final safe    = opts.contains(value) ? value : null;
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 210),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: isLight ? theme.alternate : cyan.withOpacity(0.5), width: 1.2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: cyan.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 3,
          decoration: BoxDecoration(
            color: cyan,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
            boxShadow: [BoxShadow(color: cyan.withOpacity(0.8), blurRadius: 6)],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safe,
                isExpanded: true,
                dropdownColor: cardBg,
                menuMaxHeight: 300,
                hint: Text(hint,
                    style: GoogleFonts.poppins(
                        color: isLight ? theme.secondaryText : cyan.withOpacity(0.8),
                        fontSize: 13, fontWeight: FontWeight.w600)),
                style: GoogleFonts.poppins(
                    color: isLight ? theme.primaryText : Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: cyan, size: 22),
                items: opts.map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          style: GoogleFonts.poppins(
                              color: isLight ? theme.primaryText : Colors.white,
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _miniDrop(bool isLight, FlutterFlowTheme theme, String value, List<String> opts,
      ValueChanged<String?> onChanged) {
    final cyan   = isLight ? theme.primary : _kCyan;
    final cardBg = isLight ? theme.secondaryBackground : _kCardDk;
    return Container(
      height: 34,
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: cyan.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: opts.contains(value) ? value : opts.first,
          isExpanded: true,
          dropdownColor: cardBg,
          menuMaxHeight: 220,
          style: GoogleFonts.poppins(
              fontSize: 12,
              color: isLight ? theme.primaryText : Colors.white,
              fontWeight: FontWeight.w600),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: cyan, size: 18),
          items: opts.map((o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isLight ? theme.primaryText : Colors.white,
                        fontWeight: FontWeight.w500)),
              )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Export (TSV) ───────────────────────────────────────────────────────────
  Future<void> _exportCsv() async {
    try {
      final list = _sorted;

      // TSV: tab-separated — tabs never appear in real data, so Excel always
      // splits into perfect columns A–K without any quoting ambiguity.
      const sep = '\t';
      String row(List<String> cells) => cells.join(sep);
      String n1(double v) => v.toStringAsFixed(1);
      String n2(double v) => v.toStringAsFixed(2);
      String nc(double v) => _fmtComma(v);

      final tenant = AppConfig.clientName.isNotEmpty
          ? AppConfig.clientName
          : 'Active Multi-Tenant Scope';

      // ── Header block (11 columns, label in col-A, value(s) in cols B onward) ──
      final lines = <String>[
        // Blank 11-col row helper
        row(List.filled(11, '')),

        row(['SMARTFACTORY 365', 'DEVICE ENERGY COMPARISON REPORT', '', '', '', '', '', '', '', '', '']),
        row(List.filled(11, '')),

        row(['Generated Date', '$_lastUpdate (MYT UTC+8)', '', '', '', '', '', '', '', '', '']),
        row(['Client / Tenant', tenant, '', '', '', '', '', '', '', '', '']),
        row(['Facility Scope', 'Plant: $_plant', 'Lot: $_lot', 'Block: $_block', 'Line: $_prodLine', '', '', '', '', '', '']),
        row(['Analysis Period', '$_period  ($_dateRangeStr)', '', '', '', '', '', '', '', '', '']),
        row(['Active Metric', _metric, '', '', '', '', '', '', '', '', '']),
        row(List.filled(11, '')),

        // KPI summary — 4 pairs side by side (label | value | label | value …)
        row(['TOTAL ENERGY', '${nc(_totalEnergy)} kWh',
             'TOTAL CARBON', '${nc(_totalCarbon)} kgCO2e',
             'TOTAL COST', 'RM ${nc(_totalCost)}',
             'PEAK DEMAND', '${n1(_peakDemand)} kW',
             '', '', '']),
        row(['DEVICE COUNT', '${list.length} devices', '', '', '', '', '', '', '', '', '']),
        row(List.filled(11, '')),

        // ── Data table header ──
        row([
          'Rank',
          'Device ID',
          'Facility / Machine Name',
          'Energy (kWh)',
          'Max Demand (kW)',
          'Avg Power (kW)',
          'Carbon (kgCO2e)',
          'Est. Cost (RM)',
          'Run Hours (hrs)',
          'Power Factor',
          'Status',
        ]),
      ];

      double sumEnergy = 0, sumMd = 0, sumAvgPwr = 0;
      double sumCarbon = 0, sumCost = 0, sumPf = 0;
      int    sumRunHrs = 0;

      for (int i = 0; i < list.length; i++) {
        final d = list[i];
        sumEnergy  += d.energyKwh;
        sumMd       = math.max(sumMd, d.maxDemandKw);
        sumAvgPwr  += d.avgPowerKw;
        sumCarbon  += d.carbonKg;
        sumCost    += d.costRm;
        sumRunHrs  += d.runningHours;
        sumPf      += d.pfAvg;

        lines.add(row([
          '#${i + 1}',
          d.deviceId,
          d.deviceName,
          n1(d.energyKwh),
          n1(d.maxDemandKw),
          n1(d.avgPowerKw),
          n1(d.carbonKg),
          n1(d.costRm),
          '${d.runningHours}',
          n2(d.pfAvg),
          d.isOnline ? 'ONLINE' : 'OFFLINE',
        ]));
      }

      // ── Summary / totals row ──
      if (list.isNotEmpty) {
        final avgPf = sumPf / list.length;
        lines.add(row(List.filled(11, '')));
        lines.add(row([
          'TOTAL / AVG',
          'All ${list.length} Devices',
          'Fleet Summary',
          n1(sumEnergy),
          '${n1(sumMd)} (Peak)',
          n1(sumAvgPwr),
          n1(sumCarbon),
          n1(sumCost),
          '$sumRunHrs',
          n2(avgPf),
          'SUMMARY',
        ]));
      }

      // sep=\t directive: tells Excel to use TAB as delimiter regardless of Windows locale.
      // Must be the VERY FIRST LINE before any data — this overrides all locale/regional settings.
      // UTF-8 BOM ensures correct encoding on all Windows / Excel versions.
      final content = 'sep=\t\r\n\uFEFF${lines.join('\r\n')}';
      final bytes   = utf8.encode(content);

      final ts       = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'DeviceEnergyComparison_$ts.csv';

      await csv_saver.saveExcelBytes(bytes: bytes, fileName: fileName);
      await Clipboard.setData(ClipboardData(text: content));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _kCardDk,
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: _kGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Exported $fileName  •  ${list.length} devices',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _kCyan.withOpacity(0.4))),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade900,
        content: Text('Export failed: $e',
            style: GoogleFonts.poppins(color: Colors.white)),
      ));
    }
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Remade Cyberpunk Sci-Fi Bar Chart — Interactive, Rank Badges, HUD Tooltip
// ─────────────────────────────────────────────────────────────────────────────
class _BarChart extends StatefulWidget {
  final List<_DeviceRow> devices;
  final double maxVal;
  final double avgVal;
  final String metric;
  final String? selectedDeviceId;
  final ValueChanged<String> onSelectDevice;
  final Color Function(int, int) barColorFn;
  final String Function(double) fmtFn;
  final Color txtPri;
  final Color txtSec;

  const _BarChart({
    required this.devices,
    required this.maxVal,
    required this.avgVal,
    required this.metric,
    required this.selectedDeviceId,
    required this.onSelectDevice,
    required this.barColorFn,
    required this.fmtFn,
    required this.txtPri,
    required this.txtSec,
  });

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    const double labelH  = 24.0;
    const double barArea = 196.0;
    const double xLabelH = 65.0;
    const double totalH  = labelH + barArea + xLabelH;
    const double yAxisW  = 46.0;
    const double barW    = 34.0;
    const double barGap  = 12.0;
    final int    total   = widget.devices.length;

    final hoveredDev = (_hoveredIndex != null && _hoveredIndex! < total)
        ? widget.devices[_hoveredIndex!]
        : null;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Y-Axis Labels
            SizedBox(
              width: yAxisW,
              height: totalH,
              child: Padding(
                padding: const EdgeInsets.only(top: labelH, bottom: xLabelH),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(5, (i) {
                    final v = widget.maxVal * (1 - i / 4);
                    return Text(widget.fmtFn(v),
                        style: TextStyle(fontSize: 9, color: widget.txtSec, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right);
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Bars Container
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    total * (barW + barGap).toDouble(),
                    MediaQuery.of(context).size.width - 150,
                  ),
                  height: totalH,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Grid lines
                      Positioned(
                        top: labelH, left: 0, right: 0,
                        height: barArea,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (_) =>
                              Container(height: 1, color: _kCyan.withOpacity(0.08))),
                        ),
                      ),

                      // Benchmark Average Line
                      if (widget.maxVal > 0) ...[
                        Positioned(
                          top: labelH + barArea * (1 - (widget.avgVal / widget.maxVal).clamp(0.0, 1.0)) - 1,
                          left: 0, right: 0,
                          child: CustomPaint(
                            painter: _DashPainter(Colors.amber.withOpacity(0.85)),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                        // Avg Line Label Pill — pinned to right edge so it never overlaps bars
                        Positioned(
                          top: labelH + barArea * (1 - (widget.avgVal / widget.maxVal).clamp(0.0, 1.0)) - 13,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber, width: 0.8),
                              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 6)],
                            ),
                            child: Text(
                              'AVG: ${widget.fmtFn(widget.avgVal)}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Interactive Bars
                      Positioned(
                        top: 0, left: 0, right: 0,
                        height: totalH,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(total, (i) {
                            final d         = widget.devices[i];
                            final val       = d.metricValue(widget.metric);
                            final ratio     = widget.maxVal > 0 ? (val / widget.maxVal).clamp(0.0, 1.0) : 0.0;
                            // Min bar height 6px so tiny bars are still visible
                            final bh        = (ratio * barArea).clamp(6.0, barArea);
                            final baseColor = widget.barColorFn(i, total);
                            final isHover   = _hoveredIndex == i;
                            final isSel     = widget.selectedDeviceId == d.deviceId;
                            final isTop3    = i < 3;

                            return MouseRegion(
                              onEnter: (_) => setState(() => _hoveredIndex = i),
                              onExit:  (_) => setState(() => _hoveredIndex = null),
                              child: GestureDetector(
                                onTap: () => widget.onSelectDevice(d.deviceId),
                                child: SizedBox(
                                  width: barW + barGap,
                                  height: totalH,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: barGap),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // ── Rank Badge above bar ───────────────
                                        SizedBox(
                                          height: labelH,
                                          child: Center(
                                            child: isTop3
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (i == 0
                                                              ? Colors.redAccent
                                                              : i == 1
                                                                  ? Colors.orange
                                                                  : Colors.amber)
                                                          .withOpacity(0.92),
                                                      borderRadius: BorderRadius.circular(4),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (i == 0
                                                                  ? Colors.redAccent
                                                                  : i == 1
                                                                      ? Colors.orange
                                                                      : Colors.amber)
                                                              .withOpacity(0.5),
                                                          blurRadius: 8,
                                                        )
                                                      ],
                                                    ),
                                                    child: Text(
                                                      '#${i + 1}',
                                                      style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w900,
                                                          color: Colors.black),
                                                    ),
                                                  )
                                                : (val > 0)
                                                    ? Text(
                                                        widget.fmtFn(val),
                                                        style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.w600,
                                                          color: baseColor.withOpacity(0.85),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink(),
                                          ),
                                        ),

                                        // ── Sci-Fi Glowing Bar ─────────────────
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          width: barW,
                                          height: bh,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                baseColor.withOpacity(0.5),
                                                (isHover || isSel) ? Colors.white : baseColor,
                                              ],
                                            ),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            border: (isHover || isSel)
                                                ? Border.all(color: Colors.white, width: 1.5)
                                                : Border.all(color: baseColor.withOpacity(0.6), width: 0.8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isHover || isSel ? Colors.white : baseColor).withOpacity(0.45),
                                                blurRadius: (isHover || isSel) ? 16 : 8,
                                                offset: const Offset(0, -2),
                                              ),
                                            ],
                                          ),
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Container(
                                              height: 2,
                                              margin: const EdgeInsets.only(top: 0),
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ),

                                        // ── X-Axis Device Label (no OverflowBox) ─
                                        SizedBox(
                                          height: xLabelH,
                                          width: barW,
                                          child: Center(
                                            child: RotatedBox(
                                              quarterTurns: 1,
                                              child: SizedBox(
                                                width: xLabelH - 10,
                                                child: Text(
                                                  d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: (isHover || isSel) ? FontWeight.w800 : FontWeight.w500,
                                                    color: (isHover || isSel) ? _kCyan : widget.txtSec,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating HUD Hover Tooltip Box
        if (hoveredDev != null)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kCardDk.withOpacity(0.97),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kCyan, width: 1.2),
                boxShadow: [
                  BoxShadow(color: _kCyan.withOpacity(0.4), blurRadius: 20),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: hoveredDev.isOnline ? _kGreen : Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: (hoveredDev.isOnline ? _kGreen : Colors.redAccent).withOpacity(0.6),
                            blurRadius: 6,
                          )],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hoveredDev.deviceName.isNotEmpty
                              ? hoveredDev.deviceName
                              : hoveredDev.deviceId,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kCyan),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '#${_hoveredIndex! + 1}',
                          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _kCyan),
                        ),
                      ),
                    ],
                  ),
                  // Device ID sits below the display name in smaller text, so the
                  // human-readable name is what reads first.
                  if (hoveredDev.deviceName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 16),
                      child: Text(hoveredDev.deviceId,
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54),
                          overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: _kCyan.withOpacity(0.2)),
                  const SizedBox(height: 8),
                  _tipRow(Icons.bolt_outlined,         'Energy',      hoveredDev.hasData ? '${widget.fmtFn(hoveredDev.energyKwh)} kWh' : 'N/A', _kCyan),
                  const SizedBox(height: 6),
                  _tipRow(Icons.speed_outlined,        'Max Demand',  hoveredDev.maxDemandKw > 0 ? '${hoveredDev.maxDemandKw.toStringAsFixed(1)} kW' : 'N/A', Colors.orange),
                  const SizedBox(height: 6),
                  _tipRow(Icons.eco_outlined,          'Carbon',      hoveredDev.hasData ? '${widget.fmtFn(hoveredDev.carbonKg)} kg' : 'N/A', _kGreen),
                  const SizedBox(height: 6),
                  _tipRow(Icons.attach_money_outlined, 'Est. Cost',   hoveredDev.hasData ? 'RM ${widget.fmtFn(hoveredDev.costRm)}' : 'N/A', Colors.amber),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tipRow(IconData icon, String label, String val, Color accent) => Row(
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
          const Spacer(),
          Text(val, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      );
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), p);
      x += 10;
    }
  }
  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
