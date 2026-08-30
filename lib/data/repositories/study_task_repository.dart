import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../database/database.dart';

class StudyTaskRepository {
  StudyTaskRepository(this._db);
  final AppDatabase _db;

  Stream<List<StudyTask>> watchForDay(DateTime day) {
    final iso = AppDate.isoDay(day);
    return (_db.select(_db.studyTasks)
          ..where((t) => t.day.equals(iso))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted),
            (t) => OrderingTerm(expression: t.priority),
          ]))
        .watch();
  }

  Stream<List<StudyTask>> watchUpcoming() {
    final today = AppDate.isoDay(DateTime.now());
    return (_db.select(_db.studyTasks)
          ..where((t) => t.day.isBiggerOrEqualValue(today) & t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.day)]))
        .watch();
  }

  Future<StudyTask> byId(int id) async {
    final row = await (_db.select(_db.studyTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw NotFoundException('Task not found.');
    return row;
  }

  Future<int> create({
    required int subjectId,
    int? chapterId,
    int? topicId,
    required String title,
    required DateTime day,
    required int plannedMinutes,
    required TaskPriority priority,
    String notes = '',
  }) async {
    if (title.trim().isEmpty) {
      throw const ValidationException('Task title is required.');
    }
    if (plannedMinutes < 0) {
      throw const ValidationException('Planned minutes cannot be negative.');
    }
    final now = AppDate.toIso(DateTime.now());
    try {
      return await _db.into(_db.studyTasks).insert(
            StudyTasksCompanion.insert(
              subjectId: subjectId,
              chapterId: Value(chapterId),
              topicId: Value(topicId),
              title: title.trim(),
              day: AppDate.isoDay(day),
              plannedMinutes: Value(plannedMinutes),
              priority: Value(priority.name),
              notes: Value(notes.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } catch (e) {
      throw DatabaseException('Could not create task.', cause: e);
    }
  }

  Future<void> updateTask(int id, StudyTasksCompanion changes) async {
    try {
      await (_db.update(_db.studyTasks)..where((t) => t.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(AppDate.toIso(DateTime.now()))),
      );
    } catch (e) {
      throw DatabaseException('Could not update task.', cause: e);
    }
  }

  Future<void> setCompleted(int id, bool completed) async {
    await updateTask(
      id,
      StudyTasksCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? AppDate.toIso(DateTime.now()) : null),
      ),
    );
  }

  Future<void> reschedule(int id, DateTime newDay) =>
      updateTask(id, StudyTasksCompanion(day: Value(AppDate.isoDay(newDay))));

  Future<int> duplicate(int id) async {
    final t = await byId(id);
    final now = AppDate.toIso(DateTime.now());
    return _db.into(_db.studyTasks).insert(
          StudyTasksCompanion.insert(
            subjectId: t.subjectId,
            chapterId: Value(t.chapterId),
            topicId: Value(t.topicId),
            title: '${t.title} (copy)',
            day: t.day,
            plannedMinutes: Value(t.plannedMinutes),
            priority: Value(t.priority),
            notes: Value(t.notes),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> delete(int id) async {
    try {
      await (_db.delete(_db.studyTasks)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Could not delete task.', cause: e);
    }
  }
}
