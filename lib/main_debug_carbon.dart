import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'web_app_template/carbon_emission/carbon_emission_widget.dart';

/// Temporary standalone entrypoint used to render CarbonEmissionWidget in
/// isolation (no Firebase/auth/router) for debugging. Not part of the app.
/// Includes a 270px placeholder to simulate the real app's SideNavWidget,
/// since MainLayout reduces available content width by that much when a
/// user is logged in.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await FlutterFlowTheme.initialize();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Row(
        children: [
          Container(width: 270, color: const Color(0xFF0D1A2E)),
          const Expanded(child: CarbonEmissionWidget()),
        ],
      ),
    ),
  ));
}
