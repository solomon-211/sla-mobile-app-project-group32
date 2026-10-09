import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/dialogs.dart';

/// Create / Edit Task. Pass a [task] to edit it, or null to create a new one.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.task?.title);
  late final _descriptionController =
      TextEditingController(text: widget.task?.description);

  // Form values that are not text. They start from the task being edited.
  late String _category = widget.task?.category ?? taskCategories.first;
  late int? _assigneeId = widget.task?.assigneeId;
  late DateTime? _dueDate = widget.task?.dueDate;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late TaskStatus _status = widget.task?.status ?? TaskStatus.todo;

  /// The assignee the form opened with, used to detect unsaved changes.
  /// For a new task this becomes the signed-in user once members load.
  late int? _initialAssigneeId = widget.task?.assigneeId;

  List<TeamMember> _members = [];
  bool _loadingMembers = true;
  String? _loadError;
  bool _saving = false;

  /// Errors appear after the first failed submit, then update as the user
  /// fixes each field.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEditing => widget.task != null;

  /// True when any field differs from what the form opened with.
  bool get _hasChanges {
    final task = widget.task;
    return _titleController.text.trim() != (task?.title ?? '') ||
        _descriptionController.text.trim() != (task?.description ?? '') ||
        _category != (task?.category ?? taskCategories.first) ||
        _assigneeId != _initialAssigneeId ||
        _dueDate != task?.dueDate ||
        _priority != (task?.priority ?? TaskPriority.medium) ||
        _status != (task?.status ?? TaskStatus.todo);
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _loadError = null;
    });
    try {
      final members = await DatabaseHelper.instance.getMembers();
      final userId = await SessionService.currentUserId();
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingMembers = false;
        // New tasks are assigned to the signed-in user by default.
        if (!_isEditing && _assigneeId == null) {
          final me = members.where((m) => m.id == userId).firstOrNull;
          _assigneeId = me?.id;
          _initialAssigneeId = me?.id;
        }
      });
    } catch (error, stack) {
      logError('Could not load members', error, stack);
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _loadError = 'Could not load team members.';
      });
    }
  }

  /// Date picker followed by time picker, combined into one DateTime.
  Future<void> _pickDueDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _dueDate;
    final initial = current != null && current.isAfter(today)
        ? current
        : now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? initial),
    );
    if (time == null || !mounted) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _dueDate = picked);
    field.didChange(picked);
  }

  /// Called when the user presses Back. Leaves straight away when nothing
  /// changed, otherwise asks before throwing the changes away.
  Future<void> _confirmLeave() async {
    if (_saving) return;
    if (_hasChanges) {
      final discard = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message: 'Your changes to this task have not been saved.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!discard || !mounted) return;
    }
    Navigator.pop(context);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      showMessage(context, 'Please fix the highlighted fields.');
      return;
    }

    setState(() => _saving = true);
    final existing = widget.task;
    final now = DateTime.now();
    final assignee = _members.firstWhere((m) => m.id == _assigneeId);

    final task = Task(
      id: existing?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      assigneeId: assignee.id!,
      dueDate: _dueDate!,
      priority: _priority,
      status: _status,
      createdAt: existing?.createdAt ?? now,
      // Keep the original completion time unless the task just became Done.
      completedAt: _status == TaskStatus.done
          ? (existing?.completedAt ?? now)
          : null,
    );

    try {
      final db = DatabaseHelper.instance;
      if (existing == null) {
        await db.insertTask(
          task,
          activity: 'Created and assigned to ${assignee.name}',
        );
      } else {
        await db.updateTask(
          task,
          activities: [
            if (task.status != existing.status)
              'Status changed to ${task.status.label}',
            if (task.assigneeId != existing.assigneeId)
              'Reassigned to ${assignee.name}',
            if (task.dueDate != existing.dueDate)
              'Due date changed to ${formatDateTime(task.dueDate)}',
            if (task.status == existing.status &&
                task.assigneeId == existing.assigneeId &&
                task.dueDate == existing.dueDate)
              'Task details updated',
          ],
        );
      }
      if (!mounted) return;
      showMessage(context, _isEditing ? 'Task updated' : 'Task created');
      // Navigator.pop skips PopScope, so no "discard changes" prompt here.
      Navigator.pop(context);
    } catch (error, stack) {
      logError('Could not save task', error, stack);
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Could not save the task. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_loadingMembers && _loadError == null;

    // canPop is false so every Back press goes through _confirmLeave.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textDark,
          shape: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        body: _loadingMembers
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: _loadError!,
                    message: 'The form needs the team list to assign tasks.',
                    actionLabel: 'Try again',
                    onAction: _loadMembers,
                  )
                : _buildForm(),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ElevatedButton(
              onPressed: _saving || !ready ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Task'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    // A task can only be marked Done after it exists.
    final statusOptions = [
      for (final status in TaskStatus.values)
        if (_isEditing || status != TaskStatus.done) status,
    ];

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _FieldLabel('Task title'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: Validators.titleMaxLength,
            decoration: const InputDecoration(hintText: 'Enter task title'),
            validator: Validators.taskTitle,
          ),
          const _FieldLabel('Description'),
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
            // maxLength adds the "0/300" counter and blocks extra typing.
            maxLength: Validators.descriptionMaxLength,
            decoration: const InputDecoration(
              hintText: 'Enter task description (optional)',
            ),
          ),
          const _FieldLabel('Category'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.label_outline),
            ),
            items: [
              for (final category in taskCategories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) => setState(() => _category = value!),
          ),
          const _FieldLabel('Assign to'),
          DropdownButtonFormField<int>(
            // Only use the saved assignee if they are still in the list,
            // otherwise the dropdown would have a value with no matching item.
            initialValue: _members.any((m) => m.id == _assigneeId)
                ? _assigneeId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
            ),
            hint: const Text('Select a team member'),
            items: [
              for (final member in _members)
                DropdownMenuItem(
                  value: member.id,
                  child: Text(
                    '${member.name} (${member.role})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            validator: (value) =>
                value == null ? 'Choose who will do this task' : null,
            onChanged: (value) => setState(() => _assigneeId = value),
          ),
          const _FieldLabel('Due date'),
          FormField<DateTime>(
            initialValue: _dueDate,
            validator: (value) =>
                Validators.dueDate(value, original: widget.task?.dueDate),
            builder: (field) => InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              onTap: () => _pickDueDate(field),
              child: InputDecorator(
                isEmpty: field.value == null,
                decoration: InputDecoration(
                  hintText: 'Select date and time',
                  prefixIcon: const Icon(Icons.event_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: field.errorText,
                ),
                child: field.value == null
                    ? null
                    : Text(formatDateTime(field.value!)),
              ),
            ),
          ),
          const _FieldLabel('Priority'),
          SegmentedButton<TaskPriority>(
            showSelectedIcon: false,
            segments: [
              for (final priority in TaskPriority.values)
                ButtonSegment(value: priority, label: Text(priority.label)),
            ],
            selected: {_priority},
            onSelectionChanged: (selection) {
              setState(() => _priority = selection.first);
            },
          ),
          const _FieldLabel('Status'),
          DropdownButtonFormField<TaskStatus>(
            initialValue: _status,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.notes)),
            items: [
              for (final status in statusOptions)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) => setState(() => _status = value!),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: AppText.label),
    );
  }
}
