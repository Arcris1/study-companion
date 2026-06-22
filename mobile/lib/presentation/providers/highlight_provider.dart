import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../data/datasources/local/highlight_local_datasource.dart';
import '../../data/models/highlight_model.dart';

final highlightDatasourceProvider = Provider<HighlightLocalDatasource>((ref) {
  return HighlightLocalDatasource(ref.read(objectBoxProvider));
});

final highlightsProvider =
    FutureProvider.family<List<HighlightModel>, int>((ref, noteId) {
  return ref.read(highlightDatasourceProvider).getByNoteId(noteId);
});
