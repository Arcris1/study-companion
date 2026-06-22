import 'package:objectbox/objectbox.dart';
import '../../domain/entities/note.dart';
import '../../domain/enums/note_status.dart';

@Entity()
class NoteModel {
  @Id()
  int id;

  int notebookId;
  String title;
  String rawText;
  String? summary;
  String statusStr;
  String sourceType;
  String? sourcePath;
  int chunkCount;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  NoteModel({
    this.id = 0,
    required this.notebookId,
    required this.title,
    required this.rawText,
    this.summary,
    this.statusStr = 'ready',
    this.sourceType = 'manual',
    this.sourcePath,
    this.chunkCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteStatus get status => NoteStatus.values.firstWhere(
    (e) => e.name == statusStr,
    orElse: () => NoteStatus.ready,
  );

  set status(NoteStatus value) => statusStr = value.name;

  Note toEntity() {
    return Note(
      id: id,
      notebookId: notebookId,
      title: title,
      rawText: rawText,
      summary: summary,
      status: status,
      sourceType: sourceType,
      sourcePath: sourcePath,
      chunkCount: chunkCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory NoteModel.fromEntity(Note entity) {
    return NoteModel(
      id: entity.id,
      notebookId: entity.notebookId,
      title: entity.title,
      rawText: entity.rawText,
      summary: entity.summary,
      statusStr: entity.status.name,
      sourceType: entity.sourceType,
      sourcePath: entity.sourcePath,
      chunkCount: entity.chunkCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
