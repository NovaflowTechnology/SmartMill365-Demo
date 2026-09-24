part of './work_order_dialog_cubit.dart';

class WorkOrderDialogState extends Equatable {
  const WorkOrderDialogState({
    this.id = '',
    this.sales = '',
    this.product = '',
    this.quantity = 0,
    this.unit = '',
    this.material = '',
    this.planStartDate = '',
    this.actualStartDate = '',
    this.urgency = '',
    this.progress = 0,
    this.planEndDate = '',
    this.actualEndDate = '',
    this.planCycleTime = 0,
    this.operatingTime = 0,
    this.totalPlanProdTime = 0,
    this.totalPlanCycleTime = 0,
    this.planEndTime = '',
    this.totalPlanDownTime = 0,
    this.planDownTimeList = const [],
    this.isCheckedIn = false,
    this.status = 0,
    this.equipment = '',
    this.operator = '',
    this.totalQuantityUpdate = 0,
    this.totalNgQuantity = 0,
    this.quantityUpdateList = const [],
    this.processList = const [],
  });

  final String id;
  final String sales;
  final String product;
  final int quantity;
  final String unit;
  final String material;
  final String planStartDate;
  final String actualStartDate;
  final String urgency;
  final int progress;
  final String planEndDate;
  final String actualEndDate;
  final int planCycleTime;
  final int operatingTime;
  final int totalPlanProdTime;
  final int totalPlanCycleTime;
  final String planEndTime;
  final int totalPlanDownTime;
  final List<Map<String, dynamic>> planDownTimeList;
  final bool isCheckedIn;
  final int status;
  final String equipment;
  final String operator;
  final int totalQuantityUpdate;
  final int totalNgQuantity;
  final List<Map<String, dynamic>> quantityUpdateList;
  final List<Map<String, dynamic>> processList;

  @override
  List<Object?> get props => [
        id,
        sales,
        product,
        quantity,
        unit,
        material,
        planStartDate,
        actualStartDate,
        urgency,
        progress,
        planEndDate,
        actualEndDate,
        planCycleTime,
        operatingTime,
        totalPlanProdTime,
        totalPlanCycleTime,
        planEndTime,
        totalPlanDownTime,
        planDownTimeList,
        isCheckedIn,
        status,
        equipment,
        operator,
        totalQuantityUpdate,
        totalNgQuantity,
        quantityUpdateList,
        processList
      ];

  WorkOrderDialogState copyWith({
    String? id,
    String? sales,
    String? product,
    int? quantity,
    String? unit,
    String? material,
    String? planStartDate,
    String? actualStartDate,
    String? urgency,
    int? progress,
    String? planEndDate,
    String? actualEndDate,
    int? planCycleTime,
    int? operatingTime,
    int? totalPlanProdTime,
    int? totalPlanCycleTime,
    String? planEndTime,
    int? totalPlanDownTime,
    List<Map<String, dynamic>>? planDownTimeList,
    bool? isCheckedIn,
    int? status,
    String? equipment,
    String? operator,
    int? totalQuantityUpdate,
    int? totalNgQuantity,
    List<Map<String, dynamic>>? quantityUpdateList,
    List<Map<String, dynamic>>? processList,
  }) {
    return WorkOrderDialogState(
      id: id ?? this.id,
      sales: sales ?? this.sales,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      material: material ?? this.material,
      planStartDate: planStartDate ?? this.planStartDate,
      actualStartDate: actualStartDate ?? this.actualStartDate,
      urgency: urgency ?? this.urgency,
      progress: progress ?? this.progress,
      planEndDate: planEndDate ?? this.planEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      planCycleTime: planCycleTime ?? this.planCycleTime,
      operatingTime: operatingTime ?? this.operatingTime,
      totalPlanProdTime: totalPlanProdTime ?? this.totalPlanProdTime,
      totalPlanCycleTime: totalPlanCycleTime ?? this.totalPlanCycleTime,
      planEndTime: planEndTime ?? this.planEndTime,
      totalPlanDownTime: totalPlanDownTime ?? this.totalPlanDownTime,
      planDownTimeList: planDownTimeList ?? this.planDownTimeList,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      operator: operator ?? this.operator,
      totalQuantityUpdate: totalQuantityUpdate ?? this.totalQuantityUpdate,
      totalNgQuantity: totalNgQuantity ?? this.totalNgQuantity,
      quantityUpdateList: quantityUpdateList ?? this.quantityUpdateList,
      processList: processList ?? this.processList,
    );
  }
}
