import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../models/tnb_e3_bill_simulator_model.dart';
import 'tnb_cyber_deco.dart';

class TnbFooter extends StatelessWidget {
  final String dataSource;

  const TnbFooter({super.key, this.dataSource = ''});

  String get _sourceLabel => dataSource.isNotEmpty
      ? 'Data Source: $dataSource (TNB Meter DPM ID)'
      : TnbE3BillSimulatorModel.footerSource;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final screenWidth = MediaQuery.of(context).size.width;
    final sw = screenWidth < 1000 ? 1000.0 : screenWidth;
    final isMobile = screenWidth < 600;
    const cCyan = Color(0xFF00E5FF);
    const cAmber = Color(0xFFFFC107);

    final pad = (sw * 0.010).clamp(8.0, 20.0);
    final fsNote = (sw * 0.0081).clamp(10.0, 14.0);
    final fsVer = (sw * 0.0068).clamp(9.0, 12.0);
    final iconSz = (sw * 0.0078).clamp(12.0, 16.0);
    final radius = sw * 0.005;
    final borderW = (sw * 0.0008).clamp(0.5, 2.0);
    final armLen = sw * 0.0098;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? [
                      theme.secondaryBackground.withOpacity(0.97),
                      theme.primaryBackground.withOpacity(0.97),
                    ]
                  : [
                      const Color(0xFF0A1830).withOpacity(0.88),
                      const Color(0xFF07101F).withOpacity(0.92),
                    ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cCyan.withOpacity(0.22), width: borderW),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top accent line
              Container(
                height: borderW * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      cCyan.withOpacity(0.45),
                      cAmber.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad * 1.4, vertical: pad * 0.7),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: theme.secondaryText, size: iconSz),
                              SizedBox(width: pad * 0.6),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      color: theme.secondaryText,
                                      fontSize: fsNote,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      const TextSpan(text: TnbE3BillSimulatorModel.footerNote),
                                      TextSpan(
                                        text: _sourceLabel,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF4FC3F7),
                                          fontWeight: FontWeight.w700,
                                          fontSize: fsNote,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: pad * 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: borderW,
                                height: fsVer * 2.2,
                                color: cCyan.withOpacity(0.30),
                              ),
                              SizedBox(width: pad * 0.5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SMARTFACTORY365',
                                    style: GoogleFonts.poppins(
                                      color: cCyan.withOpacity(0.65),
                                      fontSize: fsVer,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'TNB TARIFF • REV.2024',
                                    style: GoogleFonts.poppins(
                                      color: theme.secondaryText.withOpacity(0.50),
                                      fontSize: fsVer * 0.88,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.secondaryText, size: iconSz),
                          SizedBox(width: pad * 0.6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  color: theme.secondaryText,
                                  fontSize: fsNote,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  const TextSpan(text: TnbE3BillSimulatorModel.footerNote),
                                  TextSpan(
                                    text: _sourceLabel,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF4FC3F7),
                                      fontWeight: FontWeight.w700,
                                      fontSize: fsNote,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: pad),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: borderW,
                                height: fsVer * 2.2,
                                color: cCyan.withOpacity(0.30),
                              ),
                              SizedBox(width: pad * 0.5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SMARTFACTORY365',
                                    style: GoogleFonts.poppins(
                                      color: cCyan.withOpacity(0.65),
                                      fontSize: fsVer,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'TNB TARIFF • REV.2024',
                                    style: GoogleFonts.poppins(
                                      color: theme.secondaryText.withOpacity(0.50),
                                      fontSize: fsVer * 0.88,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),

        // ── Corner brackets ──────────────────────────────────────────────
        CyberpunkBrackets(
          color: cCyan.withOpacity(0.65),
          armLength: armLen * 0.7,
        ),
      ],
    );
  }
}
