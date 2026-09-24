import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class ProductionOutputDeleteDialog extends StatelessWidget {
  final Map<String, dynamic> row;
  final Future<void> Function() onConfirm;

  const ProductionOutputDeleteDialog({
    super.key,
    required this.row,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return AlertDialog(
      backgroundColor: t.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: t.cardStroke),
      ),
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: t.error, size: 22),
        const SizedBox(width: 10),
        Text('Delete Entry',
            style: TextStyle(color: t.txtPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      content: Text(
        'Delete entry for ${row['machine'] ?? 'this machine'} on ${row['date'] ?? ''}?\nThis cannot be undone.',
        style: TextStyle(color: t.txtSecondary, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: t.txtSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74852),
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await onConfirm();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
