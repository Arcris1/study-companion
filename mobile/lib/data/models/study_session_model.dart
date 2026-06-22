import 'package:objectbox/objectbox.dart';
import '../../domain/entities/study_session.dart';

@Entity()
class StudySessionModel {
  @Id()
  int id;

  int notebookId;
  String activityType;
  int durationSeconds;

  @Property(type: PropertyType.dateNano)
  DateTime startedAt;

  @Property(type: PropertyType.dateNano)
  DateTime endedAt;

  StudySessionModel({
    this.id = 0,
    required this.notebookId,
    required this.activityType,
    required this.durationSeconds,
    required this.startedAt,
    required this.endedAt,
  });

  StudySession toEntity() {
    return StudySession(
      id: id,
      notebookId: notebookId,
      activityType: activityType,
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  factory StudySessionModel.fromEntity(StudySession entity) {
    return StudySessionModel(
      id: entity.id,
      notebookId: entity.notebookId,
      activityType: entity.activityType,
      durationSeconds: entity.durationSeconds,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
    );
  }
}
