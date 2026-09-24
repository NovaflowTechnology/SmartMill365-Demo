import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/view.dart';

class AlarmSettingsWidget extends StatelessWidget {
  const AlarmSettingsWidget({super.key, required this.companyID, required this.userRole});
  final String companyID;
  final String userRole;

  @override
  Widget build(BuildContext context) => AlarmView(companyID: companyID, userRole: userRole);
}
