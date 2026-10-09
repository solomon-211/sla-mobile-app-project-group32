import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

/// Side menu opened from the menu button on the Tasks and Team tabs. It
/// mirrors the bottom navigation and adds shortcuts that have no tab.
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
    (Icons.checklist_rounded, 'Tasks'),
    (Icons.group_outlined, 'Team'),
  ];

  /// Closes the drawer first, then runs the action behind it.
  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  Widget _item({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Color color = AppColors.ink,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? AppColors.ink : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? AppColors.moss : color,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: AppText.manrope(
                      15,
                      weight: FontWeight.w800,
                      color: selected ? AppColors.paper : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // Signed-in user, styled like the dark profile card on Team.
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  MemberAvatar(member: currentUser, radius: 26, filled: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sora(18, color: AppColors.paper),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentUser.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.manrope(
                            13,
                            weight: FontWeight.w600,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                        Text(
                          currentUser.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.manrope(
                            13,
                            weight: FontWeight.w600,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final (index, (icon, label)) in _tabs.indexed)
              _item(
                icon: icon,
                label: label,
                selected: index == selectedTab,
                onTap: () => _closeThen(context, () => onSelectTab(index)),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Divider(color: AppColors.barEmpty),
            ),
            _item(
              icon: Icons.add_task,
              label: 'New task',
              onTap: () => _closeThen(context, onNewTask),
            ),
            _item(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              color: AppColors.error,
              onTap: () => _closeThen(context, onSignOut),
            ),
          ],
        ),
      ),
    );
  }
}
