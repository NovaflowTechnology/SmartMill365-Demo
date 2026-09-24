import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smartmachine365/web_app_template/work_order_overview/cubits/cubits.dart';

part './work_order_dialog_state.dart';

class WorkOrderDialogCubit extends Cubit<WorkOrderDialogState> {
  WorkOrderDialogCubit(this.workOrderCubit, {this.isNew = true})
      : super(const WorkOrderDialogState());

  WorkOrderCubit workOrderCubit;
  bool isNew;

  String get _id {
    String date = DateFormat('yyyyMMdd').format(DateTime.now());
    RegExp regexp = RegExp(r'WO-(\d{8})-(\d{4})');
    RegExpMatch? match = regexp.firstMatch(workOrderCubit.lastId);

    if (match != null) {
      String lastDate = match.group(1)!;
      int lastIndex = int.parse(match.group(2)!);
      int index = (lastDate == date) ? lastIndex + 1 : 1;
      String indexFormat = index.toString().padLeft(4, '0');

      return 'WO-$date-$indexFormat';
    } else {
      return 'WO-$date-0001';
    }
  }

  List<Map<String, dynamic>> get productList =>
      workOrderCubit.state.productList;

  List<Map<String, dynamic>> get urgencyList =>
      workOrderCubit.repository.urgencyList;

  List<Map<String, dynamic>> get downTimeCodeList =>
      workOrderCubit.state.downTimeCodeList;

  void init({Map<String, dynamic> data = const {}}) {
    if (isNew) {
      emit(state.copyWith(id: _id));
    } else {
      if (data.isNotEmpty) {
        List<Map<String, dynamic>> planDownTimeList =
            ((data['planDownTimeList'] ?? []) as List<dynamic>)
                .map((d) => Map<String, dynamic>.from(d))
                .toList();
        List<Map<String, dynamic>> quantityUpdateList =
            ((data['quantityUpdateList'] ?? []) as List<dynamic>)
                .map((d) => Map<String, dynamic>.from(d))
                .toList();
        List<Map<String, dynamic>> processList =
            ((data['processList'] ?? []) as List<dynamic>)
                .map((d) => Map<String, dynamic>.from(d))
                .toList();

        emit(state.copyWith(
            id: data['id'],
            sales: data['sales'],
            product: data['product'],
            quantity: data['quantity'],
            unit: data['unit'],
            material: data['material'],
            planStartDate: data['planStartDate'],
            actualStartDate: data['actualStartDate'],
            urgency: data['urgency'],
            progress: data['progress'],
            planEndDate: data['planEndDate'],
            actualEndDate: data['actualEndDate'],
            planCycleTime: data['planCycleTime'],
            operatingTime: data['operatingTime'],
            totalPlanProdTime: data['totalPlanProdTime'],
            totalPlanCycleTime: data['totalPlanCycleTime'],
            planEndTime: data['planEndTime'],
            totalPlanDownTime: data['totalPlanDownTime'],
            planDownTimeList: planDownTimeList,
            isCheckedIn: data['isCheckedIn'],
            status: data['status'],
            equipment: data['equipment'],
            operator: data['operator'],
            quantityUpdateList: quantityUpdateList,
            processList: processList));
      }
    }
  }

  void updateProduct(String product) => emit(state.copyWith(product: product));

  void updateUrgency(String urgency) => emit(state.copyWith(urgency: urgency));

  void updatePlanDownTimeList(
      {required int index, required String key, required dynamic value}) {
    List<Map<String, dynamic>> planDownTimeList = state.planDownTimeList
        .map((planDownTime) => Map<String, dynamic>.from(planDownTime))
        .toList();
    planDownTimeList[index][key] = value;

    emit(state.copyWith(planDownTimeList: planDownTimeList));
  }

  void managePlanDownTimeList({int? index}) {
    List<Map<String, dynamic>> planDownTimeList = state.planDownTimeList
        .map((planDownTime) => Map<String, dynamic>.from(planDownTime))
        .toList();

    if (index == null) {
      planDownTimeList.add(
          {'code': '', 'duration': 0, 'option': false, 'totalDuration': 0});
    } else {
      planDownTimeList.removeAt(index);
    }

    emit(state.copyWith(planDownTimeList: planDownTimeList));
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      if (isNew) {
        await workOrderCubit.repository.addWorkOrder(id: state.id, data: data);
      } else {
        await workOrderCubit.repository
            .updateWorkOrder(id: state.id, data: data);
      }
    } catch (_) {
      rethrow;
    }
  }

  void updateProcessList(
      {required int index, required String key, required dynamic value}) {
    List<Map<String, dynamic>> processList = state.processList
        .map((process) => Map<String, dynamic>.from(process))
        .toList();
    processList[index][key] = value;

    emit(state.copyWith(processList: processList));
  }

  void manageProcessList({int? index}) {
    List<Map<String, dynamic>> processList = state.processList
        .map((process) => Map<String, dynamic>.from(process))
        .toList();

    if (index == null) {
      processList.add({'name': '', 'urgency': ''});
    } else {
      processList.removeAt(index);
    }

    emit(state.copyWith(processList: processList));
  }
}
