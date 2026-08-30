import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/services/csv_service.dart';
import '../../core/utils/date_utils.dart';
import '../../shared/widgets/common.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedDateProvider);
    final monthly = ref.watch(monthlyProgressProvider);
    final subjectProgress = ref.watch(subjectProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly · ${AppDate.monthLabel(month)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export month CSV',
            onPressed: () async {
              try {
                final from = AppDate.monthStart(month);
                final to = DateTime(month.year, month.month,
                    AppDate.daysInMonth(month));
                final sessions = await ref
                    .read(studySessionRepositoryProvider)
                    .inRange(from, to);
                final path = await ref.read(csvServiceProvider).exportSessions(
                      sessions,
                      fileName: CsvService.monthlyFileName(month),
                    );
                await Share.shareXFiles([XFile(path)]);
              } catch (e) {
                if (context.mounted) {
                  context.showSnack(e.toString(), isError: true);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncView(
            value: monthly,
            data: (p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target ${p.targetLabel}'),
                    Text('Actual ${p.actualLabel}'),
                    Text('Achievement ${p.percent}%'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: p.fraction),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader('Subject-wise'),
          AsyncView(
            value: subjectProgress,
            data: (list) => Column(
              children: [
                for (final sp in list)
                  ListTile(
                    title: Text(sp.subjectTitle),
                    subtitle: Text(
                      'Study ${AppDate.formatMinutes(sp.studyMinutes)} · '
                      'Practice ${AppDate.formatMinutes(sp.practiceMinutes)} · '
                      'Topics ${sp.completedTopics}/${sp.totalTopics} · '
                      'Q ${sp.questionsSolved}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
