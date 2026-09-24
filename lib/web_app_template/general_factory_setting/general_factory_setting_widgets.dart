import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/production_line_setting_widget.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/process_setting_widget.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/abnormal_reason_setting_widget.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/shift_setting_widget.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/device_type_setting_widget.dart';
import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_setting_widget.dart';
export 'package:smartmachine365/web_app_template/general_factory_setting/equipment_category/equipment_category_setting_widget.dart';

class _GfsPageBase extends StatelessWidget {
  final String title;
  const _GfsPageBase(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.txtPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: theme.cardStroke),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Under Construction',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.txtTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GfsPlantWidget extends StatelessWidget {
  const GfsPlantWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Plant');
}

class GfsProductionAreaWidget extends StatelessWidget {
  const GfsProductionAreaWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Production Area');
}

class GfsProductionLineWidget extends StatelessWidget {
  const GfsProductionLineWidget({super.key});
  @override
  Widget build(BuildContext context) => const ProductionLineSettingWidget();
}

class GfsAbnormalReasonWidget extends StatelessWidget {
  const GfsAbnormalReasonWidget({super.key});
  @override
  Widget build(BuildContext context) => const AbnormalReasonSettingWidget();
}

class GfsEquipmentWidget extends StatelessWidget {
  const GfsEquipmentWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Equipment');
}

class GfsProcessWidget extends StatelessWidget {
  const GfsProcessWidget({super.key});
  @override
  Widget build(BuildContext context) => const ProcessSettingWidget();
}

class GfsProductWidget extends StatelessWidget {
  const GfsProductWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Product');
}

class GfsProductProcessRoutingWidget extends StatelessWidget {
  const GfsProductProcessRoutingWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Product Process Routing');
}

class GfsInstrumentDevicesWidget extends StatelessWidget {
  const GfsInstrumentDevicesWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Instrument Devices');
}

class GfsParameterSettingWidget extends StatelessWidget {
  const GfsParameterSettingWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Parameter Setting');
}

class GfsAlarmWidget extends StatelessWidget {
  const GfsAlarmWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Alarm');
}

class GfsShiftWidget extends StatelessWidget {
  const GfsShiftWidget({super.key});
  @override
  Widget build(BuildContext context) => const ShiftSettingWidget();
}

class GfsShiftCalendarWidget extends StatelessWidget {
  const GfsShiftCalendarWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Shift Calendar');
}

class GfsDowntimeCalendarWidget extends StatelessWidget {
  const GfsDowntimeCalendarWidget({super.key});
  @override
  Widget build(BuildContext context) => const _GfsPageBase('Downtime Calendar');
}

class GfsDeviceTypeWidget extends StatelessWidget {
  const GfsDeviceTypeWidget({super.key});
  @override
  Widget build(BuildContext context) => const DeviceTypeSettingWidget();
}

class GfsTnbMeterWidget extends StatelessWidget {
  const GfsTnbMeterWidget({super.key});
  @override
  Widget build(BuildContext context) => const TnbMeterSettingWidget();
}
