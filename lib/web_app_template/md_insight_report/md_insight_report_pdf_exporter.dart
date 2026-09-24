import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds and opens the print/save dialog for the MD Insight Report PDF.
///
/// Rather than hand-recreating the report's charts/gauge/donut with the
/// `pdf` package's primitive drawing API (which would drift from the design
/// mock over time), this renders the report body — already styled to match
/// `assets/images/md insight report.jpg` — to a single high-resolution image
/// and places that below a native-text title block on one continuous PDF
/// page. The title is drawn as real PDF text (not part of the captured
/// image) since the on-screen plant filter/Download button that sit next to
/// it on screen are page controls, not report content, and shouldn't appear
/// in the export.
class MdInsightReportPdfExporter {
  const MdInsightReportPdfExporter._();

  static Future<void> exportImage({
    required String reportDateLabel,
    required String periodLabel,
    required Uint8List pngBytes,
    required int pixelWidth,
    required int pixelHeight,
  }) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    // The default PDF base font doesn't reliably have glyphs for
    // typographic punctuation like en dashes (used in periodLabel, e.g.
    // "1 – 19 Jul 2026") — they can render as a missing/broken symbol even
    // though the same text looks fine on screen under a full Unicode font
    // (Poppins). Fall back to plain ASCII for the native PDF text only; the
    // on-screen labels are untouched.
    String pdfSafe(String s) => s.replaceAll(RegExp('[–—]'), '-');

    // Filename the operator sees in their downloads folder. Spaces and
    // punctuation that browsers or Windows would mangle are stripped.
    final _fileStem = 'MD_Insight_Report_'
        '${reportDateLabel.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}'
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'_$'), '');

    const horizontalMargin = 24.0;
    const titleBlockHeight = 108.0;
    final pageWidth = PdfPageFormat.a4.width;
    final imageHeight = pageWidth * pixelHeight / pixelWidth;
    final pageFormat = PdfPageFormat(
      pageWidth,
      titleBlockHeight + imageHeight,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: titleBlockHeight,
              width: double.infinity,
              // Matches the report's dark theme (same navy used by
              // ReportPanel/ReportHeader on screen) so the PDF title doesn't
              // look like a bare default-styled PDF page.
              color: const PdfColor.fromInt(0xFF0B1B33),
              padding: const pw.EdgeInsets.fromLTRB(
                horizontalMargin,
                18,
                horizontalMargin,
                12,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MAX DEMAND INSIGHT REPORT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Report Date: ${pdfSafe(reportDateLabel)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Period: ${pdfSafe(periodLabel)}',
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColor.fromInt(0xFFAAB4C8),
                    ),
                  ),
                ],
              ),
            ),
            pw.Image(
              image,
              width: pageWidth,
              height: imageHeight,
              fit: pw.BoxFit.fill,
            ),
          ],
        ),
      ),
    );

    // sharePdf, not layoutPdf. layoutPdf opens the browser's print dialog,
    // which makes "Download Report" ask for a printer and hides saving behind
    // Destination > Save as PDF. sharePdf hands the bytes straight to the
    // browser as a download, which is what the button says it does.
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '$_fileStem.pdf',
    );
  }
}
