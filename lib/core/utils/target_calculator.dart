import 'date_utils.dart';

/// Pure functions that derive study targets from configurable settings.
/// Never hardcode target values in widgets – always go through this.
class TargetCalculator {
  const TargetCalculator({
    required this.weekdayTargetMinutes,
    required this.weekendTargetMinutes,
  });

  final int weekdayTargetMinutes;
  final int weekendTargetMinutes;

  /// Target for a specific calendar day.
  int targetForDay(DateTime day) =>
      AppDate.isWeekend(day) ? weekendTargetMinutes : weekdayTargetMinutes;

  /// Weekly target = 5 weekdays + 2 weekend days.
  int get weeklyTargetMinutes =>
      (5 * weekdayTargetMinutes) + (2 * weekendTargetMinutes);

  /// Monthly target = sum of daily targets across the month of [anyDayInMonth].
  int monthlyTargetMinutes(DateTime anyDayInMonth) {
    final first = AppDate.monthStart(anyDayInMonth);
    final days = AppDate.daysInMonth(anyDayInMonth);
    var total = 0;
    for (var i = 0; i < days; i++) {
      total += targetForDay(first.add(Duration(days: i)));
    }
    return total;
  }

  /// Target across an arbitrary inclusive date range.
  int rangeTargetMinutes(DateTime from, DateTime to) {
    var total = 0;
    for (final d in AppDate.daysBetween(from, to)) {
      total += targetForDay(d);
    }
    return total;
  }
}
