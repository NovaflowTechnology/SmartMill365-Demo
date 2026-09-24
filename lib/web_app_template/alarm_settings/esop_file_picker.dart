import 'esop_file_picker_stub.dart'
    if (dart.library.html) 'esop_file_picker_web.dart' as impl;

import 'esop_file_picker_types.dart';

Future<EsopPickedFile?> pickEsopFile() => impl.pickEsopFile();
