# production_line_k_p_i

**Path**: `lib/web_app_template/production_line_k_p_i/`
**Category**: Production

## Purpose
KPIs aggregated at the production line level — output rate, yield,
downtime %, OEE rollup across equipment in the line.

## Firestore collections
- `equipments` (read; filter by `productionArea`)

## Key files
- `filter_controls_widget.dart`
- TODO: main widget

## Related modules
- [machine_k_p_i](machine_k_p_i.md)
- [oee_data](oee_data.md)
- [factory25_dashboard](factory25_dashboard.md)

## Notes
- Uses the same `productionArea` filtering pattern as `equipment_details`
  and `machine_k_p_i`.
