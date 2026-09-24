import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class PowerLoadTrend24hResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;      
  final List<Map<String, dynamic>> powerLoadData;
  final double maxPowerKw;
  final double minPowerKw;
  final double contractCapacity;

  const PowerLoadTrend24hResponse({
    required this.data,
    required this.powerLoadData,
    this.maxPowerKw = 0.0,
    this.minPowerKw = 0.0,
    this.contractCapacity = 0.0,
  }) : super();
}