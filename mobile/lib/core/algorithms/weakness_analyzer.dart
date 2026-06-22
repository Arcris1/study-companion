import '../../domain/entities/weakness.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_attempt.dart';

class WeaknessAnalyzer {
  /// Analyze quiz attempts to identify weak topics.
  List<Weakness> analyze({
    required List<QuizQuestion> questions,
    required List<QuizAttempt> attempts,
    required int notebookId,
    String notebookTitle = '',
  }) {
    // Group questions by topic
    final topicMap = <String, List<({QuizQuestion question, bool correct})>>{};

    for (final attempt in attempts) {
      for (final question in questions) {
        final topic = question.topic ?? 'General';
        topicMap.putIfAbsent(topic, () => []);

        final userAnswer = attempt.answers[question.questionIndex];
        final isCorrect = userAnswer != null &&
            userAnswer.trim().toLowerCase() ==
                question.correctAnswer.trim().toLowerCase();

        topicMap[topic]!.add((question: question, correct: isCorrect));
      }
    }

    // Calculate accuracy per topic
    return topicMap.entries.map((entry) {
      final results = entry.value;
      final correctCount = results.where((r) => r.correct).length;
      return Weakness(
        topic: entry.key,
        accuracy: results.isEmpty ? 0 : correctCount / results.length,
        questionCount: results.length,
        correctCount: correctCount,
        notebookId: notebookId,
        notebookTitle: notebookTitle,
      );
    }).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
  }
}
