import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/database.dart';
import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../utils/date_utils.dart';

/// JSON backup / restore of the entire local database.
///
/// Restore is transactional: the existing data is wiped and repopulated inside
/// a single transaction, so a malformed import can never leave a half-written
/// database.
class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  Future<Map<String, dynamic>> buildBackup() async {
    final data = <String, dynamic>{
      'schemaVersion': AppConstants.backupSchemaVersion,
      'exportedAt': AppDate.toIso(DateTime.now()),
      'settings': (await _db.select(_db.userSettings).get())
          .map((e) => e.toJson())
          .toList(),
      'subjects':
          (await _db.select(_db.subjects).get()).map((e) => e.toJson()).toList(),
      'chapters':
          (await _db.select(_db.chapters).get()).map((e) => e.toJson()).toList(),
      'topics':
          (await _db.select(_db.topics).get()).map((e) => e.toJson()).toList(),
      'tasks': (await _db.select(_db.studyTasks).get())
          .map((e) => e.toJson())
          .toList(),
      'sessions': (await _db.select(_db.studySessions).get())
          .map((e) => e.toJson())
          .toList(),
      'dailyTargets': (await _db.select(_db.dailyTargets).get())
          .map((e) => e.toJson())
          .toList(),
      'rewards':
          (await _db.select(_db.rewards).get()).map((e) => e.toJson()).toList(),
      'achievements': (await _db.select(_db.achievements).get())
          .map((e) => e.toJson())
          .toList(),
      'appMetadata': (await _db.select(_db.appMetadata).get())
          .map((e) => e.toJson())
          .toList(),
    };
    return data;
  }

  Future<String> exportToFile() async {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(await buildBackup());
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, AppConstants.backupFileName));
      await file.writeAsString(json);
      return file.path;
    } catch (e) {
      throw BackupException('Could not create backup file.', cause: e);
    }
  }

  /// Validates the structure of a decoded backup. Throws [ImportException].
  void validate(Map<String, dynamic> data) {
    const required = [
      'schemaVersion',
      'subjects',
      'chapters',
      'topics',
      'sessions',
    ];
    for (final key in required) {
      if (!data.containsKey(key)) {
        throw ImportException('Backup is missing "$key".');
      }
    }
    final version = data['schemaVersion'];
    if (version is! int || version > AppConstants.backupSchemaVersion) {
      throw const ImportException(
        'Backup was created by a newer app version and cannot be imported.',
      );
    }
    for (final key in ['subjects', 'chapters', 'topics', 'sessions']) {
      if (data[key] is! List) {
        throw ImportException('Backup field "$key" is malformed.');
      }
    }
  }

  Future<void> restoreFromJsonString(String jsonString) async {
    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw ImportException('File is not valid JSON.', cause: e);
    }
    validate(data);

    List<Map<String, dynamic>> list(String key) =>
        ((data[key] as List?) ?? const [])
            .cast<Map<String, dynamic>>();

    try {
      await _db.transaction(() async {
        // Wipe in FK-safe order.
        await _db.delete(_db.studySessions).go();
        await _db.delete(_db.studyTasks).go();
        await _db.delete(_db.topics).go();
        await _db.delete(_db.chapters).go();
        await _db.delete(_db.subjects).go();
        await _db.delete(_db.dailyTargets).go();
        await _db.delete(_db.rewards).go();
        await _db.delete(_db.achievements).go();
        await _db.delete(_db.appMetadata).go();

        for (final r in list('subjects')) {
          await _db.into(_db.subjects).insert(Subject.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('chapters')) {
          await _db.into(_db.chapters).insert(Chapter.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('topics')) {
          await _db.into(_db.topics).insert(Topic.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('tasks')) {
          await _db.into(_db.studyTasks).insert(StudyTask.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('sessions')) {
          await _db.into(_db.studySessions).insert(StudySession.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('dailyTargets')) {
          await _db.into(_db.dailyTargets).insert(DailyTarget.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('rewards')) {
          await _db.into(_db.rewards).insert(Reward.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('achievements')) {
          await _db.into(_db.achievements).insert(Achievement.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('appMetadata')) {
          await _db.into(_db.appMetadata).insert(AppMetadataData.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
        for (final r in list('settings')) {
          await _db.into(_db.userSettings).insert(UserSetting.fromJson(r),
              mode: InsertMode.insertOrReplace);
        }
      });
    } catch (e) {
      if (e is ImportException) rethrow;
      throw ImportException(
        'Restore failed. Your existing data was not changed.',
        cause: e,
      );
    }
  }

  Future<void> resetAllData() async {
    try {
      await _db.transaction(() async {
        await _db.delete(_db.studySessions).go();
        await _db.delete(_db.studyTasks).go();
        await _db.delete(_db.dailyTargets).go();
        await _db.delete(_db.rewards).go();
        await _db.update(_db.achievements).write(
              const AchievementsCompanion(unlockedAt: Value(null)),
            );
        await _db.update(_db.topics).write(
              const TopicsCompanion(status: Value('notStarted')),
            );
        await (_db.delete(_db.appMetadata)
              ..where((t) => t.key.equals('active_timer')))
            .go();
      });
    } catch (e) {
      throw BackupException('Could not reset data.', cause: e);
    }
  }
}
