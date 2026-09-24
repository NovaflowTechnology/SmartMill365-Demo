# master_facility_setting

**Path**: `lib/web_app_template/master_facility_setting/`
**Category**: Settings & masters
**Status**: 🟢 In scope (editable)

## Purpose
Top-level facility master data — defines factories, sites, production
areas, and the hierarchy used by every other module to scope filters
(e.g. `productionArea` on equipment).

## Firestore collections
- TODO (likely `factories`, `productionAreas` — see `device_settings`
  which references both)

## Key files
- TODO

## Related modules
- [device_settings](device_settings.md) — references `factories` and `productionAreas`
- [equipment_settings](equipment_settings.md)
- [equipment_overview](equipment_overview.md)

## Notes
- This module is **in the editable scope** for the current dev rotation.
- Changes to facility hierarchy ripple across the whole app — be careful
  when renaming or removing entries.
