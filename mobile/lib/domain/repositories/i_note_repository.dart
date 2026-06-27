import '../entities/note.dart';
import '../entities/note_chunk.dart';

abstract class INoteRepository {
  Future<List<Note>> getByNotebookId(int notebookId);
  Future<Note?> getById(int id);
  Future<Note> importFromFile(String filePath, int notebookId);
  Future<Note> createManual(String title, String text, int notebookId);
  Future<Note> update(Note note);
  Future<void> delete(int id);
  Future<String> generateSummary(int noteId);
  Future<void> indexNote(int noteId,
      {void Function(int done, int total)? onProgress});
  Future<List<NoteChunk>> getChunks(int noteId);
  Future<List<NoteChunk>> searchChunks(int notebookId, String query);
}
