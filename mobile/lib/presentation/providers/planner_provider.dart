import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/llm/llm_service.dart';
import '../../data/datasources/local/planner_local_datasource.dart';
import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/study_plan.dart';
import '../../domain/entities/weakness.dart';
import 'flashcard_provider.dart';
import 'notebook_provider.dart';
import 'weakness_provider.dart';

final plannerDatasourceProvider = Provider<PlannerLocalDatasource>((ref) {
  return PlannerLocalDatasource(ref.read(objectBoxProvider));
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(
    ref.read(plannerDatasourceProvider),
    ref.read(llmServiceProvider),
  );
});

final todayPlanProvider =
    NotifierProvider<TodayPlanNotifier, AsyncValue<StudyPlan?>>(() {
  return TodayPlanNotifier();
});

class TodayPlanNotifier extends Notifier<AsyncValue<StudyPlan?>> {
  @override
  AsyncValue<StudyPlan?> build() {
    load();
    return const AsyncValue.loading();
  }

  PlannerRepository get _repository => ref.read(plannerRepositoryProvider);

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final plan = await _repository.getPlanForToday();
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generatePlan({required int availableMinutes}) async {
    try {
      state = const AsyncValue.loading();

      final notebooks = ref.read(notebooksProvider).value ?? [];
      final recentNotebooks = notebooks.take(5).map((n) => n.title).toList();

      // Pull real signals from the user's data so plans are richer than just
      // "read your notes": flashcard decks with cards due + weak quiz topics.
      final dueDecks = <String>[];
      final weakAreas = <Weakness>[];
      for (final nb in notebooks) {
        final decks = await ref.read(flashcardRepositoryProvider).getDecks(nb.id);
        dueDecks.addAll(decks.where((d) => d.dueCount > 0).map((d) => d.title));
        try {
          final weaknesses = await ref.read(weaknessProvider(nb.id).future);
          weakAreas.addAll(weaknesses.where((w) => w.isWeak));
        } catch (_) {
          // No quiz history for this notebook — skip.
        }
      }
      weakAreas.sort((a, b) => a.accuracy.compareTo(b.accuracy));

      final plan = await _repository.generatePlan(
        availableMinutes: availableMinutes,
        dueFlashcardDecks: dueDecks.take(5).toList(),
        weakTopics: weakAreas.take(5).map((w) => w.topic).toList(),
        recentNotebooks: recentNotebooks,
      );
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(StudyTask task) async {
    try {
      final plan = await _repository.addTask(task);
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTask(int planId, int taskIndex) async {
    try {
      final plan = await _repository.toggleTask(planId, taskIndex);
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
