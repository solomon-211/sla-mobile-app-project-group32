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
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.members,
    required this.onChanged,
    required this.onOpenMenu,
    this.initialFilter,
  });

  final List<Task> tasks;
  final List<TeamMember> members;
  final Future<void> Function() onChanged;

  /// Opens the navigation drawer owned by HomeShell.
  final VoidCallback onOpenMenu;

  /// Pre-selected chip when arriving from a dashboard card.
  final SlaStatus? initialFilter;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  String _query = '';

  /// Selected SLA chip. Null means "All".
  late SlaStatus? _filter = widget.initialFilter;

  /// Earliest deadline first when true.
  bool _soonestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// True when the task title, category or assignee contains the search text.
  bool _matchesSearch(Task task, Map<int, TeamMember> membersById) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final assignee = membersById[task.assigneeId]?.name ?? '';
    return task.title.toLowerCase().contains(query) ||
        task.category.toLowerCase().contains(query) ||
        assignee.toLowerCase().contains(query);
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
        await _runAndRefresh(
          () => DatabaseHelper.instance.updateTaskStatus(task, TaskStatus.done),
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
        if (!confirmed) return;
        await _runAndRefresh(
          () => DatabaseHelper.instance.deleteTask(task.id!),
          success: 'Task deleted',
        );
    }
  }

  Future<void> _runAndRefresh(
    Future<void> Function() write, {
    required String success,
  }) async {
    try {
      await write();
      await widget.onChanged();
      if (mounted) showMessage(context, success);
    } catch (_) {
      if (mounted) showMessage(context, 'Could not save the change.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final membersById = {for (final m in widget.members) m.id!: m};

    // Work out each task's SLA status once per build.
    final slaOf = {
      for (final task in widget.tasks)
        task: Sla.statusOf(task, now: now),
    };

    // 1. search  2. chip filter  3. sort by deadline
    final visible = widget.tasks.where((task) {
      final matchesFilter = _filter == null || slaOf[task] == _filter;
      return matchesFilter && _matchesSearch(task, membersById);
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
        withStatus({SlaStatus.overdue, SlaStatus.atRisk}),
      ),
      ('Upcoming', AppColors.onTrack, withStatus({SlaStatus.onTrack})),
      ('Completed', AppColors.completed, withStatus({SlaStatus.completed})),
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
                          assignee: membersById[task.assigneeId],
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
    Widget chip(String label, SlaStatus? status) {
      final selected = _filter == status;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          shape: const StadiumBorder(),
          // Tapping a chip changes the filter and rebuilds the list.
          onSelected: (_) => setState(() => _filter = status),
        ),
      );
    }

    int count(SlaStatus status) {
      return slaOf.values.where((s) => s == status).length;
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('All (${widget.tasks.length})', null),
          for (final status in SlaStatus.values)
            chip(
              status == SlaStatus.completed
                  ? 'Done (${count(status)})'
                  : '${status.label} (${count(status)})',
              status,
            ),
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
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text('${title.toUpperCase()} · $count', style: style),
        ],
      ),
    );
  }
}
