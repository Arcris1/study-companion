import 'dart:math';
import 'dart:typed_data';
import '../../core/embedding/embedding_service.dart';
import '../../domain/entities/search_result.dart';
import '../datasources/local/note_local_datasource.dart';
import '../datasources/local/notebook_local_datasource.dart';

class SearchRepository {
  final NoteLocalDatasource _noteDatasource;
  final NotebookLocalDatasource _notebookDatasource;
  final EmbeddingService _embeddingService;

  SearchRepository(
    this._noteDatasource,
    this._notebookDatasource,
    this._embeddingService,
  );

  /// Search across notes. If embedding service is available, uses vector search;
  /// otherwise falls back to keyword search.
  Future<List<SearchResult>> search(String query, {int? notebookId}) async {
    if (query.trim().isEmpty) return [];

    final notebooks = _notebookDatasource.getAll();
    if (notebooks.isEmpty) return [];

    final results = <SearchResult>[];

    // Determine which notebooks to search
    final targetNotebooks = notebookId != null
        ? notebooks.where((nb) => nb.id == notebookId).toList()
        : notebooks;

    for (final notebook in targetNotebooks) {
      final noteCount = _notebookDatasource.getNoteCount(notebook.id);
      if (noteCount == 0) continue;

      if (_embeddingService.isReady) {
        // Vector search
        final queryEmbedding = await _embeddingService.embed(query);
        final chunks = _noteDatasource.searchChunksByVector(
          notebook.id,
          queryEmbedding,
          limit: 5,
        );

        for (final chunk in chunks) {
          final note = _noteDatasource.getById(chunk.noteId);
          if (note == null) continue;

          // Compute relevance score
          final embedding = chunk.embedding;
          double score = 0.5; // default for chunks without embedding
          if (embedding != null) {
            score = _cosineSimilarity(queryEmbedding, embedding);
          }

          results.add(SearchResult(
            chunk: chunk.toEntity(),
            noteTitle: note.title,
            notebookTitle: notebook.title,
            relevanceScore: score,
            notebookId: notebook.id,
            noteId: note.id,
          ));
        }
      } else {
        // Keyword search fallback
        final chunks = _noteDatasource.searchChunks(notebook.id, query);
        final keywords = query.toLowerCase().split(RegExp(r'\s+')).where((k) => k.length > 2).toList();

        for (final chunk in chunks) {
          final note = _noteDatasource.getById(chunk.noteId);
          if (note == null) continue;

          // Calculate keyword-based relevance score
          final textLower = chunk.text.toLowerCase();
          int matchCount = 0;
          for (final keyword in keywords) {
            if (textLower.contains(keyword)) matchCount++;
          }
          final score = keywords.isNotEmpty ? matchCount / keywords.length : 0.0;

          results.add(SearchResult(
            chunk: chunk.toEntity(),
            noteTitle: note.title,
            notebookTitle: notebook.title,
            relevanceScore: score,
            notebookId: notebook.id,
            noteId: note.id,
          ));
        }
      }
    }

    // Sort by relevance score descending
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  double _cosineSimilarity(Float32List a, Float32List b) {
    double dotProduct = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
