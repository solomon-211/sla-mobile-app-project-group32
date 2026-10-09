import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';

/// Circle with the member's initials. [member] may be null when a task points
/// at a member that no longer exists.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 22,
    this.filled = false,
    this.onDark = false,
  });

  final TeamMember? member;
  final double radius;

  /// Moss accent, used for the signed-in user.
  final bool filled;

  /// Swaps the dark ink avatar for a light one so it stays visible on dark
  /// cards.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.avatarPalette;
    var (background, foreground) = filled
        ? (AppColors.moss, AppColors.onMoss)
        : palette[(member?.colorIndex ?? 0) % palette.length];
    if (onDark && background == AppColors.ink) {
      (background, foreground) = (AppColors.paper, AppColors.ink);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        member?.initials ?? '?',
        style: AppText.manrope(
          radius * 0.6,
          weight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
