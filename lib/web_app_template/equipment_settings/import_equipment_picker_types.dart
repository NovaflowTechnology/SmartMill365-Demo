import 'dart:typed_data';

class ExcelPickedFile {
  final String fileName;
  final Uint8List bytes;
  const ExcelPickedFile({required this.fileName, required this.bytes});
}

/// Handle for the web drag-and-drop listeners. Dropping a file onto the app
/// window is a browser-only concept, so on native platforms [attachEquipmentDropZone]
/// hands back a controller whose [dispose] is a no-op.
abstract class EquipmentDropZoneController {
  void dispose();
}
