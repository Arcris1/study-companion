class Notebook {
  final int id;
  final String title;
  final String? description;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int noteCount;

  const Notebook({
    this.id = 0,
    required this.title,
    this.description,
    this.color = '#6750A4',
    required this.createdAt,
    required this.updatedAt,
    this.noteCount = 0,
  });

  Notebook copyWith({
    int? id,
    String? title,
    String? description,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? noteCount,
  }) {
    return Notebook(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      noteCount: noteCount ?? this.noteCount,
    );
  }
}
