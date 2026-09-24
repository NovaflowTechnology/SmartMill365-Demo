import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

import 'stationkpicard_model.dart';
export 'stationkpicard_model.dart';

class StationkpicardWidget extends StatefulWidget {
  final String equipmentName;

  const StationkpicardWidget(
      {super.key, required this.equipmentName, String? productionArea});

  @override
  State<StationkpicardWidget> createState() => _StationkpicardWidgetState();
}

class _StationkpicardWidgetState extends State<StationkpicardWidget> {
  late StationkpicardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StationkpicardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Station KPI',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Poppins',
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                Icon(
                  Icons.analytics_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 24,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          Icons.event_available,
                          color: FlutterFlowTheme.of(context).secondary,
                          size: 20,
                        ),
                        Text(
                          'Availability',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.0,
                                    font: GoogleFonts.poppins(),
                                  ),
                        ),
                      ].divide(const SizedBox(width: 8)),
                    ),
                    Text(
                      '98.5%',
                      style:
                          FlutterFlowTheme.of(context).headlineMedium.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primary,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                    ),
                  ].divide(const SizedBox(height: 8)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          Icons.timer,
                          color: FlutterFlowTheme.of(context).secondary,
                          size: 20,
                        ),
                        Text(
                          'Cycle Time',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.0,
                                    font: GoogleFonts.poppins(),
                                  ),
                        ),
                      ].divide(const SizedBox(width: 8)),
                    ),
                    Text(
                      '45 sec',
                      style:
                          FlutterFlowTheme.of(context).headlineMedium.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primary,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                    ),
                  ].divide(const SizedBox(height: 8)),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(
                          Icons.insert_chart_outlined_sharp,
                          color: Color(0xFFBB5FED),
                          size: 20,
                        ),
                        Text(
                          'Performance',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.0,
                                    font: GoogleFonts.poppins(),
                                  ),
                        ),
                      ].divide(const SizedBox(width: 8)),
                    ),
                    Text(
                      '20%',
                      style:
                          FlutterFlowTheme.of(context).headlineMedium.override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primary,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                    ),
                  ].divide(const SizedBox(height: 8)),
                ),
                Align(
                  alignment: const AlignmentDirectional(0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            color: FlutterFlowTheme.of(context).error,
                            size: 20,
                          ),
                          Text(
                            'Quality',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.0,
                                  font: GoogleFonts.poppins(),
                                ),
                          ),
                        ].divide(const SizedBox(width: 8)),
                      ),
                      Align(
                        alignment: const AlignmentDirectional(1, 0),
                        child: Text(
                          '80%',
                          textAlign: TextAlign.start,
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).primary,
                                letterSpacing: 0.0,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                      ),
                    ].divide(const SizedBox(height: 8)),
                  ),
                ),
              ],
            ),
          ].divide(const SizedBox(height: 20)),
        ),
      ),
    );
  }
}
