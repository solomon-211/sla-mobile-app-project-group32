/// One line in a task's history, e.g. "Status changed to In Progress".
class TaskActivity {
  final int? id;
  final int taskId;
  final String message;
  final DateTime createdAt;

  const TaskActivity({
    this.id,
    required this.taskId,
    required this.message,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'message': message,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TaskActivity.fromMap(Map<String, Object?> map) {
    return TaskActivity(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      message: map['message'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
