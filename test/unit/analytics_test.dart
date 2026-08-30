import 'package:cma_tracker/core/constants/enums.dart';
import 'package:cma_tracker/core/utils/analytics.dart';
import 'package:cma_tracker/core/utils/target_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

SessionAgg s(DateTime day, int minutes,
        {ActivityType activity = ActivityType.studied, int q = 0}) =>
    SessionAgg(
      start: day,
      durationMinutes: minutes,
      subjectId: 1,
      activity: activity,
      questionsSolved: q,
    );

void main() {
  const calc = TargetCalculator(
    weekdayTargetMinutes: 180,
    weekendTargetMinutes: 360,
  );

  test('minutesByDay aggregates per calendar day', () {
    final map = Analytics.minutesByDay([
      s(DateTime(2026, 8, 10, 9), 60),
      s(DateTime(2026, 8, 10, 18), 90),
      s(DateTime(2026, 8, 11, 8), 30),
    ]);
    expect(map['2026-08-10'], 150);
    expect(map['2026-08-11'], 30);
  });

  test('streak counts consecutive successful days ending today', () {
    final now = DateTime(2026, 8, 12); // Wednesday
    final sessions = [
      s(DateTime(2026, 8, 10), 180), // Mon - met
      s(DateTime(2026, 8, 11), 200), // Tue - met
      s(DateTime(2026, 8, 12), 190), // Wed - met
    ];
    final r = Analytics.streak(sessions, calc, now: now);
    expect(r.current, 3);
    expect(r.longest, 3);
  });

  test('streak breaks on a missed day and is recomputed from source', () {
    final now = DateTime(2026, 8, 12);
    final sessions = [
      s(DateTime(2026, 8, 9), 360), // Sat met
      s(DateTime(2026, 8, 10), 60), // Mon NOT met
      s(DateTime(2026, 8, 11), 180), // Tue met
      s(DateTime(2026, 8, 12), 180), // Wed met
    ];
    final r = Analytics.streak(sessions, calc, now: now);
    expect(r.current, 2);
    expect(r.longest, 2);
  });

  test('duplicate-looking sessions on same day do not double the streak', () {
    final now = DateTime(2026, 8, 12);
    final sessions = [
      s(DateTime(2026, 8, 12, 9), 90),
      s(DateTime(2026, 8, 12, 12), 90), // together = 180 => met, single day
    ];
    final r = Analytics.streak(sessions, calc, now: now);
    expect(r.current, 1);
  });

  test('minutesInRange respects inclusive bounds', () {
    final sessions = [
      s(DateTime(2026, 8, 1), 60),
      s(DateTime(2026, 8, 15), 120),
      s(DateTime(2026, 8, 31), 30),
    ];
    expect(
      Analytics.minutesInRange(
          sessions, DateTime(2026, 8, 1), DateTime(2026, 8, 31)),
      210,
    );
    expect(
      Analytics.minutesInRange(
          sessions, DateTime(2026, 8, 2), DateTime(2026, 8, 20)),
      120,
    );
  });

  test('totalQuestions and studyDayCount', () {
    final sessions = [
      s(DateTime(2026, 8, 1), 60, q: 10),
      s(DateTime(2026, 8, 1), 30, q: 5),
      s(DateTime(2026, 8, 2), 45, q: 7),
    ];
    expect(Analytics.totalQuestions(sessions), 22);
    expect(Analytics.studyDayCount(sessions), 2);
  });
}
