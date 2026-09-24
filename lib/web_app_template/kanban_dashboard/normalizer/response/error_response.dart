import 'package:smartmachine365/web_app_template/kanban_dashboard/normalizer/response/kanban_cell_response.dart';

final class ErrorResponse extends KanbanCellResponse {
  const ErrorResponse(String message) : super(error: message);
}