import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/database.dart';
import '../errors/app_exceptions.dart';
import '../utils/date_utils.dart';

/// Generates timesheet CSV exports. Pure string generation is exposed for tests
/// via [buildCsv].
class CsvService {
  CsvService(this._db);
  final AppDatabase _db;

  static const header = <String>[
    'Date',
    'Subject',
    'Chapter',
    'Topic',
    'Activity',
    'Start Time',
    'End Time',
    'Duration',
    'Description',
    'Difficulty',
    'Understanding',
    'Questions Solved',
  ];

  String buildCsv(List<List<String>> rows) =>
      const ListToCsvConverter().convert([header, ...rows]);

  Future<List<List<String>>> buildRows(List<StudySession> sessions) async {
    final subjects = {for (final s in await _db.select(_db.subjects).get()) s.id: s.title};
    final chapters = {for (final c in await _db.select(_db.chapters).get()) c.id: c.title};
    final topics = {for (final t in await _db.select(_db.topics).get()) t.id: t.title};

    return sessions.map((s) {
      final start = AppDate.fromIso(s.startTime);
      final end = AppDate.fromIso(s.endTime);
      return <String>[
        AppDate.isoDay(start),
        subjects[s.subjectId] ?? '',
        s.chapterId == null ? '' : (chapters[s.chapterId] ?? ''),
        s.topicId == null ? '' : (topics[s.topicId] ?? ''),
        s.activityType,
        AppDate.time(start),
        AppDate.time(end),
        AppDate.formatMinutes(s.durationMinutes),
        s.description,
        s.difficulty,
        s.understanding.toString(),
        s.questionsSolved.toString(),
      ];
    }).toList();
  }

  /// Writes a CSV file for the given sessions and returns its path.
  Future<String> exportSessions(
    List<StudySession> sessions, {
    required String fileName,
  }) async {
    try {
      final rows = await buildRows(sessions);
      final csv = buildCsv(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(csv);
      return file.path;
    } catch (e) {
      throw BackupException('Could not export CSV.', cause: e);
    }
  }

  static String monthlyFileName(DateTime month) =>
      'CMA_Timesheet_${month.year}_${month.month.toString().padLeft(2, '0')}.csv';
}
