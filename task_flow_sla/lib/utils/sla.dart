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
  static const defaultAtRiskHours = 48;

  /// Rules, checked in this order:
  /// 1. Completed - the task status is Done.
  /// 2. Overdue   - not done and the deadline has passed.
  /// 3. At Risk   - not done and the deadline is less than [atRiskHours] away.
  /// 4. On Track  - everything else.
  static SlaStatus statusOf(
    Task task, {
    int atRiskHours = defaultAtRiskHours,
    DateTime? now,
  }) {
    if (task.isDone) return SlaStatus.completed;

    final current = now ?? DateTime.now();
    if (!task.dueDate.isAfter(current)) return SlaStatus.overdue;

    final timeLeft = task.dueDate.difference(current);
    if (timeLeft < Duration(hours: atRiskHours)) return SlaStatus.atRisk;

    return SlaStatus.onTrack;
  }

  /// How many tasks fall under each status. Every status is always present.
  static Map<SlaStatus, int> countByStatus(
    Iterable<Task> tasks, {
    int atRiskHours = defaultAtRiskHours,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final counts = {for (final status in SlaStatus.values) status: 0};
    for (final task in tasks) {
      final status = statusOf(task, atRiskHours: atRiskHours, now: current);
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

  /// Short text such as "Due in 20 hours", "1 day late" or "Completed on time".
  static String describe(Task task, {DateTime? now}) {
    if (task.isDone) {
      final completedAt = task.completedAt;
      final late = completedAt != null && completedAt.isAfter(task.dueDate);
      return late ? 'Completed late' : 'Completed on time';
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
