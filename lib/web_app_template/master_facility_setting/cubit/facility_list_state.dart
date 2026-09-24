part of 'facility_list_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FacilityListState
// ─────────────────────────────────────────────────────────────────────────────

abstract class FacilityListState extends Equatable {
  const FacilityListState();
  @override
  List<Object?> get props => [];
}

class FacilityListInitial extends FacilityListState {
  const FacilityListInitial();
}

class FacilityListLoading extends FacilityListState {
  const FacilityListLoading();
}

class FacilityListError extends FacilityListState {
  final String message;
  const FacilityListError(this.message);
  @override
  List<Object?> get props => [message];
}

class FacilityListLoaded extends FacilityListState {
  final List<Map<String, dynamic>> allRows;
  final String plantFilter;
  final String zoneFilter;
  final String lineFilter;
  final String equipmentFilter;
  final String statusFilter;
  final bool   showDates;
  final bool   showMysql;

  const FacilityListLoaded({
    required this.allRows,
    this.plantFilter     = 'All',
    this.zoneFilter      = 'All',
    this.lineFilter      = 'All',
    this.equipmentFilter = 'All',
    this.statusFilter    = 'All',
    this.showDates       = false,
    this.showMysql       = false,
  });

  // ── Filtered rows ─────────────────────────────────────────────────────────
  // Mirrors the Energy Details filter dimensions:
  //   Plant → zone ("Zone / Production Area") → productionArea ("Production
  //   Line") → equipmentNameId ("Equipment"), plus Status.
  List<Map<String, dynamic>> get rows => allRows.where((r) {
    if (plantFilter     != 'All' && r['plant']           != plantFilter)     return false;
    if (zoneFilter      != 'All' && r['zone']            != zoneFilter)      return false;
    if (lineFilter      != 'All' && r['productionArea']  != lineFilter)      return false;
    if (equipmentFilter != 'All' && r['equipmentNameId'] != equipmentFilter) return false;
    if (statusFilter    != 'All' && r['status']          != statusFilter)    return false;
    return true;
  }).toList();

  // ── Unique values for filter dropdowns ────────────────────────────────────
  List<String> uniqueValues(String field) {
    final vals = allRows
        .map((r) => r[field]?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()..sort();
    return ['All', ...vals];
  }

  // Cascading options — each level narrows to the current parent selections,
  // exactly like the Energy Details filter chain.
  List<String> _cascade(String field, {bool plant = false, bool zone = false, bool line = false}) {
    final vals = allRows.where((r) {
      if (plant && plantFilter != 'All' && r['plant']          != plantFilter) return false;
      if (zone  && zoneFilter  != 'All' && r['zone']           != zoneFilter)  return false;
      if (line  && lineFilter  != 'All' && r['productionArea'] != lineFilter)  return false;
      return true;
    })
        .map((r) => r[field]?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()..sort();
    return ['All', ...vals];
  }

  // ── KPI stat cards — computed over the full unfiltered set so the cards
  // reflect the whole registry regardless of the active table filters. ──────
  int get totalDpm => allRows.length;
  int get activeDpm =>
      allRows.where((r) => (r['status']?.toString() ?? '') == 'Active').length;
  int get plantCount => allRows
      .map((r) => r['plant']?.toString() ?? '')
      .where((v) => v.isNotEmpty)
      .toSet()
      .length;
  int get pfAnalyticsCount =>
      allRows.where((r) => r['includePfAnalytics'] == true).length;
  double get pfAnalyticsPercent =>
      totalDpm > 0 ? pfAnalyticsCount / totalDpm * 100 : 0;
  int get mdRankingCount =>
      allRows.where((r) => r['includeMdRanking'] == true).length;
  int get carbonCalcCount =>
      allRows.where((r) => r['includeCarbonCalc'] == true).length;
  // Devices auto-excluded from analytics because they're not Active / not
  // currently reporting — distinct from the manual PF/MD/Carbon checkboxes.
  int get anomalyCount => allRows.where((r) {
        final status = r['status']?.toString() ?? '';
        final online = r['onlineStatus']?.toString() ?? '';
        return (status.isNotEmpty && status != 'Active') || online == 'Offline';
      }).length;

  List<String> get plantOptions     => uniqueValues('plant');
  List<String> get zoneOptions       => _cascade('zone', plant: true);
  List<String> get lineOptions       => _cascade('productionArea', plant: true, zone: true);
  List<String> get equipmentOptions  => _cascade('equipmentNameId', plant: true, zone: true, line: true);

  FacilityListLoaded copyWith({
    List<Map<String, dynamic>>? allRows,
    String? plantFilter,
    String? zoneFilter,
    String? lineFilter,
    String? equipmentFilter,
    String? statusFilter,
    bool?   showDates,
    bool?   showMysql,
  }) {
    return FacilityListLoaded(
      allRows:         allRows         ?? this.allRows,
      plantFilter:     plantFilter     ?? this.plantFilter,
      zoneFilter:      zoneFilter      ?? this.zoneFilter,
      lineFilter:      lineFilter      ?? this.lineFilter,
      equipmentFilter: equipmentFilter ?? this.equipmentFilter,
      statusFilter:    statusFilter    ?? this.statusFilter,
      showDates:       showDates       ?? this.showDates,
      showMysql:       showMysql       ?? this.showMysql,
    );
  }

  @override
  List<Object?> get props =>
      [allRows, plantFilter, zoneFilter, lineFilter, equipmentFilter, statusFilter, showDates, showMysql];
}

// ── Snackbar triggers — emitted then immediately go back to Loaded ────────────
class FacilityListSuccess extends FacilityListState {
  final String message;
  const FacilityListSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class FacilityListActionError extends FacilityListState {
  final String message;
  const FacilityListActionError(this.message);
  @override
  List<Object?> get props => [message];
}