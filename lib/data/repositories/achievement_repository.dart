import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/date_utils.dart';
import '../database/database.dart';
import 'settings_repository.dart';

/// Unlocks achievements strictly from stored data. Re-evaluated after every
/// session change; unlock timestamps are only ever set once.
class AchievementRepository {
  AchievementRepository(this._db);
  final AppDatabase _db;

  Stream<List<Achievement>> watchAll() {
    return (_db.select(_db.achievements)
          ..orderBy([(a) => OrderingTerm(expression: a.code)]))
        .watch();
  }

  Future<List<Achievement>> all() => _db.select(_db.achievements).get();

  Future<void> _unlock(String code) async {
    final row = await (_db.select(_db.achievements)
          ..where((a) => a.code.equals(code)))
        .getSingleOrNull();
    if (row == null || row.unlockedAt != null) return;
    await (_db.update(_db.achievements)..where((a) => a.code.equals(code)))
        .write(AchievementsCompanion(
      unlockedAt: Value(AppDate.toIso(DateTime.now())),
    ));
  }

  Future<void> reevaluate(AppSettings settings) async {
    final sessions = await _db.select(_db.studySessions).get();
    final topics = await _db.select(_db.topics).get();
    final subjects = await _db.select(_db.subjects).get();

    final agg = sessions
        .map((s) => SessionAgg(
              start: AppDate.fromIso(s.startTime),
              durationMinutes: s.durationMinutes,
              subjectId: s.subjectId,
              topicId: s.topicId,
              activity: ActivityType.fromName(s.activityType),
              questionsSolved: s.questionsSolved,
            ))
        .toList();

    final totalMinutes = Analytics.totalMinutes(agg);
    final totalHours = totalMinutes / 60.0;
    final streak = Analytics.streak(agg, settings.targetCalculator);
    final byDay = Analytics.minutesByDay(agg);

    final completedTopics = topics
        .where((t) =>
            TopicStatus.fromName(t.status).index >=
            TopicStatus.completed.index)
        .length;

    final targetDays = byDay.entries.where((e) {
      final d = AppDate.fromIso('${e.key}T00:00:00');
      return e.value >= settings.targetCalculator.targetForDay(d);
    }).length;

    // Days studied in the current calendar month.
    final now = DateTime.now();
    final monthDays = byDay.keys
        .where((k) => k.startsWith(
            '${now.year}-${now.month.toString().padLeft(2, '0')}'))
        .length;

    // Subject fully completed?
    var subjectChampion = false;
    for (final subj in subjects) {
      final subjTopics = topics.where((t) => t.subjectId == subj.id).toList();
      if (subjTopics.isNotEmpty &&
          subjTopics.every((t) =>
              TopicStatus.fromName(t.status).index >=
              TopicStatus.completed.index)) {
        subjectChampion = true;
        break;
      }
    }

    if (streak.current >= 7 || streak.longest >= 7) {
      await _unlock('seven_day_warrior');
    }
    if (streak.longest >= 30) await _unlock('thirty_day_warrior');
    if (targetDays >= 20) await _unlock('target_master');
    if (totalHours >= 100) {
      await _unlock('time_master');
      await _unlock('hundred_hours');
    }
    if (subjectChampion) await _unlock('subject_champion');
    if (completedTopics >= 100) await _unlock('hundred_topics');
    if (monthDays >= 25) await _unlock('consistency_king');
    if (totalHours >= 300) await _unlock('cma_warrior');
  }

  Future<void> unlockMonthlyChampionIfMet(bool met) async {
    if (met) await _unlock('monthly_champion');
  }

  Future<void> resetAll() async {
    await _db.update(_db.achievements).write(
          const AchievementsCompanion(unlockedAt: Value(null)),
        );
  }
}
