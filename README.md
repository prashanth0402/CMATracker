# CMA Tracker

An **offline-first**, fully standalone study & timesheet tracker for the
**CMA Intermediate Group 1** syllabus (Papers 5–8). Built with Flutter + Dart.

There is **no backend, API, Firebase, auth server or cloud database**. (The only network use is an AdMob banner; see `lib/core/services/ad_service.dart` — it ships with Google's *test* ad IDs, replace them and the app IDs in `AndroidManifest.xml` / `Info.plist` before release.) Every
feature works with the device in airplane mode. All data lives in a local
SQLite database; the only outbound action is the OS "share sheet" you invoke
yourself when exporting a CSV / JSON file.

---

## Product summary

| Target        | Value (default, configurable) |
|---------------|-------------------------------|
| Weekday (Mon–Fri) | 3 h / day (`weekdayTargetMinutes = 180`) |
| Weekend (Sat–Sun) | 6 h / day (`weekendTargetMinutes = 360`) |
| Weekly            | 27 h  (`5·180 + 2·360 = 1620 min`, derived) |

Core workflow:

> **Select Subject → Select Topic → Start Timer → Study → Stop → Add Description → Save Session**

Saving a session automatically recalculates daily / weekly / monthly / subject /
topic progress, streaks, points and achievements. Nothing derived is stored
except the append-only points ledger and achievement-unlock flags.

---

## Architecture

Clean, layered, unidirectional:

```
UI (features/**, shared/**)
      │  watches / calls
Riverpod providers & notifiers (core/providers, features/**/*_controller.dart)
      │
Repositories (data/repositories/**)   ← hide all Drift/SQL details
      │
Drift database (data/database/**)
      │
SQLite file  (app documents dir / cma_tracker.sqlite)
```

Business logic never lives in `build()`. Targets, streaks and analytics are
pure functions in `core/utils/` so they are trivially unit-testable.

### Directory layout

```
lib/
  main.dart                 app bootstrap (open DB, seed, restore reminder)
  app/                      app widget, GoRouter table, Material 3 theme
  core/
    constants/              enums, numeric constants, reward point values
    errors/                 sealed AppException hierarchy
    extensions/             BuildContext / iterable helpers
    utils/                  date utils, TargetCalculator, Analytics
    services/               TimerService, Recalculation, Backup, Csv, Notifications
    providers/              the Riverpod dependency graph
  data/
    database/               Drift tables + generated code
    models/                 immutable analytic value objects
    repositories/           one repository per aggregate
    seed/                   CMA Group 1 syllabus + achievement definitions (data only)
  features/                 dashboard, subjects, study_tasks, timer, timesheet,
                            calendar, progress, reports, rewards, settings, backup,
                            study_sessions
  shared/widgets/           AsyncView, Empty/Error states, StatCard, ProgressRing…
test/
  unit/                     pure-logic tests
  integration/              DB-backed flow tests (in-memory SQLite)
```

---

## Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | state management |
| `drift`, `sqlite3_flutter_libs` | typed local database over SQLite |
| `path_provider`, `path` | locate the on-device DB / export files |
| `go_router` | declarative navigation (bottom-nav `StatefulShellRoute`) |
| `shared_preferences` | reserved for lightweight prefs |
| `flutter_local_notifications`, `timezone` | optional daily study reminder |
| `csv` | timesheet CSV generation |
| `file_picker` | choose a JSON backup to import |
| `share_plus` | hand exported files to the OS share sheet |
| `intl` | date / number formatting |

Dev: `drift_dev`, `build_runner`, `flutter_lints`.

---

## Database

Drift, `schemaVersion = 1`. Tables: `subjects`, `chapters`, `topics`,
`study_tasks`, `study_sessions`, `daily_targets`, `rewards`, `achievements`,
`user_settings`, `app_metadata`.

Foreign keys are enforced (`PRAGMA foreign_keys = ON`) with cascade / set-null
rules. Indexes are created on every high-traffic column
(`study_sessions.day`, `.subject_id`, `.topic_id`, `study_tasks.day`,
`chapters.subject_id`, `topics.chapter_id`, `rewards.day`).

`study_sessions` is the single source of truth for analytics and stores:
`id, taskId, subjectId, chapterId, topicId, day, startTime, endTime,
durationMinutes, activityType, description, difficulty, understanding,
questionsSolved, createdAt, updatedAt`. Timestamps are stored as UTC ISO-8601
and displayed in device-local time (`core/utils/date_utils.dart`).

The syllabus is inserted exactly once by `SeedRepository.ensureSeeded()`
(guarded by an `app_metadata` flag) from `data/seed/syllabus_seed.dart`.

---

## State management

`core/providers/providers.dart` wires the graph. `databaseProvider` is
overridden in `main()` with the concrete `AppDatabase`. Repository/service
providers are plain `Provider`s. Live data uses `StreamProvider`s backed by
Drift `watch()` queries, so any write refreshes the UI automatically.

Derived progress providers (`dailyProgressProvider`, `weeklyProgressProvider`,
`streakProvider`, `subjectProgressProvider`, …) `ref.watch(allSessionsProvider)`
and recompute from raw sessions — they can never show stale numbers after an
edit or delete.

`SessionActions` (`features/study_sessions/session_actions.dart`) is the one
funnel for creating / editing / deleting sessions; it applies topic-status
auto-progress and invokes `RecalculationService` for both the old and new day.

---

## Timer implementation

`TimerService` persists the active timer to `app_metadata` as JSON:
`state, subjectId/chapterId/topicId/taskId, accumulatedMs, segmentStartMs,
firstStartMs`.

Elapsed time is **always** `accumulatedMs + (running ? now − segmentStartMs : 0)`
— derived from wall-clock timestamps, never from an in-memory counter. Therefore
backgrounding, screen lock, and full app restarts do not lose or distort time.
`TimerController` (an `AsyncNotifier`) adds a 1 s UI tick while running.

States: `idle → running ⇄ paused → completed`. On **Stop** the snapshot is
frozen (not cleared) so the completion screen can read the context; it is
cleared only after the session is saved or discarded.

---

## Backup format (`CMA_Tracker_Backup.json`)

```jsonc
{
  "schemaVersion": 1,
  "exportedAt": "2026-08-30T...Z",
  "settings":      [ ...userSettings rows... ],
  "subjects":      [ ... ], "chapters": [ ... ], "topics": [ ... ],
  "tasks":         [ ... ], "sessions": [ ... ],
  "dailyTargets":  [ ... ], "rewards":  [ ... ], "achievements": [ ... ],
  "appMetadata":   [ ... ]
}
```

`BackupService.restoreFromJsonString()` **validates** the structure first
(required keys, list types, schema version not newer than the app), then wipes
and repopulates **inside a single transaction**. A malformed import throws
`ImportException` and leaves the existing database untouched.

---

## CSV format

`CMA_Timesheet_YYYY_MM.csv` (monthly) or
`CMA_Timesheet_<from>_to_<to>.csv` (custom range).

Columns: `Date, Subject, Chapter, Topic, Activity, Start Time, End Time,
Duration, Description, Difficulty, Understanding, Questions Solved`.

---

## Rewards, streaks, achievements

Point values live in `RewardPoints` (`core/constants/app_constants.dart`):
daily 100 / weekend 150 / topic 25 / revision 20 / mock 50 / 7-day streak 200 /
weekly 500. The `rewards` table is an append-only ledger; awards are keyed by
`(type, day)` or `(type, entityKey)` so a milestone is never double-counted.

A day is "successful" when its total minutes ≥ that day's target. Streaks are
recomputed from scratch from `study_sessions` every time (`Analytics.streak`),
so duplicates or deletions can't corrupt them.

Achievements (`AchievementRepository.reevaluate`) unlock purely from stored
data and only ever set `unlockedAt` once.

---

## Testing

```bash
flutter test
```

* **Unit** – target/weekend/weekly/monthly target calc; session & midnight
  duration; timer state transitions (start/stop, pause/resume, reload = restart,
  double-start guard, clear); streak calculation incl. break & same-day
  de-dup; question totals; description templates.
* **Integration** (in-memory SQLite) – syllabus seed; automatic daily-progress
  update on save; points awarded once (no duplicates); progress recomputed
  after edit + delete; CSV header/rows; JSON backup round-trip; malformed
  backup rejected without data loss.

All 32 tests pass; `flutter analyze` reports no issues.

---

## Build

```bash
flutter pub get
dart run build_runner build          # generates Drift code (database.g.dart)
flutter analyze
flutter test
flutter build apk --release
```

> Regenerate `lib/data/database/database.g.dart` with `build_runner` whenever
> `tables.dart` changes.

### Offline guarantee

No `http`, `dio`, Firebase or socket code exists anywhere in `lib/`. The app
requires no `INTERNET` permission to function; the Android manifest only
declares `POST_NOTIFICATIONS` / `RECEIVE_BOOT_COMPLETED` for the optional local
reminder.
