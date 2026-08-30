// Basic smoke test. Feature-level tests live under test/ in dedicated files.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('CMA Tracker'))),
    );
    expect(find.text('CMA Tracker'), findsOneWidget);
  });
}
