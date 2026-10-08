enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.label);
  final String label;
}

enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  inReview('In Review'),
  done('Done');

  const TaskStatus(this.label);
  final String label;
}

const taskCategories = ['Mobile', 'Backend', 'UI/UX', 'DevOps', 'QA', 'General'];

class Task {
  final int? id;
  final String title;
  final String description;
  final String category;
  final int assigneeId;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;

  /// Set when the task is moved to Done, cleared if it is reopened.
  final DateTime? completedAt;

  const Task({
    this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.assigneeId,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  bool get isDone => status == TaskStatus.done;

  /// Short reference shown in the UI, e.g. "#T-014".
  String get code => '#T-${(id ?? 0).toString().padLeft(3, '0')}';

  Task withId(int newId) => _copy(id: newId);

  /// Changes the status and keeps [completedAt] in sync with it.
  Task withStatus(TaskStatus newStatus, {DateTime? now}) {
    if (newStatus == status) return this;
    return _copy(
      status: newStatus,
      completedAt: newStatus == TaskStatus.done ? (now ?? DateTime.now()) : null,
    );
  }

  Task _copy({int? id, TaskStatus? status, DateTime? completedAt}) {
    final newStatus = status ?? this.status;
    return Task(
      id: id ?? this.id,
      title: title,
      description: description,
      category: category,
      assigneeId: assigneeId,
      dueDate: dueDate,
      priority: priority,
      status: newStatus,
      createdAt: createdAt,
      completedAt: status == null ? this.completedAt : completedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'assignee_id': assigneeId,
      'due_date': dueDate.millisecondsSinceEpoch,
      'priority': priority.name,
      'status': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    final completedAt = map['completed_at'] as int?;
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      assigneeId: map['assignee_id'] as int,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      priority: TaskPriority.values.byName(map['priority'] as String),
      status: TaskStatus.values.byName(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedAt),
    );
  }
}
