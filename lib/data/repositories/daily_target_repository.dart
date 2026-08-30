import 'package:drift/drift.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/target_calculator.dart';
import '../database/database.dart';

/// Per-day target overrides. When no override exists the settings-derived
/// target from [TargetCalculator] is authoritative.
class DailyTargetRepository {
  DailyTargetRepository(this._db);
  final AppDatabase _db;

  Future<int> targetFor(DateTime day, TargetCalculator calc) async {
    final iso = AppDate.isoDay(day);
    final row = await (_db.select(_db.dailyTargets)
          ..where((t) => t.day.equals(iso)))
        .getSingleOrNull();
    return row?.targetMinutes ?? calc.targetForDay(day);
  }

  Future<Map<String, int>> overridesInRange(DateTime from, DateTime to) async {
    final f = AppDate.isoDay(from);
    final t = AppDate.isoDay(to);
    final rows = await (_db.select(_db.dailyTargets)
          ..where((r) => r.day.isBetweenValues(f, t)))
        .get();
    return {for (final r in rows) r.day: r.targetMinutes};
  }

  Future<void> setOverride(DateTime day, int minutes) async {
    if (minutes < 0) {
      throw const ValidationException('Target cannot be negative.');
    }
    await _db.into(_db.dailyTargets).insertOnConflictUpdate(
          DailyTargetsCompanion(
            day: Value(AppDate.isoDay(day)),
            targetMinutes: Value(minutes),
          ),
        );
  }

  Future<void> clearOverride(DateTime day) async {
    await (_db.delete(_db.dailyTargets)
          ..where((t) => t.day.equals(AppDate.isoDay(day))))
        .go();
  }
}
