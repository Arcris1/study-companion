import '../enums/note_status.dart';

class Note {
  final int id;
  final int notebookId;
  final String title;
  final String rawText;
  final String? summary;
  final NoteStatus status;
  final String sourceType; // 'pdf', 'txt', 'manual'
  final String? sourcePath;
  final int chunkCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    this.id = 0,
    required this.notebookId,
    required this.title,
    required this.rawText,
    this.summary,
    this.status = NoteStatus.ready,
    this.sourceType = 'manual',
    this.sourcePath,
    this.chunkCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    int? id,
    int? notebookId,
    String? title,
    String? rawText,
    String? summary,
    NoteStatus? status,
    String? sourceType,
    String? sourcePath,
    int? chunkCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      title: title ?? this.title,
      rawText: rawText ?? this.rawText,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      sourcePath: sourcePath ?? this.sourcePath,
      chunkCount: chunkCount ?? this.chunkCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
