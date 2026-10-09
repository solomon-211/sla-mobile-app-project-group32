import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';
import '../widgets/donut_chart.dart';
import '../widgets/member_avatar.dart';
import '../widgets/status_widgets.dart';

/// Project Dashboard: progress, SLA counts, status chart and the tasks that
/// need attention.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.tasks,
    required this.membersById,
    required this.currentUser,
    required this.projectName,
    required this.onRenameProject,
    required this.onChanged,
    required this.onShowTasks,
    required this.onOpenMenu,
  });

  final List<Task> tasks;
  final Map<int, TeamMember> membersById;
  final TeamMember currentUser;
  final String projectName;

  /// Opens the rename dialog owned by HomeShell.
  final VoidCallback onRenameProject;

  /// Reloads the shared data after something was created or edited.
  final Future<void> Function() onChanged;

  /// Switches to the Tasks tab filtered to the given SLA statuses
  /// (null shows every task).
  final ValueChanged<Set<SlaStatus>?> onShowTasks;

  /// Opens the navigation drawer owned by HomeShell.
  final VoidCallback onOpenMenu;

  Future<void> _open(BuildContext context, String route, [Object? args]) async {
    await Navigator.pushNamed(context, route, arguments: args);
    await onChanged();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final counts = Sla.countByStatus(tasks, now: now);

    // "Needs attention" = overdue or at risk. Tasks arrive sorted by
    // deadline, so the most urgent ones come first.
    final attention = tasks
        .where((task) => Sla.needsAttention.contains(Sla.statusOf(task, now: now)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: onOpenMenu,
        ),
        actions: [
          IconButton(
            tooltip: 'New task',
            icon: const Icon(Icons.add),
            onPressed: () => _open(context, AppRoutes.taskForm),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onChanged,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(
              greeting: '$_greeting, ${currentUser.firstName}',
              projectName: projectName,
              onRenameProject: onRenameProject,
              user: currentUser,
              doneCount: counts[SlaStatus.completed]!,
              totalCount: tasks.length,
              onTimeRate: Sla.onTimeRate(tasks),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCountCards(counts),
                  const SizedBox(height: 16),
                  _OverviewCard(counts: counts, total: tasks.length),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Needs attention', style: AppText.section),
                      ),
                      TextButton(
                        onPressed: () => onShowTasks(Sla.needsAttention),
                        child: Text(
                          attention.length > 3
                              ? 'See all ${attention.length}'
                              : 'See all',
                        ),
                      ),
                    ],
                  ),
                  if (attention.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Nothing is overdue or at risk. Nice work!',
                          textAlign: TextAlign.center,
                          style: AppText.bodyMuted,
                        ),
                      ),
                    ),
                  for (final task in attention.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AttentionTile(
                        task: task,
                        assignee: membersById[task.assigneeId],
                        status: Sla.statusOf(task, now: now),
                        timeLabel: Sla.describe(task, now: now),
                        onTap: () =>
                            _open(context, AppRoutes.taskDetails, task.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two rows of two cards. IntrinsicHeight makes both cards in a row as tall
  /// as the taller one, and lets them grow with large system font sizes
  /// instead of overflowing a fixed height.
  Widget _buildCountCards(Map<SlaStatus, int> counts) {
    Widget card(SlaStatus status) {
      return Expanded(
        child: _CountCard(
          status: status,
          count: counts[status]!,
          onTap: () => onShowTasks({status}),
        ),
      );
    }

    Widget row(SlaStatus left, SlaStatus right) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [card(left), const SizedBox(width: 12), card(right)],
        ),
      );
    }

    return Column(
      children: [
        row(SlaStatus.onTrack, SlaStatus.atRisk),
        const SizedBox(height: 12),
        row(SlaStatus.overdue, SlaStatus.completed),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.projectName,
    required this.onRenameProject,
    required this.user,
    required this.doneCount,
    required this.totalCount,
    required this.onTimeRate,
  });

  final String greeting;
  final String projectName;
  final VoidCallback onRenameProject;
  final TeamMember user;
  final int doneCount;
  final int totalCount;

  /// Share of completed tasks finished by their deadline, null if none yet.
  final double? onTimeRate;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;
    final onTime = onTimeRate;
    const white70 = TextStyle(color: Colors.white70);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Text(
                  user.initials,
                  style: AppText.bodyStrong.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading.copyWith(color: Colors.white),
                    ),
                    InkWell(
                      onTap: onRenameProject,
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.merge(white70),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.white70,
                            semanticLabel: 'Rename project',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Project progress',
                        style: AppText.bodyStrong.copyWith(color: Colors.white),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppText.bodyStrong.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(height: 10),
                Text(
                  '$doneCount of $totalCount tasks completed',
                  style: AppText.caption.merge(white70),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        onTime == null
                            ? 'On-time rate appears once a task is completed'
                            : '${(onTime * 100).round()}% of completed tasks '
                                'met their deadline',
                        style: AppText.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.status,
    required this.count,
    required this.onTap,
  });

  final SlaStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(status);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(style.icon, color: style.foreground, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$count', style: AppText.heading),
                    Text(
                      status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.counts, required this.total});

  final Map<SlaStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task overview', style: AppText.section),
            const SizedBox(height: 14),
            Row(
              children: [
                DonutChart(
                  centerValue: '$total',
                  centerLabel: 'tasks',
                  segments: [
                    for (final status in SlaStatus.values)
                      DonutSegment(counts[status]!, SlaStyle.of(status).color),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final status in SlaStatus.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 5,
                                backgroundColor: SlaStyle.of(status).color,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(status.label, style: AppText.body),
                              ),
                              Text(
                                '${counts[status]}',
                                style: AppText.bodyStrong,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.task,
    required this.assignee,
    required this.status,
    required this.timeLabel,
    required this.onTap,
  });

  final Task task;
  final TeamMember? assignee;
  final SlaStatus status;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: MemberAvatar(member: assignee, radius: 18),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.bodyStrong,
        ),
        subtitle: Text(
          timeLabel,
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: SlaStyle.of(status).foreground,
          ),
        ),
        trailing: SlaBadge(status: status),
      ),
    );
  }
}
