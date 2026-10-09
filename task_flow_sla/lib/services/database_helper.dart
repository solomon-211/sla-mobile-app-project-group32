import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/seed_data.dart';
import '../models/task.dart';
import '../models/task_activity.dart';
import '../models/team_member.dart';

/// Single access point for the local SQLite database (sqflite).
///
/// Tasks, team members and task history are relational data (a task belongs
/// to a member, activity belongs to a task), which is why they are stored in
/// SQLite rather than SharedPreferences.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'sprinttrack.db';
  static const _members = 'members';
  static const _tasks = 'tasks';
  static const _activities = 'activities';

  /// Password given to the demo team and to members added from the Team tab.
  /// Accounts made with "Create account" choose their own.
  static const demoPassword = 'sprint123';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Version 2 added the members.password column. Existing members get the
  /// demo password so nobody is locked out after the update.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $_members ADD COLUMN password TEXT NOT NULL "
        "DEFAULT '$demoPassword'",
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        color_index INTEGER NOT NULL DEFAULT 0,
        password TEXT NOT NULL DEFAULT '$demoPassword'
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        assignee_id INTEGER NOT NULL REFERENCES $_members(id),
        due_date INTEGER NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE $_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL REFERENCES $_tasks(id) ON DELETE CASCADE,
        message TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    for (final member in seedMembers) {
      await db.insert(_members, member.toMap());
    }
    final namesById = {for (final m in seedMembers) m.id: m.name};

    for (final task in buildSeedTasks(DateTime.now())) {
      final taskId = await db.insert(_tasks, task.toMap());
      await db.insert(
        _activities,
        TaskActivity(
          taskId: taskId,
          message: 'Created and assigned to ${namesById[task.assigneeId]}',
          createdAt: task.createdAt,
        ).toMap(),
      );
      if (task.completedAt != null) {
        await db.insert(
          _activities,
          TaskActivity(
            taskId: taskId,
            message: 'Status changed to ${TaskStatus.done.label}',
            createdAt: task.completedAt!,
          ).toMap(),
        );
      }
    }
  }

  // ---------------------------------------------------------------- Members

  Future<List<TeamMember>> getMembers() async {
    final db = await database;
    final rows = await db.query(_members, orderBy: 'id ASC');
    return rows.map(TeamMember.fromMap).toList();
  }

  /// Saves a new member. Without a [password] the member gets [demoPassword].
  Future<TeamMember> insertMember(TeamMember member, {String? password}) async {
    final db = await database;
    final id = await db.insert(_members, {
      ...member.toMap(),
      'password': ?password,
    });
    return member.copyWith(id: id);
  }

  /// True when [password] belongs to the member. This is a local demo check,
  /// not real authentication, so the password is stored as plain text.
  Future<bool> checkPassword(int memberId, String password) async {
    final db = await database;
    final rows = await db.query(
      _members,
      columns: ['id'],
      where: 'id = ? AND password = ?',
      whereArgs: [memberId, password],
    );
    return rows.isNotEmpty;
  }

  Future<void> updateMember(TeamMember member) async {
    final db = await database;
    await db.update(
      _members,
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(int id) async {
    final db = await database;
    await db.delete(_members, where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------ Tasks

  /// All tasks, earliest deadline first.
  Future<List<Task>> getTasks() async {
    final db = await database;
    final rows = await db.query(_tasks, orderBy: 'due_date ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final rows = await db.query(_tasks, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }

  /// Saves a new task together with its first history entry.
  Future<Task> insertTask(Task task, {required String activity}) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert(_tasks, task.toMap());
      await txn.insert(
        _activities,
        TaskActivity(
          taskId: id,
          message: activity,
          createdAt: DateTime.now(),
        ).toMap(),
      );
      return task.withId(id);
    });
  }

  /// Updates a task and records what changed in its history.
  Future<void> updateTask(
    Task task, {
    List<String> activities = const [],
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _tasks,
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      final now = DateTime.now();
      for (final message in activities) {
        await txn.insert(
          _activities,
          TaskActivity(taskId: task.id!, message: message, createdAt: now)
              .toMap(),
        );
      }
    });
  }

  /// Moves a task to [status] and returns the updated task.
  Future<Task> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = task.withStatus(status);
    await updateTask(
      updated,
      activities: ['Status changed to ${status.label}'],
    );
    return updated;
  }

  /// Deletes a task. Its history rows go with it (ON DELETE CASCADE).
  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(_tasks, where: 'id = ?', whereArgs: [id]);
  }

  /// A task's history, newest first.
  Future<List<TaskActivity>> getActivities(int taskId) async {
    final db = await database;
    final rows = await db.query(
      _activities,
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(TaskActivity.fromMap).toList();
  }
}
