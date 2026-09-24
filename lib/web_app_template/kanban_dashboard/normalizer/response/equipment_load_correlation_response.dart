// equipment_load_correlation_response.dart
import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class EquipmentLoadCorrelationResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;
  final Map<String, List<Map<String, dynamic>>> seriesData;
  final List<String> deviceIds;
  final double systemPeak;
  final String selectedEventDate;
  final String selectedEventStart;
  final String selectedEventEnd;

  const EquipmentLoadCorrelationResponse({
    required this.data,
    required this.seriesData,
    required this.deviceIds,
    this.systemPeak = 0.0,
    this.selectedEventDate = '',
    this.selectedEventStart = '',
    this.selectedEventEnd = '',
  }) : super();
}