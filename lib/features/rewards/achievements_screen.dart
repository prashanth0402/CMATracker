import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/common.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: AsyncView(
        value: achievements,
        data: (list) => ListView(
          children: [
            for (final a in list)
              ListTile(
                leading: Icon(
                  a.unlockedAt != null
                      ? Icons.emoji_events
                      : Icons.lock_outline,
                  color: a.unlockedAt != null
                      ? Colors.amber
                      : context.colors.outline,
                ),
                title: Text(a.title),
                subtitle: Text(a.description),
                trailing: a.unlockedAt != null
                    ? Text(AppDate.isoDay(AppDate.fromIso(a.unlockedAt!)))
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
