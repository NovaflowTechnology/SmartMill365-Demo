import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/user_presence.dart';
import '/flutter_flow/session_storage.dart';
import '/flutter_flow/nav_pages.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_page_model.dart';
export 'login_page_model.dart';
import 'package:smartmachine365/login_page/fogotPass.dart';
import 'package:smartmachine365/login_page/cyberpunk_warning_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget>
    with TickerProviderStateMixin {
  late LoginPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginPageModel());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRememberMe();
      safeSetState(() {});
    });

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.0, 140.0),
            end: const Offset(0.0, 0.0),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.9, 1.0),
            end: const Offset(1.0, 1.0),
          ),
          TiltEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(-0.349, 0),
            end: const Offset(0, 0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

void _checkRememberMe() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool rememberMe = prefs.getBool('remember_me') ?? false;

  if (rememberMe) {
    String email = prefs.getString('email') ?? '';
    String password = prefs.getString('password') ?? '';

    if (email.isNotEmpty && password.isNotEmpty) {
      // Only update if the email field is not focused and the text is different.
      if (!_model.emailAddressFocusNode!.hasFocus &&
          _model.emailAddressTextController.text != email) {
        _model.emailAddressTextController!.value = TextEditingValue(
          text: email,
          selection: TextSelection.collapsed(offset: email.length),
        );
      }
      // Do the same for the password field.
      if (!_model.passwordFocusNode!.hasFocus &&
          _model.passwordTextController.text != password) {
        _model.passwordTextController!.value = TextEditingValue(
          text: password,
          selection: TextSelection.collapsed(offset: password.length),
        );
      }
    }
  }
}


  void _login() async {
    if (_isLoggingIn) return;
    if (mounted) safeSetState(() => _isLoggingIn = true);
    // Generate this browser's unique session_id up front. Stored in Firestore
    // (presence/{uid}.session_id) and in SessionStorage so the single-session
    // check is based on a real per-login token rather than a shared boolean.
    final newSessionId = UserPresence.generateSessionId();
    // Block the auth-state listener from auto-starting presence on this
    // browser the moment Firebase confirms the sign-in — otherwise it would
    // race ahead and write our session_id BEFORE we've checked Firestore for
    // an existing one, making the check always pass against itself.
    UserPresence.suspendAutoStart = true;
    try {
      // 1. Capture clean inputs
      final email = _model.emailAddressTextController.text.trim();
      final password = _model.passwordTextController.text; // NO mangling/sanitizing

      if (email.isEmpty || password.isEmpty) return;

      // Always persist auth across tabs/windows so copy-pasting the URL works.
      // setPersistence is a web-only concept — native platforms already
      // persist the signed-in session on disk by default.
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }

      final user = await authManager.signInWithEmail(
        context,
        email,
        password,
      );

      if (user != null) {
        bool allowMultipleLogins = false;
        // Check if this account has been disabled by a Super Admin
        try {
          final disabledDoc = await FirebaseFirestore.instance
              .collection('account_status')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5));
          if (disabledDoc.exists && disabledDoc.data()?['disabled'] == true) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              showCyberpunkWarningToast(
                context,
                'Your account has been disabled. Contact your administrator.',
              );
            }
            return;
          }
          allowMultipleLogins = disabledDoc.data()?['allow_multiple_logins'] == true;
        } catch (_) {
          // Firestore unreachable — allow login (fail open)
        }

        // Single-session enforcement: block if another browser already holds
        // an active session_id for this account. A session is "active" when
        // presence/{uid}.session_id is non-empty AND last_seen is fresh.
        // Logout clears session_id so the next login is immediately allowed;
        // a crashed browser stales out after freshSeconds (~40 s).
        try {
          final presenceDoc = await FirebaseFirestore.instance
              .collection('presence')
              .doc(user.uid)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 5));
          if (presenceDoc.exists) {
            final data = presenceDoc.data();
            final existingSessionId = data?['session_id']?.toString();
            final lastSeen = data?['last_seen'] as Timestamp?;
            final isFresh = lastSeen != null &&
                DateTime.now()
                        .difference(lastSeen.toDate())
                        .inSeconds <=
                    UserPresence.freshSeconds;
            if (!allowMultipleLogins &&
                existingSessionId != null &&
                existingSessionId.isNotEmpty &&
                isFresh) {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                showCyberpunkWarningToast(
                  context,
                  'This account is already logged in on another device. Please log out there first.',
                );
              }
              return;
            }
          }
        } catch (_) {
          // Firestore unreachable — fail open and allow login
        }

        // Check passed — claim presence with our session_id.
        UserPresence.suspendAutoStart = false;
        final uid = user.uid;
        if (uid != null && uid.isNotEmpty) {
          await UserPresence.goOnline(uid, sessionId: newSessionId);
          // Persist the session_id locally so future loads recognize this tab
          // as the holder of the session.
          SessionStorage.updateSessionId(newSessionId);
        }

        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          await prefs.setString('email', email);
          await prefs.setString('password', password);
        } else {
          SharedPreferences prefs =   await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', false);
        }
        // Navigate to the user's preferred landing page.
        String homeRoute = 'EquipmentOverview';
        try {
          final rolesDoc = await FirebaseFirestore.instance
              .collection('roles')
              .doc(currentUserUid)
              .get();
          final data = rolesDoc.data() ?? {};
          final savedPage = data['landing_page'] as String?;
          final modules = (data['accessible_modules'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];
          final role = data['name'] as String? ?? '';
          homeRoute = resolveHomePage(savedPage, modules, role);
        } catch (_) {}
        if (context.mounted) context.goNamedAuth(homeRoute, context.mounted);
      }
    } catch (e) {
      // General safety fallback if FirebaseAuthManager didn't show the error
      if (mounted) {
        showCyberpunkWarningToast(context, 'Unexpected error: ${e.toString()}');
      }
    } finally {
      // Always re-enable the auth-listener auto-start so future logins
      // (including refreshes / route restores) behave normally.
      UserPresence.suspendAutoStart = false;
      if (mounted) safeSetState(() => _isLoggingIn = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void sendPasswordReset(String email) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    try {
      email = email.trim();
      await auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      // Password reset email failed silently
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ForgotPasswordDialog(onForgotPassword: sendPasswordReset);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.asset(
                'assets/images/Login.png',
              ).image,
            ),
            gradient: LinearGradient(
              colors: [
                FlutterFlowTheme.of(context).primary,
                FlutterFlowTheme.of(context).tertiary
              ],
              stops: const [0.0, 1.0],
              begin: const AlignmentDirectional(0.87, -1.0),
              end: const AlignmentDirectional(-0.87, 1.0),
            ),
          ),
          alignment: const AlignmentDirectional(0.0, -1.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0, 70.0, 0.0, 32.0),
                  child: Container(
                    width: 200.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    alignment: const AlignmentDirectional(0.0, 0.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 570.0,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4.0,
                          color: Color(0x33000000),
                          offset: Offset(
                            0.0,
                            2.0,
                          ),
                        )
                      ],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Align(
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.0,
                                    font: GoogleFonts.poppins(),
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 24.0),
                              child: Text(
                                'Fill out the information below in order to access your account.',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.0,
                                      font: GoogleFonts.poppins(),
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.emailAddressTextController,
                                  focusNode: _model.emailAddressFocusNode,
                                  autofocus: true,
                                  autofillHints: const [AutofillHints.email],
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily: 'Poppins',
                                          letterSpacing: 0.0,
                                          font: GoogleFonts.poppins(),
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.0,
                                        font: GoogleFonts.poppins(),
                                      ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _model
                                      .emailAddressTextControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.passwordTextController,
                                  focusNode: _model.passwordFocusNode,
                                  autofocus: false,
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: !_model.passwordVisibility,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily: 'Poppins',
                                          letterSpacing: 0.0,
                                          font: GoogleFonts.poppins(),
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                    suffixIcon: InkWell(
                                      onTap: () {
                                        safeSetState(() {
                                          _model.passwordVisibility =
                                              !_model.passwordVisibility;
                                        });
                                        // Ensure the password field is active before modifying it
                                        FocusScope.of(context).requestFocus(
                                            _model.passwordFocusNode);
                                      },
                                      focusNode: FocusNode(skipTraversal: true),
                                      child: Icon(
                                        _model.passwordVisibility
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.0,
                                        font: GoogleFonts.poppins(),
                                      ),
                                  validator: _model
                                      .passwordTextControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 16.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 44.0,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoggingIn ? null : () => _login(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).primary,
                                    disabledBackgroundColor:
                                        FlutterFlowTheme.of(context)
                                            .primary
                                            .withOpacity(0.7),
                                    elevation: 3.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: _isLoggingIn
                                        ? Row(
                                            key: const ValueKey('loading'),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'AUTHENTICATING...',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      fontFamily: 'Poppins',
                                                      color: Colors.white,
                                                      letterSpacing: 1.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      font: GoogleFonts
                                                          .poppins(),
                                                    ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Sign In',
                                            key: const ValueKey('label'),
                                            style: FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.white,
                                                  letterSpacing: 0.0,
                                                  font: GoogleFonts.poppins(),
                                                ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value!;
                                    });
                                  },
                                ),
                                const Text('Remember Me'),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 12.0),
                              child: RichText(
                                textScaler: MediaQuery.of(context).textScaler,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Forgot Password?',
                                      style: const TextStyle(),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _showForgotPasswordDialog(context);
                                        },
                                    ),
                                    TextSpan(
                                      text: '',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Poppins',
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            font: GoogleFonts.poppins(),
                                          ),
                                    )
                                  ],
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.0,
                                        font: GoogleFonts.poppins(),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animateOnPageLoad(
                      animationsMap['containerOnPageLoadAnimation']!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
