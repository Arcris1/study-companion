import 'package:flutter_test/flutter_test.dart';
import 'package:study_companion/core/algorithms/sm2.dart';

void main() {
  group('SM-2 Algorithm', () {
    group('quality 5 (perfect response)', () {
      test('ease factor increases', () {
        final result = sm2(
          oldEase: 2.5,
          oldInterval: 1,
          oldReps: 0,
          quality: 5,
        );

        expect(result.easeFactor, greaterThan(2.5));
      });

      test('interval grows over successive correct answers', () {
        // First correct: interval = 1
        final r1 = sm2(oldEase: 2.5, oldInterval: 0, oldReps: 0, quality: 5);
        expect(r1.interval, equals(1));

        // Second correct: interval = 6
        final r2 = sm2(
          oldEase: r1.easeFactor,
          oldInterval: r1.interval,
          oldReps: r1.repetitions,
          quality: 5,
        );
        expect(r2.interval, equals(6));

        // Third correct: interval = oldInterval * ease
        final r3 = sm2(
          oldEase: r2.easeFactor,
          oldInterval: r2.interval,
          oldReps: r2.repetitions,
          quality: 5,
        );
        expect(r3.interval, greaterThan(r2.interval));
      });

      test('repetitions increment', () {
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 2, quality: 5);
        expect(result.repetitions, equals(3));
      });
    });

    group('quality 4 (correct with hesitation)', () {
      test('ease stays approximately the same', () {
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 0, quality: 4);

        // With quality 4: ease change = 0.1 - 1*(0.08 + 1*0.02) = 0
        expect(result.easeFactor, equals(2.5));
      });

      test('repetitions still increment', () {
        final result = sm2(oldEase: 2.5, oldInterval: 6, oldReps: 1, quality: 4);
        expect(result.repetitions, equals(2));
      });
    });

    group('quality 3 (correct with difficulty)', () {
      test('ease may decrease slightly', () {
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 0, quality: 3);

        // With quality 3: ease change = 0.1 - 2*(0.08 + 2*0.02) = 0.1 - 0.24 = -0.14
        expect(result.easeFactor, lessThan(2.5));
      });

      test('repetitions still increment on quality 3', () {
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 0, quality: 3);
        expect(result.repetitions, equals(1));
      });
    });

    group('quality 2 (incorrect)', () {
      test('reps reset to 0', () {
        final result = sm2(oldEase: 2.5, oldInterval: 10, oldReps: 5, quality: 2);
        expect(result.repetitions, equals(0));
      });

      test('interval resets to 1', () {
        final result = sm2(oldEase: 2.5, oldInterval: 10, oldReps: 5, quality: 2);
        expect(result.interval, equals(1));
      });

      test('ease factor unchanged', () {
        final result = sm2(oldEase: 2.5, oldInterval: 10, oldReps: 5, quality: 2);
        expect(result.easeFactor, equals(2.5));
      });
    });

    group('quality 0 (complete blackout)', () {
      test('reps reset to 0', () {
        final result = sm2(oldEase: 2.5, oldInterval: 10, oldReps: 5, quality: 0);
        expect(result.repetitions, equals(0));
      });

      test('ease factor unchanged', () {
        final result = sm2(oldEase: 2.5, oldInterval: 10, oldReps: 5, quality: 0);
        expect(result.easeFactor, equals(2.5));
      });

      test('interval resets to 1', () {
        final result = sm2(oldEase: 2.5, oldInterval: 10, oldReps: 5, quality: 0);
        expect(result.interval, equals(1));
      });
    });

    group('ease floor', () {
      test('ease never drops below 1.3', () {
        // Repeatedly give quality 3 to drive ease down
        var ease = 1.5;
        var interval = 1;
        var reps = 0;

        for (var i = 0; i < 20; i++) {
          final result = sm2(
            oldEase: ease,
            oldInterval: interval,
            oldReps: reps,
            quality: 3,
          );
          ease = result.easeFactor;
          interval = result.interval;
          reps = result.repetitions;

          expect(result.easeFactor, greaterThanOrEqualTo(1.3));
        }
      });

      test('ease exactly at 1.3 stays at 1.3 with quality 3', () {
        final result = sm2(oldEase: 1.3, oldInterval: 1, oldReps: 0, quality: 3);
        expect(result.easeFactor, equals(1.3));
      });
    });

    group('first and second correct intervals', () {
      test('first correct response gives interval = 1', () {
        final result = sm2(oldEase: 2.5, oldInterval: 0, oldReps: 0, quality: 5);
        expect(result.interval, equals(1));
        expect(result.repetitions, equals(1));
      });

      test('second correct response gives interval = 6', () {
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 1, quality: 5);
        expect(result.interval, equals(6));
        expect(result.repetitions, equals(2));
      });
    });

    group('nextReviewDate', () {
      test('nextReviewDate is in the future', () {
        final before = DateTime.now();
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 0, quality: 5);
        expect(result.nextReviewDate.isAfter(before), isTrue);
      });

      test('nextReviewDate is interval days from now', () {
        final result = sm2(oldEase: 2.5, oldInterval: 1, oldReps: 1, quality: 5);
        final now = DateTime.now();
        final diff = result.nextReviewDate.difference(now).inDays;
        // interval should be 6 for second correct
        expect(diff, inInclusiveRange(5, 6));
      });
    });
  });
}
