import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/utils/leak_probe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/rbac.dart';

import 'notification_beep_stub.dart'
    if (dart.library.html) 'notification_beep_web.dart' as beep;

// ── Firestore schema ──────────────────────────────────────────────────────────
// Collection: admin_notifications  /  Document: auto-ID
// Fields: type, uid, displayName, email, status ('unread'|'read'),
//         createdAt (Timestamp), targetRoles (List<String>)
// ─────────────────────────────────────────────────────────────────────────────

// ── Notification sound (Web Audio API) ───────────────────────────────────────

void _playNotificationBeep() => beep.playNotificationBeep();

// ── Cyberpunk-style notification toast (top-center overlay) ──────────────────

void showNotificationToast(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required Color accentColor,
  VoidCallback? onReview,
  VoidCallback? onDismiss,
  Duration duration = const Duration(seconds: 6),
}) {
  _playNotificationBeep();

  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _NotificationToast(
      title: title,
      message: message,
      icon: icon,
      accentColor: accentColor,
      duration: duration,
      onReview: onReview,
      onDismiss: onDismiss,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _NotificationToast extends StatefulWidget {
  const _NotificationToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.onDismissed,
    this.onReview,
    this.onDismiss,
  });

  final String       title;
  final String       message;
  final IconData     icon;
  final Color        accentColor;
  final Duration     duration;
  final VoidCallback onDismissed;
  final VoidCallback? onReview;
  final VoidCallback? onDismiss;

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double>   _opacity;
  late final Animation<Offset>   _offset;
  late final TimerDrivenAnimation _glowController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _glowController = TimerDrivenAnimation(
        period: const Duration(milliseconds: 2800), reverse: true);

    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 24,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _offset,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final glow = 0.4 + (_glowController.value * 0.5);
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xF00A0A1F),
                              Color(0xF014142B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: accent.withOpacity(glow),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(glow * 0.7),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: accent.withOpacity(glow * 0.35),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left neon bar
                        Container(
                          width: 3,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withOpacity(0.9),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          widget.icon,
                          color: widget.accentColor,
                          size: 22,
                          shadows: [
                            Shadow(
                              color: widget.accentColor.withOpacity(0.9),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '// ${widget.title.toUpperCase()}',
                                style: GoogleFonts.shareTechMono(
                                  color: widget.accentColor,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (widget.onReview != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _actionBtn(
                                      label: 'REVIEW',
                                      color: widget.accentColor,
                                      onTap: () {
                                        _dismiss();
                                        widget.onReview?.call();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _actionBtn(
                                      label: 'DISMISS',
                                      color: const Color(0xFFEF5350),
                                      onTap: () {
                                        _dismiss();
                                        widget.onDismiss?.call();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _dismiss,
                          child: const Icon(Icons.close,
                              color: Colors.white38, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

final Map<String, Stream<QuerySnapshot>> _adminNotificationStreamCache = {};

Stream<QuerySnapshot> _getAdminNotificationStream(String role) {
  return _adminNotificationStreamCache.putIfAbsent(
    role,
    () => FirebaseFirestore.instance
        .collection('admin_notifications')
        .where('targetRoles', arrayContains: role)
        .snapshots()
        .asBroadcastStream(),
  );
}

// ── Toast listener (place once in the widget tree for admins) ─────────────────

class NotificationToastListener extends StatefulWidget {
  final Widget child;
  const NotificationToastListener({super.key, required this.child});

  @override
  State<NotificationToastListener> createState() =>
      _NotificationToastListenerState();
}

class _NotificationToastListenerState
    extends State<NotificationToastListener> {
  StreamSubscription<QuerySnapshot>? _sub;
  final Set<String> _seenIds = {};
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub != null) return;

    final role = AppStateNotifier.instance.userRole ?? '';
    final normalised = AppRoles.normalizeRole(role);
    final isAdmin = normalised == AppRoles.superAdmin ||
        normalised == 'admin' ||
        role.toLowerCase().contains('admin');
    if (!isAdmin) return;

    _sub = FirebaseFirestore.instance
        .collection('admin_notifications')
        .where('targetRoles', arrayContains: role)
        .snapshots()
        .listen((snap) {
      // Filter unread client-side to avoid composite index requirement
      final unread = snap.docs
          .where((d) => (d.data() as Map)['status'] == 'unread')
          .toList();
      if (!_initialised) {
        for (final d in unread) {
          _seenIds.add(d.id);
        }
        _initialised = true;
        return;
      }

      for (final doc in unread) {
        if (_seenIds.contains(doc.id)) continue;
        _seenIds.add(doc.id);
        _showToast(doc.data(), doc.id);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showToast(Map<String, dynamic> data, String docId) {
    if (!mounted) return;
    final name = data['displayName']?.toString() ?? 'A user';
    final type = data['type']?.toString() ?? '';

    String title;
    String message;
    IconData icon;
    Color color;

    switch (type) {
      case 'password_change_request':
        title   = 'Password Request';
        message = '$name is requesting a password change';
        icon    = Icons.lock_reset_outlined;
        color   = const Color(0xFFFFA726);
        break;
      default:
        title   = 'Notification';
        message = data['message']?.toString() ?? 'New notification';
        icon    = Icons.notifications_rounded;
        color   = const Color(0xFF31ECFC);
    }

    showNotificationToast(
      context,
      title: title,
      message: message,
      icon: icon,
      accentColor: color,
      onReview: type == 'password_change_request'
          ? () => context.pushNamed('PasswordManagement')
          : null,
      onDismiss: () {
        FirebaseFirestore.instance
            .collection('admin_notifications')
            .doc(docId)
            .update({'status': 'read'});
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Bell icon widget ──────────────────────────────────────────────────────────

class NotificationBellWidget extends StatelessWidget {
  final Color iconColor;
  final Color badgeColor;

  const NotificationBellWidget({
    super.key,
    this.iconColor = const Color(0xFF00D4FF),
    this.badgeColor = const Color(0xFFEF5350),
  });

  @override
  Widget build(BuildContext context) {
    final role = AppStateNotifier.instance.userRole ?? '';
    final normalised = AppRoles.normalizeRole(role);

    final isAdmin = normalised == AppRoles.superAdmin ||
        normalised == 'admin' ||
        role.toLowerCase().contains('admin');
    if (!isAdmin) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _getAdminNotificationStream(role),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs
                .where((d) => (d.data() as Map)['status'] == 'unread')
                .length ??
            0;

        return Tooltip(
          message: count > 0
              ? '$count unread notification${count == 1 ? '' : 's'}'
              : 'Notifications',
          child: InkWell(
            onTap: () => _openPanel(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    count > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    color: count > 0 ? iconColor : iconColor.withOpacity(0.6),
                    size: 20,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notifications',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, _) => const _NotificationPanel(),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween(begin: const Offset(-0.25, 0), end: Offset.zero)
              .animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

// ── Notification panel ────────────────────────────────────────────────────────

class _NotificationPanel extends StatefulWidget {
  const _NotificationPanel();

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  static const _cyan  = Color(0xFF31ECFC);
  static const _amber = Color(0xFFFFA726);
  static const _red   = Color(0xFFEF5350);

  bool _markingAll = false;

  Future<void> _markRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .update({'status': 'read'});
  }

  Future<void> _markAllRead(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;
    setState(() => _markingAll = true);
    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs) {
      batch.update(d.reference, {'status': 'read'});
    }
    await batch.commit();
    if (mounted) setState(() => _markingAll = false);
  }

  Future<void> _delete(String docId) async {
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg   = isDark ? const Color(0xFF0F172A) : t.secondaryBackground;
    final cardColor = isDark ? const Color(0xFF1E293B) : t.primaryBackground;
    final stroke    = isDark ? const Color(0xFF334155) : t.cardStroke;
    final role      = AppStateNotifier.instance.userRole ?? '';

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: responsiveDialogWidth(context, 380),
          height: double.infinity,
          decoration: BoxDecoration(
            color: panelBg,
            border: Border(right: BorderSide(color: stroke, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          // No orderBy — sort client-side to avoid composite index requirement
          child: StreamBuilder<QuerySnapshot>(
            stream: _getAdminNotificationStream(role),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text('Error loading notifications',
                      style: GoogleFonts.poppins(color: _red, fontSize: 12)),
                );
              }

              final docs = List<QueryDocumentSnapshot>.from(
                  snap.data?.docs ?? []);
              docs.sort((a, b) {
                final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });

              final unread = docs
                  .where((d) => (d.data() as Map)['status'] == 'unread')
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                    decoration:
                        BoxDecoration(border: Border(bottom: BorderSide(color: stroke))),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _cyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.notifications_rounded,
                              color: _cyan, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notifications',
                                  style: GoogleFonts.poppins(
                                      color: t.primaryText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              if (unread.isNotEmpty)
                                Text('${unread.length} unread',
                                    style: GoogleFonts.poppins(
                                        color: _cyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (unread.isNotEmpty)
                          TextButton(
                            onPressed: _markingAll
                                ? null
                                : () => _markAllRead(
                                    unread.cast<QueryDocumentSnapshot>()),
                            style: TextButton.styleFrom(
                              foregroundColor: _cyan,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            child: Text(
                                _markingAll ? 'Clearing…' : 'Mark all read',
                                style: GoogleFonts.poppins(fontSize: 11)),
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: t.txtMuted, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: snap.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: _cyan, strokeWidth: 2))
                        : docs.isEmpty
                            ? _empty(t)
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, i) =>
                                    _notifCard(context, t, cardColor, stroke, docs[i]),
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _notifCard(
    BuildContext context,
    FlutterFlowTheme t,
    Color cardColor,
    Color stroke,
    QueryDocumentSnapshot doc,
  ) {
    final data     = doc.data() as Map<String, dynamic>;
    final type     = data['type']?.toString() ?? '';
    final name     = data['displayName']?.toString() ?? 'Unknown User';
    final email    = data['email']?.toString() ?? '';
    final status   = data['status']?.toString() ?? 'read';
    final isUnread = status == 'unread';
    final ts       = data['createdAt'] as Timestamp?;
    final time     = ts != null ? _formatTime(ts.toDate()) : '';

    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    String message;

    switch (type) {
      case 'password_change_request':
        typeIcon  = Icons.lock_reset_outlined;
        typeColor = _amber;
        typeLabel = 'Password Request';
        message   = '$name is requesting a password change.';
        break;
      default:
        typeIcon  = Icons.info_outline;
        typeColor = _cyan;
        typeLabel = 'Notification';
        message   = data['message']?.toString() ?? '';
    }

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? typeColor.withOpacity(0.05) : cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnread ? typeColor.withOpacity(0.25) : stroke,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (isUnread) _markRead(doc.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(typeLabel,
                                style: GoogleFonts.poppins(
                                    color: t.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(message,
                          style: GoogleFonts.poppins(
                              color: t.txtMuted, fontSize: 11, height: 1.45)),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(email,
                            style: GoogleFonts.poppins(
                                color: t.txtSubtle, fontSize: 10)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 11, color: t.txtSubtle),
                          const SizedBox(width: 4),
                          Text(time,
                              style: GoogleFonts.poppins(
                                  color: t.txtSubtle, fontSize: 10)),
                          const Spacer(),
                          if (type == 'password_change_request')
                            _chipBtn(
                              label: 'Review',
                              color: _amber,
                              icon: Icons.open_in_new_rounded,
                              onTap: () {
                                if (isUnread) _markRead(doc.id);
                                Navigator.of(context).pop();
                                context.pushNamed('PasswordManagement');
                              },
                            ),
                          const SizedBox(width: 6),
                          _chipBtn(
                            label: 'Dismiss',
                            color: _red,
                            icon: Icons.close,
                            onTap: () => _delete(doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 11),
              const SizedBox(width: 3),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _empty(FlutterFlowTheme t) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 48, color: t.txtSubtle),
            const SizedBox(height: 12),
            Text('All caught up',
                style: GoogleFonts.poppins(
                    color: t.txtMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('No notifications',
                style: GoogleFonts.poppins(
                    color: t.txtSubtle, fontSize: 12)),
          ],
        ),
      );

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
