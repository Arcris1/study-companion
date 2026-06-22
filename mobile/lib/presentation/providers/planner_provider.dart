import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/objectbox.dart';
import '../../core/llm/llm_service.dart';
import '../../data/datasources/local/planner_local_datasource.dart';
import '../../data/repositories/planner_repository.dart';
import '../../domain/entities/study_plan.dart';

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

  Future<void> generatePlan({
    required int availableMinutes,
    required List<String> dueFlashcardDecks,
    required List<String> weakTopics,
    required List<String> recentNotebooks,
  }) async {
    try {
      state = const AsyncValue.loading();
      final plan = await _repository.generatePlan(
        availableMinutes: availableMinutes,
        dueFlashcardDecks: dueFlashcardDecks,
        weakTopics: weakTopics,
        recentNotebooks: recentNotebooks,
      );
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
