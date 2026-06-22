import '../../domain/entities/study_stats.dart';
import '../../domain/repositories/i_analytics_repository.dart';
import '../datasources/local/analytics_local_datasource.dart';
import '../datasources/local/quiz_local_datasource.dart';
import '../datasources/local/flashcard_local_datasource.dart';
import '../datasources/local/note_local_datasource.dart';
import '../datasources/local/notebook_local_datasource.dart';

class AnalyticsRepository implements IAnalyticsRepository {
  final AnalyticsLocalDatasource _analyticsDatasource;
  final QuizLocalDatasource _quizDatasource;
  final FlashcardLocalDatasource _flashcardDatasource;
  final NoteLocalDatasource _noteDatasource;
  final NotebookLocalDatasource _notebookDatasource;

  AnalyticsRepository(
    this._analyticsDatasource,
    this._quizDatasource,
    this._flashcardDatasource,
    this._noteDatasource,
    this._notebookDatasource,
  );

  @override
  Future<StudyStats> getOverallStats() async {
    final totalSeconds = _analyticsDatasource.getTotalStudyTime();
    final totalMinutes = totalSeconds ~/ 60;

    // Sessions this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final sessionsThisWeek =
        _analyticsDatasource.getSessionsInRange(startOfWeek, now).length;

    // Streak
    final streak = await calculateStreak();

    // Quiz stats
    final notebooks = _notebookDatasource.getAll();
    int totalQuizzesTaken = 0;
    double totalScore = 0;
    int totalAttempts = 0;

    for (final notebook in notebooks) {
      final quizzes = _quizDatasource.getByNotebookId(notebook.id);
      for (final quiz in quizzes) {
        final attempts = _quizDatasource.getAttempts(quiz.id);
        totalQuizzesTaken += attempts.length;
        for (final attempt in attempts) {
          if (attempt.totalQuestions > 0) {
            totalScore += (attempt.score / attempt.totalQuestions) * 100;
            totalAttempts++;
          }
        }
      }
    }

    final averageScore = totalAttempts > 0 ? totalScore / totalAttempts : 0.0;

    // Note count
    int totalNotes = 0;
    for (final notebook in notebooks) {
      totalNotes += _noteDatasource.getByNotebookId(notebook.id).length;
    }

    // Flashcard reviews
    int totalFlashcardsReviewed = 0;
    for (final notebook in notebooks) {
      final decks = _flashcardDatasource.getDecks(notebook.id);
      for (final deck in decks) {
        totalFlashcardsReviewed +=
            _flashcardDatasource.getAllReviewsForDeck(deck.id).length;
      }
    }

    return StudyStats(
      totalStudyMinutes: totalMinutes,
      sessionsThisWeek: sessionsThisWeek,
      streakDays: streak,
      averageQuizScore: averageScore,
      totalNotesCreated: totalNotes,
      totalQuizzesTaken: totalQuizzesTaken,
      totalFlashcardsReviewed: totalFlashcardsReviewed,
    );
  }

  @override
  Future<List<({DateTime date, double score})>> getQuizPerformanceOverTime(
      int notebookId) async {
    final quizzes = _quizDatasource.getByNotebookId(notebookId);
    final results = <({DateTime date, double score})>[];

    for (final quiz in quizzes) {
      final attempts = _quizDatasource.getAttempts(quiz.id);
      for (final attempt in attempts) {
        if (attempt.totalQuestions > 0) {
          final score = (attempt.score / attempt.totalQuestions) * 100;
          results.add((date: attempt.completedAt, score: score));
        }
      }
    }

    // Sort by date ascending
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  @override
  Future<List<({int dayOfWeek, int minutes})>> getWeeklyActivity() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final sessions =
        _analyticsDatasource.getSessionsInRange(startOfWeek, endOfWeek);

    // Initialize 7 days (1=Monday ... 7=Sunday)
    final dayMinutes = <int, int>{};
    for (int i = 1; i <= 7; i++) {
      dayMinutes[i] = 0;
    }

    for (final session in sessions) {
      final dow = session.startedAt.weekday;
      dayMinutes[dow] = (dayMinutes[dow] ?? 0) + (session.durationSeconds ~/ 60);
    }

    return dayMinutes.entries
        .map((e) => (dayOfWeek: e.key, minutes: e.value))
        .toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  }

  @override
  Future<List<({int notebookId, String notebookTitle, int minutes})>>
      getStudyTimeByNotebook() async {
    final notebooks = _notebookDatasource.getAll();
    final results = <({int notebookId, String notebookTitle, int minutes})>[];

    for (final notebook in notebooks) {
      final sessions =
          _analyticsDatasource.getSessionsByNotebookId(notebook.id);
      final totalSeconds =
          sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
      if (totalSeconds > 0) {
        results.add((
          notebookId: notebook.id,
          notebookTitle: notebook.title,
          minutes: totalSeconds ~/ 60,
        ));
      }
    }

    return results;
  }

  @override
  Future<int> calculateStreak() async {
    final allSessions = _analyticsDatasource.getAllSessions();
    if (allSessions.isEmpty) return 0;

    // Get unique days with sessions
    final uniqueDays = <DateTime>{};
    for (final session in allSessions) {
      uniqueDays.add(DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      ));
    }

    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

    // Check if today or yesterday has activity (otherwise streak is broken)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    if (!sortedDays.contains(todayDate) &&
        !sortedDays.contains(yesterdayDate)) {
      return 0;
    }

    // Count consecutive days from the most recent
    int streak = 1;
    for (int i = 0; i < sortedDays.length - 1; i++) {
      final diff = sortedDays[i].difference(sortedDays[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
