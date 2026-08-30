import 'package:cma_tracker/core/providers/providers.dart';
import 'package:cma_tracker/data/database/database.dart';
import 'package:cma_tracker/data/repositories/seed_repository.dart';
import 'package:cma_tracker/features/dashboard/dashboard_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard renders target/streak cards from a seeded DB',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await SeedRepository(db).ensureSeeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('CMA Tracker'), findsOneWidget);
    expect(find.text("Today's target"), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Subject summary'), findsOneWidget);
  });
}
