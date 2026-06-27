import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/ai/ai_config.dart';
import '../../core/openai/openai_client.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/pdf_ocr_service.dart';
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

    if (ext == '.pdf') {
      try {
        return await _createNoteFromPdf(filePath, fileName, notebookId);
      } catch (e) {
        if (e is FileException) rethrow;
        throw FileException('PDF import failed: $e');
      }
    }

    if (ext != '.txt' && ext != '.md') {
      throw FileException(
          'Unsupported file type "$ext" — only .md, .txt and .pdf are supported.');
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

  /// Imports a PDF: copies it into app storage (for preview/annotate), extracts
  /// per-page text, and creates a note with page-aware chunks.
  Future<Note> _createNoteFromPdf(
      String filePath, String title, int notebookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(dir.path, 'pdfs'));
    if (!pdfDir.existsSync()) pdfDir.createSync(recursive: true);
    final dest = p.join(pdfDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(filePath)}');
    await File(filePath).copy(dest);

    final pages = await PdfService.extractPagesText(dest);

    final buffer = StringBuffer();
    for (final t in pages) {
      final trimmed = t.trim();
      if (trimmed.isNotEmpty) {
        buffer
          ..writeln(trimmed)
          ..writeln();
      }
    }
    final rawText = buffer.toString().trim();

    final now = DateTime.now();
    var noteModel = NoteModel(
      notebookId: notebookId,
      title: title,
      // Empty rawText is allowed (scanned PDFs) — it can still be previewed.
      rawText: rawText,
      statusStr: NoteStatus.ready.name,
      sourceType: 'pdf',
      sourcePath: dest,
      createdAt: now,
      updatedAt: now,
    );
    noteModel = _datasource.create(noteModel);

    // Page-aware chunks (each chunk tagged with its 1-based page).
    final chunkModels = <NoteChunkModel>[];
    var idx = 0;
    for (var i = 0; i < pages.length; i++) {
      final pageText = pages[i].trim();
      if (pageText.isEmpty) continue;
      for (final c in _chunker.chunk(pageText)) {
        chunkModels.add(NoteChunkModel(
          noteId: noteModel.id,
          text: c,
          chunkIndex: idx++,
          page: i + 1,
        ));
      }
    }
    if (chunkModels.isNotEmpty) {
      _datasource.saveChunks(chunkModels);
    }
    // Embeddings are NOT generated here — the user builds the AI index on demand
    // (see indexNote) so importing large PDFs is instant and free.

    noteModel.chunkCount = chunkModels.length;
    noteModel = _datasource.update(noteModel);
    return noteModel.toEntity();
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
    // Embeddings built on demand via indexNote — see _createNoteFromPdf note.

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
    // Embeddings built on demand via indexNote.

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

    // Map-reduce over all chunks so large docs are summarized in full.
    final chunks = _datasource.getChunks(noteId);
    final summary =
        await _summarizeChunks(chunks.map((c) => c.text).toList());

    // Cache the summary
    note.summary = summary;
    note.updatedAt = DateTime.now();
    _datasource.update(note);

    return summary;
  }

  /// Summarizes [texts] map-reduce style: small inputs summarize directly;
  /// large inputs are summarized in batches, then the batch summaries are
  /// summarized together (recursively) so the whole document is covered.
  Future<String> _summarizeChunks(List<String> texts) async {
    const maxChars = 11000;
    if (texts.isEmpty) return '';

    final full = texts.join('\n\n');
    if (full.length <= maxChars) {
      return _llmService.generate(
        PromptTemplates.summarize(full),
        maxTokens: AiConfig.instance.tokenLimit(AiOp.summary),
      );
    }

    // Map: group chunks into ~maxChars batches and summarize each.
    final batches = <String>[];
    final buf = StringBuffer();
    for (final t in texts) {
      if (buf.isNotEmpty && buf.length + t.length > maxChars) {
        batches.add(buf.toString());
        buf.clear();
      }
      buf
        ..write(t)
        ..write('\n\n');
    }
    if (buf.isNotEmpty) batches.add(buf.toString());

    final partials = <String>[];
    for (final b in batches) {
      partials.add(await _llmService.generate(
        PromptTemplates.summarize(b),
        maxTokens: AiConfig.instance.tokenLimit(AiOp.summary),
      ));
    }

    // Reduce: combine the partial summaries (recurse if still too large).
    if (partials.join('\n\n').length <= maxChars) {
      return _llmService.generate(
        PromptTemplates.summarize(partials.join('\n\n')),
        maxTokens: AiConfig.instance.tokenLimit(AiOp.summary),
      );
    }
    return _summarizeChunks(partials);
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
  static const int _maxEmbedChunks = 1200;

  Future<void> _embedChunks(List<NoteChunkModel> chunks) async {
    // For very large docs, embed an evenly-spread subset to bound cost/time;
    // the rest stay searchable via keyword search.
    final List<NoteChunkModel> toEmbed;
    if (chunks.length > _maxEmbedChunks) {
      final stride = (chunks.length / _maxEmbedChunks).ceil();
      toEmbed = [for (var i = 0; i < chunks.length; i += stride) chunks[i]];
    } else {
      toEmbed = chunks;
    }

    final texts = toEmbed.map((c) => c.text).toList();
    final embeddings = await _embeddingService.embedBatch(texts);
    for (int i = 0; i < toEmbed.length; i++) {
      toEmbed[i].embedding = embeddings[i];
    }
    _datasource.saveChunks(toEmbed);
  }

  /// Builds the AI (RAG) index for a note on demand: embeds its chunks in
  /// batches, reporting progress. Capped + evenly sampled for huge documents.
  @override
  Future<void> indexNote(int noteId,
      {void Function(int done, int total)? onProgress}) async {
    if (!_embeddingService.isReady) {
      throw Exception(
          'Add an OpenAI API key in Settings to enable AI indexing.');
    }
    final all = _datasource.getChunks(noteId);
    if (all.isEmpty) {
      throw Exception('No readable text to index (a scanned PDF has no text).');
    }

    // Target set: capped + evenly sampled across the whole document.
    final List<NoteChunkModel> target;
    if (all.length > _maxEmbedChunks) {
      final stride = (all.length / _maxEmbedChunks).ceil();
      target = [for (var i = 0; i < all.length; i += stride) all[i]];
    } else {
      target = all;
    }

    final toEmbed = target.where((c) => c.embedding == null).toList();
    if (toEmbed.isEmpty) {
      onProgress?.call(target.length, target.length);
      return;
    }

    const slice = 96;
    for (var i = 0; i < toEmbed.length; i += slice) {
      final end = (i + slice) < toEmbed.length ? (i + slice) : toEmbed.length;
      final batch = toEmbed.sublist(i, end);
      final embeddings =
          await _embeddingService.embedBatch(batch.map((c) => c.text).toList());
      for (var j = 0; j < batch.length; j++) {
        batch[j].embedding = embeddings[j];
      }
      _datasource.saveChunks(batch);
      onProgress?.call(end, toEmbed.length);
    }
  }

  /// OCRs a scanned PDF (no extractable text) with the vision model and
  /// rebuilds its text + page-aware chunks. The user can then build the AI
  /// index. Costly — capped by [PdfOcrService.ocrPages].
  Future<void> ocrNote(int noteId,
      {void Function(int done, int total)? onProgress}) async {
    if (!OpenAiClient.instance.hasKey) {
      throw Exception('Add an OpenAI API key in Settings to use OCR.');
    }
    final note = _datasource.getById(noteId);
    if (note == null || note.sourceType != 'pdf' || note.sourcePath == null) {
      throw Exception('OCR is only available for PDF notes.');
    }

    final pages =
        await PdfOcrService.ocrPages(note.sourcePath!, onProgress: onProgress);

    final buffer = StringBuffer();
    for (final t in pages) {
      if (t.trim().isNotEmpty) {
        buffer
          ..writeln(t.trim())
          ..writeln();
      }
    }
    final rawText = buffer.toString().trim();
    if (rawText.isEmpty) {
      throw Exception('OCR found no readable text in this PDF.');
    }

    // Replace chunks with the OCR'd, page-aware ones.
    _datasource.deleteChunks(noteId);
    final chunkModels = <NoteChunkModel>[];
    var idx = 0;
    for (var i = 0; i < pages.length; i++) {
      final pt = pages[i].trim();
      if (pt.isEmpty) continue;
      for (final c in _chunker.chunk(pt)) {
        chunkModels.add(NoteChunkModel(
          noteId: noteId,
          text: c,
          chunkIndex: idx++,
          page: i + 1,
        ));
      }
    }
    _datasource.saveChunks(chunkModels);

    note.rawText = rawText;
    note.chunkCount = chunkModels.length;
    note.updatedAt = DateTime.now();
    _datasource.update(note);
  }

  /// Indexes every not-yet-indexed note in a notebook (best-effort).
  Future<void> indexNotebook(int notebookId,
      {void Function(int doneNotes, int totalNotes)? onProgress}) async {
    final notes = _datasource.getByNotebookId(notebookId);
    for (var i = 0; i < notes.length; i++) {
      final c = _datasource.indexCounts(notes[i].id);
      if (c.total > 0 && c.embedded == 0) {
        try {
          await indexNote(notes[i].id);
        } catch (_) {}
      }
      onProgress?.call(i + 1, notes.length);
    }
  }
}
