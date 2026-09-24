import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart'; // Import the provider package
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:smartmachine365/flutter_flow/nav/main_layout_cubit.dart';
import 'web_app_template/real_time_data_config/cubits/discovery_cubit.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/session_storage.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import '/flutter_flow/nav/user_provider.dart';
import '/services/app_config.dart';

import '/flutter_flow/nav/router_tracker.dart';
import 'package:smartmachine365/utils/crash_guard.dart';
import 'package:smartmachine365/utils/memory_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  await FlutterFlowTheme.initialize();
  await AppConfig.init();

  // A failing widget collapses to a placeholder instead of blanking the screen.
  installCrashGuard();

  // Reloads the tab before the browser runs it out of memory, and only while
  // the screen is idle. Growth is not stopped by this — a crash is.
  memoryGuard.start();

  // Navigation is what actually drives this app's memory up, so the guard has
  // to see it. routeTracker already fires on every route change.
  routeTracker.addListener(
      () => memoryGuard.noteNavigation(routeTracker.currentRoute));

  runApp(
    Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => memoryGuard.noteInteraction(),
      onPointerSignal: (_) => memoryGuard.noteInteraction(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});
  String? _lastUid;
  final _discoveryCubit = DiscoveryCubit();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    // When a user logs in (or session restores), apply their saved theme.
    _appStateNotifier.onThemeRestore = (mode) {
      if (mounted) safeSetState(() => _themeMode = mode);
    };
    _router = createRouter(_appStateNotifier);
    userStream = smartmachine365FirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
        final uid = user.uid;
        if (uid != _lastUid) {
          _lastUid = uid;
          if (uid != null && uid.isNotEmpty) {
            AppConfig.initForUser(user.email ?? '', uid: uid);
          }
          _discoveryCubit.onUserChanged();
        }
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();
    _discoveryCubit.close();
    super.dispose();
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
        SessionStorage.saveSetting(
            'theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
      });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(), // Provide the UserProvider
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => MainLayoutCubit()),
          BlocProvider.value(value: _discoveryCubit),
        ],
        child: MaterialApp.router(
          title: 'SMARTFACTORY365',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            );
          },
          localizationsDelegates: const [
            FFLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationDelegate(),
            FallbackCupertinoLocalizationDelegate(),
          ],
          locale: _locale,
          supportedLocales: const [
            Locale('en'),
          ],
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: false,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: false,
          ),
          themeMode: _themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
