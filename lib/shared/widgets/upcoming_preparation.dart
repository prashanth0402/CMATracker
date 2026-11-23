import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/database.dart';
import 'common.dart';

/// "Upcoming preparation": the next planned (not yet completed) study tasks
/// after today, soonest first.
class UpcomingPreparationSection extends ConsumerWidget {
  const UpcomingPreparationSection({super.key, this.maxItems = 5});
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingTasksProvider);
    final lookup = ref.watch(syllabusLookupProvider).valueOrNull;
    final todayIso = AppDate.isoDay(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Upcoming preparation',
          trailing: TextButton(
            onPressed: () => context.push('/task/edit'),
            child: const Text('Plan'),
          ),
        ),
        upcoming.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Could not load upcoming tasks.'),
          ),
          data: (all) {
            // Today's tasks already appear under "Today's tasks".
            final list =
                all.where((t) => t.day.compareTo(todayIso) > 0).toList();
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Nothing planned ahead. Tap Plan to add a task.'),
              );
            }
            final shown = list.take(maxItems).toList();
            return Column(
              children: [
                for (final t in shown)
                  _UpcomingTile(
                    task: t,
                    subject: lookup?.subject(t.subjectId) ?? '',
                  ),
                if (list.length > shown.length)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${list.length - shown.length} more planned',
                        style: context.texts.bodySmall,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.task, required this.subject});
  final StudyTask task;
  final String subject;

  static String _when(DateTime day) {
    final diff = AppDate.dayStart(day)
        .difference(AppDate.dayStart(DateTime.now()))
        .inDays;
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    return AppDate.displayDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final day = DateTime.parse(task.day);
    final details = [
      _when(day),
      if (subject.isNotEmpty) subject,
      if (task.plannedMinutes > 0) AppDate.formatMinutes(task.plannedMinutes),
    ].join(' · ');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        child: Text('${day.day}'),
      ),
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/task/edit', extra: task),
    );
  }
}
