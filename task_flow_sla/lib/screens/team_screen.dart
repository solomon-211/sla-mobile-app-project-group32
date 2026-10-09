import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';
import '../widgets/app_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/icon_circle_button.dart';
import '../widgets/member_avatar.dart';
import '../widgets/member_form_dialog.dart';
import '../widgets/status_widgets.dart';

/// Team Members / Profile: the signed-in user, plus every member with their
/// workload broken down by SLA status.
class TeamScreen extends StatelessWidget {
  const TeamScreen({
    super.key,
    required this.tasks,
    required this.members,
    required this.currentUser,
    required this.onChanged,
    required this.onOpenMenu,
    required this.onSignOut,
  });

  final List<Task> tasks;
  final List<TeamMember> members;
  final TeamMember currentUser;
  final Future<void> Function() onChanged;

  /// Opens the navigation drawer owned by HomeShell.
  final VoidCallback onOpenMenu;

  /// Sign-out lives in HomeShell so the drawer and this screen share it.
  final VoidCallback onSignOut;

  Iterable<Task> _tasksOf(TeamMember member) {
    return tasks.where((task) => task.assigneeId == member.id);
  }

  Future<void> _addMember(BuildContext context) async {
    final draft = await showMemberFormDialog(
      context,
      takenEmails: members.map((m) => m.email),
      colorIndex: members.length,
    );
    if (draft == null || !context.mounted) return;
    await _save(
      context,
      () => DatabaseHelper.instance.insertMember(draft.member),
      success: '${draft.member.name} added to the team',
    );
  }

  Future<void> _editMember(BuildContext context, TeamMember member) async {
    final draft = await showMemberFormDialog(
      context,
      member: member,
      takenEmails: members.where((m) => m.id != member.id).map((m) => m.email),
    );
    if (draft == null || !context.mounted) return;
    await _save(
      context,
      () => DatabaseHelper.instance.updateMember(draft.member),
      success: 'Profile updated',
    );
  }

  Future<void> _removeMember(BuildContext context, TeamMember member) async {
    if (member.id == currentUser.id) {
      showMessage(context, 'You cannot remove the signed-in member.');
      return;
    }
    final taskCount = _tasksOf(member).length;
    if (taskCount > 0) {
      showMessage(
        context,
        'Reassign or delete ${member.firstName}\'s $taskCount '
        '${taskCount == 1 ? 'task' : 'tasks'} first.',
      );
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove member?',
      message: '${member.name} will be removed from the team.',
      confirmLabel: 'Remove',
      destructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (!confirmed || !context.mounted) return;
    await _save(
      context,
      () => DatabaseHelper.instance.deleteMember(member.id!),
      success: '${member.name} removed',
    );
  }

  /// Saves the change, reloads the shared data, then shows feedback.
  Future<void> _save(
    BuildContext context,
    Future<void> Function() write, {
    required String success,
  }) {
    return runWithFeedback(context, () async {
      await write();
      await onChanged();
    }, success: success);
  }

  Future<void> _switchUser(BuildContext context) async {
    final chosen = await showModalBottomSheet<TeamMember>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text('Switch user', style: AppText.sora(22)),
            ),
            for (final member in members)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: MemberAvatar(member: member, radius: 20),
                title: Text(member.name, style: AppText.cardTitle()),
                subtitle: Text(
                  member.role,
                  style: AppText.manrope(
                    13,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: member.id == currentUser.id
                    ? const Icon(Icons.check_circle, color: AppColors.moss)
                    : null,
                onTap: () => Navigator.pop(sheetContext, member),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen.id == currentUser.id || !context.mounted) {
      return;
    }
    await runWithFeedback(
      context,
      () async {
        await SessionService.switchUser(chosen.id!);
        await onChanged();
      },
      success: 'Signed in as ${chosen.name}',
      failure: 'Could not switch user.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Bottom padding keeps the last card clear of the floating nav.
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 116),
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
              child: Text('Team Members', style: AppText.screenTitle()),
            ),
            _buildSignedInCard(context, now),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Members (${members.length})',
                      style: AppText.section(),
                    ),
                  ),
                  Text(
                    '${tasks.length} tasks shared',
                    style: AppText.manrope(
                      13,
                      weight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberCard(
                  member: member,
                  isCurrentUser: member.id == currentUser.id,
                  taskCount: _tasksOf(member).length,
                  counts: Sla.countByStatus(_tasksOf(member), now: now),
                  onEdit: () => _editMember(context, member),
                  onRemove: () => _removeMember(context, member),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconCircleButton(
          icon: Icons.notes_rounded,
          tooltip: 'Open menu',
          onPressed: onOpenMenu,
        ),
        Tooltip(
          message: 'Add member',
          child: Material(
            color: AppColors.ink,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _addMember(context),
              child: SizedBox(
                height: 46,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 20,
                        color: AppColors.moss,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add',
                        style: AppText.manrope(
                          14,
                          weight: FontWeight.w800,
                          color: AppColors.paper,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dark card for the signed-in user with their own task stats.
  Widget _buildSignedInCard(BuildContext context, DateTime now) {
    final myTasks = _tasksOf(currentUser);
    final myCounts = Sla.countByStatus(myTasks, now: now);
    final muted = AppText.manrope(
      13,
      weight: FontWeight.w600,
      color: AppColors.textMutedDark,
    );

    Widget stat(int value, String label, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: AppText.sora(22, color: color)),
              Text(
                label,
                style: AppText.manrope(
                  12,
                  weight: FontWeight.w600,
                  color: AppColors.textMutedDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      color: AppColors.ink,
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.moss,
                child: Text(
                  currentUser.initials,
                  style: AppText.sora(20, color: AppColors.onMoss),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.name,
                      style: AppText.sora(20, color: AppColors.paper),
                    ),
                    const SizedBox(height: 2),
                    Text(currentUser.role, style: muted),
                    Text(
                      currentUser.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusPill(
                label: 'Signed in',
                background: AppColors.moss,
                foreground: AppColors.onMoss,
                dot: AppColors.onMoss,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat(myTasks.length, 'tasks', AppColors.paper),
              const SizedBox(width: 8),
              stat(
                myCounts[SlaStatus.atRisk]!,
                'at risk',
                AppColors.amberOnDark,
              ),
              const SizedBox(width: 8),
              stat(myCounts[SlaStatus.completed]!, 'done', AppColors.moss),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: 'Switch user',
                  icon: Icons.swap_horiz_rounded,
                  background: AppColors.paper,
                  foreground: AppColors.ink,
                  onPressed: () => _switchUser(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  foreground: AppColors.coralText,
                  borderColor: AppColors.coralText,
                  onPressed: onSignOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 50px pill button used inside the dark signed-in card.
class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.background = Colors.transparent,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.manrope(
                    14,
                    weight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isCurrentUser,
    required this.taskCount,
    required this.counts,
    required this.onEdit,
    required this.onRemove,
  });

  final TeamMember member;
  final bool isCurrentUser;
  final int taskCount;
  final Map<SlaStatus, int> counts;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  /// Badges for this member: problems first, then finished work.
  List<Widget> _buildBadges() {
    Widget pill(String label, SlaStatus status) {
      final style = SlaStyle.of(status);
      return StatusPill(
        label: label,
        background: style.background,
        foreground: style.foreground,
      );
    }

    final overdue = counts[SlaStatus.overdue]!;
    final atRisk = counts[SlaStatus.atRisk]!;
    final onTrack = counts[SlaStatus.onTrack]!;
    final done = counts[SlaStatus.completed]!;

    return [
      if (overdue > 0) pill('$overdue overdue', SlaStatus.overdue),
      if (atRisk > 0) pill('$atRisk at risk', SlaStatus.atRisk),
      if (overdue == 0 && atRisk == 0 && onTrack > 0)
        pill('All on track', SlaStatus.onTrack),
      if (done > 0) pill('$done done', SlaStatus.completed),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final badges = _buildBadges();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(
        children: [
          MemberAvatar(member: member, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(member.name, style: AppText.cardTitle()),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'You',
                          style: AppText.manrope(
                            11,
                            weight: FontWeight.w800,
                            color: AppColors.moss,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${member.role} · $taskCount '
                  '${taskCount == 1 ? 'task' : 'tasks'}',
                  style: AppText.manrope(
                    13,
                    weight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(spacing: 6, runSpacing: 6, children: badges),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Member options',
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
            onSelected: (value) => value == 'edit' ? onEdit() : onRemove(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}
