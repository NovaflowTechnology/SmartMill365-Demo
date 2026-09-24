// year_on_year_analysis_response.dart
import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class YearOnYearAnalysisResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> comparisonYearData;
  final double contractCapacity;

  const YearOnYearAnalysisResponse({
    required this.data,
    required this.comparisonYearData,
    this.contractCapacity = 0.0,
  }) : super();
}