import '../enums/question_type.dart';

class QuizQuestion {
  final int id;
  final int quizId;
  final String question;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final int questionIndex;
  final String? topic;

  const QuizQuestion({
    this.id = 0,
    required this.quizId,
    required this.question,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
    required this.questionIndex,
    this.topic,
  });
}
