import '../../data/database/database.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../constants/app_constants.dart';
import '../constants/enums.dart';
import '../utils/date_utils.dart';

/// Single entry point invoked after any session is created, edited or deleted.
/// Recomputes derived progress and (idempotently) awards points / unlocks
/// achievements. Progress numbers themselves are never stored – only the
/// append-only rewards ledger and achievement unlock flags.
class RecalculationService {
  RecalculationService({
    required AppDatabase db,
    required SettingsRepository settings,
    required RewardRepository rewards,
    required AchievementRepository achievements,
    required ProgressRepository progress,
  })  : _db = db,
        _settingsRepo = settings,
        _rewards = rewards,
        _achievements = achievements,
        _progress = progress;

  final AppDatabase _db;
  final SettingsRepository _settingsRepo;
  final RewardRepository _rewards;
  final AchievementRepository _achievements;
  final ProgressRepository _progress;

  Future<void> onSessionChanged({DateTime? affectedDay}) async {
    final settings = await _settingsRepo.load();
    final now = DateTime.now();
    final day = affectedDay ?? now;

    // ---- Daily target award -------------------------------------------------
    final daily = await _progress.daily(day, settings);
    if (daily.isMet) {
      final weekend = AppDate.isWeekend(day);
      await _rewards.awardOnce(
        type: 'daily_target',
        day: day,
        points: weekend
            ? RewardPoints.weekendTargetCompleted
            : RewardPoints.dailyTargetCompleted,
      );
    }

    // ---- Weekly target award ---------------------------------------------
    final weekly = await _progress.weekly(day, settings);
    if (weekly.isMet) {
      final weekStart =
          AppDate.weekStart(day, startOfWeek: settings.startOfWeek);
      await _rewards.awardOnce(
        type: 'weekly_target',
        day: weekStart,
        points: RewardPoints.weeklyTargetCompleted,
      );
    }

    // ---- Streak award ---------------------------------------------------
    final streak = await _progress.streak(settings);
    if (streak.current >= 7) {
      // One award per completed 7-day block, keyed by block index.
      final block = streak.current ~/ 7;
      await _rewards.awardPerEntity(
        type: 'streak_7',
        day: now,
        points: RewardPoints.sevenDayStreak,
        entityKey: 'block_$block',
      );
    }

    // ---- Per-session activity awards + topic auto-status ------------------
    final sameDay = await _sessionsForDay(day);
    for (final s in sameDay) {
      final activity = ActivityType.fromName(s.activityType);
      if (activity == ActivityType.mockTest) {
        await _rewards.awardPerEntity(
          type: 'mock_test',
          day: AppDate.fromIso(s.startTime),
          points: RewardPoints.mockTest,
          entityKey: 'session_${s.id}',
        );
      }
      if (activity == ActivityType.revised ||
          activity == ActivityType.revision) {
        await _rewards.awardPerEntity(
          type: 'revision',
          day: AppDate.fromIso(s.startTime),
          points: RewardPoints.revision,
          entityKey: 'session_${s.id}',
        );
      }
    }

    // ---- Topic completion awards ----------------------------------------
    final completedTopics = await (_db.select(_db.topics)
          ..where((t) => t.status.isIn([
                TopicStatus.completed.name,
                TopicStatus.revised.name,
                TopicStatus.mastered.name,
              ])))
        .get();
    for (final t in completedTopics) {
      await _rewards.awardPerEntity(
        type: 'topic_completed',
        day: now,
        points: RewardPoints.topicCompleted,
        entityKey: 'topic_${t.id}',
      );
    }

    // ---- Achievements --------------------------------------------------
    await _achievements.reevaluate(settings);
    final monthly = await _progress.monthly(now, settings);
    await _achievements.unlockMonthlyChampionIfMet(monthly.isMet);
  }

  Future<List<StudySession>> _sessionsForDay(DateTime day) {
    final iso = AppDate.isoDay(day);
    return (_db.select(_db.studySessions)..where((s) => s.day.equals(iso)))
        .get();
  }
}
