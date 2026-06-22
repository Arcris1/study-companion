import 'note_chunk.dart';

class SearchResult {
  final NoteChunk chunk;
  final String noteTitle;
  final String notebookTitle;
  final double relevanceScore;
  final int notebookId;
  final int noteId;

  const SearchResult({
    required this.chunk,
    required this.noteTitle,
    required this.notebookTitle,
    required this.relevanceScore,
    required this.notebookId,
    required this.noteId,
  });
}
