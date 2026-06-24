import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../data/datasources/local/note_annotation_datasource.dart';
import '../../data/models/note_annotation_model.dart';

final noteAnnotationDatasourceProvider =
    Provider<NoteAnnotationDatasource>((ref) {
  return NoteAnnotationDatasource(ref.read(objectBoxProvider));
});

/// The saved annotation for a note (null if none). Used to render the
/// annotate screen and to lock the note's text editing once ink exists.
final noteAnnotationProvider =
    FutureProvider.family<NoteAnnotationModel?, int>((ref, noteId) {
  return ref.read(noteAnnotationDatasourceProvider).getByNoteId(noteId);
});
