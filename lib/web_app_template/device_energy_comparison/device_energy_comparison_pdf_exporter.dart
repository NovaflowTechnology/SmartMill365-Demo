import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Non-const wrappers were needed when nested inside other consts; at top-level, const is valid.
const _kHeaderBg    = PdfColor.fromInt(0xFF071A2E);
const _kCardBg      = PdfColor.fromInt(0xFF0B1B33);
const _kCardBorder  = PdfColor.fromInt(0xFF1E3A5F);
const _kCyan        = PdfColor.fromInt(0xFF00D4FF);
const _kAmber       = PdfColor.fromInt(0xFFFF9800);
const _kGreen       = PdfColor.fromInt(0xFF00E676);
const _kYellow      = PdfColor.fromInt(0xFFFFD600);
const _kSlate       = PdfColor.fromInt(0xFFAAB4C8);
const _kRowOdd      = PdfColor.fromInt(0xFFF8FAFC);
const _kTableBorder = PdfColor.fromInt(0xFFE2E8F0);
const _kTeal        = PdfColor.fromInt(0xFF0099C6);
const _kOnline      = PdfColor.fromInt(0xFF00A86B);
const _kTextDark    = PdfColor.fromInt(0xFF071A2E);

class DevicePdfRow {
  final String deviceId;
  final String deviceName;
  final double energyKwh;
  final double maxDemandKw;
  final double carbonKg;
  final double costRm;
  final double pfAvg;
  final bool isOnline;

  const DevicePdfRow({
    required this.deviceId,
    required this.deviceName,
    required this.energyKwh,
    required this.maxDemandKw,
    required this.carbonKg,
    required this.costRm,
    required this.pfAvg,
    required this.isOnline,
  });
}

/// Fast, lightweight, crash-free vector PDF exporter for Device Energy Comparison.
/// Uses Google Fonts (Noto Sans / Roboto) for full Unicode support.
class DeviceEnergyComparisonPdfExporter {
  const DeviceEnergyComparisonPdfExporter._();

  static Future<void> exportPdf({
    required String scopeLabel,
    required String periodLabel,
    required String dateRangeLabel,
    required String metricLabel,
    required double totalEnergy,
    required double peakDemand,
    required double totalCarbon,
    required double totalCost,
    required List<DevicePdfRow> devices,
  }) async {
    // Load Unicode-capable fonts (Noto Sans is safe for most special characters)
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    String pdfSafe(String s) => s
        .replaceAll('\u2013', '-')   // en dash
        .replaceAll('\u2014', '-')   // em dash
        .replaceAll('\u2026', '...') // ellipsis
        .replaceAll('\u00b2', '2')   // superscript 2
        .replaceAll('\u2082', '2');  // subscript 2

    String fmtComma(double v) {
      if (v.isNaN || v.isInfinite) return '0';
      final s = v.toStringAsFixed(0);
      final neg = s.startsWith('-');
      final digits = neg ? s.substring(1) : s;
      final buf = StringBuffer();
      if (neg) buf.write('-');
      for (int i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
        buf.write(digits[i]);
      }
      return buf.toString();
    }

    // ── Helper widgets ─────────────────────────────────────────────────────
    pw.Widget kpiTile(String label, String value, PdfColor color) {
      return pw.Column(
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: _kSlate)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(font: fontBold, fontSize: 11, color: color)),
        ],
      );
    }

    pw.Widget th(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white)),
      );
    }

    pw.Widget td(String text,
        {bool bold = false,
        PdfColor? color,
        pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(
              font: bold ? fontBold : fontRegular,
              fontSize: 8.5,
              color: color ?? PdfColors.black,
            )),
      );
    }

    // ── Page ───────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        // ── Header ─────────────────────────────────────────────────────────
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: _kHeaderBg,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DEVICE ENERGY COMPARISON REPORT',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 14, color: _kCyan)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Scope: ${pdfSafe(scopeLabel)}  |  Period: ${pdfSafe(periodLabel)} (${pdfSafe(dateRangeLabel)})',
                    style: pw.TextStyle(
                        font: fontRegular, fontSize: 8.5, color: _kSlate),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Metric: ${pdfSafe(metricLabel)}',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Generated: ${pdfSafe(DateTime.now().toString().substring(0, 16))} MYT',
                    style: pw.TextStyle(
                        font: fontRegular, fontSize: 8, color: _kSlate),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── Footer ─────────────────────────────────────────────────────────
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SmartFactory 365 Energy Intelligence System',
                  style: pw.TextStyle(
                      font: fontRegular, fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(
                      font: fontRegular, fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
        // ── Body ───────────────────────────────────────────────────────────
        build: (ctx) => [
          // KPI Row
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _kCardBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: _kCardBorder),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                kpiTile('Total Energy', '${fmtComma(totalEnergy)} kWh', _kCyan),
                kpiTile('Total Devices', '${devices.length}', PdfColors.white),
                kpiTile('Peak Demand', '${peakDemand.toStringAsFixed(1)} kW', _kAmber),
                kpiTile('Carbon Emission', '${fmtComma(totalCarbon)} kgCO2', _kGreen),
                kpiTile('Total Est. Cost', 'RM ${fmtComma(totalCost)}', _kYellow),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Table title
          pw.Text(
            'Detailed Device Energy & Demand Breakdown',
            style: pw.TextStyle(
                font: fontBold, fontSize: 11, color: _kTextDark),
          ),
          pw.SizedBox(height: 6),

          // Data Table
          pw.Table(
            border: pw.TableBorder.all(color: _kTableBorder, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(28),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1.8),
              4: pw.FlexColumnWidth(1.8),
              5: pw.FlexColumnWidth(1.8),
              6: pw.FixedColumnWidth(40),
              7: pw.FixedColumnWidth(50),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _kHeaderBg),
                children: [
                  th('No.'),
                  th('Device Name / ID'),
                  th('Energy (kWh)'),
                  th('Max Demand'),
                  th('Carbon (kg)'),
                  th('Cost (RM)'),
                  th('PF'),
                  th('Status'),
                ],
              ),
              // Rows
              ...devices.asMap().entries.map((entry) {
                final idx = entry.key;
                final d   = entry.value;
                final bg  = idx.isOdd ? _kRowOdd : PdfColors.white;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    td('#${idx + 1}', align: pw.TextAlign.center),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            pdfSafe(d.deviceName.isNotEmpty ? d.deviceName : d.deviceId),
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 8.5,
                                color: PdfColors.black),
                          ),
                          pw.Text(
                            pdfSafe(d.deviceId),
                            style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 7.5,
                                color: _kTeal),
                          ),
                        ],
                      ),
                    ),
                    td('${fmtComma(d.energyKwh)} kWh', bold: true),
                    td('${d.maxDemandKw.toStringAsFixed(1)} kW'),
                    td('${fmtComma(d.carbonKg)} kg'),
                    td('RM ${fmtComma(d.costRm)}'),
                    td(d.pfAvg.toStringAsFixed(2), align: pw.TextAlign.center),
                    td(
                      d.isOnline ? 'Online' : 'Offline',
                      color: d.isOnline ? _kOnline : PdfColors.red,
                      align: pw.TextAlign.center,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    // sharePdf, not layoutPdf. layoutPdf opens the browser's print dialog, so
    // a button labelled "Download Report" asked for a printer and buried
    // saving under Destination > Save as PDF. sharePdf hands the bytes to the
    // browser as a download.
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Device_Energy_Comparison.pdf',
    );
  }
}
