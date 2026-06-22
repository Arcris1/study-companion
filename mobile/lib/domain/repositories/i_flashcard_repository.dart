import '../entities/flashcard_deck.dart';
import '../entities/flashcard.dart';

abstract class IFlashcardRepository {
  Future<List<FlashcardDeck>> getDecks(int notebookId);
  Future<FlashcardDeck> createDeck(int notebookId, String title);
  Future<List<Flashcard>> generateFlashcards(int deckId, int notebookId, {int count = 20});
  Future<List<Flashcard>> getCards(int deckId);
  Future<List<Flashcard>> getDueCards(int deckId);
  Future<Flashcard> reviewCard(int flashcardId, int quality);
  Future<void> deleteDeck(int id);
}
