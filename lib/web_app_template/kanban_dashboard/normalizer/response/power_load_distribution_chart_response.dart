// power_load_distribution_response.dart
import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class PowerLoadDistributionResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;        // time_period + average_power_load_kW + total_energy_kWh + hours_count

  const PowerLoadDistributionResponse({
    required this.data,
  }) : super();
}