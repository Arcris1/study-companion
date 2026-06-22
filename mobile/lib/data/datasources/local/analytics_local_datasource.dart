import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/study_session_model.dart';

class AnalyticsLocalDatasource {
  final ObjectBox _objectBox;

  AnalyticsLocalDatasource(this._objectBox);

  Box<StudySessionModel> get _sessionBox =>
      _objectBox.store.box<StudySessionModel>();

  void saveSession(StudySessionModel model) {
    _sessionBox.put(model);
  }

  List<StudySessionModel> getSessionsByNotebookId(int notebookId) {
    final query = _sessionBox
        .query(StudySessionModel_.notebookId.equals(notebookId))
        .order(StudySessionModel_.startedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  List<StudySessionModel> getSessionsInRange(DateTime from, DateTime to) {
    final query = _sessionBox
        .query(StudySessionModel_.startedAt.betweenDate(from, to))
        .order(StudySessionModel_.startedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  List<StudySessionModel> getAllSessions() {
    final query = _sessionBox
        .query()
        .order(StudySessionModel_.startedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  int getTotalStudyTime() {
    final all = _sessionBox.getAll();
    return all.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }
}
