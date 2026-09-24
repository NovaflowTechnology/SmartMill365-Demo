import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import '../models/executive_bullet.dart';
import 'report_panel_widget.dart';
import 'section_header_widget.dart';

/// Executive Summary card: bullet list on the left, a plant photo + status
/// panel on the right (stacks vertically below ~800px wide).
class ExecutiveSummarySection extends StatelessWidget {
  final List<ExecutiveBullet> bullets;
  final String plantStatusLabel;
  final Color plantStatusColor;
  final String plantStatusMessage;
  final String plantImageAsset;

  /// Optional configured override (see md_insight_report_image_config.dart)
  /// — when set, this network image is used instead of [plantImageAsset].
  final String? plantImageUrl;

  const ExecutiveSummarySection({
    super.key,
    required this.bullets,
    required this.plantStatusLabel,
    required this.plantStatusMessage,
    this.plantStatusColor = Colors.red,
    this.plantImageAsset = 'assets/images/industrial.png',
    this.plantImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        final bulletList = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(number: '1', title: 'Executive Summary'),
            const SizedBox(height: 14),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                            color: b.color.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: Icon(b.icon, size: 12, color: b.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                color: theme.secondaryText,
                                height: 1.4),
                            children: [
                              TextSpan(text: b.prefix),
                              TextSpan(
                                  text: b.highlight,
                                  style: TextStyle(
                                      color: b.color,
                                      fontWeight: FontWeight.w700)),
                              TextSpan(text: b.suffix),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );

        return LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          if (!isWide) return bulletList;
          // IntrinsicHeight resolves a bounded height for the Row before
          // CrossAxisAlignment.stretch applies it to each side — without it,
          // this section (unlike the two-column chart cards) sits directly in
          // the page's unbounded-height scrolling Column, so `stretch` would
          // try to give both sides an infinite height and crash layout for
          // the rest of the page.
          //
          // ConstrainedBox gives the section a taller minimum presence even
          // when the bullet list itself is short — it still grows past this
          // if there are enough bullets to need more room.
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 340),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: bulletList),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _plantStatusPanel(context)),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Plant photo filling the whole panel, with the status card floating on
  /// top of it (anchored to the right) rather than sitting beside it.
  Widget _plantStatusPanel(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        // Every child is Positioned so none of them (in particular the photo,
        // via its natural aspect ratio) feed into this Stack's intrinsic
        // height — that let the panel end up taller than the bullet list
        // next to it. With no non-positioned children, this panel's
        // intrinsic height is 0, so IntrinsicHeight sizes the row from the
        // bullet list alone and this panel just fills whatever height that
        // is.
        children: [
          Positioned.fill(
            child: (plantImageUrl != null && plantImageUrl!.isNotEmpty)
                ? Image.network(
                    plantImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(plantImageAsset, fit: BoxFit.cover),
                  )
                : Image.asset(plantImageAsset, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5)
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _glassStatusCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Frosted-glass status card: blurs whatever's behind it (the plant
  /// graphic/backdrop) and sits on a translucent tint with a subtle light
  /// border, instead of a flat opaque box.
  Widget _glassStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.04)
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLANT STATUS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),
              Text(
                plantStatusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: plantStatusColor),
              ),
              const SizedBox(height: 10),
              Text(plantStatusMessage,
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.white70, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
