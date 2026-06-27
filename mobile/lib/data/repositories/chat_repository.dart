import '../../core/ai/ai_config.dart';
import '../../core/embedding/embedding_service.dart';
import '../../core/llm/llm_service.dart';
import '../../core/llm/prompt_templates.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/local/chat_local_datasource.dart';
import '../datasources/local/note_local_datasource.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';
import '../models/note_chunk_model.dart';

class ChatRepository implements IChatRepository {
  final ChatLocalDatasource _chatDatasource;
  final NoteLocalDatasource _noteDatasource;
  final LlmService _llmService;
  final EmbeddingService _embeddingService;

  ChatRepository(
    this._chatDatasource,
    this._noteDatasource,
    this._llmService,
    this._embeddingService,
  );

  @override
  Future<List<ChatSession>> getSessionsByNotebookId(int notebookId) async {
    final models = _chatDatasource.getSessionsByNotebookId(notebookId);
    return models.map((m) => m.toEntity(
      messageCount: _chatDatasource.getMessageCount(m.id),
    )).toList();
  }

  @override
  Future<ChatSession> createSession(int notebookId, String title) async {
    final now = DateTime.now();
    final model = _chatDatasource.createSession(ChatSessionModel(
      notebookId: notebookId,
      title: title,
      createdAt: now,
      updatedAt: now,
    ));
    return model.toEntity();
  }

  @override
  Future<List<ChatMessage>> getMessages(int sessionId) async {
    return _chatDatasource.getMessages(sessionId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Stream<String> sendMessage(int sessionId, String message) async* {
    // Save user message
    _chatDatasource.saveMessage(ChatMessageModel(
      sessionId: sessionId,
      content: message,
      isUser: true,
      createdAt: DateTime.now(),
    ));

    // Get session and recent chat history for context
    final session = _chatDatasource.getSessionById(sessionId);
    final recentMessages = _chatDatasource.getMessages(sessionId);

    // Auto-name the session from the first user message
    if (session != null && session.title == 'New Chat' && recentMessages.length <= 1) {
      final title = message.length > 40 ? '${message.substring(0, 40)}...' : message;
      session.title = title;
      session.updatedAt = DateTime.now();
      _chatDatasource.updateSession(session);
    }

    // Build search query — for short messages like "yes", "explain more",
    // use the previous conversation to understand what the user is asking about
    final searchQuery = _buildSearchQuery(message, recentMessages);

    // RAG: Search for relevant chunks in this notebook. Keep the chunk objects
    // (not just text) so each can be attributed to its source note.
    final relevantChunks = <NoteChunkModel>[];
    if (session != null && searchQuery.isNotEmpty) {
      if (_embeddingService.isReady) {
        try {
          final queryEmbedding = await _embeddingService.embed(searchQuery);
          relevantChunks.addAll(_noteDatasource.searchChunksByVector(
            session.notebookId,
            queryEmbedding,
          ));
        } catch (_) {
          relevantChunks.addAll(
            _noteDatasource.searchChunks(session.notebookId, searchQuery),
          );
        }
      } else {
        relevantChunks.addAll(
          _noteDatasource.searchChunks(session.notebookId, searchQuery),
        );
      }
    }

    // Provide a generous RAG context (OpenAI has a large context window).
    var context = 'No specific context found. Answer based on general knowledge.';
    if (relevantChunks.isNotEmpty) {
      final buffer = StringBuffer();
      for (final chunk in relevantChunks) {
        if (buffer.length + chunk.text.length > 8000) break;
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(chunk.text);
      }
      if (buffer.isNotEmpty) context = buffer.toString();
    }

    // Build readable sources: one entry per cited note, stored as
    // "<note title> · p.X, Y\n<snippet>" (the bubble shows the title line and
    // expands to the snippet). Page numbers come from PDF chunks (page > 0).
    final pagesByNote = <int, Set<int>>{};
    for (final chunk in relevantChunks) {
      if (chunk.page > 0) {
        (pagesByNote[chunk.noteId] ??= <int>{}).add(chunk.page);
      }
    }
    final sources = <String>[];
    final seenNotes = <int>{};
    for (final chunk in relevantChunks) {
      if (!seenNotes.add(chunk.noteId)) continue;
      final note = _noteDatasource.getById(chunk.noteId);
      final title = (note != null && note.title.trim().isNotEmpty)
          ? note.title.trim()
          : 'Untitled note';
      final pages = (pagesByNote[chunk.noteId] ?? const <int>{}).toList()
        ..sort();
      final pageStr = pages.isEmpty
          ? ''
          : ' · p.${pages.take(6).join(', ')}${pages.length > 6 ? '…' : ''}';
      final snippet = chunk.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final shortSnippet = snippet.length > 180
          ? '${snippet.substring(0, 180).trim()}…'
          : snippet;
      sources.add('$title$pageStr\n$shortSnippet');
    }

    final historyStr = _buildHistory(recentMessages, maxMessages: 10);

    final prompt = PromptTemplates.answerWithHistory(
      context: context,
      history: historyStr,
      question: message,
    );

    // Stream response
    final buffer = StringBuffer();
    await for (final token in _llmService.generateStream(
      prompt,
      maxTokens: AiConfig.instance.tokenLimit(AiOp.chat),
    )) {
      buffer.write(token);
      yield token;
    }

    // Save assistant message
    final assistantMessage = ChatMessageModel(
      sessionId: sessionId,
      content: buffer.toString().trim(),
      isUser: false,
      createdAt: DateTime.now(),
    );
    if (sources.isNotEmpty) {
      assistantMessage.sourceChunks = sources;
    }
    _chatDatasource.saveMessage(assistantMessage);
  }

  /// For short follow-up messages, use previous conversation to build a better search query
  String _buildSearchQuery(String message, List<ChatMessageModel> history) {
    // If message is long enough, use it directly
    if (message.split(RegExp(r'\s+')).length >= 3) return message;

    // Short message — combine with recent topic from chat history
    final recentTopics = <String>[];
    for (final msg in history.reversed.take(6)) {
      if (msg.isUser && msg.content.split(RegExp(r'\s+')).length >= 3) {
        recentTopics.add(msg.content);
        break;
      }
    }

    if (recentTopics.isNotEmpty) {
      return '${recentTopics.first} $message';
    }
    return message;
  }

  /// Build a conversation history string from recent messages
  String _buildHistory(List<ChatMessageModel> messages, {int maxMessages = 4}) {
    final recent = messages.reversed.take(maxMessages).toList().reversed;
    return recent.map((m) {
      final role = m.isUser ? 'Student' : 'AI';
      final content = m.content.length > 600
          ? '${m.content.substring(0, 600)}...'
          : m.content;
      return '$role: $content';
    }).join('\n');
  }

  @override
  Future<void> deleteSession(int id) async {
    _chatDatasource.deleteSession(id);
  }
}
