# product_settings

**Path**: `lib/web_app_template/product_settings/`
**Category**: Settings & masters

## Purpose
Product master data — defines the products (SKUs) being manufactured,
their cycle times, target quantities, and the process route (which
equipment they pass through).

## Firestore collections
- `products` (read/write)
- `equipments` (read)
- `processRoutes` (read/write)

## Key files
- `firestore_service.dart`

## Related modules
- [work_order_overview](work_order_overview.md) — work orders reference products
- [production_task_work_station](production_task_work_station.md)
- [equipment_settings](equipment_settings.md)

## Notes
- `processRoutes` ties products to equipment sequences — central concept
  for production scheduling.
