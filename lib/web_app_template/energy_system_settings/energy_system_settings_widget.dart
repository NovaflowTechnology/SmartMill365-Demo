import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/energy_system_settings/contract_capacity_settings.dart' show ContractCapacitySettings;
import 'package:smartmachine365/web_app_template/energy_system_settings/notification_settings.dart' show NotificationSettings;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EnergySystemSettingsWidget extends StatefulWidget {
  const EnergySystemSettingsWidget({super.key});

  @override
  State<EnergySystemSettingsWidget> createState() => _EnergySystemSettingsWidgetState();
}

class _EnergySystemSettingsWidgetState extends State<EnergySystemSettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStateNotifier = AppStateNotifier.instance;
    final userUid = appStateNotifier.uid ?? ' ';  
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
                child: Text(
                  'Dashboard/EnergySystemSettings',
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 12,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
              ),

              // Page Title
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
                child: Text(
                  'Energy System Settings',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                        fontFamily: 'Poppins',
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
              ),

              // Settings Panels in Responsive Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  // Determine number of columns based on screen width
                  int crossAxisCount = 1;
                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 3; // 3 columns for large screens
                  } else if (constraints.maxWidth >= 768) {
                    crossAxisCount = 2; // 2 columns for medium screens
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 3 ? 0.85 : 1.0,
                    children: [
                      ContractCapacitySettings(
                        uid: userUid,
                      ),
                    
                      NotificationSettings(
                        uid: userUid,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
