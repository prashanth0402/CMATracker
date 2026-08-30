import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/study_session_repository.dart';

/// Orchestrates session writes and the downstream recalculation so every entry
/// point (timer completion, manual entry, timesheet edit) behaves identically.
class SessionActions {
  SessionActions(this._ref);
  final Ref _ref;

  Future<int> create(SessionInput input) async {
    final id = await _ref.read(studySessionRepositoryProvider).create(input);
    await _applyTopicProgress(input);
    await _ref
        .read(recalculationServiceProvider)
        .onSessionChanged(affectedDay: input.start);
    return id;
  }

  Future<void> update(int id, SessionInput input) async {
    final old = await _ref.read(studySessionRepositoryProvider).byId(id);
    await _ref.read(studySessionRepositoryProvider).update(id, input);
    await _applyTopicProgress(input);
    // Recompute both the old and new day so moving a session keeps both correct.
    await _ref
        .read(recalculationServiceProvider)
        .onSessionChanged(affectedDay: AppDate.fromIso(old.startTime));
    await _ref
        .read(recalculationServiceProvider)
        .onSessionChanged(affectedDay: input.start);
  }

  Future<void> delete(int id) async {
    final old = await _ref.read(studySessionRepositoryProvider).byId(id);
    await _ref.read(studySessionRepositoryProvider).delete(id);
    await _ref
        .read(recalculationServiceProvider)
        .onSessionChanged(affectedDay: AppDate.fromIso(old.startTime));
  }

  Future<void> duplicate(int id) async {
    final newId = await _ref.read(studySessionRepositoryProvider).duplicate(id);
    final s = await _ref.read(studySessionRepositoryProvider).byId(newId);
    await _ref
        .read(recalculationServiceProvider)
        .onSessionChanged(affectedDay: AppDate.fromIso(s.startTime));
  }

  Future<void> _applyTopicProgress(SessionInput input) async {
    final topicId = input.topicId;
    if (topicId == null) return;
    await _ref
        .read(topicRepositoryProvider)
        .applySessionProgress(topicId, input.activityType);
  }
}

final sessionActionsProvider = Provider((ref) => SessionActions(ref));
