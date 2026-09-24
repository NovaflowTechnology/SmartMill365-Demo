# equipment_details

**Path**: `lib/web_app_template/equipment_details/`
**Category**: Equipment

## Purpose
Detailed view of a single equipment, drilled into from `equipment_overview`.
Shows status timeline, alarm history, energy data, and KPIs for the
selected machine. Filters can scope by production area.

## Firestore collections
- `equipments` (read) — filters by `productionArea`

## Key files
- `equipment_details_widget.dart`

## Related modules
- [equipment_overview](equipment_overview.md)
- [equipment_alarm_data](equipment_alarm_data.md)
- [equipment_status_data](equipment_status_data.md)
- [equipment_energy_data](equipment_energy_data.md)

## Notes
- TODO: document the URL parameter / argument used to select the equipment.
