import 'package:flutter/material.dart';

import '../app_router.dart';
import '../data/seed_data.dart';
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
    required this.members,
    required this.currentUser,
    required this.onChanged,
    required this.onShowTasks,
    required this.onOpenMenu,
  });

  final List<Task> tasks;
  final List<TeamMember> members;
  final TeamMember currentUser;

  /// Reloads the shared data after something was created or edited.
  final Future<void> Function() onChanged;

  /// Switches to the Tasks tab, optionally filtered by an SLA status.
  final ValueChanged<SlaStatus?> onShowTasks;

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
    final attention = tasks.where((task) {
      final status = Sla.statusOf(task, now: now);
      return status == SlaStatus.overdue || status == SlaStatus.atRisk;
    }).toList();

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
              user: currentUser,
              doneCount: counts[SlaStatus.completed]!,
              totalCount: tasks.length,
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
                        child: Text(
                          'Needs attention',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onShowTasks(null),
                        child: const Text('See all'),
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
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  for (final task in attention.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AttentionTile(
                        task: task,
                        assignee: members
                            .where((m) => m.id == task.assigneeId)
                            .firstOrNull,
                        status: Sla.statusOf(
                          task,
                          now: now,
                        ),
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

  Widget _buildCountCards(Map<SlaStatus, int> counts) {
    return GridView(
      // The grid sits inside a ListView, so it must size itself and leave
      // scrolling to the parent.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 76,
      ),
      children: [
        for (final status in SlaStatus.values)
          _CountCard(
            status: status,
            count: counts[status]!,
            onTap: () => onShowTasks(status),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.user,
    required this.doneCount,
    required this.totalCount,
  });

  final String greeting;
  final TeamMember user;
  final int doneCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;

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
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      seedProjectName,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
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
                    const Expanded(
                      child: Text(
                        'Project progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
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
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
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
            const Text(
              'Task overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
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
                              Expanded(child: Text(status.label)),
                              Text(
                                '${counts[status]}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          timeLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SlaStyle.of(status).foreground,
          ),
        ),
        trailing: SlaBadge(status: status),
      ),
    );
  }
}
