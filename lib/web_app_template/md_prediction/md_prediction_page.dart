import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/md_prediction/services/md_prediction_service.dart';
import 'package:smartmachine365/web_app_template/md_prediction/widgets/md_prediction_dashboard.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_models.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_service.dart';

// ---------------------------------------------------------------------------
// MD Prediction Page — standalone module entry point
// ---------------------------------------------------------------------------

class MdPredictionPage extends StatefulWidget {
  const MdPredictionPage({super.key});

  @override
  State<MdPredictionPage> createState() => _MdPredictionPageState();
}

class _MdPredictionPageState extends State<MdPredictionPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  double _livePowerKw = 0.0;
  double _contractCapacity = 0.0;
  List<double> _intervalReadings = [];
  List<String> _intervalLabels = [];
  List<ActiveEquipmentData> _activeEquipment = [];

  bool _isLoadingSettings = true;
  bool _isLoadingInterval = true;
  bool _isLoadingEquipment = false;
  String? _error;

  // Both start empty on purpose. Seeding them with a device name meant the
  // page queried a device that may not belong to this client and rendered a
  // chart for it, so a data problem looked like real data.
  List<String> _availableDevices = const [];
  String _selectedDeviceId = '';
  DateTime? _lastUpdated;

  // TNB meters (TNB Meter Setting) — the header dropdown refers to this list,
  // same as Max Demand Monitoring: a meter selects its DPM device
  // (influxDbTag) and its contract MD capacity.
  List<TnbMeter> _tnbMeters = [];
  List<Map<String, dynamic>> _tnbPlants = [];
  TnbMeter? _selectedTnbMeter;

  Timer? _pollTimer;
  Timer? _intervalTimer;
  Timer? _equipmentTimer;
  int _powerRequestVersion = 0;
  int _intervalRequestVersion = 0;
  int _equipmentRequestVersion = 0;

  static const _kPollInterval = Duration(seconds: 10);
  static const _kIntervalRefresh = Duration(minutes: 1);
  static const _kEquipmentRefresh = Duration(minutes: 2);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDevicesThenFetch();
    _fetchActiveEquipment();
    _fetchTnbMeters();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _fetchCurrentPower());
    _intervalTimer =
        Timer.periodic(_kIntervalRefresh, (_) => _fetchIntervalData());
    _equipmentTimer =
        Timer.periodic(_kEquipmentRefresh, (_) => _fetchActiveEquipment());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _intervalTimer?.cancel();
    _equipmentTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTnbMeters() async {
    try {
      final results = await Future.wait([
        TnbMeterService.fetchMeters(),
        TnbMeterService.fetchPlants(),
      ]);
      if (!mounted) return;
      setState(() {
        _tnbMeters =
            (results[0] as List<TnbMeter>).where((m) => m.isActive).toList();
        _tnbPlants = results[1] as List<Map<String, dynamic>>;
      });
      // Default to the first registered meter so the page opens on a
      // configured TNB meter (mirrors Max Demand Monitoring).
      if (_tnbMeters.isNotEmpty && _selectedTnbMeter == null) {
        _onTnbMeterSelected(_tnbMeters.first);
      }
    } catch (_) {}
  }

  String _tnbPlantName(String plantId) {
    for (final p in _tnbPlants) {
      if (p['id']?.toString() == plantId) return p['name']?.toString() ?? plantId;
    }
    return plantId;
  }

  String _tnbMeterLabel(TnbMeter m) {
    final plant = _tnbPlantName(m.plantId);
    final label = m.meterLabel.isNotEmpty ? m.meterLabel : m.meterCode;
    return plant.isNotEmpty && plant != m.plantId ? '$plant — $label' : label;
  }

  void _onTnbMeterSelected(TnbMeter? meter) {
    setState(() {
      _selectedTnbMeter = meter;
      // A meter with no device mapping, or no contract capacity, must clear
      // these rather than leave them alone. Skipping the assignment kept the
      // previously selected meter's values, so picking an unmapped meter
      // showed another plant's readings and another plant's MD threshold
      // under this meter's name — data that looked real and belonged to
      // somebody else.
      final tag = meter?.influxDbTag.trim() ?? '';
      _selectedDeviceId = tag;
      _contractCapacity =
          (meter != null && meter.contractMdKw > 0) ? meter.contractMdKw : 0.0;
      if (tag.isEmpty) {
        _livePowerKw = 0.0;
        _intervalReadings = const [];
        _intervalLabels = const [];
        _activeEquipment = const [];
        _lastUpdated = null;
        _isLoadingInterval = false;
      }
    });
    if (meter == null) {
      // Cleared — fall back to the raw device list + settings capacity.
      _loadSettings();
      _loadDevicesThenFetch();
      return;
    }
    _fetchCurrentPower();
    _fetchIntervalData();
  }

  /// Resolves the active client's real device list before the first fetch,
  /// so the page never queries a device (e.g. Danapac's "MSB") that doesn't
  /// exist for the current client.
  Future<void> _loadDevicesThenFetch() async {
    final devices = await MdPredictionService.fetchAvailableDevices();
    if (!mounted) return;
    setState(() {
      _availableDevices = devices;
      _selectedDeviceId = devices.isEmpty
          ? ''
          : (devices.contains('MSB') ? 'MSB' : devices.first);
    });
    // Nothing to query when the client has no devices; leave the page empty
    // rather than firing requests for a device id that does not exist.
    if (_selectedDeviceId.isEmpty) {
      if (mounted) setState(() => _isLoadingInterval = false);
      return;
    }
    _fetchCurrentPower();
    _fetchIntervalData();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final capacity = await MdPredictionService.fetchContractCapacity();
    if (mounted) {
      setState(() {
        _contractCapacity = capacity;
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _fetchCurrentPower() async {
    final requestVersion = ++_powerRequestVersion;
    final deviceId = _selectedDeviceId;
    if (deviceId.isEmpty) return;
    final result = await MdPredictionService.fetchCurrentPower(deviceId);
    if (!mounted || requestVersion != _powerRequestVersion) return;
    if (result != null && deviceId == _selectedDeviceId) {
      setState(() {
        _livePowerKw = result.powerKw;
        _lastUpdated = result.timestamp;
      });
    }
  }

  Future<void> _fetchActiveEquipment() async {
    final requestVersion = ++_equipmentRequestVersion;
    if (mounted) setState(() => _isLoadingEquipment = true);

    // Phase 1 — fast: load facility metadata from Firestore.
    // The list renders immediately with all devices shown as IDLE (kW = 0).
    final meta = await MdPredictionService.fetchActiveEquipmentMeta();
    if (!mounted || requestVersion != _equipmentRequestVersion) return;
    setState(() {
      _activeEquipment = meta;
      _isLoadingEquipment = false; // list is visible; kW still loading
    });

    if (meta.isEmpty) return;

    // Phase 2 — streaming: resolve each device's live kW through the throttled
    // queue. setState on every resolved device so the row updates in real-time.
    await MdPredictionService.streamEquipmentKw(meta, (index, kw) {
      if (!mounted || requestVersion != _equipmentRequestVersion) return;
      setState(() {
        final prev = _activeEquipment.length > index ? _activeEquipment[index] : null;
        // Preserve runningSince if the machine was already running;
        // set it to now when first detected as active this session.
        final runningSince = kw > 0.5
            ? (prev?.runningSince ?? DateTime.now())
            : null;
        _activeEquipment = List<ActiveEquipmentData>.from(_activeEquipment)
          ..[index] = ActiveEquipmentData(
            meterId:        meta[index].meterId,
            meterName:      meta[index].meterName,
            impactCategory: meta[index].impactCategory,
            plant:          meta[index].plant,
            factory:        meta[index].factory,
            specs:          meta[index].specs,
            currentKw:      kw,
            fetchedAt:      DateTime.now(),
            runningSince:   runningSince,
          );
      });
    });
  }

  Future<void> _fetchIntervalData() async {
    final requestVersion = ++_intervalRequestVersion;
    final deviceId = _selectedDeviceId;
    if (deviceId.isEmpty) {
      if (mounted) setState(() => _isLoadingInterval = false);
      return;
    }
    if (mounted) setState(() => _isLoadingInterval = true);
    try {
      final result =
          await MdPredictionService.fetchIntervalData(deviceId);
      if (mounted &&
          requestVersion == _intervalRequestVersion &&
          deviceId == _selectedDeviceId) {
        setState(() {
          _intervalReadings = result.readings;
          _intervalLabels = result.labels;
          _isLoadingInterval = false;
          _error = null;
        });
      }
    } on MdPredictionServiceException catch (e) {
      if (mounted && requestVersion == _intervalRequestVersion) {
        setState(() {
          _error = e.message;
          _isLoadingInterval = false;
        });
      }
    } catch (e) {
      if (mounted && requestVersion == _intervalRequestVersion) {
        setState(() {
          _error = 'Connection error: $e';
          _isLoadingInterval = false;
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── PageHeader with breadcrumbs ────────────────────────────────
          PageHeader(
            breadcrumbs: const [
              BreadcrumbItem(label: 'Home', icon: Icons.home_outlined),
              BreadcrumbItem(label: 'Energy Monitoring'),
              BreadcrumbItem(label: 'MD Prediction'),
            ],
            title: 'MD Prediction',
            titleStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isLight
                  ? FlutterFlowTheme.of(context).txtPrimary
                  : Colors.white,
              letterSpacing: 0.5,
            ),
            subtitle: 'Live Interval Forecast & Trend Analysis',
            subtitleStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: theme.secondaryText,
              fontWeight: FontWeight.w400,
            ),
            trailing: _buildHeaderTrailing(theme, isLight),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: _isLoadingSettings && _isLoadingInterval
                ? _buildLoading()
                : _error != null && _intervalReadings.isEmpty
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnmapped() {
    final theme = FlutterFlowTheme.of(context);
    final name = _selectedTnbMeter == null
        ? 'This selection'
        : _tnbMeterLabel(_selectedTnbMeter!);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off_rounded, size: 40, color: theme.secondaryText),
          const SizedBox(height: 12),
          Text(
            'No device mapped',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$name has no DPM device assigned in TNB Meter Setting, '
            'so there is no demand data to read.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header trailing (device picker + live chip + refresh) ─────────────────

  Widget _buildHeaderTrailing(FlutterFlowTheme theme, bool isLight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dropdown refers to the TNB meter list (TNB Meter Setting) — same
        // behaviour as Max Demand Monitoring. Falls back to the raw device
        // list when no meter is registered.
        if (_tnbMeters.isNotEmpty)
          _TnbMeterDropdown(
            meters: _tnbMeters,
            value: _selectedTnbMeter?.id,
            labelFor: _tnbMeterLabel,
            onChanged: (id) {
              TnbMeter? m;
              for (final x in _tnbMeters) {
                if (x.id == id) m = x;
              }
              _onTnbMeterSelected(m);
            },
          )
        // No meters registered and no devices returned means there is nothing
        // to pick between. Showing an empty picker invited a selection that
        // cannot exist, and DropdownButton has no valid value to display when
        // its item list is empty.
        else if (_availableDevices.isNotEmpty)
          _DeviceDropdown(
            value: _availableDevices.contains(_selectedDeviceId)
                ? _selectedDeviceId
                : _availableDevices.first,
            devices: _availableDevices,
            onChanged: (v) {
              setState(() => _selectedDeviceId = v);
              _fetchIntervalData();
              _fetchCurrentPower();
            },
          ),
        const SizedBox(width: 12),

        // Live clock chip
        if (_lastUpdated != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withOpacity(0.08),
              border: Border.all(
                  color: const Color(0xFF00C6FF).withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE  ${_fmtTime(_lastUpdated!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(width: 4),

        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 18),
          color: theme.secondaryText,
          tooltip: 'Refresh',
          onPressed: () {
            _fetchCurrentPower();
            _fetchIntervalData();
            _fetchActiveEquipment();
          },
        ),
      ],
    );
  }

  // ── Body states ────────────────────────────────────────────────────────────

  Widget _buildContent() {
    // Nothing mapped means nothing to predict from. Rendering the dashboard
    // with empty readings drew a full set of gauges and forecast lines sitting
    // at zero, which reads as "this plant used no power" rather than "this
    // plant is not wired up yet".
    if (_selectedDeviceId.isEmpty) return _buildUnmapped();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: MdPredictionDashboard(
        livePowerKw: _livePowerKw,
        // No invented default. A stand-in of 1800 kW made every percentage,
        // headroom figure and threshold alert on this page look authoritative
        // while resting on a number nobody configured. Zero is handled
        // throughout the dashboard as "not set", which is the truth.
        contractLimitKw: _contractCapacity,
        intervalReadings: _intervalReadings,
        timeLabels: _intervalLabels,
        activeEquipment: _activeEquipment,
        isLoadingEquipment: _isLoadingEquipment,
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: Color(0xFF00C6FF), strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Initialising...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF00C6FF),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00C6FF),
              side: const BorderSide(color: Color(0xFF00C6FF), width: 1),
              textStyle: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              _fetchCurrentPower();
              _fetchIntervalData();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// TNB meter dropdown (local to this page) — lists registered TNB meters
// from TNB Meter Setting, same style as the raw device dropdown below.
// ---------------------------------------------------------------------------

class _TnbMeterDropdown extends StatelessWidget {
  final List<TnbMeter> meters;
  final String? value;
  final String Function(TnbMeter) labelFor;
  final ValueChanged<String?> onChanged;

  const _TnbMeterDropdown({
    required this.meters,
    required this.value,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
        meters.any((m) => m.id == value) ? value : null;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00C6FF).withOpacity(0.06),
        border: Border.all(
            color: const Color(0xFF00C6FF).withOpacity(0.35), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          dropdownColor: const Color(0xFF0D1B2E),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF00C6FF),
            fontWeight: FontWeight.w600,
          ),
          hint: Text(
            'TNB Meter',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF00C6FF).withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.expand_more,
              size: 14, color: Color(0xFF00C6FF)),
          items: meters
              .map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(labelFor(m), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Device dropdown (local to this page)
// ---------------------------------------------------------------------------

class _DeviceDropdown extends StatelessWidget {
  final String value;
  final List<String> devices;
  final ValueChanged<String> onChanged;

  const _DeviceDropdown({
    required this.value,
    required this.devices,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00C6FF).withOpacity(0.06),
        border: Border.all(
            color: const Color(0xFF00C6FF).withOpacity(0.35), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0D1B2E),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF00C6FF),
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.expand_more,
              size: 14, color: Color(0xFF00C6FF)),
          items: devices
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
