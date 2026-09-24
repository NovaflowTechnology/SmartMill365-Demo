# work_order_report

**Path**: `lib/web_app_template/work_order_report/`
**Category**: Production

## Purpose
Reporting view for completed work orders — duration, output, downtime,
efficiency, and exportable summaries.

## Firestore collections
- `workOrders` (read)
- `equipments` (read)

## Key files
- `firestore_service.dart`
- `cubits/work_order_report_repository.dart`

## Related modules
- [work_order_overview](work_order_overview.md)
- [oee_data](oee_data.md)
- [reports](reports.md)

## Notes
- TODO: document export format (PDF? Excel?).
