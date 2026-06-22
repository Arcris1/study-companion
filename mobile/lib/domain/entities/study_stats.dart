class StudyStats {
  final int totalStudyMinutes;
  final int sessionsThisWeek;
  final int streakDays;
  final double averageQuizScore;
  final int totalNotesCreated;
  final int totalQuizzesTaken;
  final int totalFlashcardsReviewed;

  const StudyStats({
    this.totalStudyMinutes = 0,
    this.sessionsThisWeek = 0,
    this.streakDays = 0,
    this.averageQuizScore = 0,
    this.totalNotesCreated = 0,
    this.totalQuizzesTaken = 0,
    this.totalFlashcardsReviewed = 0,
  });
}
