# SprintTrack - Group 32

Project & SLA task tracker for a small software team, built with Flutter.
The app lives in [`task_flow_sla/`](task_flow_sla/). How the app works (screens,
SLA rules, storage, how to run it) is in
[`task_flow_sla/README.md`](task_flow_sla/README.md).

This page is for the team: **who owns which files, and how to push your part.**

## Who owns what

Each member has one section below with everything assigned to them: their
screens, their tasks, the widgets they must be able to explain, what they
present in the demo, and the files they push. Every file in the project belongs
to exactly one member. All paths are inside `task_flow_sla/`.

Tick the boxes as you finish each task (edit this file in your own branch).

### Everyone

- [ ] Read your own files until you can explain every widget and function
- [ ] Work only on your own branch and merge through a pull request
- [ ] Review at least one other member's pull request
- [ ] Take part in the 10-15 minute recorded demo and present your own part
- [ ] Add what you reviewed, tested and changed to the AI Usage Declaration

### Member 1 - Create / Edit Task, validation, sqflite

**Screen:** Create / Edit Task

**Tasks**

- [ ] Own the Create / Edit Task form: title, description, category, assignee,
      due date and time, priority, status
- [ ] Own the validation rules and the error messages shown under each field
- [ ] Own the sqflite database: the three tables, and how tasks, members and
      task history are saved, updated and deleted
- [ ] Own the Task model and the demo data inserted on first launch
- [ ] Test on the emulator: create a task, edit it, try to save an empty title
      and a past due date, close and reopen the app to confirm the task is saved
- [ ] Push the files below from your own branch and open a pull request
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `Form` with `GlobalKey<FormState>`,
`TextFormField`, `DropdownButtonFormField`, `FormField`, `showDatePicker`,
`showTimePicker`, `SegmentedButton`

**Explain in the demo:** the validation rules (title required and 3-60
characters, due date must be in the future, assignee required), why the group
chose sqflite, and how a task travels from the form into the database.

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/task_form_screen.dart` | The Create / Edit Task form |
| `lib/utils/validators.dart` | Validation rules (title, due date, email, password) |
| `lib/services/database_helper.dart` | The sqflite database: tables, queries, saving |
| `lib/models/task.dart` | The Task class, priorities and statuses |
| `lib/models/task_activity.dart` | One line of a task's history |
| `lib/data/seed_data.dart` | Demo members and tasks inserted on first launch |

### Member 2 - Dashboard, SLA logic, navigation

**Screen:** Project Dashboard

**Tasks**

- [ ] Push the empty project setup first (step 1 below)
- [ ] Own the Dashboard: greeting, progress bar, four SLA count cards, donut
      chart and the "Needs attention" list
- [ ] Own the SLA rules that decide On Track, At Risk, Overdue and Completed
- [ ] Own navigation: named routes, the bottom navigation bar and the drawer
- [ ] Own the app theme (colours, buttons, inputs) and the app entry point
- [ ] Own the unit tests for the SLA rules; run `flutter test`
- [ ] Test on the emulator: every tab, the drawer, the Back button, and that
      the counts change after a task is marked as done
- [ ] Push the files below from your own branch and open a pull request
- [ ] Run the final checks after the last merge (step 3 below)
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `ListView`, `GridView`, `Card`,
`LinearProgressIndicator`, `CustomPaint` (donut chart), `BottomNavigationBar`,
`Drawer`, `PopScope`

**Explain in the demo:** how the counts are calculated from the SLA rules, the
48-hour At Risk rule and why the group chose it, how the routes, bottom
navigation and drawer connect the screens, and how `HomeShell` shares data with
the tabs using `setState()`.

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/dashboard_screen.dart` | The Project Dashboard |
| `lib/utils/sla.dart` | The SLA rules (On Track, At Risk, Overdue, Completed) |
| `lib/app_router.dart` | Named routes between screens |
| `lib/screens/home_shell.dart` | Bottom navigation and the data shared by the tabs |
| `lib/widgets/app_drawer.dart` | The side menu (drawer) |
| `lib/widgets/donut_chart.dart` | The donut chart on the Dashboard |
| `lib/widgets/status_widgets.dart` | SLA badge, SLA colours and priority colours |
| `lib/main.dart` | App entry point |
| `lib/theme/app_theme.dart` | Colours and theme for the whole app |
| `test/sla_test.dart` | Unit tests for the SLA rules and validators |
| Project setup (see step 1) | `pubspec.yaml`, platform folders, both README files |

### Member 3 - Task List, Sign In

**Screens:** Task List, Sign In / User Selection

**Tasks**

- [ ] Own the Task List: search bar, SLA filter chips, sorting by deadline, the
      "Needs attention", "Upcoming" and "Completed" groups, and the + button
- [ ] Own the task card and its menu (Edit, Mark as done, Delete)
- [ ] Own Sign In: email and password fields, show-password toggle,
      "Remember me", "Forgot password?", tap-a-member sign in, Create account
- [ ] Own saving the signed-in user with SharedPreferences
- [ ] Own the shared confirm dialog, snackbar message and empty-list view
- [ ] Test on the emulator: search, each filter chip, sign in with a wrong
      email, sign in with "Remember me" on and off then reopen the app
- [ ] Push the files below from your own branch and open a pull request
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `TextField`, `FilterChip`,
`ListView.builder`, `Card`, `PopupMenuButton`, `FloatingActionButton`,
`TextFormField`, `Checkbox`, `ElevatedButton`, `CircleAvatar`

**Explain in the demo:** the search and filter logic, using `setState()` to
rebuild the list when a chip is tapped, saving the signed-in user with
SharedPreferences, and moving to the Dashboard with
`Navigator.pushReplacementNamed`.

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/task_list_screen.dart` | The Task List with search and filter chips |
| `lib/screens/sign_in_screen.dart` | Sign In / User Selection |
| `lib/widgets/task_card.dart` | One task card in the list |
| `lib/services/session_service.dart` | Saves the signed-in user (SharedPreferences) |
| `lib/widgets/dialogs.dart` | Confirm dialog, snackbar message and empty-list view |
| `lib/utils/formatters.dart` | Date formatting used on the task cards |

### Member 4 - Task Details, Team Members

**Screens:** Task Details, Team Members

**Tasks**

- [ ] Own Task Details: title, category, task ID, description, assignee, due
      date, priority, status dropdown, SLA card with the time-used bar, activity
      history, Edit Task and Mark as Done / Reopen
- [ ] Own deleting a task with a confirmation dialog
- [ ] Own Team Members: the signed-in card, Switch user, Sign out, and the
      member list with task counts and SLA badges
- [ ] Own adding, editing and removing a member, including the member form
- [ ] Own the TeamMember model and the member avatar
- [ ] Test on the emulator: change a task's status, mark it done and reopen it,
      delete a task, add a member with a duplicate email, switch user, sign out
- [ ] Push the files below from your own branch and open a pull request
- [ ] Fill in your row of the contribution tracker

**Widgets to be able to explain:** `DropdownButton`, `LinearProgressIndicator`,
`OutlinedButton`, `ElevatedButton`, `AlertDialog`, `Card`, `ListView`,
`ListTile`, `CircleAvatar`, `showModalBottomSheet`

**Explain in the demo:** updating the status with `setState()` and saving it to
the database, confirming deletion with a dialog, counting each member's tasks
by SLA status, and what happens on sign out (the sign-out code itself is in
Member 2's `home_shell.dart`; this screen calls it).

**Files to push**

| File | What it is |
| --- | --- |
| `lib/screens/task_details_screen.dart` | Task Details, status change, delete |
| `lib/screens/team_screen.dart` | Team Members, switch user, sign out |
| `lib/widgets/member_form_dialog.dart` | The add / edit member dialog |
| `lib/models/team_member.dart` | The TeamMember class |
| `lib/widgets/member_avatar.dart` | The circle with a member's initials |

Some of these files are used on other members' screens too (for example the
theme, the models and `dialogs.dart`). The owner is the person who pushes the
file and explains it in the demo. If you need a change in a file you do not
own, ask its owner.

## How to push your part

### Step 1 - Member 2 pushes the empty project setup

Do this once, before anyone else pushes. It adds the Flutter project itself
(`pubspec.yaml`, the `android/`, `ios/`, `web/`, `windows/`, `linux/` and
`macos/` folders, and the README files) but none of the Dart code in `lib/` or
`test/`. Run from the repository root:

```bash
git checkout -b project-setup
git add README.md task_flow_sla

# Leave all the Dart code out of this commit
git restore --staged task_flow_sla/lib task_flow_sla/test

git status          # check: nothing under lib/ or test/ is listed as staged
git commit -m "Add Flutter project setup and team README"
git push -u origin project-setup
```

Open a pull request from `project-setup` into `main` on GitHub and merge it.

### Step 2 - Every member pushes their own files

All four members do this, including Member 2.

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
   git add task_flow_sla/lib/models/task.dart task_flow_sla/lib/models/task_activity.dart
   git commit -m "Add Task and TaskActivity models"

   git add task_flow_sla/lib/utils/validators.dart
   git commit -m "Add validation rules for task title and due date"

   git add task_flow_sla/lib/data/seed_data.dart task_flow_sla/lib/services/database_helper.dart
   git commit -m "Add sqflite database helper with demo data"

   git add task_flow_sla/lib/screens/task_form_screen.dart
   git commit -m "Add Create / Edit Task form with validation"

   git push -u origin yourname-yourfeature
   ```

6. Open a pull request from your branch into `main`. Ask another member to
   review it, then merge.

### Step 3 - After the last merge

The app only builds once the project setup **and all four members' parts** are
in `main`, because the files import each other. Until then, errors about
missing files are expected. After the last merge, one person runs:

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
