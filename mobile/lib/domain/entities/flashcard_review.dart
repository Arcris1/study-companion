class FlashcardReview {
  final int id;
  final int flashcardId;
  final int quality;
  final DateTime reviewedAt;

  const FlashcardReview({
    this.id = 0,
    required this.flashcardId,
    required this.quality,
    required this.reviewedAt,
  });
}
