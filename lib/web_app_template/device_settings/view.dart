import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/device_settings/firestore_service.dart';
import 'package:smartmachine365/web_app_template/device_settings/edit.dart';
import '../../flutter_flow/flutter_flow_theme.dart';

class DeviceView extends StatefulWidget {
  const DeviceView({super.key});

  @override
  _DeviceViewState createState() => _DeviceViewState();
}

class _DeviceViewState extends State<DeviceView> {
  final ScrollController _scrollController = ScrollController();
  int currentDevicesPage = 0;
  List<dynamic> devices = [];
  Map<String, String> equipmentIdToName = {};
  List<dynamic> equipments = [];
  String lastUpdateTime = '';
  List<dynamic> originalDevices = [];
  String deviceFilterController = 'Device Name';
  TextEditingController deviceSearchController = TextEditingController();
  final int devicesPerPage = 13;

  bool _isLoading = false;

  List<dynamic> productionAreas = [];
  Map<String, String> productionAreaToName = {};

  List<dynamic> factories = [];
  Map<String, String> factoryToName = {};

  @override
  void initState() {
    super.initState();
    fetchDevices();
    fetchEquipments();
    fetchProductionArea();
    fetchFactory();
    listenForNewTopics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
        deviceSearchController.dispose();
    super.dispose();
  }

  void listenForNewTopics() {
    FirestoreService().startListeningForTopics().then((_) {
      fetchDevices();
      print('Listening for new topics...');
    }).catchError((error) {
      print('Error setting up listener: $error');
    });
  }

  Future<void> fetchEquipments() async {
    try {
      final fetchedEquipments = await FirestoreService().fetchEquipments();
      setState(() {
        equipments = fetchedEquipments;
        equipmentIdToName = {
          for (var equipment in equipments) equipment['id']: equipment['name']
        };
      });
    } catch (e) {
      print('Error fetching equipments: $e');
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
    }
  }

  Future<void> fetchDevices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedDevices = await FirestoreService().fetchDevices();
      setState(() {
        devices = fetchedDevices;
        originalDevices = List.from(devices);
        lastUpdateTime = DateTime.now().toLocal().toString().substring(0, 19);
      });
    } catch (e) {
      print('Error fetching devices: $e');
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

  Future<void> fetchProductionArea() async {
    try {
      final fetchedProId = await FirestoreService().fetchProductionArea();
      setState(() {
        productionAreas = fetchedProId;
        productionAreaToName = {
          for (var productionArea in productionAreas)
            productionArea['id']: productionArea['name']
        };
      });
    } catch (e) {
      print('Error fetching production area: $e');
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
    }
  }

  String _getProductionAreaName(String productionAreaID) {
    if (productionAreaID == '0') {
      return 'Not assigned';
    }
    return productionAreaToName[productionAreaID] ?? 'Unknown';
  }

  Future<void> fetchFactory() async {
    try {
      final fetchedFacId = await FirestoreService().fetchFactory();
      setState(() {
        factories = fetchedFacId;
        factoryToName = {
          for (var factory in factories) factory['id']: factory['name']
        };
      });
    } catch (e) {
      print('Error fetching factories: $e');
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
    }
  }

  String _getFactoryName(String factoryID) {
    if (factoryID == '0') {
      return 'Not assigned';
    }
    return factoryToName[factoryID] ?? 'Unknown';
  }

  Future<void> deleteDevice(String id) async {
    try {
      await FirestoreService().deleteDevice(id);
      setState(() {
        devices.removeWhere((devices) => devices['id'] == id);
        originalDevices.removeWhere((devices) => devices['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Device deleted successfully!',
            style: TextStyle(color: Colors.green),
          ),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting devices: $e');
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
    }
  }

  void searchDevices(String query) {
    final results = originalDevices.where((devices) {
      final searchLower = query.toLowerCase();
      switch (deviceFilterController) {
        case 'Device Name':
          return devices['device_name'].toLowerCase().contains(searchLower);
        case 'Topic':
          return devices['topic'].toLowerCase().contains(searchLower);
        case 'Equipment Name':
          final equipmentName =
              _getEquipmentName(devices['equipment_id']).toLowerCase();
          return equipmentName.contains(searchLower);
        default:
          return false;
      }
    }).toList();
    setState(() {
      devices = results;
    });
  }

  List<DataRow> _createDevicesRows() {
    // double screenWidth = MediaQuery.of(context).size.width;
    return devices
        .skip(currentDevicesPage * devicesPerPage)
        .take(devicesPerPage)
        .map(
          (devices) => DataRow(
            cells: [
              DataCell(
                Text(
                  '#${devices['id'].toString().padLeft(5, '0')}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 250,
                  ),
                  child: Text(
                    devices['device_name'],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // if (screenWidth > 1785)
              DataCell(
                Text(
                  devices['equipment_id'] == "0"
                      ? "-"
                      : devices['equipment_id'],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // if (screenWidth > 1300 )
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 194,
                  ),
                  child: Text(
                    _getEquipmentName(devices['equipment_id']),
                    maxLines: null,
                  ),
                ),
              ),
              // if (screenWidth > 1085)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 95,
                  ),
                  child: Text(
                    _getProductionAreaName(devices['productionArea']),
                    maxLines: null,
                  ),
                ),
              ),
              // if (screenWidth > 900)
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 95,
                  ),
                  child: Text(
                    _getFactoryName(devices['factory_id']),
                    maxLines: null,
                  ),
                ),
              ),
              // if (screenWidth > 1495)
              DataCell(
                Text(
                  devices['topic'],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // if (screenWidth > 1640)
              DataCell(
                Text(
                  devices['channel_name'],
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
                        onPressed: () {
                          _showEditDeviceDialog(context, devices['id']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: const Text(
                                    'Are you sure you want to delete this devices?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteDevice(devices['id']);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
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

  String _getEquipmentName(String equipmentId) {
    if (equipmentId == '0') {
      return 'Not assigned';
    }
    return equipmentIdToName[equipmentId] ?? 'Unknown';
  }

  void _showEditDeviceDialog(BuildContext context, String id) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        final device = devices.firstWhere((device) => device['id'] == id);
        return EditDeviceDialog(
            id: id,
            initialName: device['device_name'],
            initialEquipment: device['equipment_id'],
            initialFactory: device['factory_id'],
            initialProductionArea: device['productionArea'],
            firestoreService: FirestoreService(),
            onDeviceAdded: fetchDevices);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalPages =
        (devices.isNotEmpty) ? (devices.length / devicesPerPage).ceil() : 0;
    if (currentDevicesPage >= totalPages) {
      currentDevicesPage = totalPages > 0 ? totalPages - 1 : 0;
    }
    // double screenWidth = MediaQuery.of(context).size.width;

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
                  padding:
                      const EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard/Devices Setting',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Builder(builder: (context) {
                            final isLight = Theme.of(context).brightness ==
                                Brightness.light;
                            return Text(
                              'Devices Settings',
                              style: TextStyle(
                                  fontSize: 24,
                                  color: isLight
                                      ? FlutterFlowTheme.of(context).txtPrimary
                                      : Colors.white,
                                  fontWeight: FontWeight.bold),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Builder(builder: (context) {
                          final isLight =
                              Theme.of(context).brightness == Brightness.light;
                          final txtColor = isLight
                              ? FlutterFlowTheme.of(context).txtPrimary
                              : Colors.white;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Last Update: ',
                                      style: TextStyle(
                                        color: txtColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: lastUpdateTime,
                                      style: TextStyle(color: txtColor),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  listenForNewTopics();
                                  fetchDevices();
                                  fetchEquipments();
                                  fetchProductionArea();
                                  fetchFactory();
                                },
                                icon: Icon(Icons.refresh,
                                    size: 16, color: txtColor),
                                label: Text('Refresh',
                                    style: TextStyle(color: txtColor)),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
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
                              controller: deviceSearchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Search By $deviceFilterController...',
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
                                Timer(const Duration(milliseconds: 300), () {
                                  searchDevices(value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 180,
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
                              value: deviceFilterController,
                              items: ['Device Name', 'Equipment Name', 'Topic']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  deviceFilterController = newValue!;
                                });
                                searchDevices(deviceSearchController.text);
                              },
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 21.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800.withOpacity(0.8)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: devices.isNotEmpty
                        ? Scrollbar(
                            thumbVisibility: true,
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _scrollController,
                              child: DataTable(
                                border: const TableBorder(
                                  verticalInside: BorderSide(
                                      width: 0.5, color: Colors.grey),
                                  bottom: BorderSide(
                                      width: 0.5, color: Colors.grey),
                                ),
                                columns: const [
                                  DataColumn(
                                      label: Text('Device ID',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: SizedBox(
                                    width: 90,
                                    child: Text('Device Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  )),
                                  // if (screenWidth > 1785)
                                  DataColumn(
                                      label: Text('Equipment ID',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  // if (screenWidth > 1300 )
                                  DataColumn(
                                      label: Text('Equipment Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  // if (screenWidth > 1085 )
                                  DataColumn(
                                      label: Text('Production Area',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  // if (screenWidth > 900 )
                                  DataColumn(
                                      label: Text('Factory',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  // if (screenWidth > 1495)
                                  DataColumn(
                                      label: Text('Topic',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  // if (screenWidth > 1640)
                                  DataColumn(
                                      label: Text('Channel Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Action',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: _createDevicesRows(),
                              ),
                            ),
                          )
                        : const Center(
                            child: Text(
                              'No devices found.',
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
                        onPressed: currentDevicesPage > 0
                            ? () {
                                setState(() {
                                  currentDevicesPage--;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(110, 30),
                          backgroundColor: currentDevicesPage < totalPages - 1
                              ? Colors.grey[300]
                              : Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 5),
                      for (int i = 0; i < totalPages; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                currentDevicesPage = i;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentDevicesPage == i
                                  ? const Color.fromARGB(255, 122, 34, 236)
                                  : Colors.grey[300],
                              foregroundColor: currentDevicesPage == i
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            child: Text('${i + 1}'),
                          ),
                        ),
                      const SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: currentDevicesPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentDevicesPage++;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(110, 30),
                          backgroundColor: currentDevicesPage < totalPages - 1
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
        if (_isLoading)
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
  }
}
