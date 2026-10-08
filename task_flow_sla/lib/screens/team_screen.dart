import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';
import '../widgets/dialogs.dart';
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
      () => DatabaseHelper.instance.insertMember(draft),
      success: '${draft.name} added to the team',
    );
  }

  Future<void> _editMember(BuildContext context, TeamMember member) async {
    final edited = await showMemberFormDialog(
      context,
      member: member,
      takenEmails:
          members.where((m) => m.id != member.id).map((m) => m.email),
    );
    if (edited == null || !context.mounted) return;
    await _save(
      context,
      () => DatabaseHelper.instance.updateMember(edited),
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
    );
    if (!confirmed || !context.mounted) return;
    await _save(
      context,
      () => DatabaseHelper.instance.deleteMember(member.id!),
      success: '${member.name} removed',
    );
  }

  Future<void> _save(
    BuildContext context,
    Future<void> Function() write, {
    required String success,
  }) async {
    try {
      await write();
      await onChanged();
      if (context.mounted) showMessage(context, success);
    } catch (_) {
      if (context.mounted) showMessage(context, 'Could not save the change.');
    }
  }

  Future<void> _switchUser(BuildContext context) async {
    final chosen = await showModalBottomSheet<TeamMember>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Switch user',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final member in members)
              ListTile(
                leading: MemberAvatar(member: member, radius: 18),
                title: Text(member.name),
                subtitle: Text(member.role),
                trailing: member.id == currentUser.id
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, member),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen.id == currentUser.id) return;
    try {
      await SessionService.switchUser(chosen.id!);
      await onChanged();
      if (context.mounted) showMessage(context, 'Signed in as ${chosen.name}');
    } catch (_) {
      if (context.mounted) showMessage(context, 'Could not switch user.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: onOpenMenu,
        ),
        actions: [
          IconButton(
            tooltip: 'Add member',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _addMember(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSignedInCard(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
            child: Text(
              'Members (${members.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final (index, member) in members.indexed) ...[
                  if (index > 0) const Divider(),
                  _MemberTile(
                    member: member,
                    isCurrentUser: member.id == currentUser.id,
                    taskCount: _tasksOf(member).length,
                    counts: Sla.countByStatus(
                      _tasksOf(member),
                      now: now,
                    ),
                    onEdit: () => _editMember(context, member),
                    onRemove: () => _removeMember(context, member),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
        child: Column(
          children: [
            ListTile(
              leading: MemberAvatar(
                member: currentUser,
                radius: 24,
                filled: true,
              ),
              title: Text(
                currentUser.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${currentUser.role}\n${currentUser.email}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: const StatusPill(
                label: 'Signed in',
                background: Color(0xFFDDF1E6),
                foreground: Color(0xFF14653F),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _switchUser(context),
                      child: const Text('Switch user'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.overdue,
                        side: const BorderSide(color: AppColors.overdue),
                      ),
                      onPressed: onSignOut,
                      child: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
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

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 6, 2, 6),
      leading: MemberAvatar(member: member, radius: 22),
      title: Text.rich(
        TextSpan(
          text: member.name,
          children: [
            if (isCurrentUser)
              const TextSpan(
                text: '  (You)',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
          ],
        ),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${member.role} · $taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: badges),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Member actions',
        icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
        onSelected: (value) => value == 'edit' ? onEdit() : onRemove(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'remove', child: Text('Remove')),
        ],
      ),
    );
  }
}
