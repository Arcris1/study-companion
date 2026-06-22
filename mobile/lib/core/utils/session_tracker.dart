import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/objectbox.dart';
import '../../data/datasources/local/analytics_local_datasource.dart';
import '../../data/models/study_session_model.dart';

final sessionTrackerProvider = Provider<SessionTracker>((ref) {
  return SessionTracker(AnalyticsLocalDatasource(ref.read(objectBoxProvider)));
});

class SessionTracker {
  final AnalyticsLocalDatasource _datasource;
  DateTime? _startTime;
  int? _notebookId;
  String? _activityType;

  SessionTracker(this._datasource);

  void start(int notebookId, String activityType) {
    _startTime = DateTime.now();
    _notebookId = notebookId;
    _activityType = activityType;
  }

  void stop() {
    if (_startTime == null || _notebookId == null || _activityType == null) {
      return;
    }
    final now = DateTime.now();
    final duration = now.difference(_startTime!).inSeconds;
    if (duration < 5) return; // Don't track very short sessions

    _datasource.saveSession(StudySessionModel(
      notebookId: _notebookId!,
      activityType: _activityType!,
      durationSeconds: duration,
      startedAt: _startTime!,
      endedAt: now,
    ));
    _startTime = null;
    _notebookId = null;
    _activityType = null;
  }

  bool get isTracking => _startTime != null;
}
