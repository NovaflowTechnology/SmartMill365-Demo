// ignore_for_file: unused_element_parameter

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/web_app_template/work_order_overview/cubits/cubits.dart';

class WorkOrderDialog extends StatefulWidget {
  const WorkOrderDialog({super.key, required this.onWorkOrderAdded});

  final VoidCallback onWorkOrderAdded;

  @override
  State<WorkOrderDialog> createState() => _WorkOrderDialogState();
}

class _WorkOrderDialogState extends State<WorkOrderDialog> {
  ScrollController scrollController = ScrollController();
  TextEditingController idController = TextEditingController();
  TextEditingController salesController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController materialController = TextEditingController();
  TextEditingController planStartDateController = TextEditingController();
  TextEditingController actualStartDateController = TextEditingController();
  TextEditingController progressController = TextEditingController();
  TextEditingController planEndDateController = TextEditingController();
  TextEditingController actualEndDateController = TextEditingController();
  TextEditingController planCycleTimeController = TextEditingController();
  TextEditingController operatingTimeController =
      TextEditingController(text: '0');
  TextEditingController totalPlanProdTimeController =
      TextEditingController(text: '0');
  TextEditingController totalPlanCycleTimeController =
      TextEditingController(text: '0');
  TextEditingController planEndTimeController = TextEditingController();
  TextEditingController totalPlanDownTimeController =
      TextEditingController(text: '0');
  List<List<dynamic>> planDownTimeControllerList = [];
  String? _errorMessage;
  List<List<dynamic>> processControllerList = [];

  @override
  void initState() {
    super.initState();

    idController.text = context.read<WorkOrderDialogCubit>().state.id;

    if (!context.read<WorkOrderDialogCubit>().isNew) {
      salesController.text = context.read<WorkOrderDialogCubit>().state.sales;
      quantityController.text =
          context.read<WorkOrderDialogCubit>().state.quantity.toString();
      unitController.text = context.read<WorkOrderDialogCubit>().state.unit;
      materialController.text =
          context.read<WorkOrderDialogCubit>().state.material;
      planStartDateController.text =
          context.read<WorkOrderDialogCubit>().state.planStartDate;
      actualStartDateController.text =
          context.read<WorkOrderDialogCubit>().state.actualStartDate;
      progressController.text =
          context.read<WorkOrderDialogCubit>().state.progress.toString();
      planEndDateController.text =
          context.read<WorkOrderDialogCubit>().state.planEndDate;
      actualEndDateController.text =
          context.read<WorkOrderDialogCubit>().state.actualEndDate;
      planCycleTimeController.text =
          context.read<WorkOrderDialogCubit>().state.planCycleTime.toString();
      operatingTimeController.text =
          context.read<WorkOrderDialogCubit>().state.operatingTime.toString();
      totalPlanProdTimeController.text = context
          .read<WorkOrderDialogCubit>()
          .state
          .totalPlanProdTime
          .toString();
      totalPlanCycleTimeController.text = context
          .read<WorkOrderDialogCubit>()
          .state
          .totalPlanCycleTime
          .toString();
      planEndTimeController.text =
          context.read<WorkOrderDialogCubit>().state.planEndTime;
      totalPlanDownTimeController.text = context
          .read<WorkOrderDialogCubit>()
          .state
          .totalPlanDownTime
          .toString();
      planDownTimeControllerList = List.generate(
          context.read<WorkOrderDialogCubit>().state.planDownTimeList.length,
          (index) => [
                TextEditingController(
                    text: context
                        .read<WorkOrderDialogCubit>()
                        .state
                        .planDownTimeList[index]['duration']
                        .toString()),
                context
                    .read<WorkOrderDialogCubit>()
                    .state
                    .planDownTimeList[index]['option'],
                TextEditingController(
                    text: context
                        .read<WorkOrderDialogCubit>()
                        .state
                        .planDownTimeList[index]['totalDuration']
                        .toString())
              ]);
      processControllerList = List.generate(
          context.read<WorkOrderDialogCubit>().state.processList.length,
          (index) => [
                TextEditingController(
                    text: context
                        .read<WorkOrderDialogCubit>()
                        .state
                        .processList[index]['name'])
              ]);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    idController.dispose();
    salesController.dispose();
    quantityController.dispose();
    unitController.dispose();
    materialController.dispose();
    planStartDateController.dispose();
    actualStartDateController.dispose();
    progressController.dispose();
    planEndDateController.dispose();
    actualEndDateController.dispose();
    planCycleTimeController.dispose();
    operatingTimeController.dispose();
    totalPlanProdTimeController.dispose();
    totalPlanCycleTimeController.dispose();
    planEndTimeController.dispose();
    totalPlanDownTimeController.dispose();

    for (int i = 0; i < planDownTimeControllerList.length; i++) {
      for (int j = 0; j < planDownTimeControllerList[i].length; j++) {
        if (planDownTimeControllerList[i][j] is TextEditingController) {
          (planDownTimeControllerList[i][j] as TextEditingController).dispose();
        }
      }
    }

    for (int i = 0; i < processControllerList.length; i++) {
      for (int j = 0; j < processControllerList[i].length; j++) {
        if (processControllerList[i][j] is TextEditingController) {
          (processControllerList[i][j] as TextEditingController).dispose();
        }
      }
    }

    super.dispose();
  }

  void calculate() {
    // Theoretical Operating Time
    int planCycleTime = int.tryParse(planCycleTimeController.text) ?? 0;
    int quantity = int.tryParse(quantityController.text) ?? 0;
    operatingTimeController.text = (planCycleTime * quantity).toString();

    // Total Planned Down Time
    totalPlanDownTimeController.text = '0';
    for (int i = 0; i < planDownTimeControllerList.length; i++) {
      int totalDuration = int.tryParse(
              (planDownTimeControllerList[i][2] as TextEditingController)
                  .text) ??
          0;
      int totalPlanDownTime =
          int.tryParse(totalPlanDownTimeController.text) ?? 0;
      totalPlanDownTimeController.text =
          (totalPlanDownTime + totalDuration).toString();
    }

    // Total Planned Production Time
    int operatingTime = int.tryParse(operatingTimeController.text) ?? 0;
    int totalPlanDownTime = int.tryParse(totalPlanDownTimeController.text) ?? 0;
    totalPlanProdTimeController.text =
        (operatingTime + totalPlanDownTime).toString();

    // Total Planned Cycle Time
    totalPlanCycleTimeController.text =
        ((planCycleTime * quantity) + totalPlanDownTime).toString();

    // Planned Completion Time
    DateTime? planStartDate = DateTime.tryParse(planStartDateController.text);

    if (planStartDate != null) {
      planStartDate = planStartDate.add(Duration(minutes: operatingTime));
      planStartDate = planStartDate.add(Duration(minutes: totalPlanDownTime));
      planEndTimeController.text =
          DateFormat('yyyy-MM-dd HH:mm').format(planStartDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkOrderDialogCubit, WorkOrderDialogState>(
      builder: (context, state) {
        return AlertDialog(
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
                      const _TextFieldLabel('Work Order ID*'),
                      _TextField(idController, enabled: false),
                    ],
                  ),
                  Row(
                    spacing: 16.0,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Sales Order ID*'),
                          _TextField(salesController),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Product ID*'),
                          SizedBox(
                            width: 240.0,
                            child: Row(
                              spacing: 8.0,
                              children: [
                                Flexible(
                                  child: _DropdownButton<Map<String, dynamic>>(
                                    selectedItem: state.product.isNotEmpty
                                        ? context
                                            .read<WorkOrderDialogCubit>()
                                            .productList
                                            .firstWhere((product) =>
                                                product['id'] == state.product)
                                        : null,
                                    onChanged: (product) {
                                      if (product != null) {
                                        context
                                            .read<WorkOrderDialogCubit>()
                                            .updateProduct(product['id']);
                                      }
                                    },
                                    items: context
                                        .read<WorkOrderDialogCubit>()
                                        .productList,
                                    dropdownBuilder:
                                        (context, selectedProduct) => Text(
                                      selectedProduct != null
                                          ? selectedProduct['name']
                                          : '',
                                      style: const TextStyle(fontSize: 14.0),
                                      textAlign: TextAlign.center,
                                    ),
                                    filterFn: (product, filter) =>
                                        product['name']
                                            .toString()
                                            .toLowerCase()
                                            .contains(filter.toLowerCase()),
                                    itemAsString: (product) => product['name'],
                                    compareFn: (product1, product2) =>
                                        product1['id'] == product2['id'],
                                    itemBuilder: (context, product, isDisabled,
                                            isSelected) =>
                                        ListTile(
                                      title: Text(product['name']),
                                      selectedColor: Colors.black,
                                      titleTextStyle:
                                          const TextStyle(fontSize: 14.0),
                                      selected: isSelected,
                                      selectedTileColor: Colors.blueGrey[50],
                                    ),
                                    disabledItemFn: (product) =>
                                        product['id'] == state.product,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      await context
                                          .pushNamed('ProductSettings');
                                    } catch (_) {}
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                          ),
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
                          const _TextFieldLabel('Quantity*'),
                          SizedBox(
                            width: 240.0,
                            child: Row(
                              spacing: 8.0,
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: _TextField(
                                    quantityController,
                                    isFlexible: true,
                                    isNumber: true,
                                  ),
                                ),
                                const Flexible(
                                  child: _TextFieldLabel('Unit*',
                                      isFlexible: true),
                                ),
                                Flexible(child: _TextField(unitController)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Material Order ID*'),
                          _TextField(materialController),
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
                          const _TextFieldLabel('Planned Start Date*'),
                          _TextField(planStartDateController, isCalendar: true),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Actual Start Date'),
                          _TextField(actualStartDateController,
                              isCalendar: true),
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
                          const _TextFieldLabel('Urgency Level*'),
                          SizedBox(
                            width: 240.0,
                            child: _DropdownButton<Map<String, dynamic>>(
                              selectedItem: state.urgency.isNotEmpty
                                  ? context
                                      .read<WorkOrderDialogCubit>()
                                      .urgencyList
                                      .firstWhere((urgency) =>
                                          urgency['id'] == state.urgency)
                                  : null,
                              onChanged: (urgency) {
                                if (urgency != null) {
                                  context
                                      .read<WorkOrderDialogCubit>()
                                      .updateUrgency(urgency['id']);
                                }
                              },
                              items: context
                                  .read<WorkOrderDialogCubit>()
                                  .urgencyList,
                              dropdownBuilder: (context, selectedUrgency) =>
                                  Text(
                                selectedUrgency != null
                                    ? selectedUrgency['name']
                                    : '',
                                style: const TextStyle(fontSize: 14.0),
                                textAlign: TextAlign.center,
                              ),
                              filterFn: (urgency, filter) => urgency['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()),
                              itemAsString: (urgency) => urgency['name'],
                              compareFn: (urgency1, urgency2) =>
                                  urgency1['id'] == urgency2['id'],
                              showSearchBox: false,
                              itemBuilder:
                                  (context, urgency, isDisabled, isSelected) =>
                                      ListTile(
                                title: Text(urgency['name']),
                                selectedColor: Colors.black,
                                titleTextStyle: const TextStyle(fontSize: 14.0),
                                selected: isSelected,
                                selectedTileColor: Colors.blueGrey[50],
                              ),
                              disabledItemFn: (urgency) =>
                                  urgency['id'] == state.urgency,
                            ),
                          )
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Work Progress'),
                          _TextField(progressController, isNumber: true),
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
                          const _TextFieldLabel('Planned Completion Date*'),
                          _TextField(planEndDateController, isCalendar: true),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Actual Completion Date'),
                          _TextField(actualEndDateController, isCalendar: true),
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
                          const _TextFieldLabel('Planned Cycle Time*'),
                          _TextField(
                            planCycleTimeController,
                            isNumber: true,
                            isMinute: true,
                          ),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Theoretical Operating Time'),
                          _TextField(
                            operatingTimeController,
                            enabled: false,
                            isMinute: true,
                          ),
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
                          const _TextFieldLabel(
                              'Total Planned Production Time'),
                          _TextField(
                            totalPlanProdTimeController,
                            enabled: false,
                            isMinute: true,
                          ),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Total Planned Cycle Time'),
                          _TextField(
                            totalPlanCycleTimeController,
                            enabled: false,
                            isMinute: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14.0),
                      ),
                    ),
                  const SizedBox(height: 40.0),
                  const Text(
                    'Planned Down Time',
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    spacing: 16.0,
                    children: [
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Quantity'),
                          _TextField(quantityController, enabled: false),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel(
                              'Total Planned Production Time'),
                          _TextField(
                            totalPlanProdTimeController,
                            enabled: false,
                            isMinute: true,
                          ),
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
                          const _TextFieldLabel('Planned Completion Time'),
                          _TextField(planEndTimeController, enabled: false),
                        ],
                      ),
                      Row(
                        spacing: 8.0,
                        children: [
                          const _TextFieldLabel('Total Planned Down Time'),
                          _TextField(
                            totalPlanDownTimeController,
                            enabled: false,
                            isMinute: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Visibility(
                    visible: state.planDownTimeList.isNotEmpty,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Description*')),
                        DataColumn(label: Text('Duration*')),
                        DataColumn(label: SizedBox()),
                        DataColumn(label: Text('Total Duration')),
                        DataColumn(label: SizedBox()),
                      ],
                      dataRowHeight: 64.0,
                      horizontalMargin: 0,
                      columnSpacing: 8.0,
                      dividerThickness: 0.00000000001,
                      rows: state.planDownTimeList
                          .mapIndexed((i, planDownTime) => DataRow(cells: [
                                DataCell(
                                  SizedBox(
                                    width: 240.0,
                                    child:
                                        _DropdownButton<Map<String, dynamic>>(
                                      selectedItem: planDownTime['code']
                                              .toString()
                                              .isNotEmpty
                                          ? context
                                              .read<WorkOrderDialogCubit>()
                                              .downTimeCodeList
                                              .firstWhere((code) =>
                                                  code['id'] ==
                                                  planDownTime['code'])
                                          : null,
                                      onChanged: (planDownTime) {
                                        if (planDownTime != null) {
                                          context
                                              .read<WorkOrderDialogCubit>()
                                              .updatePlanDownTimeList(
                                                  index: i,
                                                  key: 'code',
                                                  value: planDownTime['id']);
                                        }
                                      },
                                      items: context
                                          .read<WorkOrderDialogCubit>()
                                          .downTimeCodeList,
                                      dropdownBuilder:
                                          (context, selectedPlanDownTime) =>
                                              Text(
                                        selectedPlanDownTime != null
                                            ? selectedPlanDownTime[
                                                'description']
                                            : '',
                                        style: const TextStyle(fontSize: 14.0),
                                        textAlign: TextAlign.center,
                                      ),
                                      filterFn: (planDownTime, filter) =>
                                          planDownTime['description']
                                              .toString()
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()),
                                      itemAsString: (planDownTime) =>
                                          planDownTime['description'],
                                      compareFn:
                                          (planDownTime1, planDownTime2) =>
                                              planDownTime1['id'] ==
                                              planDownTime2['id'],
                                      itemBuilder: (context, planDownTime,
                                              isDisabled, isSelected) =>
                                          ListTile(
                                        title:
                                            Text(planDownTime['description']),
                                        selectedColor: Colors.black,
                                        titleTextStyle:
                                            const TextStyle(fontSize: 14.0),
                                        selected: isSelected,
                                        selectedTileColor: Colors.blueGrey[50],
                                      ),
                                      disabledItemFn: (planDownTime) =>
                                          planDownTime['id'] ==
                                          state.planDownTimeList[i]['code'],
                                    ),
                                  ),
                                ),
                                DataCell(_TextField(
                                  planDownTimeControllerList[i][0]
                                      as TextEditingController,
                                  isNumber: true,
                                  isMinute: true,
                                )),
                                DataCell(Checkbox(
                                  value:
                                      planDownTimeControllerList[i][1] as bool,
                                  onChanged: (option) {
                                    if (option != null) {
                                      setState(() {
                                        planDownTimeControllerList[i][1] =
                                            option;
                                      });

                                      if (option) {
                                        int duration = int.tryParse(
                                                (planDownTimeControllerList[i]
                                                            [0]
                                                        as TextEditingController)
                                                    .text) ??
                                            0;
                                        int quantity = int.tryParse(
                                                quantityController.text) ??
                                            0;
                                        (planDownTimeControllerList[i][2]
                                                    as TextEditingController)
                                                .text =
                                            (duration * quantity).toString();
                                      } else {
                                        (planDownTimeControllerList[i][2]
                                                as TextEditingController)
                                            .text = '0';
                                      }
                                    }
                                  },
                                )),
                                DataCell(_TextField(
                                  planDownTimeControllerList[i][2]
                                      as TextEditingController,
                                  enabled: false,
                                  isMinute: true,
                                )),
                                DataCell(IconButton(
                                  color: Colors.red,
                                  onPressed: () {
                                    context
                                        .read<WorkOrderDialogCubit>()
                                        .managePlanDownTimeList(index: i);
                                    planDownTimeControllerList.removeAt(i);
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
                          .read<WorkOrderDialogCubit>()
                          .managePlanDownTimeList();
                      planDownTimeControllerList.add([
                        TextEditingController(),
                        false,
                        TextEditingController(text: '0')
                      ]);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Planned Down Time'),
                  ),
                  const SizedBox(height: 40.0),
                  const Text(
                    'Process',
                    style:
                        TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                  ),
                  Visibility(
                    visible: state.processList.isNotEmpty,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name*')),
                        DataColumn(label: Text('Urgency*')),
                        DataColumn(label: SizedBox()),
                      ],
                      dataRowHeight: 64.0,
                      horizontalMargin: 0,
                      columnSpacing: 8.0,
                      dividerThickness: 0.00000000001,
                      rows: state.processList
                          .mapIndexed((i, process) => DataRow(cells: [
                                DataCell(_TextField(processControllerList[i][0]
                                    as TextEditingController)),
                                DataCell(
                                  SizedBox(
                                    width: 240.0,
                                    child:
                                        _DropdownButton<Map<String, dynamic>>(
                                      selectedItem: process['urgency']
                                              .toString()
                                              .isNotEmpty
                                          ? context
                                              .read<WorkOrderDialogCubit>()
                                              .urgencyList
                                              .firstWhere((urgency) =>
                                                  urgency['id'] ==
                                                  process['urgency'])
                                          : null,
                                      onChanged: (urgency) {
                                        if (urgency != null) {
                                          context
                                              .read<WorkOrderDialogCubit>()
                                              .updateProcessList(
                                                  index: i,
                                                  key: 'urgency',
                                                  value: urgency['id']);
                                        }
                                      },
                                      items: context
                                          .read<WorkOrderDialogCubit>()
                                          .urgencyList,
                                      dropdownBuilder:
                                          (context, selectedUrgency) => Text(
                                        selectedUrgency != null
                                            ? selectedUrgency['name']
                                            : '',
                                        style: const TextStyle(fontSize: 14.0),
                                        textAlign: TextAlign.center,
                                      ),
                                      filterFn: (urgency, filter) =>
                                          urgency['name']
                                              .toString()
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()),
                                      itemAsString: (urgency) =>
                                          urgency['name'],
                                      compareFn: (urgency1, urgency2) =>
                                          urgency1['id'] == urgency2['id'],
                                      showSearchBox: false,
                                      itemBuilder: (context, urgency,
                                              isDisabled, isSelected) =>
                                          ListTile(
                                        title: Text(urgency['name']),
                                        selectedColor: Colors.black,
                                        titleTextStyle:
                                            const TextStyle(fontSize: 14.0),
                                        selected: isSelected,
                                        selectedTileColor: Colors.blueGrey[50],
                                      ),
                                      disabledItemFn: (urgency) =>
                                          urgency['id'] ==
                                          state.processList[i]['urgency'],
                                    ),
                                  ),
                                ),
                                DataCell(IconButton(
                                  color: Colors.red,
                                  onPressed: () {
                                    context
                                        .read<WorkOrderDialogCubit>()
                                        .manageProcessList(index: i);
                                    processControllerList.removeAt(i);
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
                      context.read<WorkOrderDialogCubit>().manageProcessList();
                      processControllerList.add([TextEditingController()]);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Process'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  _errorMessage = null;
                });

                if (idController.text.isEmpty ||
                    salesController.text.isEmpty ||
                    state.product.isEmpty ||
                    quantityController.text.isEmpty ||
                    unitController.text.isEmpty ||
                    materialController.text.isEmpty ||
                    planStartDateController.text.isEmpty ||
                    state.urgency.isEmpty ||
                    planEndDateController.text.isEmpty ||
                    planCycleTimeController.text.isEmpty) {
                  setState(() {
                    _errorMessage = 'All (*) marked fields are required.';
                  });
                } else {
                  try {
                    calculate();

                    List<Map<String, dynamic>> planDownTimeList = state
                        .planDownTimeList
                        .map((planDownTime) =>
                            Map<String, dynamic>.from(planDownTime))
                        .toList();

                    for (int i = 0; i < planDownTimeList.length; i++) {
                      planDownTimeList[i]['duration'] = int.tryParse(
                              (planDownTimeControllerList[i][0]
                                      as TextEditingController)
                                  .text) ??
                          0;
                      planDownTimeList[i]['option'] =
                          planDownTimeControllerList[i][1];
                      planDownTimeList[i]['totalDuration'] = int.tryParse(
                              (planDownTimeControllerList[i][2]
                                      as TextEditingController)
                                  .text) ??
                          0;
                    }

                    List<Map<String, dynamic>> processList = state.processList
                        .map((process) => Map<String, dynamic>.from(process))
                        .toList();

                    for (int i = 0; i < processList.length; i++) {
                      processList[i]['name'] =
                          (processControllerList[i][0] as TextEditingController)
                              .text;
                    }

                    Map<String, dynamic> data = {
                      'sales': salesController.text,
                      'product': state.product,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'unit': unitController.text,
                      'material': materialController.text,
                      'planStartDate': planStartDateController.text,
                      'actualStartDate': actualStartDateController.text,
                      'urgency': state.urgency,
                      'progress': int.tryParse(progressController.text) ?? 0,
                      'planEndDate': planEndDateController.text,
                      'actualEndDate': actualEndDateController.text,
                      'planCycleTime':
                          int.tryParse(planCycleTimeController.text) ?? 0,
                      'operatingTime':
                          int.tryParse(operatingTimeController.text) ?? 0,
                      'totalPlanProdTime':
                          int.tryParse(totalPlanProdTimeController.text) ?? 0,
                      'totalPlanCycleTime':
                          int.tryParse(totalPlanCycleTimeController.text) ?? 0,
                      'planEndTime': planEndTimeController.text,
                      'totalPlanDownTime':
                          int.tryParse(totalPlanDownTimeController.text) ?? 0,
                      'planDownTimeList': planDownTimeList,
                      'isCheckedIn': state.isCheckedIn,
                      'status': state.status,
                      'equipment': state.equipment,
                      'operator': state.operator,
                      'totalQuantityUpdate': state.totalQuantityUpdate,
                      'totalNgQuantity': state.totalNgQuantity,
                      'quantityUpdateList': state.quantityUpdateList,
                      'processList': processList,
                    };

                    await context
                        .read<WorkOrderDialogCubit>()
                        .save(data)
                        .then((_) {
                      widget.onWorkOrderAdded();
                      Navigator.of(context).pop();
                    });
                  } catch (_) {
                    rethrow;
                  }
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _TextFieldLabel extends StatelessWidget {
  const _TextFieldLabel(this.text, {this.isFlexible = false});

  final String text;
  final bool isFlexible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: !isFlexible ? 240.0 : null,
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
      {this.isFlexible = false,
      this.isNumber = false,
      this.isCalendar = false,
      this.enabled = true,
      this.isMinute = false});

  final TextEditingController controller;
  final bool isFlexible;
  final bool isNumber;
  final bool isCalendar;
  final bool enabled;
  final bool isMinute;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: !isFlexible ? 240.0 : null,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          suffixIcon:
              isCalendar ? const Icon(Icons.calendar_today_outlined) : null,
          suffixText: isMinute ? 'mins' : null,
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
                      controller.text = DateFormat('yyyy-MM-dd HH:mm').format(
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

class _DropdownButton<T> extends StatelessWidget {
  const _DropdownButton(
      {required this.selectedItem,
      required this.onChanged,
      required this.items,
      required this.dropdownBuilder,
      required this.filterFn,
      required this.itemAsString,
      required this.compareFn,
      this.showSearchBox = true,
      required this.itemBuilder,
      required this.disabledItemFn});

  final T? selectedItem;
  final void Function(T?) onChanged;
  final List<T> items;
  final Widget Function(BuildContext, T?) dropdownBuilder;
  final bool Function(T, String) filterFn;
  final String Function(T) itemAsString;
  final bool Function(T, T) compareFn;
  final bool showSearchBox;
  final Widget Function(BuildContext, T, bool, bool) itemBuilder;
  final bool Function(T) disabledItemFn;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkOrderDialogCubit, WorkOrderDialogState>(
      builder: (context, state) {
        return DropdownSearch<T>(
          selectedItem: selectedItem,
          onChanged: onChanged,
          items: (filter, loadProps) => items,
          dropdownBuilder: dropdownBuilder,
          filterFn: filterFn,
          itemAsString: itemAsString,
          compareFn: compareFn,
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
            showSearchBox: showSearchBox,
            searchFieldProps:
                const TextFieldProps(style: TextStyle(fontSize: 14.0)),
            scrollbarProps: const ScrollbarProps(thumbVisibility: true),
            searchDelay: Duration.zero,
            itemBuilder: itemBuilder,
            showSelectedItems: true,
            disabledItemFn: disabledItemFn,
          ),
        );
      },
    );
  }
}
