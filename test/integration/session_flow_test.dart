import 'dart:convert';

import 'package:cma_tracker/core/constants/enums.dart';
import 'package:cma_tracker/core/services/backup_service.dart';
import 'package:cma_tracker/core/services/csv_service.dart';
import 'package:cma_tracker/core/services/recalculation_service.dart';
import 'package:cma_tracker/data/database/database.dart';
import 'package:cma_tracker/data/repositories/achievement_repository.dart';
import 'package:cma_tracker/data/repositories/progress_repository.dart';
import 'package:cma_tracker/data/repositories/reward_repository.dart';
import 'package:cma_tracker/data/repositories/seed_repository.dart';
import 'package:cma_tracker/data/repositories/settings_repository.dart';
import 'package:cma_tracker/data/repositories/study_session_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StudySessionRepository sessions;
  late ProgressRepository progress;
  late RewardRepository rewards;
  late SettingsRepository settings;
  late RecalculationService recalc;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedRepository(db).ensureSeeded();
    sessions = StudySessionRepository(db);
    progress = ProgressRepository(db);
    rewards = RewardRepository(db);
    settings = SettingsRepository(db);
    recalc = RecalculationService(
      db: db,
      settings: settings,
      rewards: rewards,
      achievements: AchievementRepository(db),
      progress: progress,
    );
  });

  tearDown(() => db.close());

  test('seed inserts the full Group 1 syllabus', () async {
    expect((await db.select(db.subjects).get()).length, 4);
    expect((await db.select(db.topics).get()).length, greaterThan(150));
  });

  test('saving a session updates daily progress automatically', () async {
    final day = DateTime(2026, 8, 31, 9); // Monday
    await sessions.create(SessionInput(
      subjectId: 1,
      start: day,
      end: day.add(const Duration(minutes: 90)),
      activityType: ActivityType.studied,
    ));
    final s = await settings.load();
    final p = await progress.daily(day, s);
    expect(p.actualMinutes, 90);
    expect(p.targetMinutes, 180);
    expect(p.percent, 50);
  });

  test('hitting the daily target awards points once (no duplicates)', () async {
    final day = DateTime(2026, 8, 31, 8);
    await sessions.create(SessionInput(
      subjectId: 1,
      start: day,
      end: day.add(const Duration(minutes: 180)),
      activityType: ActivityType.studied,
    ));
    await recalc.onSessionChanged(affectedDay: day);
    await recalc.onSessionChanged(affectedDay: day);
    expect(await rewards.totalPoints(), 100);
  });

  test('editing then deleting a session recalculates progress', () async {
    final day = DateTime(2026, 8, 31, 9);
    final id = await sessions.create(SessionInput(
      subjectId: 1,
      start: day,
      end: day.add(const Duration(minutes: 120)),
      activityType: ActivityType.studied,
    ));
    await sessions.update(
      id,
      SessionInput(
        subjectId: 1,
        start: day,
        end: day.add(const Duration(minutes: 60)),
        activityType: ActivityType.studied,
      ),
    );
    final s = await settings.load();
    expect((await progress.daily(day, s)).actualMinutes, 60);
    await sessions.delete(id);
    expect((await progress.daily(day, s)).actualMinutes, 0);
  });

  test('CSV export contains a header and the session description', () async {
    final day = DateTime(2026, 8, 31, 9);
    await sessions.create(SessionInput(
      subjectId: 1,
      start: day,
      end: day.add(const Duration(minutes: 60)),
      activityType: ActivityType.studied,
      description: 'Studied contract law',
    ));
    final csvService = CsvService(db);
    final csv = csvService.buildCsv(await csvService.buildRows(await sessions.all()));
    expect(csv, contains('Date,Subject'));
    expect(csv, contains('Studied contract law'));
  });

  test('JSON backup round-trips through restore', () async {
    final day = DateTime(2026, 8, 31, 9);
    await sessions.create(SessionInput(
      subjectId: 2,
      start: day,
      end: day.add(const Duration(minutes: 45)),
      activityType: ActivityType.practicedQuestions,
      questionsSolved: 12,
    ));
    final backup = BackupService(db);
    final json = jsonEncode(await backup.buildBackup());

    await db.delete(db.studySessions).go();
    expect((await sessions.all()).length, 0);

    await backup.restoreFromJsonString(json);
    final restored = await sessions.all();
    expect(restored.length, 1);
    expect(restored.first.questionsSolved, 12);
  });

  test('restore rejects a malformed backup without touching data', () async {
    final day = DateTime(2026, 8, 31, 9);
    await sessions.create(SessionInput(
      subjectId: 1,
      start: day,
      end: day.add(const Duration(minutes: 30)),
      activityType: ActivityType.studied,
    ));
    await expectLater(
      BackupService(db).restoreFromJsonString('{"not":"a backup"}'),
      throwsA(anything),
    );
    expect((await sessions.all()).length, 1);
  });
}
