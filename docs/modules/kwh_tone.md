# kwh_tone

**Path**: `lib/web_app_template/kwh_tone/`
**Category**: Tariff / billing
**Status**: 🟢 In scope (editable)

## Purpose
kWh tone (tariff band) configuration. Defines the time-of-use bands —
typically peak / off-peak / shoulder — and the kWh rate for each.
Consumed by `tnb_e3_bill_simulator` to compute bill estimates.

## Firestore collections
- TODO

## Key files
- TODO

## Related modules
- [tnb_e3_bill_simulator](tnb_e3_bill_simulator.md)
- [tariff_category_setup](tariff_category_setup.md)
- [master_billing_configuration](master_billing_configuration.md)

## Notes
- This module is **in the editable scope** for the current dev rotation.
- TODO: document the tone band schema (start time, end time, rate, day type).
