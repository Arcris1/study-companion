import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/ai/ai_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/embedding/embedding_service.dart';
import '../../core/llm/llm_service.dart';
import '../../core/llm/prompt_templates.dart';
import '../../core/text/text_chunker.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_chunk.dart';
import '../../domain/enums/note_status.dart';
import '../../domain/repositories/i_note_repository.dart';
import '../datasources/local/note_local_datasource.dart';
import '../models/note_model.dart';
import '../models/note_chunk_model.dart';

class NoteRepository implements INoteRepository {
  final NoteLocalDatasource _datasource;
  final TextChunker _chunker;
  final LlmService _llmService;
  final EmbeddingService _embeddingService;

  NoteRepository(
    this._datasource,
    this._chunker,
    this._llmService,
    this._embeddingService,
  );

  @override
  Future<List<Note>> getByNotebookId(int notebookId) async {
    final models = _datasource.getByNotebookId(notebookId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Note?> getById(int id) async {
    final model = _datasource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<Note> importFromFile(String filePath, int notebookId) async {
    final ext = p.extension(filePath).toLowerCase();
    final fileName = p.basenameWithoutExtension(filePath);

    if (ext != '.txt' && ext != '.md') {
      throw FileException('Unsupported file type "$ext" — only .md and .txt are supported.');
    }

    try {
      final rawText = await File(filePath).readAsString();
      return await _createNoteFromText(
        title: fileName,
        rawText: rawText,
        notebookId: notebookId,
        sourceType: ext.replaceAll('.', ''),
        sourcePath: filePath,
      );
    } catch (e) {
      if (e is FileException) rethrow;
      throw FileException('Import failed: $e');
    }
  }

  Future<Note> _createNoteFromText({
    required String title,
    required String rawText,
    required int notebookId,
    required String sourceType,
    String? sourcePath,
  }) async {
    if (rawText.trim().isEmpty) {
      throw const FileException('No text content found');
    }

    final now = DateTime.now();
    var noteModel = NoteModel(
      notebookId: notebookId,
      title: title,
      rawText: rawText,
      statusStr: NoteStatus.ready.name,
      sourceType: sourceType,
      sourcePath: sourcePath,
      createdAt: now,
      updatedAt: now,
    );
    noteModel = _datasource.create(noteModel);

    // Chunk text
    final chunks = _chunker.chunk(rawText);
    final chunkModels = chunks.asMap().entries.map((entry) {
      return NoteChunkModel(
        noteId: noteModel.id,
        text: entry.value,
        chunkIndex: entry.key,
      );
    }).toList();

    _datasource.saveChunks(chunkModels);

    // Generate embeddings if available
    if (_embeddingService.isReady) {
      try {
        await _embedChunks(chunkModels);
      } catch (_) {}
    }

    noteModel.chunkCount = chunkModels.length;
    noteModel = _datasource.update(noteModel);

    return noteModel.toEntity();
  }

  @override
  Future<Note> createManual(String title, String text, int notebookId) async {
    final now = DateTime.now();
    var noteModel = NoteModel(
      notebookId: notebookId,
      title: title,
      rawText: text,
      statusStr: NoteStatus.ready.name,
      sourceType: 'manual',
      createdAt: now,
      updatedAt: now,
    );
    noteModel = _datasource.create(noteModel);

    // Chunk text
    final chunks = _chunker.chunk(text);
    final chunkModels = chunks.asMap().entries.map((entry) {
      return NoteChunkModel(
        noteId: noteModel.id,
        text: entry.value,
        chunkIndex: entry.key,
      );
    }).toList();

    _datasource.saveChunks(chunkModels);

    // Generate embeddings if embedding service is available
    if (_embeddingService.isReady) {
      try {
        await _embedChunks(chunkModels);
      } catch (_) {
        // Embedding failure is non-fatal
      }
    }

    noteModel.chunkCount = chunkModels.length;
    noteModel = _datasource.update(noteModel);

    return noteModel.toEntity();
  }

  @override
  Future<Note> update(Note note) async {
    final model = NoteModel.fromEntity(note);
    final updated = _datasource.update(model);
    return updated.toEntity();
  }

  @override
  Future<void> delete(int id) async {
    _datasource.delete(id);
  }

  @override
  Future<String> generateSummary(int noteId) async {
    final note = _datasource.getById(noteId);
    if (note == null) throw Exception('Note not found');

    if (note.summary != null && note.summary!.isNotEmpty) {
      return note.summary!;
    }

    // Use first few chunks for summary (to stay within context window)
    final chunks = _datasource.getChunks(noteId);
    final textForSummary = chunks.take(10).map((c) => c.text).join('\n\n');

    final prompt = PromptTemplates.summarize(textForSummary);
    final summary = await _llmService.generate(
      prompt,
      maxTokens: AiConfig.instance.tokenLimit(AiOp.summary),
    );

    // Cache the summary
    note.summary = summary;
    note.updatedAt = DateTime.now();
    _datasource.update(note);

    return summary;
  }

  @override
  Future<List<NoteChunk>> getChunks(int noteId) async {
    return _datasource.getChunks(noteId).map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<NoteChunk>> searchChunks(int notebookId, String query) async {
    return _datasource.searchChunks(notebookId, query)
        .map((m) => m.toEntity())
        .toList();
  }

  /// Re-generate embeddings for all chunks in a notebook.
  Future<void> reembedAllChunks(int notebookId) async {
    if (!_embeddingService.isReady) return;

    final notes = _datasource.getByNotebookId(notebookId);
    for (final note in notes) {
      final chunks = _datasource.getChunks(note.id);
      await _embedChunks(chunks);
    }
  }

  /// Generate embeddings for a list of chunk models and save them.
  Future<void> _embedChunks(List<NoteChunkModel> chunks) async {
    final texts = chunks.map((c) => c.text).toList();
    final embeddings = await _embeddingService.embedBatch(texts);

    for (int i = 0; i < chunks.length; i++) {
      chunks[i].embedding = embeddings[i];
    }

    _datasource.saveChunks(chunks);
  }
}
