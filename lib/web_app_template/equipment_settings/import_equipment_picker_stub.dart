import 'package:file_picker/file_picker.dart';

import 'import_equipment_picker_types.dart';

Future<ExcelPickedFile?> pickEquipmentExcelFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;
  return ExcelPickedFile(fileName: file.name, bytes: bytes);
}

class _NoopDropZone implements EquipmentDropZoneController {
  @override
  void dispose() {}
}

/// Dragging a file onto the window isn't a native-platform concept, so this
/// never fires [onDrop] — picking is done through [pickEquipmentExcelFile].
EquipmentDropZoneController attachEquipmentDropZone({
  required void Function() onDragEnter,
  required void Function() onDragLeave,
  required void Function(ExcelPickedFile file) onDrop,
}) =>
    _NoopDropZone();
