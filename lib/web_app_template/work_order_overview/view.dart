import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';
import 'package:smartmachine365/web_app_template/work_order_overview/cubits/cubits.dart';
import 'package:smartmachine365/web_app_template/work_order_overview/firestore_service.dart';
import 'package:smartmachine365/web_app_template/work_order_overview/widgets/widgets.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class WordOrderView extends StatefulWidget {
  final String companyID;
  final String userRole;

  const WordOrderView(
      {super.key, required this.companyID, required this.userRole});

  @override
  _WordOrderViewState createState() => _WordOrderViewState();
}

class _WordOrderViewState extends State<WordOrderView> {
  @override
  void initState() {
    super.initState();
    fetchWorkOrder();
  }

  @override
  void dispose() {
    _scrollController.dispose();
        workOrderSearchController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();
  List<dynamic> workOrders = [];
  List<dynamic> originalWorkOrder = [];
  int currentWorkOrderPage = 0;
  final int workOrdersPerPage = 13;
  TextEditingController workOrderSearchController = TextEditingController();
  String workOrderFilterController = 'Work Order ID';
  String lastUpdateTime = '';
  bool _isLoading = false;

  Future<void> fetchWorkOrder() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Map<String, dynamic>> fetchedWorkOrder;
      fetchedWorkOrder = await FirestoreService().fetchWorkOrders();
      setState(() {
        workOrders = fetchedWorkOrder;
        originalWorkOrder = List.from(workOrders);
        lastUpdateTime = DateTime.now().toLocal().toString().substring(0, 19);
      });

      context.read<WorkOrderCubit>().updateWorkOrderList(workOrders);
    } catch (e) {
      print('Error fetching workOrders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$e',
            style: const TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<DataRow> _createWorkOrderRows() {
    // double screenWidth = MediaQuery.of(context).size.width;
    return workOrders
        .skip(currentWorkOrderPage * workOrdersPerPage)
        .take(workOrdersPerPage)
        .map(
          (workOrder) => DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 55),
                  child: Text(
                    workOrder['id'],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 55,
                  child: Text(
                    workOrder['sales'],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 70),
                  child: Text(
                    getProductName(workOrder['product']),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 70),
                  child: Text(
                    workOrder['quantity'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // if (screenWidth > 1809)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 70),
                  child: Text(
                    workOrder['unit'],
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 70),
                  child: Text(
                    workOrder['material'],
                  ),
                ),
              ),
              // if (screenWidth > 1697)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 75),
                  child: Text(
                    getDateFormat(workOrder['planStartDate']),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // if (screenWidth > 1434)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 75),
                  child: Text(
                    getDateFormat(workOrder['actualStartDate']),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // if (screenWidth > 1178)
              DataCell(
                getStatus(
                            plan: workOrder['planStartDate'],
                            actual: workOrder['actualStartDate']) ==
                        -2
                    ? const SizedBox()
                    : getStatus(
                                plan: workOrder['planStartDate'],
                                actual: workOrder['actualStartDate']) ==
                            1
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 72, 59)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'Delay',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 102, 235, 106)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'On schedule',
                              style: TextStyle(
                                color: Color.fromARGB(255, 7, 224, 15),
                              ),
                            ),
                          ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 75),
                  child: Text(
                    context
                        .read<WorkOrderCubit>()
                        .repository
                        .urgencyList
                        .firstWhere((urgency) =>
                            urgency['id'] == workOrder['urgency'])['name'],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: workOrder['progress'] / workOrder['quantity'],
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${workOrder['progress']}/${workOrder['quantity']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // if (screenWidth > 1697)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 75),
                  child: Text(
                    getDateFormat(workOrder['planEndDate']),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // if (screenWidth > 1434)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 75),
                  child: Text(
                    getDateFormat(workOrder['actualEndDate']),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                getStatus(
                            plan: workOrder['planEndDate'],
                            actual: workOrder['actualEndDate']) ==
                        -2
                    ? const SizedBox()
                    : getStatus(
                                plan: workOrder['planEndDate'],
                                actual: workOrder['actualEndDate']) ==
                            1
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 72, 59)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'Delay',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 102, 235, 106)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'On schedule',
                              style: TextStyle(
                                color: Color.fromARGB(255, 7, 224, 15),
                              ),
                            ),
                          ),
              ),
              DataCell(
                Text(
                  getDateDelay(
                      plan: workOrder['planEndDate'],
                      actual: workOrder['actualEndDate']),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Text(
                  '${workOrder['totalPlanProdTime'].toString()} mins',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Text(
                  '${workOrder['totalPlanCycleTime'].toString()} mins',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          try {
                            await showDialog(
                              context: context,
                              builder: (_) => BlocProvider(
                                create: (_) => WorkOrderDialogCubit(
                                    context.read<WorkOrderCubit>(),
                                    isNew: false)
                                  ..init(data: workOrder),
                                child: WorkOrderDialog(
                                    onWorkOrderAdded: fetchWorkOrder),
                              ),
                            );
                          } catch (_) {}
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                content: const Text(
                                    'Are you sure to delete this work order?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await context
                                            .read<WorkOrderCubit>()
                                            .delete(workOrder['id'])
                                            .then((_) {
                                          fetchWorkOrder();
                                          Navigator.of(context).pop();
                                        });
                                      } catch (_) {
                                        rethrow;
                                      }
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  void searchWorkOrder(String query) {
    final results = originalWorkOrder.where((workOrder) {
      final searchLower = query.toLowerCase();
      switch (workOrderFilterController) {
        case 'Work Order ID':
          return workOrder['id'].toLowerCase().contains(searchLower);
        case 'Sales Order ID':
          return workOrder['sales'].toLowerCase().contains(searchLower);
        case 'Product ID':
          return workOrder['product'].toLowerCase().contains(searchLower);
        case 'Material Order ID':
          return workOrder['material'].toLowerCase().contains(searchLower);
        default:
          return false;
      }
    }).toList();
    setState(() {
      workOrders = results;
    });
  }

  String getDateFormat(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);

      return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
    } catch (_) {
      return '';
    }
  }

  int getStatus({required String plan, required String actual}) {
    try {
      DateTime planDate = DateTime.parse(plan);
      DateTime actualDate = DateTime.parse(actual);

      return actualDate.compareTo(planDate);
    } catch (_) {
      return -2;
    }
  }

  String getDateDelay({required String plan, required String actual}) {
    try {
      DateTime planDate = DateTime.parse(plan);
      DateTime actualDate = DateTime.parse(actual);
      int hour = actualDate.difference(planDate).inHours;
      int minute = actualDate.difference(planDate).inMinutes.remainder(60);

      if (hour == 0) {
        return '$minute mins';
      } else if (minute == 0) {
        return '$hour hrs';
      } else {
        return '$hour hrs $minute mins';
      }
    } catch (_) {
      return '';
    }
  }

  String getProductName(String id) {
    try {
      return context
          .read<WorkOrderCubit>()
          .state
          .productList
          .firstWhere((product) => product['id'] == id)['name'];
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (workOrders.isNotEmpty)
        ? (workOrders.length / workOrdersPerPage).ceil()
        : 0;
    if (currentWorkOrderPage >= totalPages) {
      currentWorkOrderPage = totalPages > 0 ? totalPages - 1 : 0;
    }
    // double screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<WorkOrderCubit, WorkOrderState>(
      builder: (context, state) {
        return Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 900,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 30.0, left: 20.0, right: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard/Manage WorkOrders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              const Text(
                                'Manage Work Orders',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Last Update: ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: lastUpdateTime,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    fetchWorkOrder();
                                  },
                                  icon: const Icon(Icons.refresh,
                                      size: 16, color: Colors.white),
                                  label: const Text('Refresh',
                                      style: TextStyle(color: Colors.white)),
                                  style: TextButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, right: 20.0, top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.3,
                                height: 30,
                                child: TextField(
                                  controller: workOrderSearchController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search by $workOrderFilterController...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 5.0, horizontal: 10.0),
                                  ),
                                  onChanged: (value) {
                                    Timer(const Duration(milliseconds: 300),
                                        () {
                                      searchWorkOrder(value);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 185,
                                height: 30,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 5.0, horizontal: 10.0),
                                  ),
                                  value: workOrderFilterController,
                                  items: [
                                    'Work Order ID',
                                    'Sales Order ID',
                                    'Product ID',
                                    'Material Order ID'
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      workOrderFilterController = newValue!;
                                    });
                                    searchWorkOrder(
                                        workOrderSearchController.text);
                                  },
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 2),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await showDialog(
                                  context: context,
                                  builder: (_) => BlocProvider(
                                    create: (_) => WorkOrderDialogCubit(
                                        context.read<WorkOrderCubit>())
                                      ..init(),
                                    child: WorkOrderDialog(
                                        onWorkOrderAdded: fetchWorkOrder),
                                  ),
                                );
                              } catch (_) {}
                            },
                            child: const Text('+ Add Work Order',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, right: 20.0, top: 21.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: workOrders.isNotEmpty
                            ? Scrollbar(
                                thumbVisibility: true,
                                controller: _scrollController,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _scrollController,
                                  child: DataTable(
                                    border: TableBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      top: BorderSide(
                                        width: 0.5,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                      horizontalInside: BorderSide(
                                        width: 0.5,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                      verticalInside: BorderSide(
                                        width: 0.5,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                      bottom: BorderSide(
                                        width: 0.5,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                      left: BorderSide(
                                        width: 0.5,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                      right: BorderSide(
                                        width: 0.5,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'Work Order ID',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          maxLines: 2,
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Sales Order ID',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Product ID',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Quantity',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      // if (screenWidth > 1809)
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Unit',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Material Order ID',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      // if (screenWidth > 1697)
                                      DataColumn(
                                        label: SizedBox(
                                          width: 75,
                                          child: Text(
                                            'Planned Start Date',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      // if (screenWidth > 1434)
                                      DataColumn(
                                        label: SizedBox(
                                          width: 75,
                                          child: Text(
                                            'Actual Start Date',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      // if (screenWidth > 1178)
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Status',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Urgency Level',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Work Progress',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          maxLines: 2,
                                        ),
                                      ),
                                      // if (screenWidth > 1697)
                                      DataColumn(
                                        label: SizedBox(
                                          width: 75,
                                          child: Text(
                                            'Planned Completion Date',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 3,
                                          ),
                                        ),
                                      ),
                                      // if (screenWidth > 1434)
                                      DataColumn(
                                        label: SizedBox(
                                          width: 75,
                                          child: Text(
                                            'Actual Completion Date',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 3,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 55,
                                          child: Text(
                                            'Status',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 75,
                                          child: Text(
                                            'Duration Delay',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 3,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 95,
                                          child: Text(
                                            'Total Planned Production Time',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 3,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 75,
                                          child: Text(
                                            'Total Planned Cycle Time',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            maxLines: 3,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                          label: Text('Action',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    rows: _createWorkOrderRows(),
                                    horizontalMargin: 16.0,
                                    columnSpacing: 16.0,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'No workOrders found.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 35, left: 50.0, right: 50.0, bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: currentWorkOrderPage > 0
                                ? () {
                                    setState(() {
                                      currentWorkOrderPage--;
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(110, 30),
                              backgroundColor:
                                  currentWorkOrderPage < totalPages - 1
                                      ? Colors.grey[300]
                                      : Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Previous'),
                          ),
                          const SizedBox(width: 5),
                          for (int i = 0; i < totalPages; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 5.0, right: 5.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentWorkOrderPage = i;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentWorkOrderPage == i
                                      ? const Color.fromARGB(255, 122, 34, 236)
                                      : Colors.grey[300],
                                  foregroundColor: currentWorkOrderPage == i
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                child: Text('${i + 1}'),
                              ),
                            ),
                          const SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: currentWorkOrderPage < totalPages - 1
                                ? () {
                                    setState(() {
                                      currentWorkOrderPage++;
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(110, 30),
                              backgroundColor:
                                  currentWorkOrderPage < totalPages - 1
                                      ? Colors.grey[300]
                                      : Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading && state.status.isInProgress)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
