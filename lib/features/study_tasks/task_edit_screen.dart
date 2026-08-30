import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/database.dart';
import '../../shared/widgets/common.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  const TaskEditScreen({super.key, this.existing});
  final StudyTask? existing;

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '45');
  int? _subjectId;
  int? _chapterId;
  int? _topicId;
  DateTime _day = AppDate.dayStart(DateTime.now());
  TaskPriority _priority = TaskPriority.medium;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _notesCtrl.text = e.notes;
      _minutesCtrl.text = e.plannedMinutes.toString();
      _subjectId = e.subjectId;
      _chapterId = e.chapterId;
      _topicId = e.topicId;
      _day = AppDate.fromIso('${e.day}T00:00:00');
      _priority = TaskPriority.fromName(e.priority);
    } else {
      _day = ref.read(selectedDateProvider);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_subjectId == null || _titleCtrl.text.trim().isEmpty) {
      context.showSnack('Subject and title are required', isError: true);
      return;
    }
    final repo = ref.read(studyTaskRepositoryProvider);
    final minutes = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
    try {
      if (_isEdit) {
        await repo.updateTask(
          widget.existing!.id,
          StudyTasksCompanion(
            subjectId: Value(_subjectId!),
            chapterId: Value(_chapterId),
            topicId: Value(_topicId),
            title: Value(_titleCtrl.text.trim()),
            day: Value(AppDate.isoDay(_day)),
            plannedMinutes: Value(minutes),
            priority: Value(_priority.name),
            notes: Value(_notesCtrl.text.trim()),
          ),
        );
      } else {
        await repo.create(
          subjectId: _subjectId!,
          chapterId: _chapterId,
          topicId: _topicId,
          title: _titleCtrl.text.trim(),
          day: _day,
          plannedMinutes: minutes,
          priority: _priority,
          notes: _notesCtrl.text.trim(),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Duplicate',
              onPressed: () async {
                await ref
                    .read(studyTaskRepositoryProvider)
                    .duplicate(widget.existing!.id);
                if (context.mounted) context.pop();
              },
            ),
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDialog(context,
                    title: 'Delete task?',
                    message: 'This cannot be undone.',
                    confirmLabel: 'Delete',
                    destructive: true);
                if (!ok) return;
                await ref
                    .read(studyTaskRepositoryProvider)
                    .delete(widget.existing!.id);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          AsyncView(
            value: subjects,
            data: (list) => DropdownButtonFormField<int>(
              value: _subjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                for (final s in list)
                  DropdownMenuItem(value: s.id, child: Text(s.title)),
              ],
              onChanged: (v) => setState(() {
                _subjectId = v;
                _chapterId = null;
                _topicId = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (_subjectId != null)
            Consumer(
              builder: (context, r, _) =>
                  r.watch(chaptersProvider(_subjectId!)).maybeWhen(
                        data: (list) => DropdownButtonFormField<int>(
                          value: _chapterId,
                          decoration: const InputDecoration(
                              labelText: 'Chapter (optional)'),
                          items: [
                            for (final c in list)
                              DropdownMenuItem(
                                  value: c.id, child: Text(c.title)),
                          ],
                          onChanged: (v) => setState(() {
                            _chapterId = v;
                            _topicId = null;
                          }),
                        ),
                        orElse: () => const LinearProgressIndicator(),
                      ),
            ),
          const SizedBox(height: 12),
          if (_chapterId != null)
            Consumer(
              builder: (context, r, _) =>
                  r.watch(topicsForChapterProvider(_chapterId!)).maybeWhen(
                        data: (list) => DropdownButtonFormField<int>(
                          value: _topicId,
                          decoration: const InputDecoration(
                              labelText: 'Topic (optional)'),
                          items: [
                            for (final t in list)
                              DropdownMenuItem(
                                  value: t.id, child: Text(t.title)),
                          ],
                          onChanged: (v) => setState(() => _topicId = v),
                        ),
                        orElse: () => const LinearProgressIndicator(),
                      ),
            ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            trailing: Text(AppDate.displayDate(_day)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _day = picked);
            },
          ),
          TextField(
            controller: _minutesCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Planned duration (minutes)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: [
              for (final p in TaskPriority.values)
                DropdownMenuItem(value: p, child: Text(p.label)),
            ],
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? 'Save changes' : 'Create task'),
          ),
        ],
      ),
    );
  }
}
