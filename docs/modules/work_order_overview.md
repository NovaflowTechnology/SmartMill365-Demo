# work_order_overview

**Path**: `lib/web_app_template/work_order_overview/`
**Category**: Production

## Purpose
List of work orders with filters by status, equipment, date range, and
product. Entry point for managing production jobs.

## Firestore collections
- `workOrders` (read/write)
- `equipments` (read)
- `products` (read)
- `downTimeCodes` (read)

## Key files
- `work_order_overview_widget.dart`
- `firestore_service.dart`
- `cubits/work_order_repository.dart` — uses BLoC/Cubit pattern

## Related modules
- [work_order_report](work_order_report.md)
- [production_task_work_station](production_task_work_station.md)
- [equipment_overview](equipment_overview.md)

## Notes
- Uses the cubit pattern (`flutter_bloc`) — see `cubits/` subfolder.
