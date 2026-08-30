import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/common.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(weeklyReportProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: AsyncView(
        value: report,
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Week ${r.weekNumber}', style: context.texts.headlineSmall),
            Text(
              '${AppDate.isoDay(r.weekStart)} – ${AppDate.isoDay(r.weekEnd)}',
              style: context.texts.bodySmall,
            ),
            const SizedBox(height: 16),
            _row(context, 'Target', AppDate.formatMinutes(r.targetMinutes)),
            _row(context, 'Actual', AppDate.formatMinutes(r.actualMinutes)),
            _row(context, 'Achievement', '${r.achievementPercent}%'),
            _row(context, 'Study days', '${r.studyDays}'),
            _row(context, 'Topics completed', '${r.topicsCompleted}'),
            _row(context, 'Questions solved', '${r.questionsSolved}'),
            _row(context, 'Current streak', '${r.currentStreak} days'),
            _row(context, 'Top subject', r.topSubject),
            const Divider(height: 32),
            _row(context, 'Weekly reward points', '${r.rewardPoints}'),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: context.texts.bodyLarge),
            Text(v, style: context.texts.titleMedium),
          ],
        ),
      );
}
