import '../models/task.dart';
import '../models/team_member.dart';

/// Demo data inserted the first time the database is created.
const seedProjectName = 'Mobile Banking v2 · Sprint 3';

const seedMembers = [
  TeamMember(
    id: 1,
    name: 'Amina K.',
    role: 'Project Manager',
    email: 'amina@devteam.app',
    colorIndex: 0,
  ),
  TeamMember(
    id: 2,
    name: 'Brian O.',
    role: 'Backend Developer',
    email: 'brian@devteam.app',
    colorIndex: 1,
  ),
  TeamMember(
    id: 3,
    name: 'Chloé M.',
    role: 'UI/UX Designer',
    email: 'chloe@devteam.app',
    colorIndex: 2,
  ),
  TeamMember(
    id: 4,
    name: 'Deng A.',
    role: 'Mobile Developer',
    email: 'deng@devteam.app',
    colorIndex: 3,
  ),
];

/// Deadlines are relative to [now] so a fresh install always shows a mix of
/// On Track, At Risk, Overdue and Completed tasks.
List<Task> buildSeedTasks(DateTime now) {
  Task open(
    String title,
    String description,
    String category,
    int assigneeId,
    TaskPriority priority,
    TaskStatus status, {
    required Duration dueIn,
    required int createdDaysAgo,
  }) {
    return Task(
      title: title,
      description: description,
      category: category,
      assigneeId: assigneeId,
      priority: priority,
      status: status,
      dueDate: now.add(dueIn),
      createdAt: now.subtract(Duration(days: createdDaysAgo)),
    );
  }

  Task done(
    String title,
    String category,
    int assigneeId,
    TaskPriority priority, {
    required int dueDaysAgo,
    required int completedDaysAgo,
  }) {
    return Task(
      title: title,
      category: category,
      assigneeId: assigneeId,
      priority: priority,
      status: TaskStatus.done,
      dueDate: now.subtract(Duration(days: dueDaysAgo)),
      createdAt: now.subtract(Duration(days: dueDaysAgo + 5)),
      completedAt: now.subtract(Duration(days: completedDaysAgo)),
    );
  }

  return [
    open(
      'Fix login token refresh',
      'Users are signed out after 15 minutes because the refresh token call '
          'fails silently. Retry once, then send the user to sign in.',
      'Backend',
      2,
      TaskPriority.high,
      TaskStatus.inProgress,
      dueIn: const Duration(days: -1),
      createdDaysAgo: 6,
    ),
    open(
      'Write API error states',
      'Show clear messages for timeout, 401 and 500 responses on the payment '
          'screens, with a retry button where it is safe.',
      'Mobile',
      1,
      TaskPriority.medium,
      TaskStatus.inProgress,
      dueIn: const Duration(hours: 20),
      createdDaysAgo: 7,
    ),
    open(
      'Design onboarding screens',
      'Three screens that introduce transfers, savings goals and alerts.',
      'UI/UX',
      3,
      TaskPriority.medium,
      TaskStatus.inReview,
      dueIn: const Duration(hours: 30),
      createdDaysAgo: 5,
    ),
    open(
      'Build transfer confirmation screen',
      'Summary of amount, recipient and fees before the transfer is sent.',
      'Mobile',
      4,
      TaskPriority.high,
      TaskStatus.inProgress,
      dueIn: const Duration(days: 4),
      createdDaysAgo: 3,
    ),
    open(
      'Prepare sprint review slides',
      'Cover what shipped, what slipped and the plan for the next sprint.',
      'General',
      1,
      TaskPriority.low,
      TaskStatus.todo,
      dueIn: const Duration(days: 5),
      createdDaysAgo: 1,
    ),
    open(
      'Set up CI for Android builds',
      'Run analyze, tests and a debug build on every pull request.',
      'DevOps',
      4,
      TaskPriority.low,
      TaskStatus.todo,
      dueIn: const Duration(days: 6),
      createdDaysAgo: 2,
    ),
    open(
      'Add rate limiting to payments API',
      'Limit each account to 10 payment requests per minute.',
      'Backend',
      2,
      TaskPriority.medium,
      TaskStatus.todo,
      dueIn: const Duration(days: 8),
      createdDaysAgo: 2,
    ),
    open(
      'Usability test the signup flow',
      'Run five short sessions and write up the top three problems.',
      'UI/UX',
      3,
      TaskPriority.medium,
      TaskStatus.todo,
      dueIn: const Duration(days: 9),
      createdDaysAgo: 1,
    ),
    done('Set up project repository', 'DevOps', 4, TaskPriority.high,
        dueDaysAgo: 10, completedDaysAgo: 11),
    done('Define sprint backlog', 'General', 1, TaskPriority.high,
        dueDaysAgo: 8, completedDaysAgo: 9),
    done('Create design system colours', 'UI/UX', 3, TaskPriority.medium,
        dueDaysAgo: 6, completedDaysAgo: 7),
    // Finished one day after its deadline, so it shows "Completed late".
    done('Implement account balance endpoint', 'Backend', 2,
        TaskPriority.medium,
        dueDaysAgo: 4, completedDaysAgo: 3),
    done('Build login screen', 'Mobile', 4, TaskPriority.high,
        dueDaysAgo: 3, completedDaysAgo: 4),
    done('Draft release checklist', 'QA', 1, TaskPriority.low,
        dueDaysAgo: 2, completedDaysAgo: 3),
  ];
}
