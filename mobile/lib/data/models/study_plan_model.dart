import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import '../../domain/entities/study_plan.dart';

@Entity()
class StudyPlanModel {
  @Id()
  int id;

  @Property(type: PropertyType.dateNano)
  DateTime date;

  String tasksJson; // JSON-encoded List<Map>

  @Property(type: PropertyType.dateNano)
  DateTime generatedAt;

  StudyPlanModel({
    this.id = 0,
    required this.date,
    this.tasksJson = '[]',
    required this.generatedAt,
  });

  List<StudyTask> get tasks {
    final decoded = jsonDecode(tasksJson) as List;
    return decoded.map((t) {
      final map = t as Map<String, dynamic>;
      return StudyTask(
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        type: map['type'] as String? ?? 'note_reading',
        notebookId: map['notebook_id'] as int?,
        estimatedMinutes: map['estimated_minutes'] as int? ?? 15,
        isCompleted: map['is_completed'] as bool? ?? false,
      );
    }).toList();
  }

  set tasks(List<StudyTask> value) {
    tasksJson = jsonEncode(value.map((t) => {
      'title': t.title,
      'description': t.description,
      'type': t.type,
      'notebook_id': t.notebookId,
      'estimated_minutes': t.estimatedMinutes,
      'is_completed': t.isCompleted,
    }).toList());
  }

  StudyPlan toEntity() {
    return StudyPlan(
      id: id,
      date: date,
      tasks: tasks,
      generatedAt: generatedAt,
    );
  }

  factory StudyPlanModel.fromEntity(StudyPlan entity) {
    final model = StudyPlanModel(
      id: entity.id,
      date: entity.date,
      generatedAt: entity.generatedAt,
    );
    model.tasks = entity.tasks;
    return model;
  }
}
