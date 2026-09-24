import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/energy_system_settings/energy_system_setting_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class ElectricityTariffSettings extends StatefulWidget {
  final String uid;
  final Function(Map<String, dynamic>)? onSaved;

  const ElectricityTariffSettings({
    super.key,
    required this.uid,
    this.onSaved,
  });

  @override
  State<ElectricityTariffSettings> createState() => _ElectricityTariffSettingsState();
}

class _ElectricityTariffSettingsState extends State<ElectricityTariffSettings> {
  final TextEditingController _peakRateController = TextEditingController(text: '0.0');
  final TextEditingController _normalRateController = TextEditingController(text: '0.0');
  final TextEditingController _offPeakRateController = TextEditingController(text: '0.0');
  final TextEditingController _capacityRateController = TextEditingController(text: '0.0');

  bool _isLoading = false;
  bool _isSaving = false;

  String _originalPeakRate = '0.0';
  String _originalNormalRate = '0.0';
  String _originalOffPeakRate = '0.0';
  String _originalCapacityRate = '0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _peakRateController.dispose();
    _normalRateController.dispose();
    _offPeakRateController.dispose();
    _capacityRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await EnergySystemSettingsService.getSettings(widget.uid);

      if (response['exists'] == true && response['settings'] != null) {
        final settings = response['settings']['electricityTariff'];
        if (settings != null) {
          setState(() {
            _peakRateController.text = settings['peakRate']?.toString() ?? '0.355';
            _normalRateController.text = settings['normalRate']?.toString() ?? '0.217';
            _offPeakRateController.text = settings['offPeakRate']?.toString() ?? '0.217';
            _capacityRateController.text = settings['capacityRate']?.toString() ?? '30.30';

            _originalPeakRate = _peakRateController.text;
            _originalNormalRate = _normalRateController.text;
            _originalOffPeakRate = _offPeakRateController.text;
            _originalCapacityRate = _capacityRateController.text;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final peakRate = double.tryParse(_peakRateController.text);
    final normalRate = double.tryParse(_normalRateController.text);
    final offPeakRate = double.tryParse(_offPeakRateController.text);
    final capacityRate = double.tryParse(_capacityRateController.text);

    if (peakRate == null || peakRate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peak rate must be a non-negative number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (normalRate == null || normalRate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Normal rate must be a non-negative number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (offPeakRate == null || offPeakRate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Off-peak rate must be a non-negative number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (capacityRate == null || capacityRate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capacity rate must be a non-negative number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settingData = {
        'peakRate': peakRate,
        'normalRate': normalRate,
        'offPeakRate': offPeakRate,
        'capacityRate': capacityRate,
      };

      await EnergySystemSettingsService.updateSettingType(
        widget.uid,
        'electricityTariff',
        settingData,
      );

      setState(() {
        _originalPeakRate = _peakRateController.text;
        _originalNormalRate = _normalRateController.text;
        _originalOffPeakRate = _offPeakRateController.text;
        _originalCapacityRate = _capacityRateController.text;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Electricity tariff settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved?.call(settingData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _cancelChanges() {
    setState(() {
      _peakRateController.text = _originalPeakRate;
      _normalRateController.text = _originalNormalRate;
      _offPeakRateController.text = _originalOffPeakRate;
      _capacityRateController.text = _originalCapacityRate;
    });
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Electricity Tariff Settings',
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
                Text(
                  'Peak Period Rate (RM/kWh)',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _peakRateController,
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
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                Text(
                  'Normal Period Rate (RM/kWh)',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _normalRateController,
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
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                Text(
                  'Off-Peak Period Rate (RM/kWh)',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _offPeakRateController,
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
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                Text(
                  'Capacity Rate (RM/kW)',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _capacityRateController,
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
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const Spacer(),
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
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1,
                        ),
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
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1,
                        ),
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
