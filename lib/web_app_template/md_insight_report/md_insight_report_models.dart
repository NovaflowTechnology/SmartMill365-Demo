// Typed view over the `/md-insight-rules` response — the computed MD001-404
// rule lines plus the supporting chart/table data the report page renders
// alongside them. See functions/api/mdInsightRulesFunction.js for the
// backend that produces this shape.

/// One rendered rule line, e.g. MD001: {status: 'ok', values: {excess_pct: 35.5},
/// text: 'Current Maximum Demand exceeded contract capacity by 35.5%.'}.
class MdRuleLine {
  final String ruleId;
  final String category;
  final String status;
  final Map<String, dynamic> values;
  final String? text;

  const MdRuleLine({
    required this.ruleId,
    required this.category,
    required this.status,
    required this.values,
    required this.text,
  });

  factory MdRuleLine.fromJson(Map<String, dynamic> json) => MdRuleLine(
        ruleId: json['rule_id']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        values: (json['values'] as Map?)?.cast<String, dynamic>() ?? {},
        text: json['text']?.toString(),
      );

  double? numValue(String key) => (values[key] as num?)?.toDouble();
  String? strValue(String key) => values[key]?.toString();
}

class MdDailyPoint {
  final String date;
  final double value;
  const MdDailyPoint(this.date, this.value);

  factory MdDailyPoint.fromJson(Map<String, dynamic> json) =>
      MdDailyPoint(json['date']?.toString() ?? '', (json['value'] as num?)?.toDouble() ?? 0);
}

class MdLoadAnalysisStats {
  final String peakPeriod;
  final double peakLoadKw;
  final double peakDurationHours;
  final double avgDuringPeakKw;
  final String? dominantShiftName;
  final double? dominantShiftPct;

  const MdLoadAnalysisStats({
    required this.peakPeriod,
    required this.peakLoadKw,
    required this.peakDurationHours,
    required this.avgDuringPeakKw,
    this.dominantShiftName,
    this.dominantShiftPct,
  });

  factory MdLoadAnalysisStats.fromJson(Map<String, dynamic> json) => MdLoadAnalysisStats(
        peakPeriod: json['peak_period']?.toString() ?? '',
        peakLoadKw: (json['peak_load_kw'] as num?)?.toDouble() ?? 0,
        peakDurationHours: (json['peak_duration_hours'] as num?)?.toDouble() ?? 0,
        avgDuringPeakKw: (json['avg_during_peak_kw'] as num?)?.toDouble() ?? 0,
        dominantShiftName: json['dominant_shift_name']?.toString(),
        dominantShiftPct: (json['dominant_shift_pct'] as num?)?.toDouble(),
      );
}

class MdLoadAnalysis {
  final String date;
  final List<double> hourlyValues;
  final MdLoadAnalysisStats stats;

  const MdLoadAnalysis({required this.date, required this.hourlyValues, required this.stats});

  factory MdLoadAnalysis.fromJson(Map<String, dynamic> json) => MdLoadAnalysis(
        date: json['date']?.toString() ?? '',
        hourlyValues: ((json['hourly'] as List?) ?? [])
            .map((e) => ((e as Map)['value'] as num?)?.toDouble() ?? 0.0)
            .toList(),
        stats: MdLoadAnalysisStats.fromJson((json['stats'] as Map?)?.cast<String, dynamic>() ?? {}),
      );
}

class MdEquipmentRankingRow {
  final String name;
  final double value;
  final double pct;
  const MdEquipmentRankingRow(this.name, this.value, this.pct);

  factory MdEquipmentRankingRow.fromJson(Map<String, dynamic> json) => MdEquipmentRankingRow(
        json['name']?.toString() ?? '',
        (json['value'] as num?)?.toDouble() ?? 0,
        (json['pct'] as num?)?.toDouble() ?? 0,
      );
}

class MdEquipmentRanking {
  final List<MdEquipmentRankingRow> rows;
  final double totalKw;
  final double totalPct;
  const MdEquipmentRanking({required this.rows, required this.totalKw, required this.totalPct});

  factory MdEquipmentRanking.fromJson(Map<String, dynamic> json) => MdEquipmentRanking(
        rows: ((json['rows'] as List?) ?? [])
            .map((e) => MdEquipmentRankingRow.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        totalKw: (json['total_kw'] as num?)?.toDouble() ?? 0,
        totalPct: (json['total_pct'] as num?)?.toDouble() ?? 0,
      );
}

/// One row from `md_insight_report_log` — a past report generation, as
/// listed by the report page's "View Logs" menu.
class MdInsightReportLogEntry {
  final String reportId;
  final String plantCode;
  final String period;
  final String generatedAt;
  final String generatedBy;
  final String reportState;

  /// 'auto' — the canonical, locked snapshot written by the monthly rollup
  /// (or its backfill route) once a month closes; 'manual' — a Download-
  /// button-triggered log entry (today's only source before this field).
  final String source;

  /// For 'auto' rows: `{ "report": <same shape /md-insight-rules returns>,
  /// "inputs": {...} }` — see functions/helpers/mdInsightMonthlyRollup.js.
  /// Null for 'manual' rows (thin headline-figure payload only, not a full
  /// report snapshot) or if the row has no payload at all.
  final Map<String, dynamic>? payloadJson;

  const MdInsightReportLogEntry({
    required this.reportId,
    required this.plantCode,
    required this.period,
    required this.generatedAt,
    required this.generatedBy,
    required this.reportState,
    this.source = 'manual',
    this.payloadJson,
  });

  factory MdInsightReportLogEntry.fromJson(Map<String, dynamic> json) =>
      MdInsightReportLogEntry(
        reportId: json['report_id']?.toString() ?? '',
        plantCode: json['plant_code']?.toString() ?? '',
        period: json['period']?.toString() ?? '',
        generatedAt: json['generated_at']?.toString() ?? '',
        generatedBy: json['generated_by']?.toString() ?? '',
        reportState: json['report_state']?.toString() ?? '',
        source: json['source']?.toString() ?? 'manual',
        payloadJson: (json['payload_json'] as Map?)?.cast<String, dynamic>(),
      );
}

class MdInsightReport {
  final String reportState; // 'breach' | 'within' | 'unknown'
  final String reportDateLabel;
  final String periodLabel;
  final List<MdDailyPoint> dailySeries;
  final MdLoadAnalysis? loadAnalysis;
  final MdEquipmentRanking? equipmentRanking;
  final Map<String, List<MdRuleLine>> sections;
  final List<String> warnings;

  const MdInsightReport({
    required this.reportState,
    required this.reportDateLabel,
    required this.periodLabel,
    required this.dailySeries,
    required this.loadAnalysis,
    required this.equipmentRanking,
    required this.sections,
    required this.warnings,
  });

  static const empty = MdInsightReport(
    reportState: 'unknown',
    reportDateLabel: '',
    periodLabel: '',
    dailySeries: [],
    loadAnalysis: null,
    equipmentRanking: null,
    sections: {},
    warnings: [],
  );

  List<MdRuleLine> section(String key) => sections[key] ?? const [];

  MdRuleLine? rule(String ruleId) {
    for (final list in sections.values) {
      for (final line in list) {
        if (line.ruleId == ruleId) return line;
      }
    }
    return null;
  }

  factory MdInsightReport.fromJson(Map<String, dynamic> json) {
    final sectionsJson = (json['sections'] as Map?)?.cast<String, dynamic>() ?? {};
    final sections = <String, List<MdRuleLine>>{};
    for (final entry in sectionsJson.entries) {
      sections[entry.key] = ((entry.value as List?) ?? [])
          .map((e) => MdRuleLine.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return MdInsightReport(
      reportState: json['report_state']?.toString() ?? 'unknown',
      reportDateLabel: json['report_date_label']?.toString() ?? '',
      periodLabel: json['period_label']?.toString() ?? '',
      dailySeries: ((json['daily_series'] as List?) ?? [])
          .map((e) => MdDailyPoint.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      loadAnalysis: json['load_analysis'] != null
          ? MdLoadAnalysis.fromJson((json['load_analysis'] as Map).cast<String, dynamic>())
          : null,
      equipmentRanking: json['equipment_ranking'] != null
          ? MdEquipmentRanking.fromJson((json['equipment_ranking'] as Map).cast<String, dynamic>())
          : null,
      sections: sections,
      warnings: ((json['warnings'] as List?) ?? [])
          .map((e) => (e as Map)['rule_id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}
