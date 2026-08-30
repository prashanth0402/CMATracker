import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/providers/providers.dart';
import '../../core/services/timer_service.dart';

/// Exposes the persisted active timer and ticks once a second while running so
/// the UI can redraw the elapsed clock. Elapsed time itself always comes from
/// wall-clock timestamps in [PersistedTimer], never from a counter.
class TimerController extends AsyncNotifier<PersistedTimer?> {
  Timer? _ticker;

  @override
  Future<PersistedTimer?> build() async {
    ref.onDispose(() => _ticker?.cancel());
    final timer = await ref.watch(timerServiceProvider).load();
    _syncTicker(timer);
    return timer;
  }

  TimerService get _service => ref.read(timerServiceProvider);

  void _syncTicker(PersistedTimer? t) {
    _ticker?.cancel();
    if (t?.state == TimerState.running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        // Force listeners to rebuild; value is unchanged but elapsed() moves.
        state = AsyncData(state.valueOrNull);
      });
    }
  }

  Future<void> start({
    required int subjectId,
    int? chapterId,
    int? topicId,
    int? taskId,
  }) async {
    final t = await _service.start(
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      taskId: taskId,
    );
    _syncTicker(t);
    state = AsyncData(t);
  }

  Future<void> pause() async {
    final t = await _service.pause();
    _syncTicker(t);
    state = AsyncData(t);
  }

  Future<void> resume() async {
    final t = await _service.resume();
    _syncTicker(t);
    state = AsyncData(t);
  }

  Future<PersistedTimer> stop() async {
    final t = await _service.stop();
    _syncTicker(t);
    state = AsyncData(t);
    return t;
  }

  Future<void> discard() async {
    await _service.clear();
    _syncTicker(null);
    state = const AsyncData(null);
  }
}

final timerControllerProvider =
    AsyncNotifierProvider<TimerController, PersistedTimer?>(
  TimerController.new,
);
