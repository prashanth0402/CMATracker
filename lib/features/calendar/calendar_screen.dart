import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/progress_models.dart';
import '../../shared/widgets/common.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedDateProvider);
    final stats = ref.watch(monthDayStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppDate.monthLabel(month)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedDateProvider.notifier).state =
                DateTime(month.year, month.month - 1, 1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedDateProvider.notifier).state =
                DateTime(month.year, month.month + 1, 1),
          ),
        ],
      ),
      body: AsyncView(
        value: stats,
        data: (days) {
          final firstWeekday = DateTime(month.year, month.month, 1).weekday;
          final leading = firstWeekday - 1; // Monday-first grid
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const _Legend(),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: leading + days.length,
                itemBuilder: (_, i) {
                  if (i < leading) return const SizedBox.shrink();
                  final stat = days[i - leading];
                  return _DayCell(
                    stat: stat,
                    onTap: () => _showDay(context, ref, stat),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDay(BuildContext context, WidgetRef ref, DayStat stat) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _DaySheet(day: stat.day),
    );
  }
}

DayCompletionLevel _level(DayStat s) {
  if (s.actualMinutes == 0) return DayCompletionLevel.none;
  if (s.actualMinutes < s.targetMinutes) return DayCompletionLevel.partial;
  if (s.actualMinutes < s.targetMinutes * 1.25) {
    return DayCompletionLevel.target;
  }
  return DayCompletionLevel.above;
}

enum DayCompletionLevel { none, partial, target, above }

Color _colorFor(BuildContext context, DayCompletionLevel l) => switch (l) {
      DayCompletionLevel.none => context.colors.surfaceContainerHighest,
      DayCompletionLevel.partial => Colors.orange.withValues(alpha: 0.5),
      DayCompletionLevel.target => Colors.green.withValues(alpha: 0.55),
      DayCompletionLevel.above => Colors.green,
    };

class _DayCell extends StatelessWidget {
  const _DayCell({required this.stat, required this.onTap});
  final DayStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: _colorFor(context, _level(stat)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(AppDate.dayNumber(stat.day)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, DayCompletionLevel l) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: _colorFor(context, l)),
            const SizedBox(width: 4),
            Text(label, style: context.texts.bodySmall),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        chip('0%', DayCompletionLevel.none),
        chip('Partial', DayCompletionLevel.partial),
        chip('Target', DayCompletionLevel.target),
        chip('Above', DayCompletionLevel.above),
      ],
    );
  }
}

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);
    final lookup = ref.watch(syllabusLookupProvider).valueOrNull;
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (all) {
          final rows = all
              .where((s) => AppDate.isSameDay(AppDate.fromIso(s.startTime), day))
              .toList();
          final total = rows.fold<int>(0, (a, s) => a + s.durationMinutes);
          final target = settings?.targetCalculator.targetForDay(day) ?? 0;
          final subjectsStudied = rows
              .map((s) => lookup?.subject(s.subjectId) ?? '')
              .where((e) => e.isNotEmpty)
              .toSet();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppDate.displayDate(day), style: context.texts.titleMedium),
              const SizedBox(height: 8),
              Text('Total: ${AppDate.formatMinutes(total)} / '
                  'Target ${AppDate.formatMinutes(target)}'),
              Text('Sessions: ${rows.length}'),
              Text('Subjects: ${subjectsStudied.join(", ")}'),
              const Divider(),
              for (final s in rows)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(lookup?.topic(s.topicId) ??
                      lookup?.subject(s.subjectId) ??
                      ''),
                  subtitle: Text(s.description),
                  trailing: Text(AppDate.formatMinutes(s.durationMinutes)),
                ),
            ],
          );
        },
      ),
    );
  }
}
