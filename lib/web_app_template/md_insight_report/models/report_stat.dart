/// A single labeled stat shown under a chart (e.g. "Peak Load" → "5418 kW").
class ReportStat {
  final String label;
  final String value;

  const ReportStat(this.label, this.value);
}
