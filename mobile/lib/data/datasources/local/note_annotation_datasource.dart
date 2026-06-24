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
