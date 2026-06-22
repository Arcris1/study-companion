import 'package:objectbox/objectbox.dart';
import '../../domain/entities/chat_session.dart';

@Entity()
class ChatSessionModel {
  @Id()
  int id;

  int notebookId;
  String title;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  ChatSessionModel({
    this.id = 0,
    required this.notebookId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatSession toEntity({int messageCount = 0}) {
    return ChatSession(
      id: id,
      notebookId: notebookId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: messageCount,
    );
  }

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      notebookId: entity.notebookId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
