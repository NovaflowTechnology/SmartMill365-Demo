import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/web_app_template/work_order_report/cubits/cubits.dart';

part './work_order_report_state.dart';

class WorkOrderReportCubit extends Cubit<WorkOrderReportState> {
  WorkOrderReportCubit(this.repository) : super(const WorkOrderReportState());

  WorkOrderReportRepository repository;

  Future<void> init() async {
    try {
      List<Map<String, dynamic>> equipmentList = await repository.equipmentList;

      emit(state.copyWith(equipmentList: equipmentList));
    } catch (_) {}
  }

  void updateWorkOrderList(List<dynamic> workOrderList) =>
      emit(state.copyWith(workOrderList: workOrderList));

  String getEquipmentName(String id) {
    if (id.isNotEmpty) {
      return state.equipmentList
          .firstWhere((equipment) => equipment['id'] == id)['name'];
    } else {
      return '';
    }
  }

  Future<void> save(
      {required String id, required Map<String, dynamic> data}) async {
    try {
      await repository.updateWorkOrder(id: id, data: data);
    } catch (_) {}
  }
}
