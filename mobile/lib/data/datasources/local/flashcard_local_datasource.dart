import 'package:objectbox/objectbox.dart';
import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/flashcard_deck_model.dart';
import '../../models/flashcard_model.dart';
import '../../models/flashcard_review_model.dart';

class FlashcardLocalDatasource {
  final ObjectBox _objectBox;

  FlashcardLocalDatasource(this._objectBox);

  Box<FlashcardDeckModel> get _deckBox => _objectBox.store.box<FlashcardDeckModel>();
  Box<FlashcardModel> get _cardBox => _objectBox.store.box<FlashcardModel>();
  Box<FlashcardReviewModel> get _reviewBox => _objectBox.store.box<FlashcardReviewModel>();

  // ── Deck CRUD ──────────────────────────────────────────────────────

  List<FlashcardDeckModel> getDecks(int notebookId) {
    final query = _deckBox.query(FlashcardDeckModel_.notebookId.equals(notebookId))
        .order(FlashcardDeckModel_.createdAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  FlashcardDeckModel? getDeckById(int id) {
    return _deckBox.get(id);
  }

  FlashcardDeckModel createDeck(FlashcardDeckModel model) {
    final id = _deckBox.put(model);
    return _deckBox.get(id)!;
  }

  void updateDeck(FlashcardDeckModel model) {
    _deckBox.put(model);
  }

  void deleteDeck(int id) {
    // Delete all reviews for cards in this deck
    final cards = getCards(id);
    for (final card in cards) {
      final rQuery = _reviewBox.query(FlashcardReviewModel_.flashcardId.equals(card.id)).build();
      final rIds = rQuery.find().map((r) => r.id).toList();
      rQuery.close();
      _reviewBox.removeMany(rIds);
    }

    // Delete cards
    final cQuery = _cardBox.query(FlashcardModel_.deckId.equals(id)).build();
    final cIds = cQuery.find().map((c) => c.id).toList();
    cQuery.close();
    _cardBox.removeMany(cIds);

    // Delete deck
    _deckBox.remove(id);
  }

  // ── Card CRUD ──────────────────────────────────────────────────────

  List<FlashcardModel> getCards(int deckId) {
    final query = _cardBox.query(FlashcardModel_.deckId.equals(deckId))
        .order(FlashcardModel_.cardIndex)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  FlashcardModel? getCardById(int id) {
    return _cardBox.get(id);
  }

  void saveCards(List<FlashcardModel> cards) {
    _cardBox.putMany(cards);
  }

  void updateCard(FlashcardModel card) {
    _cardBox.put(card);
  }

  int getCardCount(int deckId) {
    final query = _cardBox.query(FlashcardModel_.deckId.equals(deckId)).build();
    final count = query.count();
    query.close();
    return count;
  }

  List<FlashcardModel> getDueCards(int deckId) {
    final now = DateTime.now();
    final allCards = getCards(deckId);
    // Cards are due if nextReviewAt is null (new) or <= now
    return allCards.where((card) {
      return card.nextReviewAt == null || !card.nextReviewAt!.isAfter(now);
    }).toList();
  }

  int getDueCount(int deckId) {
    return getDueCards(deckId).length;
  }

  // ── Review CRUD ────────────────────────────────────────────────────

  FlashcardReviewModel saveReview(FlashcardReviewModel model) {
    final id = _reviewBox.put(model);
    return _reviewBox.get(id)!;
  }

  List<FlashcardReviewModel> getReviews(int flashcardId) {
    final query = _reviewBox.query(FlashcardReviewModel_.flashcardId.equals(flashcardId))
        .order(FlashcardReviewModel_.reviewedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  List<FlashcardReviewModel> getAllReviewsForDeck(int deckId) {
    final cards = getCards(deckId);
    final allReviews = <FlashcardReviewModel>[];
    for (final card in cards) {
      allReviews.addAll(getReviews(card.id));
    }
    return allReviews;
  }
}
