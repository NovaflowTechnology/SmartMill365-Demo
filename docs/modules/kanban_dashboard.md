# kanban_dashboard

**Path**: `lib/web_app_template/kanban_dashboard/`
**Category**: Dashboards

## Purpose
Kanban-style board view of production work orders or tasks — columns
typically represent statuses (To Do / In Progress / Done) and cards
represent work orders.

## Firestore collections
- TODO

## Key files
- `kanban_dashboard_widget.dart`
- `kanban_dashboard_model.dart`

## Related modules
- [kanban_dashboard_settings](kanban_dashboard_settings.md)
- [work_order_overview](work_order_overview.md)

## Notes
- Uses session storage (per the grep results) — likely caches column config.
