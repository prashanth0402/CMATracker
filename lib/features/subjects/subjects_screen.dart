import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/common.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key, this.embedded = false});

  /// When true this is the "Study" bottom-nav tab (no back button).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final progress = ref.watch(subjectProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        automaticallyImplyLeading: !embedded,
      ),
      body: AsyncView(
        value: subjects,
        data: (list) => ListView(
          children: [
            for (final s in list)
              Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ListTile(
                  leading: CircleAvatar(child: Text('P${s.paperNumber}')),
                  title: Text(s.title),
                  subtitle: progress.whenOrNull(
                    data: (all) {
                      final sp = all.where((e) => e.subjectId == s.id).firstOrNull;
                      if (sp == null) return null;
                      return Text(
                        '${sp.completedTopics}/${sp.totalTopics} topics · '
                        '${AppDate.formatMinutes(sp.studyMinutes + sp.practiceMinutes)}',
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/subjects/${s.id}'),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Paper 5–8 · CMA Intermediate Group 1',
                style: context.texts.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
