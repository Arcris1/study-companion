import 'package:flutter/material.dart';

class StudyPlan {
  final int id;
  final DateTime date;
  final List<StudyTask> tasks;
  final DateTime generatedAt;

  const StudyPlan({
    this.id = 0,
    required this.date,
    required this.tasks,
    required this.generatedAt,
  });

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;
}

class StudyTask {
  final String title;
  final String description;
  final String type; // 'quiz_review', 'flashcard_review', 'note_reading', 'weak_area_focus'
  final int? notebookId;
  final int estimatedMinutes;
  final bool isCompleted;

  const StudyTask({
    required this.title,
    required this.description,
    required this.type,
    this.notebookId,
    this.estimatedMinutes = 15,
    this.isCompleted = false,
  });

  StudyTask copyWith({bool? isCompleted}) {
    return StudyTask(
      title: title,
      description: description,
      type: type,
      notebookId: notebookId,
      estimatedMinutes: estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  IconData get typeIcon {
    switch (type) {
      case 'quiz_review':
        return Icons.quiz_rounded;
      case 'flashcard_review':
        return Icons.style_rounded;
      case 'note_reading':
        return Icons.menu_book_rounded;
      case 'weak_area_focus':
        return Icons.track_changes_rounded;
      default:
        return Icons.task_rounded;
    }
  }
}
