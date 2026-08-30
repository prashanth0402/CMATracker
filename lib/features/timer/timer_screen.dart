import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/services/timer_service.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/common.dart';
import '../study_sessions/session_completion_screen.dart';
import '../subjects/topic_detail_screen.dart';
import 'timer_controller.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, this.preset});
  final TimerPreset? preset;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  int? _subjectId;
  int? _chapterId;
  int? _topicId;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.preset?.subjectId;
    _chapterId = widget.preset?.chapterId;
    _topicId = widget.preset?.topicId;
  }

  @override
  Widget build(BuildContext context) {
    final timerAsync = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: timerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (timer) {
          final running = timer != null && timer.state != TimerState.idle;
          final elapsed = timer?.elapsed() ?? Duration.zero;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!running) ...[
                AsyncView(
                  value: subjects,
                  data: (list) => DropdownButtonFormField<int>(
                    value: _subjectId,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: [
                      for (final s in list)
                        DropdownMenuItem(value: s.id, child: Text(s.title)),
                    ],
                    onChanged: (v) => setState(() {
                      _subjectId = v;
                      _chapterId = null;
                      _topicId = null;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                if (_subjectId != null)
                  _ChapterPicker(
                    subjectId: _subjectId!,
                    value: _chapterId,
                    onChanged: (v) => setState(() {
                      _chapterId = v;
                      _topicId = null;
                    }),
                  ),
                const SizedBox(height: 12),
                if (_chapterId != null)
                  _TopicPicker(
                    chapterId: _chapterId!,
                    value: _topicId,
                    onChanged: (v) => setState(() => _topicId = v),
                  ),
                const SizedBox(height: 24),
              ],
              if (running)
                _RunningContext(
                  subjectId: timer.subjectId,
                  chapterId: timer.chapterId,
                  topicId: timer.topicId,
                ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  AppDate.formatHms(elapsed),
                  style: context.texts.displayMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  timer?.state.name.toUpperCase() ?? 'IDLE',
                  style: context.texts.labelLarge
                      ?.copyWith(color: context.colors.primary),
                ),
              ),
              const SizedBox(height: 32),
              _controls(context, controller, timer),
            ],
          );
        },
      ),
    );
  }

  Widget _controls(
    BuildContext context,
    TimerController controller,
    PersistedTimer? timer,
  ) {
    Future<void> guard(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) context.showSnack(e.toString(), isError: true);
      }
    }

    if (timer == null || timer.state == TimerState.idle) {
      return FilledButton.icon(
        onPressed: _subjectId == null
            ? null
            : () => guard(() => controller.start(
                  subjectId: _subjectId!,
                  chapterId: _chapterId,
                  topicId: _topicId,
                  taskId: widget.preset?.taskId,
                )),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            if (timer.state == TimerState.running)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => guard(controller.pause),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              ),
            if (timer.state == TimerState.paused)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => guard(controller.resume),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => guard(() async {
                  final done = await controller.stop();
                  if (!context.mounted) return;
                  context.push('/session/complete',
                      extra: SessionCompletionArgs(
                        subjectId: done.subjectId,
                        chapterId: done.chapterId,
                        topicId: done.topicId,
                        taskId: done.taskId,
                        start: done.startedAt,
                        end: done.startedAt.add(done.elapsed()),
                      ));
                }),
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => guard(controller.discard),
          child: const Text('Discard session'),
        ),
      ],
    );
  }
}

class _ChapterPicker extends ConsumerWidget {
  const _ChapterPicker({
    required this.subjectId,
    required this.value,
    required this.onChanged,
  });
  final int subjectId;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider(subjectId));
    return chapters.maybeWhen(
      data: (list) => DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(labelText: 'Chapter (optional)'),
        items: [
          for (final c in list)
            DropdownMenuItem(value: c.id, child: Text(c.title)),
        ],
        onChanged: onChanged,
      ),
      orElse: () => const LinearProgressIndicator(),
    );
  }
}

class _TopicPicker extends ConsumerWidget {
  const _TopicPicker({
    required this.chapterId,
    required this.value,
    required this.onChanged,
  });
  final int chapterId;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsForChapterProvider(chapterId));
    return topics.maybeWhen(
      data: (list) => DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(labelText: 'Topic (optional)'),
        items: [
          for (final t in list)
            DropdownMenuItem(value: t.id, child: Text(t.title)),
        ],
        onChanged: onChanged,
      ),
      orElse: () => const LinearProgressIndicator(),
    );
  }
}

class _RunningContext extends ConsumerWidget {
  const _RunningContext({
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
  });
  final int subjectId;
  final int? chapterId;
  final int? topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(syllabusLookupProvider).valueOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lookup?.subject(subjectId) ?? 'Subject',
                style: context.texts.titleMedium),
            if (chapterId != null)
              Text(lookup?.chapter(chapterId) ?? '',
                  style: context.texts.bodyMedium),
            if (topicId != null)
              Text(lookup?.topic(topicId) ?? '',
                  style: context.texts.bodySmall),
          ],
        ),
      ),
    );
  }
}
