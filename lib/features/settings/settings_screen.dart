import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/extensions/extensions.dart';
import '../../core/providers/providers.dart';
import '../../core/services/notification_service.dart';
import '../../data/database/database.dart';
import '../../shared/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final repo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AsyncView(
        value: settingsAsync,
        data: (s) => ListView(
          children: [
            const SectionHeader('Study targets'),
            _MinutesTile(
              label: 'Weekday target',
              minutes: s.weekdayTargetMinutes,
              onChanged: (v) => repo.update(
                UserSettingsCompanion(weekdayTargetMinutes: Value(v)),
              ),
            ),
            _MinutesTile(
              label: 'Weekend target',
              minutes: s.weekendTargetMinutes,
              onChanged: (v) => repo.update(
                UserSettingsCompanion(weekendTargetMinutes: Value(v)),
              ),
            ),
            ListTile(
              title: const Text('Weekly target'),
              trailing: Text(
                '${(s.targetCalculator.weeklyTargetMinutes / 60).toStringAsFixed(1)} h',
              ),
            ),
            const SectionHeader('Appearance'),
            ListTile(
              title: const Text('Theme'),
              trailing: DropdownButton<ThemeModeOption>(
                value: s.themeMode,
                onChanged: (v) => v == null
                    ? null
                    : repo.update(
                        UserSettingsCompanion(themeMode: Value(v.name)),
                      ),
                items: [
                  for (final o in ThemeModeOption.values)
                    DropdownMenuItem(value: o, child: Text(o.label)),
                ],
              ),
            ),
            ListTile(
              title: const Text('Start of week'),
              trailing: DropdownButton<int>(
                value: s.startOfWeek,
                onChanged: (v) => v == null
                    ? null
                    : repo.update(
                        UserSettingsCompanion(startOfWeek: Value(v)),
                      ),
                items: const [
                  DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                  DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                ],
              ),
            ),
            const SectionHeader('Reminders'),
            SwitchListTile(
              title: const Text('Daily study reminder'),
              subtitle: Text(
                '${s.reminderHour.toString().padLeft(2, '0')}:'
                '${s.reminderMinute.toString().padLeft(2, '0')}',
              ),
              value: s.remindersEnabled,
              onChanged: (v) async {
                await repo.update(
                  UserSettingsCompanion(remindersEnabled: Value(v)),
                );
                if (v) {
                  await NotificationService.instance.scheduleDailyReminder(
                    hour: s.reminderHour,
                    minute: s.reminderMinute,
                  );
                } else {
                  await NotificationService.instance.cancelReminder();
                }
              },
            ),
            if (s.remindersEnabled)
              ListTile(
                title: const Text('Reminder time'),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: s.reminderHour, minute: s.reminderMinute),
                  );
                  if (picked == null) return;
                  await repo.update(UserSettingsCompanion(
                    reminderHour: Value(picked.hour),
                    reminderMinute: Value(picked.minute),
                  ));
                  await NotificationService.instance.scheduleDailyReminder(
                    hour: picked.hour,
                    minute: picked.minute,
                  );
                },
              ),
            const SectionHeader('Data'),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup & Restore'),
              onTap: () => context.push('/backup'),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever,
                  color: context.colors.error),
              title: const Text('Reset all study data'),
              subtitle: const Text('Sessions, tasks, rewards & streaks'),
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Reset all data?',
                  message:
                      'This permanently deletes all sessions, tasks, rewards '
                      'and resets topic status. The syllabus is kept.',
                  confirmLabel: 'Reset',
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(backupServiceProvider).resetAllData();
                ref.invalidate(allSessionsProvider);
                if (context.mounted) context.showSnack('All study data reset');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MinutesTile extends StatelessWidget {
  const _MinutesTile({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });
  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: minutes.toDouble().clamp(30, 720),
        min: 30,
        max: 720,
        divisions: 23,
        label: '${(minutes / 60).toStringAsFixed(1)} h',
        onChanged: (v) => onChanged((v / 15).round() * 15),
      ),
      trailing: Text('${(minutes / 60).toStringAsFixed(1)} h'),
    );
  }
}
