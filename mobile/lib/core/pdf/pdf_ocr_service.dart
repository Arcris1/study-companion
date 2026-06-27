import 'package:pdfrx/pdfrx.dart';
import '../openai/openai_client.dart';
import 'pdf_service.dart';

/// OCRs scanned/image-only PDFs by rendering each page and asking the vision
/// model to transcribe it. Costly — call on demand and respect [maxPages].
class PdfOcrService {
  static const String _prompt =
      'You are an OCR engine. Transcribe ALL text from this scanned document '
      'page exactly as it appears, preserving headings, lists and tables using '
      'Markdown. Output only the transcribed text — no commentary.';

  /// Returns the OCR text of each page (index 0 = page 1), up to [maxPages].
  static Future<List<String>> ocrPages(
    String filePath, {
    int maxPages = 80,
    void Function(int done, int total)? onProgress,
  }) async {
    await pdfrxFlutterInitialize();
    final doc = await PdfDocument.openFile(filePath);
    try {
      final count = doc.pages.length;
      final total = count < maxPages ? count : maxPages;
      final out = <String>[];
      for (var i = 1; i <= total; i++) {
        final png = await PdfService.renderPagePng(doc, i);
        if (png == null) {
          out.add('');
          onProgress?.call(i, total);
          continue;
        }
        final buf = StringBuffer();
        await for (final t in OpenAiClient.instance.visionStream(
          _prompt,
          png,
          maxTokens: 1500,
        )) {
          buf.write(t);
        }
        out.add(buf.toString().trim());
        onProgress?.call(i, total);
      }
      return out;
    } finally {
      doc.dispose();
    }
  }
}
