import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'tnb_meter_models.dart';
import 'tnb_meter_service.dart';
import 'tnb_meter_dialog.dart';

class TnbMeterSettingWidget extends StatefulWidget {
  const TnbMeterSettingWidget({super.key});

  @override
  State<TnbMeterSettingWidget> createState() => _TnbMeterSettingWidgetState();
}

class _TnbMeterSettingWidgetState extends State<TnbMeterSettingWidget> {
  List<TnbMeter> _meters = [];
  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _tariffs = [];
  bool _isLoading = false;

  String _search = '';
  String _filterPlant = '';
  String _filterStatus = '';
  String _filterTariff = '';

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        TnbMeterService.fetchMeters(),
        TnbMeterService.fetchPlants(),
        TnbMeterService.fetchProductionAreas(),
        TnbMeterService.fetchTariffCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _meters = results[0] as List<TnbMeter>;
        _plants = results[1] as List<Map<String, dynamic>>;
        _areas = results[2] as List<Map<String, dynamic>>;
        _tariffs = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      debugPrint('Error loading TNB meter data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _plantName(String id) {
    final p = _plants.where((p) => p['id']?.toString() == id).firstOrNull;
    return p?['name']?.toString() ?? id;
  }

  String _areaName(String id) {
    final a = _areas.where((a) => a['id']?.toString() == id).firstOrNull;
    return a?['name']?.toString() ?? '';
  }

  List<TnbMeter> get _filteredMeters {
    return _meters.where((m) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final match = m.meterCode.toLowerCase().contains(q) || m.meterLabel.toLowerCase().contains(q) || m.tnbAccountNo.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_filterPlant.isNotEmpty && m.plantId != _filterPlant) return false;
      if (_filterStatus == 'Active' && !m.isActive) return false;
      if (_filterStatus == 'Inactive' && m.isActive) return false;
      if (_filterTariff.isNotEmpty && m.tariffType != _filterTariff) return false;
      return true;
    }).toList();
  }

  List<PlantGroup> get _groupedMeters {
    final filtered = _filteredMeters;
    final groups = <String, List<TnbMeter>>{};
    final ungrouped = <TnbMeter>[];

    for (final m in filtered) {
      if (m.plantId.isNotEmpty) {
        groups.putIfAbsent(m.plantId, () => []).add(m);
      } else {
        ungrouped.add(m);
      }
    }

    final result = groups.entries.map((e) {
      return PlantGroup(
        plantId: e.key,
        plantName: _plantName(e.key),
        meters: e.value,
      );
    }).toList()
      ..sort((a, b) => a.plantName.compareTo(b.plantName));

    if (ungrouped.isNotEmpty) {
      result.add(PlantGroup(
        plantId: '',
        plantName: 'Unassigned',
        meters: ungrouped,
      ));
    }

    return result;
  }

  Set<String> get _uniqueTariffs => _meters.map((m) => m.tariffType).where((t) => t.isNotEmpty).toSet();

  int _equipmentCount(TnbMeter m) {
    int count = 0;
    for (final areaId in m.boundAreaIds) {
      final area = _areas.where((a) => a['id']?.toString() == areaId).firstOrNull;
      count += (area?['equipment_count'] as num?)?.toInt() ?? 0;
    }
    return count;
  }

  String _areasSummary(TnbMeter m) {
    if (m.boundAreaIds.isEmpty) return '';
    final names = m.boundAreaIds.map(_areaName).where((n) => n.isNotEmpty).toList();
    final eqCount = _equipmentCount(m);
    final parts = <String>[];
    if (names.isNotEmpty) parts.add(names.join(', '));
    parts.add('$eqCount equipment');
    return parts.join(' · ');
  }

  double _usagePercent(TnbMeter m) {
    if (m.contractMdKw <= 0) return 0;
    return 0;
  }

  Color _statusDotColor(TnbMeter m) {
    final pct = _usagePercent(m);
    if (pct > 100) return const Color(0xFFDC2626);
    if (pct > 90) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TnbMeterDialog(
        plants: _plants,
        areas: _areas,
        tariffs: _tariffs,
        existingMeters: _meters,
        onSaved: _fetchAll,
      ),
    );
  }

  void _showEditDialog(TnbMeter meter) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TnbMeterDialog(
        meter: meter,
        plants: _plants,
        areas: _areas,
        tariffs: _tariffs,
        existingMeters: _meters,
        onSaved: _fetchAll,
      ),
    );
  }

  void _showDeleteConfirm(TnbMeter meter) {
    final theme = FlutterFlowTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.primaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.cardStroke),
        ),
        title: Text(
          'Delete Meter',
          style: TextStyle(color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete "${meter.meterCode}"? This cannot be undone.',
          style: TextStyle(color: theme.txtSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.txtSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await TnbMeterService.deleteMeter(meter.id);
              if (ok) _fetchAll();
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: Image.asset('assets/images/backgroundanimated.gif').image,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            breadcrumbs: const [
              BreadcrumbItem(label: 'Settings', icon: Icons.settings),
              BreadcrumbItem(label: 'General Factory Setting'),
              BreadcrumbItem(label: 'TNB Meter'),
            ],
            title: 'TNB Meter Setting',
            subtitle: 'Manage TNB billing accounts. Each meter is bound to one or more Production Areas to define its billing scope. '
                'All Equipment under bound Areas is automatically billed under this meter.',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildFilterBar(theme, isLight),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8))) : _buildMeterList(theme, isLight),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(FlutterFlowTheme theme, bool isLight) {
    final bgColor = isLight ? Colors.white : theme.primaryBackground;
    final borderColor = isLight ? const Color(0xFFE3E8EF) : theme.cardStroke;
    final hintColor = theme.txtMuted;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.poppins(fontSize: 13, color: theme.txtPrimary),
              decoration: InputDecoration(
                hintText: 'Search meter code, label, or account no...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: hintColor),
                prefixIcon: Icon(Icons.search, size: 18, color: hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _filterDropdown(
          theme,
          isLight,
          label: 'Plant',
          value: _filterPlant.isEmpty ? null : _filterPlant,
          items: [
            const DropdownMenuItem(value: '', child: Text('All')),
            ..._plants.map((p) => DropdownMenuItem(
                  value: p['id']?.toString() ?? '',
                  child: Text(p['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) => setState(() => _filterPlant = v ?? ''),
        ),
        const SizedBox(width: 8),
        _filterDropdown(
          theme,
          isLight,
          label: 'Status',
          value: _filterStatus.isEmpty ? null : _filterStatus,
          items: const [
            DropdownMenuItem(value: '', child: Text('All')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
          onChanged: (v) => setState(() => _filterStatus = v ?? ''),
        ),
        const SizedBox(width: 8),
        _filterDropdown(
          theme,
          isLight,
          label: 'Tariff',
          value: _filterTariff.isEmpty ? null : _filterTariff,
          items: [
            const DropdownMenuItem(value: '', child: Text('All')),
            ..._uniqueTariffs.map((t) => DropdownMenuItem(value: t, child: Text(t))),
          ],
          onChanged: (v) => setState(() => _filterTariff = v ?? ''),
        ),
        const SizedBox(width: 16),
        _addButton(theme),
      ],
    );
  }

  Widget _filterDropdown(
    FlutterFlowTheme theme,
    bool isLight, {
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bgColor = isLight ? Colors.white : theme.primaryBackground;
    final borderColor = isLight ? const Color(0xFFE3E8EF) : theme.cardStroke;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('$label: All', style: GoogleFonts.poppins(fontSize: 13, color: theme.txtSecondary)),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: theme.txtMuted),
          dropdownColor: bgColor,
          style: GoogleFonts.poppins(fontSize: 13, color: theme.txtPrimary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _addButton(FlutterFlowTheme theme) {
    return Material(
      color: const Color(0xFF2D4739),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _showAddDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text('Add new meter', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeterList(FlutterFlowTheme theme, bool isLight) {
    final groups = _groupedMeters;
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.electric_meter_outlined, size: 48, color: theme.txtMuted),
            const SizedBox(height: 12),
            Text('No meters found', style: GoogleFonts.poppins(fontSize: 14, color: theme.txtTertiary)),
            const SizedBox(height: 4),
            Text(
              'Click "+ Add new meter" to register a billing account.',
              style: GoogleFonts.poppins(fontSize: 12, color: theme.txtMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: groups.length,
      itemBuilder: (context, index) => _buildPlantGroup(groups[index], theme, isLight),
    );
  }

  Widget _buildPlantGroup(PlantGroup group, FlutterFlowTheme theme, bool isLight) {
    final headerBg = isLight ? const Color(0xFFF7F8FA) : theme.primaryBackground.withOpacity(0.5);
    final borderColor = isLight ? const Color(0xFFE3E8EF) : theme.cardStroke;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: Row(
            children: [
              Text(
                group.plantName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.txtPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                '${group.meterCount} meter${group.meterCount != 1 ? 's' : ''} · '
                '${group.totalContractKw.toStringAsFixed(0)} kW contract',
                style: GoogleFonts.poppins(fontSize: 12, color: theme.txtMuted),
              ),
            ],
          ),
        ),
        ...group.meters.map((m) => _buildMeterRow(m, theme, isLight)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMeterRow(TnbMeter meter, FlutterFlowTheme theme, bool isLight) {
    final bgColor = isLight ? Colors.white : theme.primaryBackground;
    final borderColor = isLight ? const Color(0xFFE3E8EF) : theme.cardStroke;
    final areas = _areasSummary(meter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _statusDotColor(meter),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              meter.meterCode,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.txtPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meter.meterLabel,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: theme.txtPrimary),
                ),
                if (areas.isNotEmpty)
                  Text(
                    areas,
                    style: GoogleFonts.poppins(fontSize: 11, color: theme.txtTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: meter.contractMdKw.toStringAsFixed(0),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: theme.txtPrimary),
                  ),
                  TextSpan(
                    text: ' kW MD',
                    style: GoogleFonts.poppins(fontSize: 11, color: theme.txtMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              meter.tariffType,
              style: GoogleFonts.poppins(fontSize: 13, color: theme.txtSecondary),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(
              meter.tnbAccountNo,
              style: GoogleFonts.poppins(fontSize: 12, color: theme.txtTertiary, fontFeatures: [const FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(width: 12),
          _statusBadge(meter, theme, isLight),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: theme.txtMuted),
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor),
            ),
            onSelected: (action) {
              if (action == 'edit') _showEditDialog(meter);
              if (action == 'delete') _showDeleteConfirm(meter);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: theme.txtSecondary),
                    const SizedBox(width: 8),
                    Text('Edit', style: GoogleFonts.poppins(fontSize: 13, color: theme.txtPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Text('Delete', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(TnbMeter meter, FlutterFlowTheme theme, bool isLight) {
    final active = meter.isActive;
    final bgColor =
        active ? (isLight ? const Color(0xFFECFDF5) : const Color(0xFF064E3B)) : (isLight ? const Color(0xFFF3F4F6) : const Color(0xFF374151));
    final textColor =
        active ? (isLight ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)) : (isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}
