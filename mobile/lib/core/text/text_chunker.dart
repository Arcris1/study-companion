class TextChunker {
  final int chunkSize;
  final int overlap;

  const TextChunker({
    this.chunkSize = 500,
    this.overlap = 100,
  });

  List<String> chunk(String text) {
    if (text.isEmpty) return [];

    final cleanedText = text
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();

    if (cleanedText.length <= chunkSize) return [cleanedText];

    final chunks = <String>[];
    int start = 0;

    while (start < cleanedText.length) {
      int end = start + chunkSize;

      if (end >= cleanedText.length) {
        chunks.add(cleanedText.substring(start).trim());
        break;
      }

      // Try to break at sentence boundary
      int breakPoint = _findBreakPoint(cleanedText, start, end);
      chunks.add(cleanedText.substring(start, breakPoint).trim());

      start = breakPoint - overlap;
      if (start < 0) start = 0;
      if (start >= cleanedText.length) break;
    }

    return chunks.where((c) => c.isNotEmpty).toList();
  }

  int _findBreakPoint(String text, int start, int end) {
    // Look for sentence-ending punctuation near the end
    for (int i = end; i > end - 100 && i > start; i--) {
      if (i < text.length && '.!?\n'.contains(text[i])) {
        return i + 1;
      }
    }
    // Fall back to space
    for (int i = end; i > end - 50 && i > start; i--) {
      if (i < text.length && text[i] == ' ') {
        return i + 1;
      }
    }
    return end;
  }
}
