import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/web_app_template/work_order_report/cubits/cubits.dart';

part './work_order_report_dialog_state.dart';

class WorkOrderReportDialogCubit extends Cubit<WorkOrderReportDialogState> {
  WorkOrderReportDialogCubit(this.workOrderReportCubit)
      : super(const WorkOrderReportDialogState());

  WorkOrderReportCubit workOrderReportCubit;

  List<Map<String, dynamic>> get equipmentList =>
      workOrderReportCubit.state.equipmentList;

  void init(Map<String, dynamic> data) {
    List<Map<String, dynamic>> quantityUpdateList =
        ((data['quantityUpdateList'] ?? []) as List<dynamic>)
            .map((d) => Map<String, dynamic>.from(d))
            .toList();

    emit(state.copyWith(quantityUpdateList: quantityUpdateList));
  }

  void updateQuantityUpdateList(
      {required int index, required String key, required dynamic value}) {
    List<Map<String, dynamic>> quantityUpdateList = state.quantityUpdateList
        .map((quantityUpdate) => Map<String, dynamic>.from(quantityUpdate))
        .toList();
    quantityUpdateList[index][key] = value;

    emit(state.copyWith(quantityUpdateList: quantityUpdateList));
  }

  void manageQuantityUpdateList({int? index}) {
    List<Map<String, dynamic>> quantityUpdateList = state.quantityUpdateList
        .map((quantityUpdate) => Map<String, dynamic>.from(quantityUpdate))
        .toList();

    if (index == null) {
      quantityUpdateList.add({'quantity': 0, 'ngQuantity': 0, 'timestamp': ''});
    } else {
      quantityUpdateList.removeAt(index);
    }

    emit(state.copyWith(quantityUpdateList: quantityUpdateList));
  }

  Future<void> save(
      {required String id, required Map<String, dynamic> data}) async {
    try {
      await workOrderReportCubit.repository.updateWorkOrder(id: id, data: data);
    } catch (_) {
      rethrow;
    }
  }
}
