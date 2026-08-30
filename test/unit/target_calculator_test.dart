import 'package:cma_tracker/core/constants/app_constants.dart';
import 'package:cma_tracker/core/utils/target_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = TargetCalculator(
    weekdayTargetMinutes: AppConstants.defaultWeekdayTargetMinutes,
    weekendTargetMinutes: AppConstants.defaultWeekendTargetMinutes,
  );

  test('weekday target is 3 hours', () {
    // 2026-08-31 is a Monday.
    expect(calc.targetForDay(DateTime(2026, 8, 31)), 180);
  });

  test('weekend target is 6 hours', () {
    // 2026-08-29 Saturday, 2026-08-30 Sunday.
    expect(calc.targetForDay(DateTime(2026, 8, 29)), 360);
    expect(calc.targetForDay(DateTime(2026, 8, 30)), 360);
  });

  test('weekly target is 27 hours by default', () {
    expect(calc.weeklyTargetMinutes, 1620);
    expect(calc.weeklyTargetMinutes, AppConstants.defaultWeeklyTargetMinutes);
  });

  test('monthly target sums daily targets (Aug 2026 = 31 days)', () {
    // August 2026: 21 weekdays, 10 weekend days.
    final expected = 21 * 180 + 10 * 360;
    expect(calc.monthlyTargetMinutes(DateTime(2026, 8, 15)), expected);
  });

  test('custom targets propagate to weekly total', () {
    const custom = TargetCalculator(
      weekdayTargetMinutes: 120,
      weekendTargetMinutes: 300,
    );
    expect(custom.weeklyTargetMinutes, 5 * 120 + 2 * 300);
  });
}
