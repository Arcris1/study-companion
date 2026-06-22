import 'package:objectbox/objectbox.dart';

/// A saved highlight/annotation on a note: the quoted text, a color tag, and
/// an optional attached note. (Stored as text rather than character offsets,
/// since the note content is rendered Markdown.)
@Entity()
class HighlightModel {
  @Id()
  int id;

  int noteId;

  String text;

  /// ARGB color value of the highlight tag.
  int colorValue;

  String? note;

  DateTime createdAt;

  HighlightModel({
    this.id = 0,
    required this.noteId,
    required this.text,
    required this.colorValue,
    this.note,
    required this.createdAt,
  });
}
