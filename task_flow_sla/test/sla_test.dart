import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow_sla/models/task.dart';
import 'package:task_flow_sla/models/team_member.dart';
import 'package:task_flow_sla/screens/dashboard_screen.dart';
import 'package:task_flow_sla/screens/task_list_screen.dart';
import 'package:task_flow_sla/theme/app_theme.dart';
import 'package:task_flow_sla/utils/sla.dart';
import 'package:task_flow_sla/utils/validators.dart';
import 'package:task_flow_sla/widgets/member_form_dialog.dart';

void main() {
  final now = DateTime(2026, 10, 5, 12);

  Task taskDue(
    Duration fromNow, {
    TaskStatus status = TaskStatus.inProgress,
    TaskPriority priority = TaskPriority.medium,
    DateTime? completedAt,
    Duration age = const Duration(days: 4),
  }) {
    return Task(
      title: 'Test task',
      category: 'QA',
      assigneeId: 1,
      dueDate: now.add(fromNow),
      priority: priority,
      status: status,
      createdAt: now.subtract(age),
      completedAt: completedAt,
    );
  }

  group('Sla.statusOf', () {
    test('a done task is Completed even after its deadline', () {
      final task = taskDue(const Duration(days: -3), status: TaskStatus.done);
      expect(Sla.statusOf(task, now: now), SlaStatus.completed);
    });

    test('an unfinished task past its deadline is Overdue', () {
      final task = taskDue(const Duration(minutes: -1));
      expect(Sla.statusOf(task, now: now), SlaStatus.overdue);
    });

    test('a task due exactly now is Overdue', () {
      expect(Sla.statusOf(taskDue(Duration.zero), now: now), SlaStatus.overdue);
    });

    test('medium priority: less than 48 hours left is At Risk', () {
      final task = taskDue(const Duration(hours: 47, minutes: 59));
      expect(Sla.statusOf(task, now: now), SlaStatus.atRisk);
    });

    test('medium priority: exactly 48 hours left is still On Track', () {
      final task = taskDue(const Duration(hours: 48));
      expect(Sla.statusOf(task, now: now), SlaStatus.onTrack);
    });

    test('the at-risk lead time depends on priority', () {
      // 30 hours left, created 30 days ago would trip the 75% rule, so use a
      // fresh task to test the lead time on its own.
      Task due30h(TaskPriority priority) => taskDue(
            const Duration(hours: 30),
            priority: priority,
            age: const Duration(hours: 1),
          );
      expect(Sla.statusOf(due30h(TaskPriority.low), now: now),
          SlaStatus.onTrack);
      expect(Sla.statusOf(due30h(TaskPriority.medium), now: now),
          SlaStatus.atRisk);
      expect(Sla.statusOf(due30h(TaskPriority.high), now: now),
          SlaStatus.atRisk);
    });

    test('75% of the time window used is At Risk, even far from deadline', () {
      // Created 15 days ago, due in 5 days: 75% used, 120 hours left.
      final task = taskDue(
        const Duration(days: 5),
        priority: TaskPriority.low,
        age: const Duration(days: 15),
      );
      expect(Sla.statusOf(task, now: now), SlaStatus.atRisk);
      expect(Sla.explain(task, now: now), contains('75%'));
    });

    test('explain names the rule that applied', () {
      final close = taskDue(
        const Duration(hours: 10),
        priority: TaskPriority.high,
        age: const Duration(hours: 1),
      );
      expect(Sla.explain(close, now: now), contains('72 hours'));
      expect(
        Sla.explain(taskDue(const Duration(days: 10)), now: now),
        startsWith('More than 48 hours remain'),
      );
    });
  });

  test('countByStatus counts every status, including empty ones', () {
    final counts = Sla.countByStatus([
      taskDue(const Duration(days: 5)),
      taskDue(const Duration(hours: 5)),
      taskDue(const Duration(hours: 6)),
      taskDue(const Duration(days: -1), status: TaskStatus.done),
    ], now: now);

    expect(counts[SlaStatus.onTrack], 1);
    expect(counts[SlaStatus.atRisk], 2);
    expect(counts[SlaStatus.overdue], 0);
    expect(counts[SlaStatus.completed], 1);
  });

  test('describe gives a readable time label', () {
    expect(Sla.describe(taskDue(const Duration(hours: 20)), now: now),
        'Due in 20 hours');
    expect(Sla.describe(taskDue(const Duration(days: -1)), now: now),
        '1 day late');
    final late = taskDue(
      const Duration(days: -2),
      status: TaskStatus.done,
      completedAt: now.subtract(const Duration(days: 1)),
    );
    expect(Sla.describe(late, now: now), 'Completed late');
  });

  test('onTimeRate is the share of completed tasks that met the deadline', () {
    expect(Sla.onTimeRate([taskDue(const Duration(days: 1))]), isNull);
    final onTime = taskDue(
      const Duration(days: -2),
      status: TaskStatus.done,
      completedAt: now.subtract(const Duration(days: 3)),
    );
    final late = taskDue(
      const Duration(days: -2),
      status: TaskStatus.done,
      completedAt: now.subtract(const Duration(days: 1)),
    );
    expect(Sla.onTimeRate([onTime, late, taskDue(const Duration(days: 1))]),
        0.5);
  });

  test('timeUsed is the share of the creation-to-deadline window', () {
    // Created 4 days ago, due in 4 days: half the window is used.
    expect(Sla.timeUsed(taskDue(const Duration(days: 4)), now: now), 0.5);
    expect(Sla.timeUsed(taskDue(const Duration(days: -1)), now: now), 1.0);
  });

  test('withStatus keeps completedAt in sync', () {
    final done = taskDue(const Duration(days: 1))
        .withStatus(TaskStatus.done, now: now);
    expect(done.completedAt, now);
    expect(done.withStatus(TaskStatus.inProgress).completedAt, isNull);
  });

  group('Validators', () {
    test('task title gives a specific message for each problem', () {
      expect(Validators.taskTitle(''), 'Title is required');
      expect(Validators.taskTitle('  ab  '),
          'Title must be at least 3 characters');
      expect(Validators.taskTitle('abc'), isNull);
      expect(Validators.taskTitle('a' * 60), isNull);
      expect(Validators.taskTitle('a' * 61),
          'Title must be at most 60 characters');
    });

    test('due date must be in the future unless unchanged', () {
      final past = now.subtract(const Duration(days: 1));
      expect(Validators.dueDate(null, now: now), isNotNull);
      expect(Validators.dueDate(past, now: now), isNotNull);
      expect(Validators.dueDate(past, original: past, now: now), isNull);
      expect(
        Validators.dueDate(now.add(const Duration(hours: 1)), now: now),
        isNull,
      );
    });

    test('requiredText checks min and max length', () {
      expect(Validators.requiredText(' ', 'Name'), 'Name is required');
      expect(Validators.requiredText('ab', 'Project name', min: 3),
          'Project name must be at least 3 characters');
      expect(Validators.requiredText('abcdef', 'Name', max: 5),
          'Name must be at most 5 characters');
    });

    test('email and password', () {
      expect(Validators.email('amina@devteam.app'), isNull);
      expect(Validators.email('amina@devteam'), isNotNull);
      expect(Validators.email(' '), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Widgets', () {
    const amina = TeamMember(
      id: 1,
      name: 'Amina K.',
      role: 'Project Manager',
      email: 'amina@devteam.app',
    );

    // Widget tests use the real clock, so build tasks relative to it.
    Task liveTask(String title, Duration dueIn) {
      final current = DateTime.now();
      return Task(
        title: title,
        category: 'QA',
        assigneeId: 1,
        dueDate: current.add(dueIn),
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        createdAt: current.subtract(const Duration(hours: 1)),
      );
    }

    Widget app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

    testWidgets('dashboard cards open the Tasks tab with a filter',
        (tester) async {
      Set<SlaStatus>? requested;
      await tester.pumpWidget(app(DashboardScreen(
        tasks: [
          liveTask('Late task', const Duration(days: -1)),
          liveTask('Later task', const Duration(days: 10)),
        ],
        membersById: const {1: amina},
        currentUser: amina,
        projectName: 'Test project',
        onRenameProject: () {},
        onChanged: () async {},
        onShowTasks: (filter) => requested = filter,
        onOpenMenu: () {},
      )));

      // The first "Overdue" text is the count card.
      await tester.tap(find.text('Overdue').first);
      expect(requested, {SlaStatus.overdue});

      await tester.ensureVisible(find.text('See all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See all'));
      expect(requested, Sla.needsAttention);
    });

    testWidgets('task list shows only tasks matching the filter',
        (tester) async {
      Set<SlaStatus>? changedTo;
      await tester.pumpWidget(app(TaskListScreen(
        tasks: [
          liveTask('Late task', const Duration(days: -1)),
          liveTask('Later task', const Duration(days: 10)),
        ],
        membersById: const {1: amina},
        filter: const {SlaStatus.overdue},
        onFilterChanged: (filter) => changedTo = filter,
        onChanged: () async {},
        onOpenMenu: () {},
      )));

      expect(find.text('Late task'), findsOneWidget);
      expect(find.text('Later task'), findsNothing);

      await tester.tap(find.text('On Track (1)'));
      expect(changedTo, {SlaStatus.onTrack});
    });

    testWidgets('member dialog shows validation errors', (tester) async {
      await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
          onPressed: () => showMemberFormDialog(
            context,
            takenEmails: const ['amina@devteam.app'],
            askPassword: true,
          ),
          child: const Text('Open'),
        ),
      )));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Role is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'Amina@devteam.app',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(
        find.text('Another member already uses this email'),
        findsOneWidget,
      );
    });
  });
}
