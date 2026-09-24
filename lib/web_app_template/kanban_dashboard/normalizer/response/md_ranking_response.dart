import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class MdRankingResponse extends KanbanCellResponse {
  final List<Map<String, dynamic>> data;

  const MdRankingResponse({required this.data}) : super();
}
