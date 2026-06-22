import 'package:flutter_test/flutter_test.dart';
import 'package:study_companion/core/text/text_chunker.dart';

void main() {
  group('TextChunker', () {
    const chunker = TextChunker(chunkSize: 100, overlap: 20);

    test('returns empty list for empty text', () {
      expect(chunker.chunk(''), isEmpty);
    });

    test('returns single chunk for short text', () {
      final result = chunker.chunk('Hello world');
      expect(result, hasLength(1));
      expect(result.first, 'Hello world');
    });

    test('splits long text into multiple chunks', () {
      final longText = 'This is a sentence. ' * 20;
      final result = chunker.chunk(longText);
      expect(result.length, greaterThan(1));
    });

    test('all chunks are non-empty', () {
      final longText = 'Word ' * 200;
      final result = chunker.chunk(longText);
      for (final chunk in result) {
        expect(chunk.trim(), isNotEmpty);
      }
    });
  });
}
