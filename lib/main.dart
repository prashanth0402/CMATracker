import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/providers.dart';
import 'core/services/notification_service.dart';
import 'data/database/database.dart';
import 'data/repositories/seed_repository.dart';
import 'data/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  await SeedRepository(db).ensureSeeded();

  // Restore the daily reminder if the user had enabled it.
  final settings = await SettingsRepository(db).load();
  if (settings.remindersEnabled) {
    await NotificationService.instance.scheduleDailyReminder(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );
  }

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const CmaTrackerApp(),
    ),
  );
}
