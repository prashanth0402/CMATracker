import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/models/progress_models.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/daily_target_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/study_session_repository.dart';
import '../../data/repositories/study_task_repository.dart';
import '../../data/repositories/syllabus_repository.dart';
import '../constants/enums.dart';
import '../services/backup_service.dart';
import '../services/csv_service.dart';
import '../services/recalculation_service.dart';
import '../services/timer_service.dart';

/// Overridden in [main] with the concrete instance.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

// --- Repositories ----------------------------------------------------------
final settingsRepositoryProvider = Provider(
    (ref) => SettingsRepository(ref.watch(databaseProvider)));
final seedRepositoryProvider =
    Provider((ref) => SeedRepository(ref.watch(databaseProvider)));
final subjectRepositoryProvider =
    Provider((ref) => SubjectRepository(ref.watch(databaseProvider)));
final chapterRepositoryProvider =
    Provider((ref) => ChapterRepository(ref.watch(databaseProvider)));
final topicRepositoryProvider =
    Provider((ref) => TopicRepository(ref.watch(databaseProvider)));
final studyTaskRepositoryProvider =
    Provider((ref) => StudyTaskRepository(ref.watch(databaseProvider)));
final studySessionRepositoryProvider =
    Provider((ref) => StudySessionRepository(ref.watch(databaseProvider)));
final dailyTargetRepositoryProvider =
    Provider((ref) => DailyTargetRepository(ref.watch(databaseProvider)));
final progressRepositoryProvider =
    Provider((ref) => ProgressRepository(ref.watch(databaseProvider)));
final rewardRepositoryProvider =
    Provider((ref) => RewardRepository(ref.watch(databaseProvider)));
final achievementRepositoryProvider =
    Provider((ref) => AchievementRepository(ref.watch(databaseProvider)));

// --- Services ------------------------------------------------------------
final timerServiceProvider =
    Provider((ref) => TimerService(ref.watch(databaseProvider)));
final backupServiceProvider =
    Provider((ref) => BackupService(ref.watch(databaseProvider)));
final csvServiceProvider =
    Provider((ref) => CsvService(ref.watch(databaseProvider)));
final recalculationServiceProvider = Provider(
  (ref) => RecalculationService(
    db: ref.watch(databaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    rewards: ref.watch(rewardRepositoryProvider),
    achievements: ref.watch(achievementRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
  ),
);

// --- Settings ----------------------------------------------------------
final settingsProvider = StreamProvider<AppSettings>(
    (ref) => ref.watch(settingsRepositoryProvider).watch());

final themeModeProvider = Provider<ThemeMode>((ref) {
  final option = ref.watch(settingsProvider).valueOrNull?.themeMode ??
      ThemeModeOption.system;
  return switch (option) {
    ThemeModeOption.system => ThemeMode.system,
    ThemeModeOption.light => ThemeMode.light,
    ThemeModeOption.dark => ThemeMode.dark,
  };
});

// --- Selected date (dashboard / progress / calendar) ---------------------
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// --- Syllabus --------------------------------------------------------
final subjectsProvider = FutureProvider<List<Subject>>(
    (ref) => ref.watch(subjectRepositoryProvider).all());

final chaptersProvider = StreamProvider.family<List<Chapter>, int>(
    (ref, subjectId) =>
        ref.watch(chapterRepositoryProvider).watchForSubject(subjectId));

final topicsForChapterProvider = StreamProvider.family<List<Topic>, int>(
    (ref, chapterId) =>
        ref.watch(topicRepositoryProvider).watchForChapter(chapterId));

final topicsForSubjectProvider = StreamProvider.family<List<Topic>, int>(
    (ref, subjectId) =>
        ref.watch(topicRepositoryProvider).watchForSubject(subjectId));

// --- Tasks ---------------------------------------------------------
final tasksForSelectedDayProvider = StreamProvider<List<StudyTask>>((ref) {
  final day = ref.watch(selectedDateProvider);
  return ref.watch(studyTaskRepositoryProvider).watchForDay(day);
});

final upcomingTasksProvider = StreamProvider<List<StudyTask>>(
    (ref) => ref.watch(studyTaskRepositoryProvider).watchUpcoming());

// --- Sessions -----------------------------------------------------
final allSessionsProvider = StreamProvider<List<StudySession>>(
    (ref) => ref.watch(studySessionRepositoryProvider).watchAll());

// --- Derived progress (recompute whenever sessions or settings change) ---
AppSettings _requireSettings(Ref ref) =>
    ref.watch(settingsProvider).valueOrNull ??
    (throw StateError('settings not loaded'));

final dailyProgressProvider = FutureProvider<PeriodProgress>((ref) async {
  ref.watch(allSessionsProvider);
  final settings = _requireSettings(ref);
  final day = ref.watch(selectedDateProvider);
  return ref.watch(progressRepositoryProvider).daily(day, settings);
});

final weeklyProgressProvider = FutureProvider<PeriodProgress>((ref) async {
  ref.watch(allSessionsProvider);
  final settings = _requireSettings(ref);
  final day = ref.watch(selectedDateProvider);
  return ref.watch(progressRepositoryProvider).weekly(day, settings);
});

final monthlyProgressProvider = FutureProvider<PeriodProgress>((ref) async {
  ref.watch(allSessionsProvider);
  final settings = _requireSettings(ref);
  final day = ref.watch(selectedDateProvider);
  return ref.watch(progressRepositoryProvider).monthly(day, settings);
});

final streakProvider = FutureProvider<StreakInfo>((ref) async {
  ref.watch(allSessionsProvider);
  final settings = _requireSettings(ref);
  return ref.watch(progressRepositoryProvider).streak(settings);
});

final subjectProgressProvider =
    FutureProvider<List<SubjectProgress>>((ref) async {
  ref.watch(allSessionsProvider);
  ref.watch(settingsProvider);
  return ref.watch(progressRepositoryProvider).subjectProgress();
});

final monthDayStatsProvider = FutureProvider<List<DayStat>>((ref) async {
  ref.watch(allSessionsProvider);
  final settings = _requireSettings(ref);
  final day = ref.watch(selectedDateProvider);
  return ref.watch(progressRepositoryProvider).monthDayStats(day, settings);
});

final weeklyReportProvider = FutureProvider<WeeklyReport>((ref) async {
  ref.watch(allSessionsProvider);
  final settings = _requireSettings(ref);
  final day = ref.watch(selectedDateProvider);
  final start = day.subtract(Duration(days: day.weekday - settings.startOfWeek));
  final end = start.add(const Duration(days: 6));
  final points =
      await ref.watch(rewardRepositoryProvider).pointsInRange(start, end);
  return ref
      .watch(progressRepositoryProvider)
      .weeklyReport(day, settings, points);
});

// --- Rewards / achievements ------------------------------------------
final totalPointsProvider = StreamProvider<int>(
    (ref) => ref.watch(rewardRepositoryProvider).watchTotalPoints());

final recentRewardsProvider = StreamProvider<List<Reward>>(
    (ref) => ref.watch(rewardRepositoryProvider).watchRecent());

final achievementsProvider = StreamProvider<List<Achievement>>(
    (ref) => ref.watch(achievementRepositoryProvider).watchAll());

/// Cached id -> title lookups for subjects / chapters / topics.
class SyllabusLookup {
  const SyllabusLookup(this.subjects, this.chapters, this.topics);
  final Map<int, String> subjects;
  final Map<int, String> chapters;
  final Map<int, String> topics;

  String subject(int? id) => id == null ? '' : (subjects[id] ?? '');
  String chapter(int? id) => id == null ? '' : (chapters[id] ?? '');
  String topic(int? id) => id == null ? '' : (topics[id] ?? '');
}

final syllabusLookupProvider = FutureProvider<SyllabusLookup>((ref) async {
  final db = ref.watch(databaseProvider);
  final subjects = await db.select(db.subjects).get();
  final chapters = await db.select(db.chapters).get();
  final topics = await db.select(db.topics).get();
  return SyllabusLookup(
    {for (final s in subjects) s.id: s.title},
    {for (final c in chapters) c.id: c.title},
    {for (final t in topics) t.id: t.title},
  );
});
