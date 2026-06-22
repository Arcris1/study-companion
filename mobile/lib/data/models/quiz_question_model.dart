import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/enums/question_type.dart';

@Entity()
class QuizQuestionModel {
  @Id()
  int id;

  int quizId;
  String question;
  String typeStr;
  String optionsJson; // JSON-encoded List<String>
  String correctAnswer;
  String? explanation;
  int questionIndex;
  String? topic;

  QuizQuestionModel({
    this.id = 0,
    required this.quizId,
    required this.question,
    required this.typeStr,
    this.optionsJson = '[]',
    required this.correctAnswer,
    this.explanation,
    required this.questionIndex,
    this.topic,
  });

  List<String> get options =>
      (jsonDecode(optionsJson) as List).cast<String>();

  set options(List<String> value) =>
      optionsJson = jsonEncode(value);

  QuizQuestion toEntity() {
    return QuizQuestion(
      id: id,
      quizId: quizId,
      question: question,
      type: QuestionType.fromString(typeStr),
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      questionIndex: questionIndex,
      topic: topic,
    );
  }

  factory QuizQuestionModel.fromEntity(QuizQuestion entity) {
    return QuizQuestionModel(
      id: entity.id,
      quizId: entity.quizId,
      question: entity.question,
      typeStr: entity.type.name,
      optionsJson: jsonEncode(entity.options),
      correctAnswer: entity.correctAnswer,
      explanation: entity.explanation,
      questionIndex: entity.questionIndex,
      topic: entity.topic,
    );
  }
}
