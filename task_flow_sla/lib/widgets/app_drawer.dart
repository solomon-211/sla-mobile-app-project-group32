import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';

/// Side menu opened from the menu icon on each tab. It mirrors the bottom
/// navigation and adds shortcuts that have no tab of their own.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentUser,
    required this.selectedTab,
    required this.onSelectTab,
    required this.onNewTask,
    required this.onSignOut,
  });

  final TeamMember currentUser;
  final int selectedTab;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onNewTask;
  final VoidCallback onSignOut;

  static const _tabs = [
    (Icons.home_outlined, 'Dashboard'),
    (Icons.checklist_outlined, 'Tasks'),
    (Icons.group_outlined, 'Team'),
  ];

  /// Closes the drawer first, then runs the action behind it.
  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                currentUser.initials,
                style: AppText.heading.copyWith(color: AppColors.primary),
              ),
            ),
            accountName: Text(
              currentUser.name,
              style: AppText.bodyStrong.copyWith(color: Colors.white),
            ),
            accountEmail: Text('${currentUser.role} · ${currentUser.email}'),
          ),
          for (final (index, (icon, label)) in _tabs.indexed)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              selected: index == selectedTab,
              selectedColor: AppColors.primary,
              selectedTileColor: AppColors.background,
              onTap: () => _closeThen(context, () => onSelectTab(index)),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_task),
            title: const Text('New task'),
            onTap: () => _closeThen(context, onNewTask),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.overdue),
            title: Text(
              'Sign out',
              style: AppText.body.copyWith(color: AppColors.overdue),
            ),
            onTap: () => _closeThen(context, onSignOut),
          ),
        ],
      ),
    );
  }
}
