import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'powerdiagram_model.dart';
export 'powerdiagram_model.dart';

class PowerdiagramWidget extends StatefulWidget {
  const PowerdiagramWidget({
    super.key,
    required this.apiDevices,
    required this.mqttDevices,
    required this.powerData,
    required this.isLoading,
  });

  final List<dynamic> apiDevices;
  final bool isLoading;
  final Map<String, Map<String, dynamic>> mqttDevices;
  final Map<String, double> powerData;

  @override
  State<PowerdiagramWidget> createState() => _PowerdiagramWidgetState();
}

class _PowerdiagramWidgetState extends State<PowerdiagramWidget> with TickerProviderStateMixin {
  List<int> position = [];
  List<int> uniquePosition = [];

  late AnimationController bounceController;
  late AnimationController arrowController;
  late PowerdiagramModel _model;

  static const bool DEBUG_MODE = false;

  List<String> getAllKnownDevices() {
    return [
      'MSB', 'CM1', 'CM2', 'TD10', 'MOTAN', 'C10', 'CA',
      'C4', 'L9', 'C7', 'C8', 'C9', 'TD9_SUB', 'TD9',
      'TD9 SUB', 'TDB', 'TD7', 'TD8', 'C2', 'T17'
    ];
  }

  Map<String, Offset> getDevicePositionOffsets() {
    return {
      'MSB': const Offset(0.13, 0.69),
      'CM1': const Offset(0.23, 0.16),
      'CM2': const Offset(0.49, 0.27),
      'TD10': const Offset(0.65, 0.31),
      'MOTAN': const Offset(0.78, 0.37),
      'C10': const Offset(0.94, 0.59),
      'CA': const Offset(0.92, 0.42),
      'C7': const Offset(0.56, 0.89),
      'C8': const Offset(0.70, 0.90),
      'C9': const Offset(0.90, 0.70),
      'TD9': const Offset(0.14, 0.40),
      'TD9 SUB': const Offset(0.10, 0.53),
      'TD7': const Offset(0.29, 0.77),
      'TD8': const Offset(0.44, 0.84),
      'C2': const Offset(0.76, 0.77),
    };
  }

  @override
  void dispose() {
    _model.maybeDispose();
    bounceController.dispose();
    arrowController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerdiagramModel());

    bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    arrowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Offset> devicePositionOffsets = getDevicePositionOffsets();

    // The 15 Danapac diagram slots, in a fixed order, each with its own
    // position on the diagram (e.g. MSB's slot, CM1's slot, ...).
    final List<String> defaultDeviceIds = devicePositionOffsets.keys.toList();
    final List<Offset> slotOffsets =
        defaultDeviceIds.map((id) => devicePositionOffsets[id]!).toList();

    final List<String> apiDeviceIds = widget.apiDevices
        .map((d) => d['device']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    // If the active client's devices match the known Danapac layout, keep
    // the original device labels. Otherwise, fill the same 15 slots with the
    // active client's devices (e.g. MSB -> DPM001, CM1 -> DPM003, ...).
    final bool isDanapac =
        apiDeviceIds.isEmpty || apiDeviceIds.any(devicePositionOffsets.containsKey);

    List<String> deviceIds = isDanapac
        ? defaultDeviceIds
        : List.generate(
            defaultDeviceIds.length,
            (i) => i < apiDeviceIds.length ? apiDeviceIds[i] : defaultDeviceIds[i],
          );

    List<_DeviceInfo> devices = [];

    List<Offset> computeDevicePositions(double width, double height, List<String> deviceList) {
      List<Offset> positions = [];
      for (int i = 0; i < deviceList.length; i++) {
        Offset relativePos = slotOffsets[i];
        positions.add(Offset(width * relativePos.dx, height * relativePos.dy));
      }
      uniquePosition = position.toSet().toList();
      uniquePosition.sort();
      return positions;
    }

    String addCommas(String numberStr) {
      List<String> parts = numberStr.split('.');
      parts[0] = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (Match m) => ',',
      );
      return parts.join('.');
    }

    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isLight ? theme.secondaryBackground : const Color(0xFF0E1A3A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isLight ? theme.alternate : const Color(0xFF1E3A6E),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;

                // All sizing from constraints — ngikut zoom
                final containerWidth = (width * 0.12).clamp(90.0, 160.0);
                final halfContainerWidth = containerWidth / 2;
                final headerFontSize = (width * 0.012).clamp(8.0, 12.0);
                final dataFontSize = (width * 0.010).clamp(7.0, 10.0);
                final indicatorSize = (width * 0.008).clamp(5.0, 8.0);
                final headerPadH = (width * 0.007).clamp(4.0, 8.0);
                final headerPadV = (width * 0.005).clamp(3.0, 6.0);
                final dataPad = (width * 0.005).clamp(3.0, 6.0);
                final rowSpacing = (width * 0.003).clamp(2.0, 4.0);
                final borderRadius = (width * 0.007).clamp(4.0, 8.0);

                // Container height proportional to width
                final containerHeight = containerWidth * 1.1;
                final halfContainerHeight = containerHeight / 2;

                // Build device list
                devices.clear();
                for (String id in deviceIds) {
                  double edel = 0.0;

                  if (widget.powerData.containsKey(id)) {
                    edel = widget.powerData[id] ?? 0.0;
                  } else if (widget.mqttDevices.containsKey(id)) {
                    var mqttData = widget.mqttDevices[id];
                    if (mqttData?["Power"] != null && mqttData?["Power"]["P(kW)"] is num) {
                      edel = (mqttData?["Power"]["P(kW)"] as num).toDouble();
                    } else if (mqttData?["Power"] != null && mqttData?["Power"]["P(W)"] is num) {
                      edel = (mqttData?["Power"]["P(W)"] as num).toDouble() / 1000;
                    }
                  }

                  double totalEnergy = 0.0;
                  var apiDevice = widget.apiDevices.firstWhere(
                    (item) => item['device'].toString() == id,
                    orElse: () => null,
                  );
                  if (apiDevice != null && apiDevice['total_energy'] is num) {
                    totalEnergy = (apiDevice['total_energy'] as num).toDouble();
                  }

                  devices.add(_DeviceInfo(id: id, edel: edel, totalEnergy: totalEnergy));
                }

                final devicePositions = computeDevicePositions(width, height, deviceIds);

                return Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        // Decode at the size this is actually drawn at rather
                        // than the asset's native 1536x1228. It is a 297-frame
                        // GIF and every frame is held as a raw bitmap, so at
                        // native size that is 1536*1228*4 bytes * 297 frames,
                        // roughly 2.1 GB, and Flutter's image cache keeps it
                        // after the page is left. It was being downscaled to fit
                        // anyway, so this looks identical. Guarded on isFinite
                        // because an unbounded parent makes maxWidth infinite
                        // and round() would throw.
                        child: Image.asset(
                          'assets/images/danapac_diagram_new.gif',
                          fit: BoxFit.cover,
                          cacheWidth:
                              (width.isFinite && width > 0) ? width.round() : null,
                        ),
                      ),
                    ),
                    // Device containers
                    for (int i = 0; i < devices.length && i < devicePositions.length; i++)
                      Positioned(
                        left: (devicePositions[i].dx - halfContainerWidth).clamp(0.0, width - containerWidth),
                        top: (devicePositions[i].dy - halfContainerHeight).clamp(0.0, height - containerHeight),
                        child: Stack(
                          children: [
                            Container(
                              width: containerWidth,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.light
                                    ? FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.9)
                                    : const Color(0xFF1E293B).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(borderRadius),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: headerPadH,
                                      vertical: headerPadV,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(borderRadius - 1),
                                        topRight: Radius.circular(borderRadius - 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            devices[i].id,
                                            style: GoogleFonts.poppins(
                                              fontSize: headerFontSize,
                                              fontWeight: FontWeight.w600,
                                              color: FlutterFlowTheme.of(context).txtOnAccent,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          width: indicatorSize,
                                          height: indicatorSize,
                                          decoration: BoxDecoration(
                                            color: devices[i].edel > 0 ? Colors.green : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Data rows
                                  Padding(
                                    padding: EdgeInsets.all(dataPad),
                                    child: Column(
                                      children: [
                                        _dataRow('Power', '${devices[i].edel.toStringAsFixed(1)} kW', dataFontSize),
                                        SizedBox(height: rowSpacing),
                                        _dataRow('Energy', '${addCommas(devices[i].totalEnergy.toStringAsFixed(1))} kWh', dataFontSize),
                                        SizedBox(height: rowSpacing),
                                        _dataRow('CO2e', '${addCommas((devices[i].totalEnergy * 0.58).toStringAsFixed(1))} kg', dataFontSize),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (DEBUG_MODE)
                              Positioned(
                                top: -20,
                                left: 0,
                                right: 0,
                                child: Text(
                                  '${devices[i].id}\n(${(devicePositions[i].dx / width).toStringAsFixed(2)}, ${(devicePositions[i].dy / height).toStringAsFixed(2)})',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }


  Widget _dataRow(String label, String value, double fontSize) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: isLight ? theme.txtSecondary : Colors.white,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: isLight ? theme.primary : const Color(0xFF00BFFF),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DeviceInfo {
  _DeviceInfo({required this.id, required this.edel, required this.totalEnergy});

  final double edel;
  final String id;
  final double totalEnergy;
}
