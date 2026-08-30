import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/database/database.dart';
import '../constants/enums.dart';
import '../errors/app_exceptions.dart';

/// Persisted stopwatch. Elapsed time is derived from wall-clock timestamps, so
/// backgrounding, screen-lock, or a full app restart never lose or distort time.
class PersistedTimer {
  const PersistedTimer({
    required this.state,
    required this.subjectId,
    this.chapterId,
    this.topicId,
    this.taskId,
    required this.accumulatedMs,
    this.segmentStartMs,
    required this.firstStartMs,
  });

  final TimerState state;
  final int subjectId;
  final int? chapterId;
  final int? topicId;
  final int? taskId;

  /// Completed running time before the current segment.
  final int accumulatedMs;

  /// Epoch ms when the current running segment began (null when paused).
  final int? segmentStartMs;

  /// Epoch ms of the very first start (session start time).
  final int firstStartMs;

  Duration elapsed({DateTime? now}) {
    final ms = accumulatedMs +
        (state == TimerState.running && segmentStartMs != null
            ? (now ?? DateTime.now()).millisecondsSinceEpoch - segmentStartMs!
            : 0);
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  DateTime get startedAt =>
      DateTime.fromMillisecondsSinceEpoch(firstStartMs);

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'subjectId': subjectId,
        'chapterId': chapterId,
        'topicId': topicId,
        'taskId': taskId,
        'accumulatedMs': accumulatedMs,
        'segmentStartMs': segmentStartMs,
        'firstStartMs': firstStartMs,
      };

  factory PersistedTimer.fromJson(Map<String, dynamic> j) => PersistedTimer(
        state: TimerState.values
            .firstWhere((e) => e.name == j['state'], orElse: () => TimerState.idle),
        subjectId: j['subjectId'] as int,
        chapterId: j['chapterId'] as int?,
        topicId: j['topicId'] as int?,
        taskId: j['taskId'] as int?,
        accumulatedMs: j['accumulatedMs'] as int? ?? 0,
        segmentStartMs: j['segmentStartMs'] as int?,
        firstStartMs: j['firstStartMs'] as int,
      );
}

class TimerService {
  TimerService(this._db);
  final AppDatabase _db;

  static const _key = 'active_timer';

  Future<PersistedTimer?> load() async {
    final row = await (_db.select(_db.appMetadata)
          ..where((t) => t.key.equals(_key)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return PersistedTimer.fromJson(
        jsonDecode(row.value) as Map<String, dynamic>,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> _save(PersistedTimer t) async {
    await _db.into(_db.appMetadata).insertOnConflictUpdate(
          AppMetadataCompanion(
            key: const Value(_key),
            value: Value(jsonEncode(t.toJson())),
          ),
        );
  }

  Future<PersistedTimer> start({
    required int subjectId,
    int? chapterId,
    int? topicId,
    int? taskId,
  }) async {
    final existing = await load();
    if (existing != null && existing.state != TimerState.idle) {
      throw const TimerException('A study session is already in progress.');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final t = PersistedTimer(
      state: TimerState.running,
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      taskId: taskId,
      accumulatedMs: 0,
      segmentStartMs: now,
      firstStartMs: now,
    );
    await _save(t);
    return t;
  }

  Future<PersistedTimer> pause() async {
    final t = await load();
    if (t == null || t.state != TimerState.running) {
      throw const TimerException('Timer is not running.');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = PersistedTimer(
      state: TimerState.paused,
      subjectId: t.subjectId,
      chapterId: t.chapterId,
      topicId: t.topicId,
      taskId: t.taskId,
      accumulatedMs: t.accumulatedMs + (now - (t.segmentStartMs ?? now)),
      segmentStartMs: null,
      firstStartMs: t.firstStartMs,
    );
    await _save(updated);
    return updated;
  }

  Future<PersistedTimer> resume() async {
    final t = await load();
    if (t == null || t.state != TimerState.paused) {
      throw const TimerException('Timer is not paused.');
    }
    final updated = PersistedTimer(
      state: TimerState.running,
      subjectId: t.subjectId,
      chapterId: t.chapterId,
      topicId: t.topicId,
      taskId: t.taskId,
      accumulatedMs: t.accumulatedMs,
      segmentStartMs: DateTime.now().millisecondsSinceEpoch,
      firstStartMs: t.firstStartMs,
    );
    await _save(updated);
    return updated;
  }

  /// Freezes the timer and returns the final snapshot without clearing it,
  /// so the completion screen can still read the context. Call [clear] after
  /// the session is saved (or discarded).
  Future<PersistedTimer> stop() async {
    final t = await load();
    if (t == null || t.state == TimerState.idle) {
      throw const TimerException('No active timer to stop.');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final totalMs = t.accumulatedMs +
        (t.state == TimerState.running
            ? (now - (t.segmentStartMs ?? now))
            : 0);
    final done = PersistedTimer(
      state: TimerState.completed,
      subjectId: t.subjectId,
      chapterId: t.chapterId,
      topicId: t.topicId,
      taskId: t.taskId,
      accumulatedMs: totalMs,
      segmentStartMs: null,
      firstStartMs: t.firstStartMs,
    );
    await _save(done);
    return done;
  }

  Future<void> clear() async {
    await (_db.delete(_db.appMetadata)..where((t) => t.key.equals(_key))).go();
  }
}
