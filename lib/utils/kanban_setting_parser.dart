class KanbanSettingsParser {
  KanbanSettingsParser._();

  static String? parseStringField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      if (seconds != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          (seconds as int) * 1000,
          isUtc: true,
        ).toLocal();
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
            '${dt.day.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      }
      return value.toString();
    }
    return value.toString();
  }

  static Map<String, dynamic>? parseMapField(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}