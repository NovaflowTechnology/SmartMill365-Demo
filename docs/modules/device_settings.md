# device_settings

**Path**: `lib/web_app_template/device_settings/`
**Category**: Settings & masters

## Purpose
Manages physical devices (PLCs, gateways, sensors, meters) connected to
the system. Maps each device to an equipment + production area + factory.

## Firestore collections
- `devices` (read/write)
- `equipments` (read)
- `productionAreas` (read)
- `factories` (read)

## Key files
- `firestore_service.dart`
- `device_settings_widget.dart`

## Related modules
- [equipment_settings](equipment_settings.md)
- [alarm_settings](alarm_settings.md)
- [master_facility_setting](master_facility_setting.md)
- [energy_data_logger_1](energy_data_logger_1.md) / [_2](energy_data_logger_2.md)

## Notes
- This module shows the canonical "factory → area → equipment → device"
  hierarchy in one place.
