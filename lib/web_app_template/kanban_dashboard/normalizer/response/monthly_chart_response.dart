import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class MonthlyChartResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;
  final String period;

  const MonthlyChartResponse({
    required this.data,
    this.period = 'Monthly',
  }) : super();
}