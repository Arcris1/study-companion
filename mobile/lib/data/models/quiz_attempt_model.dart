import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import '../../domain/entities/quiz_attempt.dart';

@Entity()
class QuizAttemptModel {
  @Id()
  int id;

  int quizId;
  int score;
  int totalQuestions;
  String answersJson; // JSON-encoded Map<int, String>

  @Property(type: PropertyType.dateNano)
  DateTime completedAt;

  QuizAttemptModel({
    this.id = 0,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    this.answersJson = '{}',
    required this.completedAt,
  });

  Map<int, String> get answers {
    final decoded = jsonDecode(answersJson) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  set answers(Map<int, String> value) {
    answersJson = jsonEncode(value.map((k, v) => MapEntry(k.toString(), v)));
  }

  QuizAttempt toEntity() {
    return QuizAttempt(
      id: id,
      quizId: quizId,
      score: score,
      totalQuestions: totalQuestions,
      answers: answers,
      completedAt: completedAt,
    );
  }

  factory QuizAttemptModel.fromEntity(QuizAttempt entity) {
    final model = QuizAttemptModel(
      id: entity.id,
      quizId: entity.quizId,
      score: entity.score,
      totalQuestions: entity.totalQuestions,
      completedAt: entity.completedAt,
    );
    model.answers = entity.answers;
    return model;
  }
}
