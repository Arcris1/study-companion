enum DifficultyLevel {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case DifficultyLevel.easy: return 'Easy';
      case DifficultyLevel.medium: return 'Medium';
      case DifficultyLevel.hard: return 'Hard';
    }
  }
}
