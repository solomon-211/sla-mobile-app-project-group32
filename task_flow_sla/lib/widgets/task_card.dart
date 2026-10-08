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
/// and SLA badge, with a menu for quick actions.
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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemberAvatar(member: assignee),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.category} · ${task.priority.label} priority',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formatDate(task.dueDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        SlaBadge(status: slaStatus),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<TaskCardAction>(
                tooltip: 'Task actions',
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
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
            ],
          ),
        ),
      ),
    );
  }
}
