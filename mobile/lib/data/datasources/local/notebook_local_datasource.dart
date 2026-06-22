import 'package:objectbox/objectbox.dart';
import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/notebook_model.dart';
import '../../models/note_model.dart';
import '../../models/note_chunk_model.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_question_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/chat_session_model.dart';
import '../../models/chat_message_model.dart';
import '../../models/flashcard_deck_model.dart';
import '../../models/flashcard_model.dart';
import '../../models/flashcard_review_model.dart';

class NotebookLocalDatasource {
  final ObjectBox _objectBox;

  NotebookLocalDatasource(this._objectBox);

  Box<NotebookModel> get _box => _objectBox.store.box<NotebookModel>();
  Box<NoteModel> get _noteBox => _objectBox.store.box<NoteModel>();
  Box<NoteChunkModel> get _chunkBox => _objectBox.store.box<NoteChunkModel>();
  Box<QuizModel> get _quizBox => _objectBox.store.box<QuizModel>();
  Box<QuizQuestionModel> get _questionBox => _objectBox.store.box<QuizQuestionModel>();
  Box<QuizAttemptModel> get _attemptBox => _objectBox.store.box<QuizAttemptModel>();
  Box<ChatSessionModel> get _sessionBox => _objectBox.store.box<ChatSessionModel>();
  Box<ChatMessageModel> get _messageBox => _objectBox.store.box<ChatMessageModel>();
  Box<FlashcardDeckModel> get _deckBox => _objectBox.store.box<FlashcardDeckModel>();
  Box<FlashcardModel> get _cardBox => _objectBox.store.box<FlashcardModel>();
  Box<FlashcardReviewModel> get _reviewBox => _objectBox.store.box<FlashcardReviewModel>();

  List<NotebookModel> getAll() {
    final query = _box.query().order(NotebookModel_.updatedAt, flags: Order.descending).build();
    final results = query.find();
    query.close();
    return results;
  }

  int getNoteCount(int notebookId) {
    final query = _noteBox.query(NoteModel_.notebookId.equals(notebookId)).build();
    final count = query.count();
    query.close();
    return count;
  }

  NotebookModel? getById(int id) {
    return _box.get(id);
  }

  NotebookModel create(NotebookModel model) {
    final id = _box.put(model);
    return _box.get(id)!;
  }

  NotebookModel update(NotebookModel model) {
    _box.put(model);
    return _box.get(model.id)!;
  }

  void delete(int id) {
    // Delete all notes and their chunks
    final noteQuery = _noteBox.query(NoteModel_.notebookId.equals(id)).build();
    final notes = noteQuery.find();
    noteQuery.close();
    for (final note in notes) {
      final chunkQuery = _chunkBox.query(NoteChunkModel_.noteId.equals(note.id)).build();
      final chunkIds = chunkQuery.find().map((c) => c.id).toList();
      chunkQuery.close();
      _chunkBox.removeMany(chunkIds);
      _noteBox.remove(note.id);
    }

    // Delete all quizzes and their questions + attempts
    final quizQuery = _quizBox.query(QuizModel_.notebookId.equals(id)).build();
    final quizzes = quizQuery.find();
    quizQuery.close();
    for (final quiz in quizzes) {
      final qQuery = _questionBox.query(QuizQuestionModel_.quizId.equals(quiz.id)).build();
      final qIds = qQuery.find().map((q) => q.id).toList();
      qQuery.close();
      _questionBox.removeMany(qIds);

      final aQuery = _attemptBox.query(QuizAttemptModel_.quizId.equals(quiz.id)).build();
      final aIds = aQuery.find().map((a) => a.id).toList();
      aQuery.close();
      _attemptBox.removeMany(aIds);

      _quizBox.remove(quiz.id);
    }

    // Delete all chat sessions and their messages
    final sessionQuery = _sessionBox.query(ChatSessionModel_.notebookId.equals(id)).build();
    final sessions = sessionQuery.find();
    sessionQuery.close();
    for (final session in sessions) {
      final mQuery = _messageBox.query(ChatMessageModel_.sessionId.equals(session.id)).build();
      final mIds = mQuery.find().map((m) => m.id).toList();
      mQuery.close();
      _messageBox.removeMany(mIds);
      _sessionBox.remove(session.id);
    }

    // Delete all flashcard decks and their cards + reviews
    final deckQuery = _deckBox.query(FlashcardDeckModel_.notebookId.equals(id)).build();
    final decks = deckQuery.find();
    deckQuery.close();
    for (final deck in decks) {
      final cardQuery = _cardBox.query(FlashcardModel_.deckId.equals(deck.id)).build();
      final cards = cardQuery.find();
      cardQuery.close();
      for (final card in cards) {
        final rQuery = _reviewBox.query(FlashcardReviewModel_.flashcardId.equals(card.id)).build();
        final rIds = rQuery.find().map((r) => r.id).toList();
        rQuery.close();
        _reviewBox.removeMany(rIds);
      }
      final cIds = cards.map((c) => c.id).toList();
      _cardBox.removeMany(cIds);
      _deckBox.remove(deck.id);
    }

    _box.remove(id);
  }
}
