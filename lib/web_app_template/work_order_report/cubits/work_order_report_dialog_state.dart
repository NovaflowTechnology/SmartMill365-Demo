part of './work_order_report_dialog_cubit.dart';

class WorkOrderReportDialogState extends Equatable {
  const WorkOrderReportDialogState({
    this.quantityUpdateList = const [
      {'quantity': 0, 'ngQuantity': 0, 'timestamp': ''}
    ],
  });

  final List<Map<String, dynamic>> quantityUpdateList;

  @override
  List<Object?> get props => [quantityUpdateList];

  WorkOrderReportDialogState copyWith({
    List<Map<String, dynamic>>? quantityUpdateList,
  }) {
    return WorkOrderReportDialogState(
      quantityUpdateList: quantityUpdateList ?? this.quantityUpdateList,
    );
  }
}
