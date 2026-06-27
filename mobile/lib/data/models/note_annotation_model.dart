import 'package:objectbox/objectbox.dart';

/// Freehand ink + margin sidenotes drawn on a note's content.
///
/// Strokes/sidenotes are stored in a "page" coordinate space whose width is
/// [pageWidth] (the width they were drawn at); the page is scaled to fit other
/// screens so ink stays aligned with the text.
@Entity()
class NoteAnnotationModel {
  @Id()
  int id;

  int noteId;

  /// 1-based PDF page this annotation belongs to; 0 for non-PDF (single page).
  int page;

  /// JSON: [{"c": argb, "w": width, "h": isHighlighter, "p": [x,y,x,y,...]}]
  String strokesJson;

  /// JSON: [{"x": x, "y": y, "t": "text"}]
  String sidenotesJson;

  /// The page width (logical px) the ink was drawn at, so it can be scaled to
  /// align on other screen sizes. 0 = legacy (drawn in the old fixed 400 space).
  double pageWidth;

  DateTime updatedAt;

  NoteAnnotationModel({
    this.id = 0,
    required this.noteId,
    this.page = 0,
    this.strokesJson = '[]',
    this.sidenotesJson = '[]',
    this.pageWidth = 0,
    required this.updatedAt,
  });

  bool get isEmpty => strokesJson == '[]' && sidenotesJson == '[]';
}
