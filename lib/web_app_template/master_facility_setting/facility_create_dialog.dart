import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import 'facility_form_widgets.dart';
import 'facility_helpers.dart';
import 'cubit/facility_cubit.dart';
import '/components/dialogs/custom_dialog.dart';
import '../equipment_settings/add.dart';
import '../equipment_settings/addFactory.dart';
import '../equipment_settings/addProductionArea.dart';
import '../equipment_settings/addProductionLine.dart';

// ─────────────────────────────────────────────
// CREATE — Register New Device
// ─────────────────────────────────────────────

class FacilityCreateDialog extends StatelessWidget {
  final Future<void> Function(Map<String, dynamic>) onCreated;
  final String userRole;
  /// Already-registered meter IDs used for real-time duplicate detection.
  final Set<String> existingMeterIds;

  const FacilityCreateDialog({
    super.key,
    required this.onCreated,
    this.userRole = 'Admin',
    this.existingMeterIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FacilityCubit()..loadDropdowns(),
      child: _CreateForm(
        onCreated: onCreated,
        userRole: userRole,
        existingMeterIds: existingMeterIds,
      ),
    );
  }
}

class _CreateForm extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onCreated;
  final String userRole;
  final Set<String> existingMeterIds;
  const _CreateForm({
    required this.onCreated,
    required this.userRole,
    required this.existingMeterIds,
  });

  @override
  State<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends State<_CreateForm> {
  final _formKey        = GlobalKey<FormState>();
  final _meterNameCtrl  = TextEditingController();
  final _meterIdCtrl    = TextEditingController();
  final _gatewayIdCtrl  = TextEditingController();
  final _gridTypeCtrl   = TextEditingController();

  // Real-time duplicate warning for Meter ID field.
  bool _meterIdDuplicate = false;

  @override
  void initState() {
    super.initState();
    _meterIdCtrl.addListener(_checkMeterIdDuplicate);
  }

  void _checkMeterIdDuplicate() {
    final isDup = widget.existingMeterIds.contains(_meterIdCtrl.text.trim());
    if (isDup != _meterIdDuplicate) setState(() => _meterIdDuplicate = isDup);
  }

  @override
  void dispose() {
    _meterNameCtrl.dispose();
    _meterIdCtrl.dispose();
    _gatewayIdCtrl.dispose();
    _gridTypeCtrl.dispose();
    super.dispose();
  }

  // ── Navigation logic ──────────────────────────────────────────────────────
  void _goToAddEquipment() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AddEquipmentDialog(
        userRole: widget.userRole,
        onEquipmentAdded: () {},
        userId: AppStateNotifier.instance.uid ?? '',
      ),
    );
  }

  void _goToAddFactory() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AddFactoryDialog(
        onEquipmentAdded: () {},
        userRole: widget.userRole,
      ),
    );
  }

  void _goToAddProductionArea() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AddProductionAreaDialog(
        onEquipmentAdded: () {},
        userRole: widget.userRole,
      ),
    );
  }

  void _goToAddProductionLine() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => AddProductionLineDialog(
        onAdded: () {},
        userId: AppStateNotifier.instance.uid ?? '',
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<bool> _onSubmit() async {
    if (_meterIdDuplicate) return false;
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    await context.read<FacilityCubit>().submitCreate(
          meterName: _meterNameCtrl.text.trim(),
          meterId:   _meterIdCtrl.text.trim(),
          gatewayId: _gatewayIdCtrl.text.trim(),
          gridType:  _gridTypeCtrl.text.trim(),
          onCreated: widget.onCreated,
        );
    return false;
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
        // Display Name & Device ID are NOT auto-filled from the selected
        // equipment — they come from Device Discovery (stored to Firestore
        // when a new device is first discovered). On a manual Add they stay
        // empty for the user to type.
      },
      builder: (context, state) {
        if (state is FacilityInitial ||
            state is FacilityDropdownsLoading ||
            state is FacilitySubmitting) {
          return facilityLoadingView(context);
        }
        if (state is FacilityDropdownsError) {
          return facilityErrorView(
            context,
            message: state.message,
            onRetry: () => context.read<FacilityCubit>().retry(),
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
      formKey: _formKey,
      icon: Icons.add_circle_outline,
      title: 'Register New Device',
      subtitle: 'Add a new facility equipment to the system',
      requiredNote: true,
      submitLabel: 'SUBMIT',
      cancelLabel: 'CANCEL',
      onSubmit: _onSubmit,
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Basic Information',
          subtitle: 'Select Site, Machine, Zone and Line from your factory settings.',
          children: [
            facilityRow2(
              facilityDropdownField(
                context,
                label: 'Site / Plant',
                items: s.factories,
                selectedId: s.selectedPlantId,
                isRequired: true,
                emptyMessage: 'No sites found. Tap to add one.',
                onEmpty: _goToAddFactory,
                onChanged: cubit.selectPlant,
              ),
              facilityDropdownField(
                context,
                label: 'Machine / Factory',
                items: s.productionAreas,
                selectedId: s.selectedFactoryId,
                isRequired: true,
                emptyMessage: 'No machines found. Tap to add one.',
                onEmpty: _goToAddFactory,
                onChanged: cubit.selectFactory,
              ),
            ),
            const SizedBox(height: 18),
            facilityRow2(
              facilityDropdownField(
                context,
                label: 'Production Area',
                items: s.zones,
                selectedId: s.selectedProductionAreaId,
                isRequired: true,
                emptyMessage: 'No zones found. Tap to add one.',
                onEmpty: _goToAddProductionArea,
                onChanged: (id, name) => cubit.selectProductionArea(id, name),
              ),
              facilityDropdownField(
                context,
                label: 'Production Line',
                items: s.productionLines,
                selectedId: s.selectedProductionLineId,
                isRequired: true,
                emptyMessage: 'No lines found. Tap to add one.',
                onEmpty: _goToAddProductionLine,
                onChanged: cubit.selectProductionLine,
              ),
            ),
          ],
        ),
        CustomDialogSection(
          number: 2,
          title: 'Equipment Details',
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
                equipments: s.equipments,
                selected: s.selectedEquipment,
                onChanged: cubit.selectEquipment,
                onEmpty: _goToAddEquipment,
                isRequired: true,
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
          number: 3,
          title: 'Device & Gateway',
          subtitle: 'Configure display name, device ID and gateway.',
          children: [
            facilityRow2(
              facilityInputField(context,
                  label: 'Display Name',
                  controller: _meterNameCtrl,
                  isRequired: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  facilityInputField(context,
                      label: 'Device ID',
                      controller: _meterIdCtrl,
                      isRequired: true),
                  if (_meterIdDuplicate)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 13, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'This Device ID is already registered in the system.',
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            facilityInputField(context,
                label: 'Gateway ID',
                controller: _gatewayIdCtrl,
                isRequired: true),
          ],
        ),
        CustomDialogSection(
          number: 4,
          title: 'Maintenance & Registration Dates',
          subtitle: 'Set maintenance schedule and registration date.',
          children: [
            facilityRow2(
              facilityDateField(context,
                  label: 'Maintenance Date',
                  value: s.maintenanceDate,
                  isRequired: true,
                  onPicked: (d) => cubit.setDate('maintenance', d)),
              facilityDateField(context,
                  label: 'Last Maintenance Date',
                  value: s.lastMaintenanceDate,
                  isRequired: true,
                  onPicked: (d) => cubit.setDate('lastMaintenance', d)),
            ),
            const SizedBox(height: 18),
            facilityRow2(
              facilityDateField(context,
                  label: 'Next Maintenance Date',
                  value: s.nextMaintenanceDate,
                  isRequired: true,
                  onPicked: (d) => cubit.setDate('nextMaintenance', d)),
              facilityDateField(context,
                  label: 'Registration Date',
                  value: s.registrationDate,
                  isRequired: true,
                  onPicked: (d) => cubit.setDate('registration', d)),
            ),
          ],
        ),
      ],
    );
  }
}
