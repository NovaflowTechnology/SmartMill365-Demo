import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class Last24hChartResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> previousData;

  const Last24hChartResponse({
    required this.data,
    required this.previousData,
  }) : super();
}