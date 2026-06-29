import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/llm/llm_service.dart';
import '../../data/datasources/local/quiz_local_datasource.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/quiz_style.dart';
import '../../domain/enums/question_type.dart';
import 'note_provider.dart';

final quizDatasourceProvider = Provider<QuizLocalDatasource>((ref) {
  return QuizLocalDatasource(ref.read(objectBoxProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(
    ref.read(quizDatasourceProvider),
    ref.read(noteDatasourceProvider),
    ref.read(llmServiceProvider),
  );
});

final quizzesProvider = NotifierProvider.family<QuizzesNotifier, AsyncValue<List<Quiz>>, int>(
  (notebookId) => QuizzesNotifier(notebookId),
);

class QuizzesNotifier extends Notifier<AsyncValue<List<Quiz>>> {
  final int notebookId;
  late QuizRepository _repository;

  QuizzesNotifier(this.notebookId);

  @override
  AsyncValue<List<Quiz>> build() {
    _repository = ref.read(quizRepositoryProvider);
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final quizzes = await _repository.getByNotebookId(notebookId);
      state = AsyncValue.data(quizzes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<Quiz> generate({
    required String title,
    required QuestionType questionType,
    required DifficultyLevel difficulty,
    required int questionCount,
    QuizStyle style = QuizStyle.mixed,
    List<int>? noteIds,
  }) async {
    final quiz = await _repository.generateQuiz(
      notebookId: notebookId,
      title: title,
      questionType: questionType,
      difficulty: difficulty,
      questionCount: questionCount,
      style: style,
      noteIds: noteIds,
    );
    await load();
    return quiz;
  }

  Future<void> delete(int id) async {
    await _repository.deleteQuiz(id);
    await load();
  }
}

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, int>((ref, quizId) {
  return ref.read(quizRepositoryProvider).getQuestions(quizId);
});

final quizAttemptsProvider = FutureProvider.family<List<QuizAttempt>, int>((ref, quizId) {
  return ref.read(quizRepositoryProvider).getAttempts(quizId);
});
