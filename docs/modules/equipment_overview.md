# equipment_overview

**Path**: `lib/web_app_template/equipment_overview/`
**Category**: Equipment

## Purpose
Main landing page after login. Displays a list/grid of all equipment in the
factory with their current status, basic KPIs, and quick navigation to
detail views. This is the default route after a successful login
(`context.goNamedAuth('EquipmentOverview')`).

## Firestore collections
- `equipments` (read) — primary data source

## Key files
- `equipment_overview_widget.dart`
- `equipment_overview_model.dart`

## Related modules
- [equipment_details](equipment_details.md) — drill-down target
- [equipment_settings](equipment_settings.md)
- [side_nav](side_nav.md)

## Notes
- Default landing screen for all roles after authentication.
