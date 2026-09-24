import 'package:smartmachine365/services/app_config.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '../../../components/page_header/breadcrumb_item.dart';
import '../../../components/page_header/page_header_widget.dart';

// Firestore path: password_change_requests/{uid}
// Fields: status ('pending'|'approved'|'declined'|'completed'),
//         declineCount, lockedUntil, requestedAt, approvedAt, approvedBy

class ProfileSettingsWidget extends StatefulWidget {
  const ProfileSettingsWidget({super.key});

  @override
  State<ProfileSettingsWidget> createState() => _ProfileSettingsWidgetState();
}

class _ProfileSettingsWidgetState extends State<ProfileSettingsWidget> {
  static const _cyan  = Color(0xFF31ECFC);
  static const _green = Color(0xFF24D18A);
  static const _red   = Color(0xFFEF5350);
  static const _amber = Color(0xFFFFA726);

  static String get _apiBase => AppConfig.apiBase;

  Map<String, dynamic> _profile = {};
  bool _loadingProfile = false;

  // Request state
  String   _requestStatus = 'none';
  int      _declineCount  = 0;
  DateTime? _lockedUntil;
  bool     _loadingRequest = false;
  bool     _submitting     = false;

  // OTP form — shown when approved
  final _otpCtrl         = TextEditingController();
  final _newPwCtrl       = TextEditingController();
  final _confirmPwCtrl   = TextEditingController();
  final _formKey         = GlobalKey<FormState>();
  bool  _obscureNew      = true;
  bool  _obscureConfirm  = true;
  bool  _verifying       = false;
  String? _otpError;

  final _pwRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  String get _uid => AppStateNotifier.instance.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRequestStatus();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      if (_uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('roles')
            .doc(_uid)
            .get();
        if (doc.exists && mounted) {
          setState(() => _profile = doc.data() ?? {});
        }
      }
    } catch (e) {
      debugPrint('ProfileSettings load: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadRequestStatus() async {
    if (_uid.isEmpty) return;
    setState(() => _loadingRequest = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_change_requests')
          .doc(_uid)
          .get();
      if (mounted) {
        if (!doc.exists) {
          setState(() => _requestStatus = 'none');
        } else {
          final data        = doc.data()!;
          final status      = data['status']?.toString() ?? 'none';
          final declineCount = (data['declineCount'] as int?) ?? 0;
          final lockedTs    = data['lockedUntil'] as Timestamp?;
          final lockedUntil = lockedTs?.toDate();

          // If locked but time has passed — reset to none
          if (status == 'declined' &&
              lockedUntil != null &&
              DateTime.now().isAfter(lockedUntil)) {
            await FirebaseFirestore.instance
                .collection('password_change_requests')
                .doc(_uid)
                .delete();
            setState(() {
              _requestStatus = 'none';
              _declineCount  = 0;
              _lockedUntil   = null;
            });
          } else {
            setState(() {
              _requestStatus = status;
              _declineCount  = declineCount;
              _lockedUntil   = lockedUntil;
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRequest = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_uid.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final email       = AppStateNotifier.instance.userEmail ?? '';
      final displayName = AppStateNotifier.instance.userName ?? '';

      await FirebaseFirestore.instance
          .collection('password_change_requests')
          .doc(_uid)
          .set({
        'status':       'pending',
        'requestedAt':  FieldValue.serverTimestamp(),
        'uid':          _uid,
        'email':        email,
        'displayName':  displayName,
        'declineCount': _declineCount, // preserve existing count
      });

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type':        'password_change_request',
        'uid':         _uid,
        'displayName': displayName,
        'email':       email,
        'status':      'unread',
        'createdAt':   FieldValue.serverTimestamp(),
        'targetRoles': ['Super Admin', 'Admin'],
      });

      if (mounted) setState(() => _requestStatus = 'pending');
    } catch (e) {
      _snack('Failed to submit request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelRequest() async {
    if (_uid.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('password_change_requests')
          .doc(_uid)
          .delete();
      if (mounted) setState(() => _requestStatus = 'none');
    } catch (e) {
      _snack('Failed to cancel request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtpAndChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _verifying = true;
      _otpError  = null;
    });
    try {
      final r = await http.post(
        Uri.parse('$_apiBase/password-reset/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid':         _uid,
          'otp':         _otpCtrl.text.trim(),
          'newPassword': _newPwCtrl.text,
        }),
      );

      final body = jsonDecode(r.body) as Map<String, dynamic>;

      if (r.statusCode == 200) {
        _otpCtrl.clear();
        _newPwCtrl.clear();
        _confirmPwCtrl.clear();
        // Mark request completed in Firestore so admin sees updated status
        FirebaseFirestore.instance
            .collection('password_change_requests')
            .doc(_uid)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
        if (mounted) {
          setState(() => _requestStatus = 'none');
          _snack('Password updated successfully!');
        }
      } else {
        final msg = body['error']?.toString() ?? 'Something went wrong.';
        if (mounted) setState(() => _otpError = msg);
      }
    } catch (e) {
      if (mounted) setState(() => _otpError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final color = isError ? _red : _green;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg, style: TextStyle(color: color, fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFF1A2035),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t      = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor   = isDark ? const Color(0xFF1E293B) : t.secondaryBackground;
    final strokeColor = isDark ? const Color(0xFF334155) : t.cardStroke;
    final bgColor     = isDark ? const Color(0xFF0F172A) : t.primaryBackground;

    final name    = AppStateNotifier.instance.userName ??
        _profile['display_name']?.toString() ?? '—';
    final email   = AppStateNotifier.instance.userEmail ??
        _profile['email']?.toString() ?? '—';
    final role    = AppStateNotifier.instance.userRole ??
        _profile['name']?.toString() ?? '—';
    final phone   = _profile['phone']?.toString() ?? '—';
    final initial = name.isNotEmpty && name != '—' ? name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset('assets/images/backgroundanimated.gif').image),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            breadcrumbs: [
              BreadcrumbItem(label: 'Account', icon: Icons.person_outline),
              BreadcrumbItem(label: 'Profile Settings'),
            ],
            title: 'Profile Settings',
            subtitle: 'View your profile and manage your password.',
          ),
          Expanded(
            child: _loadingProfile
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _cyan, strokeWidth: 2))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Account Info ──────────────────────────────
                            _card(
                              t: t,
                              cardColor: cardColor,
                              stroke: strokeColor,
                              icon: Icons.person_outline,
                              title: 'Account Information',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _avatarWidget(name, initial, role),
                                  const SizedBox(height: 24),
                                  _infoRow(t, Icons.email_outlined, 'Email', email),
                                  const SizedBox(height: 10),
                                  _infoRow(t, Icons.phone_outlined, 'Phone', phone),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Change Password ───────────────────────────
                            _card(
                              t: t,
                              cardColor: cardColor,
                              stroke: strokeColor,
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              child: _buildPasswordSection(
                                  t, cardColor, strokeColor, isDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Password section ──────────────────────────────────────────────────────

  Widget _buildPasswordSection(FlutterFlowTheme t, Color cardColor,
      Color strokeColor, bool isDark) {
    if (_loadingRequest) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: _cyan, strokeWidth: 2),
      ));
    }

    // Locked — declined 3x, must wait until tomorrow
    if (_requestStatus == 'declined' && _lockedUntil != null &&
        DateTime.now().isBefore(_lockedUntil!)) {
      return _requestLocked(t);
    }

    switch (_requestStatus) {
      case 'none':
        return _requestNone(t);
      case 'pending':
        return _requestPending(t);
      case 'approved':
        return _requestApproved(t, cardColor, strokeColor, isDark);
      case 'declined':
        return _requestDeclined(t);
      case 'completed':
        return _requestNone(t); // reset to none after completed
      default:
        return _requestNone(t);
    }
  }

  // ── State widgets ─────────────────────────────────────────────────────────

  Widget _requestNone(FlutterFlowTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner(
            t,
            _cyan,
            Icons.info_outline,
            'To change your password, submit a request to the admin. '
            'Once approved, you will receive an OTP code via email to verify.',
          ),
          const SizedBox(height: 20),
          Center(
            child: _filledBtn(
              label: _submitting ? 'Submitting…' : 'Request Password Change',
              icon: Icons.send_outlined,
              color: _cyan,
              loading: _submitting,
              onTap: _submitRequest,
            ),
          ),
        ],
      );

  Widget _requestPending(FlutterFlowTheme t) => Column(
        children: [
          _infoBanner(
            t,
            _amber,
            Icons.hourglass_top_rounded,
            'Your password change request is awaiting admin approval. '
            'You will receive an OTP email once approved.',
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _submitting ? null : _cancelRequest,
              icon: const Icon(Icons.cancel_outlined, size: 15),
              label: Text(_submitting ? 'Cancelling…' : 'Cancel Request'),
              style: TextButton.styleFrom(foregroundColor: _red),
            ),
          ),
        ],
      );

  Widget _requestDeclined(FlutterFlowTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner(
            t,
            _red,
            Icons.cancel_outlined,
            'Your request was declined by the admin. '
            'You may submit a new request '
            '($_declineCount/3 attempts used).',
          ),
          const SizedBox(height: 20),
          Center(
            child: _filledBtn(
              label: _submitting ? 'Submitting…' : 'Request Again',
              icon: Icons.refresh_outlined,
              color: _amber,
              loading: _submitting,
              onTap: _submitRequest,
            ),
          ),
        ],
      );

  Widget _requestLocked(FlutterFlowTheme t) {
    final until = _lockedUntil;
    final timeStr = until != null
        ? '${until.day}/${until.month}/${until.year}'
        : 'besok';
    return _infoBanner(
      t,
      _red,
      Icons.lock_clock_outlined,
      'You have been declined 3 times today. '
      'Please try again on $timeStr.',
    );
  }

  Widget _requestApproved(FlutterFlowTheme t, Color cardColor, Color stroke,
      bool isDark) {
    final fieldFill = isDark ? const Color(0xFF0F172A) : t.primaryBackground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoBanner(
          t,
          _green,
          Icons.mark_email_read_outlined,
          'Your request has been approved! An OTP code has been sent to your email. '
          'Enter the OTP code and your new password below.',
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              // OTP field
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                    color: t.primaryText,
                    fontSize: 22,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your OTP code';
                  if (v.length != 6) return 'OTP must be 6 digits';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'OTP Code (6 digits)',
                  labelStyle: TextStyle(color: t.txtMuted, fontSize: 13),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: stroke)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: stroke)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _cyan, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: t.error)),
                  focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: t.error, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              // New password
              _pwField(t, fieldFill, stroke, _newPwCtrl, 'New Password',
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!_pwRegex.hasMatch(v)) {
                  return 'Min 8 chars, uppercase, lowercase, digit & symbol';
                }
                return null;
              }),
              const SizedBox(height: 12),
              // Confirm password
              _pwField(t, fieldFill, stroke, _confirmPwCtrl,
                  'Confirm New Password', _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) => v != _newPwCtrl.text
                      ? 'Passwords do not match'
                      : null),
              if (_otpError != null) ...[
                const SizedBox(height: 12),
                _banner(_red, Icons.error_outline, _otpError!),
              ],
              const SizedBox(height: 20),
              Center(
                child: _filledBtn(
                  label: _verifying ? 'Verifying…' : 'Verify OTP & Save',
                  icon: Icons.verified_outlined,
                  color: _cyan,
                  loading: _verifying,
                  onTap: _verifyOtpAndChangePassword,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _infoBanner(FlutterFlowTheme t, Color color, IconData icon,
          String message) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style:
                      TextStyle(color: t.txtMuted, fontSize: 13, height: 1.55)),
            ),
          ],
        ),
      );

  Widget _avatarWidget(String name, String initial, String role) {
    final rc = _roleColor(role);
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [rc.withOpacity(0.25), rc.withOpacity(0.07)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: rc.withOpacity(0.45), width: 2),
          ),
          child: Center(
            child: Text(initial,
                style: TextStyle(
                    color: rc, fontSize: 26, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        Text(name,
            style: TextStyle(
                color: _roleColor(role),
                fontSize: 18,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        _roleBadge(role),
      ],
    );
  }

  Widget _card({
    required FlutterFlowTheme t,
    required Color cardColor,
    required Color stroke,
    required IconData icon,
    required String title,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _cyan, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: t.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ]),
            Divider(color: stroke, height: 24),
            child,
          ],
        ),
      );

  Widget _infoRow(FlutterFlowTheme t, IconData icon, String label,
          String value) =>
      Row(children: [
        Icon(icon, color: t.txtMuted, size: 16),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: t.txtMuted, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: t.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ]);

  Widget _roleBadge(String role) {
    final c = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(role,
          style:
              TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _roleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('super')) return const Color(0xFFAB47BC);
    if (r.contains('admin')) return const Color(0xFFEF5350);
    if (r.contains('manager')) return const Color(0xFF42A5F5);
    if (r.contains('engineer')) return const Color(0xFF26C6A6);
    if (r.contains('technician')) return const Color(0xFFFFA726);
    return const Color(0xFF78909C);
  }

  Widget _pwField(
    FlutterFlowTheme t,
    Color fill,
    Color stroke,
    TextEditingController ctrl,
    String label,
    bool obscure,
    VoidCallback toggle, {
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: t.primaryText, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.txtMuted, fontSize: 13),
          filled: true,
          fillColor: fill,
          suffixIcon: IconButton(
            icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: t.txtMuted,
                size: 18),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: stroke)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: stroke)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cyan, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.error, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  Widget _banner(Color color, IconData icon, String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(msg, style: TextStyle(color: color, fontSize: 12))),
        ]),
      );

  Widget _filledBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool loading = false,
  }) =>
      FilledButton.icon(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          disabledBackgroundColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: loading
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
