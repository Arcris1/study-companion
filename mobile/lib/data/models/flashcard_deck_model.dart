import 'package:objectbox/objectbox.dart';
import '../../domain/entities/flashcard_deck.dart';

@Entity()
class FlashcardDeckModel {
  @Id()
  int id;

  int notebookId;
  String title;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  FlashcardDeckModel({
    this.id = 0,
    required this.notebookId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  FlashcardDeck toEntity({int cardCount = 0, int dueCount = 0}) {
    return FlashcardDeck(
      id: id,
      notebookId: notebookId,
      title: title,
      cardCount: cardCount,
      dueCount: dueCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory FlashcardDeckModel.fromEntity(FlashcardDeck entity) {
    return FlashcardDeckModel(
      id: entity.id,
      notebookId: entity.notebookId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
