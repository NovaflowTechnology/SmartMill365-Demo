import 'dart:async';
import 'dart:html' as html;

import 'package:excel/excel.dart';

import 'esop_file_picker_types.dart';

Future<EsopPickedFile?> pickEsopFile() async {
  final input = html.FileUploadInputElement()..accept = '.csv,.xlsx'..click();

  final completer = Completer<EsopPickedFile?>();

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      try {
        if (file.name.endsWith('.csv')) {
          final content = reader.result as String? ?? '';
          completer.complete(
              EsopPickedFile(fileName: file.name, content: content));
          return;
        }
        if (file.name.endsWith('.xlsx')) {
          final excel = Excel.decodeBytes(reader.result as List<int>);
          final rows = <String>[];
          var n = 1;
          for (final t in excel.tables.keys) {
            final table = excel.tables[t];
            if (table == null) continue;
            for (var i = 1; i < table.rows.length; i++) {
              rows.add(
                '$n. ${table.rows[i].skip(1).map((c) => c?.value.toString() ?? '').join(' ')}',
              );
              n++;
            }
          }
          completer.complete(
              EsopPickedFile(fileName: file.name, content: rows.join('\n')));
          return;
        }
        completer.complete(null);
      } catch (_) {
        completer.complete(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
