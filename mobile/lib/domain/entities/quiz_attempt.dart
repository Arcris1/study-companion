class QuizAttempt {
  final int id;
  final int quizId;
  final int score;
  final int totalQuestions;
  final Map<int, String> answers; // questionIndex -> answer
  final DateTime completedAt;

  const QuizAttempt({
    this.id = 0,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.answers,
    required this.completedAt,
  });

  double get percentage => totalQuestions > 0 ? score / totalQuestions * 100 : 0;
  String get grade {
    final pct = percentage;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }
}
