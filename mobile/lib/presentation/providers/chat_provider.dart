import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/embedding/embedding_service.dart';
import '../../core/llm/llm_service.dart';
import '../../data/datasources/local/chat_local_datasource.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat_message.dart';
import '../../core/openai/openai_client.dart';
import 'note_provider.dart';

final chatDatasourceProvider = Provider<ChatLocalDatasource>((ref) {
  return ChatLocalDatasource(ref.read(objectBoxProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(chatDatasourceProvider),
    ref.read(noteDatasourceProvider),
    ref.read(llmServiceProvider),
    ref.read(embeddingServiceProvider),
  );
});

final chatSessionsProvider = FutureProvider.family<List<ChatSession>, int>((ref, notebookId) {
  return ref.read(chatRepositoryProvider).getSessionsByNotebookId(notebookId);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isGenerating;
  final String streamingContent;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.streamingContent = '',
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? streamingContent,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      streamingContent: streamingContent ?? this.streamingContent,
      error: error,
    );
  }
}

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, int>(
  (sessionId) => ChatNotifier(sessionId),
);

class ChatNotifier extends Notifier<ChatState> {
  final int sessionId;
  StreamSubscription<String>? _streamSub;

  ChatNotifier(this.sessionId);

  @override
  ChatState build() {
    ref.onDispose(() {
      _streamSub?.cancel();
    });
    _loadMessages();
    return const ChatState();
  }

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  Future<void> _loadMessages() async {
    final messages = await _repository.getMessages(sessionId);
    state = state.copyWith(messages: messages);
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.isGenerating) return;

    final userMsg = ChatMessage(
      sessionId: sessionId,
      content: message,
      isUser: true,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isGenerating: true,
      streamingContent: '',
      error: null,
    );

    try {
      if (!OpenAiClient.instance.hasKey) {
        state = state.copyWith(
          isGenerating: false,
          error: 'No OpenAI API key set. Add your key in Settings > AI.',
        );
        return;
      }

      final buffer = StringBuffer();
      await for (final token in _repository.sendMessage(sessionId, message)) {
        buffer.write(token);
        state = state.copyWith(streamingContent: buffer.toString());
      }

      await _loadMessages();
      state = state.copyWith(isGenerating: false, streamingContent: '');
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate response: $e',
      );
    }
  }
}
