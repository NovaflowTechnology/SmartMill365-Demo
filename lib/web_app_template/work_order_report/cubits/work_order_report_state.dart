part of './work_order_report_cubit.dart';

class WorkOrderReportState extends Equatable {
  const WorkOrderReportState({
    this.workOrderList = const [],
    this.equipmentList = const [],
  });

  final List<dynamic> workOrderList;
  final List<Map<String, dynamic>> equipmentList;

  @override
  List<Object?> get props => [workOrderList, equipmentList];

  WorkOrderReportState copyWith({
    List<dynamic>? workOrderList,
    List<Map<String, dynamic>>? equipmentList,
  }) {
    return WorkOrderReportState(
      workOrderList: workOrderList ?? this.workOrderList,
      equipmentList: equipmentList ?? this.equipmentList,
    );
  }
}
