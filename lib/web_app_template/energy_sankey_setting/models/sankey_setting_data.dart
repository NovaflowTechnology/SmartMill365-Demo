class SankeyTier {
  final String id;
  final String label;
  final int order;
  final String colorHex;

  const SankeyTier(
      {required this.id, required this.label, required this.order, this.colorHex = ''});

  factory SankeyTier.fromMap(Map<String, dynamic> m) => SankeyTier(
        id: m['id']?.toString() ?? '',
        label: m['label']?.toString() ?? '',
        order: (m['order'] as num?)?.toInt() ?? 0,
        colorHex: m['color']?.toString() ??
            m['colorHex']?.toString() ??
            m['tierColor']?.toString() ??
            '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'order': order,
        'color': colorHex,
      };

  SankeyTier copyWith({String? id, String? label, int? order, String? colorHex}) => SankeyTier(
      id: id ?? this.id,
      label: label ?? this.label,
      order: order ?? this.order,
      colorHex: colorHex ?? this.colorHex);
}

const int kMinFields = 1;

class SankeyNode {
  final String id;
  final String tierId;
  final String masterFacilityId;
  final String label;
  final String deviceId;
  final String flowValueTag;
  final String colorHex;

  /// InfluxDB fields to read for this node — min 5 entries
  final List<String> fields;

  /// IDs of nodes (in the NEXT tier) that this node distributes energy to
  final List<String> targetIds;

  /// Ghost flag: when true, this node's slot is visually empty and the
  /// column renders a "+ Add" button in its place. The slot position,
  /// id, and parent link via targetIds are preserved so the user can
  /// restore the slot without losing alignment.
  final bool removed;

  const SankeyNode({
    required this.id,
    required this.tierId,
    this.masterFacilityId = '',
    required this.label,
    required this.deviceId,
    this.flowValueTag = '',
    this.colorHex = '',
    this.fields = const [''],
    this.targetIds = const [],
    this.removed = false,
  });

  factory SankeyNode.fromMap(Map<String, dynamic> m) {
    List<String> fields;
    if (m['fields'] != null) {
      fields = (m['fields'] as List<dynamic>).map((e) => e.toString()).toList();
    } else {
      // backwards-compat: old single 'field' / 'dataMapping'
      final single =
          m['field']?.toString() ?? m['dataMapping']?.toString() ?? 'P(kW)';
      fields = [single];
    }
    // ensure minimum length
    while (fields.length < kMinFields) {
      fields.add('');
    }
    return SankeyNode(
      id: m['id']?.toString() ?? '',
      tierId: m['tierId']?.toString() ?? '',
      masterFacilityId: m['master_facility_id']?.toString() ??
          m['masterFacilityId']?.toString() ??
          m['facilityId']?.toString() ??
          '',
      label: m['label']?.toString() ?? '',
      deviceId: m['deviceId']?.toString() ?? '',
      flowValueTag: m['flow_value_tag']?.toString() ??
          m['flowValueTag']?.toString() ??
          '',
      colorHex: m['color']?.toString() ??
          m['colorHex']?.toString() ??
          m['nodeColor']?.toString() ??
          '',
      fields: fields,
      targetIds: (m['targetIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      removed: m['removed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'tierId': tierId,
        'master_facility_id': masterFacilityId,
        'label': label,
        'deviceId': deviceId,
        'color': colorHex,
        'flow_value_tag': fields.firstWhere(
          (field) => field.trim().isNotEmpty,
          orElse: () => flowValueTag,
        ),
        'fields': fields,
        'targetIds': targetIds,
        'removed': removed,
      };

  SankeyNode copyWith({
    String? id,
    String? tierId,
    String? masterFacilityId,
    String? label,
    String? deviceId,
    String? flowValueTag,
    String? colorHex,
    List<String>? fields,
    List<String>? targetIds,
    bool? removed,
  }) =>
      SankeyNode(
        id: id ?? this.id,
        tierId: tierId ?? this.tierId,
        masterFacilityId: masterFacilityId ?? this.masterFacilityId,
        label: label ?? this.label,
        deviceId: deviceId ?? this.deviceId,
        flowValueTag: flowValueTag ?? this.flowValueTag,
        colorHex: colorHex ?? this.colorHex,
        fields: fields ?? this.fields,
        targetIds: targetIds ?? this.targetIds,
        removed: removed ?? this.removed,
      );
}
