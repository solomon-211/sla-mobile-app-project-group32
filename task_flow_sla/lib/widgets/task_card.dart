import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/sla.dart';
import 'member_avatar.dart';
import 'status_widgets.dart';

enum TaskCardAction { edit, markDone, delete }

/// One task in the task list: assignee, title, category, priority, due date
/// and SLA badge, with a menu for quick actions. Overdue tasks use a dark
/// card so they stand out.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.assignee,
    required this.slaStatus,
    required this.onTap,
    required this.onAction,
  });

  final Task task;
  final TeamMember? assignee;
  final SlaStatus slaStatus;
  final VoidCallback onTap;
  final ValueChanged<TaskCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final dark = slaStatus == SlaStatus.overdue;
    final foreground = dark ? AppColors.paper : AppColors.ink;
    final muted = dark ? AppColors.textMutedDark : AppColors.textMuted;

    return Material(
      color: dark ? AppColors.ink : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MemberAvatar(member: assignee, onDark: dark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.manrope(
                          16,
                          weight: FontWeight.w800,
                          color: foreground,
                          height: 21,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.category} · ${task.priority.label} priority',
                        style: AppText.manrope(
                          13,
                          weight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.darkNav
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: foreground,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDate(task.dueDate),
                              style: AppText.caption(color: foreground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<TaskCardAction>(
                      tooltip: 'Task options',
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert, color: foreground, size: 20),
                      onSelected: onAction,
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: TaskCardAction.edit,
                          child: Text('Edit'),
                        ),
                        if (!task.isDone)
                          const PopupMenuItem(
                            value: TaskCardAction.markDone,
                            child: Text('Mark as done'),
                          ),
                        const PopupMenuItem(
                          value: TaskCardAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SlaBadge(status: slaStatus),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
