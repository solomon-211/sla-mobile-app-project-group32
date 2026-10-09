# SprintTrack - Group 32

Project & SLA task tracker for a small software team, built with Flutter.

This page is for the team: **who owns which files, and how to move your part
into the group repository.**

| | Repository | Layout |
| --- | --- | --- |
| **Source** (this repo, the finished app) | `github.com/solomon-211/sla-mobile-app-project-group32` | App inside `task_flow_sla/`. The finished redesign is commit `6d8424b` on `main`. |
| **Destination** (the graded repo) | `github.com/solomon-211/sla-mobile-app-project` | Flutter project at the repository root (`lib/`, `test/`, `pubspec.yaml`). |

How the app works (screens, SLA rules, storage, how to run it) is in
[`task_flow_sla/README.md`](task_flow_sla/README.md).

## File map

Every file belongs to exactly one member. Paths are as they will be in the
**destination** repo (in this repo, add `task_flow_sla/` in front).

| File | Owner |
| --- | --- |
| `lib/screens/task_form_screen.dart` | Member 1 |
| `lib/screens/register_screen.dart` | Member 1 |
| `lib/utils/validators.dart` | Member 1 |
| `lib/services/database_helper.dart` | Member 1 |
| `lib/models/task.dart` | Member 1 |
| `lib/models/task_activity.dart` | Member 1 |
| `lib/data/seed_data.dart` | Member 1 |
| `lib/widgets/pill_buttons.dart` | Member 1 |
| `lib/widgets/password_toggle.dart` | Member 1 |
| `lib/screens/dashboard_screen.dart` | Member 2 |
| `lib/screens/home_shell.dart` | Member 2 |
| `lib/utils/sla.dart` | Member 2 |
| `lib/app_router.dart` | Member 2 |
| `lib/main.dart` | Member 2 |
| `lib/theme/app_theme.dart` | Member 2 |
| `lib/widgets/status_widgets.dart` | Member 2 |
| `lib/widgets/donut_chart.dart` | Member 2 |
| `lib/widgets/app_drawer.dart` | Member 2 |
| `lib/widgets/tempo_bottom_nav.dart` | Member 2 |
| `test/sla_test.dart` | Member 2 |
| `pubspec.yaml`, `pubspec.lock` | Member 2 |
| `lib/screens/task_list_screen.dart` | Member 3 |
| `lib/screens/sign_in_screen.dart` | Member 3 |
| `lib/screens/landing_screen.dart` | Member 3 |
| `lib/widgets/task_card.dart` | Member 3 |
| `lib/widgets/entrance.dart` | Member 3 |
| `lib/services/session_service.dart` | Member 3 |
| `lib/utils/formatters.dart` | Member 3 |
| `assets/images/sticky-desk.png` | Member 3 |
| `lib/screens/task_details_screen.dart` | Member 4 |
| `lib/screens/team_screen.dart` | Member 4 |
| `lib/models/team_member.dart` | Member 4 |
| `lib/widgets/member_form_dialog.dart` | Member 4 |
| `lib/widgets/member_avatar.dart` | Member 4 |
| `lib/widgets/dialogs.dart` | Member 4 |
| `lib/widgets/app_card.dart` | Member 4 |
| `lib/widgets/icon_circle_button.dart` | Member 4 |

Many of these files are used on other members' screens too (for example the
theme, the models, the pill buttons and `dialogs.dart`). The owner is the
person who pushes the file and explains it in the demo. If you need a change
in a file you do not own, ask its owner.

## Who owns what

Tick the boxes as you finish each task (edit this file in your own branch).

### Everyone

- [ ] Read your own files until you can explain every widget and function
- [ ] Work only on your own branch and merge through a pull request
- [ ] Review at least one other member's pull request
- [ ] Take part in the 10-15 minute recorded demo and present your own part
- [ ] Add what you reviewed, tested and changed to the AI Usage Declaration

### Member 1 - Create / Edit Task, Register, validation, sqflite

**Screens:** Create / Edit Task, Register

**Tasks**

- [ ] Own the Create / Edit Task form: title, description, category, assignee,
      due date and time, segmented priority pill, status, and the
      "Discard changes?" prompt when leaving with unsaved edits
- [ ] Own Register: full name, work email, role, password with the strength
      bar, confirm password with the live "Passwords don't match" message,
      saving the new member and signing them in
- [ ] Own the validation rules and the error messages shown under each field
- [ ] Own the sqflite database: the three tables, the version 2 migration that
      adds passwords, and how tasks, members and task history are saved,
      updated and deleted
- [ ] Own the Task model and the demo data inserted on first launch
- [ ] Own the pill buttons (press animation and arrow nudge) and the
      show / hide password button
- [ ] Test on the emulator: create a task, edit it, try to save an empty title
      and a past due date, press Back with unsaved changes, register a new
      account with mismatched passwords and then correctly, close and reopen
      the app to confirm everything is saved
- [ ] Push the files below from your own branch and open a pull request
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `Form` with `GlobalKey<FormState>` and
`AutovalidateMode`, `TextFormField`, `DropdownButtonFormField`, `FormField`
(the due date row), `showDatePicker`, `showTimePicker`, `PopScope`,
`AnimatedContainer` (the priority pill and the strength bar),
`Material` + `InkWell`, `AnimationController` with `TweenSequence`,
`AnimatedScale` and `AnimatedBuilder` (the pill button), `Semantics`

**Explain in the demo:** the validation rules (title required and 3-60
characters, due date must be in the future, assignee required, password 6+
characters and both passwords must match), why the group chose sqflite, how a
task travels from the form into the database, and how the migration keeps old
installs working after the password column was added.

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/task_form_screen.dart` | The Create / Edit Task form |
| `lib/screens/register_screen.dart` | Create account (saves through sqflite) |
| `lib/utils/validators.dart` | Validation rules (title, due date, email, password) |
| `lib/services/database_helper.dart` | The sqflite database: tables, queries, migration |
| `lib/models/task.dart` | The Task class, priorities and statuses |
| `lib/models/task_activity.dart` | One line of a task's history |
| `lib/data/seed_data.dart` | Demo members and tasks inserted on first launch |
| `lib/widgets/pill_buttons.dart` | `PrimaryPillButton` and `OutlinePillButton` |
| `lib/widgets/password_toggle.dart` | Show / hide button inside password fields |

The destination repo already has `lib/screens/create_edit_task_screen.dart`.
`task_form_screen.dart` replaces it, so remove it in your pull request
(`git rm lib/screens/create_edit_task_screen.dart`).

### Member 2 - Dashboard, SLA logic, navigation, theme

**Screen:** Project Dashboard

**Tasks**

- [ ] Push the project setup first (step 1 below): dependencies, the image
      asset entry and the test file
- [ ] Own the Dashboard (dark screen): greeting, project name (tap to rename),
      the 21-segment progress bar, four SLA tiles, the donut chart with the
      on-time rate, and the "Needs attention" list
- [ ] Own the SLA rules that decide On Track, At Risk, Overdue and Completed
- [ ] Own navigation: named routes (Landing, Register, Sign In, Home, Task
      Details, Task Form), the floating bottom navigation bar and the drawer
- [ ] Own the app theme: colour tokens, Sora and Manrope fonts, inputs,
      buttons, dialogs, and the app entry point
- [ ] Own the tests; run `flutter test`
- [ ] Test on the emulator: every tab, the drawer, the Back button, pull to
      refresh, and that the counts change after a task is marked as done
- [ ] Push the files below from your own branch and open a pull request
- [ ] Run the final checks after the last merge (step 3 below)
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `SingleChildScrollView` with
`RefreshIndicator`, `IntrinsicHeight` (equal-height tiles), `Row` of
`Expanded` bars (progress), `CustomPaint` (donut chart), `AnnotatedRegion`
(light status bar), `IndexedStack` (tabs keep their state), `Scaffold` with
`extendBody` and the floating `TempoBottomNav` (`AnimatedSize`),
`Drawer`, `PopScope`, `Timer.periodic` (SLA refresh), `onGenerateRoute`,
`ThemeData` and `GoogleFonts`

**Explain in the demo:** how the counts are calculated from the SLA rules, the
priority-based At Risk rule (72/48/24 hours or 75% of the window used) and
why the group chose it, how the routes, bottom navigation and drawer connect
the screens, and how `HomeShell` shares data with the tabs using `setState()`.

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/dashboard_screen.dart` | The Project Dashboard |
| `lib/screens/home_shell.dart` | Bottom navigation and the data shared by the tabs |
| `lib/utils/sla.dart` | The SLA rules (On Track, At Risk, Overdue, Completed) |
| `lib/app_router.dart` | Named routes between screens |
| `lib/main.dart` | App entry point (starts on Landing or Home) |
| `lib/theme/app_theme.dart` | Colour tokens, fonts and theme for the whole app |
| `lib/widgets/status_widgets.dart` | SLA badge, SLA colours and priority colours |
| `lib/widgets/donut_chart.dart` | The donut chart on the Dashboard |
| `lib/widgets/app_drawer.dart` | The side menu (drawer) |
| `lib/widgets/tempo_bottom_nav.dart` | The floating pill navigation bar |
| `test/sla_test.dart` | Tests for the SLA rules, validators and three widgets |
| `pubspec.yaml`, `pubspec.lock` | Dependencies and the asset entry (step 1) |

The destination repo already has `lib/screens/project_dashboard_screen.dart`
and the default `test/widget_test.dart`. `dashboard_screen.dart` and
`sla_test.dart` replace them, so remove both in your pull request.

### Member 3 - Task List, Sign In, Landing

**Screens:** Task List, Sign In, Landing

**Tasks**

- [ ] Own the Task List: search pill, SLA filter chips with counts, sorting by
      deadline, the "Needs attention", "Upcoming" and "Completed" groups, dark
      cards for overdue tasks, and the + button
- [ ] Own the task card and its menu (Edit, Mark as done, Delete)
- [ ] Own Sign In: email and password fields, show-password toggle, the
      "Incorrect password" message, and the link to Create account
- [ ] Own Landing: the three-slide carousel with autoplay, the dots, "Get
      started" and "I already have an account"
- [ ] Own the entrance animations (fields sliding up, titles rising in)
- [ ] Own saving the signed-in user with SharedPreferences
- [ ] Own the Landing image (`sticky-desk.png` is an unlicensed placeholder:
      replace it with a licensed image before submitting)
- [ ] Test on the emulator: search, each filter chip, sign in with a wrong
      email and a wrong password, close and reopen the app to confirm you stay
      signed in, watch the carousel autoplay and pause after a swipe
- [ ] Push the files below from your own branch and open a pull request
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `ListView.builder`, `TextField`, filter
chips built from `Material` + `InkWell`, `OverflowBox` (edge-to-edge chip
row), `PopupMenuButton`, `FloatingActionButton`, `IntrinsicHeight` (task
card), `TextFormField`, `LayoutBuilder` with `ConstrainedBox` and
`SingleChildScrollView`, `CarouselView` with `CarouselController`,
`NotificationListener<ScrollNotification>`, `AnimatedContainer` (dots),
`Image.asset`, `AnimationController` with `Interval` (entrance animations),
`ClipRect` + `FractionalTranslation` (rising titles)

**Explain in the demo:** the search and filter logic, using `setState()` to
rebuild the list when a chip is tapped, how the carousel autoplays every 3.2
seconds and pauses for 4 seconds after a swipe, saving the signed-in user with
SharedPreferences, and moving to the Dashboard with
`Navigator.pushNamedAndRemoveUntil` so Back cannot return to Sign In.

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/task_list_screen.dart` | The Task List with search and filter chips |
| `lib/screens/sign_in_screen.dart` | Sign In |
| `lib/screens/landing_screen.dart` | The first screen with the carousel |
| `lib/widgets/task_card.dart` | One task card in the list |
| `lib/widgets/entrance.dart` | `SlideUpIn` and `RiseIn` entrance animations |
| `lib/services/session_service.dart` | Saves the signed-in user (SharedPreferences) |
| `lib/utils/formatters.dart` | Date and time formatting |
| `assets/images/sticky-desk.png` | Landing slide image (placeholder) |

### Member 4 - Task Details, Team Members

**Screens:** Task Details, Team Members

**Tasks**

- [ ] Own Task Details: category, task ID, title, description, the SLA card
      with the 36-tick "time used" scale, the four info tiles (assignee, due
      date, priority, status dropdown), activity history, Edit Task and
      Mark as Done / Reopen
- [ ] Own deleting a task with the bottom confirmation dialog (all confirm
      dialogs in the app share this design)
- [ ] Own Team Members: the dark signed-in card with task stats, Switch user,
      Sign out, and the member cards with task counts and SLA badges
- [ ] Own adding, editing and removing a member, including the member form
- [ ] Own the TeamMember model, the member avatar, and the shared card and
      round icon button
- [ ] Test on the emulator: change a task's status, mark it done and reopen it,
      delete a task, add a member with a duplicate email, switch user, sign out
- [ ] Push the files below from your own branch and open a pull request
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `DropdownButton`, a `Row` of `Container`
ticks (time-used scale), `IntrinsicHeight` (2x2 info tiles), `Text.rich`,
`PopupMenuButton`, `Dialog` aligned to the bottom (`showConfirmDialog`),
`AlertDialog` with a `Theme` override (member form), `showModalBottomSheet`,
`ListTile`, `CircleAvatar`, `Wrap` (SLA chips), `Tooltip`, `Material` +
`InkWell` (`AppCard`, `IconCircleButton`)

**Explain in the demo:** updating the status with `setState()` and saving it to
the database, why the status controls are disabled while saving, confirming
deletion with a dialog, counting each member's tasks by SLA status, and what
happens on sign out (the sign-out code itself is in Member 2's
`home_shell.dart`; this screen calls it).

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/task_details_screen.dart` | Task Details, status change, delete |
| `lib/screens/team_screen.dart` | Team Members, switch user, sign out |
| `lib/models/team_member.dart` | The TeamMember class |
| `lib/widgets/member_form_dialog.dart` | The add / edit member dialog |
| `lib/widgets/member_avatar.dart` | The circle with a member's initials |
| `lib/widgets/dialogs.dart` | Confirm dialog, snackbar message and empty state |
| `lib/widgets/app_card.dart` | Flat rounded card used on most screens |
| `lib/widgets/icon_circle_button.dart` | Round back / menu / sort / more button |

## How to push your part

Use **Git Bash** for these commands, not PowerShell. PowerShell's `>` changes
the file encoding and will break the copied files.

### Step 1 - Member 2 pushes the project setup

Do this once, before anyone else pushes. The destination repo already has the
Flutter project, but its `pubspec.yaml` is missing the packages the app uses.

```bash
cd ~/Desktop/sla-mobile-app-project      # your clone of the destination repo
git checkout main
git pull
git checkout -b yourname-project-setup

TRIAL=~/Desktop/sla-mobile-app-project-group32   # your clone of this repo
REF=6d8424b
git -C "$TRIAL" show "$REF:task_flow_sla/pubspec.yaml" > pubspec.yaml
git -C "$TRIAL" show "$REF:task_flow_sla/pubspec.lock" > pubspec.lock
```

The copied file is named after this repo's project, so change its first line
back to the destination project's name:

```bash
sed -i 's/^name: task_flow_sla$/name: sla_mobile_app/' pubspec.yaml
grep -n "^name:" pubspec.yaml      # must print: name: sla_mobile_app
git add pubspec.yaml pubspec.lock
git commit -m "Add sqflite, shared_preferences, intl and google_fonts dependencies"
git push -u origin yourname-project-setup
```

Open a pull request into `main` and merge it.

### Step 2 - Every member pushes their own files

All four members do this, including Member 2.

1. If you do not have this repo yet, clone it once:

   ```bash
   git clone https://github.com/solomon-211/sla-mobile-app-project-group32.git ~/Desktop/sla-mobile-app-project-group32
   ```

2. Get the latest destination `main` and create your own branch:

   ```bash
   cd ~/Desktop/sla-mobile-app-project
   git checkout main
   git pull
   git checkout -b yourname-yourfeature     # e.g. njunge-task-form
   ```

3. Copy **only the files in your table** from the finished redesign. Put your
   own paths in `FILES`; this example is Member 1's list:

   ```bash
   TRIAL=~/Desktop/sla-mobile-app-project-group32
   REF=6d8424b
   FILES="lib/screens/task_form_screen.dart lib/screens/register_screen.dart
          lib/utils/validators.dart lib/services/database_helper.dart
          lib/models/task.dart lib/models/task_activity.dart
          lib/data/seed_data.dart lib/widgets/pill_buttons.dart
          lib/widgets/password_toggle.dart"
   for f in $FILES; do
     mkdir -p "$(dirname "$f")"
     git -C "$TRIAL" show "$REF:task_flow_sla/$f" > "$f"
   done
   ```

4. If your table says a file is replaced, remove the old one, e.g.
   `git rm lib/screens/create_edit_task_screen.dart`.

   **Member 2 only:** the test file imports the app by its package name, which
   is different in the destination repo. Fix it after copying:

   ```bash
   sed -i 's/package:task_flow_sla\//package:sla_mobile_app\//' test/sla_test.dart
   ```

5. Read every file you are about to push. You will explain it in the demo, so
   make sure you can say what each widget and function does. Make your own
   changes where you want them (wording, spacing, comments, messages).

6. Check exactly what you are about to push:

   ```bash
   git status
   ```

   Only files from **your** table should appear. If you see someone else's
   file, do not add it.

7. Commit in small steps as you finish reading each part, not all at once.
   For example, Member 1:

   ```bash
   git add lib/models/task.dart lib/models/task_activity.dart
   git commit -m "Add Task and TaskActivity models"

   git add lib/utils/validators.dart
   git commit -m "Add validation rules for title, due date, email and password"

   git add lib/data/seed_data.dart lib/services/database_helper.dart
   git commit -m "Add sqflite database with demo data and password migration"

   git add lib/widgets/pill_buttons.dart lib/widgets/password_toggle.dart
   git commit -m "Add pill buttons and password toggle"

   git add lib/screens/task_form_screen.dart
   git rm lib/screens/create_edit_task_screen.dart
   git commit -m "Replace Create / Edit Task form with validated redesign"

   git add lib/screens/register_screen.dart
   git commit -m "Add Register screen with password strength and match checks"

   git push -u origin yourname-yourfeature
   ```

8. Open a pull request from your branch into `main`. Ask another member to
   review it, then merge.

### Step 3 - After the last merge

The app only builds once the project setup **and all four members' parts** are
in `main`, because the files import each other. Until then, errors about
missing files are expected. After the last merge, one person runs:

```bash
git checkout main
git pull
flutter pub get
flutter analyze     # should say "No issues found!"
flutter test        # should say "All tests passed!"
flutter run         # on an emulator or phone, not Chrome
```

## Rules to keep the history clean

- Never commit straight to `main`. Always use your own branch and a pull request.
- Commit from your own GitHub account. Commits made by someone else on your
  behalf count as their contribution, not yours.
- Push only your own files. If you need to change someone else's file, ask them
  or open a separate pull request that says why.
- Write commit messages that say what changed, e.g. "Add search to task list",
  not "update" or "fix".
- Record what you did in the group contribution tracker after each push.
- AI tools were used to write this code. Each member must review, test and be
  able to explain their own files, and the group's AI Usage Declaration must say
  so.
