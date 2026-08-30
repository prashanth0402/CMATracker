import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/common.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  static const _labels = {
    'daily_target': 'Daily target completed',
    'weekly_target': 'Weekly target completed',
    'streak_7': '7-day streak',
    'mock_test': 'Mock test',
    'revision': 'Revision',
    'topic_completed': 'Topic completed',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(totalPointsProvider);
    final recent = ref.watch(recentRewardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: [
          TextButton(
            onPressed: () => context.push('/achievements'),
            child: const Text('Achievements'),
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Total points', style: context.texts.titleMedium),
                  const SizedBox(height: 8),
                  points.when(
                    data: (p) => Text('$p',
                        style: context.texts.displaySmall),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('-'),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Point values'),
          _pv(context, 'Daily target', RewardPoints.dailyTargetCompleted),
          _pv(context, 'Weekend target', RewardPoints.weekendTargetCompleted),
          _pv(context, 'Topic completed', RewardPoints.topicCompleted),
          _pv(context, 'Revision', RewardPoints.revision),
          _pv(context, 'Mock test', RewardPoints.mockTest),
          _pv(context, '7-day streak', RewardPoints.sevenDayStreak),
          _pv(context, 'Weekly target', RewardPoints.weeklyTargetCompleted),
          const SectionHeader('Recent'),
          AsyncView(
            value: recent,
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No points earned yet.'),
                  )
                : Column(
                    children: [
                      for (final r in list)
                        ListTile(
                          leading: const Icon(Icons.stars_outlined),
                          title: Text(_labels[r.type] ?? r.type),
                          subtitle: Text(AppDate.isoDay(
                              AppDate.fromIso('${r.day}T00:00:00'))),
                          trailing: Text('+${r.points}'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pv(BuildContext context, String label, int pts) => ListTile(
        dense: true,
        title: Text(label),
        trailing: Text('+$pts'),
      );
}
