import 'dart:convert';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '/services/app_config.dart';
import 'import_equipment_picker.dart';
import 'package:smartmachine365/utils/report_exporter_saver_io.dart'
    if (dart.library.html) 'package:smartmachine365/utils/report_exporter_saver_web.dart'
    as saver;

/// Bulk import/update equipment from an .xlsx file. Columns map to the same
/// fields used in the Add/Edit Equipment dialogs. Rows whose "Equipment ID"
/// matches an existing equipment update that record; unmatched IDs create
/// a new one.
class ImportEquipmentExcelDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingEquipments;
  final String userId;
  final String factoryId;
  final VoidCallback onImported;

  const ImportEquipmentExcelDialog({
    super.key,
    required this.existingEquipments,
    required this.userId,
    required this.factoryId,
    required this.onImported,
  });

  @override
  State<ImportEquipmentExcelDialog> createState() => _ImportEquipmentExcelDialogState();
}

class _ImportEquipmentExcelDialogState extends State<ImportEquipmentExcelDialog> {
  String? _fileName;
  List<Map<String, String>> _rows = [];
  bool _importing = false;
  int _doneCount = 0;
  final List<String> _errors = [];
  bool _finished = false;
  bool _dragOver = false;
  EquipmentDropZoneController? _dropZone;

  @override
  void initState() {
    super.initState();
    _dropZone = attachEquipmentDropZone(
      onDragEnter: () {
        if (!_dragOver) setState(() => _dragOver = true);
      },
      onDragLeave: () {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onDrop: (file) {
        setState(() => _dragOver = false);
        _processPickedFile(file);
      },
    );
  }

  @override
  void dispose() {
    _dropZone?.dispose();
    super.dispose();
  }

  static const Map<String, String> _headerAliases = {
    'equipment id': 'equipment_id',
    'equipment name': 'name',
    'name': 'name',
    'serial no': 'serialNo',
    'serial no.': 'serialNo',
    'model type': 'modelType',
    'equipment type': 'equipment_type',
    'equipment category': 'equipment_category',
    'production line': 'production_line',
    'production area': 'productionArea',
    'plant': 'factory',
    'factory': 'factory',
    'pic': 'PIC',
    'purchase date': 'purchaseDate',
    'warranty expiry date': 'warrantyDate',
    'warranty date': 'warrantyDate',
    'enable oee': 'enableOEE',
    'enable energy': 'enableEnergy',
    'equipment process': 'equipmentProcess',
  };

  Future<void> _downloadTemplate() async {
    final workbook = xls.Excel.createExcel();
    final sheet = workbook['Equipment'];
    workbook.setDefaultSheet('Equipment');
    for (final name in workbook.sheets.keys.toList()) {
      if (name != 'Equipment') workbook.delete(name);
    }

    const headers = [
      'Equipment ID', 'Equipment Name', 'Serial No', 'Model Type', 'Equipment Type',
      'Equipment Category', 'Production Line', 'Production Area', 'Plant', 'PIC',
      'Purchase Date', 'Warranty Expiry Date', 'Enable OEE', 'Enable Energy', 'Equipment Process',
    ];
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    const sampleRow = [
      'EQ-1001', 'CNC Machine A', '#10001', 'XM-200', 'CNC', 'Machining',
      'Line 1', 'Area A', 'Plant A', 'John Tan', '2023-01-15', '2026-01-15',
      'true', 'true', 'Process A',
    ];
    sheet.appendRow(sampleRow.map((v) => xls.TextCellValue(v)).toList());

    final bytes = workbook.save();
    if (bytes == null) return;

    final path = await saver.saveExcelBytes(
      bytes: bytes,
      fileName: 'equipment template.xlsx',
    );
    if (!mounted || kIsWeb) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(path != null ? 'Template saved to: $path' : 'Template saved')),
    );
  }

  Future<void> _pickFile() async {
    final file = await pickEquipmentExcelFile();
    if (file == null) return;
    _processPickedFile(file);
  }

  void _processPickedFile(ExcelPickedFile file) {
    if (!file.fileName.toLowerCase().endsWith('.xlsx')) {
      setState(() => _errors.add('${file.fileName}: only .xlsx files are supported'));
      return;
    }
    try {
      final excel = xls.Excel.decodeBytes(file.bytes);
      if (excel.tables.isEmpty) return;
      final table = excel.tables[excel.tables.keys.first];
      if (table == null || table.rows.isEmpty) return;

      final headerRow = table.rows.first;
      final headers = headerRow
          .map((c) => (c?.value?.toString() ?? '').trim().toLowerCase())
          .toList();

      final parsed = <Map<String, String>>[];
      for (var r = 1; r < table.rows.length; r++) {
        final row = table.rows[r];
        final map = <String, String>{};
        for (var c = 0; c < headers.length && c < row.length; c++) {
          final key = _headerAliases[headers[c]];
          if (key == null) continue;
          map[key] = (row[c]?.value?.toString() ?? '').trim();
        }
        if (map.values.any((v) => v.isNotEmpty)) parsed.add(map);
      }

      setState(() {
        _fileName = file.fileName;
        _rows = parsed;
        _errors.clear();
        _finished = false;
      });
    } catch (e) {
      setState(() => _errors.add('Failed to read file: $e'));
    }
  }

  String? _normalizeDate(String raw) {
    if (raw.isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct.toIso8601String().split('T').first;
    final viaSpace = DateTime.tryParse(raw.split(' ').first);
    if (viaSpace != null) return viaSpace.toIso8601String().split('T').first;
    return null;
  }

  // Field labels shown in the per-item duplicate comparison dialog, in display order.
  static const _compareFields = <String, String>{
    'name': 'Equipment Name',
    'serialNo': 'Serial No',
    'modelType': 'Model Type',
    'equipment_type': 'Equipment Type',
    'equipment_category': 'Equipment Category',
    'production_line': 'Production Line',
    'factory': 'Plant',
    'PIC': 'PIC',
    'purchaseDate': 'Purchase Date',
    'warrantyDate': 'Warranty Expiry Date',
  };

  Map<String, String> _compareValuesFromRow(Map<String, String> row) =>
      {for (final k in _compareFields.keys) k: row[k] ?? ''};

  Map<String, String> _compareValuesFromExisting(Map<String, dynamic> e) => {
        'name': e['name']?.toString() ?? '',
        'serialNo': e['serialNo']?.toString() ?? '',
        'modelType': e['modelType']?.toString() ?? '',
        'equipment_type': e['equipment_type']?.toString() ?? e['equipmentType']?.toString() ?? '',
        'equipment_category': e['equipment_category']?.toString() ?? e['equipmentCategory']?.toString() ?? '',
        'production_line': e['production_line']?.toString() ?? e['productionLine']?.toString() ?? '',
        'factory': e['factory']?.toString() ?? '',
        'PIC': e['PIC']?.toString() ?? '',
        'purchaseDate': e['purchaseDate']?.toString() ?? '',
        'warrantyDate': e['warrantyDate']?.toString() ?? '',
      };

  // Shows one duplicate at a time — like Windows' file-copy conflict prompt —
  // with a field-by-field comparison and a "do this for all" checkbox so the
  // user isn't forced to click through every single conflict individually.
  Future<Map<String, dynamic>?> _resolveDuplicateDialog({
    required String title,
    required String subtitle,
    required Map<String, String> existingValues,
    required Map<String, String> newValues,
  }) async {
    const accent = Color(0xFF31ECFC);
    var applyToAll = false;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        final diffFields = _compareFields.keys.where((k) => (existingValues[k] ?? '') != (newValues[k] ?? '')).toList();
        return Dialog(
          backgroundColor: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.difference_outlined, size: 18, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx, 'skip'),
                      child: const Icon(Icons.close, size: 18, color: Colors.white70),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('This data already exists. Review the fields below and choose what to do.',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white60)),
                  const SizedBox(height: 14),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(4),
                      child: Table(
                        columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            children: [
                              _dupHeaderCell('Field'),
                              _dupHeaderCell('Existing'),
                              _dupHeaderCell('New (file)'),
                            ],
                          ),
                          for (final f in diffFields)
                            TableRow(children: [
                              _dupCell(_compareFields[f]!, Colors.white60),
                              _dupCell(existingValues[f]!.isEmpty ? '—' : existingValues[f]!, Colors.white70),
                              _dupCell(newValues[f]!.isEmpty ? '—' : newValues[f]!, accent, bold: true),
                            ]),
                          if (diffFields.isEmpty)
                            TableRow(children: [
                              _dupCell('—', Colors.white38),
                              _dupCell('No field differences', Colors.white38),
                              _dupCell('', Colors.white38),
                            ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setLocal(() => applyToAll = !applyToAll),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: applyToAll,
                          onChanged: (v) => setLocal(() => applyToAll = v ?? false),
                          activeColor: accent,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Do this for all remaining duplicates',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    InkWell(
                      onTap: () => Navigator.pop(ctx, 'skip'),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                        child: Center(child: Text('Skip', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => Navigator.pop(ctx, 'replace'),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text('Replace', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      }),
    );
    if (action == null) return null;
    return {'action': action, 'applyToAll': applyToAll};
  }

  Widget _dupHeaderCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
      );

  Widget _dupCell(String text, Color color, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      );

  Future<void> _import() async {
    setState(() {
      _importing = true;
      _doneCount = 0;
      _errors.clear();
    });

    final seenIds = <String>{};
    final duplicateIds = <String>{};
    final seenSerials = <String>{};
    final duplicateSerials = <String>{};
    for (final row in _rows) {
      final id = row['equipment_id'] ?? '';
      if (id.isNotEmpty && !seenIds.add(id)) duplicateIds.add(id);
      final serial = row['serialNo'] ?? '';
      if (serial.isNotEmpty && !seenSerials.add(serial)) duplicateSerials.add(serial);
    }

    // For each duplicated ID/Serial, the last row in the file is treated as
    // the "latest" version — used below if the user chooses to keep it.
    final firstIndexForId = <String, int>{};
    final lastIndexForId = <String, int>{};
    final firstIndexForSerial = <String, int>{};
    final lastIndexForSerial = <String, int>{};
    for (var i = 0; i < _rows.length; i++) {
      final id = _rows[i]['equipment_id'] ?? '';
      if (id.isNotEmpty) {
        firstIndexForId.putIfAbsent(id, () => i);
        lastIndexForId[id] = i;
      }
      final serial = _rows[i]['serialNo'] ?? '';
      if (serial.isNotEmpty) {
        firstIndexForSerial.putIfAbsent(serial, () => i);
        lastIndexForSerial[serial] = i;
      }
    }

    // Rows whose Equipment ID isn't in the system yet, but whose Serial No
    // already belongs to a different existing equipment.
    final existingList = widget.existingEquipments.cast<Map<String, dynamic>>();
    final conflictRows = <int>{};
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final equipmentId = row['equipment_id'] ?? '';
      final serialNo = row['serialNo'] ?? '';
      if (duplicateIds.contains(equipmentId) || duplicateSerials.contains(serialNo) || serialNo.isEmpty) continue;
      final matchesById = existingList.any((e) => equipmentId.isNotEmpty && (e['equipment_id']?.toString() ?? '') == equipmentId);
      if (matchesById) continue;
      final matchesBySerial = existingList.any((e) => (e['serialNo']?.toString() ?? '') == serialNo);
      if (matchesBySerial) conflictRows.add(i);
    }

    // Resolve every conflict one item at a time (like the Windows copy-file
    // prompt), honoring "apply to all" once the user checks it.
    String? applyAllAction; // 'replace' | 'skip' once set, used for every remaining item
    final idDecision = <String, String>{}; // equipment_id -> 'replace'/'skip'
    final serialDecision = <String, String>{}; // serialNo -> 'replace'/'skip'
    final conflictDecision = <int, String>{}; // row index -> 'replace'/'skip'

    if (mounted) {
      for (final id in duplicateIds) {
        if (applyAllAction != null) {
          idDecision[id] = applyAllAction;
          continue;
        }
        final firstRow = _rows[firstIndexForId[id]!];
        final lastRow = _rows[lastIndexForId[id]!];
        final dialogResult = await _resolveDuplicateDialog(
          title: 'Duplicate Equipment ID',
          subtitle: 'Equipment ID $id appears more than once in this file.',
          existingValues: _compareValuesFromRow(firstRow),
          newValues: _compareValuesFromRow(lastRow),
        );
        if (dialogResult != null && dialogResult['applyToAll'] == true) {
          applyAllAction = dialogResult['action'] as String;
        }
        idDecision[id] = applyAllAction ?? (dialogResult?['action'] as String? ?? 'skip');
      }
      for (final serial in duplicateSerials) {
        if (applyAllAction != null) {
          serialDecision[serial] = applyAllAction;
          continue;
        }
        final firstRow = _rows[firstIndexForSerial[serial]!];
        final lastRow = _rows[lastIndexForSerial[serial]!];
        final dialogResult = await _resolveDuplicateDialog(
          title: 'Duplicate Serial No',
          subtitle: 'Serial No $serial appears more than once in this file.',
          existingValues: _compareValuesFromRow(firstRow),
          newValues: _compareValuesFromRow(lastRow),
        );
        if (dialogResult != null && dialogResult['applyToAll'] == true) {
          applyAllAction = dialogResult['action'] as String;
        }
        serialDecision[serial] = applyAllAction ?? (dialogResult?['action'] as String? ?? 'skip');
      }
      for (final i in conflictRows) {
        if (applyAllAction != null) {
          conflictDecision[i] = applyAllAction;
          continue;
        }
        final row = _rows[i];
        final serialNo = row['serialNo'] ?? '';
        final equipmentId = row['equipment_id'] ?? '';
        final matchedExisting = existingList.firstWhere((e) => (e['serialNo']?.toString() ?? '') == serialNo, orElse: () => {});
        final dialogResult = await _resolveDuplicateDialog(
          title: 'Similar Equipment Detected',
          subtitle: 'Serial No $serialNo (Equipment ID $equipmentId) already belongs to another equipment record.',
          existingValues: _compareValuesFromExisting(matchedExisting),
          newValues: _compareValuesFromRow(row),
        );
        if (dialogResult != null && dialogResult['applyToAll'] == true) {
          applyAllAction = dialogResult['action'] as String;
        }
        conflictDecision[i] = applyAllAction ?? (dialogResult?['action'] as String? ?? 'skip');
      }
    }

    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final equipmentId = row['equipment_id'] ?? '';
      final rowLabel = equipmentId.isNotEmpty ? equipmentId : 'Row ${i + 2}';

      final serialNo = row['serialNo'] ?? '';

      if (duplicateIds.contains(equipmentId)) {
        final keepThisOne = idDecision[equipmentId] == 'replace' && lastIndexForId[equipmentId] == i;
        if (!keepThisOne) {
          final reason = idDecision[equipmentId] == 'replace' ? 'an older duplicate, the latest row was kept instead' : 'this Equipment ID appears more than once in the file, fix the duplicate rows and re-import';
          _errors.add('$rowLabel: skipped — $reason');
          setState(() => _doneCount++);
          continue;
        }
      }
      if (duplicateSerials.contains(serialNo)) {
        final keepThisOne = serialDecision[serialNo] == 'replace' && lastIndexForSerial[serialNo] == i;
        if (!keepThisOne) {
          final reason = serialDecision[serialNo] == 'replace' ? 'an older duplicate, the latest row was kept instead' : 'Serial No $serialNo appears more than once in the file, fix the duplicate rows and re-import';
          _errors.add('$rowLabel: skipped — $reason');
          setState(() => _doneCount++);
          continue;
        }
      }

      final name = row['name'] ?? '';
      final modelType = row['modelType'] ?? '';
      final purchaseDate = _normalizeDate(row['purchaseDate'] ?? '');
      final warrantyDate = _normalizeDate(row['warrantyDate'] ?? '');

      if (name.isEmpty || serialNo.isEmpty || modelType.isEmpty || purchaseDate == null || warrantyDate == null) {
        _errors.add('$rowLabel: missing/invalid required field (Name, Serial No, Model Type, Purchase Date, Warranty Expiry Date)');
        setState(() => _doneCount++);
        continue;
      }

      if (conflictRows.contains(i) && conflictDecision[i] != 'replace') {
        _errors.add('$rowLabel: skipped — Serial No $serialNo already belongs to another equipment');
        setState(() => _doneCount++);
        continue;
      }

      var existing = existingList.firstWhere(
        (e) => equipmentId.isNotEmpty && (e['equipment_id']?.toString() ?? '') == equipmentId,
        orElse: () => {},
      );
      if (existing.isEmpty && conflictRows.contains(i)) {
        existing = existingList.firstWhere(
          (e) => (e['serialNo']?.toString() ?? '') == serialNo,
          orElse: () => {},
        );
      }

      final factoryValue = (row['factory']?.isNotEmpty ?? false) ? row['factory']! : widget.factoryId;
      final equipmentType = row['equipment_type'] ?? '';
      final equipmentCategory = row['equipment_category'] ?? '';
      final productionLine = row['production_line'] ?? '';
      final enableOEE = (row['enableOEE'] ?? '').toLowerCase() == 'true' || row['enableOEE'] == '1';
      final enableEnergy = (row['enableEnergy'] ?? '').toLowerCase() == 'true' || row['enableEnergy'] == '1';

      final payload = <String, dynamic>{
        'name': name,
        'serialNo': serialNo,
        'modelType': modelType,
        'productionArea': row['productionArea'] ?? '',
        'purchaseDate': purchaseDate,
        'warrantyDate': warrantyDate,
        'PIC': row['PIC'] ?? '',
        'factory': factoryValue,
        'workOrder': <String>[],
        'equipmentProcess': row['equipmentProcess'] ?? '',
        'equipment_type': equipmentType,
        'equipmentType': equipmentType,
        'device_type': equipmentType,
        'type': equipmentType,
        'equipment_category': equipmentCategory,
        'equipmentCategory': equipmentCategory,
        'production_line': productionLine,
        'productionLine': productionLine,
        'enableOEE': enableOEE,
        'enableEnergy': enableEnergy,
      };

      try {
        http.Response res;
        if (existing.isNotEmpty) {
          payload['id'] = existing['id'];
          payload['initialSerialNo'] = existing['serialNo'] ?? serialNo;
          res = await http.put(
            Uri.parse('${AppConfig.dataApiBaseSafe}/equipment/${existing['id']}'),
            headers: AppConfig.headers,
            body: json.encode(payload),
          );
        } else {
          payload['userId'] = widget.userId;
          payload['equipment_id'] = equipmentId;
          payload['product'] = '0';
          res = await http.post(
            Uri.parse('${AppConfig.dataApiBaseSafe}/equipment/add'),
            headers: AppConfig.headers,
            body: json.encode(payload),
          );
        }
        if (res.statusCode != 200 && res.statusCode != 201) {
          String msg = res.body;
          try {
            msg = (jsonDecode(res.body) as Map)['error']?.toString() ?? res.body;
          } catch (_) {}
          _errors.add('$rowLabel: $msg');
        }
      } catch (e) {
        _errors.add('$rowLabel: $e');
      }

      setState(() => _doneCount++);
    }

    setState(() {
      _importing = false;
      _finished = true;
    });
    widget.onImported();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text('Import Equipment from Excel',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 18, color: Colors.white70),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                'Columns: Equipment ID, Equipment Name, Serial No, Model Type, Equipment Type, Equipment Category, '
                'Production Line, Production Area, Plant, PIC, Purchase Date (YYYY-MM-DD), Warranty Expiry Date (YYYY-MM-DD), '
                'Enable OEE, Enable Energy, Equipment Process. Rows matching an existing Equipment ID get updated; new IDs get created.',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60, height: 1.5),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _downloadTemplate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_outlined, size: 14, color: Color(0xFF31ECFC)),
                    const SizedBox(width: 6),
                    Text('Download template (.xlsx)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF31ECFC),
                          decoration: TextDecoration.underline,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _importing ? null : _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
                  decoration: BoxDecoration(
                    color: _dragOver ? const Color(0xFF31ECFC).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _dragOver ? const Color(0xFF31ECFC) : Colors.white24,
                      width: _dragOver ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _dragOver ? Icons.file_download_outlined : Icons.upload_file,
                        size: 26,
                        color: const Color(0xFF31ECFC),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fileName ??
                            (_dragOver
                                ? 'Drop file to import'
                                : (kIsWeb
                                    ? 'Drag & drop .xlsx file here, or click to choose'
                                    : 'Tap to choose an .xlsx file')),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                      ),
                      if (_rows.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${_rows.length} rows', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
                      ],
                    ],
                  ),
                ),
              ),
              if (_importing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _rows.isEmpty ? null : _doneCount / _rows.length,
                  color: const Color(0xFF31ECFC),
                ),
                const SizedBox(height: 6),
                Text('Importing $_doneCount / ${_rows.length}…',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
              ],
              if (_finished) ...[
                const SizedBox(height: 16),
                Text(
                  _errors.isEmpty
                      ? 'Imported ${_rows.length} of ${_rows.length} rows successfully.'
                      : 'Imported ${_rows.length - _errors.length} of ${_rows.length} rows. ${_errors.length} failed.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _errors.isEmpty ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  ),
                ),
              ],
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _errors
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(e, style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                    child: Center(
                        child: Text(_finished ? 'Close' : 'Cancel', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70))),
                  ),
                ),
                const SizedBox(width: 10),
                if (!_finished)
                  Opacity(
                    opacity: (_rows.isNotEmpty && !_importing) ? 1 : 0.4,
                    child: InkWell(
                      onTap: (_rows.isNotEmpty && !_importing) ? _import : null,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFF31ECFC), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text('Import ${_rows.length} Rows',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
