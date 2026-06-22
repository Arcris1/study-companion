import 'package:objectbox/objectbox.dart';
import '../../domain/entities/notebook.dart';

@Entity()
class NotebookModel {
  @Id()
  int id;

  String title;
  String? description;
  String color;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  NotebookModel({
    this.id = 0,
    required this.title,
    this.description,
    this.color = '#6750A4',
    required this.createdAt,
    required this.updatedAt,
  });

  Notebook toEntity({int noteCount = 0}) {
    return Notebook(
      id: id,
      title: title,
      description: description,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      noteCount: noteCount,
    );
  }

  factory NotebookModel.fromEntity(Notebook entity) {
    return NotebookModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      color: entity.color,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
