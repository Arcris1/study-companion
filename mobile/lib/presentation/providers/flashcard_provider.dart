import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/llm/llm_service.dart';
import '../../data/datasources/local/flashcard_local_datasource.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../domain/entities/flashcard_deck.dart';
import '../../domain/entities/flashcard.dart';
import 'note_provider.dart';

final flashcardDatasourceProvider = Provider<FlashcardLocalDatasource>((ref) {
  return FlashcardLocalDatasource(ref.read(objectBoxProvider));
});

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository(
    ref.read(flashcardDatasourceProvider),
    ref.read(noteDatasourceProvider),
    ref.read(llmServiceProvider),
  );
});

// Use simple FutureProvider instead of Notifier to avoid _dependents.isEmpty
final flashcardDecksProvider = FutureProvider.family<List<FlashcardDeck>, int>((ref, notebookId) {
  return ref.read(flashcardRepositoryProvider).getDecks(notebookId);
});

final dueFlashcardsProvider = FutureProvider.family<List<Flashcard>, int>((ref, deckId) {
  return ref.read(flashcardRepositoryProvider).getDueCards(deckId);
});

final allFlashcardsProvider = FutureProvider.family<List<Flashcard>, int>((ref, deckId) {
  return ref.read(flashcardRepositoryProvider).getCards(deckId);
});
