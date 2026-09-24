import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';

import '../md_insight_report_models.dart';
import '../md_insight_report_service.dart';

/// Read-only list of past report generations (`md_insight_report_log`),
/// opened from the report page's "View Logs" button.
class ReportLogDialog extends StatefulWidget {
  final String? plantCode;

  const ReportLogDialog({super.key, this.plantCode});

  static Future<void> show(BuildContext context, {String? plantCode}) {
    return showDialog(
      context: context,
      builder: (_) => ReportLogDialog(plantCode: plantCode),
    );
  }

  @override
  State<ReportLogDialog> createState() => _ReportLogDialogState();
}

class _ReportLogDialogState extends State<ReportLogDialog> {
  bool _isLoading = true;
  List<MdInsightReportLogEntry> _logs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs =
        await MdInsightReportService.fetchReportLogs(plantCode: widget.plantCode);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats the raw `generated_at` (an ISO/DATETIME string from
  /// `md_insight_report_log`) as e.g. "28 Jul 2026, 14:32" in local time.
  /// Falls back to the raw string if it doesn't parse as a date.
  String _fmtTimestamp(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.isUtc ? dt.toLocal() : dt;
    final month = _months[(local.month - 1).clamp(0, 11)];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} $month ${local.year}, $hh:$mm';
  }

  Color _stateColor(String state) {
    switch (state.toLowerCase()) {
      case 'breach':
        return Colors.red;
      case 'within':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static const _autoBadgeColor = Color(0xFF00D4FF);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AlertDialog(
      backgroundColor: theme.secondaryBackground,
      title: Text(
        'Report Generation Logs',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: theme.primaryText),
      ),
      content: SizedBox(
        width: responsiveDialogWidth(context, 560),
        height: 420,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _logs.isEmpty
                ? Center(
                    child: Text(
                      'No reports have been generated yet.',
                      style: GoogleFonts.poppins(
                          fontSize: 13.5, color: theme.secondaryText),
                    ),
                  )
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: theme.alternate),
                    itemBuilder: (context, i) => _logRow(theme, _logs[i]),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _logRow(FlutterFlowTheme theme, MdInsightReportLogEntry log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${log.plantCode}  •  ${log.period}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText),
                      ),
                    ),
                    if (log.source == 'auto') ...[
                      const SizedBox(width: 6),
                      _sourceBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtTimestamp(log.generatedAt)}  —  ${log.generatedBy}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _stateColor(log.reportState).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.reportState.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _stateColor(log.reportState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Marks the canonical, locked monthly snapshot (source='auto') apart
  /// from ordinary Download-button-triggered entries — this dialog is the
  /// only surface that lists `md_insight_report_log` rows, so it's the
  /// natural place to show which one is the permanent record for its month.
  Widget _sourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _autoBadgeColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 10, color: _autoBadgeColor),
          const SizedBox(width: 3),
          Text(
            'AUTO',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _autoBadgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
