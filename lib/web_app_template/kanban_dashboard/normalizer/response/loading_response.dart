import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class LoadingResponse extends KanbanCellResponse {
  const LoadingResponse() : super(isLoading: true);
}