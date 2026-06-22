import '../entities/chat_session.dart';
import '../entities/chat_message.dart';

abstract class IChatRepository {
  Future<List<ChatSession>> getSessionsByNotebookId(int notebookId);
  Future<ChatSession> createSession(int notebookId, String title);
  Future<List<ChatMessage>> getMessages(int sessionId);
  Stream<String> sendMessage(int sessionId, String message);
  Future<void> deleteSession(int id);
}
