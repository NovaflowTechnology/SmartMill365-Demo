import 'package:smartmachine365/services/app_config.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/rbac.dart';
import '../../../components/page_header/breadcrumb_item.dart';
import '../../../components/page_header/page_header_widget.dart';
import 'package:smartmachine365/services/site_tenant.dart';

Color _cardBg(FlutterFlowTheme t, BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : t.secondaryBackground;

Color _surfaceStroke(FlutterFlowTheme t, BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : t.cardStroke;

Color _pageBg(FlutterFlowTheme t, BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : t.primaryBackground;

class PasswordManagementWidget extends StatefulWidget {
  const PasswordManagementWidget({super.key});

  @override
  State<PasswordManagementWidget> createState() =>
      _PasswordManagementWidgetState();
}

class _PasswordManagementWidgetState extends State<PasswordManagementWidget> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();
  // uid → 'pending' | 'approved' | 'declined' | 'completed'
  Map<String, String> _requestStatuses = {};
  // uid → declineCount
  Map<String, int> _declineCounts = {};

  static const _cyan   = Color(0xFF31ECFC);
  static const _green  = Color(0xFF24D18A);
  static const _purple = Color(0xFFAB47BC);
  static const _red    = Color(0xFFEF5350);
  static const _blue   = Color(0xFF42A5F5);
  static const _teal   = Color(0xFF26C6A6);
  static const _amber  = Color(0xFFFFA726);
  static const _slate  = Color(0xFF78909C);

  static String get _apiBase => AppConfig.apiBase;

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_apiBase/users')),
        FirebaseFirestore.instance.collection('roles').get(),
        FirebaseFirestore.instance.collection('password_change_requests').get(),
      ]);

      final res      = results[0] as http.Response;
      final rolesSnap = results[1] as QuerySnapshot;
      final reqSnap  = results[2] as QuerySnapshot;

      final rolesMap = {
        for (final d in rolesSnap.docs) d.id: d.data() as Map<String, dynamic>
      };
      final reqMap = <String, String>{};
      final declineMap = <String, int>{};
      for (final d in reqSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        reqMap[d.id]     = data['status']?.toString() ?? '';
        declineMap[d.id] = (data['declineCount'] as int?) ?? 0;
      }

      if (res.statusCode == 200) {
        // The two customer sites keep separate account lists, and password
        // management is an account screen like any other.
        final data = SiteTenant.filter(
          (json.decode(res.body) as List<dynamic>).cast<Map<String, dynamic>>(),
          (u) => u['email']?.toString() ?? '',
        );
        final users = data.map((u) {
          final uid = u['UID']?.toString() ?? u['uid']?.toString() ?? '';
          final rd  = rolesMap[uid] ?? {};
          return {
            ...u,
            '_uid':   uid,
            '_role':  rd['name']?.toString() ?? u['role']?.toString() ?? '',
            '_email': u['email']?.toString() ?? rd['email']?.toString() ?? '',
            '_name':  rd['display_name']?.toString() ?? u['name']?.toString() ?? '',
          };
        }).toList();

        if (mounted) {
          setState(() {
            _users          = users;
            _filtered       = users;
            _requestStatuses = reqMap;
            _declineCounts  = declineMap;
          });
        }
      }
    } catch (e) {
      debugPrint('PasswordManagement fetch: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users.where((u) =>
              (u['_name'] as String).toLowerCase().contains(q) ||
              (u['_email'] as String).toLowerCase().contains(q) ||
              (u['_role'] as String).toLowerCase().contains(q)).toList();
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _approveRequest(Map<String, dynamic> user) async {
    final uid   = user['_uid'] as String;
    final email = user['_email'] as String;
    final name  = user['_name'] as String;
    if (uid.isEmpty) return;

    try {
      // 1. Update Firestore status
      await FirebaseFirestore.instance
          .collection('password_change_requests')
          .doc(uid)
          .update({
        'status':     'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': AppStateNotifier.instance.userName ?? '',
      });

      // 2. Call API to send OTP email
      final r = await http.post(
        Uri.parse('$_apiBase/password-reset/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'email': email, 'userName': name}),
      );

      if (mounted) {
        setState(() => _requestStatuses[uid] = 'approved');
        if (r.statusCode == 200) {
          _snack('Request approved — OTP sent to ${user['_email']}');
        } else {
          _snack('Approved but OTP email failed: ${r.body}', isError: true);
        }
      }
    } catch (e) {
      _snack('Failed to approve: $e', isError: true);
    }
  }

  Future<void> _declineRequest(Map<String, dynamic> user) async {
    final uid = user['_uid'] as String;
    if (uid.isEmpty) return;

    try {
      final currentCount = _declineCounts[uid] ?? 0;
      final newCount     = currentCount + 1;

      // Calculate locked until tomorrow midnight if 3 declines reached
      final now       = DateTime.now();
      final tomorrow  = DateTime(now.year, now.month, now.day + 1);
      final lockUntil = newCount >= 3
          ? Timestamp.fromDate(tomorrow)
          : null;

      final updateData = <String, dynamic>{
        'status':        'declined',
        'declinedAt':    FieldValue.serverTimestamp(),
        'declinedBy':    AppStateNotifier.instance.userName ?? '',
        'declineCount':  newCount,
      };
      if (lockUntil != null) updateData['lockedUntil'] = lockUntil;

      await FirebaseFirestore.instance
          .collection('password_change_requests')
          .doc(uid)
          .update(updateData);

      // Send lock notification email when user reaches 3 declines
      if (newCount >= 3) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final unlockDate =
            '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}';
        http.post(
          Uri.parse('$_apiBase/password-reset/notify-locked'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid':        uid,
            'email':      user['_email'],
            'userName':   user['_name'],
            'unlockDate': unlockDate,
          }),
        ).catchError((_) => http.Response('', 500));
      }

      if (mounted) {
        setState(() {
          _requestStatuses[uid] = 'declined';
          _declineCounts[uid]   = newCount;
        });
        final msg = newCount >= 3
            ? 'Request declined — user locked until tomorrow'
            : 'Request declined ($newCount/3 attempts used)';
        _snack(msg);
      }
    } catch (e) {
      _snack('Failed to decline: $e', isError: true);
    }
  }

  List<Widget> _requestActions(
      FlutterFlowTheme t, BuildContext ctx, Map<String, dynamic> user) {
    final uid    = user['_uid'] as String;
    final status = _requestStatuses[uid] ?? 'none';

    if (status == 'pending') {
      return [
        _actionBtn(
          icon:  Icons.check_circle_outline,
          label: 'Approve',
          color: _green,
          onTap: () => _approveRequest(user),
        ),
        const SizedBox(width: 6),
        _actionBtn(
          icon:  Icons.cancel_outlined,
          label: 'Decline',
          color: _red,
          onTap: () => _declineRequest(user),
        ),
        const SizedBox(width: 6),
        _statusChip('Pending', const Color(0xFFFFA726),
            Icons.hourglass_top_rounded),
      ];
    }

    if (status == 'approved') {
      return [
        _statusChip('Approved — OTP Sent', _green,
            Icons.mark_email_read_outlined),
      ];
    }

    if (status == 'declined') {
      final count = _declineCounts[uid] ?? 0;
      return [
        _statusChip(
          count >= 3 ? 'Declined — Locked' : 'Declined ($count/3)',
          _red,
          Icons.block_outlined,
        ),
      ];
    }

    if (status == 'completed') {
      return [_statusChip('Completed', _cyan, Icons.verified_outlined)];
    }

    return [];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t          = FlutterFlowTheme.of(context);
    final isSuperAdmin = AppRoles.normalizeRole(
            AppStateNotifier.instance.userRole ?? '') ==
        AppRoles.superAdmin;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _pageBg(t, context),
        image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset('assets/images/backgroundanimated.gif').image),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            breadcrumbs: [
              BreadcrumbItem(label: 'Settings', icon: Icons.settings),
              BreadcrumbItem(label: 'Password Management'),
            ],
            title: 'Password Management',
            subtitle: 'Reset or change passwords for users in your organization.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: _searchBar(t, context)),
                    const SizedBox(width: 10),
                    _toolbarBtn(t, context,
                        icon: Icons.refresh_rounded,
                        label: 'Refresh',
                        onTap: _fetch),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    '${_filtered.length} user${_filtered.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: t.txtMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: _cyan, strokeWidth: 2))
                        : _filtered.isEmpty
                            ? _emptyState(t)
                            : ListView.separated(
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, i) => _userCard(
                                    t, context, _filtered[i], isSuperAdmin),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _searchBar(FlutterFlowTheme t, BuildContext ctx) => Container(
        height: 42,
        decoration: BoxDecoration(
          color: _cardBg(t, ctx),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _surfaceStroke(t, ctx)),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(color: t.primaryText, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search by name, email or role…',
            hintStyle: TextStyle(color: t.txtMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: t.txtMuted, size: 17),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  Widget _toolbarBtn(FlutterFlowTheme t, BuildContext ctx,
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _cardBg(t, ctx),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _surfaceStroke(t, ctx)),
            ),
            child: Row(children: [
              Icon(icon, color: t.secondaryText, size: 17),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: t.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _userCard(FlutterFlowTheme t, BuildContext ctx,
      Map<String, dynamic> user, bool isSuperAdmin) {
    final name    = user['_name'] as String;
    final email   = user['_email'] as String;
    final role    = user['_role'] as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final rc      = _roleColor(role);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg(t, ctx),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceStroke(t, ctx)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          hoverColor: _cyan.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              _avatar(initial, rc),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : email,
                        style: TextStyle(
                            color: t.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(email,
                        style: TextStyle(color: t.txtMuted, fontSize: 12)),
                  ],
                ),
              ),
              _roleBadge(role, rc),
              const SizedBox(width: 14),
              Container(width: 1, height: 26, color: _surfaceStroke(t, ctx)),
              const SizedBox(width: 14),
              if (isSuperAdmin) ...[
                _actionBtn(
                    icon: Icons.lock_reset_outlined,
                    label: 'Set Password',
                    color: _cyan,
                    onTap: () => _showSetPasswordDialog(user)),
                const SizedBox(width: 8),
              ],
              ..._requestActions(t, ctx, user),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _avatar(String initial, Color rc) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [rc.withOpacity(0.22), rc.withOpacity(0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: rc.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(initial,
              style: TextStyle(
                  color: rc, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _roleBadge(String role, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          role.isEmpty ? '—' : role,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.28)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _emptyState(FlutterFlowTheme t) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_outlined, size: 48, color: t.txtSubtle),
            const SizedBox(height: 12),
            Text('No users found',
                style: TextStyle(
                    color: t.txtMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Try a different search term',
                style: TextStyle(color: t.txtSubtle, fontSize: 13)),
          ],
        ),
      );

  Future<void> _showSetPasswordDialog(Map<String, dynamic> user) async {
    final t      = FlutterFlowTheme.of(context);
    final newCtrl = TextEditingController();
    final cnfCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool ob1 = true, ob2 = true;
    String? err;

    final pwRx = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: _cardBg(t, ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _cyan.withOpacity(0.25)),
          ),
          child: SizedBox(
            width: responsiveDialogWidth(ctx, 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _cyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_outlined,
                          color: _cyan, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set New Password',
                            style: TextStyle(
                                color: t.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(
                            user['_name'].toString().isNotEmpty
                                ? user['_name'].toString()
                                : user['_email'].toString(),
                            style:
                                TextStyle(color: t.txtMuted, fontSize: 12)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Form(
                    key: formKey,
                    child: Column(children: [
                      _dlgField(t, ctx, newCtrl, 'New Password', ob1,
                          () => ss(() => ob1 = !ob1), validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!pwRx.hasMatch(v)) {
                          return 'Min 8 chars, upper, lower, digit, symbol';
                        }
                        return null;
                      }),
                      const SizedBox(height: 12),
                      _dlgField(t, ctx, cnfCtrl, 'Confirm Password', ob2,
                          () => ss(() => ob2 = !ob2),
                          validator: (v) =>
                              v != newCtrl.text ? 'Passwords do not match' : null),
                      if (err != null) ...[
                        const SizedBox(height: 10),
                        _errorBanner(t, err!),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel',
                            style: TextStyle(color: t.txtMuted)),
                      ),
                      const SizedBox(width: 8),
                      _filledBtn(
                        label: 'Set Password',
                        icon: Icons.check_rounded,
                        color: _cyan,
                        onTap: () async {
                          if (!formKey.currentState!.validate()) return;
                          final uid = user['_uid']?.toString() ?? '';
                          if (uid.isEmpty) {
                            ss(() => err = 'Cannot resolve user ID.');
                            return;
                          }
                          try {
                            final r = await http.put(
                              Uri.parse('$_apiBase/users/updateUserPassword'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'userUid': uid,
                                'newPassword': newCtrl.text,
                              }),
                            );
                            if (r.statusCode == 200) {
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              _snack('Password updated for ${user['_name']}');
                            } else {
                              ss(() => err = 'API error ${r.statusCode}');
                            }
                          } catch (e) {
                            ss(() => err = 'Error: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dlgField(
    FlutterFlowTheme t,
    BuildContext ctx,
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
        style: TextStyle(color: t.primaryText, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.txtMuted, fontSize: 13),
          filled: true,
          fillColor: _pageBg(t, ctx),
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
              borderSide: BorderSide(color: _surfaceStroke(t, ctx))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _surfaceStroke(t, ctx))),
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

  Widget _errorBanner(FlutterFlowTheme t, String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.error.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: t.error, size: 14),
          const SizedBox(width: 6),
          Expanded(
              child: Text(msg,
                  style: TextStyle(color: t.error, fontSize: 12))),
        ]),
      );

  Widget _filledBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        icon: Icon(icon, size: 15),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        onPressed: onTap,
      );

  Color _roleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('super')) return _purple;
    if (r.contains('admin')) return _red;
    if (r.contains('manager')) return _blue;
    if (r.contains('engineer')) return _teal;
    if (r.contains('technician')) return _amber;
    return _slate;
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final color = isError ? const Color(0xFFEF5350) : const Color(0xFF24D18A);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: TextStyle(color: color, fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFF1A2035),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }
}
