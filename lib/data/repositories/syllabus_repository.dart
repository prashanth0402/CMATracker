import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../database/database.dart';

/// Read-mostly access to Subjects. Syllabus is static so callers may cache.
class SubjectRepository {
  SubjectRepository(this._db);
  final AppDatabase _db;

  Future<List<Subject>> all() {
    return (_db.select(_db.subjects)
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
  }

  Stream<List<Subject>> watchAll() {
    return (_db.select(_db.subjects)
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<Subject> byId(int id) async {
    final row = await (_db.select(_db.subjects)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw NotFoundException('Subject not found.');
    return row;
  }
}

class ChapterRepository {
  ChapterRepository(this._db);
  final AppDatabase _db;

  Future<List<Chapter>> forSubject(int subjectId) {
    return (_db.select(_db.chapters)
          ..where((t) => t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
  }

  Stream<List<Chapter>> watchForSubject(int subjectId) {
    return (_db.select(_db.chapters)
          ..where((t) => t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<Chapter> byId(int id) async {
    final row = await (_db.select(_db.chapters)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw NotFoundException('Chapter not found.');
    return row;
  }
}

class TopicRepository {
  TopicRepository(this._db);
  final AppDatabase _db;

  Future<List<Topic>> forChapter(int chapterId) {
    return (_db.select(_db.topics)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
  }

  Stream<List<Topic>> watchForChapter(int chapterId) {
    return (_db.select(_db.topics)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Stream<List<Topic>> watchForSubject(int subjectId) {
    return (_db.select(_db.topics)
          ..where((t) => t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<List<Topic>> all() => _db.select(_db.topics).get();

  Future<Topic> byId(int id) async {
    final row = await (_db.select(_db.topics)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw NotFoundException('Topic not found.');
    return row;
  }

  Future<void> setStatus(int topicId, TopicStatus status) async {
    try {
      await (_db.update(_db.topics)..where((t) => t.id.equals(topicId))).write(
        TopicsCompanion(
          status: Value(status.name),
          updatedAt: Value(AppDate.toIso(DateTime.now())),
        ),
      );
    } catch (e) {
      throw DatabaseException('Could not update topic status.', cause: e);
    }
  }

  /// Auto-advance status from a saved session, without ever downgrading a
  /// manually set higher status.
  Future<void> applySessionProgress(int topicId, ActivityType activity) async {
    final topic = await byId(topicId);
    final current = TopicStatus.fromName(topic.status);
    TopicStatus next = current;
    switch (activity) {
      case ActivityType.revised:
      case ActivityType.revision:
        if (current.index < TopicStatus.revised.index) {
          next = TopicStatus.revised;
        }
        break;
      case ActivityType.mockTest:
        if (current.index < TopicStatus.completed.index) {
          next = TopicStatus.completed;
        }
        break;
      default:
        if (current == TopicStatus.notStarted) next = TopicStatus.inProgress;
    }
    if (next != current) await setStatus(topicId, next);
  }
}
