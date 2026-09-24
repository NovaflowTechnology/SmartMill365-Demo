import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';

import 'report_exporter_saver_io.dart'
    if (dart.library.html) 'report_exporter_saver_web.dart' as saver;

class ReportExporter {
  // Export to PDF with Charts
  static Future<void> exportToPdf({
    required BuildContext context,
    required Map<String, dynamic> reportData,
    required String? selectedShift,
    required String? selectedMachine,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();

      // Page 1: Summary
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildPdfHeader(),
              pw.SizedBox(height: 16),
              _buildFilterInfo(selectedShift, selectedMachine, startDate, endDate),
              pw.SizedBox(height: 24),
              pw.Text(
                'Key Performance Indicators',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              _buildMetricsTable(reportData),
            ];
          },
        ),
      );

      // Page 2: Overview Charts
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Overview Charts',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                if (reportData['oeeChartImage'] != null) ...[
                  pw.Text('OEE Trend', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 250,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['oeeChartImage'])),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (reportData['performanceChartImage'] != null) ...[
                  pw.Text('Output Comparison', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 250,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['performanceChartImage'])),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Page 3: Availability and Quality Charts
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (reportData['availabilityChartImage'] != null) ...[
                  pw.Text('Availability Analysis', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 250,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['availabilityChartImage'])),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (reportData['qualityChartImage'] != null) ...[
                  pw.Text('Quality Metrics', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 250,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['qualityChartImage'])),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Page 4: Machine Comparison Charts
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Machine Comparison Charts',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                if (reportData['machineOeeChartImage'] != null) ...[
                  pw.Text('OEE by Machine', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['machineOeeChartImage'])),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (reportData['machinePerformanceChartImage'] != null) ...[
                  pw.Text('Output by Machine', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['machinePerformanceChartImage'])),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Page 5: More Machine Charts
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (reportData['machineAvailabilityChartImage'] != null) ...[
                  pw.Text('Availability by Machine', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['machineAvailabilityChartImage'])),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (reportData['machineQualityChartImage'] != null) ...[
                  pw.Text('Quality by Machine', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Image(pw.MemoryImage(reportData['machineQualityChartImage'])),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Page 6: Data Tables
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Text(
                'Detailed Data Tables',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'OEE Performance by Machine',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              _buildOeeTable(reportData['oeeData'], selectedShift),
              pw.SizedBox(height: 24),
              pw.Text(
                'Output Performance by Machine',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              _buildPerformanceTable(reportData['performanceData'], selectedShift),
            ];
          },
        ),
      );

      // Download the PDF rather than opening the print dialog. layoutPdf sends
      // the user to a printer picker, which is not what a report export is for.
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Report.pdf',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report with charts generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Export to Excel
  static Future<void> exportToExcel({
    required BuildContext context,
    required Map<String, dynamic> reportData,
    required String? selectedShift,
    required String? selectedMachine,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      _createSummarySheet(excel, reportData, selectedShift, selectedMachine, startDate, endDate);
      _createOeeSheet(excel, reportData['oeeData'], selectedShift);
      _createPerformanceSheet(excel, reportData['performanceData'], selectedShift);
      _createAvailabilitySheet(excel, reportData['availabilityData'], selectedShift);
      _createQualitySheet(excel, reportData['qualityData'], selectedShift);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ProductionKPI_Report_$timestamp.xlsx';
      final fileBytes = excel.save();

      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final filePath =
          await saver.saveExcelBytes(bytes: fileBytes, fileName: fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb
              ? 'Excel report downloaded: $fileName'
              : 'Excel report saved to: $filePath'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: kIsWeb ? 3 : 5),
          action: kIsWeb
              ? null
              : SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating Excel: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // PDF Helper Methods
  static pw.Widget _buildPdfHeader() {
    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Production Line KPI Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: ${DateTime.now().toString().substring(0, 19)}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Divider(thickness: 2),
        ],
      ),
    );
  }

  static pw.Widget _buildFilterInfo(String? selectedShift, String? selectedMachine, DateTime? startDate, DateTime? endDate) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Report Filters', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Shift: ${selectedShift ?? "All Shifts"}')),
              pw.Expanded(child: pw.Text('Machine: ${selectedMachine ?? "All Machines"}')),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Date Range: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}'),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricsTable(Map<String, dynamic> reportData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        _buildMetricRow('Total Machines', '${reportData['totalMachines'] ?? 0}'),
        _buildMetricRow('Average OEE', '${(reportData['averageOee'] ?? 0.0).toStringAsFixed(2)}%'),
        _buildMetricRow('Total Output', '${reportData['totalOutput'] ?? 0}'),
        _buildMetricRow('Average Uptime', '${(reportData['uptime'] ?? 0.0).toStringAsFixed(2)}%'),
      ],
    );
  }

  static pw.TableRow _buildMetricRow(String metric, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(metric),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static pw.Widget _buildOeeTable(Map<String, dynamic>? oeeData, String? selectedShift) {
    if (oeeData == null || oeeData['data'] == null) {
      return pw.Text('No OEE data available');
    }

    List<dynamic> data = oeeData['data'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: pw.FixedColumnWidth(100),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Machine ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Morning OEE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Night OEE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Average OEE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...data
            .map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(item['MachineID']?.toString() ?? ''),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${item['Morning_OEE']?.toStringAsFixed(2) ?? '0.00'}%'),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${item['Night_OEE']?.toStringAsFixed(2) ?? '0.00'}%'),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${((item['Morning_OEE'] ?? 0 + item['Night_OEE'] ?? 0) / 2).toStringAsFixed(2)}%'),
                    ),
                  ],
                ))
            .toList(),
      ],
    );
  }

  static pw.Widget _buildPerformanceTable(Map<String, dynamic>? performanceData, String? selectedShift) {
    if (performanceData == null || performanceData['data'] == null) {
      return pw.Text('No Performance data available');
    }

    List<dynamic> data = performanceData['data'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: pw.FixedColumnWidth(100),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Machine ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Morning Output', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Night Output', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Total Output', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...data
            .map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(item['MachineID']?.toString() ?? ''),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${item['Morning_NGQuantity'] ?? 0}'),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${item['Night_NGQuantity'] ?? 0}'),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('${(item['Morning_NGQuantity'] ?? 0) + (item['Night_NGQuantity'] ?? 0)}'),
                    ),
                  ],
                ))
            .toList(),
      ],
    );
  }

  // Excel Helper Methods
  static void _createSummarySheet(
    Excel excel,
    Map<String, dynamic> reportData,
    String? selectedShift,
    String? selectedMachine,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final sheet = excel['Summary'];

    // Header - Wrap all values in TextCellValue
    sheet.appendRow([TextCellValue('Production Line KPI Report')]);
    sheet.appendRow([TextCellValue('Generated: ${DateTime.now().toString().substring(0, 19)}')]);
    sheet.appendRow([TextCellValue('')]);

    // Filters
    sheet.appendRow([TextCellValue('Report Filters')]);
    sheet.appendRow([TextCellValue('Shift:'), TextCellValue(selectedShift ?? 'All Shifts')]);
    sheet.appendRow([TextCellValue('Machine:'), TextCellValue(selectedMachine ?? 'All Machines')]);
    sheet.appendRow([TextCellValue('Date Range:'), TextCellValue('${_formatDate(startDate!)} - ${_formatDate(endDate!)}')]);
    sheet.appendRow([TextCellValue('')]);

    // Metrics
    sheet.appendRow([TextCellValue('Key Performance Indicators')]);
    sheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    sheet.appendRow([TextCellValue('Total Machines'), IntCellValue(reportData['totalMachines'] ?? 0)]);
    sheet.appendRow([TextCellValue('Average OEE'), TextCellValue('${(reportData['averageOee'] ?? 0.0).toStringAsFixed(2)}%')]);
    sheet.appendRow([TextCellValue('Total Output'), IntCellValue(reportData['totalOutput'] ?? 0)]);
    sheet.appendRow([TextCellValue('Average Uptime'), TextCellValue('${(reportData['uptime'] ?? 0.0).toStringAsFixed(2)}%')]);
  }

  static void _createOeeSheet(Excel excel, Map<String, dynamic>? oeeData, String? selectedShift) {
    final sheet = excel['OEE Data'];

    if (oeeData == null || oeeData['data'] == null) return;

    List<dynamic> data = oeeData['data'];

    // Headers
    sheet.appendRow([TextCellValue('Machine ID'), TextCellValue('Morning OEE'), TextCellValue('Night OEE'), TextCellValue('Average OEE')]);

    // Data
    for (var item in data) {
      final morningOee = item['Morning_OEE'] ?? 0.0;
      final nightOee = item['Night_OEE'] ?? 0.0;
      final avgOee = (morningOee + nightOee) / 2;

      sheet.appendRow([
        TextCellValue(item['MachineID']?.toString() ?? ''),
        DoubleCellValue(morningOee),
        DoubleCellValue(nightOee),
        DoubleCellValue(avgOee),
      ]);
    }
  }

  static void _createPerformanceSheet(Excel excel, Map<String, dynamic>? performanceData, String? selectedShift) {
    final sheet = excel['Performance Data'];

    if (performanceData == null || performanceData['data'] == null) return;

    List<dynamic> data = performanceData['data'];

    // Headers
    sheet.appendRow([TextCellValue('Machine ID'), TextCellValue('Morning Output'), TextCellValue('Night Output'), TextCellValue('Total Output')]);

    // Data
    for (var item in data) {
      final morningOutput = item['Morning_NGQuantity'] ?? 0;
      final nightOutput = item['Night_NGQuantity'] ?? 0;
      final totalOutput = morningOutput + nightOutput;

      sheet.appendRow([
        TextCellValue(item['MachineID']?.toString() ?? ''),
        IntCellValue(morningOutput),
        IntCellValue(nightOutput),
        IntCellValue(totalOutput),
      ]);
    }
  }

  static void _createAvailabilitySheet(Excel excel, Map<String, dynamic>? availabilityData, String? selectedShift) {
    final sheet = excel['Availability Data'];

    if (availabilityData == null || availabilityData['data'] == null) return;

    List<dynamic> data = availabilityData['data'];

    // Headers
    sheet.appendRow([
      TextCellValue('Machine ID'),
      TextCellValue('Morning Availability'),
      TextCellValue('Night Availability'),
      TextCellValue('Average Availability')
    ]);

    // Data
    for (var item in data) {
      final morningAvail = item['Morning_Availability'] ?? 0.0;
      final nightAvail = item['Night_Availability'] ?? 0.0;
      final avgAvail = (morningAvail + nightAvail) / 2;

      sheet.appendRow([
        TextCellValue(item['MachineID']?.toString() ?? ''),
        DoubleCellValue(morningAvail),
        DoubleCellValue(nightAvail),
        DoubleCellValue(avgAvail),
      ]);
    }
  }

  static void _createQualitySheet(Excel excel, Map<String, dynamic>? qualityData, String? selectedShift) {
    final sheet = excel['Quality Data'];

    if (qualityData == null || qualityData['data'] == null) return;

    List<dynamic> data = qualityData['data'];

    // Headers
    sheet
        .appendRow([TextCellValue('Machine ID'), TextCellValue('Morning Quality'), TextCellValue('Night Quality'), TextCellValue('Average Quality')]);

    // Data
    for (var item in data) {
      final morningQuality = item['Morning_Quality'] ?? 0.0;
      final nightQuality = item['Night_Quality'] ?? 0.0;
      final avgQuality = (morningQuality + nightQuality) / 2;

      sheet.appendRow([
        TextCellValue(item['MachineID']?.toString() ?? ''),
        DoubleCellValue(morningQuality),
        DoubleCellValue(nightQuality),
        DoubleCellValue(avgQuality),
      ]);
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
