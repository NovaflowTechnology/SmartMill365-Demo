import 'package:flutter/material.dart';

import '../../models/settlement_masters.dart';
import 'setting_inputs.dart';

/// A meter picker over Master Facilities.
///
/// A saved meter that is no longer registered stays selectable and says so,
/// rather than the dropdown quietly showing nothing and the next save
/// dropping the mapping.
class DeviceDropdown extends StatelessWidget {
  const DeviceDropdown({
    super.key,
    required this.value,
    required this.devices,
    required this.onChanged,
    this.allowNone = false,
    this.solarFirst = false,
    this.noneLabel = '— Not mapped —',
  });

  final String value;
  final List<DeviceRef> devices;
  final ValueChanged<String>? onChanged;
  final bool allowNone;

  /// Solar meters listed first, for pickers where one is the likely answer.
  final bool solarFirst;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    final list = [...devices];
    if (solarFirst) {
      list.sort((a, b) {
        if (a.isSolar != b.isSolar) return a.isSolar ? -1 : 1;
        return a.id.compareTo(b.id);
      });
    }
    final options = <SettingOption<String>>[
      if (allowNone) SettingOption('', noneLabel),
      if (value.isNotEmpty && !list.any((d) => d.id == value))
        SettingOption(value, '$value · not in Master Facilities'),
      for (final d in list) SettingOption(d.id, d.label),
    ];
    return SettingDropdown<String>(
      value: value,
      options: options,
      onChanged: onChanged,
      hint: 'Select meter',
    );
  }
}
