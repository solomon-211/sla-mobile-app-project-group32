import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';
import '../widgets/dialogs.dart';
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
    return [task.title, task.description, task.category, assignee]
        .any((text) => text.toLowerCase().contains(query));
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
        await runWithFeedback(
          context,
          () async {
            await DatabaseHelper.instance.updateTaskStatus(task, TaskStatus.done);
            await widget.onChanged();
          },
          success: '"${task.title}" marked as done',
        );
      case TaskCardAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete task?',
          message: '"${task.title}" and its history will be removed.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (!confirmed || !mounted) return;
        await runWithFeedback(
          context,
          () async {
            await DatabaseHelper.instance.deleteTask(task.id!);
            await widget.onChanged();
          },
          success: 'Task deleted',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filter = widget.filter;

    // Work out each task's SLA status once per build.
    final slaOf = {
      for (final task in widget.tasks)
        task: Sla.statusOf(task, now: now),
    };

    // 1. search  2. chip filter  3. sort by deadline
    final visible = widget.tasks.where((task) {
      final matchesFilter = filter == null || filter.contains(slaOf[task]);
      return matchesFilter && _matchesSearch(task);
    }).toList()
      ..sort((a, b) => _soonestFirst
          ? a.dueDate.compareTo(b.dueDate)
          : b.dueDate.compareTo(a.dueDate));

    // 4. group into sections, then flatten into rows for ListView.builder.
    List<Task> withStatus(Set<SlaStatus> statuses) {
      return visible.where((task) => statuses.contains(slaOf[task])).toList();
    }

    final sections = [
      (
        'Needs attention',
        AppColors.overdue,
        withStatus(Sla.needsAttention),
      ),
      (
        SlaStatus.onTrack.label,
        AppColors.onTrack,
        withStatus({SlaStatus.onTrack}),
      ),
      (
        SlaStatus.completed.label,
        AppColors.completed,
        withStatus({SlaStatus.completed}),
      ),
    ];
    final rows = <Object>[
      for (final (title, color, sectionTasks) in sections)
        if (sectionTasks.isNotEmpty) ...[
          _SectionHeader(title, sectionTasks.length, color),
          ...sectionTasks,
        ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: widget.onOpenMenu,
        ),
        actions: [
          IconButton(
            tooltip: _soonestFirst
                ? 'Sorted by soonest deadline'
                : 'Sorted by latest deadline',
            icon: Icon(
              _soonestFirst ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () => setState(() => _soonestFirst = !_soonestFirst),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New task',
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search tasks, categories or people',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          _buildFilterChips(slaOf),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_outlined,
                    title: widget.tasks.isEmpty
                        ? 'No tasks yet'
                        : 'No tasks match',
                    message: widget.tasks.isEmpty
                        ? 'Tap + to create the first task.'
                        : 'Try a different search or filter.',
                  )
                : ListView.builder(
                    // Extra bottom padding keeps the last card clear of the FAB.
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row is _SectionHeader) return row;
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
        ],
      ),
    );
  }

  Widget _buildFilterChips(Map<Task, SlaStatus> slaOf) {
    int count(Set<SlaStatus> statuses) {
      return slaOf.values.where(statuses.contains).length;
    }

    Widget chip(String label, Set<SlaStatus>? statuses) {
      final selected = setEquals(widget.filter, statuses);
      final countText =
          statuses == null ? widget.tasks.length : count(statuses);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text('$label ($countText)'),
          selected: selected,
          showCheckmark: false,
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle: AppText.bodyStrong.copyWith(
            color: selected ? Colors.white : AppColors.textDark,
          ),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          shape: const StadiumBorder(),
          // Tapping a chip asks HomeShell to change the filter; HomeShell
          // calls setState and this list rebuilds with the new filter.
          onSelected: (_) => widget.onFilterChanged(statuses),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('All', null),
          chip('Needs attention', Sla.needsAttention),
          for (final status in SlaStatus.values) chip(status.label, {status}),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.count, this.color);

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            '${title.toUpperCase()} · $count',
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
