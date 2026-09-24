import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/flutter_flow/nav/main_layout_cubit.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import '/web_app_template/side_nav/mobile_nav_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  /// Mobile / tablet breakpoint: anything below kBreakpointLarge (991 px).
  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < kBreakpointLarge;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateNotifier.instance;
    final mobile   = _isMobile(context);
    final theme    = FlutterFlowTheme.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => BlocBuilder<MainLayoutCubit, MainLayoutState>(
        builder: (context, state) {

          // ── Mobile / tablet ───────────────────────────────────────────────
          if (mobile) {
            final isLoggedIn = appState.userRole != null;
            return Scaffold(
              backgroundColor: theme.primaryBackground,
              drawer: isLoggedIn ? const MobileNavDrawer() : null,

              // Thin mobile top-bar: only shown after login.
              // Using appBar ensures SafeArea on inner pages works correctly
              // (Flutter zeros out MediaQuery.padding.top inside the body).
              appBar: isLoggedIn
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(52),
                      child: _MobileAppBar(),
                    )
                  : null,

              body: Container(
                color: theme.primaryBackground,
                child: child,
              ),
            );
          }

          // ── Desktop: persistent side-nav row layout ───────────────────────
          return Scaffold(
            body: Stack(
              children: [
                Row(
                  children: [
                    if (appState.userRole != null && state.showSideNav)
                      SideNavWidget(
                        name: appState.userName ?? appState.userEmail ?? '',
                        email: appState.userEmail ?? '',
                        roles: appState.userRole!,
                      ),
                    Expanded(
                      child: Container(
                        color: theme.primaryBackground,
                        child: child,
                      ),
                    ),
                  ],
                ),

                // Hover-reveal button to re-open the side nav
                Visibility(
                  visible: !state.showSideNav,
                  child: Positioned(
                    left: 8.0,
                    top: 8.0,
                    child: MouseRegion(
                      onEnter: (_) =>
                          context.read<MainLayoutCubit>().showButton(true),
                      onExit:  (_) =>
                          context.read<MainLayoutCubit>().showButton(false),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: state.showButton
                            ? FloatingActionButton.small(
                                tooltip: 'Show side bar',
                                foregroundColor: Colors.white,
                                backgroundColor: FlutterFlowTheme.of(context)
                                    .secondaryText
                                    .withAlpha(120),
                                onPressed: () {
                                  context
                                      .read<MainLayoutCubit>()
                                      .showButton(false);
                                  context
                                      .read<MainLayoutCubit>()
                                      .showSideNav(true);
                                },
                                child: const Icon(Icons.chevron_right_rounded),
                              )
                            : const SizedBox(width: 100.0, height: 100.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Mobile App Bar ────────────────────────────────────────────────────────────
class _MobileAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme   = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AppBar(
      backgroundColor:
          isLight ? theme.secondaryBackground : const Color(0xFF0D1117),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          padding: const EdgeInsets.all(8),
          icon: Icon(
            Icons.menu_rounded,
            color: theme.txtPrimary,
            size: 22,
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SMARTFACTORY365',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.txtPrimary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isLight
              ? theme.cardStroke.withOpacity(0.5)
              : const Color(0xFF21262D),
        ),
      ),
    );
  }
}
