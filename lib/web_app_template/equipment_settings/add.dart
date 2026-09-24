import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class AddEquipmentDialog extends StatefulWidget {
  final VoidCallback onEquipmentAdded;
  final String userRole;
  final String userId;
  final String factoryId;

  const AddEquipmentDialog({
    super.key,
    required this.onEquipmentAdded,
    required this.userRole,
    required this.userId,
    this.factoryId = '',
  });

  @override
  _AddEquipmentDialogState createState() => _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends State<AddEquipmentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _modelTypeController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _warrantyDateController = TextEditingController();
  final TextEditingController _picController = TextEditingController();
  final TextEditingController _equipmentProcessController = TextEditingController();
  final TextEditingController _equipmentCategoryController = TextEditingController();
  final TextEditingController _productionAreaController = TextEditingController();
  final TextEditingController _factoryController = TextEditingController();

  List<String> fetchedWork = [];
  List<String>? selectedWork;
  List<Map<String, dynamic>> fetchedProcesses = [];
  
  List<dynamic> fetchedDeviceTypes = [];
  String? selectedDeviceType;
  
  List<dynamic> fetchedProductionLines = [];
  String? selectedProductionLine;
  List<dynamic> fetchedFactories = [];
  String? selectedFactory;

  bool enableOEE = false;
  bool enableEnergy = false;

  List<FacilityData> fetchedFacilities = [];
  String? selectedDpmId;

  final TextEditingController _targetKwhController = TextEditingController(text: '0');
  final TextEditingController _warningPctController = TextEditingController(text: '0');
  final TextEditingController _criticalPctController = TextEditingController(text: '0');
  final TextEditingController _rateController = TextEditingController(text: '0');
  final TextEditingController _currencyController = TextEditingController(text: 'RM');

  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];

  String? selectedEquipmentProcess;
  bool showManualEquipmentProcess = false;

  String? _errorMessage;
  String? _serialNoError;

  final RegExp serialNoRegex = RegExp(r'^#\d{5}$');

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
    fetchWork();
    fetchProcesses();
    fetchProductionLines();
    fetchFactories();
    fetchFacilities();
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

  Future<void> fetchProcesses() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/process'),
        headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          fetchedProcesses = data
              .where((e) => (e['name']?.toString() ?? '').isNotEmpty)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
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

  Future<void> fetchDeviceTypes({String? factoryId}) async {
    final fid = (factoryId ?? selectedFactory ?? widget.factoryId).trim();
    if (fid.isEmpty) return;
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/equipmentCategory?factory_id=$fid";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => fetchedDeviceTypes = data.where((e) => e['device_type'] != null && e['device_type'].toString().isNotEmpty).toList());
      }
    } catch (_) {}
  }

  Future<void> fetchProductionLines() async {
    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/productionLines";
      final response = await http.get(Uri.parse(apiUrl), headers: AppConfig.headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          fetchedProductionLines = data.where((e) => e['name'] != null && e['name'].toString().isNotEmpty).toList();
        });
        return;
      }
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> _pickAndValidateImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (pickedFile != null) {
        String fileName = pickedFile.name.toLowerCase();
        String? fileExtension = fileName.split('.').last;
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

  Future<String?> _uploadImageToFirebase(String equipmentId) async {
    if (_imageBytes == null) return null;
    try {
      String contentType = 'image/jpeg';
      String fileExtension = 'jpg';
      if (_imageExtension == 'png') {
        contentType = 'image/png';
        fileExtension = 'png';
      }
      String fileName = 'equipment_$equipmentId.$fileExtension';
      final storageRef =
          FirebaseStorage.instance.ref().child('equipment_images/${widget.userId}/$fileName');
      final uploadTask = storageRef.putData(_imageBytes!, SettableMetadata(contentType: contentType));
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timeout - please check your connection'),
      );
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      setState(() => _errorMessage = 'Firebase error: ${e.message}');
      return null;
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
        List<String> workOrderIdList = [];
        for (dynamic workOrder in workOrders) {
          workOrderIdList.add(workOrder['id']?.toString() ?? '');
        }
        setState(() {
          fetchedWork = workOrderIdList;
        });
      } else {
        throw Exception("Failed to fetch work orders: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error fetching work orders: $e');
    }
  }

String? getEquipmentProcessValue() {
    if (showManualEquipmentProcess && _equipmentProcessController.text.isNotEmpty) {
      return _equipmentProcessController.text;
    } else if (selectedEquipmentProcess != null && selectedEquipmentProcess != 'Other (Manual Entry)') {
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
        _idController.text.isEmpty ||
        _serialNoController.text.isEmpty ||
        _modelTypeController.text.isEmpty ||
        _purchaseDateController.text.isEmpty ||
        _warrantyDateController.text.isEmpty ||
        _picController.text.isEmpty ||
        selectedDeviceType == null ||
        selectedProductionLine == null ||
        (showManualEquipmentProcess && _equipmentProcessController.text.isEmpty)) {
      setState(() => _errorMessage = 'All fields are required.');
      return false;
    }

    if (!serialNoRegex.hasMatch(_serialNoController.text)) {
      setState(() => _serialNoError = 'Please enter a valid serial no. (e.g. #12345)');
      return false;
    }

    try {
      final String apiUrl = "${AppConfig.dataApiBaseSafe}/equipment/add";
      String purchaseDateISO = DateTime.parse(_purchaseDateController.text).toIso8601String();
      String warrantyDateISO = DateTime.parse(_warrantyDateController.text).toIso8601String();

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
        "userId": widget.userId,
        "name": _nameController.text.trim(),
        "equipment_id": _idController.text.trim(),
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
        "workOrder": selectedWork ?? [],
        'product': '0',
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: AppConfig.headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        String equipmentId = responseBody['id'];

        if (_imageBytes != null) {
          setState(() => _isUploadingImage = true);
          final uploadedImageUrl = await _uploadImageToFirebase(equipmentId);
          setState(() => _isUploadingImage = false);

          if (uploadedImageUrl != null) {
            await http.put(
              Uri.parse("${AppConfig.dataApiBaseSafe}/equipment/$equipmentId/image"),
              headers: AppConfig.headers,
              body: json.encode({"userId": widget.userId, "imageUrl": uploadedImageUrl}),
            );
          }
        }

        if (enableEnergy && (selectedDpmId ?? '').isNotEmpty) {
          try {
            final linkedFacility = fetchedFacilities.firstWhere(
              (f) => f.meterId == selectedDpmId,
              orElse: () => const FacilityData(
                plant: '', factory: '', zone: '', productionArea: '',
                equipmentType: '', equipmentNameId: '', meterName: '',
                meterId: '', gatewayId: '', status: '', gridType: '',
                maintenanceDate: '', lastMaintenanceDate: '',
                nextMaintenanceDate: '', registrationDate: '',
              ),
            );
            if (linkedFacility.id != null) {
              await FacilityService.patchFacility(linkedFacility.id!, {
                'equipmentNameId':
                    '${_nameController.text.trim()} (${_idController.text.trim()})',
              });
            }
          } catch (_) {}
        }

        try {
          CollectionReference workOrderCollection = FirebaseFirestore.instance.collection('workOrders');
          if (selectedWork != null && selectedWork!.isNotEmpty) {
            for (String work in selectedWork!) {
              await workOrderCollection.doc(work).update({'equipment': equipmentId});
            }
          }
        } catch (_) {}

        widget.onEquipmentAdded();
        return true;
      } else if (response.statusCode == 400) {
        throw Exception(json.decode(response.body)['error']);
      } else {
        throw Exception("Failed to add equipment: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _serialNoError = e.toString().replaceFirst('Exception:', '').trim());
      return false;
    }
  }

  Widget _row2(Widget left, Widget right) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.precision_manufacturing_outlined,
      title: 'Add New Equipment',
      subtitle: 'Register a new equipment entry to the system.',
      requiredNote: true,
      submitLabel: 'SUBMIT',
      sections: [
        // ── 1. Equipment Image ────────────────────────────────────────────────
        CustomDialogSection(
          number: 1,
          title: 'Equipment Image',
          subtitle: 'Upload an optional photo of the equipment (JPG/PNG, max 5MB).',
          children: [
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndValidateImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: _imageBytes != null
                      ? Colors.transparent
                      : const Color(0xFF31ECFC).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _imageBytes != null
                        ? const Color(0xFF31ECFC).withOpacity(0.4)
                        : const Color(0xFF31ECFC).withOpacity(0.18),
                    width: 1.5,
                  ),
                ),
                child: _isUploadingImage
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF31ECFC), strokeWidth: 2))
                    : _imageBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(_imageBytes!,
                                    fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.edit_outlined,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF31ECFC).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_upload_outlined,
                                    size: 22,
                                    color: Color(0xFF31ECFC)),
                              ),
                              const SizedBox(height: 10),
                              Text('Click to upload image',
                                  style: TextStyle(
                                      color: const Color(0xFF31ECFC).withOpacity(0.85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 3),
                              Text('JPG or PNG, max 5MB',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 11)),
                            ],
                          ),
              ),
            ),
          ],
        ),

        // ── 2. Classification ─────────────────────────────────────────────────
        CustomDialogSection(
          number: 2,
          title: 'Classification',
          subtitle: 'Select equipment type and category.',
          children: [
            _row2(
              _dropdownField(
                label: 'Equipment Type *',
                value: selectedDeviceType,
                icon: Icons.category_outlined,
                items: fetchedDeviceTypes.map((e) => {
                  'id': e['device_type']?.toString() ?? '',
                  'name': e['device_type']?.toString() ?? '',
                  'relatedInfo': e['equipment_category']?.toString() ?? '',
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedDeviceType = v;
                    final selected = fetchedDeviceTypes.firstWhere(
                        (e) => e['device_type'] == v, orElse: () => null);
                    if (selected != null) {
                      _equipmentCategoryController.text =
                          selected['equipment_category'] ?? '';
                    }
                  });
                },
              ),
              _inputField(
                label: 'Equipment Category (Auto)',
                controller: _equipmentCategoryController,
                readOnly: true,
                icon: Icons.auto_awesome_outlined,
              ),
            ),
          ],
        ),

        // ── 3. Basic Information ──────────────────────────────────────────────
        CustomDialogSection(
          number: 3,
          title: 'Basic Information',
          subtitle: 'Equipment ID, name, serial number, model type and PIC.',
          children: [
            _row2(
              _inputField(
                  label: 'Equipment ID',
                  controller: _idController,
                  isRequired: true,
                  icon: Icons.qr_code_outlined),
              _inputField(
                  label: 'Equipment Name',
                  controller: _nameController,
                  isRequired: true,
                  icon: Icons.label_outline),
            ),
            const SizedBox(height: 16),
            _row2(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField(
                    label: 'Serial No.',
                    controller: _serialNoController,
                    isRequired: true,
                    hint: '#12345',
                    icon: Icons.numbers_outlined,
                  ),
                  if (_serialNoError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, left: 2),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 12, color: Color(0xFFE74852)),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(_serialNoError!,
                                style: const TextStyle(
                                    color: Color(0xFFE74852), fontSize: 11))),
                      ]),
                    ),
                ],
              ),
              _inputField(
                  label: 'Model Type',
                  controller: _modelTypeController,
                  isRequired: true,
                  icon: Icons.devices_outlined),
            ),
            const SizedBox(height: 16),
            _inputField(
                label: 'PIC',
                controller: _picController,
                isRequired: true,
                icon: Icons.person_outline),
          ],
        ),

        // ── 4. Equipment Parent Info ─────────────────────────────────────────
        CustomDialogSection(
          number: 4,
          title: 'Equipment Parent Info',
          subtitle: 'Production line, area, plant, client and dates.',
          children: [
            _row2(
              _dropdownField(
                key: ValueKey('pl_${fetchedProductionLines.length}'),
                label: 'Production Line *',
                value: selectedProductionLine,
                icon: Icons.linear_scale_outlined,
                items: fetchedProductionLines.map((e) => {
                  'id': e['name']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedProductionLine = v;
                    final found = fetchedProductionLines.cast<Map<String,dynamic>>().firstWhere(
                        (e) => e['name'] == v, orElse: () => {});
                    _productionAreaController.text = found['productionArea'] ?? '';
                    _factoryController.text = found['factory_id'] ?? '';
                    selectedFactory = found['factory_id']?.toString();
                  });
                  if ((selectedFactory ?? '').isNotEmpty) fetchDeviceTypes(factoryId: selectedFactory);
                },
              ),
              _inputField(
                  label: 'Production Area (Auto)',
                  controller: _productionAreaController,
                  readOnly: true,
                  icon: Icons.auto_awesome_outlined),
            ),
            const SizedBox(height: 16),
            _row2(
              _dropdownField(
                label: 'Plant *',
                value: selectedFactory,
                icon: Icons.factory_outlined,
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
                  if (v != null && v.isNotEmpty) fetchDeviceTypes(factoryId: v);
                },
              ),
              _inputField(
                  label: 'Client (Auto)',
                  controller: TextEditingController(text: AppConfig.clientName),
                  readOnly: true,
                  icon: Icons.business_outlined),
            ),
            const SizedBox(height: 16),
            _equipmentProcessDropdown(),
            if (showManualEquipmentProcess) ...[
              const SizedBox(height: 16),
              _inputField(
                  label: 'Enter Equipment Process',
                  controller: _equipmentProcessController,
                  isRequired: true,
                  icon: Icons.settings_outlined),
            ],
            const SizedBox(height: 16),
            _row2(
              _dateField(
                  controller: _purchaseDateController,
                  label: 'Purchase Date',
                  isRequired: true),
              _dateField(
                  controller: _warrantyDateController,
                  label: 'Warranty Expiry Date',
                  isRequired: true),
            ),
          ],
        ),

        // ── 5. Modules ────────────────────────────────────────────────────────
        CustomDialogSection(
          number: 5,
          title: 'Modules',
          subtitle: 'Enable or disable OEE and Energy modules.',
          children: [
            _switchField(
              label: 'Enable OEE Module',
              icon: Icons.speed_outlined,
              value: enableOEE,
              onChanged: (v) => setState(() => enableOEE = v),
            ),
            const SizedBox(height: 10),
            _switchField(
              label: 'Enable Energy Module',
              icon: Icons.bolt_outlined,
              value: enableEnergy,
              onChanged: (v) => setState(() => enableEnergy = v),
            ),
            if (enableEnergy) ...[
              const SizedBox(height: 16),
              _energyThresholdFields(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFE74852)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: Color(0xFFE74852), fontSize: 12))),
              ]),
            ],
          ],
        ),
      ],
      onSubmit: _submitForm,
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool readOnly = false,
    String? hint,
    IconData? icon,
  }) {
    const cyan = Color(0xFF31ECFC);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
          color: readOnly ? Colors.white.withOpacity(0.45) : Colors.white,
          fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
        labelStyle: TextStyle(
            color: Colors.white.withOpacity(readOnly ? 0.4 : 0.65),
            fontSize: 11,
            letterSpacing: 0.7),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(icon,
                    size: 16,
                    color: readOnly
                        ? Colors.white.withOpacity(0.25)
                        : cyan.withOpacity(0.55)),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: readOnly
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(readOnly ? 0.06 : 0.1),
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    const cyan = Color(0xFF31ECFC);
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.65), fontSize: 11, letterSpacing: 0.7),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(Icons.calendar_today_outlined,
              size: 16, color: cyan.withOpacity(0.55)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = picked.toLocal().toString().split(' ')[0];
        }
      },
    );
  }

  Widget _dropdownField({
    Key? key,
    required String label,
    required String? value,
    required List<dynamic> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
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
    final isValidValue = uniqueItems.any((item) => item['id'] == value);
    return DropdownSearch<Map<String, dynamic>>(
      key: key,
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
              color: Colors.white.withOpacity(0.65), fontSize: 11, letterSpacing: 0.7),
          prefixIcon: icon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(icon,
                      size: 16,
                      color: const Color(0xFF31ECFC).withOpacity(0.55)),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _switchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    const cyan = Color(0xFF31ECFC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? cyan.withOpacity(0.06) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? cyan.withOpacity(0.25) : Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16,
                color: value ? cyan.withOpacity(0.8) : Colors.white.withOpacity(0.35)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: value ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: value ? FontWeight.w500 : FontWeight.normal)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cyan,
            activeTrackColor: cyan.withOpacity(0.3),
            inactiveThumbColor: Colors.white.withOpacity(0.4),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
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
            key: ValueKey('dpm_${fetchedFacilities.length}'),
            label: 'Device ID',
            value: selectedDpmId,
            icon: Icons.developer_board_outlined,
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
          _inputField(
            label: 'Target kWh / Tonne',
            controller: _targetKwhController,
            icon: Icons.speed_outlined,
          ),
          const SizedBox(height: 16),
          _row2(
            _inputField(label: 'Warning %', controller: _warningPctController, icon: Icons.warning_amber_outlined),
            _inputField(label: 'Critical %', controller: _criticalPctController, icon: Icons.error_outline),
          ),
          const SizedBox(height: 16),
          _row2(
            _inputField(label: 'Rate (\$/kWh)', controller: _rateController, icon: Icons.attach_money_outlined),
            _inputField(label: 'Currency', controller: _currencyController, icon: Icons.payments_outlined),
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
    final processNames = [
      ...fetchedProcesses.map((e) => e['name']?.toString() ?? '').where((n) => n.isNotEmpty),
      'Other (Manual Entry)',
    ];
    final isValidValue = processNames.contains(selectedEquipmentProcess);
    return DropdownSearch<String>(
      key: ValueKey('ep_${fetchedProcesses.length}'),
      items: (filter, _) => processNames
          .where((o) => o.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItem: isValidValue ? selectedEquipmentProcess : null,
      compareFn: (a, b) => a == b,
      itemAsString: (e) => e,
      onChanged: (newValue) {
        setState(() {
          selectedEquipmentProcess = newValue;
          showManualEquipmentProcess = newValue == 'Other (Manual Entry)';
          if (!showManualEquipmentProcess) _equipmentProcessController.clear();
          _errorMessage = null;
        });
      },
      popupProps: PopupProps.menu(
        fit: FlexFit.loose,
        showSearchBox: true,
        searchDelay: Duration.zero,
        searchFieldProps: TextFieldProps(
          style: const TextStyle(fontSize: 14.0, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search process...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            fillColor: const Color(0xFF1A2A4A),
            filled: true,
            border: OutlineInputBorder(borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary)),
          ),
        ),
        containerBuilder: (ctx, popupWidget) => Container(
          decoration: BoxDecoration(color: const Color(0xFF1A2A4A), borderRadius: BorderRadius.circular(10)),
          child: popupWidget,
        ),
        itemBuilder: (ctx, item, isDisabled, isSelected) => ListTile(
          title: Text(item, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 14)),
          selected: isSelected,
          selectedTileColor: const Color.fromARGB(255, 9, 218, 255),
        ),
      ),
      dropdownBuilder: (ctx, selected) => Text(selected ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'Equipment Process',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 0.8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _workOrderDropdown() {
    return DropdownSearch<String>.multiSelection(
      items: (filter, loadProps) => fetchedWork,
      filterFn: (workOrder, filter) => workOrder.toLowerCase().contains(filter.toLowerCase()),
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
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 0.8),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
