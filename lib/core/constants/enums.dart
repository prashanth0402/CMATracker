// Shared enumerations, stored in the database as their `name` string.

enum ActivityType {
  studied,
  revised,
  practicedQuestions,
  mockTest,
  watchedLecture,
  readNotes,
  doubtClearing,
  revision;

  String get label => switch (this) {
    ActivityType.studied => 'Studied',
    ActivityType.revised => 'Revised',
    ActivityType.practicedQuestions => 'Practiced Questions',
    ActivityType.mockTest => 'Mock Test',
    ActivityType.watchedLecture => 'Watched Lecture',
    ActivityType.readNotes => 'Read Notes',
    ActivityType.doubtClearing => 'Doubt Clearing',
    ActivityType.revision => 'Revision',
  };

  static ActivityType fromName(String value) => ActivityType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ActivityType.studied,
  );
}

enum Difficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Hard',
  };

  static Difficulty fromName(String value) => Difficulty.values.firstWhere(
    (e) => e.name == value,
    orElse: () => Difficulty.medium,
  );
}

enum TopicStatus {
  notStarted,
  inProgress,
  completed,
  revised,
  mastered;

  String get label => switch (this) {
    TopicStatus.notStarted => 'Not Started',
    TopicStatus.inProgress => 'In Progress',
    TopicStatus.completed => 'Completed',
    TopicStatus.revised => 'Revised',
    TopicStatus.mastered => 'Mastered',
  };

  static TopicStatus fromName(String value) => TopicStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TopicStatus.notStarted,
  );
}

enum TaskPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  static TaskPriority fromName(String value) => TaskPriority.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TaskPriority.medium,
  );
}

enum TimerState { idle, running, paused, completed }

enum ThemeModeOption {
  system,
  light,
  dark;

  String get label => switch (this) {
    ThemeModeOption.system => 'System',
    ThemeModeOption.light => 'Light',
    ThemeModeOption.dark => 'Dark',
  };

  static ThemeModeOption fromName(String value) =>
      ThemeModeOption.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeModeOption.system,
      );
}

enum DayCompletion { none, partial, targetCompleted, aboveTarget }
