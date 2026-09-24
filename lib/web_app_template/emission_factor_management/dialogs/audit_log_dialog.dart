import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../emission_factor_model.dart';

class AuditLogDialog extends StatelessWidget {
  final List<AuditLogEntry> entries;
  final VoidCallback? onExportCsv;

  const AuditLogDialog({
    super.key,
    required this.entries,
    this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final cardBg = isLight ? Colors.white : const Color(0xFF1A2236);
    final cardBorder = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C3A55);
    final headerColor = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 740, maxHeight: 600),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.1 : 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: cardBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emission Factor Audit Log',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Complete immutable history of all factor changes',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF2C3A55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Icon(Icons.close,
                          size: 15, color: subColor),
                    ),
                  ),
                ],
              ),
            ),

            // Table
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: [
                        _tableHeader(t, isLight, cardBorder, subColor),
                        ...entries.asMap().entries.map((e) =>
                            _tableRow(context, e.value, e.key,
                                entries.length, t, isLight, cardBorder)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: cardBorder, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Close button
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E2A48),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Export CSV
                  InkWell(
                    onTap: onExportCsv,
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: t.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded,
                              size: 15,
                              color: isLight
                                  ? Colors.white
                                  : const Color(0xFF0A0E1A)),
                          const SizedBox(width: 7),
                          Text(
                            'Export CSV',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isLight
                                  ? Colors.white
                                  : const Color(0xFF0A0E1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(
    dynamic t,
    bool isLight,
    Color border,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0F1827).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          _hCell('TIMESTAMP', flex: 20, subColor: subColor),
          _hCell('ACTION', flex: 22, subColor: subColor),
          const SizedBox(width: 20),
          _hCell('FY', flex: 12, subColor: subColor),
          _hCell('CHANGE', flex: 24, subColor: subColor),
          _hCell('ACTOR', flex: 22, subColor: subColor),
        ],
      ),
    );
  }

  Widget _hCell(String label, {required int flex, required Color subColor}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: subColor.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _tableRow(
    BuildContext context,
    AuditLogEntry entry,
    int index,
    int total,
    dynamic t,
    bool isLight,
    Color border,
  ) {
    final isLast = index == total - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: border.withOpacity(0.6), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Expanded(
            flex: 20,
            child: Text(
              entry.timestampDisplay,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: isLight
                    ? const Color(0xFF475569)
                    : t.secondaryText.withOpacity(0.65),
                height: 1.5,
              ),
            ),
          ),
          // Action chip
          Expanded(
            flex: 22,
            child: _actionChip(entry.action, t, isLight),
          ),
          const SizedBox(width: 20),
          // FY
          Expanded(
            flex: 12,
            child: Text(
              '${entry.fiscalYear}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLight
                    ? const Color(0xFF1E293B)
                    : t.primaryText,
              ),
            ),
          ),
          // Change
          Expanded(
            flex: 24,
            child: _changeCell(entry, t, isLight),
          ),
          // Actor
          Expanded(
            flex: 22,
            child: Text(
              entry.actor,
              style: TextStyle(
                fontSize: 12,
                color: entry.actor == 'System'
                    ? t.secondaryText.withOpacity(0.45)
                    : (isLight
                        ? const Color(0xFF475569)
                        : t.secondaryText.withOpacity(0.7)),
                fontStyle: entry.actor == 'System'
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(AuditAction action, dynamic t, bool isLight) {
    Color bg, border, text;

    switch (action) {
      case AuditAction.activated:
        bg = t.success.withOpacity(0.1);
        border = t.success.withOpacity(0.35);
        text = t.success;
        break;
      case AuditAction.autoLocked:
        bg = t.secondaryText.withOpacity(0.07);
        border = t.secondaryText.withOpacity(0.2);
        text = t.secondaryText.withOpacity(0.6);
        break;
      case AuditAction.restated:
        bg = t.warning.withOpacity(0.1);
        border = t.warning.withOpacity(0.35);
        text = t.warning;
        break;
      case AuditAction.deactivated:
        bg = t.error.withOpacity(0.1);
        border = t.error.withOpacity(0.35);
        text = t.error;
        break;
      case AuditAction.created:
        bg = t.info.withOpacity(0.1);
        border = t.info.withOpacity(0.35);
        text = t.info;
        break;
      case AuditAction.updated:
        bg = t.tertiary.withOpacity(0.1);
        border = t.tertiary.withOpacity(0.35);
        text = t.tertiary;
        break;
    }

    final label = _auditActionEntry(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: text,
        ),
      ),
    );
  }

  String _auditActionEntry(AuditAction action) {
    switch (action) {
      case AuditAction.activated:   return 'ACTIVATED';
      case AuditAction.autoLocked:  return 'AUTO-LOCKED';
      case AuditAction.restated:    return 'RESTATED';
      case AuditAction.deactivated: return 'DEACTIVATED';
      case AuditAction.created:     return 'CREATED';
      case AuditAction.updated:     return 'UPDATED';
    }
  }

  Widget _changeCell(AuditLogEntry entry, dynamic t, bool isLight) {
    if (entry.action == AuditAction.autoLocked) {
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: t.secondaryText.withOpacity(0.55),
          ),
          children: const [
            TextSpan(text: 'Active → Locked'),
          ],
        ),
      );
    }

    if (entry.fromValue == null && entry.toValue != null) {
      return RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: t.secondaryText.withOpacity(0.4)),
          children: [
            const TextSpan(text: '— → '),
            TextSpan(
              text: entry.toValue!.toStringAsFixed(3),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.success,
              ),
            ),
          ],
        ),
      );
    }

    if (entry.fromValue != null && entry.toValue != null) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: entry.fromValue!.toStringAsFixed(3),
              style: TextStyle(
                color: t.error.withOpacity(0.8),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            TextSpan(
              text: ' → ',
              style: TextStyle(color: t.secondaryText.withOpacity(0.4)),
            ),
            TextSpan(
              text: entry.toValue!.toStringAsFixed(3),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.warning,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      '—',
      style: TextStyle(color: t.secondaryText.withOpacity(0.3), fontSize: 12),
    );
  }
}
