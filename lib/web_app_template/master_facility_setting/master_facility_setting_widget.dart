import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import './cubit/facility_list_cubit.dart';
import 'facility_create_dialog.dart';
import 'facility_update_dialog.dart';
import 'facility_delete.dart';
import 'services/facility_service.dart';
import 'package:smartmachine365/web_app_template/power_factor_monitoring/stat_card_wdiget.dart';

// Neon accents shared with the Power Factor Monitoring KPI row, for a
// consistent cyberpunk look across dashboard stat cards.
const _kCyan = Color(0xFF00C6FF);
const _kGreen = Color(0xFF22C55E);
const _kBlue = Color(0xFF3B82F6);
const _kRed = Color(0xFFEF4444);

class MasterFacilitySettingWidget extends StatelessWidget {
  final String userRole;
  final String factoryId;

  const MasterFacilitySettingWidget({
    super.key,
    this.userRole = '',
    this.factoryId = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FacilityListCubit(userRole: userRole, factoryId: factoryId)
        ..loadFacilities(),
      child: const _FacilityListView(),
    );
  }
}

class _FacilityListView extends StatefulWidget {
  const _FacilityListView();

  @override
  State<_FacilityListView> createState() => _FacilityListViewState();
}

class _FacilityListViewState extends State<_FacilityListView> {
  List<Map<String, dynamic>> _deviceTypes = [];

  @override
  void initState() {
    super.initState();
    FacilityService.getDeviceTypes().then((list) {
      if (mounted) setState(() => _deviceTypes = list);
    }).catchError((_) {});
  }

  // ── column definitions ─────────────────────────────────────────────────────
  static const List<TableColumn> _columnsMain = [
    TableColumn('Display Name', 'meterName', 130),
    TableColumn('Device Type', 'equipmentType', 120),
    TableColumn('Device ID', 'meterId', 100),
    // Analytics inclusion — kept up front (right after the identity columns)
    // so the checkboxes are visible without horizontal scrolling.
    TableColumn('PF', 'includePfAnalytics', 56),
    TableColumn('MD', 'includeMdRanking', 56),
    TableColumn('Carbon', 'includeCarbonCalc', 70),
    TableColumn('Gateway ID', 'gatewayId', 100),
    TableColumn('Grid Type', 'gridType', 90),
    TableColumn('Client Name', 'clientName', 130),
    TableColumn('Client ID', 'clientId', 120),
    // Equipment the device (e.g. DPM001 → renamed "Cast 15-DPM") is linked to,
    // set via the dialog's Equipment ID field — auto-synced with the device.
    TableColumn('Equipment ID', 'equipmentNameId', 160),
    TableColumn('Site / Plant', 'plant', 120),
    TableColumn('Machine / Factory', 'factory', 130),
    TableColumn('Production Area', 'zone', 120),
    TableColumn('Production Line', 'productionArea', 140),
    TableColumn('Status', 'status', 90),
    TableColumn('MD Insight', 'insight', 90),
  ];

  static const List<TableColumn> _columnsMysql = [
    TableColumn('Display Name', 'meterName', 130),
    TableColumn('Device ID', 'meterId', 110),
    TableColumn('Site ID', 'siteId', 90),
    TableColumn('Machine ID', 'machineId', 100),
    TableColumn('Machine Name', 'machineName', 130),
    TableColumn('Line ID', 'lineId', 90),
    TableColumn('Line Name', 'lineName', 120),
    TableColumn('Zone ID', 'zoneId', 90),
    TableColumn('Zone Name', 'zoneName', 130),
    TableColumn('Parent ID', 'parentId', 100),
    TableColumn('Parent Name', 'parentName', 130),
    TableColumn('Status', 'status', 90),
  ];

  static const List<TableColumn> _columnsDates = [
    TableColumn('Equipment Name / ID', 'equipmentNameId', 200, sortable: true),
    TableColumn('Maintenance Date', 'maintenanceDate', 160),
    TableColumn('Last Maintenance', 'lastMaintenanceDate', 160),
    TableColumn('Next Maintenance', 'nextMaintenanceDate', 160),
    TableColumn('Registration Date', 'registrationDate', 160),
    TableColumn('Status', 'status', 110),
  ];

  // ── Inline device-type dropdown cell ─────────────────────────────────────
  // Colors mirror the PF / MD / Carbon dots used in the column header.
  static const Map<String, Color> _inclusionColors = {
    'includePfAnalytics': Color(0xFF2DD4BF),
    'includeMdRanking': Color(0xFF3B82F6),
    'includeCarbonCalc': Color(0xFF22C55E),
  };

  Widget? _deviceTypeCellBuilder(
      String key, String value, Map<String, dynamic> row) {
    if (_inclusionColors.containsKey(key)) {
      final id = row['id']?.toString() ?? '';
      final checked = row[key] == true;
      final color = _inclusionColors[key]!;
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: checked,
            activeColor: color,
            checkColor: Colors.white,
            side: BorderSide(color: color.withOpacity(0.6), width: 1.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: id.isEmpty
                ? null
                : (v) => context
                    .read<FacilityListCubit>()
                    .patchInclusionFlag(id, key, v ?? false),
          ),
        ),
      );
    }
    if (key == 'insight') {
      return Tooltip(
        message: 'View MD Prediction for ${row['meterId'] ?? 'this device'}',
        child: InkWell(
          onTap: () => context.pushNamed('MdPrediction'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00C6FF).withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.query_stats_rounded,
                    size: 12, color: Color(0xFF00C6FF)),
                SizedBox(width: 4),
                Text('Insight',
                    style: TextStyle(
                        color: Color(0xFF00C6FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }
    if (key != 'equipmentType') return null;
    if (_deviceTypes.isEmpty) {
      return Text(value.isNotEmpty ? value : '—',
          style: const TextStyle(
              color: Color.fromRGBO(226, 232, 240, 1), fontSize: 13));
    }
    final id = row['id']?.toString() ?? '';
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(22, 33, 62, 1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color.fromRGBO(56, 78, 120, 0.7),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _deviceTypes.any((dt) => dt['name']?.toString() == value)
              ? value
              : null,
          isDense: true,
          isExpanded: true,
          hint: Text(value.isNotEmpty ? value : '— select —',
              style: const TextStyle(
                  color: Color.fromRGBO(148, 163, 196, 1), fontSize: 12)),
          dropdownColor: const Color.fromRGBO(26, 35, 58, 1),
          style: const TextStyle(
              color: Color.fromRGBO(226, 232, 240, 1), fontSize: 12),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 14, color: Color.fromRGBO(107, 122, 153, 1)),
          items: _deviceTypes.map((dt) {
            final name = dt['name']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name,
                  style: const TextStyle(
                      color: Color.fromRGBO(226, 232, 240, 1), fontSize: 12)),
            );
          }).toList(),
          onChanged: (newType) {
            if (newType == null || id.isEmpty) return;
            context.read<FacilityListCubit>().patchDeviceType(id, newType);
          },
        ),
      ),
    );
  }

  void _onCreate(BuildContext context) {
    final cubit = context.read<FacilityListCubit>();
    // Collect existing meter IDs from current state for real-time validation.
    final loaded = cubit.state is FacilityListLoaded
        ? cubit.state as FacilityListLoaded
        : null;
    final existingMeterIds = loaded?.allRows
            .map((r) => r['meterId']?.toString().trim() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet() ??
        <String>{};
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => FacilityCreateDialog(
        onCreated: (data) async => cubit.addFacility(data),
        existingMeterIds: existingMeterIds,
      ),
    );
  }

  void _onEdit(BuildContext context, Map<String, dynamic> row) {
    final cubit = context.read<FacilityListCubit>();
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => FacilityUpdateDialog(
        initialData: row,
        onUpdated: () async => cubit.updateFacility(row['id']?.toString() ?? '', row),
      ),
    );
  }

  void _onDelete(BuildContext context, Map<String, dynamic> row) {
    final cubit = context.read<FacilityListCubit>();
    showDialog(
      context: context,
      builder: (_) => FacilityDeleteDialog(
        facilityId: row['id'] ?? '',
        facilityName: row['equipmentNameId'] ?? '-',
        onDeleted: () async => cubit.deleteFacility(row['id']?.toString() ?? ''),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    final t = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_outline, color: t.success, size: 18),
        const SizedBox(width: 10),
        Text(message,
            style: t.bodyMedium.override(
              fontFamily: t.bodyMediumFamily,
              color: t.primaryText,
              fontSize: 15,
              font: t.bodyMedium,
            )),
      ]),
      backgroundColor: t.secondaryBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showError(BuildContext context, String message) {
    final t = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.error_outline, color: t.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: t.bodyMedium.override(
                  fontFamily: t.bodyMediumFamily,
                  color: t.primaryText,
                  fontSize: 15,
                  font: t.bodyMedium,
                ))),
      ]),
      backgroundColor: t.secondaryBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _confirmRemoveAll(
    BuildContext context,
    FlutterFlowTheme t,
    int totalRows,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: t.secondaryBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: t.error, size: 22),
              const SizedBox(width: 10),
              Text('Remove All Equipment',
                  style: t.titleMedium.override(
                    fontFamily: t.titleMediumFamily,
                    color: t.primaryText,
                    fontWeight: FontWeight.w700,
                    font: t.titleMedium,
                  )),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete $totalRows equipment records from '
                'Master Facility. This action cannot be undone.',
                style: t.bodyMedium.override(
                  fontFamily: t.bodyMediumFamily,
                  color: t.secondaryText,
                  font: t.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Type DELETE to confirm:',
                style: t.labelMedium.override(
                  fontFamily: t.labelMediumFamily,
                  color: t.primaryText,
                  fontWeight: FontWeight.w600,
                  font: t.labelMedium,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel',
                  style: t.labelLarge.override(
                    fontFamily: t.labelLargeFamily,
                    color: t.secondaryText,
                    font: t.labelLarge,
                  )),
            ),
            ElevatedButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.error,
                disabledBackgroundColor: t.error.withOpacity(0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Yes, Remove All',
                  style: t.labelLarge.override(
                    fontFamily: t.labelLargeFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    font: t.labelLarge,
                  )),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FacilityListCubit, FacilityListState>(
      listener: (context, state) {
        if (state is FacilityListSuccess) {
          _showSuccess(context, state.message);
        }
        if (state is FacilityListActionError) {
          _showError(context, state.message);
        }
      },
      builder: (context, state) {
        final t = FlutterFlowTheme.of(context);
        final cubit = context.read<FacilityListCubit>();

        if (state is FacilityListInitial || state is FacilityListLoading) {
          return Container(
            color: t.primaryBackground,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: t.primary, strokeWidth: 2.5),
                const SizedBox(height: 16),
                Text('Loading facilities…',
                    style: t.labelLarge.override(
                      fontFamily: t.labelLargeFamily,
                      color: t.secondaryText,
                      fontSize: 15,
                      font: t.labelLarge,
                    )),
              ]),
            ),
          );
        }

        if (state is FacilityListError) {
          return Container(
            color: t.primaryBackground,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, color: t.error, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load facilities',
                    style: t.headlineSmall.override(
                      fontFamily: t.headlineSmallFamily,
                      color: t.primaryText,
                      fontSize: 20,
                      font: t.headlineSmall,
                    )),
                const SizedBox(height: 8),
                Text(state.message,
                    style: t.labelMedium.override(
                      fontFamily: t.labelMediumFamily,
                      color: t.secondaryText,
                      fontSize: 14,
                      font: t.labelMedium,
                    )),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: cubit.loadFacilities,
                  icon:
                      Icon(Icons.refresh, size: 16, color: t.primaryBackground),
                  label: Text('Retry',
                      style: t.labelLarge.override(
                        fontFamily: t.labelLargeFamily,
                        color: t.primaryBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        font: t.labelLarge,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ]),
            ),
          );
        }

        if (state is FacilityListLoaded) {
          return _buildPage(context, t, cubit, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ── KPI stat cards — reuses the shared cyberpunk CardWidget (glass fill,
  // neon glow border, HUD corner brackets) via StatCard, matching the same
  // component the Power Factor Monitoring KPI row is built on. ─────────────
  Widget _statsRow(FacilityListLoaded s) {
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              label: 'TOTAL DPM',
              value: '${s.totalDpm}',
              subtitle: 'Across ${s.plantCount} plants · Active ${s.activeDpm}',
              valueColor: _kCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'IN PF ANALYTICS',
              value: '${s.pfAnalyticsCount}',
              subtitle: '${s.pfAnalyticsPercent.round()}% of active',
              valueColor: _kGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'IN MD RANKING',
              value: '${s.mdRankingCount}',
              subtitle: 'Key contributors',
              valueColor: _kBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'IN CARBON CALC',
              value: '${s.carbonCalcCount}',
              subtitle: 'Scope 2 sources',
              valueColor: _kGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'ANOMALIES',
              value: '${s.anomalyCount}',
              subtitle: 'Auto-excluded',
              valueColor: _kRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    FlutterFlowTheme t,
    FacilityListCubit cubit,
    FacilityListLoaded s,
  ) {
    return Container(
      color: t.primaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.home_outlined,
                      size: 14, color: t.secondaryText.withOpacity(0.45)),
                  const SizedBox(width: 5),
                  Text('Dashboard',
                      style: t.labelSmall.override(
                        fontFamily: t.labelSmallFamily,
                        color: t.secondaryText.withOpacity(0.5),
                        fontSize: 13,
                        font: t.labelSmall,
                      )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right,
                        size: 14, color: t.secondaryText.withOpacity(0.3)),
                  ),
                  Text('Facilities Master List Setting',
                      style: t.labelSmall.override(
                        fontFamily: t.labelSmallFamily,
                        color: t.secondaryText.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        font: t.labelSmall,
                      )),
                ]),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: t.primary.withOpacity(0.25), width: 1)),
                    child: Center(
                        child: Icon(Icons.precision_manufacturing_outlined,
                            size: 20, color: t.primary)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Facilities Master List Setting',
                              style: t.headlineSmall.override(
                                fontFamily: t.headlineSmallFamily,
                                color: t.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                font: t.headlineSmall,
                              )),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                                color: t.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: t.primary.withOpacity(0.25),
                                    width: 1)),
                            child: Text('${s.rows.length}',
                                style: t.labelMedium.override(
                                  fontFamily: t.labelMediumFamily,
                                  color: t.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  font: t.labelMedium,
                                )),
                          ),
                        ]),
                        const SizedBox(height: 3),                        Text(
                            'Manage your facility equipment details, all in one place.',
                            style: t.labelMedium.override(
                              fontFamily: t.labelMediumFamily,
                              color: t.secondaryText,
                              fontSize: 14,
                              font: t.labelMedium,
                            )),
                      ]),
                ]),
              ],
            ),

          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Divider(color: t.primary.withOpacity(0.12), thickness: 0.5),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _statsRow(s),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              child: DataTableWidget(
                columns: s.showDates ? _columnsDates : (s.showMysql ? _columnsMysql : _columnsMain),
                rows: s.rows,
                perPage: 200,
                primaryKey: 'id',
                cellBuilder: _deviceTypeCellBuilder,
                primaryColumnKey: 'equipmentNameId',
                primarySubtitleKey: 'equipmentType',
                primaryIcon: Icons.precision_manufacturing_outlined,
                sortKey: 'equipmentNameId',
                showSelection: false,
                showFilterDropdown: false,
                // Free-text search spans Display Name + Device ID (+ Equipment /
                // Gateway) rather than a single column.
                searchKeys: const [
                  'meterName',
                  'meterId',
                  'equipmentNameId',
                  'gatewayId',
                ],
                // Filter chips mirror the Energy Details dimensions.
                filters: [
                  TableFilter(
                    label: 'Plant',
                    icon: Icons.location_city_outlined,
                    options: s.plantOptions,
                    value: s.plantFilter,
                    onChanged: cubit.setPlantFilter,
                  ),
                  TableFilter(
                    label: 'Zone / Production Area',
                    icon: Icons.grid_view_outlined,
                    options: s.zoneOptions,
                    value: s.zoneFilter,
                    onChanged: cubit.setZoneFilter,
                  ),
                  TableFilter(
                    label: 'Production Line',
                    icon: Icons.linear_scale_outlined,
                    options: s.lineOptions,
                    value: s.lineFilter,
                    onChanged: cubit.setLineFilter,
                  ),
                  TableFilter(
                    label: 'Equipment',
                    icon: Icons.precision_manufacturing_outlined,
                    options: s.equipmentOptions,
                    value: s.equipmentFilter,
                    onChanged: cubit.setEquipmentFilter,
                  ),
                  TableFilter(
                    label: 'Status',
                    icon: Icons.toggle_on_outlined,
                    options: s.uniqueValues('status'),
                    value: s.statusFilter,
                    onChanged: cubit.setStatusFilter,
                  ),
                ],
                actions: [
                  TableAction(
                    label: 'Details',
                    icon: Icons.view_column_outlined,
                    isPrimary: false,
                    onTap: cubit.showDetails,
                  ),
                  TableAction(
                    label: 'Dates',
                    icon: Icons.calendar_month_outlined,
                    isPrimary: false,
                    onTap: cubit.showDates,
                  ),
                  TableAction(
                    label: 'Discovery',
                    icon: Icons.device_hub_outlined,
                    isPrimary: false,
                    onTap: cubit.showMysqlView,
                  ),
                  TableAction(
                    label: 'Add New Device',
                    icon: Icons.add_rounded,
                    isPrimary: true,
                    onTap: () => _onCreate(context),
                  ),
                ],
                activeActionLabel: s.showMysql ? 'Discovery' : (s.showDates ? 'Dates' : 'Details'),
                onEdit: (row) => _onEdit(context, row),
                onDelete: (row) => _onDelete(context, row),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

