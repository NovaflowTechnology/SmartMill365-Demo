import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/device_settings/firestore_service.dart';

class EditDeviceDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String id;
  final String initialName;
  final String initialEquipment;
  final String initialProductionArea;
  final String initialFactory;
  final VoidCallback onDeviceAdded;

  const EditDeviceDialog({
    super.key,
    required this.id,
    required this.initialName,
    required this.initialEquipment,
    required this.initialProductionArea,
    required this.initialFactory,
    required this.firestoreService,
    required this.onDeviceAdded,
  });

  @override
  _EditDeviceDialogState createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<EditDeviceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _errorMessage;
  List<dynamic> fetchedEquipments = [];
  String? selectedEquipment;
  List<dynamic> fetchedProductionArea = [];
  String? selectedProductionArea;
  List<dynamic> fetchedFactory = [];
  String? selectedFactory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    fetchEquipment();
    fetchProductionArea();
    fetchFactory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> fetchEquipment() async {
    try {
      final dynamic fetchedEquipmentsData = await widget.firestoreService.fetchEquipments();
      setState(() {
        fetchedEquipments = fetchedEquipmentsData;
        selectedEquipment = fetchedEquipments.isNotEmpty ? widget.initialEquipment : "0";
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching equipments: $e';
      });
    }
  }

  Future<void> fetchProductionArea() async {
    try {
      final dynamic fetchedProductionAreasData = await widget.firestoreService.fetchProductionArea();
      setState(() {
        fetchedProductionArea = fetchedProductionAreasData;
        selectedProductionArea = fetchedProductionArea.isNotEmpty ? widget.initialProductionArea : "0";
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching production area: $e';
      });
    }
  }

  Future<void> fetchFactory() async {
    try {
      final dynamic fetchedFactoryData = await widget.firestoreService.fetchFactory();
      setState(() {
        fetchedFactory = fetchedFactoryData;
        selectedFactory = fetchedFactory.isNotEmpty ? widget.initialFactory : "0";
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching factory: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit User Details',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
      content: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.4,
          minHeight: MediaQuery.of(context).size.height * 0.2,
          maxWidth: MediaQuery.of(context).size.width * 0.4,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildTextField(_nameController, 'Device Name'),
                const SizedBox(height: 20),
                buildDropdownField(
                  value: selectedEquipment,
                  items: [
                    {'id': '0', 'name': 'Not Assigned'},
                    ...fetchedEquipments,
                  ],
                  labelText: 'Equipment',
                  onChanged: (String? newEquipment) {
                    setState(() {
                      selectedEquipment = newEquipment;
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                buildDropdownField(
                  value: selectedProductionArea,
                  items: [
                    {'id': '0', 'name': 'Not Assigned'},
                    ...fetchedProductionArea,
                  ],
                  labelText: 'Production Area',
                  onChanged: (String? newEquipment) {
                    setState(() {
                      selectedProductionArea = newEquipment;
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                buildDropdownField(
                  value: selectedFactory,
                  items: [
                    {'id': '0', 'name': 'Not Assigned'},
                    ...fetchedFactory,
                  ],
                  labelText: 'Factory',
                  onChanged: (String? newEquipment) {
                    setState(() {
                      selectedFactory = newEquipment;
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (_errorMessage != null)
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 7),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            setState(() {
              _errorMessage = null;
            });

            if (_formKey.currentState!.validate()) {
              if (_nameController.text.isEmpty || selectedEquipment == null || selectedEquipment == null || selectedEquipment == null) {
                setState(() {
                  _errorMessage = 'All fields are required.';
                });
              } else {
                try {
                  await widget.firestoreService.editDevice(
                    widget.id,
                    _nameController.text,
                    selectedEquipment!,
                    selectedProductionArea!,
                    selectedFactory!,
                  );
                  widget.onDeviceAdded();
                  Navigator.of(context).pop();
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Error editing device: $e';
                  });
                }
              }
            }
          },
          child: const Text('Submit'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget buildTextField(TextEditingController controller, String labelText,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
    );
  }

  Widget buildDropdownField({
    required String? value,
    required List<dynamic> items,
    required String labelText,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = items.toSet().toList();

    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: value,
        items: uniqueItems.map((dynamic equipment) {
          return DropdownMenuItem<String>(
            value: equipment['id'],
            child: Text(equipment['name']),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
        ),
      ),
    );
  }
}
