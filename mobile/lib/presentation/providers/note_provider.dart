import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/embedding/embedding_service.dart';
import '../../core/llm/llm_service.dart';
import '../../core/text/text_chunker.dart';
import '../../data/datasources/local/note_local_datasource.dart';
import '../../data/repositories/note_repository.dart';
import '../../domain/entities/note.dart';

final noteDatasourceProvider = Provider<NoteLocalDatasource>((ref) {
  return NoteLocalDatasource(ref.read(objectBoxProvider));
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(
    ref.read(noteDatasourceProvider),
    const TextChunker(),
    ref.read(llmServiceProvider),
    ref.read(embeddingServiceProvider),
  );
});

final notesProvider = NotifierProvider.family<NotesNotifier, AsyncValue<List<Note>>, int>(
  (notebookId) => NotesNotifier(notebookId),
);

class NotesNotifier extends Notifier<AsyncValue<List<Note>>> {
  final int notebookId;
  late NoteRepository _repository;

  NotesNotifier(this.notebookId);

  @override
  AsyncValue<List<Note>> build() {
    _repository = ref.read(noteRepositoryProvider);
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final notes = await _repository.getByNotebookId(notebookId);
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<Note> importFile(String filePath) async {
    final note = await _repository.importFromFile(filePath, notebookId);
    await load();
    return note;
  }

  Future<Note> createManual(String title, String text) async {
    final note = await _repository.createManual(title, text, notebookId);
    await load();
    return note;
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await load();
  }
}
