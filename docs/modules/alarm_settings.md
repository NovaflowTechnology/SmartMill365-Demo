# alarm_settings

**Path**: `lib/web_app_template/alarm_settings/`
**Category**: Equipment

## Purpose
Configure alarm rules — thresholds, severity, and which devices/equipment
they apply to. Alarms triggered here populate `equipment_alarm_data`.

## Firestore collections
- `alarms` (read/write)
- `equipments` (read)
- `devices` (read)

## Key files
- `firestore_service.dart` — DB access layer
- `alarm_settings_widget.dart`

## Related modules
- [equipment_alarm_data](equipment_alarm_data.md)
- [device_settings](device_settings.md)
- [equipment_settings](equipment_settings.md)

## Notes
- Has its own `firestore_service.dart` — follow this pattern for new modules
  that need a clean DB access layer.
