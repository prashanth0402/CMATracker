import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/progress_models.dart';
import '../../shared/widgets/common.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyProgressProvider);
    final weekly = ref.watch(weeklyProgressProvider);
    final monthly = ref.watch(monthlyProgressProvider);
    final subjects = ref.watch(subjectProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          TextButton(
            onPressed: () => context.push('/reports/weekly'),
            child: const Text('Weekly'),
          ),
          TextButton(
            onPressed: () => context.push('/reports/monthly'),
            child: const Text('Monthly'),
          ),
        ],
      ),
      body: ListView(
        children: [
          _periodCard(context, 'Today', daily),
          _periodCard(context, 'This week', weekly),
          _periodCard(context, 'This month', monthly),
          const SectionHeader('Subject-wise'),
          AsyncView(
            value: subjects,
            data: (list) => Column(
              children: [
                for (final sp in list) _SubjectRow(sp: sp),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _periodCard(
    BuildContext context,
    String title,
    AsyncValue<PeriodProgress> value,
  ) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: value.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.titleMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: p.fraction),
              const SizedBox(height: 8),
              Text(
                'Actual ${p.actualLabel} / Target ${p.targetLabel} · '
                '${p.percent}% · Remaining ${p.remainingLabel}',
                style: context.texts.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.sp});
  final SubjectProgress sp;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(sp.subjectTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(value: sp.completionFraction),
          const SizedBox(height: 4),
          Text(
            '${sp.completedTopics}/${sp.totalTopics} topics · '
            'Revised ${sp.revisedTopics} · '
            'Study ${AppDate.formatMinutes(sp.studyMinutes)} · '
            'Practice ${AppDate.formatMinutes(sp.practiceMinutes)} · '
            'Q ${sp.questionsSolved}',
          ),
        ],
      ),
      onTap: () => context.push('/subjects/${sp.subjectId}'),
    );
  }
}
