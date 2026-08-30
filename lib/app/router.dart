import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/database/database.dart';
import '../features/backup/backup_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/reports/monthly_report_screen.dart';
import '../features/reports/weekly_report_screen.dart';
import '../features/rewards/achievements_screen.dart';
import '../features/rewards/rewards_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/study_sessions/manual_entry_screen.dart';
import '../features/study_sessions/session_completion_screen.dart';
import '../features/study_tasks/task_edit_screen.dart';
import '../features/subjects/subject_detail_screen.dart';
import '../features/subjects/subjects_screen.dart';
import '../features/subjects/topic_detail_screen.dart' show TopicDetailScreen, TimerPreset;
import '../features/timer/timer_screen.dart';
import '../features/timesheet/timesheet_screen.dart';
import '../shared/widgets/scaffold_shell.dart';

/// Central route table. Bottom-nav tabs live in a [StatefulShellRoute]; every
/// other screen is a top-level push so it keeps its own back button.
class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();

  static GoRouter build() => GoRouter(
        navigatorKey: _rootKey,
        initialLocation: '/dashboard',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => ScaffoldShell(shell: shell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (_, __) => const DashboardScreen(),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/study',
                  builder: (_, __) => const SubjectsScreen(embedded: true),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/timer',
                  builder: (_, s) =>
                      TimerScreen(preset: s.extra as TimerPreset?),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/timesheet',
                  builder: (_, __) => const TimesheetScreen(),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/progress',
                  builder: (_, __) => const ProgressScreen(),
                ),
              ]),
            ],
          ),
          GoRoute(
            path: '/subjects',
            builder: (_, __) => const SubjectsScreen(),
          ),
          GoRoute(
            path: '/subjects/:id',
            builder: (_, s) => SubjectDetailScreen(
              subjectId: int.parse(s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/topic/:id',
            builder: (_, s) => TopicDetailScreen(
              topicId: int.parse(s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/calendar',
            builder: (_, __) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/reports/weekly',
            builder: (_, __) => const WeeklyReportScreen(),
          ),
          GoRoute(
            path: '/reports/monthly',
            builder: (_, __) => const MonthlyReportScreen(),
          ),
          GoRoute(
            path: '/rewards',
            builder: (_, __) => const RewardsScreen(),
          ),
          GoRoute(
            path: '/achievements',
            builder: (_, __) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/backup',
            builder: (_, __) => const BackupScreen(),
          ),
          GoRoute(
            path: '/session/complete',
            builder: (_, s) =>
                SessionCompletionScreen(args: s.extra as SessionCompletionArgs),
          ),
          GoRoute(
            path: '/session/manual',
            builder: (_, __) => const ManualEntryScreen(),
          ),
          GoRoute(
            path: '/session/edit',
            builder: (_, s) =>
                ManualEntryScreen(existing: s.extra as StudySession?),
          ),
          GoRoute(
            path: '/task/edit',
            builder: (_, s) => TaskEditScreen(existing: s.extra as StudyTask?),
          ),
        ],
      );
}
