import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';
import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/note_model.dart';
import '../../models/note_chunk_model.dart';
import '../../models/highlight_model.dart';
import '../../models/note_annotation_model.dart';

class NoteLocalDatasource {
  final ObjectBox _objectBox;

  NoteLocalDatasource(this._objectBox);

  Box<NoteModel> get _box => _objectBox.store.box<NoteModel>();
  Box<NoteChunkModel> get _chunkBox => _objectBox.store.box<NoteChunkModel>();
  Box<HighlightModel> get _highlightBox =>
      _objectBox.store.box<HighlightModel>();
  Box<NoteAnnotationModel> get _annotationBox =>
      _objectBox.store.box<NoteAnnotationModel>();

  List<NoteModel> getByNotebookId(int notebookId) {
    final query = _box.query(NoteModel_.notebookId.equals(notebookId))
        .order(NoteModel_.updatedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  NoteModel? getById(int id) {
    return _box.get(id);
  }

  NoteModel create(NoteModel model) {
    final id = _box.put(model);
    return _box.get(id)!;
  }

  NoteModel update(NoteModel model) {
    _box.put(model);
    return _box.get(model.id)!;
  }

  void delete(int id) {
    // Delete associated chunks
    final chunkQuery = _chunkBox.query(NoteChunkModel_.noteId.equals(id)).build();
    final chunkIds = chunkQuery.find().map((c) => c.id).toList();
    chunkQuery.close();
    _chunkBox.removeMany(chunkIds);

    // Delete associated highlights
    final highlightQuery =
        _highlightBox.query(HighlightModel_.noteId.equals(id)).build();
    final highlightIds = highlightQuery.find().map((h) => h.id).toList();
    highlightQuery.close();
    _highlightBox.removeMany(highlightIds);

    // Delete associated annotations (ink/sidenotes, possibly per-page).
    final annQuery =
        _annotationBox.query(NoteAnnotationModel_.noteId.equals(id)).build();
    final annIds = annQuery.find().map((a) => a.id).toList();
    annQuery.close();
    _annotationBox.removeMany(annIds);

    // Delete the copied PDF/image file (imported into app storage) if any.
    final note = _box.get(id);
    final path = note?.sourcePath;
    if ((note?.sourceType == 'pdf' || note?.sourceType == 'image') &&
        path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }

    _box.remove(id);
  }

  void saveChunks(List<NoteChunkModel> chunks) {
    _chunkBox.putMany(chunks);
  }

  void deleteChunks(int noteId) {
    final q = _chunkBox.query(NoteChunkModel_.noteId.equals(noteId)).build();
    final ids = q.find().map((c) => c.id).toList();
    q.close();
    _chunkBox.removeMany(ids);
  }

  /// (total chunks, embedded chunks) for a note — used to show AI-index state.
  ({int total, int embedded}) indexCounts(int noteId) {
    final totalQ =
        _chunkBox.query(NoteChunkModel_.noteId.equals(noteId)).build();
    final total = totalQ.count();
    totalQ.close();
    final embQ = _chunkBox
        .query(NoteChunkModel_.noteId.equals(noteId) &
            NoteChunkModel_.embedding.notNull())
        .build();
    final embedded = embQ.count();
    embQ.close();
    return (total: total, embedded: embedded);
  }

  List<NoteChunkModel> getChunks(int noteId) {
    final query = _chunkBox.query(NoteChunkModel_.noteId.equals(noteId))
        .order(NoteChunkModel_.chunkIndex)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  List<NoteChunkModel> searchChunks(int notebookId, String query) {
    // Phase 1: keyword search - find notes in notebook, then search their chunks
    final noteQuery = _box.query(NoteModel_.notebookId.equals(notebookId)).build();
    final noteIds = noteQuery.find().map((n) => n.id).toList();
    noteQuery.close();

    if (noteIds.isEmpty) return [];

    final keywords = query.toLowerCase().split(RegExp(r'\s+')).where((k) => k.length > 2).toList();
    if (keywords.isEmpty) return [];

    // Get all chunks for this notebook's notes
    final allChunks = <NoteChunkModel>[];
    for (final noteId in noteIds) {
      final chunkQuery = _chunkBox.query(NoteChunkModel_.noteId.equals(noteId)).build();
      allChunks.addAll(chunkQuery.find());
      chunkQuery.close();
    }

    // Score chunks by keyword matches
    final scored = allChunks.map((chunk) {
      final textLower = chunk.text.toLowerCase();
      int score = 0;
      for (final keyword in keywords) {
        if (textLower.contains(keyword)) score++;
      }
      return (chunk: chunk, score: score);
    }).where((s) => s.score > 0).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(5).map((s) => s.chunk).toList();
  }

  List<NoteChunkModel> searchChunksByVector(
    int notebookId,
    Float32List queryEmbedding, {
    int limit = 5,
  }) {
    // Get all note IDs in notebook
    final noteQuery =
        _box.query(NoteModel_.notebookId.equals(notebookId)).build();
    final noteIds = noteQuery.find().map((n) => n.id).toList();
    noteQuery.close();

    if (noteIds.isEmpty) return [];

    // Collect all chunks from this notebook's notes
    final allChunks = <NoteChunkModel>[];
    for (final noteId in noteIds) {
      final chunkQuery =
          _chunkBox.query(NoteChunkModel_.noteId.equals(noteId)).build();
      allChunks.addAll(chunkQuery.find());
      chunkQuery.close();
    }

    // Filter to chunks that have embeddings, compute cosine similarity
    final scored = allChunks
        .where((c) => c.embedding != null)
        .map((c) {
          final sim = _cosineSimilarity(queryEmbedding, c.embedding!);
          return (chunk: c, score: sim);
        })
        .toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((s) => s.chunk).toList();
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
