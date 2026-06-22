class FlashcardDeck {
  final int id;
  final int notebookId;
  final String title;
  final int cardCount;
  final int dueCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlashcardDeck({
    this.id = 0,
    required this.notebookId,
    required this.title,
    this.cardCount = 0,
    this.dueCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}
