import 'package:drift/drift.dart';

import '../../core/utils/date_utils.dart';
import '../database/database.dart';

/// Append-only points ledger. Awards are keyed by (type, day) so the same
/// milestone can never be counted twice.
class RewardRepository {
  RewardRepository(this._db);
  final AppDatabase _db;

  Future<bool> _exists(String type, String day) async {
    final row = await (_db.select(_db.rewards)
          ..where((r) => r.type.equals(type) & r.day.equals(day))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Records an award unless an identical (type, day) award already exists.
  /// Returns the points actually added (0 if it was a duplicate).
  Future<int> awardOnce({
    required String type,
    required DateTime day,
    required int points,
    String? meta,
  }) async {
    final iso = AppDate.isoDay(day);
    if (await _exists(type, iso)) return 0;
    await _db.into(_db.rewards).insert(
          RewardsCompanion.insert(
            type: type,
            points: points,
            day: iso,
            meta: Value(meta),
            createdAt: AppDate.toIso(DateTime.now()),
          ),
        );
    return points;
  }

  /// Award tied to a specific entity (e.g. a session or topic id) so it is
  /// counted exactly once regardless of day.
  Future<int> awardPerEntity({
    required String type,
    required DateTime day,
    required int points,
    required String entityKey,
  }) async {
    final match = await (_db.select(_db.rewards)
          ..where((r) => r.type.equals(type) & r.meta.equals(entityKey))
          ..limit(1))
        .getSingleOrNull();
    if (match != null) return 0;
    await _db.into(_db.rewards).insert(
          RewardsCompanion.insert(
            type: type,
            points: points,
            day: AppDate.isoDay(day),
            meta: Value(entityKey),
            createdAt: AppDate.toIso(DateTime.now()),
          ),
        );
    return points;
  }

  Future<int> totalPoints() async {
    final rows = await _db.select(_db.rewards).get();
    return rows.fold<int>(0, (a, r) => a + r.points);
  }

  Stream<int> watchTotalPoints() {
    return _db.select(_db.rewards).watch().map(
          (rows) => rows.fold<int>(0, (a, r) => a + r.points),
        );
  }

  Future<int> pointsInRange(DateTime from, DateTime to) async {
    final f = AppDate.isoDay(from);
    final t = AppDate.isoDay(to);
    final rows = await (_db.select(_db.rewards)
          ..where((r) => r.day.isBetweenValues(f, t)))
        .get();
    return rows.fold<int>(0, (a, r) => a + r.points);
  }

  Stream<List<Reward>> watchRecent({int limit = 50}) {
    return (_db.select(_db.rewards)
          ..orderBy([
            (r) => OrderingTerm(
                  expression: r.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .watch();
  }

  Future<void> clearAll() => _db.delete(_db.rewards).go();
}
