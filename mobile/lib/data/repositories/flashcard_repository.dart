import 'dart:convert';
import '../../core/algorithms/sm2.dart';
import '../../core/llm/llm_service.dart';
import '../../core/llm/prompt_templates.dart';
import '../../domain/entities/flashcard_deck.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/i_flashcard_repository.dart';
import '../datasources/local/flashcard_local_datasource.dart';
import '../datasources/local/note_local_datasource.dart';
import '../models/flashcard_deck_model.dart';
import '../models/flashcard_model.dart';
import '../models/flashcard_review_model.dart';

class FlashcardRepository implements IFlashcardRepository {
  final FlashcardLocalDatasource _flashcardDatasource;
  final NoteLocalDatasource _noteDatasource;
  final LlmService _llmService;

  FlashcardRepository(
    this._flashcardDatasource,
    this._noteDatasource,
    this._llmService,
  );

  @override
  Future<List<FlashcardDeck>> getDecks(int notebookId) async {
    final models = _flashcardDatasource.getDecks(notebookId);
    return models.map((m) {
      final cardCount = _flashcardDatasource.getCardCount(m.id);
      final dueCount = _flashcardDatasource.getDueCount(m.id);
      return m.toEntity(cardCount: cardCount, dueCount: dueCount);
    }).toList();
  }

  @override
  Future<FlashcardDeck> createDeck(int notebookId, String title) async {
    final now = DateTime.now();
    final model = _flashcardDatasource.createDeck(FlashcardDeckModel(
      notebookId: notebookId,
      title: title,
      createdAt: now,
      updatedAt: now,
    ));
    return model.toEntity();
  }

  @override
  Future<List<Flashcard>> generateFlashcards(
    int deckId,
    int notebookId, {
    int count = 20,
  }) async {
    // Gather note content from notebook
    final notes = _noteDatasource.getByNotebookId(notebookId);
    if (notes.isEmpty) throw Exception('No notes found in notebook');

    // Collect chunks from all notes
    final allChunks = <String>[];
    for (final note in notes) {
      final chunks = _noteDatasource.getChunks(note.id);
      allChunks.addAll(chunks.map((c) => c.text));
    }

    // Take a selection of chunks to fit context window
    final selectedContent = allChunks.take(15).join('\n\n');

    final prompt = PromptTemplates.generateFlashcards(
      content: selectedContent,
      count: count,
    );

    final response = await _llmService.generate(prompt, maxTokens: 3000);

    // Parse JSON response — try multiple strategies
    List<FlashcardModel> cardModels;
    try {
      List cards;
      try {
        final jsonStr = '{"cards": [$response';
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        cards = parsed['cards'] as List;
      } catch (_) {
        try {
          final parsed = jsonDecode(response) as Map<String, dynamic>;
          cards = parsed['cards'] as List;
        } catch (_) {
          try {
            cards = jsonDecode(response) as List;
          } catch (_) {
            final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
            if (jsonMatch != null) {
              cards = jsonDecode(jsonMatch.group(0)!) as List;
            } else {
              throw const FormatException('No valid JSON found');
            }
          }
        }
      }

      final now = DateTime.now();
      cardModels = <FlashcardModel>[];
      for (final raw in cards) {
        if (raw is! Map) continue;
        final front = raw['front']?.toString().trim() ?? '';
        final back = raw['back']?.toString().trim() ?? '';
        if (front.isEmpty || back.isEmpty) continue;
        cardModels.add(FlashcardModel(
          deckId: deckId,
          front: front,
          back: back,
          cardIndex: cardModels.length,
          createdAt: now,
        ));
      }
      if (cardModels.isEmpty) {
        throw const FormatException('No valid flashcards in response');
      }

      _flashcardDatasource.saveCards(cardModels);

      // Update deck timestamp
      final deck = _flashcardDatasource.getDeckById(deckId);
      if (deck != null) {
        deck.updatedAt = now;
        _flashcardDatasource.updateDeck(deck);
      }

      return cardModels.map((m) => m.toEntity()).toList();
    } catch (e) {
      // If parsing fails, create a single fallback card
      final now = DateTime.now();
      final fallbackCard = FlashcardModel(
        deckId: deckId,
        front: 'Flashcard generation encountered an issue. Please try again.',
        back: 'The AI response could not be parsed into flashcards. Try with different notes or fewer cards.',
        cardIndex: 0,
        createdAt: now,
      );
      _flashcardDatasource.saveCards([fallbackCard]);
      return [fallbackCard.toEntity()];
    }
  }

  @override
  Future<List<Flashcard>> getCards(int deckId) async {
    return _flashcardDatasource.getCards(deckId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<Flashcard>> getDueCards(int deckId) async {
    return _flashcardDatasource.getDueCards(deckId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<Flashcard> reviewCard(int flashcardId, int quality) async {
    final card = _flashcardDatasource.getCardById(flashcardId);
    if (card == null) throw Exception('Flashcard not found');

    // Run SM-2 algorithm
    final result = sm2(
      oldEase: card.easeFactor,
      oldInterval: card.interval,
      oldReps: card.repetitions,
      quality: quality,
    );

    // Update card with SM-2 results
    card.easeFactor = result.easeFactor;
    card.interval = result.interval;
    card.repetitions = result.repetitions;
    card.nextReviewAt = result.nextReviewDate;
    _flashcardDatasource.updateCard(card);

    // Save review record
    _flashcardDatasource.saveReview(FlashcardReviewModel(
      flashcardId: flashcardId,
      quality: quality,
      reviewedAt: DateTime.now(),
    ));

    return card.toEntity();
  }

  @override
  Future<void> deleteDeck(int id) async {
    _flashcardDatasource.deleteDeck(id);
  }
}
