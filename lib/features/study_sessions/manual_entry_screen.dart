import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/database/database.dart';
import '../../data/repositories/study_session_repository.dart';
import '../../shared/widgets/common.dart';
import 'session_actions.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key, this.existing});
  final StudySession? existing;

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  int? _subjectId;
  int? _chapterId;
  int? _topicId;
  ActivityType _activity = ActivityType.studied;
  Difficulty _difficulty = Difficulty.medium;
  int _understanding = 3;
  final _descriptionCtrl = TextEditingController();
  final _questionsCtrl = TextEditingController(text: '0');
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      final s = AppDate.fromIso(e.startTime);
      final en = AppDate.fromIso(e.endTime);
      _date = AppDate.dayStart(s);
      _start = TimeOfDay.fromDateTime(s);
      _end = TimeOfDay.fromDateTime(en);
      _subjectId = e.subjectId;
      _chapterId = e.chapterId;
      _topicId = e.topicId;
      _activity = ActivityType.fromName(e.activityType);
      _difficulty = Difficulty.fromName(e.difficulty);
      _understanding = e.understanding;
      _descriptionCtrl.text = e.description;
      _questionsCtrl.text = e.questionsSolved.toString();
    } else {
      final now = DateTime.now();
      _date = AppDate.dayStart(now);
      _start = TimeOfDay(hour: now.hour, minute: 0);
      _end = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _questionsCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDt => DateTime(
      _date.year, _date.month, _date.day, _start.hour, _start.minute);

  DateTime get _endDt {
    var e = DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);
    // Session crossing midnight – roll end into the next day.
    if (!e.isAfter(_startDt)) e = e.add(const Duration(days: 1));
    return e;
  }

  Future<void> _save() async {
    if (_subjectId == null) {
      context.showSnack('Pick a subject', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final input = SessionInput(
        subjectId: _subjectId!,
        chapterId: _chapterId,
        topicId: _topicId,
        start: _startDt,
        end: _endDt,
        activityType: _activity,
        description: _descriptionCtrl.text,
        difficulty: _difficulty,
        understanding: _understanding,
        questionsSolved: int.tryParse(_questionsCtrl.text.trim()) ?? 0,
      );
      final actions = ref.read(sessionActionsProvider);
      if (_isEdit) {
        await actions.update(widget.existing!.id, input);
      } else {
        await actions.create(input);
      }
      if (mounted) {
        context.showSnack(_isEdit ? 'Session updated' : 'Session added');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final mins = _endDt.difference(_startDt).inMinutes;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Session' : 'Add Manual Session'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Delete session?',
                  message: 'Progress will be recalculated.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!ok) return;
                await ref
                    .read(sessionActionsProvider)
                    .delete(widget.existing!.id);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            trailing: Text(AppDate.displayDate(_date)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start'),
                  trailing: Text(_start.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _start);
                    if (t != null) setState(() => _start = t);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End'),
                  trailing: Text(_end.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _end);
                    if (t != null) setState(() => _end = t);
                  },
                ),
              ),
            ],
          ),
          Text('Duration: ${AppDate.formatMinutes(mins)}',
              style: context.texts.bodyMedium),
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
              builder: (context, r, _) => r
                  .watch(chaptersProvider(_subjectId!))
                  .maybeWhen(
                    data: (list) => DropdownButtonFormField<int>(
                      value: _chapterId,
                      decoration: const InputDecoration(
                          labelText: 'Chapter (optional)'),
                      items: [
                        for (final c in list)
                          DropdownMenuItem(value: c.id, child: Text(c.title)),
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
              builder: (context, r, _) => r
                  .watch(topicsForChapterProvider(_chapterId!))
                  .maybeWhen(
                    data: (list) => DropdownButtonFormField<int>(
                      value: _topicId,
                      decoration: const InputDecoration(
                          labelText: 'Topic (optional)'),
                      items: [
                        for (final t in list)
                          DropdownMenuItem(value: t.id, child: Text(t.title)),
                      ],
                      onChanged: (v) => setState(() => _topicId = v),
                    ),
                    orElse: () => const LinearProgressIndicator(),
                  ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ActivityType>(
            value: _activity,
            decoration: const InputDecoration(labelText: 'Activity'),
            items: [
              for (final a in ActivityType.values)
                DropdownMenuItem(value: a, child: Text(a.label)),
            ],
            onChanged: (v) => setState(() => _activity = v ?? _activity),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<Difficulty>(
            segments: const [
              ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
              ButtonSegment(value: Difficulty.medium, label: Text('Medium')),
              ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 12),
          Text('Understanding: $_understanding / 5'),
          Slider(
            value: _understanding.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _understanding = v.round()),
          ),
          TextField(
            controller: _questionsCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Questions solved (optional)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEdit ? 'Save changes' : 'Add session'),
          ),
        ],
      ),
    );
  }
}

