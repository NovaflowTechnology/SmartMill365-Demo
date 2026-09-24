import 'package:smartmachine365/web_app_template/kanban_dashboard/models/response.dart';

class CellStateModel {
  final KanbanCellResponse? result;

  const CellStateModel({this.result});

  bool get isLoading => result is LoadingResponse;
  String? get error => result?.error;
}
