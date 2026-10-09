import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_router.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';
import '../widgets/app_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/icon_circle_button.dart';
import '../widgets/member_avatar.dart';
import '../widgets/status_widgets.dart';

/// Project Dashboard (dark screen): progress, SLA counts, status chart and
/// the tasks that need attention. All numbers come from the SLA rules.
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

  /// Opens the navigation drawer owned by HomeShell (tap the avatar).
  final VoidCallback onOpenMenu;

  /// Number of segments in the progress bar.
  static const _progressBars = 21;

  Future<void> _open(BuildContext context, String route, [Object? args]) async {
    await Navigator.pushNamed(context, route, arguments: args);
    await onChanged();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final counts = Sla.countByStatus(tasks, now: now);

    // "Needs attention" = overdue or at risk. Tasks arrive sorted by
    // deadline, so the most urgent ones come first.
    final attention = tasks
        .where(
          (task) => Sla.needsAttention.contains(Sla.statusOf(task, now: now)),
        )
        .toList();

    // Light status bar icons on the dark background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.inkDeep,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: onChanged,
            color: AppColors.ink,
            // A fixed set of sections, so a plain Column is built in full.
            // AlwaysScrollable keeps pull-to-refresh working on tall phones.
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Bottom padding keeps the last card clear of the floating nav.
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _ProgressCard(
                    doneCount: counts[SlaStatus.completed]!,
                    totalCount: tasks.length,
                    bars: _progressBars,
                  ),
                  const SizedBox(height: 16),
                  _buildTiles(counts),
                  const SizedBox(height: 16),
                  _OverviewCard(
                    counts: counts,
                    total: tasks.length,
                    onTimeRate: Sla.onTimeRate(tasks),
                  ),
                  const SizedBox(height: 16),
                  _buildAttention(context, attention, now),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Menu',
          child: InkWell(
            onTap: onOpenMenu,
            customBorder: const CircleBorder(),
            child: MemberAvatar(member: currentUser, radius: 24, filled: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: AppText.manrope(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.textMutedDark,
                ),
              ),
              Text(
                currentUser.firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.manrope(
                  17,
                  weight: FontWeight.w800,
                  color: AppColors.paper,
                ),
              ),
            ],
          ),
        ),
        IconCircleButton(
          icon: Icons.add_rounded,
          tooltip: 'Create task',
          background: AppColors.paper,
          onPressed: () => _open(context, AppRoutes.taskForm),
        ),
      ],
    );
  }

  /// Project name as the screen title. Tapping it renames the project.
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        hint: 'Rename project',
        child: InkWell(
          onTap: onRenameProject,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  projectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sora(
                    30,
                    color: AppColors.paper,
                    height: 36,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textMutedDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2x2 SLA count tiles. IntrinsicHeight keeps both tiles in a row the same
  /// height, and lets them grow with large system font sizes.
  Widget _buildTiles(Map<SlaStatus, int> counts) {
    Widget tile(SlaStatus status) {
      return Expanded(
        child: _SlaTile(
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
          children: [tile(left), const SizedBox(width: 12), tile(right)],
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

  Widget _buildAttention(
    BuildContext context,
    List<Task> attention,
    DateTime now,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Needs attention',
                  style: AppText.section(color: AppColors.paper),
                ),
              ),
              TextButton(
                onPressed: () => onShowTasks(Sla.needsAttention),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mossLight,
                ),
                child: Text(
                  attention.length > 3
                      ? 'See all ${attention.length}'
                      : 'See all',
                  style: AppText.manrope(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.mossLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (attention.isEmpty)
          AppCard(
            color: AppColors.darkCard,
            borderColor: AppColors.darkBorder,
            radius: 22,
            padding: const EdgeInsets.all(20),
            child: Text(
              'Nothing is overdue or at risk. Nice work!',
              textAlign: TextAlign.center,
              style: AppText.manrope(
                14,
                weight: FontWeight.w600,
                color: AppColors.textMutedDark,
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
              onTap: () => _open(context, AppRoutes.taskDetails, task.id),
            ),
          ),
      ],
    );
  }
}

/// Light card with the big progress number and a 21-segment bar. The bar
/// fills in proportion to progress, so it works for any number of tasks.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.doneCount,
    required this.totalCount,
    required this.bars,
  });

  final int doneCount;
  final int totalCount;
  final int bars;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;
    final filled = (progress * bars).round();
    final percent = (progress * 100).round();

    return AppCard(
      color: AppColors.paper,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project progress',
                      style: AppText.label(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$percent%',
                      style: AppText.sora(48, height: 52, letterSpacing: -2),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$doneCount',
                      children: [
                        TextSpan(
                          text: '/$totalCount',
                          style: AppText.sora(
                            16,
                            color: const Color(0xFF7D8280),
                          ),
                        ),
                      ],
                    ),
                    style: AppText.sora(22),
                  ),
                  Text(
                    'tasks completed',
                    style: AppText.manrope(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: '$percent% of tasks completed',
            excludeSemantics: true,
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  for (var i = 0; i < bars; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i < filled
                              ? AppColors.ink
                              : AppColors.barEmpty,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the four SLA count tiles. On Track is the moss accent tile; the
/// others are dark cards with a coloured icon.
class _SlaTile extends StatelessWidget {
  const _SlaTile({
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
    final accent = status == SlaStatus.onTrack;

    return AppCard(
      color: accent ? AppColors.moss : AppColors.darkCard,
      borderColor: accent ? null : AppColors.darkBorder,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent ? AppColors.onMoss : style.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  style.icon,
                  size: 18,
                  color: accent ? AppColors.moss : AppColors.ink,
                ),
              ),
              if (accent)
                const Icon(
                  Icons.north_east_rounded,
                  size: 18,
                  color: AppColors.onMoss,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: AppText.sora(
                  32,
                  height: 36,
                  color: accent ? AppColors.onMoss : AppColors.paper,
                ),
              ),
              Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  color: accent ? AppColors.onMoss : style.onDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.counts,
    required this.total,
    required this.onTimeRate,
  });

  final Map<SlaStatus, int> counts;
  final int total;

  /// Share of completed tasks that met their deadline, null if none yet.
  final double? onTimeRate;

  @override
  Widget build(BuildContext context) {
    final onTime = onTimeRate;

    return AppCard(
      color: AppColors.darkCard,
      borderColor: AppColors.darkBorder,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Task overview',
                  style: AppText.cardTitle(color: AppColors.paper),
                ),
              ),
              if (onTime != null)
                Tooltip(
                  message: 'Completed tasks that met their deadline',
                  child: StatusPill(
                    label: '${(onTime * 100).round()}% on time',
                    background: AppColors.darkNav,
                    foreground: AppColors.textMutedDark,
                  ),
                ),
            ],
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
                        padding: const EdgeInsets.symmetric(vertical: 4.5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: SlaStyle.of(status).color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status.label,
                                style: AppText.manrope(
                                  13,
                                  weight: FontWeight.w600,
                                  color: AppColors.paper,
                                ),
                              ),
                            ),
                            Text(
                              '${counts[status]}',
                              style: AppText.manrope(
                                13,
                                weight: FontWeight.w800,
                                color: AppColors.paper,
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
    return AppCard(
      color: AppColors.darkCard,
      borderColor: AppColors.darkBorder,
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          MemberAvatar(member: assignee, onDark: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.manrope(
                    15,
                    weight: FontWeight.w700,
                    color: AppColors.paper,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: AppText.manrope(
                    13,
                    weight: FontWeight.w600,
                    color: SlaStyle.of(status).onDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SlaBadge(status: status),
        ],
      ),
    );
  }
}
