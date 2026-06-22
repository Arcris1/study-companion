import 'package:objectbox/objectbox.dart';
import '../../domain/entities/flashcard_review.dart';

@Entity()
class FlashcardReviewModel {
  @Id()
  int id;

  int flashcardId;
  int quality;

  @Property(type: PropertyType.dateNano)
  DateTime reviewedAt;

  FlashcardReviewModel({
    this.id = 0,
    required this.flashcardId,
    required this.quality,
    required this.reviewedAt,
  });

  FlashcardReview toEntity() {
    return FlashcardReview(
      id: id,
      flashcardId: flashcardId,
      quality: quality,
      reviewedAt: reviewedAt,
    );
  }

  factory FlashcardReviewModel.fromEntity(FlashcardReview entity) {
    return FlashcardReviewModel(
      id: entity.id,
      flashcardId: entity.flashcardId,
      quality: entity.quality,
      reviewedAt: entity.reviewedAt,
    );
  }
}
