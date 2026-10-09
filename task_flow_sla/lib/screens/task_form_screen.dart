import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/icon_circle_button.dart';
import '../widgets/pill_buttons.dart';
import '../widgets/status_widgets.dart';

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
  late final _descriptionController = TextEditingController(
    text: widget.task?.description,
  );

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

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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
        // The save button floats over the form.
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loadingMembers
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: _loadError!,
                        message:
                            'The form needs the team list to assign tasks.',
                        actionLabel: 'Try again',
                        onAction: _loadMembers,
                      )
                    : _buildForm(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: PrimaryPillButton(
              label: _isEditing ? 'Save changes' : 'Create Task',
              loading: _saving,
              onPressed: _saving || !ready ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          IconCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            // maybePop goes through PopScope, so unsaved changes are checked.
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Task' : 'Create Task',
              style: AppText.sora(26, letterSpacing: -0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    // A task can only be marked Done after it exists.
    final statusOptions = [
      for (final status in TaskStatus.values)
        if (_isEditing || status != TaskStatus.done) status,
    ];
    final fieldText = AppText.manrope(15, weight: FontWeight.w600);

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: ListView(
        // Bottom padding keeps the last row clear of the save button.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          const _FieldLabel('Task title'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: Validators.titleMaxLength,
            style: fieldText,
            // The limit is enforced by maxLength; the counter is hidden.
            decoration: const InputDecoration(
              hintText: 'Enter task title',
              counterText: '',
            ),
            validator: Validators.taskTitle,
          ),
          const SizedBox(height: 8),
          const _FieldLabel('Description'),
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 4,
            // maxLength adds the "0/300" counter and blocks extra typing.
            maxLength: Validators.descriptionMaxLength,
            style: AppText.manrope(15, height: 22),
            decoration: const InputDecoration(
              hintText: 'Enter task description (optional)',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailsCard(statusOptions),
        ],
      ),
    );
  }

  /// One white card holding assignee, category, due date, priority and
  /// status, separated by thin dividers.
  Widget _buildDetailsCard(List<TaskStatus> statusOptions) {
    return AppCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardRow(
            icon: Icons.person_outline_rounded,
            iconBackground: AppColors.moss,
            iconColor: AppColors.onMoss,
            label: 'Assign to',
            child: DropdownButtonFormField<int>(
              // Only use the saved assignee if they are still in the list,
              // otherwise the dropdown would have a value with no matching item.
              initialValue: _members.any((m) => m.id == _assigneeId)
                  ? _assigneeId
                  : null,
              isExpanded: true,
              decoration: _inlineDecoration,
              style: _inlineText,
              borderRadius: BorderRadius.circular(20),
              hint: Text(
                'Select a team member',
                style: AppText.manrope(15, color: AppColors.hint),
              ),
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
          ),
          const Divider(),
          _CardRow(
            icon: Icons.label_outline_rounded,
            label: 'Category',
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: _inlineDecoration,
              style: _inlineText,
              borderRadius: BorderRadius.circular(20),
              items: [
                for (final category in taskCategories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
          ),
          const Divider(),
          _buildDueDateRow(),
          const Divider(),
          _buildPriorityRow(),
          const Divider(),
          _CardRow(
            icon: Icons.notes_rounded,
            iconBackground: AppColors.ink,
            iconColor: AppColors.moss,
            label: 'Status',
            child: DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              isExpanded: true,
              decoration: _inlineDecoration,
              style: _inlineText,
              borderRadius: BorderRadius.circular(20),
              items: [
                for (final status in statusOptions)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdowns inside the card have no box of their own.
  static const _inlineDecoration = InputDecoration(
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );

  TextStyle get _inlineText => AppText.manrope(15, weight: FontWeight.w800);

  Widget _buildDueDateRow() {
    return FormField<DateTime>(
      initialValue: _dueDate,
      validator: (value) =>
          Validators.dueDate(value, original: widget.task?.dueDate),
      builder: (field) {
        final hasError = field.errorText != null;
        final value = field.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconCircle(
                    icon: Icons.calendar_today_outlined,
                    background: hasError
                        ? AppColors.coralBg
                        : AppColors.surfaceMuted,
                    color: hasError ? AppColors.coralDeep : AppColors.ink,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due date',
                          style: AppText.manrope(
                            12,
                            weight: FontWeight.w800,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value == null
                              ? 'Select date and time'
                              : formatDateTime(value),
                          style: value == null
                              ? AppText.manrope(15, color: AppColors.hint)
                              : AppText.manrope(
                                  15,
                                  weight: FontWeight.w800,
                                  color: hasError
                                      ? AppColors.error
                                      : AppColors.ink,
                                ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDueDate(field),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(
                      value == null ? 'Pick' : 'Change',
                      style: AppText.label(),
                    ),
                  ),
                ],
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 58, top: 6),
                  child: Text(
                    field.errorText!,
                    style: AppText.manrope(
                      13,
                      weight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Low / Medium / High as one segmented pill.
  Widget _buildPriorityRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Priority',
                style: AppText.manrope(
                  12,
                  weight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                for (final priority in TaskPriority.values)
                  Expanded(child: _priorityOption(priority)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityOption(TaskPriority priority) {
    final selected = priority == _priority;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${priority.label} priority',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _priority = priority),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: priorityColor(priority),
                ),
                const SizedBox(width: 6),
                Text(
                  priority.label,
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(text, style: AppText.label()),
    );
  }
}

/// 44px coloured circle with an icon, used at the start of each card row.
class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    this.background = AppColors.surfaceMuted,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// A row in the grouped details card: icon circle, small label and a control.
class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.icon,
    required this.label,
    required this.child,
    this.iconBackground = AppColors.surfaceMuted,
    this.iconColor = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _IconCircle(icon: icon, background: iconBackground, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.manrope(
                    12,
                    weight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
