import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';

/// Thin wrapper over pdfrx for extracting text from PDF files.
class PdfService {
  /// Renders a single page (1-based) of an already-open [doc] to PNG bytes,
  /// scaled so the longest side is roughly [width] px. Used for vision OCR.
  static Future<Uint8List?> renderPagePng(
    PdfDocument doc,
    int pageNumber, {
    double width = 1500,
  }) async {
    final page = doc.pages[pageNumber - 1];
    final h = width * (page.height / page.width);
    final img = await page.render(
      width: width.round(),
      height: h.round(),
      fullWidth: width,
      fullHeight: h,
    );
    if (img == null) return null;
    final uiImg = await img.createImage();
    img.dispose();
    final bytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    uiImg.dispose();
    return bytes?.buffer.asUint8List();
  }

  /// Returns the text of each page (index 0 = page 1). The list length is the
  /// page count. Pages with no extractable text (e.g. scanned images) yield ''.
  static Future<List<String>> extractPagesText(String filePath) async {
    await pdfrxFlutterInitialize();
    final doc = await PdfDocument.openFile(filePath);
    try {
      final pages = <String>[];
      for (final page in doc.pages) {
        final t = await page.loadText();
        pages.add(t?.fullText ?? '');
      }
      return pages;
    } finally {
      doc.dispose();
    }
  }

  /// Number of pages in a PDF.
  static Future<int> pageCount(String filePath) async {
    await pdfrxFlutterInitialize();
    final doc = await PdfDocument.openFile(filePath);
    try {
      return doc.pages.length;
    } finally {
      doc.dispose();
    }
  }
}
