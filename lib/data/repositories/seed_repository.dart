import 'package:drift/drift.dart';

import '../../core/errors/app_exceptions.dart';
import '../database/database.dart';
import '../seed/syllabus_seed.dart';

/// Populates the database with the CMA Group 1 syllabus and achievement
/// definitions exactly once (idempotent).
class SeedRepository {
  SeedRepository(this._db);
  final AppDatabase _db;

  static const _seededKey = 'syllabus_seeded_v1';

  Future<bool> _alreadySeeded() async {
    final row = await (_db.select(_db.appMetadata)
          ..where((t) => t.key.equals(_seededKey)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> ensureSeeded() async {
    try {
      if (await _alreadySeeded()) return;
      await _db.transaction(() async {
        for (var s = 0; s < kSyllabus.length; s++) {
          final subj = kSyllabus[s];
          final subjectId = await _db.into(_db.subjects).insert(
                SubjectsCompanion.insert(
                  code: subj.code,
                  title: subj.title,
                  paperNumber: subj.paperNumber,
                  orderIndex: Value(s),
                ),
              );
          for (var c = 0; c < subj.chapters.length; c++) {
            final chap = subj.chapters[c];
            final chapterId = await _db.into(_db.chapters).insert(
                  ChaptersCompanion.insert(
                    subjectId: subjectId,
                    title: chap.title,
                    orderIndex: Value(c),
                  ),
                );
            for (var t = 0; t < chap.topics.length; t++) {
              await _db.into(_db.topics).insert(
                    TopicsCompanion.insert(
                      chapterId: chapterId,
                      subjectId: subjectId,
                      title: chap.topics[t],
                      orderIndex: Value(t),
                    ),
                  );
            }
          }
        }
        for (final a in kAchievements) {
          await _db.into(_db.achievements).insert(
                AchievementsCompanion.insert(
                  code: a.code,
                  title: a.title,
                  description: a.description,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        await _db.into(_db.appMetadata).insert(
              AppMetadataCompanion.insert(
                key: _seededKey,
                value: DateTime.now().toUtc().toIso8601String(),
              ),
            );
      });
    } catch (e) {
      throw DatabaseException('Failed to initialise syllabus data.', cause: e);
    }
  }
}
