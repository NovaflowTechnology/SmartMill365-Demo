import 'package:flutter/material.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,

    // Breadcrumb
    required this.breadcrumbs,
    this.separatorIcon = Icons.chevron_right,
    this.separatorSize = 13.0,

    // Title
    required this.title,
    this.titleStyle,

    // Count badge (optional)
    this.count,
    this.countBadgeColor,
    this.countTextStyle,

    // Subtitle (optional)
    this.subtitle,
    this.subtitleStyle,

    // Trailing widget (optional — e.g. view toggle, button)
    this.trailing,

    // Padding / spacing
    this.padding = const EdgeInsets.only(top: 20, left: 24, right: 24),
    this.breadcrumbBottomSpacing = 10.0,
    this.titleSubtitleSpacing = 2.0,
  });

  // ── Breadcrumb ──
  final List<BreadcrumbItem> breadcrumbs;
  final IconData separatorIcon;
  final double separatorSize;

  // ── Title ──
  final String title;
  final TextStyle? titleStyle;

  // ── Count badge ──
  final int? count;
  final Color? countBadgeColor;
  final TextStyle? countTextStyle;

  // ── Subtitle ──
  final String? subtitle;
  final TextStyle? subtitleStyle;

  // ── Trailing ──
  final Widget? trailing;

  // ── Layout ──
  final EdgeInsets padding;
  final double breadcrumbBottomSpacing;
  final double titleSubtitleSpacing;

  // ─────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────

  Widget _breadcrumb(BuildContext context) {
    final items = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      final crumb = breadcrumbs[i];
      final isLast = i == breadcrumbs.length - 1;

      final isLight = Theme.of(context).brightness == Brightness.light;
      final theme = FlutterFlowTheme.of(context);
      if (crumb.icon != null) {
        items.add(Icon(
          crumb.icon,
          size: 12,
          color: isLight ? theme.txtTertiary : Colors.white.withOpacity(0.25),
        ));
        items.add(const SizedBox(width: 4));
      }

      final label = Text(
        crumb.label,
        style: TextStyle(
          fontSize: 11,
          color: isLast
              ? (isLight ? theme.txtSecondary : Colors.white.withOpacity(0.4))
              : (isLight ? theme.txtTertiary : Colors.white.withOpacity(0.25)),
          fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
        ),
      );

      items.add(
        crumb.onTap != null
            ? GestureDetector(onTap: crumb.onTap, child: label)
            : label,
      );

      if (!isLast) {
        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(
            separatorIcon,
            size: separatorSize,
            color: isLight ? theme.txtMuted : Colors.white.withOpacity(0.18),
          ),
        ));
      }
    }

    return Row(children: items);
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumb ──
          _breadcrumb(context),
          SizedBox(height: breadcrumbBottomSpacing),

          // ── Title row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + count badge
                    Row(
                      children: [
                        Builder(builder: (ctx) {
                          final isLightCtx =
                              Theme.of(ctx).brightness == Brightness.light;
                          return Text(
                            title,
                            style: titleStyle ??
                                TextStyle(
                                  fontSize: 20,
                                  color: isLightCtx
                                      ? FlutterFlowTheme.of(ctx).txtPrimary
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                          );
                        }),
                      ],
                    ),

                    // Subtitle
                    if (subtitle != null) ...[
                      SizedBox(height: titleSubtitleSpacing),
                      Text(
                        subtitle!,
                        style: subtitleStyle ??
                            TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.3),
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing widget
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
