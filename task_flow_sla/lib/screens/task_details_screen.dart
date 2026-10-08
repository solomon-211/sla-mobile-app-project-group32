import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/task.dart';
import '../models/task_activity.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/sla.dart';
import '../widgets/dialogs.dart';
import '../widgets/member_avatar.dart';
import '../widgets/status_widgets.dart';

/// Task Details: everything about one task, with status updates, edit and
/// delete.
class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final int taskId;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  bool _loading = true;
  Task? _task;
  TeamMember? _assignee;
  List<TaskActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseHelper.instance;
      final task = await db.getTask(widget.taskId);
      final members = await db.getMembers();
      final activities = await db.getActivities(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _assignee = members.where((m) => m.id == task?.assigneeId).firstOrNull;
        _activities = activities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showMessage(context, 'Could not load this task.');
    }
  }

  /// Saves the new status to the database, then updates the screen.
  Future<void> _changeStatus(TaskStatus status) async {
    final task = _task;
    if (task == null || task.status == status) return;
    try {
      final db = DatabaseHelper.instance;
      final updated = await db.updateTaskStatus(task, status);
      final activities = await db.getActivities(task.id!);
      if (!mounted) return;
      // setState rebuilds the badge, SLA card, dropdown and bottom button.
      setState(() {
        _task = updated;
        _activities = activities;
      });
    } catch (_) {
      if (mounted) showMessage(context, 'Could not update the status.');
    }
  }

  Future<void> _edit() async {
    await Navigator.pushNamed(context, AppRoutes.taskForm, arguments: _task);
    await _load();
  }

  Future<void> _delete() async {
    final task = _task;
    if (task == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: '"${task.title}" and its history will be removed. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await DatabaseHelper.instance.deleteTask(task.id!);
      if (!mounted) return;
      showMessage(context, 'Task deleted');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) showMessage(context, 'Could not delete the task.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        actions: [
          if (task != null)
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? _edit() : _delete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit task')),
                PopupMenuItem(value: 'delete', child: Text('Delete task')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Task not found',
                  message: 'It may have been deleted.',
                )
              : _buildContent(task),
      bottomNavigationBar: task == null ? null : _buildActions(task),
    );
  }

  Widget _buildContent(Task task) {
    final now = DateTime.now();
    final status = Sla.statusOf(task, now: now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SlaBadge(status: status),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: task.category,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' · ${task.code}'),
            ],
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          task.description.isEmpty ? 'No description.' : task.description,
          style: const TextStyle(height: 1.4, color: AppColors.textDark),
        ),
        const SizedBox(height: 16),
        const Divider(),
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Assigned to',
          child: Row(
            children: [
              MemberAvatar(member: _assignee, radius: 13),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _assignee?.name ?? 'Unassigned',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Due date',
          child: Text(
            formatDateTime(task.dueDate),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(),
        _DetailRow(
          icon: Icons.flag_outlined,
          label: 'Priority',
          child: Text(
            task.priority.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: priorityColor(task.priority),
            ),
          ),
        ),
        const Divider(),
        _DetailRow(
          icon: Icons.notes,
          label: 'Status',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<TaskStatus>(
              value: task.status,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final option in TaskStatus.values)
                  DropdownMenuItem(value: option, child: Text(option.label)),
              ],
              onChanged: (value) {
                if (value != null) _changeStatus(value);
              },
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
        _SlaCard(
          task: task,
          status: status,
          now: now,
        ),
        const SizedBox(height: 20),
        const Text(
          'Activity',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final (index, activity) in _activities.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  // The newest entry is highlighted.
                  backgroundColor:
                      index == 0 ? AppColors.primary : AppColors.border,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  formatShortDate(activity.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActions(Task task) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _edit,
                child: const Text('Edit Task'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _changeStatus(
                  task.isDone ? TaskStatus.inProgress : TaskStatus.done,
                ),
                child: Text(task.isDone ? 'Reopen Task' : 'Mark as Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Explains the task's SLA status and how much of its time window is used.
class _SlaCard extends StatelessWidget {
  const _SlaCard({
    required this.task,
    required this.status,
    required this.now,
  });

  final Task task;
  final SlaStatus status;
  final DateTime now;

  String get _explanation {
    switch (status) {
      case SlaStatus.completed:
        return 'This task is done, so it no longer counts against the SLA.';
      case SlaStatus.overdue:
        return 'The deadline has passed and the task is not done.';
      case SlaStatus.atRisk:
        return 'Tasks become At Risk inside ${Sla.defaultAtRiskHours} hours of the deadline.';
      case SlaStatus.onTrack:
        return 'More than ${Sla.defaultAtRiskHours} hours remain before the deadline.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(status);
    final used = Sla.timeUsed(task, now: now);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.background),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLA Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: style.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(style.icon, size: 20, color: style.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${status.label} · ${Sla.describe(task, now: now)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: style.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: used,
            minHeight: 7,
            borderRadius: BorderRadius.circular(7),
            color: style.color,
            backgroundColor: style.background,
          ),
          const SizedBox(height: 10),
          Text(
            '${(used * 100).round()}% of the time window used. $_explanation',
            style: TextStyle(fontSize: 12, color: style.foreground),
          ),
        ],
      ),
    );
  }
}
