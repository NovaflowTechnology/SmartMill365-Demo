import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/sankey_energy_flow/sankey_flow_service.dart';
import 'package:smartmachine365/web_app_template/sankey_energy_flow/widgets/echarts_sankey_widget.dart';

class SankeyEnergyFlow extends StatefulWidget {
  const SankeyEnergyFlow({super.key});

  @override
  State<SankeyEnergyFlow> createState() => _SankeyEnergyFlowState();
}

class _SankeyEnergyFlowState extends State<SankeyEnergyFlow> {
  SankeyFlowData? _data;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool forceRebuildTemplate = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await SankeyFlowService.load(
        forceRebuildTemplate: forceRebuildTemplate,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: t.primaryBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Breadcrumb ────────────────────────────────────────────────
            Row(children: [
              Icon(Icons.home_outlined,
                  size: 13, color: t.secondaryText.withOpacity(0.45)),
              const SizedBox(width: 4),
              Text('Dashboard',
                  style: GoogleFonts.poppins(
                      color: t.secondaryText.withOpacity(0.5), fontSize: 12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.chevron_right,
                    size: 13, color: t.secondaryText.withOpacity(0.3)),
              ),
              Text('Sankey Energy Flow',
                  style: GoogleFonts.poppins(
                      color: t.secondaryText.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),

            // ── Page header ───────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: t.primary.withOpacity(0.25)),
                ),
                child: Center(
                    child: Icon(Icons.account_tree_outlined,
                        size: 20, color: t.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sankey Energy Flow',
                          style: GoogleFonts.poppins(
                              color: t.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      Text('Real-time facility power distribution diagram',
                          style: GoogleFonts.poppins(
                              color: t.secondaryText, fontSize: 13)),
                    ]),
              ),
              // Status chip
              if (_data != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.primary.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.primary,
                        boxShadow: [
                          BoxShadow(
                              color: t.primary.withOpacity(0.6), blurRadius: 4)
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Updated ${_fmt(_data!.fetchedAt)}',
                        style: GoogleFonts.poppins(
                            color: t.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              const SizedBox(width: 8),
              // Refresh button
              InkWell(
                onTap: _loading ? null : _fetch,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.primary.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.8, color: t.primary))
                        : Icon(Icons.refresh, color: t.primary, size: 18),
                  ),
                ),
              ),
            ]),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child:
                  Divider(color: t.primary.withOpacity(0.12), thickness: 0.5),
            ),

            // ── Data status info (shows why data is empty) ─────────────────
            if (!_loading && _data != null && _data!.nodes.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No data returned from server',
                            style: GoogleFonts.poppins(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(
                          'Make sure: (1) Master Facility has data, '
                          '(2) Devices/meter IDs are assigned, '
                          '(3) Your account UID is authenticated. '
                          'If Sankey settings are empty, template will be '
                          'auto-generated from Master Facility.',
                          style: GoogleFonts.poppins(
                              color: Colors.amber.withOpacity(0.7),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

            // ── Chart ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: _cardHeight(context),
              child: CardWidget(
                glowColor: t.primary,
                topPadMultiplier: 1.05,
                bottomPadMultiplier: 0.65,
                armLenMultiplier: 0.85,
                builder: (_, __) => _buildChart(context, t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, FlutterFlowTheme t) {
    // Loading
    if (_loading) {
      return SizedBox(
        height: 480,
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: t.primary, strokeWidth: 2),
          const SizedBox(height: 14),
          Text('Loading energy flow data…',
              style: GoogleFonts.poppins(color: t.secondaryText, fontSize: 12)),
        ])),
      );
    }

    // Error
    if (_error != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: t.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.error.withOpacity(0.2)),
        ),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: t.error, size: 36),
          const SizedBox(height: 10),
          Text('Failed to load: $_error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: t.secondaryText, fontSize: 12)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                elevation: 0),
          ),
        ])),
      );
    }

    // Empty — show placeholder inside the CardWidget-styled chart container
    if (_data == null || _data!.nodes.isEmpty) {
      return const SizedBox(
        height: 400,
        child: EchartsSankeyWidget(
          nodes: [],
          links: [],
          title: 'Facility Power Distribution',
          subtitle: 'No nodes configured',
        ),
      );
    }

    // Have data
    final now = _data!.fetchedAt;
    final subtitle =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
        '  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // Responsive height: target filling the available screen height so it doesn't
    // arbitrarily stretch down too far, forcing unnecessary scrolling.
    final screenH = MediaQuery.of(context).size.height;
    // Estimate available height below the breadcrumb/header
    final availableH = screenH - 240.0;

    // Choose the remaining screen space, but provide a tiny absolute fallback
    final h = availableH < 400.0 ? 400.0 : availableH;

    return EchartsSankeyWidget(
      nodes: _data!.nodes,
      links: _data!.links,
      title: 'Facility Power Distribution',
      subtitle: subtitle,
      height: h,
    );
  }

  double _cardHeight(BuildContext context) {
    if (_loading) return 520;
    if (_error != null) return 360;
    if (_data == null || _data!.nodes.isEmpty) return 430;
    final available = MediaQuery.of(context).size.height - 250;
    if (available < 430) return 430;
    if (available > 820) return 820;
    return available;
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
