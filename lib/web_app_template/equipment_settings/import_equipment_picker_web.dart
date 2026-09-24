import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'import_equipment_picker_types.dart';

Future<ExcelPickedFile?> pickEquipmentExcelFile() {
  final input = html.FileUploadInputElement()..accept = '.xlsx';
  final completer = Completer<ExcelPickedFile?>();
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    _readHtmlFile(files.first).then(completer.complete);
  });
  input.click();
  return completer.future;
}

Future<ExcelPickedFile?> _readHtmlFile(html.File file) {
  final completer = Completer<ExcelPickedFile?>();
  final reader = html.FileReader();
  reader.onLoadEnd.listen((_) {
    try {
      final result = reader.result;
      final Uint8List bytes = result is ByteBuffer
          ? result.asUint8List()
          : Uint8List.fromList((result as List).cast<int>());
      completer.complete(ExcelPickedFile(fileName: file.name, bytes: bytes));
    } catch (_) {
      completer.complete(null);
    }
  });
  reader.readAsArrayBuffer(file);
  return completer.future;
}

class _WebDropZone implements EquipmentDropZoneController {
  _WebDropZone(this._onDragOver, this._onDragLeave, this._onDrop) {
    html.document.body?.addEventListener('dragover', _onDragOver);
    html.document.body?.addEventListener('dragleave', _onDragLeave);
    html.document.body?.addEventListener('drop', _onDrop);
  }

  final html.EventListener _onDragOver;
  final html.EventListener _onDragLeave;
  final html.EventListener _onDrop;

  @override
  void dispose() {
    html.document.body?.removeEventListener('dragover', _onDragOver);
    html.document.body?.removeEventListener('dragleave', _onDragLeave);
    html.document.body?.removeEventListener('drop', _onDrop);
  }
}

EquipmentDropZoneController attachEquipmentDropZone({
  required void Function() onDragEnter,
  required void Function() onDragLeave,
  required void Function(ExcelPickedFile file) onDrop,
}) {
  void handleDragOver(html.Event e) {
    e.preventDefault();
    onDragEnter();
  }

  void handleDragLeave(html.Event e) {
    e.preventDefault();
    onDragLeave();
  }

  void handleDrop(html.Event e) {
    e.preventDefault();
    onDragLeave();
    final mouseEvent = e as html.MouseEvent;
    final files = mouseEvent.dataTransfer.files;
    if (files == null || files.isEmpty) return;
    _readHtmlFile(files.first).then((picked) {
      if (picked != null) onDrop(picked);
    });
  }

  return _WebDropZone(handleDragOver, handleDragLeave, handleDrop);
}
