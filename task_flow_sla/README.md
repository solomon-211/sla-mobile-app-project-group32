# SprintTrack

Project & SLA task tracker for a small software team, built with Flutter.
Assign tasks, track deadlines and flag work that is at risk. All data is stored
on the device; there is no backend.

## Screens

| Screen | File |
| --- | --- |
| Sign In / User Selection | `lib/screens/sign_in_screen.dart` |
| Project Dashboard | `lib/screens/dashboard_screen.dart` |
| Task List | `lib/screens/task_list_screen.dart` |
| Task Details | `lib/screens/task_details_screen.dart` |
| Create / Edit Task | `lib/screens/task_form_screen.dart` |
| Team Members | `lib/screens/team_screen.dart` |

## SLA rules

Checked in this order (`lib/utils/sla.dart`):

1. **Completed** - the task status is Done.
2. **Overdue** - not done and the deadline has passed.
3. **At Risk** - not done and either
   - less time is left than the priority's lead time
     (High 72 hours, Medium 48 hours, Low 24 hours), or
   - 75% or more of the time between creation and deadline is used.
4. **On Track** - everything else.

Statuses refresh every minute while the app is open.

## Demo sign in

Tap any team member, or sign in with their email and the demo password
`sprint123`. Accounts made with "Create account" use the password chosen there.

## Project structure

```
lib/
  main.dart            App entry, restores the saved session
  app_router.dart      Named routes
  theme/               Colours and ThemeData
  models/              Task, TeamMember, TaskActivity
  services/            DatabaseHelper (sqflite), SessionService (SharedPreferences)
  utils/               SLA rules, validators, date formatting
  data/                Demo data inserted on first launch
  screens/             One file per screen, plus HomeShell (bottom navigation)
  widgets/             Shared widgets (badges, avatars, task card, dialogs, donut chart)
test/
  sla_test.dart        Unit tests for the SLA rules and validators
```

## Storage

- **sqflite** stores tasks, team members and task history, because they are
  related records that need querying and sorting.
- **SharedPreferences** stores the signed-in user and the "Remember me" choice,
  which are single key-value settings.

## Running

Run on an Android emulator or a physical device (sqflite does not run in the
browser):

```
flutter pub get
flutter run
flutter test
```

On Windows, building with plugins needs Developer Mode switched on
(`start ms-settings:developers`).
