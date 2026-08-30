import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../database/database.dart';

/// Input value object for creating / editing a session.
class SessionInput {
  const SessionInput({
    this.taskId,
    required this.subjectId,
    this.chapterId,
    this.topicId,
    required this.start,
    required this.end,
    required this.activityType,
    this.description = '',
    this.difficulty = Difficulty.medium,
    this.understanding = 3,
    this.questionsSolved = 0,
  });

  final int? taskId;
  final int subjectId;
  final int? chapterId;
  final int? topicId;
  final DateTime start;
  final DateTime end;
  final ActivityType activityType;
  final String description;
  final Difficulty difficulty;
  final int understanding;
  final int questionsSolved;

  /// Duration in whole minutes. Sessions crossing midnight are handled because
  /// [start] / [end] are absolute DateTimes.
  int get durationMinutes => end.difference(start).inMinutes;

  void validate() {
    if (!end.isAfter(start)) {
      throw const ValidationException('End time must be after start time.');
    }
    if (durationMinutes < 1) {
      throw const ValidationException('Session must be at least 1 minute long.');
    }
    if (understanding < 1 || understanding > 5) {
      throw const ValidationException('Understanding must be between 1 and 5.');
    }
    if (questionsSolved < 0) {
      throw const ValidationException('Questions solved cannot be negative.');
    }
  }
}

class StudySessionRepository {
  StudySessionRepository(this._db);
  final AppDatabase _db;

  StudySessionsCompanion _toCompanion(SessionInput i, {required bool isNew}) {
    final now = AppDate.toIso(DateTime.now());
    return StudySessionsCompanion(
      taskId: Value(i.taskId),
      subjectId: Value(i.subjectId),
      chapterId: Value(i.chapterId),
      topicId: Value(i.topicId),
      day: Value(AppDate.isoDay(i.start)),
      startTime: Value(AppDate.toIso(i.start)),
      endTime: Value(AppDate.toIso(i.end)),
      durationMinutes: Value(i.durationMinutes),
      activityType: Value(i.activityType.name),
      description: Value(i.description.trim()),
      difficulty: Value(i.difficulty.name),
      understanding: Value(i.understanding),
      questionsSolved: Value(i.questionsSolved),
      createdAt: isNew ? Value(now) : const Value.absent(),
      updatedAt: Value(now),
    );
  }

  Future<int> create(SessionInput input) async {
    input.validate();
    try {
      return await _db
          .into(_db.studySessions)
          .insert(_toCompanion(input, isNew: true));
    } catch (e) {
      throw DatabaseException('Could not save session.', cause: e);
    }
  }

  Future<void> update(int id, SessionInput input) async {
    input.validate();
    try {
      await (_db.update(_db.studySessions)..where((t) => t.id.equals(id)))
          .write(_toCompanion(input, isNew: false));
    } catch (e) {
      throw DatabaseException('Could not update session.', cause: e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await (_db.delete(_db.studySessions)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Could not delete session.', cause: e);
    }
  }

  Future<StudySession> byId(int id) async {
    final row = await (_db.select(_db.studySessions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw NotFoundException('Session not found.');
    return row;
  }

  Future<int> duplicate(int id) async {
    final s = await byId(id);
    final now = AppDate.toIso(DateTime.now());
    return _db.into(_db.studySessions).insert(
          s
              .toCompanion(false)
              .copyWith(
                id: const Value.absent(),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
        );
  }

  Stream<List<StudySession>> watchAll() {
    return (_db.select(_db.studySessions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.startTime,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<List<StudySession>> inRange(DateTime from, DateTime to) {
    final f = AppDate.isoDay(from);
    final t = AppDate.isoDay(to);
    return (_db.select(_db.studySessions)
          ..where((s) => s.day.isBetweenValues(f, t))
          ..orderBy([(s) => OrderingTerm(expression: s.startTime)]))
        .get();
  }

  Stream<List<StudySession>> watchInRange(DateTime from, DateTime to) {
    final f = AppDate.isoDay(from);
    final t = AppDate.isoDay(to);
    return (_db.select(_db.studySessions)
          ..where((s) => s.day.isBetweenValues(f, t))
          ..orderBy([(s) => OrderingTerm(expression: s.startTime)]))
        .watch();
  }

  Future<List<StudySession>> all() => _db.select(_db.studySessions).get();

  /// Paginated history for the timesheet, newest first.
  Future<List<StudySession>> page({
    required int limit,
    required int offset,
  }) {
    return (_db.select(_db.studySessions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.startTime,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit, offset: offset))
        .get();
  }
}
