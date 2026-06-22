import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import '../../domain/entities/chat_message.dart';

@Entity()
class ChatMessageModel {
  @Id()
  int id;

  int sessionId;
  String content;
  bool isUser;
  String? sourceChunksJson;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  ChatMessageModel({
    this.id = 0,
    required this.sessionId,
    required this.content,
    required this.isUser,
    this.sourceChunksJson,
    required this.createdAt,
  });

  List<String>? get sourceChunks {
    if (sourceChunksJson == null) return null;
    return (jsonDecode(sourceChunksJson!) as List).cast<String>();
  }

  set sourceChunks(List<String>? value) {
    sourceChunksJson = value != null ? jsonEncode(value) : null;
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      content: content,
      isUser: isUser,
      sourceChunks: sourceChunks,
      createdAt: createdAt,
    );
  }

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    final model = ChatMessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      content: entity.content,
      isUser: entity.isUser,
      createdAt: entity.createdAt,
    );
    model.sourceChunks = entity.sourceChunks;
    return model;
  }
}
