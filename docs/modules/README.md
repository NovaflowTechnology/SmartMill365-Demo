# Modules — Index

One markdown file per feature module under `lib/web_app_template/`. Each file
follows the same template:

- **Purpose** — what the module does
- **Firestore collections** — collections it reads/writes
- **Key files** — important files inside the module folder
- **Related modules** — modules it depends on or shares data with
- **Notes** — gotchas, in-progress work, scope flags

> **In scope** = currently editable per the team-agreed working scope
> (`tnb_e3_bill_simulator`, `kwh_tone`, `master_facility_setting`,
> `energy_details`, `card_widget`).

## By category

### Navigation & shell
- [side_nav](side_nav.md)

### Equipment / machines
- [equipment_overview](equipment_overview.md)
- [equipment_details](equipment_details.md)
- [equipment_settings](equipment_settings.md)
- [equipment_data_logger](equipment_data_logger.md)
- [equipment_alarm_data](equipment_alarm_data.md)
- [equipment_status_data](equipment_status_data.md)
- [equipment_energy_data](equipment_energy_data.md)
- [alarm_settings](alarm_settings.md)

### Energy / power
- [energy_overview](energy_overview.md)
- [energy_details](energy_details.md) *(in scope)*
- [energy_data_logger_1](energy_data_logger_1.md)
- [energy_data_logger_2](energy_data_logger_2.md)
- [energy_comparison](energy_comparison.md)
- [energy_vs_work_order](energy_vs_work_order.md)
- [energy_system_settings](energy_system_settings.md)
- [max_demand_monitoring](max_demand_monitoring.md)
- [power_factor_monitoring](power_factor_monitoring.md)
- [carbon_emission](carbon_emission.md)

### Tariff / billing
- [kwh_tone](kwh_tone.md) *(in scope)*
- [tnb_e3_bill_simulator](tnb_e3_bill_simulator.md) *(in scope)*
- [tariff_category_setup](tariff_category_setup.md)
- [master_billing_configuration](master_billing_configuration.md)

### Production / work orders
- [work_order_overview](work_order_overview.md)
- [work_order_report](work_order_report.md)
- [production_calendar](production_calendar.md)
- [production_line_k_p_i](production_line_k_p_i.md)
- [production_task_work_station](production_task_work_station.md)
- [mc_wo_qty_data_logger](mc_wo_qty_data_logger.md)
- [oee_data](oee_data.md)
- [machine_k_p_i](machine_k_p_i.md)

### Dashboards
- [factory25_dashboard](factory25_dashboard.md)
- [kanban_dashboard](kanban_dashboard.md)
- [kanban_dashboard_settings](kanban_dashboard_settings.md)

### Settings & masters
- [master_facility_setting](master_facility_setting.md) *(in scope)*
- [device_settings](device_settings.md)
- [product_settings](product_settings.md)
- [manage_user_groups](manage_user_groups.md)
- [reports](reports.md)
