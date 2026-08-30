import '../../core/constants/enums.dart';

/// Generates a first-draft timesheet description. The user can always edit the
/// result; callers must never overwrite text the user has typed.
class DescriptionTemplates {
  const DescriptionTemplates._();

  static String generate({
    required ActivityType activity,
    required String subject,
    String? chapter,
    String? topic,
  }) {
    final scope = [
      if (subject.isNotEmpty) subject,
      if (chapter != null && chapter.isNotEmpty) chapter,
      if (topic != null && topic.isNotEmpty) topic,
    ].join(' - ');
    final where = scope.isEmpty ? 'the planned material' : scope;

    return switch (activity) {
      ActivityType.studied =>
        'Studied $where. Reviewed concepts and worked through examples.',
      ActivityType.revised || ActivityType.revision =>
        'Revised $where and consolidated key points.',
      ActivityType.practicedQuestions =>
        'Practiced questions on $where and reviewed solutions.',
      ActivityType.mockTest =>
        'Attempted a mock test covering $where and analysed mistakes.',
      ActivityType.watchedLecture =>
        'Watched a lecture on $where and made notes.',
      ActivityType.readNotes =>
        'Read notes on $where and highlighted important points.',
      ActivityType.doubtClearing =>
        'Cleared doubts on $where and noted clarifications.',
    };
  }

  static const List<String> quickTemplates = [
    'Studied Financial Accounting - Accounting Standards. Reviewed concepts and solved practice questions.',
    'Revised Cost Accounting - Material Cost and practiced numerical problems.',
    'Studied GST - Input Tax Credit and reviewed eligibility conditions.',
  ];
}
