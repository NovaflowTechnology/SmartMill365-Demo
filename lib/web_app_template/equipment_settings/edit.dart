import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class EditEquipmentDialog extends StatefulWidget {
  final String id;
  final String initialEquipmentId;
  final String initialName;
  final String initialSerialNo;
  final String initialModelType;
  final Timestamp initialPurchaseDate;
  final Timestamp initialWarrantyDate;
  final dynamic initialWork;
  final String initialPIC;
  final String initialProductionArea;
  final String initialFactory;
  final String? initialEquipmentProcess;
  final String? initialImageUrl;
  final String userId;
  final VoidCallback onEquipmentAdded;
  
  final String? initialEquipmentType;
  final String? initialEquipmentCategory;
  final String? initialProductionLine;
  final bool initialEnableOEE;
  final bool initialEnableEnergy;
  final double initialTargetKwhPerTonne;
  final double initialWarningPct;
  final double initialCriticalPct;
  final double initialRatePerKwh;
  final String initialCurrency;
  final String initialDpmId;
  final String factoryId;

  const EditEquipmentDialog({
    super.key,
    required this.id,
    this.initialEquipmentId = '',
    required this.initialName,
    required this.initialSerialNo,
    required this.initialModelType,
    required this.initialPurchaseDate,
    required this.initialWarrantyDate,
    required this.initialPIC,
    required this.initialWork,
    required this.initialProductionArea,
    required this.initialFactory,
    this.initialEquipmentProcess,
    this.initialImageUrl,
    required this.userId,
    required this.onEquipmentAdded,
    this.initialEquipmentType,
    this.initialEquipmentCategory,
    this.initialProductionLine,
    this.initialEnableOEE = false,
    this.initialEnableEnergy = false,
    this.initialTargetKwhPerTonne = 0.0,
    this.initialWarningPct = 0.0,
    this.initialCriticalPct = 0.0,
    this.initialRatePerKwh = 0.0,
    this.initialCurrency = 'RM',
    this.initialDpmId = '',
    this.factoryId = '',
  });

  @override
  _EditEquipmentDialogState createState() => _EditEquipmentDialogState();
}

class _EditEquipmentDialogState extends State<EditEquipmentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _equipmentIdController;
  late TextEditingController _nameController;
  late TextEditingController _serialNoController;
  late TextEditingController _modelTypeController;
  late TextEditingController _purchaseDateController;
  late TextEditingController _warrantyDateController;
  late TextEditingController _picController;
  late TextEditingController _equipmentProcessController;
  late TextEditingController _equipmentCategoryController;
  late TextEditingController _productionAreaController;
  late TextEditingController _factoryController;

  List<String> fetchedWork = [];
  List<String>? selectedWork;
  
  List<dynamic> fetchedDeviceTypes = [];
  String? selectedDeviceType;
  
  List<dynamic> fetchedProductionLines = [];
  String? selectedProductionLine;
  List<dynamic> fetchedFactories = [];
  String? selectedFactory;

  late bool enableOEE;
  late bool enableEnergy;
  List<FacilityData> fetchedFacilities = [];
  String? selectedDpmId;
  String _initialDpmId = '';
  late TextEditingController _targetKwhController;
  late TextEditingController _warningPctController;
  late TextEditingController _criticalPctController;
  late TextEditingController _rateController;
  late TextEditingController _currencyController;

  Uint8List? _imageBytes;
  String? _imageUrl;
  String? _imageExtension;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];

  String? selectedEquipmentProcess;
  bool showManualEquipmentProcess = false;
  List<String> equipmentProcessOptions = [];

  String? _errorMessage;
  String? _serialNoError;
  List<String> previousWorkOrderList = [];

  final RegExp serialNoRegex = RegExp(r'^#\d{5}$');

  @override
  void initState() {
    super.initState();
    final dateFormat = DateFormat('yyyy-MM-dd');
    _equipmentIdController = TextEditingController(text: widget.initialEquipmentId);
    _nameController = TextEditingController(text: widget.initialName);
    _serialNoController = TextEditingController(text: widget.initialSerialNo);
    _modelTypeController = TextEditingController(text: widget.initialModelType);
    _purchaseDateController = TextEditingController(
        text: dateFormat.format(widget.initialPurchaseDate.toDate()));
    _warrantyDateController = TextEditingController(
        text: dateFormat.format(widget.initialWarrantyDate.toDate()));
    _picController = TextEditingController(text: widget.initialPIC);
    _equipmentProcessController = TextEditingController();
    _equipmentCategoryController = TextEditingController(text: widget.initialEquipmentCategory);
    _productionAreaController = TextEditingController(text: widget.initialProductionArea);
    _factoryController = TextEditingController(text: widget.initialFactory);

    selectedDeviceType = widget.initialEquipmentType;
    selectedProductionLine = widget.initialProductionLine;
    selectedFactory = widget.initialFactory.isNotEmpty ? widget.initialFactory : null;
    enableOEE = widget.initialEnableOEE;
    enableEnergy = widget.initialEnableEnergy;
    _initialDpmId = widget.initialDpmId.trim();
    selectedDpmId = _initialDpmId.isNotEmpty ? _initialDpmId : null;
    _targetKwhController = TextEditingController(text: widget.initialTargetKwhPerTonne.toStringAsFixed(0));
    _warningPctController = TextEditingController(text: widget.initialWarningPct.toStringAsFixed(0));
    _criticalPctController = TextEditingController(text: widget.initialCriticalPct.toStringAsFixed(0));
    _rateController = TextEditingController(text: widget.initialRatePerKwh.toStringAsFixed(2));
    _currencyController = TextEditingController(text: widget.initialCurrency);

    _imageUrl = widget.initialImageUrl;
    if (_imageUrl != null && _imageUrl!.isNotEmpty) _loadExistingImage();

    _mergeEquipmentProcessOptions();
    if (widget.initialEquipmentProcess != null &&
        widget.initialEquipmentProcess!.isNotEmpty) {
      if (equipmentProcessOptions.contains(widget.initialEquipmentProcess)) {
        selectedEquipmentProcess = widget.initialEquipmentProcess;
      } else {
        selectedEquipmentProcess = 'Other (Manual Entry)';
        _equipmentProcessController.text = widget.initialEquipmentProcess!;
        showManualEquipmentProcess = true;
      }
    }

    fetchWork();
    fetchDeviceTypes();
    fetchProductionLines();
    fetchFactories();
    fetchFacilities();

    previousWorkOrderList = _convertToStringList(widget.initialWork);
  }

  Future<void> fetchFacilities() async {
    try {
      final facilities = await FacilityService.getFacilities();
      setState(() {
        fetchedFacilities =
            facilities.where((f) => f.meterId.trim().isNotEmpty).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _equipmentIdController.dispose();
    _nameController.dispose();
    _serialNoController.dispose();
    _modelTypeController.dispose();
    _purchaseDateController.dispose();
    _warrantyDateController.dispose();
    _picController.dispose();
    _equipmentProcessController.dispose();
    _equipmentCategoryController.dispose();
    _productionAreaController.dispose();
    _factoryController.dispose();
    _targetKwhController.dispose();
    _warningPctController.dispose();
    _criticalPctController.dispose();
    _rateController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> fetchDeviceTypes() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/equipmentCategory?factory_id=${widget.factoryId}";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => fetchedDeviceTypes = data.where((e) => e['device_type'] != null && e['device_type'].toString().isNotEmpty).toList());
      }
    } catch (e) {
      print('Error fetching device types: $e');
    }
  }

  Future<void> fetchProductionLines() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/productionLines";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => fetchedProductionLines = data.where((e) => e['name'] != null && e['name'].toString().isNotEmpty).toList());
      }
    } catch (e) {
      print('Error fetching production lines: $e');
    }
  }

  Future<void> fetchFactories() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/factory";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          fetchedFactories = data
              .where((e) =>
                  e['id'] != null &&
                  e['id'].toString().isNotEmpty &&
                  e['name'] != null &&
                  e['name'].toString().isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching factories: $e');
    }
  }

  String _extractPathFromUrl(String url) {
    try {
      if (url.contains('/o/')) {
        String encodedPath = url.split('/o/')[1].split('?')[0];
        return Uri.decodeComponent(encodedPath);
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadExistingImage() async {
    if (_imageUrl == null || _imageUrl!.isEmpty) return;
    try {
      String path = _extractPathFromUrl(_imageUrl!);
      if (path.isEmpty) return;

      if (kIsWeb) {
        await _loadImageViaHttp(_imageUrl!);
      } else {
        final ref = FirebaseStorage.instance.ref().child(path);
        final bytes = await ref.getData();
        if (bytes != null && mounted) setState(() => _imageBytes = bytes);
      }
    } catch (_) {
      if (_imageUrl != null && _imageUrl!.isNotEmpty)
        await _loadImageViaHttp(_imageUrl!);
    }
  }

  Future<void> _loadImageViaHttp(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        setState(() => _imageBytes = response.bodyBytes);
      }
    } catch (_) {}
  }

  void _mergeEquipmentProcessOptions() {
    Set<String> mergedOptions = {};
    List<String> workList = _convertToStringList(widget.initialWork);
    if (workList.isNotEmpty) mergedOptions.addAll(workList);
    equipmentProcessOptions = mergedOptions.toList()
      ..add('Other (Manual Entry)');
  }

  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.isEmpty ? [] : [value];
    return [value.toString()];
  }

  Future<void> _pickAndValidateImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 100);
      if (pickedFile != null) {
        String fileName = pickedFile.name.toLowerCase();
        String fileExtension = fileName.split('.').last;
        if (!allowedExtensions.contains(fileExtension)) {
          setState(() => _errorMessage = 'Only JPG and PNG images are allowed');
          return;
        }
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > maxImageSizeBytes) {
          setState(() => _errorMessage =
              'Image size must be less than 5MB (current: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)}MB)');
          return;
        }
        setState(() {
          _imageBytes = bytes;
          _imageExtension = fileExtension;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking image: $e');
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_imageBytes == null) return _imageUrl;
    try {
      String contentType = 'image/jpeg';
      String fileExtension = 'jpg';
      if (_imageExtension == 'png') {
        contentType = 'image/png';
        fileExtension = 'png';
      }
      String fileName = 'equipment_${widget.id}.$fileExtension';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('equipment_images/${widget.userId}/$fileName');
      final UploadTask uploadTask = storageRef.putData(
          _imageBytes!, SettableMetadata(contentType: contentType));
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      setState(() => _errorMessage = 'Error uploading image: $e');
      return null;
    }
  }

  Future<void> fetchWork() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/workOrders";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> workOrders = json.decode(response.body);
        List<String> workOrderIdList =
            workOrders.map((w) => w['id']?.toString() ?? '').toList();
        setState(() {
          fetchedWork = workOrderIdList;
          List<String> initialWorkList =
              _convertToStringList(widget.initialWork);
          selectedWork = fetchedWork.isNotEmpty ? initialWorkList : [];
          _updateEquipmentProcessOptions();
        });
      } else {
        throw Exception("Failed to fetch work orders: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error fetching work orders: $e');
    }
  }

  void _updateEquipmentProcessOptions() {
    Set<String> mergedOptions = {};
    mergedOptions.addAll(_convertToStringList(widget.initialWork));
    mergedOptions.addAll(fetchedWork);
    equipmentProcessOptions = mergedOptions.toList()..sort();
    equipmentProcessOptions.add('Other (Manual Entry)');
  }

  String? getEquipmentProcessValue() {
    if (showManualEquipmentProcess &&
        _equipmentProcessController.text.isNotEmpty) {
      return _equipmentProcessController.text;
    } else if (selectedEquipmentProcess != null &&
        selectedEquipmentProcess != 'Other (Manual Entry)') {
      return selectedEquipmentProcess;
    }
    return null;
  }

  Future<bool> _submitForm() async {
    setState(() {
      _errorMessage = null;
      _serialNoError = null;
    });

    if (_nameController.text.isEmpty ||
        _serialNoController.text.isEmpty ||
        _modelTypeController.text.isEmpty ||
        selectedDeviceType == null ||
        selectedProductionLine == null ||
        _purchaseDateController.text.isEmpty ||
        _warrantyDateController.text.isEmpty ||
        _picController.text.isEmpty ||
        (showManualEquipmentProcess &&
            _equipmentProcessController.text.isEmpty)) {
      setState(() => _errorMessage = 'All fields are required.');
      return false;
    }

    try {
      String? uploadedImageUrl;
      if (_imageBytes != null) {
        setState(() => _isUploadingImage = true);
        uploadedImageUrl = await _uploadImageToFirebase();
        setState(() => _isUploadingImage = false);
        if (uploadedImageUrl == null) {
          setState(() =>
              _errorMessage = 'Failed to upload image. Please try again.');
          return false;
        }
      } else {
        uploadedImageUrl = _imageUrl;
      }

      final String apiUrl =
          "${AppConfig.dataApiBaseSafe}/equipment/${widget.id}";
      String purchaseDateISO =
          DateTime.parse(_purchaseDateController.text).toIso8601String();
      String warrantyDateISO =
          DateTime.parse(_warrantyDateController.text).toIso8601String();

      // Get selected item objects to extract both ID and Name
      final selectedTypeObj = fetchedDeviceTypes.firstWhere(
        (e) => e['device_type']?.toString() == selectedDeviceType,
        orElse: () => {},
      );
      final selectedLineObj = fetchedProductionLines.firstWhere(
        (e) => e['name']?.toString() == selectedProductionLine,
        orElse: () => {},
      );
      final String selectedFactoryValue =
          (selectedFactory ?? _factoryController.text).trim();

      final Map<String, dynamic> requestData = {
        "id": widget.id,
        "userId": widget.userId,
        "equipment_id": _equipmentIdController.text.trim(),
        "equipmentId": _equipmentIdController.text.trim(),
        "name": _nameController.text.trim(),
        "initialSerialNo": widget.initialSerialNo,
        "serialNo": _serialNoController.text.trim(),
        "modelType": _modelTypeController.text.trim(),
        
        // Equipment Type
        "equipment_type": (selectedDeviceType ?? '').trim(),
        "equipmentType": (selectedDeviceType ?? '').trim(),
        "device_type": (selectedDeviceType ?? '').trim(),
        "type": (selectedDeviceType ?? '').trim(),
        "device_type_id": selectedTypeObj['id']?.toString() ?? '',
        
        // Equipment Category
        "equipment_category": _equipmentCategoryController.text.trim(),
        "equipmentCategory": _equipmentCategoryController.text.trim(),
        "device_category": _equipmentCategoryController.text.trim(),
        "category": _equipmentCategoryController.text.trim(),
        "category_id": selectedTypeObj['equipment_category_id']?.toString() ?? '',
        
        // Production Line
        "production_line": (selectedProductionLine ?? '').trim(),
        "productionLine": (selectedProductionLine ?? '').trim(),
        "line": (selectedProductionLine ?? '').trim(),
        "production_line_id": selectedLineObj['id']?.toString() ?? '',
        
        "productionArea": _productionAreaController.text.trim(),
        "factory": selectedFactoryValue,
        "factory_id": selectedFactoryValue,
        "enableOEE": enableOEE,
        "enableEnergy": enableEnergy,
        "dpmId": enableEnergy ? (selectedDpmId ?? '') : '',
        "targetKwhPerTonne": double.tryParse(_targetKwhController.text) ?? 0.0,
        "warningPct": double.tryParse(_warningPctController.text) ?? 0.0,
        "criticalPct": double.tryParse(_criticalPctController.text) ?? 0.0,
        "ratePerKwh": double.tryParse(_rateController.text) ?? 0.0,
        "currency": _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim() : 'RM',
        "equipmentProcess": getEquipmentProcessValue(),
        "purchaseDate": purchaseDateISO,
        "warrantyDate": warrantyDateISO,
        "PIC": _picController.text.trim(),
        "workOrder": selectedWork,
      };

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: AppConfig.headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        if (uploadedImageUrl != null) {
          await http.put(
            Uri.parse(
                "${AppConfig.dataApiBaseSafe}/equipment/${widget.id}/image"),
            headers: AppConfig.headers,
            body: json.encode(
                {"userId": widget.userId, "imageUrl": uploadedImageUrl}),
          );
        }

        // Keep these fields persisted even when API update omits them.
        try {
          await FirebaseFirestore.instance
              .collection('equipments')
              .doc(widget.id)
              .set({
            "equipment_type": (selectedDeviceType ?? '').trim(),
            "equipmentType": (selectedDeviceType ?? '').trim(),
            "device_type": (selectedDeviceType ?? '').trim(),
            "device_type_id": selectedTypeObj['id']?.toString() ?? '',
            "equipment_category": _equipmentCategoryController.text.trim(),
            "equipmentCategory": _equipmentCategoryController.text.trim(),
            "device_category": _equipmentCategoryController.text.trim(),
            "category": _equipmentCategoryController.text.trim(),
            "category_id":
                selectedTypeObj['equipment_category_id']?.toString() ?? '',
            "production_line": (selectedProductionLine ?? '').trim(),
            "productionLine": (selectedProductionLine ?? '').trim(),
            "line": (selectedProductionLine ?? '').trim(),
            "production_line_id": selectedLineObj['id']?.toString() ?? '',
            "factory_id": selectedFactoryValue,
            "factory": selectedFactoryValue,
            "plant": selectedFactoryValue,
            "enableOEE": enableOEE,
            "enableEnergy": enableEnergy,
            "dpmId": enableEnergy ? (selectedDpmId ?? '') : '',
            "targetKwhPerTonne": double.tryParse(_targetKwhController.text) ?? 0.0,
            "warningPct": double.tryParse(_warningPctController.text) ?? 0.0,
            "criticalPct": double.tryParse(_criticalPctController.text) ?? 0.0,
            "ratePerKwh": double.tryParse(_rateController.text) ?? 0.0,
            "currency": _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim() : 'RM',
          }, SetOptions(merge: true));
        } catch (_) {}

        final newDpmId = enableEnergy ? (selectedDpmId ?? '').trim() : '';
        if (newDpmId != _initialDpmId) {
          try {
            if (_initialDpmId.isNotEmpty) {
              final oldFacility = fetchedFacilities.firstWhere(
                (f) => f.meterId == _initialDpmId,
                orElse: () => const FacilityData(
                  plant: '', factory: '', zone: '', productionArea: '',
                  equipmentType: '', equipmentNameId: '', meterName: '',
                  meterId: '', gatewayId: '', status: '', gridType: '',
                  maintenanceDate: '', lastMaintenanceDate: '',
                  nextMaintenanceDate: '', registrationDate: '',
                ),
              );
              if (oldFacility.id != null) {
                await FacilityService
                    .patchFacility(oldFacility.id!, {'equipmentNameId': '-'});
              }
            }
            if (newDpmId.isNotEmpty) {
              final newFacility = fetchedFacilities.firstWhere(
                (f) => f.meterId == newDpmId,
                orElse: () => const FacilityData(
                  plant: '', factory: '', zone: '', productionArea: '',
                  equipmentType: '', equipmentNameId: '', meterName: '',
                  meterId: '', gatewayId: '', status: '', gridType: '',
                  maintenanceDate: '', lastMaintenanceDate: '',
                  nextMaintenanceDate: '', registrationDate: '',
                ),
              );
              if (newFacility.id != null) {
                await FacilityService.patchFacility(newFacility.id!, {
                  'equipmentNameId':
                      '${_nameController.text.trim()} (${_equipmentIdController.text.trim()})',
                });
              }
            }
          } catch (_) {}
        }

        try {
          final responseBody = jsonDecode(response.body);
          CollectionReference workOrderCollection =
              FirebaseFirestore.instance.collection('workOrders');
          if (selectedWork != null && selectedWork!.isNotEmpty) {
            for (String work in selectedWork!) {
              await workOrderCollection
                  .doc(work)
                  .update({'equipment': responseBody['id'] ?? widget.id});
            }
          }
          for (String prev in previousWorkOrderList) {
            if (selectedWork == null || !selectedWork!.contains(prev)) {
              await workOrderCollection.doc(prev).update({'equipment': ''});
            }
          }
        } catch (_) {}

        widget.onEquipmentAdded();
        return true;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to edit equipment');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception:', '').trim();
      final lastColon = errorMessage.lastIndexOf(':');
      if (lastColon != -1 && lastColon < errorMessage.length - 1) {
        errorMessage = errorMessage.substring(lastColon + 1).trim();
      }
      setState(() => _serialNoError = errorMessage);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.edit_outlined,
      title: 'Edit Equipment',
      subtitle: 'Update the details of the selected equipment.',
      requiredNote: true,
      submitLabel: 'SAVE',
      sections: [
        CustomDialogSection(
          title: 'Equipment Image',
          subtitle: 'Upload or replace the equipment photo (JPG/PNG, max 5MB).',
          children: [
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndValidateImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.12), width: 1),
                ),
                child: _isUploadingImage
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF31ECFC)))
                    : _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(_imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder()),
                              )
                            : _imagePlaceholder(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (_imageBytes != null ||
                      (_imageUrl != null && _imageUrl!.isNotEmpty))
                  ? 'Tap image to change (JPG/PNG, max 5MB)'
                  : 'JPG or PNG, maximum 5MB',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!,
                  style:
                      const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
            ],
          ],
        ),
        CustomDialogSection(
          title: 'Classification',
          subtitle: 'Select equipment type and category.',
          children: [
            _dropdownField(
              label: 'Equipment Type',
              value: selectedDeviceType,
              items: fetchedDeviceTypes.map((e) => {
                'id': e['device_type']?.toString() ?? '',
                'name': e['device_type']?.toString() ?? '',
                'relatedInfo': e['equipment_category']?.toString() ?? '',
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedDeviceType = v;
                  final selected = fetchedDeviceTypes.firstWhere((e) => e['device_type'] == v, orElse: () => null);
                  if (selected != null) {
                    _equipmentCategoryController.text = selected['equipment_category'] ?? '';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            _inputField(label: 'Equipment Category (Auto)', controller: _equipmentCategoryController, isRequired: false, readOnly: true),
          ],
        ),
        CustomDialogSection(
          title: 'Basic Information',
          subtitle: 'Equipment name, serial number, model type and PIC.',
          children: [
            _inputField(
                label: 'Equipment ID',
                controller: _equipmentIdController,
                isRequired: true),
            const SizedBox(height: 16),
            _inputField(
                label: 'Equipment Name',
                controller: _nameController,
                isRequired: true),
            const SizedBox(height: 16),
            _inputField(
                label: 'Serial No.',
                controller: _serialNoController,
                isRequired: true),
            if (_serialNoError != null) ...[
              const SizedBox(height: 6),
              Text(_serialNoError!,
                  style:
                      const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
            ],
            const SizedBox(height: 16),
            _inputField(
                label: 'Model Type',
                controller: _modelTypeController,
                isRequired: true),
            const SizedBox(height: 16),
            _inputField(
                label: 'PIC', controller: _picController, isRequired: true),
          ],
        ),
        CustomDialogSection(
          title: 'Equipment Parent Info',
          subtitle:
              'Production line, area, plant, client and dates.',
          children: [
             _dropdownField(
              label: 'Production Line',
              value: selectedProductionLine,
              items: fetchedProductionLines.map((e) => {
                'id': e['name']?.toString() ?? '',
                'name': e['name']?.toString() ?? ''
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedProductionLine = v;
                  final selected = fetchedProductionLines.firstWhere((e) => e['name'] == v, orElse: () => null);
                  if (selected != null) {
                    _productionAreaController.text = selected['productionArea'] ?? '';
                    _factoryController.text = selected['factory_id'] ?? '';
                    selectedFactory = selected['factory_id']?.toString();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            _inputField(label: 'Production Area (Auto)', controller: _productionAreaController, isRequired: false, readOnly: true),
            const SizedBox(height: 16),
            _dropdownField(
              label: 'Plant',
              value: selectedFactory,
              items: fetchedFactories
                  .map((e) => {
                        'id': e['id']?.toString() ?? '',
                        'name': e['name']?.toString() ?? ''
                      })
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedFactory = v;
                  _factoryController.text = v ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            _inputField(
                label: 'Client (Auto)',
                controller: TextEditingController(text: AppConfig.clientName),
                isRequired: false,
                readOnly: true),
            const SizedBox(height: 16),
            _equipmentProcessDropdown(),
            if (showManualEquipmentProcess) ...[
              const SizedBox(height: 16),
              _inputField(
                  label: 'Enter Equipment Process',
                  controller: _equipmentProcessController,
                  isRequired: true),
            ],
            const SizedBox(height: 16),
            _dateField(
                controller: _purchaseDateController,
                label: 'Purchase Date',
                isRequired: true),
            const SizedBox(height: 16),
            _dateField(
                controller: _warrantyDateController,
                label: 'Warranty Expiry Date',
                isRequired: true),
          ],
        ),
        CustomDialogSection(
          title: 'Modules',
          subtitle: 'Enable or disable OEE and Energy modules.',
          children: [
            _switchField(
              label: 'Enable OEE Module',
              value: enableOEE,
              onChanged: (v) => setState(() => enableOEE = v),
            ),
            const SizedBox(height: 8),
            _switchField(
              label: 'Enable Energy Module',
              value: enableEnergy,
              onChanged: (v) => setState(() => enableEnergy = v),
            ),
            if (enableEnergy) ...[
              const SizedBox(height: 16),
              _energyThresholdFields(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!,
                  style:
                      const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
            ],
          ],
        ),
      ],
      onSubmit: _submitForm,
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate,
            size: 48, color: Colors.white.withOpacity(0.25)),
        const SizedBox(height: 8),
        Text('Tap to upload image',
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 4),
        Text('JPG or PNG, max 5MB',
            style:
                TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
      ],
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool readOnly = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white.withOpacity(0.5) : Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontSize: 11,
          letterSpacing: 0.8,
        ),
        filled: true,
        fillColor: readOnly ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontSize: 11,
          letterSpacing: 0.8,
        ),
        suffixIcon: Icon(Icons.calendar_today_outlined,
            size: 16, color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          controller.text = "${pickedDate.toLocal()}".split(' ')[0];
        }
      },
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<dynamic> items,
    required ValueChanged<String?> onChanged,
  }) {
    final seenIds = <String>{};
    final uniqueItems = <dynamic>[];
    for (var item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        uniqueItems.add(item);
      }
    }
    uniqueItems.sort((a, b) => (a['name']?.toString() ?? '')
        .toLowerCase()
        .compareTo((b['name']?.toString() ?? '').toLowerCase()));
    // If current value is not in uniqueItems, add it to avoid defaulting to null
    if (value != null && value.isNotEmpty && !seenIds.contains(value)) {
      uniqueItems.add({'id': value, 'name': value});
    }
    final isValidValue = uniqueItems.any((item) => item['id'] == value);
    return DropdownSearch<Map<String, dynamic>>(
      items: (filter, loadProps) =>
          uniqueItems.map((e) => Map<String, dynamic>.from(e)).toList(),
      selectedItem: isValidValue
          ? uniqueItems
              .cast<Map<String, dynamic>>()
              .firstWhere((item) => item['id'] == value)
          : null,
      compareFn: (a, b) => a['id']?.toString() == b['id']?.toString(),
      itemAsString: (item) => item['name']?.toString() ?? '',
      filterFn: (item, filter) {
        final keyword = filter.toLowerCase().trim();
        if (keyword.isEmpty) return true;
        final name = (item['name']?.toString() ?? '').toLowerCase();
        final relatedInfo = (item['relatedInfo']?.toString() ?? '').toLowerCase();
        final searchText = (item['searchText']?.toString() ?? '').toLowerCase();
        return name.contains(keyword) ||
            relatedInfo.contains(keyword) ||
            searchText.contains(keyword);
      },
      onChanged: (selected) => onChanged(selected?['id']?.toString()),
      popupProps: PopupProps.menu(
        fit: FlexFit.loose,
        showSearchBox: true,
        searchDelay: Duration.zero,
        searchFieldProps: TextFieldProps(
          style: const TextStyle(fontSize: 14.0, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by name or related info...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            fillColor: const Color(0xFF1A2A4A),
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
            ),
          ),
        ),
        containerBuilder: (context, popupWidget) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A4A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: popupWidget,
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          final relatedInfo = item['relatedInfo']?.toString() ?? '';
          return ListTile(
            title: Text(
              item['name']?.toString() ?? '',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
              ),
            ),
            subtitle: relatedInfo.isNotEmpty
                ? Text(
                    relatedInfo,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black.withOpacity(0.75)
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  )
                : null,
            selected: isSelected,
            selectedTileColor: const Color.fromARGB(255, 9, 218, 255),
          );
        },
      ),
      dropdownBuilder: (context, selectedItem) => Text(
        selectedItem?['name']?.toString() ?? '',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 0.8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _switchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF31ECFC),
        ),
      ],
    );
  }

  Widget _energyThresholdFields() {
    const cyan = Color(0xFF31ECFC);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THRESHOLDS & RATE',
              style: TextStyle(
                  color: cyan.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          _dropdownField(
            label: 'Device ID',
            value: selectedDpmId,
            items: fetchedFacilities
                .map((f) => {
                      'id': f.meterId,
                      'name': f.meterId,
                      'relatedInfo': f.meterName,
                    })
                .toList(),
            onChanged: (v) => setState(() => selectedDpmId = v),
          ),
          const SizedBox(height: 16),
          _inputField(label: 'Target kWh / Tonne', controller: _targetKwhController),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _inputField(label: 'Warning %', controller: _warningPctController)),
              const SizedBox(width: 16),
              Expanded(child: _inputField(label: 'Critical %', controller: _criticalPctController)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _inputField(label: 'Rate (\$/kWh)', controller: _rateController)),
              const SizedBox(width: 16),
              Expanded(child: _inputField(label: 'Currency', controller: _currencyController)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Machines exceeding the target by more than the warning % are flagged amber; those exceeding by the critical % are flagged red.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _equipmentProcessDropdown() {
    final isValidValue = equipmentProcessOptions.contains(selectedEquipmentProcess);
    return DropdownButtonFormField<String>(
      value: isValidValue ? selectedEquipmentProcess : null,
      dropdownColor: const Color(0xFF1A2A4A),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Equipment Process',
        labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            letterSpacing: 0.8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: equipmentProcessOptions.map((String process) {
        return DropdownMenuItem<String>(
          value: process,
          child: Text(process, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedEquipmentProcess = newValue;
          showManualEquipmentProcess = newValue == 'Other (Manual Entry)';
          if (!showManualEquipmentProcess) _equipmentProcessController.clear();
          _errorMessage = null;
        });
      },
    );
  }

  Widget _workOrderDropdown() {
    return DropdownSearch<String>.multiSelection(
      items: (filter, loadProps) => fetchedWork,
      filterFn: (workOrder, filter) =>
          workOrder.toLowerCase().contains(filter.toLowerCase()),
      itemAsString: (workOrder) => workOrder,
      compareFn: (a, b) => a == b,
      selectedItems: selectedWork ?? [],
      popupProps: PopupPropsMultiSelection.menu(
        containerBuilder: (context, popupWidget) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A4A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: popupWidget,
        ),
        fit: FlexFit.loose,
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          style: const TextStyle(fontSize: 14.0, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            fillColor: const Color(0xFF1A2A4A),
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
            ),
          ),
        ),
        scrollbarProps: const ScrollbarProps(thumbVisibility: true),
        searchDelay: Duration.zero,
        itemBuilder: (context, workOrder, isDisabled, isSelected) {
          final idx = selectedWork?.indexWhere((w) => w == workOrder) ?? -1;
          return ListTile(
            leading: Text(idx == -1 ? '' : '${idx + 1}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 14.0)),
            title: Text(workOrder,
                style: TextStyle(fontSize: 14.0, color: isSelected ? Colors.black : Colors.white)),
            selected: isSelected,
            selectedTileColor: const Color.fromARGB(255, 9, 218, 255),
          );
        },
        showSelectedItems: true,
        onItemAdded: (selectedItems, _) => setState(() {
          selectedWork = selectedItems;
          _errorMessage = null;
        }),
        onItemRemoved: (selectedItems, _) => setState(() {
          selectedWork = selectedItems;
          _errorMessage = null;
        }),
      ),
      dropdownBuilder: (context, selectedItems) =>
          Text(selectedItems.isNotEmpty ? selectedItems.join(', ') : '',
              style: const TextStyle(color: Colors.white)),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'Work Order',
          labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              letterSpacing: 0.8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
