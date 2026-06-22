import '../entities/study_stats.dart';

abstract class IAnalyticsRepository {
  Future<StudyStats> getOverallStats();
  Future<List<({DateTime date, double score})>> getQuizPerformanceOverTime(int notebookId);
  Future<List<({int dayOfWeek, int minutes})>> getWeeklyActivity();
  Future<List<({int notebookId, String notebookTitle, int minutes})>> getStudyTimeByNotebook();
  Future<int> calculateStreak();
}
