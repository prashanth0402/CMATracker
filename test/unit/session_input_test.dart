import 'package:cma_tracker/core/constants/enums.dart';
import 'package:cma_tracker/core/errors/app_exceptions.dart';
import 'package:cma_tracker/data/repositories/study_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionInput make(DateTime start, DateTime end) => SessionInput(
        subjectId: 1,
        start: start,
        end: end,
        activityType: ActivityType.studied,
      );

  test('duration is computed in whole minutes', () {
    final i = make(DateTime(2026, 8, 10, 9), DateTime(2026, 8, 10, 10, 45));
    expect(i.durationMinutes, 105);
  });

  test('midnight-crossing session has correct duration', () {
    final i = make(DateTime(2026, 8, 10, 23), DateTime(2026, 8, 11, 1, 30));
    expect(i.durationMinutes, 150);
    i.validate();
  });

  test('end before start throws ValidationException', () {
    final i = make(DateTime(2026, 8, 10, 10), DateTime(2026, 8, 10, 9));
    expect(i.validate, throwsA(isA<ValidationException>()));
  });

  test('sub-minute session throws', () {
    final i = make(
        DateTime(2026, 8, 10, 10, 0, 0), DateTime(2026, 8, 10, 10, 0, 30));
    expect(i.validate, throwsA(isA<ValidationException>()));
  });

  test('understanding out of range throws', () {
    final i = SessionInput(
      subjectId: 1,
      start: DateTime(2026, 8, 10, 9),
      end: DateTime(2026, 8, 10, 10),
      activityType: ActivityType.studied,
      understanding: 9,
    );
    expect(i.validate, throwsA(isA<ValidationException>()));
  });
}
