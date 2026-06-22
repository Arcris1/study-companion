class StudySession {
  final int id;
  final int notebookId;
  final String activityType; // 'quiz', 'flashcard', 'chat', 'notes'
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime endedAt;

  const StudySession({
    this.id = 0,
    required this.notebookId,
    required this.activityType,
    required this.durationSeconds,
    required this.startedAt,
    required this.endedAt,
  });

  String get durationLabel {
    if (durationSeconds < 60) return '${durationSeconds}s';
    if (durationSeconds < 3600) return '${durationSeconds ~/ 60}m';
    return '${durationSeconds ~/ 3600}h ${(durationSeconds % 3600) ~/ 60}m';
  }
}
