import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class HourlyChartResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> previousData;
  final DateTime selectedDate;

  const HourlyChartResponse({
    required this.data,
    required this.previousData,
    required this.selectedDate,
  }) : super();
}