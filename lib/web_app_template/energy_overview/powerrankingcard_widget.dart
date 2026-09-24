import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/card_widget/card_widget.dart';
import 'package:flutter/material.dart';

import 'powerrankingcard_model.dart';
export 'powerrankingcard_model.dart';

class PowerrankingcardWidget extends StatefulWidget {
  final String order;
  final String title;
  final bool isLoading;
  final ValueChanged<String> onOrderChanged;
  final List<dynamic> rankingDevices;

  const PowerrankingcardWidget({
    super.key,
    required this.order,
    required this.title,
    required this.isLoading,
    required this.rankingDevices,
    required this.onOrderChanged,
  });

  @override
  State<PowerrankingcardWidget> createState() => _PowerrankingcardWidgetState();
}

class _PowerrankingcardWidgetState extends State<PowerrankingcardWidget> {
  late PowerrankingcardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PowerrankingcardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _addCommas(String s) {
    final parts = s.split('.');
    parts[0] = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final filtered = widget.rankingDevices
        .where((d) => d['device'].toString() != 'MSB')
        .toList();

    const cCyan = Color(0xFF00E5FF);

    return CardWidget(
      armLenMultiplier: 0.7,
      topPadMultiplier: 1.2,
      builder: (context, s) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                style: GoogleFonts.poppins(
                    fontSize: s.titleFs,
                    fontWeight: FontWeight.w400,
                    color: isLight ? theme.txtPrimary : Colors.white,
                    letterSpacing: 0.5,
                    shadows: isLight ? null : [Shadow(color: cCyan.withOpacity(0.6), blurRadius: 10)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  widget.order == 'asc'
                      ? Icons.arrow_circle_up
                      : Icons.arrow_circle_down,
                  size: s.titleFs * 1.2,
                  color: cCyan,
                ),
                onPressed: () => widget.onOrderChanged(
                    widget.order == 'asc' ? 'desc' : 'asc'),
              ),
            ],
          ),
          SizedBox(height: s.pad * 0.4),

          // ── Table ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary.withOpacity(0.5)),
              ),
              child: widget.isLoading
                  ? Center(child: CircularProgressIndicator(
                      color: cCyan, strokeWidth: s.strokeW * 2))
                  : Column(
                      children: [
                        // Table header
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: s.pad * 0.7,
                              vertical: s.pad * 0.3),
                          child: Row(
                            children: [
                              SizedBox(width: s.bodyFs * 1.6 + s.pad * 0.3),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Equipment',
                                  style: GoogleFonts.poppins(
                                    fontSize: s.labelFs,
                                    color: theme.info,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'kWh',
                                  style: GoogleFonts.poppins(
                                    fontSize: s.labelFs,
                                    color: theme.info,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: theme.primary.withOpacity(0.3)),

                        // Table rows
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final device = filtered[i];
                              final rank   = i + 1;

                              // Rank badge colour
                              final rankColor = rank == 1
                                  ? const Color(0xFFFFD600)   // gold
                                  : rank == 2
                                      ? const Color(0xFFCBD5E1) // silver
                                      : rank == 3
                                          ? const Color(0xFFFF6D00) // bronze
                                          : theme.primaryText.withOpacity(0.45);

                              return Column(
                                children: [
                                  Container(
                                    color: i.isEven
                                        ? theme.primaryBackground.withOpacity(0.5)
                                        : Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: s.pad * 0.7,
                                        vertical: s.pad * 0.28),
                                    child: Row(
                                      children: [
                                        // Rank badge
                                        SizedBox(
                                          width: s.bodyFs * 1.6,
                                          child: Text(
                                            '#$rank',
                                            style: GoogleFonts.poppins(
                                              fontSize: s.bodyFs * 0.75,
                                              color: rankColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: s.pad * 0.3),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            device['device'].toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: s.bodyFs,
                                              color: theme.primaryText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            _addCommas(device['total_energy']
                                                .toStringAsFixed(3)),
                                            style: GoogleFonts.poppins(
                                              fontSize: s.bodyFs * 0.85,
                                              color: rank <= 3
                                                  ? rankColor
                                                  : theme.primaryText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (i < filtered.length - 1)
                                    Divider(
                                      height: 1,
                                      color: theme.primary.withOpacity(0.12),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
        );
      },
    );
  }
}