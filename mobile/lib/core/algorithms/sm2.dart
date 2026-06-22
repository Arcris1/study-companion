class SM2Result {
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime nextReviewDate;

  const SM2Result({
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.nextReviewDate,
  });
}

SM2Result sm2({
  required double oldEase,
  required int oldInterval,
  required int oldReps,
  required int quality,
}) {
  assert(quality >= 0 && quality <= 5);

  double newEase;
  int newInterval;
  int newReps;

  if (quality >= 3) {
    // Correct response
    newReps = oldReps + 1;
    if (newReps == 1) {
      newInterval = 1;
    } else if (newReps == 2) {
      newInterval = 6;
    } else {
      newInterval = (oldInterval * oldEase).round();
    }
    newEase = oldEase + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  } else {
    // Incorrect response
    newReps = 0;
    newInterval = 1;
    newEase = oldEase;
  }

  // Ease factor never drops below 1.3
  if (newEase < 1.3) newEase = 1.3;

  final nextReview = DateTime.now().add(Duration(days: newInterval));

  return SM2Result(
    easeFactor: newEase,
    interval: newInterval,
    repetitions: newReps,
    nextReviewDate: nextReview,
  );
}
