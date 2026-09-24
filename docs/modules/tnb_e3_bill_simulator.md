# tnb_e3_bill_simulator

**Path**: `lib/web_app_template/tnb_e3_bill_simulator/`
**Category**: Tariff / billing
**Status**: 🟢 In scope (editable)

## Purpose
Simulator for TNB (Tenaga Nasional Berhad) E3 industrial tariff bills.
Takes the measured kWh, max demand, and power factor for a billing period
and computes the estimated bill broken down by:

- Energy charge (per tone band)
- Max demand charge
- Power factor surcharge (if applicable)
- ICPT / fuel cost adjustment
- Service tax

## Firestore collections
- TODO

## Key files
- TODO

## Related modules
- [kwh_tone](kwh_tone.md) — supplies the time-of-use rates
- [max_demand_monitoring](max_demand_monitoring.md)
- [power_factor_monitoring](power_factor_monitoring.md)
- [tariff_category_setup](tariff_category_setup.md)
- [master_billing_configuration](master_billing_configuration.md)

## Notes
- This module is **in the editable scope** for the current dev rotation.
- TODO: document the exact E3 tariff formula source (TNB tariff schedule
  reference) so future devs can verify calculations.
