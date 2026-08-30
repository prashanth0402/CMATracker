import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/database.dart';
import '../../shared/widgets/common.dart';

enum _RangeMode { day, week, month, all }

class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  _RangeMode _mode = _RangeMode.week;
  String _search = '';
  int? _subjectFilter;
  ActivityType? _activityFilter;

  (DateTime, DateTime) _range(DateTime anchor) {
    return switch (_mode) {
      _RangeMode.day => (AppDate.dayStart(anchor), anchor),
      _RangeMode.week => (
          AppDate.weekStart(anchor),
          AppDate.weekStart(anchor).add(const Duration(days: 6)),
        ),
      _RangeMode.month => (
          AppDate.monthStart(anchor),
          DateTime(anchor.year, anchor.month, AppDate.daysInMonth(anchor)),
        ),
      _RangeMode.all => (DateTime(2020), DateTime(2100)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final anchor = ref.watch(selectedDateProvider);
    final (from, to) = _range(anchor);
    final sessionsAsync = ref.watch(allSessionsProvider);
    final lookup = ref.watch(syllabusLookupProvider).valueOrNull;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(from, to),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add manual session',
            onPressed: () => context.push('/session/manual'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final m in _RangeMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m.name),
                      selected: _mode == m,
                      onSelected: (_) => setState(() => _mode = m),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search description / topic',
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _subjectFilter,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final s in subjects)
                        DropdownMenuItem(value: s.id, child: Text(s.title)),
                    ],
                    onChanged: (v) => setState(() => _subjectFilter = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<ActivityType?>(
                    value: _activityFilter,
                    decoration: const InputDecoration(labelText: 'Activity'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final a in ActivityType.values)
                        DropdownMenuItem(value: a, child: Text(a.label)),
                    ],
                    onChanged: (v) => setState(() => _activityFilter = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView(
              value: sessionsAsync,
              data: (all) {
                final rows = all.where((s) {
                  final d = AppDate.fromIso(s.startTime);
                  if (d.isBefore(AppDate.dayStart(from)) ||
                      d.isAfter(AppDate.dayEnd(to))) {
                    return false;
                  }
                  if (_subjectFilter != null &&
                      s.subjectId != _subjectFilter) {
                    return false;
                  }
                  if (_activityFilter != null &&
                      s.activityType != _activityFilter!.name) {
                    return false;
                  }
                  if (_search.isNotEmpty) {
                    final hay =
                        '${s.description} ${lookup?.topic(s.topicId) ?? ''}'
                            .toLowerCase();
                    if (!hay.contains(_search)) return false;
                  }
                  return true;
                }).toList()
                  ..sort((a, b) => b.startTime.compareTo(a.startTime));

                if (rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.table_chart_outlined,
                    title: 'No sessions',
                    message: 'Adjust filters or add a manual session.',
                  );
                }
                final total =
                    rows.fold<int>(0, (a, s) => a + s.durationMinutes);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${rows.length} sessions · ${AppDate.formatMinutes(total)}',
                        style: context.texts.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (_, i) => _SessionTile(
                          session: rows[i],
                          lookup: lookup,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(DateTime from, DateTime to) async {
    try {
      final repo = ref.read(studySessionRepositoryProvider);
      final sessions = _mode == _RangeMode.all
          ? await repo.all()
          : await repo.inRange(from, to);
      final csv = ref.read(csvServiceProvider);
      final name = _mode == _RangeMode.month
          ? '' // handled below
          : 'CMA_Timesheet_${AppDate.isoDay(from)}_to_${AppDate.isoDay(to)}.csv';
      final fileName = name.isEmpty
          ? 'CMA_Timesheet_${from.year}_${from.month.toString().padLeft(2, '0')}.csv'
          : name;
      final path = await csv.exportSessions(sessions, fileName: fileName);
      if (mounted) {
        await Share.shareXFiles([XFile(path)], text: 'CMA timesheet export');
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    }
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session, required this.lookup});
  final StudySession session;
  final SyllabusLookup? lookup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = AppDate.fromIso(session.startTime);
    final end = AppDate.fromIso(session.endTime);
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.colors.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete),
      ),
      confirmDismiss: (_) => confirmDialog(
        context,
        title: 'Delete session?',
        message: 'Progress will be recalculated.',
        confirmLabel: 'Delete',
        destructive: true,
      ),
      onDismissed: (_) => ref
          .read(studySessionRepositoryProvider)
          .delete(session.id)
          .then((_) => ref.invalidate(allSessionsProvider)),
      child: ListTile(
        title: Text(
          '${lookup?.subject(session.subjectId) ?? ''} · '
          '${ActivityType.fromName(session.activityType).label}',
        ),
        subtitle: Text(
          '${AppDate.isoDay(start)}  ${AppDate.time(start)}–${AppDate.time(end)} · '
          '${AppDate.formatMinutes(session.durationMinutes)}\n'
          '${session.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        onTap: () => context.push('/session/edit', extra: session),
      ),
    );
  }
}
