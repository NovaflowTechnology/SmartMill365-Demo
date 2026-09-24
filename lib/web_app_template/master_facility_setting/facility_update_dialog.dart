import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'facility_form_widgets.dart';
import 'facility_helpers.dart';
import 'cubit/facility_cubit.dart';
import '/components/dialogs/custom_dialog.dart';
import '../equipment_settings/addFactory.dart';
import '../equipment_settings/addProductionArea.dart';
import '../equipment_settings/addProductionLine.dart';

// ─────────────────────────────────────────────
// UPDATE — Edit Facility (Full Screen)
// ─────────────────────────────────────────────

class FacilityUpdateDialog extends StatelessWidget {
  final Map<String, dynamic> initialData;
  final Future<void> Function() onUpdated;

  const FacilityUpdateDialog({
    super.key,
    required this.initialData,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Same Cubit — initialData pre-fills selections
      create: (_) => FacilityCubit()..loadDropdowns(initialData: initialData),
      child: _UpdateForm(initialData: initialData, onUpdated: onUpdated),
    );
  }
}

class _UpdateForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Future<void> Function() onUpdated;
  const _UpdateForm({required this.initialData, required this.onUpdated});

  @override
  State<_UpdateForm> createState() => _UpdateFormState();
}

class _UpdateFormState extends State<_UpdateForm> {
  final _formKey       = GlobalKey<FormState>();
  late final TextEditingController _meterNameCtrl;
  late final TextEditingController _meterIdCtrl;
  late final TextEditingController _gatewayIdCtrl;
  late final TextEditingController _gridTypeCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    // Display Name & Device ID show the already-saved values (which came from
    // Device Discovery) and are NOT auto-overwritten when the user changes
    // the equipment selection.
    _meterNameCtrl = TextEditingController(text: d['meterName'] ?? '');
    _meterIdCtrl   = TextEditingController(text: d['meterId']   ?? '');
    _gatewayIdCtrl = TextEditingController(text: d['gatewayId'] ?? '');
    _gridTypeCtrl  = TextEditingController(text: d['gridType']  ?? '');
  }

  @override
  void dispose() {
    _meterNameCtrl.dispose();
    _meterIdCtrl.dispose();
    _gatewayIdCtrl.dispose();
    _gridTypeCtrl.dispose();
    super.dispose();
  }

  // ── Navigation logic ───────────────────────────────────────────────────────────────
  void _goToAddEquipment() => Navigator.of(context).pop();
  void _goToAddFactory()   => Navigator.of(context).pop();
  void _goToAddProductionArea() => Navigator.of(context).pop();
  void _goToAddProductionLine() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AddProductionLineDialog(
        onAdded: () {},
        userId: '',
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<bool> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    await context.read<FacilityCubit>().submitUpdate(
      meterName:   _meterNameCtrl.text.trim(),
      meterId:     _meterIdCtrl.text.trim(),
      gatewayId:   _gatewayIdCtrl.text.trim(),
      gridType:    _gridTypeCtrl.text.trim(),
      initialData: widget.initialData,
      onUpdated:   widget.onUpdated,
    );
    return false; // pop handled by BlocListener on FacilitySubmitSuccess
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FacilityCubit, FacilityState>(
      listener: (context, state) {
        if (state is FacilitySubmitSuccess) Navigator.of(context).pop();
        if (state is FacilitySubmitError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        // Display Name & Device ID keep their saved (Device Discovery) values
        // and are NOT auto-overwritten when the equipment selection changes.
      },
      builder: (context, state) {
        if (state is FacilityInitial || state is FacilityDropdownsLoading ||
            state is FacilitySubmitting) {
          return facilityLoadingView(context);
        }
        if (state is FacilityDropdownsError) {
          return facilityErrorView(context,
            message:  state.message,
            onRetry:  () => context.read<FacilityCubit>()
                .retry(initialData: widget.initialData),
            onCancel: () => Navigator.of(context).pop(),
          );
        }
        if (state is FacilityDropdownsLoaded) return _buildForm(context, state);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildForm(BuildContext context, FacilityDropdownsLoaded s) {
    final cubit = context.read<FacilityCubit>();
    return CustomDialog(
      formKey:      _formKey,
      icon:         Icons.edit_outlined,
      title:        'Edit Facility',
      subtitle:     'Editing: ${widget.initialData['equipmentNameId'] ?? '-'}',
      requiredNote: true,
      submitLabel:  'SAVE CHANGES',
      cancelLabel:  'CANCEL',
      onSubmit:     _onSubmit,
      sections: [
        CustomDialogSection(
          number: 1, title: 'Basic Information',
          subtitle: 'Select Plant and Production Line from your factory settings.',
          children: [
            facilityRow2(
              facilityDropdownField(context,
                label: 'Site / Plant', items: s.factories,
                selectedId: s.selectedPlantId, isRequired: true,
                emptyMessage: 'No plants found. Tap to add one.',
                onEmpty: _goToAddFactory,
                onChanged: cubit.selectPlant,
              ),
              facilityDropdownField(context,
                label: 'Machine / Factory', items: s.productionAreas,
                selectedId: s.selectedFactoryId, isRequired: true,
                emptyMessage: 'No factories found. Tap to add one.',
                onEmpty: _goToAddFactory,
                onChanged: cubit.selectFactory,
              ),
            ),
            const SizedBox(height: 18),
            facilityRow2(
              facilityDropdownField(context,
                label: 'Production Area', items: s.zones,
                selectedId: s.selectedProductionAreaId, isRequired: true,
                emptyMessage: 'No zones found. Tap to add one.',
                onEmpty: _goToAddProductionArea,
                onChanged: (id, name) => cubit.selectProductionArea(id, name),
              ),
              facilityDropdownField(context,
                label: 'Production Line', items: s.productionLines,
                selectedId: s.selectedProductionLineId, isRequired: true,
                emptyMessage: 'No production lines found. Tap to add one.',
                onEmpty: _goToAddProductionLine,
                onChanged: cubit.selectProductionLine,
              ),
            ),
          ],
        ),
        CustomDialogSection(
          number: 2, title: 'Equipment Details',
          subtitle: 'Choose a machine and select device type.',
          children: [
            // Equipment ID — selecting it auto-syncs Site/Plant, Zone, Line and
            // Device Type from that equipment (all stay editable).
            facilityDropdownField(
              context,
              label: 'Equipment ID',
              items: [
                for (final e in s.equipments)
                  if (e.equipmentId.isNotEmpty) {'id': e.equipmentId, 'name': e.displayLabel},
              ],
              selectedId: s.selectedEquipment?.equipmentId,
              onChanged: (id, name) => cubit.selectEquipmentById(id),
            ),
            const SizedBox(height: 18),
            facilityRow2(
              FacilityEquipmentPicker(
                equipments: s.equipments, selected: s.selectedEquipment,
                onChanged: cubit.selectEquipment, onEmpty: _goToAddEquipment,
              ),
              facilityDeviceTypeDropdown(
                context,
                deviceTypes: s.deviceTypes,
                selectedName: s.selectedDeviceType,
                onChanged: (name) => cubit.selectDeviceType(name),
              ),
            ),
            const SizedBox(height: 18),
            facilityRow2(
              facilityInputField(context,
                  label: 'Grid Type', controller: _gridTypeCtrl),
              facilityStatusToggle(context, s.status,
                  (v) => cubit.setStatus(v ? 'Active' : 'Inactive')),
            ),
            const SizedBox(height: 18),
            facilityImpactCategoryDropdown(
              context,
              selected: s.impactCategory,
              onChanged: cubit.setImpactCategory,
            ),
          ],
        ),
        CustomDialogSection(
          number: 3, title: 'Meter & Gateway',
          subtitle: 'Meter and gateway identifiers.',
          children: [
            facilityRow2(
              facilityInputField(context,
                  label: 'Display Name', controller: _meterNameCtrl, isRequired: true),
              facilityInputField(context,
                  label: 'Device ID', controller: _meterIdCtrl, isRequired: true),
            ),
            const SizedBox(height: 18),
            facilityInputField(context,
                label: 'Gateway ID', controller: _gatewayIdCtrl, isRequired: true),
          ],
        ),
        CustomDialogSection(
          number: 4, title: 'Maintenance & Registration Dates',
          subtitle: 'Maintenance schedule and registration date.',
          children: [
            facilityRow2(
              facilityDateField(context,
                  label: 'Maintenance Date', value: s.maintenanceDate,
                  isRequired: true, onPicked: (d) => cubit.setDate('maintenance', d)),
              facilityDateField(context,
                  label: 'Last Maintenance Date', value: s.lastMaintenanceDate,
                  isRequired: true, onPicked: (d) => cubit.setDate('lastMaintenance', d)),
            ),
            const SizedBox(height: 18),
            facilityRow2(
              facilityDateField(context,
                  label: 'Next Maintenance Date', value: s.nextMaintenanceDate,
                  isRequired: true, onPicked: (d) => cubit.setDate('nextMaintenance', d)),
              facilityDateField(context,
                  label: 'Registration Date', value: s.registrationDate,
                  isRequired: true, onPicked: (d) => cubit.setDate('registration', d)),
            ),
          ],
        ),
      ],
    );
  }
}