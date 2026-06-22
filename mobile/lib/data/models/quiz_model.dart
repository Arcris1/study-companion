import 'package:objectbox/objectbox.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';

@Entity()
class QuizModel {
  @Id()
  int id;

  int notebookId;
  String title;
  String questionTypeStr;
  String difficultyStr;
  int questionCount;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  QuizModel({
    this.id = 0,
    required this.notebookId,
    required this.title,
    required this.questionTypeStr,
    required this.difficultyStr,
    required this.questionCount,
    required this.createdAt,
  });

  Quiz toEntity() {
    return Quiz(
      id: id,
      notebookId: notebookId,
      title: title,
      questionType: QuestionType.fromString(questionTypeStr),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == difficultyStr,
        orElse: () => DifficultyLevel.medium,
      ),
      questionCount: questionCount,
      createdAt: createdAt,
    );
  }

  factory QuizModel.fromEntity(Quiz entity) {
    return QuizModel(
      id: entity.id,
      notebookId: entity.notebookId,
      title: entity.title,
      questionTypeStr: entity.questionType.name,
      difficultyStr: entity.difficulty.name,
      questionCount: entity.questionCount,
      createdAt: entity.createdAt,
    );
  }
}
