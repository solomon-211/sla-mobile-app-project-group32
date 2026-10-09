import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';
import '../widgets/dialogs.dart';
import '../widgets/icon_circle_button.dart';
import '../widgets/status_widgets.dart';
import '../widgets/task_card.dart';

/// Task List: search, SLA filter chips and tasks grouped by urgency.
///
/// The selected filter lives in HomeShell (so dashboard cards can set it);
/// the search text and sort order are local state of this screen.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.membersById,
    required this.filter,
    required this.onFilterChanged,
    required this.onChanged,
    required this.onOpenMenu,
  });

  final List<Task> tasks;
  final Map<int, TeamMember> membersById;

  /// SLA statuses to show. Null means "All".
  final Set<SlaStatus>? filter;
  final ValueChanged<Set<SlaStatus>?> onFilterChanged;

  final Future<void> Function() onChanged;

  /// Opens the navigation drawer owned by HomeShell.
  final VoidCallback onOpenMenu;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  String _query = '';

  /// Earliest deadline first when true.
  bool _soonestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// True when the task title, description, category or assignee contains
  /// the search text.
  bool _matchesSearch(Task task) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final assignee = widget.membersById[task.assigneeId]?.name ?? '';
    return [
      task.title,
      task.description,
      task.category,
      assignee,
    ].any((text) => text.toLowerCase().contains(query));
  }

  Future<void> _openDetails(Task task) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.taskDetails,
      arguments: task.id,
    );
    await widget.onChanged();
  }

  Future<void> _openForm([Task? task]) async {
    await Navigator.pushNamed(context, AppRoutes.taskForm, arguments: task);
    await widget.onChanged();
  }

  Future<void> _handleAction(Task task, TaskCardAction action) async {
    switch (action) {
      case TaskCardAction.edit:
        await _openForm(task);
      case TaskCardAction.markDone:
        await runWithFeedback(context, () async {
          await DatabaseHelper.instance.updateTaskStatus(task, TaskStatus.done);
          await widget.onChanged();
        }, success: '"${task.title}" marked as done');
      case TaskCardAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete this task?',
          message:
              '"${task.title}" and its history will be removed. '
              'This can\'t be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (!confirmed || !mounted) return;
        await runWithFeedback(context, () async {
          await DatabaseHelper.instance.deleteTask(task.id!);
          await widget.onChanged();
        }, success: 'Task deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filter = widget.filter;

    // Work out each task's SLA status once per build.
    final slaOf = {
      for (final task in widget.tasks) task: Sla.statusOf(task, now: now),
    };

    // 1. search  2. chip filter  3. sort by deadline
    final visible =
        widget.tasks.where((task) {
          final matchesFilter = filter == null || filter.contains(slaOf[task]);
          return matchesFilter && _matchesSearch(task);
        }).toList()..sort(
          (a, b) => _soonestFirst
              ? a.dueDate.compareTo(b.dueDate)
              : b.dueDate.compareTo(a.dueDate),
        );

    // 4. group into sections, then flatten into rows for ListView.builder.
    List<Task> withStatus(Set<SlaStatus> statuses) {
      return visible.where((task) => statuses.contains(slaOf[task])).toList();
    }

    final sections = [
      (
        'Needs attention',
        AppColors.coralDeep,
        AppColors.coral,
        withStatus(Sla.needsAttention),
      ),
      (
        'Upcoming',
        AppColors.mossText,
        AppColors.mossDeep,
        withStatus({SlaStatus.onTrack}),
      ),
      (
        SlaStatus.completed.label,
        AppColors.textMuted,
        AppColors.doneDot,
        withStatus({SlaStatus.completed}),
      ),
    ];
    final taskRows = <Object>[
      for (final (title, color, dot, sectionTasks) in sections)
        if (sectionTasks.isNotEmpty) ...[
          _SectionHeader(title, sectionTasks.length, color, dot),
          ...sectionTasks,
        ],
    ];

    // Header widgets scroll together with the tasks, as in the design.
    final rows = <Object>[
      _buildHeader(),
      _buildTitle(),
      _buildSearch(),
      _buildFilterChips(slaOf),
      if (taskRows.isEmpty) _buildEmpty() else ...taskRows,
    ];

    return Scaffold(
      backgroundColor: AppColors.ground,
      floatingActionButton: SizedBox.square(
        dimension: 62,
        child: FloatingActionButton(
          tooltip: 'New task',
          elevation: 6,
          onPressed: _openForm,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          // Bottom padding keeps the last card clear of the FAB and nav.
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 180),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            if (row is Widget) return row;
            final task = row as Task;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskCard(
                task: task,
                assignee: widget.membersById[task.assigneeId],
                slaStatus: slaOf[task]!,
                onTap: () => _openDetails(task),
                onAction: (action) => _handleAction(task, action),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconCircleButton(
          icon: Icons.notes_rounded,
          tooltip: 'Open menu',
          onPressed: widget.onOpenMenu,
        ),
        IconCircleButton(
          icon: _soonestFirst
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          tooltip: _soonestFirst
              ? 'Sorted by soonest deadline'
              : 'Sorted by latest deadline',
          onPressed: () => setState(() => _soonestFirst = !_soonestFirst),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text('Tasks', style: AppText.screenTitle())),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${widget.tasks.length} total',
              style: AppText.manrope(
                14,
                weight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: AppText.manrope(15, weight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill.copyWith(
            borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search_rounded, color: AppColors.textMuted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildFilterChips(Map<Task, SlaStatus> slaOf) {
    int count(Set<SlaStatus> statuses) {
      return slaOf.values.where(statuses.contains).length;
    }

    Widget chip(String label, Set<SlaStatus>? statuses, Color dot) {
      final selected = setEquals(widget.filter, statuses);
      final countText = statuses == null
          ? widget.tasks.length
          : count(statuses);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? AppColors.ink : AppColors.surface,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // Tapping a chip asks HomeShell to change the filter; HomeShell
              // calls setState and this list rebuilds with the new filter.
              onTap: () => widget.onFilterChanged(statuses),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: selected ? AppColors.moss : dot,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$label ($countText)',
                      style: AppText.manrope(
                        14,
                        weight: FontWeight.w800,
                        color: selected ? AppColors.paper : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        height: 44,
        // Negative margin lets the chips scroll edge to edge.
        child: OverflowBox(
          maxWidth: MediaQuery.sizeOf(context).width,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip('All', null, AppColors.ink),
              for (final status in SlaStatus.values)
                chip(status.label, {status}, SlaStyle.of(status).dot),
              chip('Needs attention', Sla.needsAttention, AppColors.coralDeep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final noTasks = widget.tasks.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              noTasks ? 'No tasks yet' : 'Nothing here',
              style: AppText.sora(18),
            ),
            const SizedBox(height: 6),
            Text(
              noTasks
                  ? 'Tap + to create the first task.'
                  : 'No tasks match this search or filter.',
              textAlign: TextAlign.center,
              style: AppText.manrope(14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.count, this.color, this.dot);

  final String title;
  final int count;
  final Color color;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: dot),
          const SizedBox(width: 8),
          Text(
            '${title.toUpperCase()} · $count',
            style: AppText.manrope(
              13,
              weight: FontWeight.w800,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
