import 'package:flutter/material.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/firestore_service.dart';

class showESOPDialog extends StatefulWidget {
  const showESOPDialog({
    super.key,
    required this.onAlarmAdded,
    required this.esop,
    required this.id,
    required this.firestoreService,
  });
  final VoidCallback onAlarmAdded;
  final String esop;
  final String id;
  final FirestoreService firestoreService;
  @override
  State<showESOPDialog> createState() => _showESOPDialogState();
}

class _showESOPDialogState extends State<showESOPDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<String> esopItems;
  late List<bool> checkedValues;

  @override
  void initState() {
    super.initState();
    esopItems = widget.esop.split('\n').map((item) =>
        item.endsWith('(T)') || item.endsWith('(F)') ? item : '$item (F)').toList();
    checkedValues = esopItems.map((item) => item.endsWith('(T)')).toList();
  }

  Future<bool> _submit() async {
    for (int i = 0; i < esopItems.length; i++) {
      esopItems[i] = esopItems[i].replaceAll(RegExp(r'\(T\)|\(F\)'), checkedValues[i] ? '(T)' : '(F)');
    }
    try {
      await widget.firestoreService.editAlarmESOP(widget.id, esopItems.join('\n'));
      widget.onAlarmAdded();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.checklist_outlined,
      title: 'ESOP Checklist',
      subtitle: 'Check off completed ESOP steps.',
      submitLabel: 'DONE',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Steps',
          subtitle: 'Mark each step as completed or pending.',
          children: [
            for (int i = 0; i < esopItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF7A68FF),
                  checkColor: Colors.white,
                  title: Text(
                    esopItems[i].replaceAll(RegExp(r' \(T\)| \(F\)'), ''),
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  value: checkedValues[i],
                  onChanged: (v) => setState(() => checkedValues[i] = v ?? false),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
