import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/weakness_analyzer.dart';
import '../../domain/entities/weakness.dart';
import 'quiz_provider.dart';
import 'notebook_provider.dart';

final weaknessProvider =
    FutureProvider.family<List<Weakness>, int>((ref, notebookId) async {
  final quizRepo = ref.read(quizRepositoryProvider);
  final notebooks = ref.read(notebooksProvider).value ?? [];
  final notebook = notebooks.where((n) => n.id == notebookId).firstOrNull;
  final notebookTitle = notebook?.title ?? '';

  // Get all quizzes for this notebook
  final quizzes = await quizRepo.getByNotebookId(notebookId);
  if (quizzes.isEmpty) return [];

  // Gather all questions and attempts across all quizzes
  final allQuestions = <dynamic>[];
  final allAttempts = <dynamic>[];

  for (final quiz in quizzes) {
    final questions = await quizRepo.getQuestions(quiz.id);
    final attempts = await quizRepo.getAttempts(quiz.id);
    allQuestions.addAll(questions);
    allAttempts.addAll(attempts);
  }

  if (allAttempts.isEmpty) return [];

  final analyzer = WeaknessAnalyzer();
  return analyzer.analyze(
    questions: allQuestions.cast(),
    attempts: allAttempts.cast(),
    notebookId: notebookId,
    notebookTitle: notebookTitle,
  );
});
