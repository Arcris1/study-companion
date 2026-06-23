import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';

class QuizConfig {
  final QuestionType questionType;
  final DifficultyLevel difficulty;
  final int questionCount;

  /// Notes to draw questions from; empty = all notes ("General").
  final List<int> selectedNoteIds;
  final bool isGenerating;
  final String? error;

  const QuizConfig({
    this.questionType = QuestionType.mcq,
    this.difficulty = DifficultyLevel.medium,
    this.questionCount = 10,
    this.selectedNoteIds = const [],
    this.isGenerating = false,
    this.error,
  });

  QuizConfig copyWith({
    QuestionType? questionType,
    DifficultyLevel? difficulty,
    int? questionCount,
    List<int>? selectedNoteIds,
    bool? isGenerating,
    String? error,
  }) {
    return QuizConfig(
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

final quizConfigProvider = NotifierProvider.autoDispose<QuizConfigNotifier, QuizConfig>(QuizConfigNotifier.new);

class QuizConfigNotifier extends Notifier<QuizConfig> {
  @override
  QuizConfig build() {
    return const QuizConfig();
  }

  void setQuestionType(QuestionType type) {
    state = state.copyWith(questionType: type);
  }

  void setDifficulty(DifficultyLevel level) {
    state = state.copyWith(difficulty: level);
  }

  void setQuestionCount(int count) {
    state = state.copyWith(questionCount: count.clamp(5, 30));
  }

  void setNoteIds(List<int> ids) {
    state = state.copyWith(selectedNoteIds: ids);
  }

  void setGenerating(bool value) {
    state = state.copyWith(isGenerating: value, error: null);
  }

  void setError(String message) {
    state = state.copyWith(isGenerating: false, error: message);
  }
}
