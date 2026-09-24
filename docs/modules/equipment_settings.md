# equipment_settings

**Path**: `lib/web_app_template/equipment_settings/`
**Category**: Equipment

## Purpose
CRUD screen for equipment master data. Add, edit, and view equipment
records along with their work order linkage.

## Firestore collections
- `equipments` (read/write)
- `workOrders` (read) — referenced when associating work orders to equipment

## Key files
- `view.dart` — list/view
- `add.dart` — create new equipment
- `edit.dart` — edit existing equipment

## Related modules
- [equipment_overview](equipment_overview.md)
- [work_order_overview](work_order_overview.md)
- [device_settings](device_settings.md)

## Notes
- TODO: confirm RBAC — likely admin-only.
