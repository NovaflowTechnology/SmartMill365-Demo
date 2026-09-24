/// Which parts of the facility hierarchy a user is allowed to see.
///
/// Stored on `roles/{uid}.data_scope` next to `accessible_modules`, because
/// the two answer the same question from different directions: modules say
/// *which screens*, scope says *whose data* on those screens.
///
/// ## Why ids and not names
///
/// Plants and production areas are edited by hand, and a rename would silently
/// revoke access if permissions pointed at the text. The master lists already
/// carry stable ids — `F0002`, `P0003` — so those are what a grant records.
/// Names are looked up for display and for matching equipment rows, but they
/// are never the identity.
///
/// ## Empty means unrestricted
///
/// Every user predates this feature, so an absent or empty scope has to mean
/// "everything". The alternative locks the whole customer out on the day it
/// ships. User Management shows which accounts are still unrestricted so this
/// stays a visible state rather than a silent default.
class UserScope {
  /// Granted plant ids, e.g. `F0002`. Empty means every plant.
  final List<String> plantIds;

  /// Granted production area ids, e.g. `P0003`. Empty means every area within
  /// whatever plants are granted.
  final List<String> areaIds;

  const UserScope({
    this.plantIds = const [],
    this.areaIds = const [],
  });

  static const UserScope unrestricted = UserScope();

  /// True when this scope places no limit at all.
  bool get isUnrestricted => plantIds.isEmpty && areaIds.isEmpty;

  bool get hasPlantLimit => plantIds.isNotEmpty;
  bool get hasAreaLimit => areaIds.isNotEmpty;

  /// Whether a plant is visible. An empty plant list allows all of them.
  bool allowsPlant(String plantId) =>
      plantIds.isEmpty || plantIds.contains(plantId);

  /// Whether a production area is visible.
  ///
  /// [parentPlantId] is optional because the area master does not always
  /// record which plant an area belongs to. When it is known, an area also has
  /// to sit inside a granted plant; when it is not, the area list alone
  /// decides — a looser rule, but an honest one given the data.
  bool allowsArea(String areaId, {String? parentPlantId}) {
    if (parentPlantId != null &&
        parentPlantId.isNotEmpty &&
        !allowsPlant(parentPlantId)) {
      return false;
    }
    return areaIds.isEmpty || areaIds.contains(areaId);
  }

  UserScope copyWith({List<String>? plantIds, List<String>? areaIds}) =>
      UserScope(
        plantIds: plantIds ?? this.plantIds,
        areaIds: areaIds ?? this.areaIds,
      );

  Map<String, dynamic> toJson() => {
        'plant_ids': plantIds,
        'area_ids': areaIds,
      };

  /// Tolerant of both shapes seen in the wild: a map with the two lists, and a
  /// missing field altogether on accounts saved before this existed.
  factory UserScope.fromJson(Map<String, dynamic>? json) {
    if (json == null) return unrestricted;
    List<String> ids(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
    return UserScope(plantIds: ids('plant_ids'), areaIds: ids('area_ids'));
  }

  @override
  String toString() =>
      'UserScope(plants: $plantIds, areas: $areaIds, unrestricted: $isUnrestricted)';

  @override
  bool operator ==(Object other) =>
      other is UserScope &&
      _sameIds(other.plantIds, plantIds) &&
      _sameIds(other.areaIds, areaIds);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(plantIds),
        Object.hashAllUnordered(areaIds),
      );

  static bool _sameIds(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}
