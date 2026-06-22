import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../data/datasources/local/analytics_local_datasource.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/entities/study_stats.dart';
import 'notebook_provider.dart';
import 'note_provider.dart';
import 'quiz_provider.dart';
import 'flashcard_provider.dart';

final analyticsDatasourceProvider = Provider<AnalyticsLocalDatasource>((ref) {
  return AnalyticsLocalDatasource(ref.read(objectBoxProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    ref.read(analyticsDatasourceProvider),
    ref.read(quizDatasourceProvider),
    ref.read(flashcardDatasourceProvider),
    ref.read(noteDatasourceProvider),
    ref.read(notebookDatasourceProvider),
  );
});

final overallStatsProvider = FutureProvider<StudyStats>((ref) {
  return ref.read(analyticsRepositoryProvider).getOverallStats();
});

final quizPerformanceProvider = FutureProvider.family<
    List<({DateTime date, double score})>, int>((ref, notebookId) {
  return ref
      .read(analyticsRepositoryProvider)
      .getQuizPerformanceOverTime(notebookId);
});

final weeklyActivityProvider =
    FutureProvider<List<({int dayOfWeek, int minutes})>>((ref) {
  return ref.read(analyticsRepositoryProvider).getWeeklyActivity();
});

final studyTimeByNotebookProvider = FutureProvider<
    List<({int notebookId, String notebookTitle, int minutes})>>((ref) {
  return ref.read(analyticsRepositoryProvider).getStudyTimeByNotebook();
});
