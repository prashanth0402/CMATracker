import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/database.dart';
import '../../shared/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final daily = ref.watch(dailyProgressProvider);
    final weekly = ref.watch(weeklyProgressProvider);
    final streak = ref.watch(streakProvider);
    final tasks = ref.watch(tasksForSelectedDayProvider);
    final subjectProgress = ref.watch(subjectProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CMA Tracker'),
        actions: [
          IconButton(
            tooltip: 'Calendar',
            onPressed: () => context.push('/calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allSessionsProvider);
          ref.invalidate(dailyProgressProvider);
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                AppDate.displayDate(today),
                style: context.texts.titleMedium,
              ),
            ),
            AsyncView(
              value: daily,
              data: (p) => Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        ProgressRing(
                          fraction: p.fraction,
                          centerLabel: '${p.percent}%',
                          subLabel: 'of target',
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv(context, "Today's target", p.targetLabel),
                              _kv(context, 'Completed', p.actualLabel),
                              _kv(context, 'Remaining', p.remainingLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: streak.when(
                      data: (s) => StatCard(
                        label: 'Current streak',
                        value: '${s.current} d',
                        sublabel: 'Longest ${s.longest} d',
                        icon: Icons.local_fire_department,
                      ),
                      loading: () => const StatCard(
                          label: 'Current streak', value: '…'),
                      error: (_, __) => const StatCard(
                          label: 'Current streak', value: '-'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: weekly.when(
                      data: (w) => StatCard(
                        label: 'This week',
                        value: w.actualLabel,
                        sublabel: '${w.percent}% of ${w.targetLabel}',
                        icon: Icons.calendar_view_week,
                      ),
                      loading: () =>
                          const StatCard(label: 'This week', value: '…'),
                      error: (_, __) =>
                          const StatCard(label: 'This week', value: '-'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: () => context.go('/timer'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue studying'),
              ),
            ),
            SectionHeader(
              "Today's tasks",
              trailing: TextButton(
                onPressed: () => context.push('/task/edit'),
                child: const Text('Add'),
              ),
            ),
            AsyncView(
              value: tasks,
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No tasks planned for today.'),
                    )
                  : Column(
                      children: [
                        for (final t in list)
                          _TaskTile(task: t),
                      ],
                    ),
            ),
            const SectionHeader('Subject summary'),
            AsyncView(
              value: subjectProgress,
              data: (list) => Column(
                children: [
                  for (final sp in list)
                    ListTile(
                      title: Text(sp.subjectTitle),
                      subtitle: Text(
                        '${sp.completedTopics}/${sp.totalTopics} topics · '
                        '${AppDate.formatMinutes(sp.studyMinutes + sp.practiceMinutes)}',
                      ),
                      trailing: Text(
                        '${(sp.completionFraction * 100).round()}%',
                        style: context.texts.labelLarge,
                      ),
                      onTap: () => context.push('/subjects/${sp.subjectId}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: context.texts.bodyMedium),
            Text(v, style: context.texts.titleSmall),
          ],
        ),
      );
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final StudyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: task.isCompleted,
      onChanged: (v) => ref
          .read(studyTaskRepositoryProvider)
          .setCompleted(task.id, v ?? false),
      title: Text(
        task.title,
        style: task.isCompleted
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: task.plannedMinutes > 0
          ? Text('Planned ${AppDate.formatMinutes(task.plannedMinutes)}')
          : null,
      secondary: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => context.push('/task/edit', extra: task),
      ),
    );
  }
}
