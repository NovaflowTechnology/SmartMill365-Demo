import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/rbac.dart';

/// Dialog for creating or editing a custom role.
///
/// Firestore collection: `custom_roles`
/// Document fields:
///   - name: String
///   - modules: List<String>   (granular module keys)
///   - subModules: List<String> (e.g. 'readonly_energy_overview')
///   - canManageUsers: bool
///   - createdBy: String (uid)
///   - updated_at: Timestamp
class CustomRoleDialog extends StatefulWidget {
  final String createdByUid;

  /// If editing an existing custom role, pass its Firestore doc ID and data.
  final String? editDocId;
  final Map<String, dynamic>? editData;

  /// Called when a role is created/updated/deleted so the parent can refresh.
  final VoidCallback onChanged;

  const CustomRoleDialog({
    super.key,
    required this.createdByUid,
    required this.onChanged,
    this.editDocId,
    this.editData,
  });

  @override
  State<CustomRoleDialog> createState() => _CustomRoleDialogState();
}

class _CustomRoleDialogState extends State<CustomRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Set<String> _enabledModules;
  bool _canManageUsers = false;
  String? _errorMessage;
  bool _isSaving = false;

  bool get isEditing => widget.editDocId != null;

  static const _kFieldFill = Color(0xFF151C2E);
  static const _kLabelColor = Color(0xFF6B7FA3);
  static const _kTextColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.editData != null) {
      _nameController = TextEditingController(
        text: widget.editData!['name'] as String? ?? '',
      );
      _enabledModules = Set<String>.from(
        (widget.editData!['modules'] as List<dynamic>?)?.cast<String>() ?? [],
      );
      _canManageUsers = widget.editData!['canManageUsers'] == true;
    } else {
      _nameController = TextEditingController();
      _enabledModules = {};
      _canManageUsers = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();

    // Validate name doesn't conflict with built-in roles
    if (AppRoles.builtInRoles
        .map((r) => r.toLowerCase())
        .contains(name.toLowerCase())) {
      setState(() => _errorMessage = 'Cannot use a built-in role name.');
      return;
    }

    // Check for duplicate custom role name (unless editing the same one)
    if (!isEditing || name != widget.editData?['name']) {
      final existing = await FirebaseFirestore.instance
          .collection('custom_roles')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        setState(() => _errorMessage = 'A custom role with this name already exists.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final data = {
        'name': name,
        'modules': _enabledModules.toList(),
        'subModules': <String>[],
        'canManageUsers': _canManageUsers,
        'createdBy': widget.createdByUid,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('custom_roles')
            .doc(widget.editDocId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('custom_roles')
            .add(data);
      }

      widget.onChanged();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Delete Custom Role',
            style: TextStyle(color: _kTextColor)),
        content: Text(
          'Delete "${_nameController.text}"? Users with this role will keep '
          'their current permissions but won\'t match any role template.',
          style: const TextStyle(color: _kLabelColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kLabelColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('custom_roles')
          .doc(widget.editDocId)
          .delete();
      widget.onChanged();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to delete: $e');
    }
  }

  InputDecoration _inputDeco(FlutterFlowTheme t, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kLabelColor, fontSize: 13),
        filled: true,
        fillColor: _kFieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2C354A)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add_circle_outline,
                      color: const Color(0xFF7A68FF),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Custom Role' : 'Create Custom Role',
                      style: const TextStyle(
                        color: _kTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: _kLabelColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        ),

                      // Role name
                      TextFormField(
                        controller: _nameController,
                        style:
                            const TextStyle(color: _kTextColor, fontSize: 14),
                        decoration: _inputDeco(t, 'Role Name *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Role name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Can manage users toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Can Register & Manage Users',
                            style:
                                TextStyle(color: _kTextColor, fontSize: 14)),
                        subtitle: const Text(
                          'Allow users with this role to add/edit other users',
                          style:
                              TextStyle(color: _kLabelColor, fontSize: 12),
                        ),
                        value: _canManageUsers,
                        activeColor: const Color(0xFF7A68FF),
                        onChanged: (v) => setState(() => _canManageUsers = v),
                      ),
                      const SizedBox(height: 16),

                      // Module permissions header
                      Row(
                        children: [
                          const Text(
                            'Module Permissions',
                            style: TextStyle(
                              color: _kTextColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() =>
                                _enabledModules =
                                    AppRoles.allModuleKeys.toSet()),
                            child: const Text('Select All',
                                style: TextStyle(
                                    color: Color(0xFF7A68FF), fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _enabledModules = {}),
                            child: const Text('Clear All',
                                style: TextStyle(
                                    color: _kLabelColor, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Module groups
                      ...AppRoles.moduleGroups.entries.map((group) {
                        final groupModules = group.value;
                        final allEnabled = groupModules
                            .every((m) => _enabledModules.contains(m));
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _kFieldFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF2C354A), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group header
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (allEnabled) {
                                      _enabledModules
                                          .removeAll(groupModules);
                                    } else {
                                      _enabledModules.addAll(groupModules);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 10, 10, 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        allEnabled
                                            ? Icons.check_box
                                            : Icons
                                                .check_box_outline_blank,
                                        color: allEnabled
                                            ? const Color(0xFF7A68FF)
                                            : _kLabelColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        group.key,
                                        style: const TextStyle(
                                          color: _kTextColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                  height: 1, color: Color(0xFF2C354A)),
                              // Module chips
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children:
                                      groupModules.map((moduleKey) {
                                    final enabled =
                                        _enabledModules.contains(moduleKey);
                                    final label =
                                        AppRoles.moduleLabels[moduleKey] ??
                                            moduleKey;
                                    return FilterChip(
                                      selected: enabled,
                                      label: Text(
                                        label,
                                        style: TextStyle(
                                          color: enabled
                                              ? Colors.white
                                              : _kLabelColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      selectedColor: const Color(0xFF7A68FF)
                                          .withOpacity(0.3),
                                      backgroundColor:
                                          const Color(0xFF1E2432),
                                      checkmarkColor:
                                          const Color(0xFF7A68FF),
                                      side: BorderSide(
                                        color: enabled
                                            ? const Color(0xFF7A68FF)
                                                .withOpacity(0.5)
                                            : const Color(0xFF2C354A),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            _enabledModules.add(moduleKey);
                                          } else {
                                            _enabledModules
                                                .remove(moduleKey);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Footer ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: Color(0xFF2C354A))),
                ),
                child: Row(
                  children: [
                    if (isEditing)
                      TextButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 18),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: _kLabelColor)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A68FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Update Role' : 'Create Role',
                              style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
