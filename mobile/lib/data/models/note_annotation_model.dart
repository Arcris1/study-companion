import 'package:objectbox/objectbox.dart';

/// Freehand ink + margin sidenotes drawn on a note's content.
///
/// Strokes/sidenotes are stored in a fixed 400-wide "page" coordinate space so
/// they render identically on any screen (the page is scaled to fit).
@Entity()
class NoteAnnotationModel {
  @Id()
  int id;

  int noteId;

  /// JSON: [{"c": argb, "w": width, "h": isHighlighter, "p": [x,y,x,y,...]}]
  String strokesJson;

  /// JSON: [{"x": x, "y": y, "t": "text"}]
  String sidenotesJson;

  DateTime updatedAt;

  NoteAnnotationModel({
    this.id = 0,
    required this.noteId,
    this.strokesJson = '[]',
    this.sidenotesJson = '[]',
    required this.updatedAt,
  });

  bool get isEmpty => strokesJson == '[]' && sidenotesJson == '[]';
}
