import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/note_annotation_model.dart';

class NoteAnnotationDatasource {
  final ObjectBox _objectBox;

  NoteAnnotationDatasource(this._objectBox);

  Box<NoteAnnotationModel> get _box =>
      _objectBox.store.box<NoteAnnotationModel>();

  NoteAnnotationModel? getByNoteId(int noteId) {
    final query =
        _box.query(NoteAnnotationModel_.noteId.equals(noteId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  /// Annotation for a specific PDF page (page 0 = non-PDF single page).
  NoteAnnotationModel? getByNoteAndPage(int noteId, int page) {
    final query = _box
        .query(NoteAnnotationModel_.noteId.equals(noteId) &
            NoteAnnotationModel_.page.equals(page))
        .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  /// Whether the note has any annotations (any page).
  bool hasAny(int noteId) {
    final query =
        _box.query(NoteAnnotationModel_.noteId.equals(noteId)).build();
    final n = query.count();
    query.close();
    return n > 0;
  }

  NoteAnnotationModel save(NoteAnnotationModel model) {
    final id = _box.put(model);
    return _box.get(id)!;
  }

  void deleteByNoteId(int noteId) {
    final query =
        _box.query(NoteAnnotationModel_.noteId.equals(noteId)).build();
    final ids = query.find().map((a) => a.id).toList();
    query.close();
    _box.removeMany(ids);
  }
}
