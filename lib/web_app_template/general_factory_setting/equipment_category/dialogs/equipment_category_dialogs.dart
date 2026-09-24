import 'package:flutter/material.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart'
    show CustomDialog, CustomDialogSection;
import '/flutter_flow/flutter_flow_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _inputDeco(FlutterFlowTheme t, String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B7FA3), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF151C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: t.primary.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: t.primary.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

// ─────────────────────────────────────────────────────────────────────────────
// ADD CATEGORY GROUP DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class AddCategoryGroupDialog extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const AddCategoryGroupDialog({super.key, required this.onSave});

  @override
  State<AddCategoryGroupDialog> createState() => _AddCategoryGroupDialogState();
}

class _AddCategoryGroupDialogState extends State<AddCategoryGroupDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _codeCtrl   = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _error = null);
    final ok = await widget.onSave({
      'name':          _nameCtrl.text.trim(),
      'category_code': _codeCtrl.text.trim().toUpperCase(),
    });
    if (!ok && mounted) setState(() => _error = 'Failed to save category.');
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.label_outline,
      title: 'Add Equipment Category',
      subtitle: 'Define a new top-level equipment category.',
      submitLabel: 'SAVE',
      cancelLabel: 'CANCEL',
      requiredNote: true,
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Category Details',
          subtitle: 'Name and short code for the category.',
          children: [
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Category Name *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _codeCtrl,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Code *'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT CATEGORY GROUP DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class EditCategoryGroupDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const EditCategoryGroupDialog(
      {super.key, required this.initialData, required this.onSave});

  @override
  State<EditCategoryGroupDialog> createState() =>
      _EditCategoryGroupDialogState();
}

class _EditCategoryGroupDialogState extends State<EditCategoryGroupDialog> {
  final _formKey  = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData['name'] ?? '');
    _codeCtrl =
        TextEditingController(text: widget.initialData['category_code'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _error = null);
    final ok = await widget.onSave({
      'name':          _nameCtrl.text.trim(),
      'category_code': _codeCtrl.text.trim().toUpperCase(),
    });
    if (!ok && mounted) setState(() => _error = 'Failed to update category.');
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.edit_outlined,
      title: 'Edit Equipment Category',
      subtitle:
          'Update "${widget.initialData['name'] ?? 'this category'}".',
      submitLabel: 'UPDATE',
      cancelLabel: 'CANCEL',
      requiredNote: true,
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Category Details',
          subtitle: 'Name and short code for the category.',
          children: [
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Category Name *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _codeCtrl,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Code *'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD EQUIPMENT TYPE DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class AddEquipmentCategoryDialog extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> data) onSave;
  final List<Map<String, dynamic>> categoryGroups;

  const AddEquipmentCategoryDialog({
    super.key,
    required this.onSave,
    this.categoryGroups = const [],
  });

  @override
  State<AddEquipmentCategoryDialog> createState() =>
      _AddEquipmentCategoryDialogState();
}

class _AddEquipmentCategoryDialogState
    extends State<AddEquipmentCategoryDialog> {
  final _formKey                  = GlobalKey<FormState>();
  final _deviceTypeController     = TextEditingController();
  final _deviceCodeController     = TextEditingController();
  final _electricalParentController = TextEditingController();
  String? _selectedCategoryName;
  String  _selectedCategoryCode  = '';
  String? _errorMessage;

  @override
  void dispose() {
    _deviceTypeController.dispose();
    _deviceCodeController.dispose();
    _electricalParentController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? name) {
    if (name == null) return;
    final match = widget.categoryGroups
        .firstWhere((g) => g['name'] == name, orElse: () => {});
    setState(() {
      _selectedCategoryName = name;
      _selectedCategoryCode = match['category_code']?.toString() ?? '';
    });
  }

  Future<bool> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _errorMessage = null);
    final payload = {
      'device_type':         _deviceTypeController.text.trim(),
      'device_code':         _deviceCodeController.text.trim(),
      'equipment_category':  _selectedCategoryName ?? '',
      'category_code':       _selectedCategoryCode,
      'electrical_parent':   _electricalParentController.text.trim(),
    };
    final success = await widget.onSave(payload);
    if (!success && mounted) {
      setState(() => _errorMessage = 'Failed to save equipment type.');
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final groups = widget.categoryGroups;

    return CustomDialog(
      formKey: _formKey,
      icon: Icons.precision_manufacturing_outlined,
      title: 'Add Equipment Type',
      subtitle: 'Create a new device type under a category.',
      submitLabel: 'SAVE',
      cancelLabel: 'CANCEL',
      requiredNote: true,
      onSubmit: _handleSubmit,
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Device Identification',
          subtitle: 'Basic identifiers for the equipment type.',
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _deviceTypeController,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Device Type *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _deviceCodeController,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Device Code *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryName,
              dropdownColor: const Color(0xFF1E2432),
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
              decoration: _inputDeco(theme, 'Equipment Category *'),
              items: groups
                  .map((g) => DropdownMenuItem<String>(
                        value: g['name']?.toString(),
                        child: Text(
                          '${g['name']} (${g['category_code']})',
                          style: const TextStyle(
                              color: Color(0xFFE2E8F0), fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: _onCategoryChanged,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Select a category' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _electricalParentController,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
              decoration: _inputDeco(theme, 'Electrical Parent'),
            ),
          ],
        ),
        if (_errorMessage != null)
          CustomDialogSection(
            title: 'Error',
            subtitle: _errorMessage!,
            children: const [],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT EQUIPMENT TYPE DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class EditEquipmentCategoryDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Future<bool> Function(Map<String, dynamic> data) onSave;
  final List<Map<String, dynamic>> categoryGroups;

  const EditEquipmentCategoryDialog({
    super.key,
    required this.initialData,
    required this.onSave,
    this.categoryGroups = const [],
  });

  @override
  State<EditEquipmentCategoryDialog> createState() =>
      _EditEquipmentCategoryDialogState();
}

class _EditEquipmentCategoryDialogState
    extends State<EditEquipmentCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _deviceTypeController;
  late TextEditingController _deviceCodeController;
  late TextEditingController _electricalParentController;
  String? _selectedCategoryName;
  String  _selectedCategoryCode  = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _deviceTypeController =
        TextEditingController(text: widget.initialData['device_type'] ?? '');
    _deviceCodeController =
        TextEditingController(text: widget.initialData['device_code'] ?? '');
    _electricalParentController =
        TextEditingController(text: widget.initialData['electrical_parent'] ?? '');

    // Pre-select category from existing data
    final existingCat = widget.initialData['equipment_category']?.toString() ?? '';
    final match = widget.categoryGroups
        .firstWhere((g) => g['name'] == existingCat, orElse: () => {});
    if (match.isNotEmpty) {
      _selectedCategoryName = existingCat;
      _selectedCategoryCode = match['category_code']?.toString() ?? '';
    } else if (existingCat.isNotEmpty) {
      _selectedCategoryName = existingCat;
      _selectedCategoryCode =
          widget.initialData['category_code']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _deviceTypeController.dispose();
    _deviceCodeController.dispose();
    _electricalParentController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? name) {
    if (name == null) return;
    final match = widget.categoryGroups
        .firstWhere((g) => g['name'] == name, orElse: () => {});
    setState(() {
      _selectedCategoryName = name;
      _selectedCategoryCode = match['category_code']?.toString() ?? '';
    });
  }

  Future<bool> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _errorMessage = null);
    final payload = {
      'device_type':         _deviceTypeController.text.trim(),
      'device_code':         _deviceCodeController.text.trim(),
      'equipment_category':  _selectedCategoryName ?? '',
      'category_code':       _selectedCategoryCode,
      'electrical_parent':   _electricalParentController.text.trim(),
    };
    final success = await widget.onSave(payload);
    if (!success && mounted) {
      setState(() => _errorMessage = 'Failed to update equipment type.');
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final theme  = FlutterFlowTheme.of(context);
    final groups = widget.categoryGroups;

    // Build dropdown items. If the current value isn't in the list, add it.
    final groupNames = groups.map((g) => g['name']?.toString() ?? '').toList();
    final dropdownValue = (groupNames.contains(_selectedCategoryName))
        ? _selectedCategoryName
        : null;

    return CustomDialog(
      formKey: _formKey,
      icon: Icons.edit_outlined,
      title: 'Edit Equipment Type',
      subtitle:
          'Update "${widget.initialData['device_type'] ?? 'this type'}".',
      submitLabel: 'UPDATE',
      cancelLabel: 'CANCEL',
      requiredNote: true,
      onSubmit: _handleSubmit,
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Device Identification',
          subtitle: 'Basic identifiers for the equipment type.',
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _deviceTypeController,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Device Type *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _deviceCodeController,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                  decoration: _inputDeco(theme, 'Device Code *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              dropdownColor: const Color(0xFF1E2432),
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
              decoration: _inputDeco(theme, 'Equipment Category *'),
              items: groups
                  .map((g) => DropdownMenuItem<String>(
                        value: g['name']?.toString(),
                        child: Text(
                          '${g['name']} (${g['category_code']})',
                          style: const TextStyle(
                              color: Color(0xFFE2E8F0), fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: _onCategoryChanged,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Select a category' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _electricalParentController,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
              decoration: _inputDeco(theme, 'Electrical Parent'),
            ),
          ],
        ),
        if (_errorMessage != null)
          CustomDialogSection(
            title: 'Error',
            subtitle: _errorMessage!,
            children: const [],
          ),
      ],
    );
  }
}
