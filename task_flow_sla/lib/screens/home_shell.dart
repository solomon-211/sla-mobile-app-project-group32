import 'dart:async';

import 'package:flutter/material.dart';

import '../app_router.dart';
import '../data/seed_data.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../utils/sla.dart';
import '../utils/validators.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dialogs.dart';
import 'dashboard_screen.dart';
import 'task_list_screen.dart';
import 'team_screen.dart';

/// Holds the bottom navigation and the data shared by the three tabs.
///
/// State is "lifted up" to this widget: it loads tasks and members from the
/// database once, passes them down to the tabs, and reloads + calls
/// setState() whenever a tab reports a change through [_loadData].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _dashboardTab = 0;
  static const _tasksTab = 1;

  /// Lets the tabs open this Scaffold's drawer from their own app bars.
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;

  /// Rebuilds every minute so SLA statuses move from On Track to At Risk to
  /// Overdue while the app is open, without the user having to refresh.
  Timer? _clock;

  int _tabIndex = _dashboardTab;

  /// SLA statuses the Tasks tab is filtered to. Null means "All". Kept here
  /// so dashboard cards can set it and it survives switching tabs.
  Set<SlaStatus>? _taskFilter;

  bool _loading = true;
  String? _error;
  List<Task> _tasks = [];
  List<TeamMember> _members = [];
  Map<int, TeamMember> _membersById = {};
  TeamMember? _currentUser;
  String _projectName = seedProjectName;

  @override
  void initState() {
    super.initState();
    _loadData();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper.instance;
      final members = await db.getMembers();
      final tasks = await db.getTasks();
      final userId = await SessionService.currentUserId();
      final projectName =
          await SessionService.projectName(fallback: seedProjectName);
      if (!mounted) return;

      final user = members.where((m) => m.id == userId).firstOrNull;
      if (user == null) {
        // Nobody is signed in (or the member was removed): back to sign in.
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signIn,
          (route) => false,
        );
        return;
      }

      setState(() {
        _members = members;
        _membersById = {for (final m in members) m.id!: m};
        _tasks = tasks;
        _currentUser = user;
        _projectName = projectName;
        _loading = false;
        _error = null;
      });
    } catch (error, stack) {
      logError('Could not load project data', error, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your project data.';
      });
    }
  }

  void _selectTab(int index) => setState(() => _tabIndex = index);

  /// Opens the Tasks tab with [filter] applied (null shows every task).
  void _showTasks(Set<SlaStatus>? filter) {
    setState(() {
      _tabIndex = _tasksTab;
      _taskFilter = filter;
    });
  }

  void _setTaskFilter(Set<SlaStatus>? filter) {
    setState(() => _taskFilter = filter);
  }

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _openRoute(String route) async {
    await Navigator.pushNamed(context, route);
    await _loadData();
  }

  Future<void> _renameProject() async {
    final name = await showTextInputDialog(
      context,
      title: 'Rename project',
      label: 'Project name',
      initialValue: _projectName,
      maxLength: Validators.projectNameMaxLength,
      validator: (value) => Validators.requiredText(
        value,
        'Project name',
        min: 3,
        max: Validators.projectNameMaxLength,
      ),
    );
    if (name == null || name == _projectName || !mounted) return;
    await runWithFeedback(
      context,
      () async {
        await SessionService.setProjectName(name);
        if (mounted) setState(() => _projectName = name);
      },
      success: 'Project renamed',
      failure: 'Could not rename the project.',
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'Your tasks stay saved on this device.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;
    try {
      // Clear the saved user, then remove every screen so Back cannot return.
      await SessionService.signOut();
    } catch (error, stack) {
      logError('Could not sign out', error, stack);
      if (mounted) showMessage(context, 'Could not sign out.');
      return;
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.signIn,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    // While the drawer is open, Back closes it instead of leaving the app.
    return PopScope(
      canPop: !_drawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _scaffoldKey.currentState?.closeDrawer();
      },
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: (isOpen) => setState(() => _drawerOpen = isOpen),
        drawer: user == null
            ? null
            : AppDrawer(
                currentUser: user,
                selectedTab: _tabIndex,
                onSelectTab: _selectTab,
                onNewTask: () => _openRoute(AppRoutes.taskForm),
                onSignOut: _signOut,
              ),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: _selectTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Team',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = _currentUser;
    if (_error != null || user == null) {
      return SafeArea(
        child: EmptyState(
          icon: Icons.error_outline,
          title: _error ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    // IndexedStack keeps all three tabs alive, so the Tasks tab remembers its
    // search text and sort order when the user switches tabs and comes back.
    return IndexedStack(
      index: _tabIndex,
      children: [
        DashboardScreen(
          tasks: _tasks,
          membersById: _membersById,
          currentUser: user,
          projectName: _projectName,
          onRenameProject: _renameProject,
          onChanged: _loadData,
          onShowTasks: _showTasks,
          onOpenMenu: _openMenu,
        ),
        TaskListScreen(
          tasks: _tasks,
          membersById: _membersById,
          filter: _taskFilter,
          onFilterChanged: _setTaskFilter,
          onChanged: _loadData,
          onOpenMenu: _openMenu,
        ),
        TeamScreen(
          tasks: _tasks,
          members: _members,
          currentUser: user,
          onChanged: _loadData,
          onOpenMenu: _openMenu,
          onSignOut: _signOut,
        ),
      ],
    );
  }
}
