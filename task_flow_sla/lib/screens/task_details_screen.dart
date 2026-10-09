import 'dart:async';

import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/task.dart';
import '../models/task_activity.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/sla.dart';
import '../widgets/app_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/icon_circle_button.dart';
import '../widgets/member_avatar.dart';
import '../widgets/pill_buttons.dart';
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

  /// Set when the task could not be read from the database. Different from
  /// [_task] being null, which means the task no longer exists.
  String? _error;

  /// True while a status change is being saved. Disables the status controls
  /// so a double tap cannot save the same change twice.
  bool _updating = false;

  /// Rebuilds every minute so the SLA card and time label stay current.
  Timer? _clock;

  Task? _task;
  TeamMember? _assignee;
  List<TaskActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
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
        _error = null;
      });
    } catch (error, stack) {
      logError('Could not load task ${widget.taskId}', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this task.';
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  /// Saves the new status to the database, then updates the screen.
  Future<void> _changeStatus(TaskStatus status) async {
    final task = _task;
    if (task == null || task.status == status || _updating) return;
    setState(() => _updating = true);
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
    } catch (error, stack) {
      logError('Could not update status', error, stack);
      if (mounted) showMessage(context, 'Could not update the status.');
    } finally {
      if (mounted) setState(() => _updating = false);
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
      title: 'Delete this task?',
      message:
          '"${task.title}" and its history will be removed. '
          'This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await DatabaseHelper.instance.deleteTask(task.id!);
      if (!mounted) return;
      showMessage(context, 'Task deleted');
      Navigator.pop(context);
    } catch (error, stack) {
      logError('Could not delete task', error, stack);
      if (mounted) showMessage(context, 'Could not delete the task.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;

    return Scaffold(
      // The action bar floats over the content.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(task),
            Expanded(child: _buildBody(task)),
          ],
        ),
      ),
      bottomNavigationBar: task == null ? null : _buildActions(task),
    );
  }

  Widget _buildHeader(Task? task) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          IconCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back to tasks',
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              'Task Details',
              textAlign: TextAlign.center,
              style: AppText.cardTitle(),
            ),
          ),
          // Keeps the title centred while the task is loading.
          if (task == null)
            const SizedBox(width: 46)
          else
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (value) => value == 'edit' ? _edit() : _delete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit task')),
                PopupMenuItem(value: 'delete', child: Text('Delete task')),
              ],
              child: const IgnorePointer(
                child: IconCircleButton(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'More options',
                  onPressed: null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(Task? task) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: _error!,
        message: 'Check your storage and try again.',
        actionLabel: 'Try again',
        onAction: _retry,
      );
    }
    if (task == null) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Task not found',
        message: 'It may have been deleted.',
      );
    }
    return _buildContent(task);
  }

  Widget _buildContent(Task task) {
    final now = DateTime.now();
    final status = Sla.statusOf(task, now: now);

    return ListView(
      // Bottom padding keeps the last card clear of the action bar.
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 116),
      children: [
        _buildTitleBlock(task, status),
        const SizedBox(height: 14),
        _SlaCard(task: task, status: status, now: now),
        const SizedBox(height: 14),
        _buildInfoTiles(task),
        const SizedBox(height: 14),
        _buildActivity(),
      ],
    );
  }

  Widget _buildTitleBlock(Task task, SlaStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: task.category,
                background: AppColors.ink,
                foreground: AppColors.moss,
              ),
              const SizedBox(width: 8),
              Text(
                task.code,
                style: AppText.manrope(
                  13,
                  weight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              SlaBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: AppText.sora(30, height: 36, letterSpacing: -1),
          ),
          const SizedBox(height: 10),
          Text(
            task.description.isEmpty ? 'No description.' : task.description,
            style: AppText.manrope(15, color: AppColors.textBody, height: 23),
          ),
        ],
      ),
    );
  }

  /// 2x2 tiles: assignee, due date, priority and status.
  Widget _buildInfoTiles(Task task) {
    Widget row(Widget left, Widget right) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(
          _InfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Assigned to',
            child: Row(
              children: [
                MemberAvatar(member: _assignee, radius: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _assignee?.name ?? 'Unassigned',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle(),
                  ),
                ),
              ],
            ),
          ),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Due date',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDate(task.dueDate), style: AppText.sora(18)),
                Text(
                  formatTime(task.dueDate),
                  style: AppText.manrope(
                    13,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        row(
          _InfoTile(
            icon: Icons.flag_outlined,
            label: 'Priority',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: priorityColor(task.priority),
                ),
                const SizedBox(width: 8),
                Text(task.priority.label, style: AppText.sora(18)),
              ],
            ),
          ),
          _InfoTile(
            icon: Icons.notes_rounded,
            label: 'Status',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButton<TaskStatus>(
                value: task.status,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(20),
                style: AppText.manrope(14, weight: FontWeight.w800),
                items: [
                  for (final option in TaskStatus.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                // A null onChanged disables the dropdown while saving.
                onChanged: _updating
                    ? null
                    : (value) {
                        if (value != null) _changeStatus(value);
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivity() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Activity', style: AppText.cardTitle()),
          for (final (index, activity) in _activities.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    // The newest entry is highlighted with a moss ring.
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: index == 0 ? AppColors.ink : AppColors.dotMuted,
                        shape: BoxShape.circle,
                        border: index == 0
                            ? Border.all(
                                color: AppColors.moss,
                                width: 4,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.message,
                      style: AppText.manrope(14, height: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatShortDate(activity.createdAt),
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(Task task) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // The main action gets 1.35x the width of Edit, as in the design.
        child: Row(
          children: [
            Expanded(
              flex: 100,
              child: OutlinePillButton(
                label: 'Edit Task',
                icon: Icons.edit_outlined,
                height: 64,
                background: AppColors.surface,
                onPressed: _updating ? null : _edit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 135,
              child: PrimaryPillButton(
                label: task.isDone ? 'Reopen task' : 'Mark as Done',
                icon: task.isDone ? Icons.replay_rounded : Icons.check_rounded,
                nudge: false,
                loading: _updating,
                onPressed: () => _changeStatus(
                  task.isDone ? TaskStatus.inProgress : TaskStatus.done,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White tile with a small icon + label on top and the value below.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: AppText.caption()),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Dark card explaining the SLA status, with a tick scale showing how much
/// of the time between creation and deadline is used.
class _SlaCard extends StatelessWidget {
  const _SlaCard({required this.task, required this.status, required this.now});

  final Task task;
  final SlaStatus status;
  final DateTime now;

  static const _ticks = 36;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(status);
    final used = Sla.timeUsed(task, now: now);
    final percent = (used * 100).round();
    final filled = (used * _ticks).round();
    // Completed tasks show in moss; the others use their status colour.
    final accent = status == SlaStatus.completed ? AppColors.moss : style.color;
    final titleColor = status == SlaStatus.completed
        ? AppColors.moss
        : style.onDark;

    return AppCard(
      color: AppColors.ink,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLA STATUS',
                      style: AppText.manrope(
                        12,
                        weight: FontWeight.w800,
                        color: AppColors.textMutedDark,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${status.label} · ${Sla.describe(task, now: now)}',
                      style: AppText.sora(20, color: titleColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$percent',
                      children: [
                        TextSpan(
                          text: '%',
                          style: AppText.sora(18, color: AppColors.paper),
                        ),
                      ],
                    ),
                    style: AppText.sora(
                      34,
                      color: AppColors.paper,
                      height: 36,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'time used',
                    style: AppText.manrope(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: '$percent% of the time window used',
            excludeSemantics: true,
            child: SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _ticks; i++)
                    Container(
                      width: 3,
                      // Every fifth tick is taller, like a ruler.
                      height: i % 5 == 0 ? 30 : 18,
                      decoration: BoxDecoration(
                        color: i < filled ? accent : AppColors.darkTick,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$percent% of the time window used. ${Sla.explain(task, now: now)}',
            style: AppText.manrope(
              13,
              color: AppColors.textSoftDark,
              height: 19,
            ),
          ),
        ],
      ),
    );
  }
}
