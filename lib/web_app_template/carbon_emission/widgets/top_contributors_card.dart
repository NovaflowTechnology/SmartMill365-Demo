import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../carbon_emission_model.dart';
import 'carbon_flow_diagram.dart' show DashboardCard;

/// "Top 5 Carbon Contributors by Net Emission" ranked table with a
/// "View All" action and a footer summarizing combined share.
class TopContributorsCard extends StatelessWidget {
  const TopContributorsCard({
    super.key,
    required this.periodLabel,
    required this.contributors,
    this.onViewAll,
  });

  final String periodLabel;
  final List<CarbonContributor> contributors;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (contributors.isEmpty) {
      return DashboardCard(
        title: 'TOP CARBON CONTRIBUTORS',
        subtitle: 'by Net Emission · $periodLabel',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No contributor Device IDs configured yet. Set them in Carbon Dashboard Config.',
            style: GoogleFonts.poppins(fontSize: 11, color: t.txtMuted),
          ),
        ),
      );
    }

    final combinedShare = contributors.fold<double>(0, (s, c) => s + c.sharePercent);
    final maxEmission = contributors.map((c) => c.tco2e).reduce((a, b) => a > b ? a : b);

    return DashboardCard(
      title: 'TOP CARBON CONTRIBUTORS',
      subtitle: 'by Net Emission · $periodLabel',
      trailing: onViewAll == null
          ? null
          : InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: t.primary),
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                _headerCell('RANK', flex: 2, t: t),
                _headerCell('AREA / SYSTEM', flex: 5, t: t),
                _headerCell('EMISSION (tCO₂e)', flex: 4, t: t, align: TextAlign.right),
                _headerCell('SHARE', flex: 2, t: t, align: TextAlign.right),
              ],
            ),
          ),
          Divider(height: 1, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
          for (final c in contributors) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${c.rank}',
                      style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: t.txtMuted),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                c.area,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                              ),
                            ),
                            if (c.deviceId != null && c.deviceId!.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: t.success.withOpacity(isLight ? 0.08 : 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  c.deviceId!,
                                  style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: t.success),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: maxEmission > 0 ? (c.tco2e / maxEmission).clamp(0.0, 1.0) : 0.0,
                            minHeight: 3,
                            backgroundColor: isLight ? const Color(0xFFE8EFF6) : const Color(0xFF1A2D4F),
                            valueColor: AlwaysStoppedAnimation(t.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      c.tco2e.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${c.sharePercent.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: t.txtMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: t.success.withOpacity(isLight ? 0.06 : 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Top ${contributors.length} contributors contribute '),
                TextSpan(
                  text: '${combinedShare.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.success),
                ),
                const TextSpan(text: ' of total emission'),
              ]),
              style: GoogleFonts.poppins(fontSize: 10, color: t.txtMuted),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _headerCell(String label, {required int flex, required FlutterFlowTheme t, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: t.txtSubtle),
      ),
    );
  }
}
