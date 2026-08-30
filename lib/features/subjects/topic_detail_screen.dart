import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/database.dart';
import '../../shared/widgets/common.dart';

final _topicProvider = FutureProvider.family<Topic, int>(
    (ref, id) => ref.watch(topicRepositoryProvider).byId(id));

final _topicSessionsProvider = FutureProvider.family<List<StudySession>, int>(
    (ref, id) async {
  ref.watch(allSessionsProvider);
  final all = await ref.watch(studySessionRepositoryProvider).all();
  return all.where((s) => s.topicId == id).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
});

class TopicDetailScreen extends ConsumerWidget {
  const TopicDetailScreen({super.key, required this.topicId});
  final int topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = ref.watch(_topicProvider(topicId));
    final sessions = ref.watch(_topicSessionsProvider(topicId));

    return Scaffold(
      appBar: AppBar(title: const Text('Topic')),
      floatingActionButton: topic.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go(
                '/timer',
                extra: TimerPreset(
                  subjectId: topic.value!.subjectId,
                  chapterId: topic.value!.chapterId,
                  topicId: topic.value!.id,
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Study'),
            ),
      body: AsyncView(
        value: topic,
        data: (t) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t.title, style: context.texts.headlineSmall),
            const SizedBox(height: 16),
            Text('Status', style: context.texts.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final s in TopicStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: TopicStatus.fromName(t.status) == s,
                    onSelected: (_) => ref
                        .read(topicRepositoryProvider)
                        .setStatus(t.id, s)
                        .then((_) {
                      ref.invalidate(_topicProvider(topicId));
                      ref.invalidate(subjectProgressProvider);
                    }),
                  ),
              ],
            ),
            const Divider(height: 32),
            Text('Sessions', style: context.texts.titleMedium),
            const SizedBox(height: 8),
            ...switch (sessions) {
              AsyncData(:final value) when value.isEmpty => [
                  const Text('No sessions recorded for this topic yet.'),
                ],
              AsyncData(:final value) => [
                  for (final s in value)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${AppDate.isoDay(AppDate.fromIso(s.startTime))} · '
                        '${AppDate.formatMinutes(s.durationMinutes)}',
                      ),
                      subtitle: Text(
                        s.description.isEmpty ? s.activityType : s.description,
                      ),
                    ),
                ],
              _ => [const Center(child: CircularProgressIndicator())],
            },
          ],
        ),
      ),
    );
  }
}

/// Passed to the timer screen to pre-select subject/chapter/topic.
class TimerPreset {
  const TimerPreset({
    required this.subjectId,
    this.chapterId,
    this.topicId,
    this.taskId,
  });
  final int subjectId;
  final int? chapterId;
  final int? topicId;
  final int? taskId;
}
