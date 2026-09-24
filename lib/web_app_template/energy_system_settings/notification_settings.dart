import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/energy_system_settings/energy_system_setting_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class NotificationSettings extends StatefulWidget {
  final String uid;
  final Function(Map<String, dynamic>)? onSaved;

  const NotificationSettings({
    super.key,
    required this.uid,
    this.onSaved,
  });

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _phoneController = TextEditingController(text: '');

  String _emailNotification = 'Enable';
  String _smsNotification = 'Enable';

  bool _isLoading = false;
  bool _isSaving = false;

  String _originalEmail = '';
  String _originalPhone = '';
  String _originalEmailNotification = 'Enable';
  String _originalSmsNotification = 'Enable';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await EnergySystemSettingsService.getSettings(widget.uid);

      if (response['exists'] == true && response['settings'] != null) {
        final settings = response['settings']['notification'];
        if (settings != null) {
          setState(() {
            _emailController.text = settings['email'] ?? '';
            _phoneController.text = settings['phone'] ?? '';
            _emailNotification = (settings['emailEnabled'] ?? true) ? 'Enable' : 'Disable';
            _smsNotification = (settings['smsEnabled'] ?? true) ? 'Enable' : 'Disable';

            _originalEmail = _emailController.text;
            _originalPhone = _phoneController.text;
            _originalEmailNotification = _emailNotification;
            _originalSmsNotification = _smsNotification;
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
    // Basic email validation
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settingData = {
        'email': email,
        'phone': _phoneController.text.trim(),
        'emailEnabled': _emailNotification == 'Enable',
        'smsEnabled': _smsNotification == 'Enable',
      };

      await EnergySystemSettingsService.updateSettingType(
        widget.uid,
        'notification',
        settingData,
      );

      setState(() {
        _originalEmail = _emailController.text;
        _originalPhone = _phoneController.text;
        _originalEmailNotification = _emailNotification;
        _originalSmsNotification = _smsNotification;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully'),
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
      _emailController.text = _originalEmail;
      _phoneController.text = _originalPhone;
      _emailNotification = _originalEmailNotification;
      _smsNotification = _originalSmsNotification;
    });
  }

  bool _isValidEmail(String email) {
    // Simple email validation
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
                  'Notification Settings',
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
                  'Email Notification',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _emailNotification,
                      isExpanded: true,
                      dropdownColor: const Color.fromRGBO(0, 4, 51, 1),
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Poppins',
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            font: GoogleFonts.poppins(),
                          ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      items: ['Enable', 'Disable'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _emailNotification = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email Address',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
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
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Text(
                  'Separate multiple email addresses with commas.',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SMS Notification',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _smsNotification,
                      isExpanded: true,
                      dropdownColor: const Color.fromRGBO(0, 4, 51, 1),
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Poppins',
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            font: GoogleFonts.poppins(),
                          ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      items: ['Enable', 'Disable'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _smsNotification = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Phone Number',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
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
                  keyboardType: TextInputType.phone,
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
