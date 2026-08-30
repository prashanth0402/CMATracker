import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/study_session_repository.dart';
import '../timer/timer_controller.dart';
import 'description_templates.dart';
import 'session_actions.dart';

class SessionCompletionArgs {
  const SessionCompletionArgs({
    required this.subjectId,
    this.chapterId,
    this.topicId,
    this.taskId,
    required this.start,
    required this.end,
  });
  final int subjectId;
  final int? chapterId;
  final int? topicId;
  final int? taskId;
  final DateTime start;
  final DateTime end;
}

class SessionCompletionScreen extends ConsumerStatefulWidget {
  const SessionCompletionScreen({super.key, required this.args});
  final SessionCompletionArgs args;

  @override
  ConsumerState<SessionCompletionScreen> createState() =>
      _SessionCompletionScreenState();
}

class _SessionCompletionScreenState
    extends ConsumerState<SessionCompletionScreen> {
  ActivityType _activity = ActivityType.studied;
  Difficulty _difficulty = Difficulty.medium;
  int _understanding = 3;
  final _descriptionCtrl = TextEditingController();
  final _questionsCtrl = TextEditingController(text: '0');
  bool _descriptionEditedByUser = false;
  bool _saving = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _questionsCtrl.dispose();
    super.dispose();
  }

  int get _minutes => widget.args.end.difference(widget.args.start).inMinutes;

  void _regenerateTemplate() {
    if (_descriptionEditedByUser) return; // never overwrite manual text
    final lookup = ref.read(syllabusLookupProvider).valueOrNull;
    _descriptionCtrl.text = DescriptionTemplates.generate(
      activity: _activity,
      subject: lookup?.subject(widget.args.subjectId) ?? '',
      chapter: lookup?.chapter(widget.args.chapterId),
      topic: lookup?.topic(widget.args.topicId),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final input = SessionInput(
        taskId: widget.args.taskId,
        subjectId: widget.args.subjectId,
        chapterId: widget.args.chapterId,
        topicId: widget.args.topicId,
        start: widget.args.start,
        end: widget.args.end,
        activityType: _activity,
        description: _descriptionCtrl.text,
        difficulty: _difficulty,
        understanding: _understanding,
        questionsSolved: int.tryParse(_questionsCtrl.text.trim()) ?? 0,
      );
      await ref.read(sessionActionsProvider).create(input);
      await ref.read(timerControllerProvider.notifier).discard();
      if (mounted) {
        context.showSnack('Session saved');
        context.go('/timesheet');
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.read(syllabusLookupProvider).hasValue && _descriptionCtrl.text.isEmpty) {
      _regenerateTemplate();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Save Session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer),
              title: Text('Time spent: ${AppDate.formatMinutes(_minutes)}'),
              subtitle: Text(
                '${AppDate.time(widget.args.start)} – ${AppDate.time(widget.args.end)}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Activity type', style: context.texts.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final a in ActivityType.values)
                ChoiceChip(
                  label: Text(a.label),
                  selected: _activity == a,
                  onSelected: (_) {
                    setState(() => _activity = a);
                    _regenerateTemplate();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Used for your timesheet',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _descriptionEditedByUser = true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _descriptionEditedByUser = false;
                _regenerateTemplate();
                setState(() {});
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset to template'),
            ),
          ),
          const SizedBox(height: 8),
          Text('Difficulty', style: context.texts.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Difficulty>(
            segments: const [
              ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
              ButtonSegment(value: Difficulty.medium, label: Text('Medium')),
              ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 16),
          Text('Understanding', style: context.texts.labelLarge),
          Slider(
            value: _understanding.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_understanding / 5',
            onChanged: (v) => setState(() => _understanding = v.round()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _questionsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Questions solved (optional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save Session'),
          ),
        ],
      ),
    );
  }
}
