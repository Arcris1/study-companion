import 'dart:convert';
import '../../core/llm/llm_service.dart';
import '../../core/llm/prompt_templates.dart';
import '../../domain/entities/study_plan.dart';
import '../datasources/local/planner_local_datasource.dart';
import '../models/study_plan_model.dart';

class PlannerRepository {
  final PlannerLocalDatasource _datasource;
  final LlmService _llmService;

  PlannerRepository(this._datasource, this._llmService);

  Future<StudyPlan?> getPlanForToday() async {
    final model = _datasource.getPlanForDate(DateTime.now());
    return model?.toEntity();
  }

  Future<StudyPlan> generatePlan({
    required int availableMinutes,
    required List<String> dueFlashcardDecks,
    required List<String> weakTopics,
    required List<String> recentNotebooks,
  }) async {
    final prompt = PromptTemplates.generateStudyPlan(
      availableMinutes: availableMinutes,
      dueFlashcardDecks: dueFlashcardDecks,
      weakTopics: weakTopics,
      recentNotebooks: recentNotebooks,
    );

    final response = await _llmService.generate(prompt, maxTokens: 1024);

    List<StudyTask> tasks;
    try {
      final jsonStr = '{"tasks": [$response';
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final taskList = parsed['tasks'] as List;

      tasks = taskList.map((t) {
        final map = t as Map<String, dynamic>;
        return StudyTask(
          title: map['title'] as String? ?? 'Study Task',
          description: map['description'] as String? ?? '',
          type: map['type'] as String? ?? 'note_reading',
          estimatedMinutes: map['estimated_minutes'] as int? ?? 15,
        );
      }).toList();
    } catch (_) {
      // Fallback tasks if LLM parsing fails
      tasks = _generateFallbackTasks(
        availableMinutes: availableMinutes,
        dueFlashcardDecks: dueFlashcardDecks,
        weakTopics: weakTopics,
        recentNotebooks: recentNotebooks,
      );
    }

    final now = DateTime.now();
    final model = StudyPlanModel(
      date: DateTime(now.year, now.month, now.day),
      generatedAt: now,
    );
    model.tasks = tasks;

    final saved = _datasource.savePlan(model);
    return saved.toEntity();
  }

  Future<StudyPlan> toggleTask(int planId, int taskIndex) async {
    final model = _datasource.getPlanForDate(DateTime.now());
    if (model == null || model.id != planId) {
      throw Exception('Plan not found');
    }

    final currentTasks = model.tasks;
    if (taskIndex < 0 || taskIndex >= currentTasks.length) {
      throw Exception('Invalid task index');
    }

    final updatedTasks = List<StudyTask>.from(currentTasks);
    updatedTasks[taskIndex] = updatedTasks[taskIndex].copyWith(
      isCompleted: !updatedTasks[taskIndex].isCompleted,
    );

    model.tasks = updatedTasks;
    _datasource.updatePlan(model);
    return model.toEntity();
  }

  List<StudyTask> _generateFallbackTasks({
    required int availableMinutes,
    required List<String> dueFlashcardDecks,
    required List<String> weakTopics,
    required List<String> recentNotebooks,
  }) {
    final tasks = <StudyTask>[];
    int remaining = availableMinutes;

    // Add flashcard reviews
    for (final deck in dueFlashcardDecks) {
      if (remaining <= 0) break;
      final time = remaining >= 15 ? 15 : remaining;
      tasks.add(StudyTask(
        title: 'Review $deck flashcards',
        description: 'Complete due flashcard reviews for $deck',
        type: 'flashcard_review',
        estimatedMinutes: time,
      ));
      remaining -= time;
    }

    // Add weak area focus
    for (final topic in weakTopics) {
      if (remaining <= 0) break;
      final time = remaining >= 20 ? 20 : remaining;
      tasks.add(StudyTask(
        title: 'Focus on $topic',
        description: 'Practice weak area: $topic with focused quiz',
        type: 'weak_area_focus',
        estimatedMinutes: time,
      ));
      remaining -= time;
    }

    // Add note reading for remaining time
    for (final notebook in recentNotebooks) {
      if (remaining <= 0) break;
      final time = remaining >= 15 ? 15 : remaining;
      tasks.add(StudyTask(
        title: 'Review $notebook notes',
        description: 'Read through recent notes in $notebook',
        type: 'note_reading',
        estimatedMinutes: time,
      ));
      remaining -= time;
    }

    if (tasks.isEmpty) {
      tasks.add(const StudyTask(
        title: 'General Study Session',
        description: 'Review your notes and take a quiz',
        type: 'note_reading',
        estimatedMinutes: 30,
      ));
    }

    return tasks;
  }
}
