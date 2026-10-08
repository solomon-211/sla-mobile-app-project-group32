# SprintTrack - Group 32

Project & SLA task tracker for a small software team, built with Flutter.
The app lives in [`task_flow_sla/`](task_flow_sla/). How the app works (screens,
SLA rules, storage, how to run it) is in
[`task_flow_sla/README.md`](task_flow_sla/README.md).

This page is for the team: **who owns which files, and how to push your part.**

## Who owns what

Each member owns the screens assigned to them in the screen designs, plus the
helper files those screens depend on. All paths below are inside
`task_flow_sla/`.

### Member 1 - Create / Edit Task, validation, sqflite

| File | What it is |
| --- | --- |
| `lib/screens/task_form_screen.dart` | The Create / Edit Task form |
| `lib/utils/validators.dart` | Validation rules (title, due date, email, password) |
| `lib/services/database_helper.dart` | The sqflite database: tables, queries, saving |

### Member 2 - Dashboard, SLA logic, navigation

| File | What it is |
| --- | --- |
| `lib/screens/dashboard_screen.dart` | The Project Dashboard |
| `lib/utils/sla.dart` | The SLA rules (On Track, At Risk, Overdue, Completed) |
| `lib/app_router.dart` | Named routes between screens |
| `lib/screens/home_shell.dart` | Bottom navigation and the data shared by the tabs |
| `lib/widgets/app_drawer.dart` | The side menu (drawer) |
| `lib/widgets/donut_chart.dart` | The donut chart on the Dashboard |
| `test/sla_test.dart` | Unit tests for the SLA rules and validators |

### Member 3 - Task List, Sign In

| File | What it is |
| --- | --- |
| `lib/screens/task_list_screen.dart` | The Task List with search and filter chips |
| `lib/screens/sign_in_screen.dart` | Sign In / User Selection |
| `lib/widgets/task_card.dart` | One task card in the list |
| `lib/services/session_service.dart` | Saves the signed-in user (SharedPreferences) |

### Member 4 - Task Details, Team Members

| File | What it is |
| --- | --- |
| `lib/screens/task_details_screen.dart` | Task Details, status change, delete |
| `lib/screens/team_screen.dart` | Team Members, switch user, sign out |
| `lib/widgets/member_form_dialog.dart` | The add / edit member dialog |

### Shared base - pushed once, before anyone else

These files are used by every screen, so they do not belong to one member.
One person pushes them first (see step 1 below).

| Files | What they are |
| --- | --- |
| `lib/main.dart` | App entry point |
| `lib/models/` (`task.dart`, `team_member.dart`, `task_activity.dart`) | Data classes |
| `lib/theme/app_theme.dart` | Colours and theme |
| `lib/data/seed_data.dart` | Demo data for the first launch |
| `lib/utils/formatters.dart` | Date formatting |
| `lib/widgets/status_widgets.dart`, `member_avatar.dart`, `dialogs.dart` | Widgets used on several screens |
| `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore` | Project setup |
| `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` | Platform folders created by Flutter |
| `README.md` (this file) and `task_flow_sla/README.md` | Documentation |

## How to push your part

### Step 1 - One person pushes the shared base

Do this once. It adds the whole project, then takes the four members' files
back out so each member can push their own. Run from the repository root:

```bash
git checkout -b shared-base
git add README.md task_flow_sla

# Take the members' files back out of this commit
git restore --staged \
  task_flow_sla/lib/screens \
  task_flow_sla/lib/app_router.dart \
  task_flow_sla/lib/utils/validators.dart \
  task_flow_sla/lib/utils/sla.dart \
  task_flow_sla/lib/services \
  task_flow_sla/lib/widgets/app_drawer.dart \
  task_flow_sla/lib/widgets/donut_chart.dart \
  task_flow_sla/lib/widgets/task_card.dart \
  task_flow_sla/lib/widgets/member_form_dialog.dart \
  task_flow_sla/test/sla_test.dart

git status          # check: no file from the member tables is listed as staged
git commit -m "Add Flutter project setup, models, theme and shared widgets"
git push -u origin shared-base
```

Open a pull request from `shared-base` into `main` on GitHub and merge it.

### Step 2 - Each member pushes their own files

1. Get the latest `main` and create your own branch:

   ```bash
   git checkout main
   git pull
   git checkout -b yourname-yourfeature     # e.g. amina-task-form
   ```

2. Copy **only the files in your table above** into the same paths inside
   `task_flow_sla/`. Get them from the teammate who has the full project.

3. Read every file you are about to push. You will explain it in the demo, so
   make sure you can say what each widget and function does. Make your own
   changes where you want them (wording, spacing, comments, messages).

4. Check exactly what you are about to push:

   ```bash
   git status
   ```

   Only files from **your** table should appear. If you see someone else's
   file, do not add it.

5. Commit in small steps, not one big commit. For example, Member 1:

   ```bash
   git add task_flow_sla/lib/utils/validators.dart
   git commit -m "Add validation rules for task title and due date"

   git add task_flow_sla/lib/services/database_helper.dart
   git commit -m "Add sqflite database helper for tasks and members"

   git add task_flow_sla/lib/screens/task_form_screen.dart
   git commit -m "Add Create / Edit Task form with validation"

   git push -u origin yourname-yourfeature
   ```

6. Open a pull request from your branch into `main`. Ask another member to
   review it, then merge.

### Step 3 - After the last merge

The app only builds once the shared base **and all four members' parts** are in
`main`, because the screens import each other. Until then, errors about missing
files are expected. After the last merge, one person runs:

```bash
git checkout main
git pull
cd task_flow_sla
flutter pub get
flutter analyze     # should say "No issues found!"
flutter test        # should say "All tests passed!"
flutter run         # on an emulator or phone, not Chrome
```

## Rules to keep the history clean

- Never commit straight to `main`. Always use your own branch and a pull request.
- Push only your own files. If you need to change someone else's file, ask them
  or open a separate pull request that says why.
- Write commit messages that say what changed, e.g. "Add search to task list",
  not "update" or "fix".
- Record what you did in the group contribution tracker after each push.
- AI tools were used to write this code. Each member must review, test and be
  able to explain their own files, and the group's AI Usage Declaration must say
  so.
