import 'package:objectbox/objectbox.dart';
import '../../domain/entities/flashcard.dart';

@Entity()
class FlashcardModel {
  @Id()
  int id;

  int deckId;
  String front;
  String back;
  int cardIndex;
  double easeFactor;
  int interval;
  int repetitions;

  @Property(type: PropertyType.dateNano)
  DateTime? nextReviewAt;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  FlashcardModel({
    this.id = 0,
    required this.deckId,
    required this.front,
    required this.back,
    required this.cardIndex,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReviewAt,
    required this.createdAt,
  });

  Flashcard toEntity() {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      cardIndex: cardIndex,
      easeFactor: easeFactor,
      interval: interval,
      repetitions: repetitions,
      nextReviewAt: nextReviewAt,
      createdAt: createdAt,
    );
  }

  factory FlashcardModel.fromEntity(Flashcard entity) {
    return FlashcardModel(
      id: entity.id,
      deckId: entity.deckId,
      front: entity.front,
      back: entity.back,
      cardIndex: entity.cardIndex,
      easeFactor: entity.easeFactor,
      interval: entity.interval,
      repetitions: entity.repetitions,
      nextReviewAt: entity.nextReviewAt,
      createdAt: entity.createdAt,
    );
  }
}
