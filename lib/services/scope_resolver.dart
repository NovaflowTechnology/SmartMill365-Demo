import 'package:smartmachine365/models/user_scope.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';

/// One plant or production area, as the scope picker and the dashboard filters
/// need to see it.
class ScopeNode {
  final String id;
  final String name;

  /// The plant this area belongs to, when the master records it. Areas often
  /// The plant this area belongs to, when the master records a plant that
  /// actually exists. Empty means "unknown", not "no parent" — see
  /// [ScopeResolver.hasHierarchy].
  final String parentId;

  const ScopeNode({
    required this.id,
    required this.name,
    this.parentId = '',
  });
}

/// Turns a [UserScope] into the plants and areas a user may actually see.
///
/// Everything funnels through here rather than each dropdown filtering for
/// itself. Scope is a rule that has to hold identically on every screen, and
/// the surest way to get that is to give every screen the same answer from one
/// place — a filter written twice is a filter that will disagree once.
///
/// Note what this class does *not* do: it does not secure anything. It decides
/// what the UI offers. The API is what must refuse data the user is not
/// entitled to, and until it does, this is a convenience rather than a control.
class ScopeResolver {
  ScopeResolver._();

  /// Rows that exist only from testing. Matching on the name keeps this to one
  /// place instead of a hardcoded list of ids that would go stale.
  static bool _looksLikeScratch(String name) {
    final n = name.trim().toLowerCase();
    return n.startsWith('test') || n.contains('testete');
  }

  /// The master list's placeholder row, which is never a real grant.
  static const _unassignedId = '0';

  static List<ScopeNode> _plants = const [];
  static List<ScopeNode> _areas = const [];
  static bool _loaded = false;

  static List<ScopeNode> get plants => _plants;
  static List<ScopeNode> get areas => _areas;

  /// True when at least one area records which plant it belongs to.
  ///
  /// The picker uses this to choose its shape: a tree when the links exist, two
  /// flat lists when they do not. Pointing an area's factory_id at a plant that
  /// exists upgrades the picker on its own, with no code change.
  static bool get hasHierarchy => _areas.any((a) => a.parentId.isNotEmpty);

  /// Loads both masters once. [force] refetches, e.g. after an admin edits the
  /// facility list in another tab.
  static Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final factories =
        await FacilityService.getFactories(forceRefresh: force, bypassScope: true);
    final areas = await FacilityService.getProductionAreas(
        forceRefresh: force, bypassScope: true);

    _plants = factories
        .map((f) => ScopeNode(
              id: f['id']?.toString() ?? '',
              name: f['name']?.toString() ?? '',
            ))
        // Unnamed and obviously scratch rows are dropped. A permission list is
        // the wrong place to meet a blank entry or a row called "testetes":
        // whoever is granting access cannot tell what they would be granting.
        .where((n) =>
            n.id.isNotEmpty &&
            n.id != _unassignedId &&
            n.name.trim().isNotEmpty &&
            !_looksLikeScratch(n.name))
        .toList();

    final knownPlantIds = _plants.map((p) => p.id).toSet();

    _areas = areas
        .map((a) {
          // The master writes the parent as factory_id; company_id exists on
          // the same records but is null in practice. Read both so neither
          // spelling is the one that silently breaks the tree.
          final parent = (a['factory_id'] ?? a['company_id'] ?? '')
              .toString()
              .trim();
          return ScopeNode(
            id: a['id']?.toString() ?? '',
            name: a['name']?.toString() ?? '',
            // Some areas point at a plant id that no longer exists in the
            // plant master. Keeping such a link would hide the area under a
            // parent that never renders, so it is treated as unrecorded and
            // the area stays grantable on its own.
            parentId: knownPlantIds.contains(parent) ? parent : '',
          );
        })
        .where((n) =>
            n.id.isNotEmpty &&
            n.id != _unassignedId &&
            n.name.trim().isNotEmpty &&
            !_looksLikeScratch(n.name))
        .toList();

    _loaded = true;
  }

  /// The plant id carrying this name, or empty when the master has no such
  /// plant. Names are what the nav passes around, ids are what a scope stores.
  static String plantIdByName(String name) {
    final want = name.trim().toLowerCase();
    if (want.isEmpty) return '';
    for (final p in _plants) {
      if (p.name.trim().toLowerCase() == want) return p.id;
    }
    return '';
  }

  /// The plant an area belongs to, or empty when the master does not record one.
  static String parentPlantOf(String areaId) {
    for (final a in _areas) {
      if (a.id == areaId) return a.parentId;
    }
    return '';
  }

  /// The plants this scope may see, in master order.
  static List<ScopeNode> visiblePlants(UserScope scope) =>
      _plants.where((p) => scope.allowsPlant(p.id)).toList();

  /// The areas this scope may see.
  ///
  /// When [withinPlantId] is given, only areas of that plant are returned —
  /// but only for areas that actually record a parent. An area with no parent
  /// recorded is left in rather than hidden: dropping it would make it
  /// unreachable on every screen, which looks like data loss rather than a
  /// permission.
  static List<ScopeNode> visibleAreas(UserScope scope, {String? withinPlantId}) {
    return _areas.where((a) {
      if (withinPlantId != null &&
          withinPlantId.isNotEmpty &&
          a.parentId.isNotEmpty &&
          a.parentId != withinPlantId) {
        return false;
      }
      return scope.allowsArea(a.id, parentPlantId: a.parentId);
    }).toList();
  }

  /// Areas belonging to a plant, for the picker's tree branches.
  static List<ScopeNode> areasOfPlant(String plantId) =>
      _areas.where((a) => a.parentId == plantId).toList();

  /// Areas no plant claims. Shown as their own group so they can still be
  /// granted, instead of disappearing because the master is incomplete.
  static List<ScopeNode> get orphanAreas =>
      _areas.where((a) => a.parentId.isEmpty).toList();

  static String plantName(String id) =>
      _plants.firstWhere((p) => p.id == id, orElse: () => const ScopeNode(id: '', name: '')).name;

  static String areaName(String id) =>
      _areas.firstWhere((a) => a.id == id, orElse: () => const ScopeNode(id: '', name: '')).name;

  /// Whether an equipment row is inside a scope.
  ///
  /// Equipment records its plant and area as free text, not as ids, so a grant
  /// made of ids has to be compared by name. That translation is the one weak
  /// joint in this design, and it lives here alone: when the equipment table
  /// gains real id columns, this method is what changes and nothing else.
  ///
  /// A row whose plant or area is blank is kept rather than hidden. Unfiled
  /// equipment is a data gap, and making it vanish would read as data loss on
  /// every screen instead of as a permission.
  static bool allowsFacilityNames(
    UserScope scope, {
    required String plantName,
    required String areaName,
  }) {
    if (scope.isUnrestricted) return true;
    final names = namesFor(scope);

    if (names.plants.isNotEmpty && plantName.trim().isNotEmpty) {
      if (!names.plants.contains(plantName.trim())) return false;
    }
    if (names.areas.isNotEmpty && areaName.trim().isNotEmpty) {
      if (!names.areas.contains(areaName.trim())) return false;
    }
    return true;
  }

  /// The names behind a scope, for matching equipment rows.
  ///
  /// Equipment records the plant and area as text, not as ids, so a scope of
  /// ids has to be translated before it can filter devices. This is the one
  /// weak joint in the design and it lives in a single method on purpose: when
  /// the equipment table grows real id columns, only this changes.
  static ({Set<String> plants, Set<String> areas}) namesFor(UserScope scope) => (
        plants: scope.plantIds.map(plantName).where((n) => n.isNotEmpty).toSet(),
        areas: scope.areaIds.map(areaName).where((n) => n.isNotEmpty).toSet(),
      );
}
