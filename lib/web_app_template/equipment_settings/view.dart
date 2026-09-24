import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:smartmachine365/auth/firebase_auth/auth_util.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/add.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/edit.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/import_equipment_excel_dialog.dart';
import 'package:smartmachine365/backend/firebase/firebase_config.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/rbac.dart';
import 'package:smartmachine365/services/app_config.dart';

const List<TableColumn> _equipmentColumns = [
  TableColumn('Equipment ID', 'equipment_id', 110),
  TableColumn('Equipment Name', 'name', 150, sortable: true),
  TableColumn('Equipment Type', 'equipment_type', 130),
  TableColumn('Equipment Category', 'equipment_category', 150),
  TableColumn('Client', 'work_id', 140),
  TableColumn('Model Type', 'modelType', 130),
  TableColumn('Serial No.', 'serialNo', 110),
  TableColumn('Production Line', 'production_line', 140),
  TableColumn('OEE', 'enableOEE', 80),
  TableColumn('Energy', 'enableEnergy', 80),
  TableColumn('Production Area', 'productionArea', 130),
  TableColumn('Plant', 'factory_id', 110),
  TableColumn('Purchase Date', 'purchaseDate', 110),
  TableColumn('Warranty Date', 'warrantyDate', 110),
  TableColumn('PIC', 'PIC', 100),
];

class EquipmentView extends StatefulWidget {
  final String userRole;
  final String factoryId;
  const EquipmentView({super.key, required this.userRole, this.factoryId = ''});

  @override
  _EquipmentViewState createState() => _EquipmentViewState();
}

class _EquipmentViewState extends State<EquipmentView> {
  @override
  void initState() {
    super.initState();
    fetchEquipment();
    fetchWorkOrder();
    fetchFactory();
    fetchProductionArea();
    fetchEquipmentLookups();
  }

  List<Map<String, dynamic>> equipments = [];
  List<String> workOrders = [];
  List<dynamic> productionAreas = [];
  Map<String, String> productionAreaToName = {};
  List<dynamic> factories = [];
  Map<String, String> factoryToName = {};
  Map<String, String> deviceTypeIdToName = {};
  Map<String, String> categoryIdToName = {};
  Map<String, String> productionLineIdToName = {};
  bool _isLoading = false;

  Future<void> fetchWorkOrder() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/workOrders";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedWorkId = json.decode(response.body);
        List<String> workOrderIdList = [];
        if (fetchedWorkId.isNotEmpty) {
          for (dynamic workOrder in fetchedWorkId) {
            workOrderIdList.add(workOrder['id']?.toString() ?? '');
          }
        }
        setState(() {
          workOrders = workOrderIdList;
        });
      } else {
        throw Exception("Failed to fetch work orders: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching work order: $e');
    }
  }

  Future<void> fetchProductionArea() async {
    try {
      final String uid = AppStateNotifier.instance.uid ?? '';
      final normalizedRole = AppRoles.normalizeRole(widget.userRole);
      final isSuperAdminOrAdmin = normalizedRole == AppRoles.superAdmin ||
          normalizedRole == AppRoles.admin;

      final params = <String, String>{};
      if (!isSuperAdminOrAdmin) {
        if (uid.isNotEmpty) params['userId'] = uid;
        if (widget.factoryId.isNotEmpty) {
          params['factory_id'] = widget.factoryId;
        }
      }

      final uri =
          Uri.parse("${AppConfig.dataApiBaseSafe}/productionAreas")
              .replace(
        queryParameters: params.isNotEmpty ? params : null,
      );
      final response = await http.get(uri, headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedProId = json.decode(response.body);
        setState(() {
          productionAreas = fetchedProId;
          productionAreaToName = {
            for (var pa in productionAreas)
              (pa['id']?.toString() ?? ''): (pa['name']?.toString() ?? '')
          };
        });
      } else {
        throw Exception(
            "Failed to fetch production areas: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching production area: $e');
    }
  }

  String _getProductionAreaName(dynamic productionAreaID) {
    if (productionAreaID == null ||
        productionAreaID == '0' ||
        productionAreaID.toString().isEmpty) return 'Not assigned';
    final idStr = productionAreaID.toString();
    return productionAreaToName[idStr] ?? idStr;
  }

  Future<void> fetchFactory() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/factory";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedFacId = json.decode(response.body);
        setState(() {
          factories = fetchedFacId;
          factoryToName = {
            for (var factory in factories)
              (factory['id']?.toString() ?? ''):
                  (factory['name']?.toString() ?? '')
          };
        });
      } else {
        throw Exception("Failed to fetch factories: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching factories: $e');
    }
  }

  String _getFactoryName(dynamic factoryID) {
    if (factoryID == null || factoryID == '0' || factoryID.toString().isEmpty)
      return 'Not assigned';
    final idStr = factoryID.toString();
    return factoryToName[idStr] ?? idStr;
  }

  Future<void> fetchEquipmentLookups() async {
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final categoryUri = Uri.parse(
              "${AppConfig.dataApiBaseSafe}/equipmentCategory")
          .replace(
        queryParameters:
            widget.factoryId.isNotEmpty ? {'factory_id': widget.factoryId} : null,
      );
      final lineUri =
          Uri.parse("${AppConfig.dataApiBaseSafe}/productionLines")
              .replace(
        queryParameters:
            widget.factoryId.isNotEmpty ? {'factory_id': widget.factoryId} : null,
      );

      final responses = await Future.wait([
        http.get(categoryUri, headers: AppConfig.headers),
        http.get(lineUri, headers: AppConfig.headers),
      ]);

      if (responses[0].statusCode == 200) {
        final List<dynamic> categories = json.decode(responses[0].body);
        deviceTypeIdToName = {
          for (final item in categories)
            (item['id']?.toString() ?? ''): (item['device_type']?.toString() ?? '')
        }..removeWhere((key, value) => key.isEmpty || value.trim().isEmpty);

        categoryIdToName = {
          for (final item in categories)
            (item['equipment_category_id']?.toString() ?? ''):
                (item['equipment_category']?.toString() ?? '')
        }..removeWhere((key, value) => key.isEmpty || value.trim().isEmpty);
      }

      if (responses[1].statusCode == 200) {
        final List<dynamic> lines = json.decode(responses[1].body);
        productionLineIdToName = {
          for (final item in lines)
            (item['id']?.toString() ?? ''): (item['name']?.toString() ?? '')
        }..removeWhere((key, value) => key.isEmpty || value.trim().isEmpty);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error fetching equipment lookups: $e');
    }
  }

  Future<void> fetchEquipment() async {
    setState(() => _isLoading = true);
    try {
      final String uid = AppStateNotifier.instance.uid ?? '';
      final normalizedRole = AppRoles.normalizeRole(widget.userRole);
      final isSuperAdminOrAdmin = normalizedRole == AppRoles.superAdmin ||
          normalizedRole == AppRoles.admin;

      final params = <String, String>{};
      if (!isSuperAdminOrAdmin) {
        if (uid.isNotEmpty) params['userId'] = uid;
        if (widget.factoryId.isNotEmpty) {
          params['factory_id'] = widget.factoryId;
        }
      }

      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final uri = Uri.parse("${AppConfig.dataApiBaseSafe}/equipment")
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> fetched = json.decode(response.body);
        setState(() {
          equipments =
              fetched.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      } else {
        throw Exception("Failed to fetch equipments: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching equipments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/equipment/$id";
      final response = await http.delete(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        try {
          if (!isFirebaseInitialized) await initFirebase();
          CollectionReference workOrderCollection =
              FirebaseFirestore.instance.collection('workOrders');
          Map<String, dynamic> equipment =
              equipments.firstWhere((e) => e['id'] == id);
          List<String> selectedWork = [];
          if (equipment['work_id'] is List) {
            selectedWork = List<String>.from(equipment['work_id']);
          } else if (equipment['work_id'] is String &&
              equipment['work_id'].isNotEmpty) {
            selectedWork = [equipment['work_id']];
          }
          for (String work in selectedWork) {
            await workOrderCollection.doc(work).update({'equipment': ''});
          }
        } catch (_) {}
        setState(() {
          equipments.removeWhere((e) => e['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment deleted successfully!',
                  style: TextStyle(color: Colors.green)),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception("Equipment not found");
      } else {
        throw Exception("Failed to delete equipment: ${response.statusCode}");
      }
    } catch (e) {
      print('Error deleting equipment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getWorkOrderDisplay(dynamic workId) {
    if (workId == null) return '';
    if (workId is List) return List<String>.from(workId).join(', ');
    if (workId is String) return workId;
    return workId.toString();
  }

  Widget _tip(String text, {TextStyle? style}) {
    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 400),
      child: Text(text, overflow: TextOverflow.ellipsis, style: style),
    );
  }

  Widget? _cellBuilder(String key, String value, Map<String, dynamic> row) {
    switch (key) {
      case 'work_id':
        return _tip(AppConfig.clientName.isNotEmpty ? AppConfig.clientName : '-');
      case 'productionArea':
        return _tip(_getProductionAreaName(value));
      case 'factory_id':
        return _tip(_getFactoryName(value));
      case 'enableOEE':
      case 'enableEnergy':
        final bool enabled = (value == 'true' || value == '1' || value == true);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: enabled
                    ? Colors.green.withOpacity(0.5)
                    : Colors.red.withOpacity(0.5)),
          ),
          child: Text(
            enabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
                color: enabled ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        );
      case 'equipment_type':
      case 'equipment_category':
      case 'production_line':
        return _tip(_getResolvedValue(row, key) ?? '-');
      case 'purchaseDate':
        if (value.isEmpty) return _tip('-');
        try {
          return _tip(DateFormat('dd/MM/yyyy').format(DateTime.parse(value)));
        } catch (_) {
          return _tip(value);
        }
      case 'warrantyDate':
        if (value.isEmpty) return _tip('-');
        try {
          return _tip(DateFormat('dd/MM/yyyy').format(DateTime.parse(value)));
        } catch (_) {
          return _tip(value);
        }
      default:
        return null;
    }
  }

  String? _getResolvedValue(Map<String, dynamic> row, String key) {
    // 1. Priority exact matches for Equipment Type and Category
    if (key == 'equipment_type') {
      final typeId = row['device_type_id']?.toString() ?? '';
      if (typeId.isNotEmpty && deviceTypeIdToName.containsKey(typeId)) {
        return deviceTypeIdToName[typeId];
      }
      if (row['device_type'] != null && row['device_type'].toString().isNotEmpty) return row['device_type'].toString();
      if (row['equipment_type'] != null && row['equipment_type'].toString().isNotEmpty) return row['equipment_type'].toString();
      if (row['equipmentType'] != null && row['equipmentType'].toString().isNotEmpty) return row['equipmentType'].toString();
    } else if (key == 'equipment_category') {
      final categoryId = row['category_id']?.toString() ?? '';
      if (categoryId.isNotEmpty && categoryIdToName.containsKey(categoryId)) {
        return categoryIdToName[categoryId];
      }
      if (row['equipment_category'] != null && row['equipment_category'].toString().isNotEmpty) return row['equipment_category'].toString();
      if (row['device_category'] != null && row['device_category'].toString().isNotEmpty) return row['device_category'].toString();
      if (row['category'] != null && row['category'].toString().isNotEmpty) return row['category'].toString();
    } else if (key == 'production_line') {
      final productionLineId = row['production_line_id']?.toString() ?? '';
      if (productionLineId.isNotEmpty &&
          productionLineIdToName.containsKey(productionLineId)) {
        return productionLineIdToName[productionLineId];
      }
    }

    // 2. Direct match as fallback
    if (row[key] != null && row[key].toString().trim().isNotEmpty) {
      return row[key].toString();
    }

    // 3. Define the search terms for each logical field
    final List<String> searchTerms;
    final List<String> excludeTerms;
    
    if (key == 'equipment_type') {
      searchTerms = ['type', 'devicetype', 'equipmenttype'];
      excludeTerms = ['model']; // EXCLUDE modelType
    } else if (key == 'equipment_category') {
      searchTerms = ['category', 'devicecategory', 'equipmentcategory'];
      excludeTerms = [];
    } else if (key == 'production_line') {
      searchTerms = ['line', 'productionline'];
      excludeTerms = [];
    } else {
      searchTerms = [key.toLowerCase().replaceAll('_', '')];
      excludeTerms = [];
    }

    // 4. Fuzzy match: case-insensitive and ignore underscores
    for (var k in row.keys) {
      final normalizedK = k.toLowerCase().replaceAll('_', '');
      
      // Check exclusions first
      bool isExcluded = false;
      for (var ex in excludeTerms) {
        if (normalizedK.contains(ex)) {
          isExcluded = true;
          break;
        }
      }
      if (isExcluded) continue;

      for (var term in searchTerms) {
        if (normalizedK == term || normalizedK.contains(term)) {
          final val = row[k];
          if (val != null && val.toString().trim().isNotEmpty) {
            return val.toString();
          }
        }
      }
    }
    return null;
  }

  void _onEdit(Map<String, dynamic> row) =>
      _showEditEquipmentDialog(context, row);

  void _onDelete(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Equipment',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${row['name']}"? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              deleteEquipment(row['id']);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74852),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AddEquipmentDialog(
          onEquipmentAdded: fetchEquipment,
          userRole: widget.userRole,
          userId: AppStateNotifier.instance.uid ?? '',
          factoryId: widget.factoryId,
        );
      },
    );
  }

  void _showImportExcelDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ImportEquipmentExcelDialog(
          existingEquipments: equipments,
          userId: AppStateNotifier.instance.uid ?? '',
          factoryId: widget.factoryId,
          onImported: fetchEquipment,
        );
      },
    );
  }

  void _showEditEquipmentDialog(
      BuildContext context, Map<String, dynamic> equipment) {
    DateTime purchaseDateDT;
    try {
      purchaseDateDT = DateTime.parse(equipment['purchaseDate']?.toString() ??
          DateTime.now().toIso8601String());
    } catch (_) {
      purchaseDateDT = DateTime.now();
    }
    Timestamp purchaseDate = Timestamp.fromDate(purchaseDateDT);

    DateTime warrantyDateDT;
    try {
      warrantyDateDT = DateTime.parse(equipment['warrantyDate']?.toString() ??
          DateTime.now().toIso8601String());
    } catch (_) {
      warrantyDateDT = DateTime.now();
    }
    Timestamp warrantyDate = Timestamp.fromDate(warrantyDateDT);

    List<String> workIdList = [];
    if (equipment['work_id'] is List) {
      workIdList = List<String>.from(equipment['work_id']);
    } else if (equipment['work_id'] is String &&
        equipment['work_id'].isNotEmpty) {
      workIdList = [equipment['work_id']];
    }

    String? equipmentProcess = workIdList.isNotEmpty ? workIdList[0] : null;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return EditEquipmentDialog(
          id: equipment['id'] ?? '',
          userId: AppStateNotifier.instance.uid ?? '',
          initialEquipmentId: equipment['equipment_id']?.toString() ?? '',
          initialName: equipment['name'] ?? '',
          initialSerialNo: equipment['serialNo'] ?? '',
          initialModelType: equipment['modelType'] ?? '',
          initialProductionArea: equipment['productionArea'] ?? '',
          initialFactory: equipment['factory_id'] ?? '',
          initialPurchaseDate: purchaseDate,
          initialWarrantyDate: warrantyDate,
          initialPIC: equipment['PIC'] ?? '',
          initialWork: workIdList,
          initialEquipmentProcess: equipmentProcess,
          initialImageUrl: equipment['imageUrl'],
          initialEquipmentType: _getResolvedValue(equipment, 'equipment_type'),
          initialEquipmentCategory:
              _getResolvedValue(equipment, 'equipment_category'),
          initialProductionLine: _getResolvedValue(equipment, 'production_line'),
          initialEnableOEE: (equipment['enableOEE'] == 'true' ||
              equipment['enableOEE'] == true),
          initialEnableEnergy: (equipment['enableEnergy'] == 'true' ||
              equipment['enableEnergy'] == true),
          initialTargetKwhPerTonne:
              double.tryParse(equipment['targetKwhPerTonne']?.toString() ?? '') ?? 0.0,
          initialWarningPct:
              double.tryParse(equipment['warningPct']?.toString() ?? '') ?? 0.0,
          initialCriticalPct:
              double.tryParse(equipment['criticalPct']?.toString() ?? '') ?? 0.0,
          initialRatePerKwh:
              double.tryParse(equipment['ratePerKwh']?.toString() ?? '') ?? 0.0,
          initialCurrency: (equipment['currency']?.toString().isNotEmpty ?? false)
              ? equipment['currency'].toString()
              : 'RM',
          initialDpmId: equipment['dpmId']?.toString() ?? '',
          factoryId: widget.factoryId,
          onEquipmentAdded: () {
            fetchProductionArea();
            fetchWorkOrder();
            fetchEquipment();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          breadcrumbs: [
            BreadcrumbItem(label: 'Settings', icon: Icons.settings),
            BreadcrumbItem(label: 'Equipment Settings'),
          ],
          title: 'Equipment Settings',
          subtitle: 'Manage your equipment, all in one place.',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF31ECFC)))
                : DataTableWidget(
                    columns: _equipmentColumns,
                    rows: equipments,
                    perPage: 13,
                    primaryKey: 'id',
                    primaryColumnKey: 'name',
                    primarySubtitleKey: 'equipment_id',
                    primaryIcon: Icons.precision_manufacturing_outlined,
                    sortKey: 'name',
                    cellBuilder: _cellBuilder,
                    onEdit: _onEdit,
                    onDelete: _onDelete,
                    onSelectionChanged: (ids) {},
                    showSelection: false,
                    showFilterDropdown: false,
                    actions: [
                      TableAction(
                        label: 'Import Excel',
                        icon: Icons.upload_file,
                        isPrimary: false,
                        onTap: () => _showImportExcelDialog(context),
                      ),
                      TableAction(
                        label: 'Add Equipment',
                        icon: Icons.add,
                        isPrimary: true,
                        onTap: () => _showAddEquipmentDialog(context),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
