// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/web_app_template/work_order_report/cubits/cubits.dart';

class WorkOrderReportInProgressDialog extends StatefulWidget {
  const WorkOrderReportInProgressDialog(
      {super.key, required this.workOrder, required this.onWorkOrderUpdated});

  final Map<String, dynamic> workOrder;
  final VoidCallback onWorkOrderUpdated;

  @override
  State<WorkOrderReportInProgressDialog> createState() =>
      _WorkOrderReportInProgressDialogState();
}

class _WorkOrderReportInProgressDialogState
    extends State<WorkOrderReportInProgressDialog> {
  ScrollController scrollController = ScrollController();
  TextEditingController idController = TextEditingController();
  TextEditingController operatorController = TextEditingController();
  TextEditingController equipmentController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController totalQuantityUpdateController = TextEditingController();
  TextEditingController totalNgQuantityController = TextEditingController();
  List<List<TextEditingController>> quantityUpdateControllerList = [];

  @override
  void initState() {
    super.initState();

    idController.text = widget.workOrder['id'];
    operatorController.text = widget.workOrder['operator'];
    equipmentController.text = getEquipmentName(widget.workOrder['equipment']);
    startDateController.text = widget.workOrder['actualStartDate'];
    totalQuantityUpdateController.text =
        widget.workOrder['totalQuantityUpdate'].toString();
    totalNgQuantityController.text =
        widget.workOrder['totalNgQuantity'].toString();

    if (context
        .read<WorkOrderReportDialogCubit>()
        .state
        .quantityUpdateList
        .isNotEmpty) {
      quantityUpdateControllerList = List.generate(
          context
              .read<WorkOrderReportDialogCubit>()
              .state
              .quantityUpdateList
              .length,
          (index) => [
                TextEditingController(
                    text: context
                        .read<WorkOrderReportDialogCubit>()
                        .state
                        .quantityUpdateList[index]['quantity']
                        .toString()),
                TextEditingController(
                    text: context
                        .read<WorkOrderReportDialogCubit>()
                        .state
                        .quantityUpdateList[index]['ngQuantity']
                        .toString()),
                TextEditingController(
                    text: context
                        .read<WorkOrderReportDialogCubit>()
                        .state
                        .quantityUpdateList[index]['timestamp'])
              ]);
    } else {
      quantityUpdateControllerList = List.generate(
          context
              .read<WorkOrderReportDialogCubit>()
              .state
              .quantityUpdateList
              .length,
          (index) => [
                TextEditingController(),
                TextEditingController(),
                TextEditingController()
              ]);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    idController.dispose();
    operatorController.dispose();
    equipmentController.dispose();
    startDateController.dispose();
    totalQuantityUpdateController.dispose();
    totalNgQuantityController.dispose();

    for (int i = 0; i < quantityUpdateControllerList.length; i++) {
      for (int j = 0; j < quantityUpdateControllerList[i].length; j++) {
        quantityUpdateControllerList[i][j].dispose();
      }
    }

    super.dispose();
  }

  String getEquipmentName(String id) {
    try {
      return context
          .read<WorkOrderReportDialogCubit>()
          .equipmentList
          .firstWhere((equipment) => equipment['id'] == id)['name'];
    } catch (_) {
      return '';
    }
  }

  void calculate() {
    // Total Quantity Update
    totalQuantityUpdateController.text = '0';
    for (int i = 0; i < quantityUpdateControllerList.length; i++) {
      int quantity = int.tryParse(quantityUpdateControllerList[i][0].text) ?? 0;
      int totalQuantityUpdate =
          int.tryParse(totalQuantityUpdateController.text) ?? 0;
      totalQuantityUpdateController.text =
          (totalQuantityUpdate + quantity).toString();
    }

    // Total NG Quantity
    totalNgQuantityController.text = '0';
    for (int i = 0; i < quantityUpdateControllerList.length; i++) {
      int ngQuantity =
          int.tryParse(quantityUpdateControllerList[i][1].text) ?? 0;
      int totalNgQuantity = int.tryParse(totalNgQuantityController.text) ?? 0;
      totalNgQuantityController.text =
          (totalNgQuantity + ngQuantity).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkOrderReportDialogCubit, WorkOrderReportDialogState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text(
            'WO In Progress Report',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16.0,
                children: [
                  Row(
                    spacing: 16.0,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Work Order ID'),
                          _TextField(idController, enabled: false),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Operator ID'),
                          _TextField(operatorController, enabled: false),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    spacing: 16.0,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Assigned Work Station'),
                          _TextField(equipmentController, enabled: false),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Start Production'),
                          _TextField(startDateController, enabled: false),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    spacing: 16.0,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Total Quantity Update'),
                          _TextField(totalQuantityUpdateController,
                              enabled: false),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Total NG Quantity'),
                          _TextField(totalNgQuantityController, enabled: false),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 80.0),
                  Visibility(
                    visible: state.quantityUpdateList.isNotEmpty,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Total Quantity')),
                        DataColumn(label: Text('NG Parts Quantity')),
                        DataColumn(label: SizedBox()),
                        DataColumn(label: SizedBox()),
                      ],
                      dataRowHeight: 64.0,
                      horizontalMargin: 0,
                      columnSpacing: 8.0,
                      dividerThickness: 0.00000000001,
                      rows: state.quantityUpdateList
                          .mapIndexed((i, quantityUpdate) => DataRow(cells: [
                                DataCell(_TextField(
                                    quantityUpdateControllerList[i][0],
                                    isNumber: true)),
                                DataCell(_TextField(
                                    quantityUpdateControllerList[i][1],
                                    isNumber: true)),
                                DataCell(_TextField(
                                    quantityUpdateControllerList[i][2],
                                    isCalendar: true)),
                                DataCell(IconButton(
                                  color: Colors.red,
                                  onPressed: () {
                                    context
                                        .read<WorkOrderReportDialogCubit>()
                                        .manageQuantityUpdateList(index: i);
                                    quantityUpdateControllerList.removeAt(i);
                                  },
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                )),
                              ]))
                          .toList(),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context
                          .read<WorkOrderReportDialogCubit>()
                          .manageQuantityUpdateList();
                      quantityUpdateControllerList.add([
                        TextEditingController(),
                        TextEditingController(),
                        TextEditingController()
                      ]);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Partially Quantity Update'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Visibility(
              visible: widget.workOrder['status'] != 2,
              child: TextButton(
                onPressed: () => calculate(),
                child: const Text('Calculate'),
              ),
            ),
            const SizedBox(width: 8.0),
            Visibility(
              visible: widget.workOrder['status'] != 2,
              child: TextButton(
                onPressed: () async {
                  try {
                    calculate();

                    List<Map<String, dynamic>> quantityUpdateList = state
                        .quantityUpdateList
                        .map((quantityUpdate) =>
                            Map<String, dynamic>.from(quantityUpdate))
                        .toList();

                    for (int i = 0; i < quantityUpdateList.length; i++) {
                      quantityUpdateList[i]['quantity'] = int.tryParse(
                              quantityUpdateControllerList[i][0].text) ??
                          0;
                      quantityUpdateList[i]['ngQuantity'] = int.tryParse(
                              quantityUpdateControllerList[i][1].text) ??
                          0;
                      quantityUpdateList[i]['timestamp'] =
                          quantityUpdateControllerList[i][2].text;
                    }

                    Map<String, dynamic> data = {
                      'quantityUpdateList': quantityUpdateList,
                      'totalQuantityUpdate':
                          int.tryParse(totalQuantityUpdateController.text) ?? 0,
                      'totalNgQuantity':
                          int.tryParse(totalNgQuantityController.text) ?? 0
                    };

                    await context
                        .read<WorkOrderReportDialogCubit>()
                        .save(id: idController.text, data: data)
                        .then((_) {
                      widget.onWorkOrderUpdated();
                      Navigator.of(context).pop();
                    });
                  } catch (_) {
                    rethrow;
                  }
                },
                child: const Text('Save'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8.0),
            Visibility(
              visible: widget.workOrder['status'] != 2,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: const Text(
                            'Work order will complete its production. Please confirm.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await context
                                    .read<WorkOrderReportDialogCubit>()
                                    .save(id: idController.text, data: {
                                  'status': 2,
                                  'actualEndDate':
                                      DateFormat('yyyyMMdd HH:mm:ss')
                                          .format(DateTime.now())
                                }).then((_) {
                                  widget.onWorkOrderUpdated();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                });
                              } catch (_) {
                                rethrow;
                              }
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );
                  } catch (_) {}
                },
                child: const Text('Complete Production'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TextFieldLabel extends StatelessWidget {
  const _TextFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.0,
      child: TextField(
        controller: TextEditingController(text: text),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.blueGrey[50],
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(100.0),
          ),
          enabled: false,
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField(this.controller,
      {this.isNumber = false, this.isCalendar = false, this.enabled = true});

  final TextEditingController controller;
  final bool isNumber;
  final bool isCalendar;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.0,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          suffixIcon:
              isCalendar ? const Icon(Icons.calendar_today_outlined) : null,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : null,
        style: const TextStyle(fontSize: 14.0),
        textAlign: TextAlign.center,
        inputFormatters:
            isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        enabled: enabled,
        onTap: () async {
          if (isCalendar) {
            try {
              await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              ).then((date) async {
                if (date != null) {
                  await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  ).then((time) {
                    if (time != null) {
                      controller.text = DateFormat('yyyyMMdd HH:mm:ss').format(
                          DateTime(date.year, date.month, date.day, time.hour,
                              time.minute));
                    }
                  });
                }
              });
            } catch (_) {}
          }
        },
      ),
    );
  }
}
