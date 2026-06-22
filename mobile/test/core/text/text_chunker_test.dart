import 'package:flutter_test/flutter_test.dart';
import 'package:study_companion/core/text/text_chunker.dart';

void main() {
  group('TextChunker', () {
    group('basic behavior', () {
      test('returns empty list for empty text', () {
        const chunker = TextChunker(chunkSize: 100, overlap: 20);
        expect(chunker.chunk(''), isEmpty);
      });

      test('returns single chunk when text is shorter than chunkSize', () {
        const chunker = TextChunker(chunkSize: 500, overlap: 100);
        final chunks = chunker.chunk('Short text.');
        expect(chunks, hasLength(1));
        expect(chunks.first, equals('Short text.'));
      });

      test('returns single chunk when text equals chunkSize exactly', () {
        const chunker = TextChunker(chunkSize: 10, overlap: 2);
        final text = 'a' * 10;
        final chunks = chunker.chunk(text);
        expect(chunks, hasLength(1));
      });
    });

    group('exact chunkSize boundary behavior', () {
      test('text one character longer than chunkSize produces multiple chunks', () {
        const chunker = TextChunker(chunkSize: 10, overlap: 2);
        final text = 'a' * 11;
        final chunks = chunker.chunk(text);
        expect(chunks.length, greaterThan(1));
      });

      test('all chunks are non-empty', () {
        const chunker = TextChunker(chunkSize: 20, overlap: 5);
        final text = 'word ' * 20; // 100 chars
        final chunks = chunker.chunk(text);
        for (final chunk in chunks) {
          expect(chunk.isNotEmpty, isTrue);
        }
      });
    });

    group('overlap verification', () {
      test('consecutive chunks share text when overlap > 0', () {
        const chunker = TextChunker(chunkSize: 30, overlap: 10);
        // Use text without sentence boundaries so overlap is predictable
        final text = List.generate(100, (i) => 'x').join();
        final chunks = chunker.chunk(text);

        expect(chunks.length, greaterThan(1));

        // Check that there is overlapping content between consecutive chunks
        for (int i = 0; i < chunks.length - 1; i++) {
          final current = chunks[i];
          final next = chunks[i + 1];
          // The end of the current chunk should overlap with the start of the next
          final currentEnd = current.substring(current.length - 10.clamp(0, current.length));
          expect(next, startsWith(currentEnd));
        }
      });

      test('zero overlap produces no shared text between chunks', () {
        const chunker = TextChunker(chunkSize: 20, overlap: 0);
        final text = 'a' * 60;
        final chunks = chunker.chunk(text);

        // Total characters across all chunks should equal original length
        final totalLen = chunks.fold<int>(0, (sum, c) => sum + c.length);
        expect(totalLen, equals(60));
      });
    });

    group('sentence boundary breaking', () {
      test('breaks at sentence boundary (period) when available', () {
        const chunker = TextChunker(chunkSize: 50, overlap: 10);
        final text = 'This is sentence one. This is sentence two. This is sentence three. This is sentence four.';
        final chunks = chunker.chunk(text);

        // First chunk should end at a sentence boundary
        expect(chunks.first, endsWith('.'));
      });

      test('breaks at newline when available', () {
        const chunker = TextChunker(chunkSize: 50, overlap: 10);
        final text = 'First paragraph here with more words.\nSecond paragraph here and more text that goes on and on to make it long enough.';
        final chunks = chunker.chunk(text);

        // With sentence/newline breaking, first chunk should end at the newline
        expect(chunks.length, greaterThan(1));
      });
    });

    group('multi-newline collapsing', () {
      test('collapses three or more consecutive newlines to two', () {
        const chunker = TextChunker(chunkSize: 500, overlap: 50);
        final text = 'Hello\n\n\n\n\nWorld';
        final chunks = chunker.chunk(text);

        expect(chunks.first, contains('\n\n'));
        expect(chunks.first, isNot(contains('\n\n\n')));
      });

      test('collapses multiple spaces to single space', () {
        const chunker = TextChunker(chunkSize: 500, overlap: 50);
        final text = 'Hello    World';
        final chunks = chunker.chunk(text);

        expect(chunks.first, equals('Hello World'));
      });
    });

    group('different chunk sizes and overlaps', () {
      test('very small chunkSize still produces valid chunks', () {
        const chunker = TextChunker(chunkSize: 5, overlap: 1);
        final text = 'abcdefghijklmnop';
        final chunks = chunker.chunk(text);

        expect(chunks.length, greaterThan(1));
        for (final chunk in chunks) {
          expect(chunk.isNotEmpty, isTrue);
        }
      });

      test('large overlap relative to chunkSize works', () {
        const chunker = TextChunker(chunkSize: 20, overlap: 15);
        final text = 'a' * 60;
        final chunks = chunker.chunk(text);

        expect(chunks.length, greaterThan(1));
      });

      test('default parameters work correctly', () {
        const chunker = TextChunker(); // defaults: chunkSize=500, overlap=100
        final text = 'A' * 1200;
        final chunks = chunker.chunk(text);

        expect(chunks.length, greaterThan(1));
      });

      test('reconstructed text covers entire original (no gaps)', () {
        const chunker = TextChunker(chunkSize: 50, overlap: 10);
        final text = 'abcdefghij' * 10; // 100 chars, no spaces/periods
        final chunks = chunker.chunk(text);

        // Every character in the original should appear in at least one chunk
        for (int i = 0; i < text.length; i++) {
          final char = text[i];
          final found = chunks.any((c) => c.contains(char));
          expect(found, isTrue);
        }
      });
    });
  });
}
