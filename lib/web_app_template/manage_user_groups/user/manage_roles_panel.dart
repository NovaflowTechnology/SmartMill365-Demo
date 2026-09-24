import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/rbac.dart';
import '/flutter_flow/nav/nav.dart';
import 'custom_role_dialog.dart';

/// A panel that lists all custom roles and lets Super Admin create/edit/delete them.
class ManageRolesPanel extends StatefulWidget {
  const ManageRolesPanel({super.key});

  @override
  State<ManageRolesPanel> createState() => _ManageRolesPanelState();
}

class _ManageRolesPanelState extends State<ManageRolesPanel> {
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('custom_roles')
          .get();
      final roles = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
      AppRoles.setCustomRoles(roles);
      if (mounted) setState(() => _roles = roles);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => CustomRoleDialog(
        createdByUid: AppStateNotifier.instance.uid ?? '',
        onChanged: _loadRoles,
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> role) {
    showDialog(
      context: context,
      builder: (_) => CustomRoleDialog(
        createdByUid: AppStateNotifier.instance.uid ?? '',
        editDocId: role['id'] as String,
        editData: role,
        onChanged: _loadRoles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: Color(0xFF7A68FF), size: 22),
              const SizedBox(width: 10),
              const Text(
                'Custom Roles',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A68FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Create custom roles with specific module permissions. '
            'Custom roles appear in the role dropdown when assigning users.',
            style: TextStyle(color: Color(0xFF6B7FA3), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Built-in roles info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2C354A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Built-in Roles',
                    style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: AppRoles.builtInRoles.map((role) {
                    return Chip(
                      label: Text(role,
                          style: const TextStyle(
                              color: Color(0xFFE2E8F0), fontSize: 12)),
                      backgroundColor: const Color(0xFF1E2432),
                      side: const BorderSide(color: Color(0xFF2C354A)),
                      avatar: const Icon(Icons.lock_outline,
                          size: 14, color: Color(0xFF6B7FA3)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Custom roles list
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF7A68FF)),
              ),
            )
          else if (_roles.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.category_outlined,
                      color: Color(0xFF6B7FA3), size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'No custom roles yet',
                    style: TextStyle(color: Color(0xFF6B7FA3), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create a custom role to define specific permissions',
                    style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...(_roles.map((role) {
              final name = role['name'] as String? ?? '';
              final modules =
                  (role['modules'] as List<dynamic>?)?.cast<String>() ?? [];
              final canManage = role['canManageUsers'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF151C2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2C354A)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF7A68FF).withOpacity(0.2),
                    child: const Icon(Icons.person_outline,
                        color: Color(0xFF7A68FF), size: 20),
                  ),
                  title: Text(name,
                      style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${modules.length} modules',
                          style: const TextStyle(
                              color: Color(0xFF6B7FA3), fontSize: 12),
                        ),
                        if (canManage)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A68FF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Can Manage Users',
                                style: TextStyle(
                                    color: Color(0xFF7A68FF), fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFF6B7FA3), size: 20),
                    onPressed: () => _showEditDialog(role),
                  ),
                ),
              );
            })),
        ],
      ),
    );
  }
}
