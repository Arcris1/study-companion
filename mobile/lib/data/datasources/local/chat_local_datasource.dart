import 'package:objectbox/objectbox.dart';
import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/chat_session_model.dart';
import '../../models/chat_message_model.dart';

class ChatLocalDatasource {
  final ObjectBox _objectBox;

  ChatLocalDatasource(this._objectBox);

  Box<ChatSessionModel> get _sessionBox => _objectBox.store.box<ChatSessionModel>();
  Box<ChatMessageModel> get _messageBox => _objectBox.store.box<ChatMessageModel>();

  List<ChatSessionModel> getSessionsByNotebookId(int notebookId) {
    final query = _sessionBox.query(ChatSessionModel_.notebookId.equals(notebookId))
        .order(ChatSessionModel_.updatedAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  int getMessageCount(int sessionId) {
    final query = _messageBox.query(ChatMessageModel_.sessionId.equals(sessionId)).build();
    final count = query.count();
    query.close();
    return count;
  }

  ChatSessionModel createSession(ChatSessionModel model) {
    final id = _sessionBox.put(model);
    return _sessionBox.get(id)!;
  }

  ChatSessionModel? getSessionById(int id) {
    return _sessionBox.get(id);
  }

  List<ChatMessageModel> getMessages(int sessionId) {
    final query = _messageBox.query(ChatMessageModel_.sessionId.equals(sessionId))
        .order(ChatMessageModel_.createdAt)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  ChatMessageModel saveMessage(ChatMessageModel model) {
    final id = _messageBox.put(model);
    return _messageBox.get(id)!;
  }

  void updateSession(ChatSessionModel model) {
    _sessionBox.put(model);
  }

  void deleteSession(int id) {
    final msgQuery = _messageBox.query(ChatMessageModel_.sessionId.equals(id)).build();
    final msgIds = msgQuery.find().map((m) => m.id).toList();
    msgQuery.close();
    _messageBox.removeMany(msgIds);
    _sessionBox.remove(id);
  }
}
