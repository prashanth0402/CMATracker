import 'package:drift/drift.dart';

/// CMA Group 1 subjects (papers 5-8).
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 32)();
  TextColumn get title => text().withLength(min: 1, max: 128)();
  IntColumn get paperNumber => integer()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}

class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}

class Topics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId =>
      integer().references(Chapters, #id, onDelete: KeyAction.cascade)();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('notStarted'))();
  TextColumn get updatedAt => text().nullable()();
}

class StudyTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get chapterId =>
      integer().nullable().references(Chapters, #id, onDelete: KeyAction.setNull)();
  IntColumn get topicId =>
      integer().nullable().references(Topics, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get day => text()(); // yyyy-MM-dd (local)
  IntColumn get plannedMinutes => integer().withDefault(const Constant(0))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get completedAt => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().nullable().references(StudyTasks, #id, onDelete: KeyAction.setNull)();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get chapterId =>
      integer().nullable().references(Chapters, #id, onDelete: KeyAction.setNull)();
  IntColumn get topicId =>
      integer().nullable().references(Topics, #id, onDelete: KeyAction.setNull)();
  TextColumn get day => text()(); // yyyy-MM-dd of startTime (local)
  TextColumn get startTime => text()(); // ISO-8601 UTC
  TextColumn get endTime => text()(); // ISO-8601 UTC
  IntColumn get durationMinutes => integer()();
  TextColumn get activityType => text().withDefault(const Constant('studied'))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  IntColumn get understanding => integer().withDefault(const Constant(3))();
  IntColumn get questionsSolved => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

/// Optional per-day target overrides. Absence => use settings-derived target.
class DailyTargets extends Table {
  TextColumn get day => text()(); // yyyy-MM-dd
  IntColumn get targetMinutes => integer()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Append-only points ledger.
class Rewards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get points => integer()();
  TextColumn get day => text()(); // yyyy-MM-dd the award relates to
  TextColumn get meta => text().nullable()();
  TextColumn get createdAt => text()();
}

class Achievements extends Table {
  TextColumn get code => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get unlockedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

/// Single-row (id = 1) typed settings.
class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get weekdayTargetMinutes =>
      integer().withDefault(const Constant(180))();
  IntColumn get weekendTargetMinutes =>
      integer().withDefault(const Constant(360))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  IntColumn get startOfWeek => integer().withDefault(const Constant(1))(); // Mon
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderHour => integer().withDefault(const Constant(19))();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key/value store for misc app state (e.g. persisted active timer).
class AppMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
