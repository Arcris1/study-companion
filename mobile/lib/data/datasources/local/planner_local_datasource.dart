import 'package:objectbox/objectbox.dart';
import '../../../core/database/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../models/study_plan_model.dart';

class PlannerLocalDatasource {
  final ObjectBox _objectBox;

  PlannerLocalDatasource(this._objectBox);

  Box<StudyPlanModel> get _box => _objectBox.store.box<StudyPlanModel>();

  StudyPlanModel savePlan(StudyPlanModel model) {
    final id = _box.put(model);
    return _box.get(id)!;
  }

  StudyPlanModel? getPlanForDate(DateTime date) {
    // Normalize to start of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _box
        .query(StudyPlanModel_.date.greaterOrEqual(startOfDay.microsecondsSinceEpoch) &
            StudyPlanModel_.date.lessThan(endOfDay.microsecondsSinceEpoch))
        .order(StudyPlanModel_.generatedAt, flags: Order.descending)
        .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  void updatePlan(StudyPlanModel model) {
    _box.put(model);
  }

  void deletePlan(int id) {
    _box.remove(id);
  }
}
