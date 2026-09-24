# production_task_work_station

**Path**: `lib/web_app_template/production_task_work_station/`
**Category**: Production

## Purpose
Workstation-level task tracker. Operators see assigned work orders and
log progress / downtime / quantity from this screen. The shop-floor
front-end of the production module.

## Firestore collections
- `workOrders` (read/write)
- `equipments` (read)
- `products` (read)
- `downTimeCodes` (read)

## Key files
- `firestore_service.dart`
- `cubits/work_order_repository.dart`

## Related modules
- [work_order_overview](work_order_overview.md)
- [mc_wo_qty_data_logger](mc_wo_qty_data_logger.md)
- [oee_data](oee_data.md)

## Notes
- Uses cubit pattern. Probably the most-touched screen on the shop floor.
