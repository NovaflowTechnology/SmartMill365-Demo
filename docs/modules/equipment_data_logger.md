# equipment_data_logger

**Path**: `lib/web_app_template/equipment_data_logger/`
**Category**: Equipment

## Purpose
Raw data log viewer for an equipment — shows the time-series telemetry
captured from the machine (sensor readings, status changes, counter values).
Used by engineers debugging machine behavior.

## Firestore collections
- TODO: confirm — likely a per-equipment subcollection or a top-level
  `equipmentLogs` / `telemetry` collection.

## Key files
- TODO

## Related modules
- [equipment_details](equipment_details.md)
- [equipment_status_data](equipment_status_data.md)

## Notes
- TODO: clarify retention / pagination strategy for large logs.
