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

    // `date` is stored as PropertyType.dateNano (nanoseconds since epoch).
    // Dart DateTime is microsecond-precision, so nanos = micros * 1000.
    // The old code queried with microsecondsSinceEpoch, which never matched
    // the nanosecond-scale stored values → plan was never found.
    final startNanos = startOfDay.microsecondsSinceEpoch * 1000;
    final endNanos = endOfDay.microsecondsSinceEpoch * 1000;

    final query = _box
        .query(StudyPlanModel_.date.greaterOrEqual(startNanos) &
            StudyPlanModel_.date.lessThan(endNanos))
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
