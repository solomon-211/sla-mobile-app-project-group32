import '../models/task.dart';

enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  const SlaStatus(this.label);
  final String label;
}

/// The SLA business rules. Kept free of Flutter imports so the rules can be
/// unit tested and explained on their own.
class Sla {
  /// Once this share of the creation-to-deadline window is used, an
  /// unfinished task is At Risk no matter how much time is left.
  static const atRiskWindowShare = 0.75;

  /// The statuses shown under "Needs attention".
  static const needsAttention = {SlaStatus.overdue, SlaStatus.atRisk};

  /// How close to the deadline a task becomes At Risk. Important work gets
  /// flagged earlier so there is still time to react.
  static Duration atRiskLeadTime(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Duration(hours: 72);
      case TaskPriority.medium:
        return const Duration(hours: 48);
      case TaskPriority.low:
        return const Duration(hours: 24);
    }
  }

  /// Rules, checked in this order:
  /// 1. Completed - the task status is Done.
  /// 2. Overdue   - not done and the deadline has passed.
  /// 3. At Risk   - not done and either
  ///    a. less than [atRiskLeadTime] is left for its priority, or
  ///    b. [atRiskWindowShare] (75%) or more of its time window is used.
  /// 4. On Track  - everything else.
  static SlaStatus statusOf(Task task, {DateTime? now}) {
    if (task.isDone) return SlaStatus.completed;

    final current = now ?? DateTime.now();
    if (!task.dueDate.isAfter(current)) return SlaStatus.overdue;

    if (_closeToDeadline(task, current) ||
        timeUsed(task, now: current) >= atRiskWindowShare) {
      return SlaStatus.atRisk;
    }
    return SlaStatus.onTrack;
  }

  static bool _closeToDeadline(Task task, DateTime now) {
    return task.dueDate.difference(now) < atRiskLeadTime(task.priority);
  }

  /// One sentence explaining why the task has its status.
  static String explain(Task task, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final leadHours = atRiskLeadTime(task.priority).inHours;
    final priority = task.priority.label;
    final share = (atRiskWindowShare * 100).round();

    switch (statusOf(task, now: current)) {
      case SlaStatus.completed:
        return 'This task is done, so it no longer counts against the SLA.';
      case SlaStatus.overdue:
        return 'The deadline has passed and the task is not done.';
      case SlaStatus.atRisk:
        return _closeToDeadline(task, current)
            ? '$priority priority tasks become At Risk inside $leadHours '
                'hours of the deadline.'
            : '$share% or more of the time window is used.';
      case SlaStatus.onTrack:
        return 'More than $leadHours hours remain and less than $share% of '
            'the time window is used.';
    }
  }

  /// How many tasks fall under each status. Every status is always present.
  static Map<SlaStatus, int> countByStatus(
    Iterable<Task> tasks, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final counts = {for (final status in SlaStatus.values) status: 0};
    for (final task in tasks) {
      final status = statusOf(task, now: current);
      counts[status] = counts[status]! + 1;
    }
    return counts;
  }

  /// Fraction (0 to 1) of the window between creation and deadline that has
  /// been used. For finished tasks the clock stops at the completion time.
  static double timeUsed(Task task, {DateTime? now}) {
    final end = task.completedAt ?? now ?? DateTime.now();
    final window = task.dueDate.difference(task.createdAt).inSeconds;
    if (window <= 0) return 1;
    final used = end.difference(task.createdAt).inSeconds;
    return (used / window).clamp(0.0, 1.0);
  }

  /// True when a finished task was completed by its deadline.
  static bool completedOnTime(Task task) {
    final completedAt = task.completedAt;
    return completedAt == null || !completedAt.isAfter(task.dueDate);
  }

  /// Share (0 to 1) of completed tasks that met their deadline, or null when
  /// nothing has been completed yet.
  static double? onTimeRate(Iterable<Task> tasks) {
    final done = tasks.where((task) => task.isDone).toList();
    if (done.isEmpty) return null;
    return done.where(completedOnTime).length / done.length;
  }

  /// Short text such as "Due in 20 hours", "1 day late" or "Completed on time".
  static String describe(Task task, {DateTime? now}) {
    if (task.isDone) {
      return completedOnTime(task) ? 'Completed on time' : 'Completed late';
    }
    final current = now ?? DateTime.now();
    if (!task.dueDate.isAfter(current)) {
      return '${_humanize(current.difference(task.dueDate))} late';
    }
    return 'Due in ${_humanize(task.dueDate.difference(current))}';
  }

  static String _humanize(Duration duration) {
    if (duration.inMinutes < 60) {
      return _plural(duration.inMinutes < 1 ? 1 : duration.inMinutes, 'minute');
    }
    if (duration.inHours < 24) return _plural(duration.inHours, 'hour');
    return _plural(duration.inDays, 'day');
  }

  static String _plural(int count, String unit) {
    return count == 1 ? '1 $unit' : '$count ${unit}s';
  }
}
