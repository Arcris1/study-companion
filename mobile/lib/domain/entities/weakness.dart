class Weakness {
  final String topic;
  final double accuracy; // 0.0-1.0
  final int questionCount;
  final int correctCount;
  final int notebookId;
  final String notebookTitle;

  const Weakness({
    required this.topic,
    required this.accuracy,
    required this.questionCount,
    required this.correctCount,
    required this.notebookId,
    this.notebookTitle = '',
  });

  String get strengthLabel {
    if (accuracy >= 0.8) return 'Strong';
    if (accuracy >= 0.6) return 'Average';
    if (accuracy >= 0.4) return 'Weak';
    return 'Very Weak';
  }

  bool get isWeak => accuracy < 0.6;
}
