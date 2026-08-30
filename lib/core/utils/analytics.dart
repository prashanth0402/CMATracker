import '../constants/enums.dart';
import 'date_utils.dart';
import 'target_calculator.dart';

/// Lightweight, DB-agnostic view of a study session for analytics + tests.
class SessionAgg {
  const SessionAgg({
    required this.start,
    required this.durationMinutes,
    required this.subjectId,
    this.topicId,
    required this.activity,
    this.questionsSolved = 0,
  });

  final DateTime start;
  final int durationMinutes;
  final int subjectId;
  final int? topicId;
  final ActivityType activity;
  final int questionsSolved;

  bool get isPractice =>
      activity == ActivityType.practicedQuestions ||
      activity == ActivityType.mockTest;
  bool get isRevision =>
      activity == ActivityType.revised || activity == ActivityType.revision;
}

/// Pure analytics helpers. No IO, no Flutter – fully unit-testable.
class Analytics {
  const Analytics._();

  /// Sums session minutes keyed by local ISO day (yyyy-MM-dd).
  static Map<String, int> minutesByDay(Iterable<SessionAgg> sessions) {
    final out = <String, int>{};
    for (final s in sessions) {
      final key = AppDate.isoDay(s.start);
      out[key] = (out[key] ?? 0) + s.durationMinutes;
    }
    return out;
  }

  static int totalMinutes(Iterable<SessionAgg> sessions) =>
      sessions.fold(0, (a, s) => a + s.durationMinutes);

  static int totalQuestions(Iterable<SessionAgg> sessions) =>
      sessions.fold(0, (a, s) => a + s.questionsSolved);

  /// Count of distinct days that have at least one session.
  static int studyDayCount(Iterable<SessionAgg> sessions) =>
      sessions.map((s) => AppDate.isoDay(s.start)).toSet().length;

  /// A day is "successful" when its total study minutes >= that day's target.
  static bool isDaySuccessful(
    DateTime day,
    Map<String, int> byDay,
    TargetCalculator calc,
  ) {
    final minutes = byDay[AppDate.isoDay(day)] ?? 0;
    return minutes >= calc.targetForDay(day) && minutes > 0;
  }

  /// Current streak: consecutive successful days ending today (or yesterday if
  /// today is not yet successful). Longest: best run across all history.
  ///
  /// Recomputed from source data every time, so editing/deleting sessions can
  /// never leave a stale streak.
  static ({int current, int longest}) streak(
    Iterable<SessionAgg> sessions,
    TargetCalculator calc, {
    DateTime? now,
  }) {
    final byDay = minutesByDay(sessions);
    if (byDay.isEmpty) return (current: 0, longest: 0);

    final today = AppDate.dayStart(now ?? DateTime.now());

    // Longest run across the full span of recorded days.
    final keys = byDay.keys.toList()..sort();
    final first = AppDate.fromIso('${keys.first}T00:00:00');
    var longest = 0;
    var run = 0;
    for (
      var d = AppDate.dayStart(first);
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))
    ) {
      if (isDaySuccessful(d, byDay, calc)) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }

    // Current streak walking backwards from today.
    var current = 0;
    var cursor = today;
    if (!isDaySuccessful(cursor, byDay, calc)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (isDaySuccessful(cursor, byDay, calc)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return (current: current, longest: longest);
  }

  /// Minutes actually studied within [from]..[to] inclusive.
  static int minutesInRange(
    Iterable<SessionAgg> sessions,
    DateTime from,
    DateTime to,
  ) {
    final f = AppDate.dayStart(from);
    final t = AppDate.dayEnd(to);
    return sessions
        .where((s) => !s.start.isBefore(f) && !s.start.isAfter(t))
        .fold(0, (a, s) => a + s.durationMinutes);
  }
}
