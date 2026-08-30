import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/providers/providers.dart';
import '../../data/database/database.dart';
import '../../shared/widgets/common.dart';

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});
  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final chapters = ref.watch(chaptersProvider(subjectId));
    final topics = ref.watch(topicsForSubjectProvider(subjectId));

    final title = subjects.valueOrNull
            ?.where((s) => s.id == subjectId)
            .firstOrNull
            ?.title ??
        'Subject';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: chapters,
        data: (chapterList) {
          final topicMap = <int, List<Topic>>{};
          for (final t in topics.valueOrNull ?? const []) {
            topicMap.putIfAbsent(t.chapterId, () => []).add(t);
          }
          if (chapterList.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No chapters',
            );
          }
          return ListView(
            children: [
              for (final c in chapterList)
                ExpansionTile(
                  title: Text(c.title),
                  subtitle: Text('${topicMap[c.id]?.length ?? 0} topics'),
                  children: [
                    for (final t in topicMap[c.id] ?? const [])
                      ListTile(
                        dense: true,
                        leading: _statusDot(context, TopicStatus.fromName(t.status)),
                        title: Text(t.title),
                        subtitle: Text(TopicStatus.fromName(t.status).label),
                        onTap: () => context.push('/topic/${t.id}'),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusDot(BuildContext context, TopicStatus status) {
    final color = switch (status) {
      TopicStatus.notStarted => Theme.of(context).colorScheme.outlineVariant,
      TopicStatus.inProgress => Colors.orange,
      TopicStatus.completed => Colors.blue,
      TopicStatus.revised => Colors.teal,
      TopicStatus.mastered => Colors.green,
    };
    return Icon(Icons.circle, size: 12, color: color);
  }
}
