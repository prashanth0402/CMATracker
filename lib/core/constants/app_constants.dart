/// Application-wide constant values.
///
/// No magic numbers should appear in widgets or business logic – reference
/// these constants instead so behaviour can be tuned in one place.
class AppConstants {
  const AppConstants._();

  static const String appName = 'CMA Tracker';
  static const String backupFileName = 'CMA_Tracker_Backup.json';
  static const int backupSchemaVersion = 1;

  /// Default study targets (minutes).
  static const int defaultWeekdayTargetMinutes = 180; // 3h
  static const int defaultWeekendTargetMinutes = 360; // 6h

  /// Number of weekday / weekend days in a standard week.
  static const int weekdayCount = 5;
  static const int weekendDayCount = 2;

  /// Default weekly target = (5 * 180) + (2 * 360) = 1620 minutes (27h).
  static const int defaultWeeklyTargetMinutes =
      (weekdayCount * defaultWeekdayTargetMinutes) +
      (weekendDayCount * defaultWeekendTargetMinutes);

  /// Timesheet pagination.
  static const int timesheetPageSize = 30;

  /// Minimum minutes for a session to count toward streak-safe dedupe.
  static const int minSessionMinutes = 1;
}

/// Points awarded for various achievements. Configurable in one place.
class RewardPoints {
  const RewardPoints._();

  static const int dailyTargetCompleted = 100;
  static const int weekendTargetCompleted = 150;
  static const int topicCompleted = 25;
  static const int revision = 20;
  static const int mockTest = 50;
  static const int sevenDayStreak = 200;
  static const int weeklyTargetCompleted = 500;
}
