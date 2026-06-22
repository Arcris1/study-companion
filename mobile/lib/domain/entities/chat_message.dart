class ChatMessage {
  final int id;
  final int sessionId;
  final String content;
  final bool isUser;
  final List<String>? sourceChunks;
  final DateTime createdAt;

  const ChatMessage({
    this.id = 0,
    required this.sessionId,
    required this.content,
    required this.isUser,
    this.sourceChunks,
    required this.createdAt,
  });
}
