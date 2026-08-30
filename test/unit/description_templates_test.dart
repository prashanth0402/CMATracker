import 'package:cma_tracker/core/constants/enums.dart';
import 'package:cma_tracker/features/study_sessions/description_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('template mentions subject, chapter and topic', () {
    final text = DescriptionTemplates.generate(
      activity: ActivityType.studied,
      subject: 'Financial Accounting',
      chapter: 'Accounting Standards',
      topic: 'AS 10',
    );
    expect(text, contains('Financial Accounting'));
    expect(text, contains('AS 10'));
  });

  test('template varies by activity type', () {
    final revise = DescriptionTemplates.generate(
      activity: ActivityType.revised,
      subject: 'Cost Accounting',
    );
    final mock = DescriptionTemplates.generate(
      activity: ActivityType.mockTest,
      subject: 'Cost Accounting',
    );
    expect(revise, isNot(equals(mock)));
    expect(revise.toLowerCase(), contains('revised'));
    expect(mock.toLowerCase(), contains('mock test'));
  });

  test('handles missing chapter/topic gracefully', () {
    final text = DescriptionTemplates.generate(
      activity: ActivityType.studied,
      subject: 'Business Laws and Ethics',
    );
    expect(text, contains('Business Laws and Ethics'));
    expect(text, isNot(contains(' -  - ')));
  });
}
