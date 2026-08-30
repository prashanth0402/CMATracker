import 'package:cma_tracker/core/constants/enums.dart';
import 'package:cma_tracker/core/services/timer_service.dart';
import 'package:cma_tracker/data/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TimerService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = TimerService(db);
  });

  tearDown(() => db.close());

  test('start -> stop produces elapsed time and completed state', () async {
    await service.start(subjectId: 1);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final done = await service.stop();
    expect(done.state, TimerState.completed);
    expect(done.elapsed().inMilliseconds, greaterThan(0));
  });

  test('start -> pause -> resume -> stop accumulates only running time',
      () async {
    await service.start(subjectId: 1);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final paused = await service.pause();
    final atPause = paused.elapsed().inMilliseconds;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    // Elapsed must not advance while paused.
    expect(paused.elapsed().inMilliseconds, atPause);
    await service.resume();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final done = await service.stop();
    expect(done.elapsed().inMilliseconds, greaterThanOrEqualTo(atPause));
  });

  test('timer state survives a reload (simulated app restart)', () async {
    await service.start(subjectId: 2, topicId: 5);
    final reloaded = await TimerService(db).load();
    expect(reloaded, isNotNull);
    expect(reloaded!.state, TimerState.running);
    expect(reloaded.subjectId, 2);
    expect(reloaded.topicId, 5);
  });

  test('cannot start a second timer while one is active', () async {
    await service.start(subjectId: 1);
    expect(() => service.start(subjectId: 1), throwsA(anything));
  });

  test('clear removes the persisted timer', () async {
    await service.start(subjectId: 1);
    await service.clear();
    expect(await service.load(), isNull);
  });
}
