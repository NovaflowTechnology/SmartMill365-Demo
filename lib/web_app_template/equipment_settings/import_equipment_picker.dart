import 'import_equipment_picker_stub.dart'
    if (dart.library.html) 'import_equipment_picker_web.dart' as impl;

import 'import_equipment_picker_types.dart';

export 'import_equipment_picker_types.dart';

Future<ExcelPickedFile?> pickEquipmentExcelFile() =>
    impl.pickEquipmentExcelFile();

EquipmentDropZoneController attachEquipmentDropZone({
  required void Function() onDragEnter,
  required void Function() onDragLeave,
  required void Function(ExcelPickedFile file) onDrop,
}) =>
    impl.attachEquipmentDropZone(
      onDragEnter: onDragEnter,
      onDragLeave: onDragLeave,
      onDrop: onDrop,
    );
