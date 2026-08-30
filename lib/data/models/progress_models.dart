import '../../core/utils/date_utils.dart';

/// Immutable analytic value objects derived from stored sessions.

class PeriodProgress {
  const PeriodProgress({
    required this.targetMinutes,
    required this.actualMinutes,
    required this.label,
  });

  final int targetMinutes;
  final int actualMinutes;
  final String label;

  int get remainingMinutes =>
      (targetMinutes - actualMinutes).clamp(0, 1 << 31);

  double get fraction =>
      targetMinutes <= 0 ? 0 : (actualMinutes / targetMinutes).clamp(0.0, 1.0);

  int get percent => (fraction * 100).round();

  bool get isMet => actualMinutes >= targetMinutes && targetMinutes > 0;

  String get actualLabel => AppDate.formatMinutes(actualMinutes);
  String get targetLabel => AppDate.formatMinutes(targetMinutes);
  String get remainingLabel => AppDate.formatMinutes(remainingMinutes);

  static const empty = PeriodProgress(
    targetMinutes: 0,
    actualMinutes: 0,
    label: '',
  );
}

class SubjectProgress {
  const SubjectProgress({
    required this.subjectId,
    required this.subjectTitle,
    required this.totalTopics,
    required this.completedTopics,
    required this.revisedTopics,
    required this.masteredTopics,
    required this.studyMinutes,
    required this.practiceMinutes,
    required this.questionsSolved,
  });

  final int subjectId;
  final String subjectTitle;
  final int totalTopics;
  final int completedTopics;
  final int revisedTopics;
  final int masteredTopics;
  final int studyMinutes;
  final int practiceMinutes;
  final int questionsSolved;

  double get completionFraction =>
      totalTopics == 0 ? 0 : completedTopics / totalTopics;
}

class StreakInfo {
  const StreakInfo({required this.current, required this.longest});
  final int current;
  final int longest;

  static const zero = StreakInfo(current: 0, longest: 0);
}

class DayStat {
  const DayStat({
    required this.day,
    required this.targetMinutes,
    required this.actualMinutes,
    required this.sessionCount,
  });

  final DateTime day;
  final int targetMinutes;
  final int actualMinutes;
  final int sessionCount;

  double get fraction =>
      targetMinutes <= 0 ? 0 : actualMinutes / targetMinutes;
}

class WeeklyReport {
  const WeeklyReport({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.targetMinutes,
    required this.actualMinutes,
    required this.studyDays,
    required this.topicsCompleted,
    required this.questionsSolved,
    required this.currentStreak,
    required this.topSubject,
    required this.rewardPoints,
  });

  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int targetMinutes;
  final int actualMinutes;
  final int studyDays;
  final int topicsCompleted;
  final int questionsSolved;
  final int currentStreak;
  final String topSubject;
  final int rewardPoints;

  int get achievementPercent =>
      targetMinutes <= 0 ? 0 : ((actualMinutes / targetMinutes) * 100).round();
}
