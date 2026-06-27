import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';
import '../../domain/entities/note_chunk.dart';

@Entity()
class NoteChunkModel {
  @Id()
  int id;

  int noteId;

  @Index()
  String text;

  int chunkIndex;

  /// 1-based source page (for PDFs); 0 for non-paged sources.
  int page;

  @HnswIndex(dimensions: 384)
  Float32List? embedding;

  NoteChunkModel({
    this.id = 0,
    required this.noteId,
    required this.text,
    required this.chunkIndex,
    this.page = 0,
    this.embedding,
  });

  NoteChunk toEntity() {
    return NoteChunk(
      id: id,
      noteId: noteId,
      text: text,
      chunkIndex: chunkIndex,
      embedding: embedding,
    );
  }

  factory NoteChunkModel.fromEntity(NoteChunk entity) {
    return NoteChunkModel(
      id: entity.id,
      noteId: entity.noteId,
      text: entity.text,
      chunkIndex: entity.chunkIndex,
      embedding: entity.embedding,
    );
  }
}
