import '../../core/constants/enums.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/date_utils.dart';
import '../database/database.dart';
import '../models/progress_models.dart';
import 'settings_repository.dart';

/// Derives all analytics from raw session data. Nothing here is persisted –
/// keeping progress a pure function of sessions means it can never drift out of
/// sync after an edit or delete.
class ProgressRepository {
  ProgressRepository(this._db);
  final AppDatabase _db;

  Future<List<SessionAgg>> _aggAll() async {
    final rows = await _db.select(_db.studySessions).get();
    return rows.map(_map).toList();
  }

  static SessionAgg _map(StudySession s) => SessionAgg(
        start: AppDate.fromIso(s.startTime),
        durationMinutes: s.durationMinutes,
        subjectId: s.subjectId,
        topicId: s.topicId,
        activity: ActivityType.fromName(s.activityType),
        questionsSolved: s.questionsSolved,
      );

  Future<PeriodProgress> daily(DateTime day, AppSettings settings) async {
    final agg = await _aggAll();
    final actual = Analytics.minutesInRange(agg, day, day);
    return PeriodProgress(
      targetMinutes: settings.targetCalculator.targetForDay(day),
      actualMinutes: actual,
      label: AppDate.displayDate(day),
    );
  }

  Future<PeriodProgress> weekly(DateTime anyDay, AppSettings settings) async {
    final agg = await _aggAll();
    final start = AppDate.weekStart(anyDay, startOfWeek: settings.startOfWeek);
    final end = AppDate.weekStart(anyDay, startOfWeek: settings.startOfWeek)
        .add(const Duration(days: 6));
    return PeriodProgress(
      targetMinutes: settings.targetCalculator
          .rangeTargetMinutes(start, end),
      actualMinutes: Analytics.minutesInRange(agg, start, end),
      label: 'Week ${AppDate.weekOfYear(anyDay)}',
    );
  }

  Future<PeriodProgress> monthly(DateTime anyDay, AppSettings settings) async {
    final agg = await _aggAll();
    final start = AppDate.monthStart(anyDay);
    final end = DateTime(anyDay.year, anyDay.month,
        AppDate.daysInMonth(anyDay));
    return PeriodProgress(
      targetMinutes: settings.targetCalculator.monthlyTargetMinutes(anyDay),
      actualMinutes: Analytics.minutesInRange(agg, start, end),
      label: AppDate.monthLabel(anyDay),
    );
  }

  Future<StreakInfo> streak(AppSettings settings) async {
    final agg = await _aggAll();
    final r = Analytics.streak(agg, settings.targetCalculator);
    return StreakInfo(current: r.current, longest: r.longest);
  }

  Future<List<SubjectProgress>> subjectProgress() async {
    final subjects = await _db.select(_db.subjects).get();
    final topics = await _db.select(_db.topics).get();
    final sessions = await _db.select(_db.studySessions).get();

    return subjects.map((subj) {
      final subjTopics = topics.where((t) => t.subjectId == subj.id).toList();
      final subjSessions =
          sessions.where((s) => s.subjectId == subj.id).toList();
      int minutesFor(bool Function(StudySession) test) => subjSessions
          .where(test)
          .fold(0, (a, s) => a + s.durationMinutes);
      bool isPractice(StudySession s) {
        final a = ActivityType.fromName(s.activityType);
        return a == ActivityType.practicedQuestions || a == ActivityType.mockTest;
      }

      return SubjectProgress(
        subjectId: subj.id,
        subjectTitle: subj.title,
        totalTopics: subjTopics.length,
        completedTopics: subjTopics
            .where((t) => TopicStatus.fromName(t.status).index >=
                TopicStatus.completed.index)
            .length,
        revisedTopics: subjTopics
            .where((t) => TopicStatus.fromName(t.status).index >=
                TopicStatus.revised.index)
            .length,
        masteredTopics: subjTopics
            .where((t) =>
                TopicStatus.fromName(t.status) == TopicStatus.mastered)
            .length,
        studyMinutes: minutesFor((s) => !isPractice(s)),
        practiceMinutes: minutesFor(isPractice),
        questionsSolved:
            subjSessions.fold(0, (a, s) => a + s.questionsSolved),
      );
    }).toList();
  }

  Future<List<DayStat>> monthDayStats(
    DateTime anyDay,
    AppSettings settings,
  ) async {
    final sessions = await _db.select(_db.studySessions).get();
    final agg = sessions.map(_map).toList();
    final byDay = Analytics.minutesByDay(agg);
    final countByDay = <String, int>{};
    for (final s in agg) {
      final k = AppDate.isoDay(s.start);
      countByDay[k] = (countByDay[k] ?? 0) + 1;
    }
    final days = AppDate.daysInMonth(anyDay);
    final first = AppDate.monthStart(anyDay);
    return List.generate(days, (i) {
      final d = first.add(Duration(days: i));
      final key = AppDate.isoDay(d);
      return DayStat(
        day: d,
        targetMinutes: settings.targetCalculator.targetForDay(d),
        actualMinutes: byDay[key] ?? 0,
        sessionCount: countByDay[key] ?? 0,
      );
    });
  }

  Future<WeeklyReport> weeklyReport(
    DateTime anyDay,
    AppSettings settings,
    int rewardPoints,
  ) async {
    final start = AppDate.weekStart(anyDay, startOfWeek: settings.startOfWeek);
    final end = start.add(const Duration(days: 6));
    final sessions = await _db.select(_db.studySessions).get();
    final agg = sessions.map(_map).toList();
    final inWeek = agg
        .where((s) =>
            !s.start.isBefore(AppDate.dayStart(start)) &&
            !s.start.isAfter(AppDate.dayEnd(end)))
        .toList();

    final subjects = await _db.select(_db.subjects).get();
    final bySubject = <int, int>{};
    for (final s in inWeek) {
      bySubject[s.subjectId] = (bySubject[s.subjectId] ?? 0) + s.durationMinutes;
    }
    String topSubject = '—';
    if (bySubject.isNotEmpty) {
      final topId = bySubject.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      topSubject = subjects
          .firstWhere((e) => e.id == topId,
              orElse: () => subjects.first)
          .title;
    }

    final topics = await _db.select(_db.topics).get();
    final completedTopics = topics
        .where((t) =>
            TopicStatus.fromName(t.status).index >=
            TopicStatus.completed.index)
        .length;

    final streakInfo = Analytics.streak(agg, settings.targetCalculator);

    return WeeklyReport(
      weekNumber: AppDate.weekOfYear(anyDay),
      weekStart: start,
      weekEnd: end,
      targetMinutes: settings.targetCalculator
          .rangeTargetMinutes(start, end),
      actualMinutes: Analytics.totalMinutes(inWeek),
      studyDays: Analytics.studyDayCount(inWeek),
      topicsCompleted: completedTopics,
      questionsSolved: Analytics.totalQuestions(inWeek),
      currentStreak: streakInfo.current,
      topSubject: topSubject,
      rewardPoints: rewardPoints,
    );
  }
}
