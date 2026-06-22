import '../entities/quiz.dart';
import '../entities/quiz_question.dart';
import '../entities/quiz_attempt.dart';
import '../enums/difficulty_level.dart';
import '../enums/question_type.dart';

abstract class IQuizRepository {
  Future<List<Quiz>> getByNotebookId(int notebookId);
  Future<Quiz> generateQuiz({
    required int notebookId,
    required String title,
    required QuestionType questionType,
    required DifficultyLevel difficulty,
    required int questionCount,
  });
  Future<List<QuizQuestion>> getQuestions(int quizId);
  Future<QuizAttempt> submitAttempt({
    required int quizId,
    required Map<int, String> answers,
  });
  Future<List<QuizAttempt>> getAttempts(int quizId);
  Future<void> deleteQuiz(int id);
}
