import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/web_app_template/production_task_work_station/remark.dart';
import 'package:smartmachine365/web_app_template/production_task_work_station/check_in_out.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:percent_indicator/percent_indicator.dart';
export 'production_task_card_model.dart';

class ProductionTaskCardWidget extends StatefulWidget {
  final String parent;
  final Map<String, dynamic> productionTaskTicketList; // Details for a single equipment
  final Map<String, dynamic>? productionTaskTicketData; // Status data for a single equipment
  final bool isLoading;
  final Map<String, dynamic> workOrder;

  

  const ProductionTaskCardWidget(
      {super.key,
      required this.parent,
      required this.productionTaskTicketList,
      required this.productionTaskTicketData,
      required this.isLoading,
      required this.workOrder
  });

  @override
  ProductionTaskCardWidgetState createState() => ProductionTaskCardWidgetState();
}

class ProductionTaskCardWidgetState extends State<ProductionTaskCardWidget> {
  

  String work_id = 'ABC-123'; // Default, can be overridden by productionTaskTicketList
  String machineId = 'Unknown Equipment ID';
  DateTime plannedStartDate = DateTime.now();
  DateTime plannedEndDate = DateTime.now().add(const Duration(days: 1));
  int? plannedQuantity;
  String productId = 'Unknown Product ID';
  String processDescriptionNote = '';
  String processRouting = 'parent';
  DateTime actualStartDate = DateTime.now();
  int? actualQuantity = 0;
  int? remainingQuantity = 0;
  int? ngQuantity = 0;
  DateTime estimatedEndDate = DateTime.now().add(const Duration(days: 1));
  String taskStatus = 'Unknown';
  String taskUrgency = 'Normal'; // Default urgency, can be overridden by productionTaskTicketList
  String taskProgress = 'On Track'; // Default progress, can be overridden by productionTaskTicketList
  

  @override
  void initState() {
    super.initState();
    updateData();
    print("DATA IN WIDGET |||||||||||||||| "
        "${widget.productionTaskTicketData.toString()}");
    print("LIST IN WIDGET |||||||||||||||| "
        "${widget.productionTaskTicketList.toString()}");
  }

  @override
  void didUpdateWidget(ProductionTaskCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productionTaskTicketList != widget.productionTaskTicketList ||
        oldWidget.productionTaskTicketData != widget.productionTaskTicketData) {
      updateData();
    }
  }  

  void updateData() {
  print("STEP 2: Update Data for ProductionTaskCardWidget");
  
  // Return early if no data
  if (widget.productionTaskTicketList.isEmpty) {
    setState(() {
      // Reset all fields to default values
      work_id = 'N/A';
      machineId = 'Unknown Equipment';
      plannedStartDate = DateTime.now();
      plannedEndDate = DateTime.now().add(const Duration(days: 1));
      plannedQuantity = 0;
      productId = 'N/A';
      processDescriptionNote = '';
      processRouting = 'N/A';
      actualStartDate = DateTime.now();
      actualQuantity = 0;
      remainingQuantity = 0;
      ngQuantity = 0;
      estimatedEndDate = DateTime.now().add(const Duration(days: 1));
      taskStatus = 'Unknown';
      taskUrgency = 'Normal'; // Default urgency
      taskProgress = 'On Track'; // Default progress
    });
    return;
  }

  // Get the first task data
  final productionTask = widget.productionTaskTicketList.values.first;

  setState(() {
    // Update all fields with null checks
    work_id = productionTask['work_id']?.toString() ?? 'N/A';
    machineId = productionTask['machineId']?.toString() ?? 'Unknown Equipment';
    productId = productionTask['productId']?.toString() ?? "N/A";
    processDescriptionNote = productionTask['processDescriptionNote']?.toString() ?? 'IDK';
    processRouting = productionTask['processRouting']?.toString() ?? 'N/A';
    taskStatus = productionTask['taskStatus']?.toString() ?? 'IDK';
    taskUrgency = productionTask['taskUrgency']?.toString() ?? 'Normal';
    taskProgress = productionTask['taskProgress']?.toString() ?? 'On Track';

    print("WORK ID: $work_id");
    print("MACHINE ID: $machineId");
    print("PRODUCT ID: $productId");
    print("PROCESS DESCRIPTION NOTE: $processDescriptionNote");
    print("PROCESS ROUTING: $processRouting");
    print("WORK ORDER: ${widget.workOrder.toString()}");
    print("PRODUCTION TASK: ${productionTask.toString()}");
    print("TASK STATUS: ${taskStatus.toString()}");
    
    // Date handling
    plannedStartDate = productionTask['plannedStartDate'] != null 
        ? DateTime.parse(productionTask['plannedStartDate'])
        : DateTime.now();
    plannedEndDate = productionTask['plannedEndDate'] != null 
        ? DateTime.parse(productionTask['plannedEndDate'])
        : DateTime.now();
    actualStartDate = productionTask['actualStartDate'] != null 
        ? DateTime.parse(productionTask['actualStartDate'])
        : DateTime.now();
    estimatedEndDate = productionTask['estimatedEndDate'] != null 
        ? DateTime.parse(productionTask['estimatedEndDate'])
        : DateTime.now().add(const Duration(days: 1));
    
    // Numeric values
    plannedQuantity = _getInt('plannedQuantity');
    actualQuantity = _getInt('actualQuantity');
    remainingQuantity = _getInt('remainingQuantity');
    ngQuantity = _getInt('ngQuantity');
    
  });
}
    String _getString(String key, [String fallback = 'N/A']) {
      print("Fetching String key: $key");
      if (widget.productionTaskTicketList.isEmpty) return fallback;
      final taskData = widget.productionTaskTicketList.values.first;
      final value = taskData[key];
      return value?.toString().trim() ?? fallback;
}

  int _getInt(String key, [int fallback = 0]) {
    final taskData = widget.productionTaskTicketList.values.first;
    return int.tryParse(taskData[key]?.toString() ?? '') ?? fallback;
  }

String _formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty || dateString == 'null') {
    return 'N/A';
  }
  try {
    return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(dateString));
  } catch (e) {
    print('Error formatting date: $dateString - $e');
    return 'Invalid date';
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

  final ButtonStyle blueRoundedButtonStyle = ButtonStyle(
  padding: MaterialStatePropertyAll(
    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  ),
  backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
    if (states.contains(MaterialState.hovered)) {
      return Colors.blue.shade200; // Darker on hover
    }
    return Colors.blue;
  }),
  foregroundColor: MaterialStatePropertyAll(Colors.white),
  shape: MaterialStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
    if (states.contains(MaterialState.hovered)) {
      return Colors.blue.withOpacity(0.1); // Blue ripple on hover
    }
    return null;
  }),
);

final divider = const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 20,
                          indent: 20,     // Padding from left
                          endIndent: 20,  // Padding from right
                        );

  // Helper method to determine the status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return const Color(0xFF07F077);
      case 'stopped':
        return const Color.fromARGB(255, 255, 17, 0);
      case 'idle':
        return const Color.fromARGB(255, 252, 248, 11);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  void refreshData() {
    setState(() {
      updateData();
    });
  }

  void _showStartRunDialog(BuildContext context, String checkType, String workId, String machineId, String productId, String plannedQuantity, String actualQuantity) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StartRunDialog(
          checkType: checkType,
          workId: workId,
          machineId: machineId,
          productId: productId,
          plannedQuantity: plannedQuantity,
          actualQuantity: actualQuantity,
          checkInTime: DateTime.now(),
        );
    },
  );
}

  void _showRemarkDialog(BuildContext context, String checkType, String workId, String machineId, String productId, String plannedQuantity, String actualQuantity) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return RemarkDialog(
          checkType: checkType,
          workId: workId,
          machineId: machineId,
          productId: productId,
          plannedQuantity: plannedQuantity,
          actualQuantity: actualQuantity,
          checkInTime: DateTime.now(),
        );
    },
  );
}



Widget buildLabeledField({
  required String searchLabel,
  required String searchHintText,
  required TextEditingController controller,
  }) {
    return SizedBox(
      width: 250,
      height: 30,
      child: Row(
        children: [
          SizedBox(
            child: Text(
              '$searchLabel:',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '$searchHintText',
                hintStyle: const TextStyle(
                  color: Colors.grey, // Set your desired grey color here
                  fontSize: 14,      // Optional: adjust font size if needed
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: const Color.fromARGB(255, 110, 110, 110),
                ),
                
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildFieldRow(String label, String value, TextStyle style) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 2.0),
    child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: style),
    const SizedBox(width: 12), // spacing between label and box
    SizedBox(
      width: 300, // uniform width for all value boxes
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: style.copyWith(color: Colors.black),
          overflow: TextOverflow.ellipsis,
          maxLines: 2, // Optional: allows wrapping
        ),
      ),
    ),
  ],
)

  );
}

Widget _buildStatusWidget(String label, String value, TextStyle style, String category) {
  // Determine colors based on category and value
  final (Color color, Color bgColor) = switch (category) {
    'urgency' => switch (value.toLowerCase()) {
        'high' => (Colors.red, Colors.red.withOpacity(0.1)),
        _ => (Colors.green, Colors.green.withOpacity(0.1)), // Default for 'Normal' or others
      },
    'task' => switch (value.toLowerCase()) {
        'delayed' => (Colors.red, Colors.red.withOpacity(0.1)),
        'not started' => (Colors.grey, Colors.grey.withOpacity(0.1)),
        'in progress' => (Colors.blue, Colors.blue.withOpacity(0.1)),
        'on hold' => (Colors.orange, Colors.orange.withOpacity(0.1)),
        'completed' => (Colors.green, Colors.green.withOpacity(0.1)),
        _ => (Colors.black, Colors.white), // Fallback
      },
    'progress' => switch (value.toLowerCase()) {
        'at risk' => (Colors.red, Colors.red.withOpacity(0.1)),
        'on track' => (Colors.green, Colors.green.withOpacity(0.1)),
        'ahead of schedule' => (Colors.blue, Colors.blue.withOpacity(0.1)),
        _ => (Colors.grey, Colors.grey.withOpacity(0.1)),
      },
    _ => (Colors.black, Colors.white), // Default fallback
  };

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: style),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}



 @override
Widget build(BuildContext context) {
  final textStyle = FlutterFlowTheme.of(context).bodyMedium.override(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        font: GoogleFonts.poppins(),
      );

  

  final labelTextStyle = FlutterFlowTheme.of(context).bodyMedium.override(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        font: GoogleFonts.poppins(),
      );


  final productionTask = widget.productionTaskTicketList.isNotEmpty
      ? widget.productionTaskTicketList.values.first
      : {};
      print("Production Task: $productionTask");
  final machineId =
      productionTask['machineId']?.toString() ?? 'Unknown Equipment';
  print("Machine ID: $machineId");
  final work_id = productionTask['work_id']?.toString() ?? 'Unknown work_id';
    print("WORK ORDER ID: $work_id");

final productId =
      productionTask['productId']?.toString() ?? 'Unknown Product ID';
  print("Product ID: $productId");   
  final processRouting =
      productionTask['processRouting']?.toString() ?? 'N/A';
  print("Process Routing: $processRouting");
  final processDescriptionNote =
      productionTask['processDescriptionNote']?.toString() ?? 'N/A';
  print("Process Description Note: $processDescriptionNote");
  final plannedQuantity = _getInt('plannedQuantity', 0);
  print("Planned Quantity: $plannedQuantity");
  final actualQuantity = _getInt('actualQuantity', 0).toString();
  print("Actual Quantity: $actualQuantity");
  final remainingQuantity = _getInt('remainingQuantity', 0).toString();
  print("Remaining Quantity: $remainingQuantity");
  final ngQuantity = _getInt('ngQuantity', 0).toString();
  print("NG Quantity: $ngQuantity");
  String taskStatus = 'Unknown';
  final taskUrgency = productionTask['taskUrgency']?.toString() ?? 'Normal';
  print("Task Urgency: $taskUrgency");

  try {
    // suspect code
    taskStatus = (productionTask['taskStatus'] == null || productionTask['taskStatus'].toString().isEmpty)
      ? 'IDK'
      : productionTask['taskStatus'].toString();
  } catch (e, stack) {
    print('Exception in taskStatus assignment: $e');
    print(stack);
  }
  print("Task Status: $taskStatus"); 

  Color statusColor = _getStatusColor(taskStatus);

  // Format dates
  
  final plannedStartDate = _formatDate(productionTask['plannedStartDate']?.toString()) ?? 'N/A';
  final plannedEndDate = _formatDate(productionTask['plannedEndDate']?.toString()) ?? 'N/A';
  final actualStartDate = _formatDate(productionTask['actualStartDate']?.toString())  ?? 'N/A';
  final estimatedEndDate = _formatDate(productionTask['estimatedEndDate']?.toString()) ?? 'N/A';

  double width = MediaQuery.of(context).size.width;
  double cardWidth = double.infinity; // Default to full width
  double fontSize = width > 600 ? 18 : 16;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primary,
              width: 1,
            ),
          ),
          child: GestureDetector(
            onTap: () {
              final productionTaskTicketData;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Top Section - Title & Statuses
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Work Station: ', style: textStyle),
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                      machineId,
                                      style: textStyle,
                                      overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ],
                                ),

                              const SizedBox(width: 30),
                              _buildStatusWidget('Urgency Class: ', taskUrgency, textStyle, 'urgency'),
                              const SizedBox(width: 30),
                              _buildStatusWidget('Task Status: ', taskStatus, textStyle, 'task'), 
                              const SizedBox(width: 30),
                              _buildStatusWidget('Progress: ', taskProgress, textStyle, 'progress'),
                                  ],
                          ),
                          ],
                        ),

                        divider,


                        /// Details Section - Two Columns
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Production Task Description: ', style: textStyle),
                                  const SizedBox(height: 5,),
                                  _buildFieldRow('Work Order ID:', work_id, labelTextStyle),
                                  _buildFieldRow('Expected Task Start Date:', plannedStartDate, labelTextStyle),
                                  _buildFieldRow('Expected Task Completion Date:', plannedEndDate, labelTextStyle),
                                  _buildFieldRow('Product ID:', productId, labelTextStyle),
                                  _buildFieldRow('Planned Production Quantity:', plannedQuantity.toString(), labelTextStyle),
                                  _buildFieldRow('Due Date:', plannedEndDate, labelTextStyle),
                                  _buildFieldRow('Process Routing:', processRouting, labelTextStyle),
                                  _buildFieldRow('Process Description Note:', processDescriptionNote, labelTextStyle),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Task In Progress Report Status: ', style: textStyle),
                                  const SizedBox(height: 5,),
                                  _buildFieldRow('Actual Check In Time:', actualStartDate, labelTextStyle),
                                  _buildFieldRow('Qty of Produce:', actualQuantity, labelTextStyle),
                                  _buildFieldRow('Remaining Production Qty:', remainingQuantity, labelTextStyle),
                                  _buildFieldRow('Estimated Completion Date:', estimatedEndDate, labelTextStyle),
                                  _buildFieldRow('NG Qty:', ngQuantity, labelTextStyle),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                            onPressed: () {
                            _showStartRunDialog(context, "in", productionTask['work_id'], productionTask['machineId'], productionTask['productId'], productionTask['plannedQuantity'], productionTask['actualQuantity']);
                        },
                            style: blueRoundedButtonStyle,
                            child: const Text('Start Check In',
                                style: TextStyle(fontWeight: FontWeight.normal)),
                          ),
                            ElevatedButton(
                            onPressed: () async {
                            _showStartRunDialog(context, "out", productionTask['work_id'], productionTask['machineId'], productionTask['productId'], productionTask['plannedQuantity'], productionTask['actualQuantity']);
                            },
                            style: blueRoundedButtonStyle,
                            child: const Text('Partially Check Out',
                                style: TextStyle(fontWeight: FontWeight.normal)),
                          ),
                            ElevatedButton(
                            onPressed: () async {
                              _showRemarkDialog(context,  "remark", productionTask['work_id'], productionTask['machineId'], productionTask['productId'], productionTask['plannedQuantity'], productionTask['actualQuantity']);
                            },
                            style: blueRoundedButtonStyle,
                            child: const Text('Production Remark',
                                style: TextStyle(fontWeight: FontWeight.normal)),
                          ),
                          // Log Defect Button
                             ElevatedButton(
                            onPressed: () async {
                              _showRemarkDialog(context, "defect", productionTask['work_id'], productionTask['machineId'], productionTask['productId'], productionTask['plannedQuantity'], productionTask['actualQuantity']);
                            },
                            style: blueRoundedButtonStyle,
                            child: const Text('Production Defect',
                                style: TextStyle(fontWeight: FontWeight.normal)),
                          ),
                          // Task On Hold Buttons
                            ElevatedButton(
                            onPressed: () async {
                              _showRemarkDialog(context, "hold", productionTask['work_id'], productionTask['machineId'], productionTask['productId'], productionTask['plannedQuantity'], productionTask['actualQuantity']);
                            },
                            style: blueRoundedButtonStyle,
                            child: const Text('Task ON HOLD',
                                style: TextStyle(fontWeight: FontWeight.normal)),
                          ),
                          //  Task Complete Button
                            ElevatedButton(
                            onPressed: () async {
                              _showRemarkDialog(context, "complete", productionTask['work_id'], productionTask['machineId'], productionTask['productId'], productionTask['plannedQuantity'], productionTask['actualQuantity']);
                            },
                            style: blueRoundedButtonStyle,
                            child: const Text('Task Complete',
                                style: TextStyle(fontWeight: FontWeight.normal)),
                          ),
                          
                          ],
                        )
                      ],
                    ),
            ),
          ),
        );
      },
    ),
  );
}

}
