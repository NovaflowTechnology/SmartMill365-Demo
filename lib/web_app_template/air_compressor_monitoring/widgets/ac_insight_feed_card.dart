import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../carbon_emission/widgets/carbon_flow_diagram.dart' show DashboardCard;
import '../air_compressor_monitoring_model.dart';

/// "AI Insight" feed: a vertical list of icon-badge + message + timestamp
/// rows, with a "View All" trailing action.
class AcInsightFeedCard extends StatelessWidget {
  const AcInsightFeedCard({super.key, required this.insights, this.onViewAll});

  final List<AcInsight> insights;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DashboardCard(
      title: 'AI INSIGHT',
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
      child: insights.isEmpty
          ? _EmptyInsights(t: t)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < insights.length; i++) ...[
                  if (i > 0)
                    Divider(height: 18, color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
                  _InsightRow(insight: insights[i], t: t, isLight: isLight),
                ],
              ],
            ),
    );
  }
}

/// Shown while no insight engine is wired up yet — no live source exists to
/// generate these, so there is nothing to fabricate a placeholder from.
class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights({required this.t});

  final FlutterFlowTheme t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 24, color: t.txtSubtle),
            const SizedBox(height: 8),
            Text('No insights available', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: t.txtSubtle)),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.t, required this.isLight});

  final AcInsight insight;
  final FlutterFlowTheme t;
  final bool isLight;

  ({IconData icon, Color color}) get _visual {
    switch (insight.kind) {
      case AcInsightKind.positive:
        return (icon: Icons.trending_up_rounded, color: t.success);
      case AcInsightKind.warning:
        return (icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B));
      case AcInsightKind.info:
        return (icon: Icons.info_outline_rounded, color: isLight ? t.primary : const Color(0xFF31ECFC));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: v.color.withOpacity(isLight ? 0.12 : 0.18), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(v.icon, size: 13, color: v.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            insight.message,
            style: GoogleFonts.poppins(fontSize: 10.5, color: isLight ? t.txtSecondary : Colors.white70, height: 1.35),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          insight.time,
          style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle),
        ),
      ],
    );
  }
}
