import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:smartmachine365/web_app_template/work_order_overview/cubits/cubits.dart';

part './work_order_state.dart';

class WorkOrderCubit extends Cubit<WorkOrderState> {
  WorkOrderCubit(this.repository) : super(const WorkOrderState());

  WorkOrderRepository repository;

  String get lastId {
    if (state.workOrderList.isNotEmpty) {
      state.workOrderList
          .sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));

      return state.workOrderList[0]['id'].toString();
    } else {
      return '';
    }
  }

  Future<void> init() async {
    try {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

      List<Map<String, dynamic>> productList = await repository.productList;
      List<Map<String, dynamic>> downTimeCodeList =
          await repository.downTimeCodeList;

      emit(state.copyWith(
          productList: productList,
          downTimeCodeList: downTimeCodeList,
          status: FormzSubmissionStatus.success));
    } catch (_) {}
  }

  void updateWorkOrderList(List<dynamic> workOrderList) =>
      emit(state.copyWith(workOrderList: workOrderList));

  Future<void> delete(String id) async {
    try {
      await repository.deleteWorkOrder(id);
    } catch (_) {
      rethrow;
    }
  }
}
