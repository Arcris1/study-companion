import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/highlight_model.dart';

class HighlightLocalDatasource {
  final ObjectBox _objectBox;

  HighlightLocalDatasource(this._objectBox);

  Box<HighlightModel> get _box => _objectBox.store.box<HighlightModel>();

  List<HighlightModel> getByNoteId(int noteId) {
    final query = _box
        .query(HighlightModel_.noteId.equals(noteId))
        .order(HighlightModel_.createdAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  HighlightModel save(HighlightModel model) {
    final id = _box.put(model);
    return _box.get(id)!;
  }

  void delete(int id) => _box.remove(id);

  void deleteByNoteId(int noteId) {
    final query = _box.query(HighlightModel_.noteId.equals(noteId)).build();
    final ids = query.find().map((h) => h.id).toList();
    query.close();
    _box.removeMany(ids);
  }
}
