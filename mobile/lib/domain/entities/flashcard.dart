class Flashcard {
  final int id;
  final int deckId;
  final String front;
  final String back;
  final int cardIndex;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime createdAt;

  const Flashcard({
    this.id = 0,
    required this.deckId,
    required this.front,
    required this.back,
    required this.cardIndex,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReviewAt,
    required this.createdAt,
  });

  bool get isDue => nextReviewAt == null || nextReviewAt!.isBefore(DateTime.now());

  String get statusLabel {
    if (repetitions == 0) return 'New';
    if (interval >= 21) return 'Mastered';
    return 'Learning';
  }
}
