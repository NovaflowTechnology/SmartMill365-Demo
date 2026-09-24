import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds and opens the browser download for the TNB E3 Bill Simulator PDF.
///
/// Mirrors [MdInsightReportPdfExporter]: rather than hand-recreating the
/// breakdown table / summary cards with the `pdf` package's primitive
/// drawing API, this captures the already-styled report body as a single
/// high-resolution image and places it below a native-text title block on
/// one continuous PDF page. The title block is drawn as real PDF text (not
/// part of the captured image) since the on-screen meter filter and
/// Download button next to it are page controls, not report content, and
/// shouldn't appear in the export.
class TnbE3BillSimulatorPdfExporter {
  const TnbE3BillSimulatorPdfExporter._();

  static Future<void> exportImage({
    required String categoryName,
    required String plantLabel,
    required String accrualAmount,
    required String generatedLabel,
    required Uint8List pngBytes,
    required int pixelWidth,
    required int pixelHeight,
  }) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    // The default PDF base font doesn't reliably have glyphs for
    // typographic punctuation (e.g. em dashes used in plant labels like
    // "Lot 237 — Enterprise Energy Management") — fall back to plain ASCII
    // for the native PDF text only; the on-screen labels are untouched.
    String pdfSafe(String s) => s.replaceAll(RegExp('[–—]'), '-');

    final title =
        categoryName.isNotEmpty ? '$categoryName BILL SIMULATOR' : 'TNB E3 BILL SIMULATOR';

    // Filename the operator sees in their downloads folder. Spaces and
    // punctuation that browsers or Windows would mangle are stripped.
    final _fileStem = 'TNB_Bill_Simulator_'
        '${(categoryName.isNotEmpty ? categoryName : 'Report').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}'
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
              // Matches the bill simulator's dark cyberpunk theme (same navy
              // used by TnbHeaderCard/TnbBreakdownTable on screen) so the PDF
              // title doesn't look like a bare default-styled PDF page.
              color: const PdfColor.fromInt(0xFF07101F),
              padding: const pw.EdgeInsets.fromLTRB(
                horizontalMargin,
                18,
                horizontalMargin,
                12,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        pdfSafe(title),
                        style: pw.TextStyle(
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      if (plantLabel.isNotEmpty)
                        pw.Text(
                          pdfSafe(plantLabel),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromInt(0xFFAAB4C8),
                          ),
                        ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Generated: ${pdfSafe(generatedLabel)}',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColor.fromInt(0xFFAAB4C8),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'CURRENT MONTH ACCRUAL (MTD)',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromInt(0xFFAAB4C8),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        pdfSafe(accrualAmount),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF00E676),
                        ),
                      ),
                    ],
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
    // which makes "Download" ask for a printer and hides saving behind
    // Destination > Save as PDF. sharePdf hands the bytes straight to the
    // browser as a download, which is what the button says it does.
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '$_fileStem.pdf',
    );
  }
}
