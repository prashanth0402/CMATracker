import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/target_calculator.dart';
import '../database/database.dart';

class AppSettings {
  const AppSettings({
    required this.weekdayTargetMinutes,
    required this.weekendTargetMinutes,
    required this.themeMode,
    required this.startOfWeek,
    required this.remindersEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });

  final int weekdayTargetMinutes;
  final int weekendTargetMinutes;
  final ThemeModeOption themeMode;
  final int startOfWeek; // DateTime.weekday value
  final bool remindersEnabled;
  final int reminderHour;
  final int reminderMinute;

  TargetCalculator get targetCalculator => TargetCalculator(
    weekdayTargetMinutes: weekdayTargetMinutes,
    weekendTargetMinutes: weekendTargetMinutes,
  );

  factory AppSettings.fromRow(UserSetting r) => AppSettings(
    weekdayTargetMinutes: r.weekdayTargetMinutes,
    weekendTargetMinutes: r.weekendTargetMinutes,
    themeMode: ThemeModeOption.fromName(r.themeMode),
    startOfWeek: r.startOfWeek,
    remindersEnabled: r.remindersEnabled,
    reminderHour: r.reminderHour,
    reminderMinute: r.reminderMinute,
  );
}

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<AppSettings> load() async {
    try {
      final row = await (_db.select(_db.userSettings)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      if (row == null) {
        await _db.into(_db.userSettings).insert(
              const UserSettingsCompanion(id: Value(1)),
              mode: InsertMode.insertOrIgnore,
            );
        return const AppSettings(
          weekdayTargetMinutes: 180,
          weekendTargetMinutes: 360,
          themeMode: ThemeModeOption.system,
          startOfWeek: DateTime.monday,
          remindersEnabled: false,
          reminderHour: 19,
          reminderMinute: 0,
        );
      }
      return AppSettings.fromRow(row);
    } catch (e) {
      throw DatabaseException('Could not load settings.', cause: e);
    }
  }

  Stream<AppSettings> watch() {
    return (_db.select(_db.userSettings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((r) => r == null
            ? const AppSettings(
                weekdayTargetMinutes: 180,
                weekendTargetMinutes: 360,
                themeMode: ThemeModeOption.system,
                startOfWeek: DateTime.monday,
                remindersEnabled: false,
                reminderHour: 19,
                reminderMinute: 0,
              )
            : AppSettings.fromRow(r));
  }

  Future<void> update(UserSettingsCompanion companion) async {
    try {
      await (_db.update(_db.userSettings)..where((t) => t.id.equals(1)))
          .write(companion);
    } catch (e) {
      throw DatabaseException('Could not save settings.', cause: e);
    }
  }
}
