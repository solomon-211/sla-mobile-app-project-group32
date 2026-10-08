import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';

/// Circle with the member's initials. [member] may be null when a task points
/// at a member that no longer exists.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 20,
    this.filled = false,
  });

  final TeamMember? member;
  final double radius;

  /// Solid brand colour, used for the signed-in user.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.avatarPalette;
    final (background, foreground) = filled
        ? (AppColors.primary, Colors.white)
        : palette[(member?.colorIndex ?? 0) % palette.length];

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        member?.initials ?? '?',
        style: TextStyle(
          color: foreground,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
