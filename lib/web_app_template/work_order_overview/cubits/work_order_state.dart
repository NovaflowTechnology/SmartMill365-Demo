part of './work_order_cubit.dart';

class WorkOrderState extends Equatable {
  const WorkOrderState({
    this.productList = const [],
    this.workOrderList = const [],
    this.downTimeCodeList = const [],
    this.status = FormzSubmissionStatus.initial,
  });

  final List<Map<String, dynamic>> productList;
  final List<dynamic> workOrderList;
  final List<Map<String, dynamic>> downTimeCodeList;
  final FormzSubmissionStatus status;

  @override
  List<Object?> get props =>
      [productList, workOrderList, downTimeCodeList, status];

  WorkOrderState copyWith({
    List<Map<String, dynamic>>? productList,
    List<dynamic>? workOrderList,
    List<Map<String, dynamic>>? downTimeCodeList,
    FormzSubmissionStatus? status,
  }) {
    return WorkOrderState(
      productList: productList ?? this.productList,
      workOrderList: workOrderList ?? this.workOrderList,
      downTimeCodeList: downTimeCodeList ?? this.downTimeCodeList,
      status: status ?? this.status,
    );
  }
}
