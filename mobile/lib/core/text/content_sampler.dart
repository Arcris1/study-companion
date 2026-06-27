/// Picks text from [chunks] up to ~[maxChars], **spread evenly across the whole
/// list** rather than just taking the beginning. This lets AI features (quiz,
/// flashcards) cover an entire large document instead of only its first pages.
String sampleAcross(List<String> chunks, int maxChars) {
  if (chunks.isEmpty) return '';
  final joined = chunks.join('\n\n');
  if (joined.length <= maxChars) return joined;

  final avg = (joined.length / chunks.length).ceil().clamp(1, maxChars);
  final fit = (maxChars / avg).floor().clamp(1, chunks.length);
  final stride = (chunks.length / fit).floor().clamp(1, chunks.length);

  final buf = StringBuffer();
  for (var i = 0; i < chunks.length && buf.length < maxChars; i += stride) {
    if (buf.isNotEmpty) buf.write('\n\n');
    buf.write(chunks[i]);
  }
  return buf.toString();
}
