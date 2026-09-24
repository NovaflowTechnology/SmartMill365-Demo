// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smartmachine365/web_app_template/work_order_report/cubits/cubits.dart';

class WorkOrderReportCheckInDialog extends StatefulWidget {
  const WorkOrderReportCheckInDialog(
      {super.key, required this.workOrder, required this.onWorkOrderCheckedIn});

  final Map<String, dynamic> workOrder;
  final VoidCallback onWorkOrderCheckedIn;

  @override
  State<WorkOrderReportCheckInDialog> createState() =>
      _WorkOrderReportCheckInDialogState();
}

class _WorkOrderReportCheckInDialogState
    extends State<WorkOrderReportCheckInDialog> {
  ScrollController scrollController = ScrollController();
  TextEditingController idController = TextEditingController();
  TextEditingController operatorController = TextEditingController();
  TextEditingController equipmentController = TextEditingController();
  TextEditingController startDateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    idController.text = widget.workOrder['id'];
    operatorController.text = widget.workOrder['operator'];
    equipmentController.text = getEquipmentName(widget.workOrder['equipment']);
    startDateController.text = widget.workOrder['actualStartDate'];
  }

  @override
  void dispose() {
    scrollController.dispose();
    idController.dispose();
    operatorController.dispose();
    equipmentController.dispose();
    startDateController.dispose();

    super.dispose();
  }

  String getEquipmentName(String id) {
    try {
      return context
          .read<WorkOrderReportCubit>()
          .state
          .equipmentList
          .firstWhere((equipment) => equipment['id'] == id)['name'];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkOrderReportCubit, WorkOrderReportState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text(
            'WO Check In Report',
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
                      _TextField(operatorController),
                    ],
                  ),
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
                      _TextField(startDateController, isCalendar: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                try {
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: const Text(
                          'Work order will be checked in. Please confirm.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await context
                                  .read<WorkOrderReportCubit>()
                                  .save(id: idController.text, data: {
                                'operator': operatorController.text,
                                'status': 1,
                                'actualStartDate': startDateController.text,
                                'isCheckedIn': true
                              }).then((_) {
                                widget.onWorkOrderCheckedIn();
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
              child: const Text('Check In'),
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
      {this.isCalendar = false, this.enabled = true});

  final TextEditingController controller;
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
        style: const TextStyle(fontSize: 14.0),
        textAlign: TextAlign.center,
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
