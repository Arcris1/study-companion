import 'dart:typed_data';

class NoteChunk {
  final int id;
  final int noteId;
  final String text;
  final int chunkIndex;
  final Float32List? embedding;

  const NoteChunk({
    this.id = 0,
    required this.noteId,
    required this.text,
    required this.chunkIndex,
    this.embedding,
  });
}
