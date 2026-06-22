import '../enums/difficulty_level.dart';
import '../enums/question_type.dart';

class Quiz {
  final int id;
  final int notebookId;
  final String title;
  final QuestionType questionType;
  final DifficultyLevel difficulty;
  final int questionCount;
  final DateTime createdAt;

  const Quiz({
    this.id = 0,
    required this.notebookId,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.questionCount,
    required this.createdAt,
  });
}
