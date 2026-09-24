import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/rbac.dart';
import 'package:smartmachine365/services/site_tenant.dart';

class AccessPermissionMatrixWidget extends StatefulWidget {
  const AccessPermissionMatrixWidget({super.key});

  @override
  State<AccessPermissionMatrixWidget> createState() =>
      _AccessPermissionMatrixWidgetState();
}

class _AccessPermissionMatrixWidgetState
    extends State<AccessPermissionMatrixWidget> {
  // uid → flat Set of enabled keys (module keys + "module.action" keys)
  final Map<String, Set<String>> _userKeys = {};
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final Set<String> _saving = {};

  // Which user card is expanded
  String? _expandedUid;

  // User-level search
  final TextEditingController _userSearchCtrl = TextEditingController();
  String _userQuery = '';

  // Per-user module search (uid → query string)
  final Map<String, TextEditingController> _moduleSearchCtrls = {};
  final Map<String, String> _moduleQueries = {};

  static const _kBg      = Color(0xFF0D1117);
  static const _kSurface = Color(0xFF151C2E);
  static const _kBorder  = Color(0xFF1E2A3A);
  static const _kText    = Color(0xFFE2E8F0);
  static const _kSubText = Color(0xFF6B7FA3);
  static const _kAccent  = Color(0xFF7A68FF);
  static const _kOn      = Color(0xFF22C55E);
  static const _kDanger  = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _userSearchCtrl.addListener(
        () => setState(() => _userQuery = _userSearchCtrl.text.trim().toLowerCase()));
    _loadUsers();
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    for (final c in _moduleSearchCtrls.values) { c.dispose(); }
    super.dispose();
  }

  TextEditingController _moduleCtrlFor(String uid) {
    return _moduleSearchCtrls.putIfAbsent(uid, () {
      final c = TextEditingController();
      c.addListener(() => setState(() => _moduleQueries[uid] = c.text.trim().toLowerCase()));
      return c;
    });
  }

  String _moduleQueryFor(String uid) => _moduleQueries[uid] ?? '';

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('customers').get();
      // Same boundary as the user list: the two customer sites must not show
      // each other's accounts, and a rule applied on one screen only is no
      // boundary at all.
      final docs = SiteTenant.filter(
        snap.docs.toList(),
        (d) => d.data()['email']?.toString() ?? '',
      );
      final uids = docs
          .map((d) => d.data()['UID']?.toString() ?? d.id)
          .where((u) => u.isNotEmpty)
          .toSet();

      final Map<String, Map<String, dynamic>> rolesMap = {};
      for (var i = 0; i < uids.length; i += 10) {
        final batch = uids.skip(i).take(10).toList();
        final r = await FirebaseFirestore.instance
            .collection('roles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in r.docs) { rolesMap[doc.id] = doc.data(); }
      }

      final List<Map<String, dynamic>> users = [];
      // docs, not snap.docs — the filtered list, or the rows would come back in
      // through the second pass.
      for (final doc in docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final uid = data['UID']?.toString() ?? doc.id;
        if (uid.isEmpty) continue;
        final roleData = rolesMap[uid];
        final role = roleData?['name']?.toString() ?? data['roles']?.toString() ?? '';
        final stored = (roleData?['accessible_modules'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            AppRoles.defaultGranularModules(role).toSet();
        users.add({
          'uid': uid,
          'name': data['display_name']?.toString() ?? data['name']?.toString() ?? 'Unknown',
          'email': data['email']?.toString() ?? '',
          'role': role,
        });
        _userKeys[uid] = stored;
      }

      final roleOrder = [
        AppRoles.superAdmin, AppRoles.admin, AppRoles.manager,
        AppRoles.engineer, AppRoles.operator_, AppRoles.viewer,
      ];
      users.sort((a, b) {
        final ai = roleOrder.indexOf(AppRoles.normalizeRole(a['role']));
        final bi = roleOrder.indexOf(AppRoles.normalizeRole(b['role']));
        if (ai != bi) return ai.compareTo(bi);
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveKeys(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('roles').doc(uid).set(
        {'accessible_modules': _userKeys[uid]!.toList()},
        SetOptions(merge: true),
      );
    } catch (_) {}
    if (mounted) setState(() => _saving.remove(uid));
  }

  void _toggleModuleAccess(String uid, String moduleKey, bool enable) {
    setState(() {
      _saving.add(uid);
      if (enable) {
        _userKeys[uid]?.add(moduleKey);
        for (final ak in AppRoles.defaultActionsFor(moduleKey)) {
          _userKeys[uid]?.add(ak);
        }
      } else {
        _userKeys[uid]?.remove(moduleKey);
        _userKeys[uid]?.removeWhere(
          (k) => AppRoles.moduleFromActionKey(k) == moduleKey,
        );
      }
    });
    _saveKeys(uid);
  }

  void _toggleAction(String uid, String moduleKey, String action, bool enable) {
    setState(() {
      _saving.add(uid);
      final ak = AppRoles.actionKey(moduleKey, action);
      if (enable) {
        _userKeys[uid]?.add(ak);
      } else {
        _userKeys[uid]?.remove(ak);
      }
    });
    _saveKeys(uid);
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_userQuery.isEmpty) return _users;
    return _users.where((u) {
      return (u['name'] as String).toLowerCase().contains(_userQuery) ||
          (u['email'] as String).toLowerCase().contains(_userQuery) ||
          (u['role'] as String).toLowerCase().contains(_userQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(t),
              const SizedBox(height: 12),
              _userSearchBar(),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _userQuery.isEmpty ? 'No users found.' : 'No users match "$_userQuery".',
                          style: const TextStyle(color: _kSubText),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _userCard(_filteredUsers[i], t),
                      ),
              ),
            ],
          );
  }

  Widget _header(FlutterFlowTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent.withOpacity(0.3)),
            ),
            child: const Icon(Icons.tune_rounded, size: 18, color: _kAccent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Action Permissions',
                    style: TextStyle(
                        color: _kText, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text(
                  'Toggle module access and specific actions per user. Saves instantly.',
                  style: TextStyle(color: _kSubText, fontSize: 12),
                ),
              ],
            ),
          ),
          _refreshButton(),
        ],
      ),
    );
  }

  Widget _userSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                controller: _userSearchCtrl,
                style: const TextStyle(color: _kText, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search users by name, email or role...',
                  hintStyle: const TextStyle(color: _kSubText, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kSubText),
                  suffixIcon: _userQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: _kSubText),
                          onPressed: () {
                            _userSearchCtrl.clear();
                            setState(() => _userQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Center(
              child: Text(
                '${_filteredUsers.length} / ${_users.length} users',
                style: const TextStyle(color: _kSubText, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refreshButton() {
    return InkWell(
      onTap: _loadUsers,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.refresh_rounded, size: 15, color: _kSubText),
            SizedBox(width: 6),
            Text('Refresh', style: TextStyle(color: _kSubText, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, FlutterFlowTheme t) {
    final uid      = user['uid'] as String;
    final name     = user['name'] as String;
    final email    = user['email'] as String;
    final role     = user['role'] as String;
    final keys     = _userKeys[uid] ?? {};
    final isSaving = _saving.contains(uid);
    final expanded = _expandedUid == uid;

    final allModules    = AppRoles.allModuleKeys;
    final enabledModules = allModules.where((m) => keys.contains(m)).length;

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expanded ? _kAccent.withOpacity(0.3) : _kBorder),
      ),
      child: Column(
        children: [
          // User row header
          InkWell(
            onTap: () => setState(() => _expandedUid = expanded ? null : uid),
            borderRadius: expanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _roleColor(role).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _roleColor(role).withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: _roleColor(role),
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(color: _kSubText, fontSize: 11)),
                      ],
                    ),
                  ),
                  _roleChip(role),
                  const SizedBox(width: 12),
                  if (isSaving)
                    const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent))
                  else
                    Text('$enabledModules / ${allModules.length} modules',
                        style: const TextStyle(color: _kSubText, fontSize: 11)),
                  const SizedBox(width: 12),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _kSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded module groups + module search
          if (expanded) ...[
            const Divider(height: 1, color: _kBorder),
            _moduleSearchBar(uid),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildFilteredGroups(uid, keys),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _moduleSearchBar(String uid) {
    final ctrl = _moduleCtrlFor(uid);
    final query = _moduleQueryFor(uid);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: _kText, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search modules or actions (e.g. "Emission", "Delete", "Export")...',
            hintStyle: const TextStyle(color: _kSubText, fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kSubText),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 14, color: _kSubText),
                    onPressed: () {
                      ctrl.clear();
                      setState(() => _moduleQueries[uid] = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredGroups(String uid, Set<String> keys) {
    final query = _moduleQueryFor(uid);
    final widgets = <Widget>[];

    for (final group in AppRoles.moduleGroups.entries) {
      // Filter modules in this group by name or by matching action labels
      final filteredModules = group.value.where((moduleKey) {
        if (query.isEmpty) return true;
        final moduleLabel = (AppRoles.moduleLabels[moduleKey] ?? moduleKey).toLowerCase();
        if (moduleLabel.contains(query)) return true;
        // Also match if any action label matches the query
        final actions = AppRoles.moduleActions[moduleKey] ?? ['view'];
        return actions.any((a) =>
            (AppRoles.actionLabels[a] ?? a).toLowerCase().contains(query));
      }).toList();

      if (filteredModules.isEmpty) continue;

      final enabledCount = filteredModules.where((m) => keys.contains(m)).length;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 14, color: _kSubText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(group.key,
                          style: const TextStyle(
                              color: _kText, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      '$enabledCount / ${filteredModules.length}',
                      style: TextStyle(
                          color: enabledCount > 0 ? _kOn : _kSubText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _kBorder),
              ...filteredModules.asMap().entries.map((entry) {
                final isLast = entry.key == filteredModules.length - 1;
                return _moduleRow(uid, entry.value, keys, isLast: isLast);
              }),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('No modules match "$query".',
                style: const TextStyle(color: _kSubText, fontSize: 12)),
          ),
        ),
      ];
    }
    return widgets;
  }

  Widget _moduleRow(String uid, String moduleKey, Set<String> keys, {bool isLast = false}) {
    final label   = AppRoles.moduleLabels[moduleKey] ?? moduleKey;
    final actions = AppRoles.moduleActions[moduleKey] ?? ['view'];
    final moduleOn = keys.contains(moduleKey);

    // Highlight if module search query matches
    final query = _moduleQueryFor(uid);
    final highlighted = query.isNotEmpty &&
        (AppRoles.moduleLabels[moduleKey] ?? moduleKey).toLowerCase().contains(query);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: highlighted ? _kAccent.withOpacity(0.05) : Colors.transparent,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module name + master toggle
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (highlighted)
                      Container(
                        width: 3,
                        height: 14,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: moduleOn ? _kText : _kSubText,
                          fontSize: 13,
                          fontWeight: moduleOn ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action count badge when module is on
              if (moduleOn) ...[
                _actionCountBadge(moduleKey, keys, actions),
                const SizedBox(width: 8),
              ],
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: moduleOn,
                  onChanged: (val) => _toggleModuleAccess(uid, moduleKey, val),
                  activeColor: _kAccent,
                  activeTrackColor: _kAccent.withOpacity(0.3),
                  inactiveThumbColor: _kSubText,
                  inactiveTrackColor: _kBorder,
                ),
              ),
            ],
          ),
          // Action chips — only when module is ON and has more than just 'view'
          if (moduleOn && actions.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: actions.map((action) {
                final actionKey = AppRoles.actionKey(moduleKey, action);
                final actionOn  = keys.contains(actionKey);
                // Highlight action chip if query matches action label
                final actionMatches = query.isNotEmpty &&
                    (AppRoles.actionLabels[action] ?? action)
                        .toLowerCase()
                        .contains(query);
                return _actionChip(
                  uid: uid,
                  moduleKey: moduleKey,
                  action: action,
                  enabled: actionOn,
                  highlighted: actionMatches,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionCountBadge(String moduleKey, Set<String> keys, List<String> actions) {
    if (actions.length <= 1) return const SizedBox.shrink();
    final enabledActions = actions.where((a) => keys.contains(AppRoles.actionKey(moduleKey, a))).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: enabledActions > 0 ? _kOn.withOpacity(0.12) : _kBorder,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$enabledActions/${actions.length}',
        style: TextStyle(
          color: enabledActions > 0 ? _kOn : _kSubText,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionChip({
    required String uid,
    required String moduleKey,
    required String action,
    required bool enabled,
    bool highlighted = false,
  }) {
    final label = AppRoles.actionLabels[action] ?? action;
    final color = _actionColor(action);

    return GestureDetector(
      onTap: () => _toggleAction(uid, moduleKey, action, !enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.15)
              : highlighted
                  ? _kAccent.withOpacity(0.06)
                  : const Color(0xFF1A2035),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled
                ? color.withOpacity(0.5)
                : highlighted
                    ? _kAccent.withOpacity(0.3)
                    : _kBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_actionIcon(action), size: 12,
                color: enabled ? color : highlighted ? _kAccent : _kSubText),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : highlighted ? _kAccent : _kSubText,
                fontSize: 11,
                fontWeight: enabled || highlighted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.startsWith('delete'))                                       return _kDanger;
    if (action.startsWith('edit'))                                         return const Color(0xFFF59E0B);
    if (action == 'view' || action == AppRoles.kEmfViewAuditLog)          return const Color(0xFF60A5FA);
    if (action == 'add'  || action == AppRoles.kEmfAddFactor)             return _kOn;
    if (action == 'activate' || action == AppRoles.kEmfActivate)          return const Color(0xFF34D399);
    if (action == 'export')                                                return const Color(0xFF818CF8);
    return _kSubText;
  }

  IconData _actionIcon(String action) {
    if (action.startsWith('delete'))                              return Icons.delete_outline_rounded;
    if (action.startsWith('edit'))                               return Icons.edit_outlined;
    if (action == AppRoles.kEmfViewAuditLog)                     return Icons.history_rounded;
    if (action == 'view')                                        return Icons.visibility_outlined;
    if (action == 'add' || action == AppRoles.kEmfAddFactor)     return Icons.add_circle_outline_rounded;
    if (action == 'activate' || action == AppRoles.kEmfActivate) return Icons.play_arrow_rounded;
    if (action == 'export')                                      return Icons.file_download_outlined;
    return Icons.settings_outlined;
  }

  Widget _roleChip(String role) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(role.isEmpty ? '—' : role,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _roleColor(String role) {
    switch (AppRoles.normalizeRole(role)) {
      case 'Super Admin': return const Color(0xFFFF6B6B);
      case 'Admin':       return const Color(0xFFFF9F43);
      case 'Manager':     return const Color(0xFF54A0FF);
      case 'Engineer':    return const Color(0xFF5F27CD);
      case 'Operator':    return const Color(0xFF00D2D3);
      case 'Viewer':      return const Color(0xFF6B7FA3);
      default:            return _kAccent;
    }
  }
}
