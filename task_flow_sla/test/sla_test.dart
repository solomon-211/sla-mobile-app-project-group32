import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow_sla/models/task.dart';
import 'package:task_flow_sla/utils/sla.dart';
import 'package:task_flow_sla/utils/validators.dart';

void main() {
  final now = DateTime(2026, 10, 5, 12);

  Task taskDue(
    Duration fromNow, {
    TaskStatus status = TaskStatus.inProgress,
    DateTime? completedAt,
  }) {
    return Task(
      title: 'Test task',
      category: 'QA',
      assigneeId: 1,
      dueDate: now.add(fromNow),
      priority: TaskPriority.medium,
      status: status,
      createdAt: now.subtract(const Duration(days: 4)),
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

    test('less than 48 hours left is At Risk', () {
      final task = taskDue(const Duration(hours: 47, minutes: 59));
      expect(Sla.statusOf(task, now: now), SlaStatus.atRisk);
    });

    test('exactly 48 hours left is still On Track', () {
      final task = taskDue(const Duration(hours: 48));
      expect(Sla.statusOf(task, now: now), SlaStatus.onTrack);
    });

    test('the at-risk window can be changed', () {
      final task = taskDue(const Duration(hours: 30));
      expect(Sla.statusOf(task, atRiskHours: 24, now: now), SlaStatus.onTrack);
      expect(Sla.statusOf(task, atRiskHours: 72, now: now), SlaStatus.atRisk);
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
    test('task title must be 3-60 characters', () {
      expect(Validators.taskTitle(''), isNotNull);
      expect(Validators.taskTitle('  ab  '), isNotNull);
      expect(Validators.taskTitle('abc'), isNull);
      expect(Validators.taskTitle('a' * 60), isNull);
      expect(Validators.taskTitle('a' * 61), isNotNull);
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

    test('email and password', () {
      expect(Validators.email('amina@devteam.app'), isNull);
      expect(Validators.email('amina@devteam'), isNotNull);
      expect(Validators.email(' '), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });
}
