import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';

/// "Compressor Efficiency" card: one ring-gauge row per compressor showing
/// its specific energy against the benchmark band.
// Specific Energy / Role have no live backend yet (no fetch mechanism
// exists) — every row always renders "N/A"; only the configured benchmark
// band is shown for context.
class AcCompressorEfficiencyCard extends StatelessWidget {
  const AcCompressorEfficiencyCard({
    super.key,
    required this.compressors,
    this.seBandLow,
    this.seBandHigh,
  });

  final List<AcCompressor> compressors;
  final double? seBandLow;
  final double? seBandHigh;

  String get _bandRangeLabel =>
      seBandLow != null && seBandHigh != null ? '(${seBandLow!.toStringAsFixed(1)} - ${seBandHigh!.toStringAsFixed(1)})' : 'N/A';

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return DashboardCard(
      title: 'COMPRESSOR EFFICIENCY',
      trailing: Tooltip(
        message: 'kW/(m³/min) specific energy vs the $_bandRangeLabel benchmark band.',
        child: Icon(Icons.info_outline_rounded, size: 13, color: t.txtSubtle),
      ),
      child: Column(
        children: [
          for (var i = 0; i < compressors.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _EfficiencyRow(compressor: compressors[i], bandRangeLabel: _bandRangeLabel, t: t),
          ],
        ],
      ),
    );
  }
}

class _EfficiencyRow extends StatelessWidget {
  const _EfficiencyRow({required this.compressor, required this.bandRangeLabel, required this.t});

  final AcCompressor compressor;
  final String bandRangeLabel;
  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = t.txtSubtle;

    return Row(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: 0.0,
                  strokeWidth: 5,
                  backgroundColor: isLight ? const Color(0xFFE8EFF6) : const Color(0xFF1A2D4F),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              Text(
                'N/A',
                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    compressor.id,
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: isLight ? t.txtPrimary : Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: t.txtSubtle, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(
                    'N/A',
                    style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtSubtle, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'kW/(m³/min) · benchmark $bandRangeLabel',
                style: GoogleFonts.poppins(fontSize: 8.5, color: t.txtSubtle),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: accent.withOpacity(isLight ? 0.1 : 0.16), borderRadius: BorderRadius.circular(5)),
                child: Text(
                  'N/A',
                  style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
