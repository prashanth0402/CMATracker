import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Subjects,
    Chapters,
    Topics,
    StudyTasks,
    StudySessions,
    DailyTargets,
    Rewards,
    Achievements,
    UserSettings,
    AppMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        await into(userSettings).insert(
          const UserSettingsCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_day ON study_sessions(day)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_subject ON study_sessions(subject_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_topic ON study_sessions(topic_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_day ON study_tasks(day)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chapters_subject ON chapters(subject_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_topics_chapter ON topics(chapter_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_rewards_day ON rewards(day)',
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cma_tracker.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    return NativeDatabase.createInBackground(file);
  });
}
