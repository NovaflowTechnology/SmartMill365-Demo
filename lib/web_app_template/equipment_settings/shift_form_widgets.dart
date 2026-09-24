import 'package:flutter/material.dart';

// ── Time picker field ─────────────────────────────────────────────────────────

class ShiftTimePickerField extends StatelessWidget {
  const ShiftTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.isLight,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    final bgColor =
        isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final labelColor =
        isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final textColor =
        isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final hintColor =
        isLight ? const Color(0xFF94A3B8) : const Color(0xFF5C6987);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: labelColor, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select time' : value,
                    style: TextStyle(
                        color: value.isEmpty ? hintColor : textColor,
                        fontSize: 14),
                  ),
                ),
                Icon(Icons.access_time, size: 16, color: hintColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rest time sub-table ───────────────────────────────────────────────────────

class ShiftRestTimeTable extends StatelessWidget {
  const ShiftRestTimeTable({
    super.key,
    required this.restTimes,
    required this.isLight,
    required this.onAdd,
    required this.onRemove,
    required this.onPickTime,
  });

  final List<Map<String, String>> restTimes;
  final bool isLight;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, bool isStart) onPickTime;

  @override
  Widget build(BuildContext context) {
    final headerColor =
        isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1A2240);
    final borderColor =
        isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A);
    final labelColor =
        isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final textColor =
        isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final hintColor =
        isLight ? const Color(0xFF94A3B8) : const Color(0xFF5C6987);
    final bgColor =
        isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16, color: Color(0xFF31ECFC)),
          label: const Text('Add Shift Rest Time',
              style: TextStyle(color: Color(0xFF31ECFC), fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF31ECFC)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Start Rest Time',
                            style: TextStyle(
                                color: labelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        child: Text('End Rest Time',
                            style: TextStyle(
                                color: labelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 60,
                        child: Text('Operate',
                            style: TextStyle(
                                color: labelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              // Empty state
              if (restTimes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 32, color: hintColor),
                        const SizedBox(height: 8),
                        Text('No Data',
                            style: TextStyle(color: hintColor, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              // Data rows
              ...restTimes.asMap().entries.map((entry) {
                final i = entry.key;
                final rt = entry.value;
                return Container(
                  decoration:
                      BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onPickTime(i, true),
                          child: _timeCell(rt['startRestTime']!, bgColor,
                              borderColor, textColor, hintColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onPickTime(i, false),
                          child: _timeCell(rt['endRestTime']!, bgColor,
                              borderColor, textColor, hintColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: IconButton(
                          onPressed: () => onRemove(i),
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFE74852)),
                          tooltip: 'Remove',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeCell(String value, Color bg, Color border, Color text, Color hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? 'Select time' : value,
              style: TextStyle(
                  color: value.isEmpty ? hint : text, fontSize: 13),
            ),
          ),
          Icon(Icons.access_time, size: 14, color: hint),
        ],
      ),
    );
  }
}
