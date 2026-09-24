// daily_max_demand_response.dart
import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class DailyMaxDemandResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;       
  final double contractCapacity;

  const DailyMaxDemandResponse({
    required this.data,
    this.contractCapacity = 0.0,
  }) : super();
}