import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/energy_system_settings/energy_system_setting_service.dart';
import 'package:smartmachine365/web_app_template/energy_system_settings/time_picker_tile_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class ContractCapacitySettings extends StatefulWidget {
  final String uid;
  final Function(Map<String, dynamic>)? onSaved;

  const ContractCapacitySettings({
    super.key,
    required this.uid,
    this.onSaved,
  });

  @override
  State<ContractCapacitySettings> createState() => _ContractCapacitySettingsState();
}

class _ContractCapacitySettingsState extends State<ContractCapacitySettings> {
  final TextEditingController _contractCapacityController = TextEditingController(text: '0');
  final TextEditingController _warningThresholdController = TextEditingController(text: '0');
  final TextEditingController _emergencyThresholdController = TextEditingController(text: '0');

  bool _isLoading = false;
  bool _isSaving = false;

  // Store original values for cancel functionality
  String _originalContractCapacity = '0';
  String _originalWarningThreshold = '0';
  String _originalEmergencyThreshold = '0';
  TimeOfDay _originalPeakStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _originalPeakEndTime = const TimeOfDay(hour: 12, minute: 0);
  List<int> _originalPeakDays = const [1, 2, 3, 4, 5]; // Mon–Fri default

  // Peak Hour ToU time pickers
  TimeOfDay _peakStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _peakEndTime = const TimeOfDay(hour: 12, minute: 0);

  // Peak Hour ToU day selector (1=Mon … 7=Sun)
  List<int> _selectedPeakDays = [1, 2, 3, 4, 5];

  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _contractCapacityController.dispose();
    _warningThresholdController.dispose();
    _emergencyThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await EnergySystemSettingsService.getSettings(widget.uid);

      if (response['exists'] == true && response['settings'] != null) {
        final settings = response['settings']['contractCapacity'];
        if (settings != null) {
          TimeOfDay loadedStartTime = const TimeOfDay(hour: 8, minute: 0);
          TimeOfDay loadedEndTime = const TimeOfDay(hour: 12, minute: 0);

          List<int> loadedDays = [1, 2, 3, 4, 5];

          if (settings['peakHourToU'] != null) {
            final tou = settings['peakHourToU'] as Map<String, dynamic>;
            if (tou['startTime'] != null) {
              loadedStartTime = _parseTimeOfDay(tou['startTime'] as String);
            }
            if (tou['endTime'] != null) {
              loadedEndTime = _parseTimeOfDay(tou['endTime'] as String);
            }
            if (tou['days'] != null) {
              loadedDays = List<int>.from(tou['days'] as List);
            }
          }

          setState(() {
            _contractCapacityController.text = settings['contractCapacity']?.toString() ?? '0';
            _warningThresholdController.text = settings['warningThreshold']?.toString() ?? '0';
            _emergencyThresholdController.text = settings['emergencyThreshold']?.toString() ?? '0';
            _peakStartTime = loadedStartTime;
            _peakEndTime = loadedEndTime;
            _selectedPeakDays = loadedDays;

            _originalContractCapacity = _contractCapacityController.text;
            _originalWarningThreshold = _warningThresholdController.text;
            _originalEmergencyThreshold = _emergencyThresholdController.text;
            _originalPeakStartTime = loadedStartTime;
            _originalPeakEndTime = loadedEndTime;
            _originalPeakDays = List<int>.from(loadedDays);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Parses "HH:MM" string into [TimeOfDay].
  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  /// Formats [TimeOfDay] into "HH:MM" 24-hour string for storage.
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initialTime,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: FlutterFlowTheme.of(context).primary,
              onPrimary: Colors.white,
              surface: const Color.fromRGBO(0, 4, 51, 1),
              onSurface: Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color.fromRGBO(0, 10, 70, 1),
              hourMinuteTextColor: Colors.white,
              dialTextColor: Colors.white,
              entryModeIconColor: FlutterFlowTheme.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _saveSettings() async {
    final contractCapacity = double.tryParse(_contractCapacityController.text);
    final warningThreshold = double.tryParse(_warningThresholdController.text);
    final emergencyThreshold = double.tryParse(_emergencyThresholdController.text);

    if (contractCapacity == null || contractCapacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Contract capacity must be a positive number'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (warningThreshold == null || warningThreshold < 0 || warningThreshold > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warning threshold must be between 0 and 100'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (emergencyThreshold == null || emergencyThreshold < 0 || emergencyThreshold > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Emergency threshold must be between 0 and 100'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (warningThreshold >= emergencyThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warning threshold must be less than emergency threshold'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final startMin = _peakStartTime.hour * 60 + _peakStartTime.minute;
    final endMin = _peakEndTime.hour * 60 + _peakEndTime.minute;
    if (startMin >= endMin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Peak hour start time must be before end time'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settingData = {
        'contractCapacity': contractCapacity,
        'warningThreshold': warningThreshold,
        'emergencyThreshold': emergencyThreshold,
        'peakHourToU': {
          'startTime': _formatTimeOfDay(_peakStartTime),
          'endTime': _formatTimeOfDay(_peakEndTime),
          'days': _selectedPeakDays,
        },
      };

      await EnergySystemSettingsService.updateSettingType(
        widget.uid,
        'contractCapacity',
        settingData,
      );

      setState(() {
        _originalContractCapacity = _contractCapacityController.text;
        _originalWarningThreshold = _warningThresholdController.text;
        _originalEmergencyThreshold = _emergencyThresholdController.text;
        _originalPeakStartTime = _peakStartTime;
        _originalPeakEndTime = _peakEndTime;
        _originalPeakDays = List<int>.from(_selectedPeakDays);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Contract capacity settings saved successfully'),
          backgroundColor: Colors.green,
        ));
      }

      widget.onSaved?.call(settingData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _cancelChanges() {
    setState(() {
      _contractCapacityController.text = _originalContractCapacity;
      _warningThresholdController.text = _originalWarningThreshold;
      _emergencyThresholdController.text = _originalEmergencyThreshold;
      _peakStartTime = _originalPeakStartTime;
      _peakEndTime = _originalPeakEndTime;
      _selectedPeakDays = List<int>.from(_originalPeakDays);
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color.fromRGBO(0, 4, 51, 1),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              // ← outer Column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Scrollable body ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'Contract Capacity Settings (Max Demand)',
                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).info,
                                fontSize: 20,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Contract Capacity (kW)
                        Text(
                          'Contract Capacity (kW)',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contractCapacityController,
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),

                        // Warning Threshold (%)
                        Text(
                          'Warning Threshold (%)',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _warningThresholdController,
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Issue a warning when the power load reaches the specified percentage of contract capacity.',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Emergency Threshold (%)
                        Text(
                          'Emergency Threshold (%)',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emergencyThresholdController,
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Issue an emergency alert when the power load reaches the specified percentage of contract capacity.',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Peak Hour ToU Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bolt_rounded, color: FlutterFlowTheme.of(context).primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Peak Hour ToU',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          fontFamily: 'Poppins',
                                          color: FlutterFlowTheme.of(context).info,
                                          fontSize: 15,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          font: GoogleFonts.poppins(),
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TimePickerTileWidget(
                                label: 'Start Time',
                                time: _peakStartTime,
                                onTap: () => _pickTime(
                                  context,
                                  _peakStartTime,
                                  (t) => setState(() => _peakStartTime = t),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TimePickerTileWidget(
                                label: 'End Time',
                                time: _peakEndTime,
                                onTap: () => _pickTime(
                                  context,
                                  _peakEndTime,
                                  (t) => setState(() => _peakEndTime = t),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Peak Days',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Poppins',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      fontSize: 13,
                                      letterSpacing: 0.0,
                                      font: GoogleFonts.poppins(),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_dayLabels.length, (index) {
                                  final dayNum = index + 1; // 1=Mon … 7=Sun
                                  final isSelected = _selectedPeakDays.contains(dayNum);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedPeakDays.remove(dayNum);
                                        } else {
                                          _selectedPeakDays.add(dayNum);
                                          _selectedPeakDays.sort();
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? FlutterFlowTheme.of(context).primary
                                            : const Color.fromRGBO(255, 255, 255, 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? FlutterFlowTheme.of(context).primary
                                              : FlutterFlowTheme.of(context).alternate,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _dayLabels[index],
                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                              fontFamily: 'Poppins',
                                              color: isSelected
                                                  ? Colors.white
                                                  : FlutterFlowTheme.of(context).secondaryText,
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              letterSpacing: 0.0,
                                              font: GoogleFonts.poppins(),
                                            ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),

                        // Bottom padding so last item isn't flush against the divider
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Sticky divider + buttons (never scrolls away) ────────────
                Divider(color: FlutterFlowTheme.of(context).alternate, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FFButtonWidget(
                      onPressed: _isSaving ? null : _cancelChanges,
                      text: 'Cancel',
                      options: FFButtonOptions(
                        height: 44,
                        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        color: Colors.transparent,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Poppins',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              font: GoogleFonts.poppins(),
                            ),
                        elevation: 0,
                        borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FFButtonWidget(
                      onPressed: _isSaving ? null : _saveSettings,
                      text: _isSaving ? 'Saving...' : 'Save Settings',
                      options: FFButtonOptions(
                        height: 44,
                        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              letterSpacing: 0.0,
                              font: GoogleFonts.poppins(),
                            ),
                        elevation: 0,
                        borderSide: const BorderSide(color: Colors.transparent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
