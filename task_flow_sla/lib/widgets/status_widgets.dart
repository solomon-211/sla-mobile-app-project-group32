import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';

/// Colours and icon for one SLA status, shared by badges, cards and charts.
class SlaStyle {
  final Color color;
  final Color background;
  final Color foreground;
  final IconData icon;

  const SlaStyle._(this.color, this.background, this.foreground, this.icon);

  static SlaStyle of(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return const SlaStyle._(
          AppColors.onTrack,
          Color(0xFFDDF1E6),
          Color(0xFF14653F),
          Icons.check_circle_outline,
        );
      case SlaStatus.atRisk:
        return const SlaStyle._(
          AppColors.atRisk,
          Color(0xFFFCEBD0),
          Color(0xFF8A5200),
          Icons.warning_amber_rounded,
        );
      case SlaStatus.overdue:
        return const SlaStyle._(
          AppColors.overdue,
          Color(0xFFFBDCD9),
          Color(0xFFA3221A),
          Icons.schedule,
        );
      case SlaStatus.completed:
        return const SlaStyle._(
          AppColors.completed,
          Color(0xFFDEE5F6),
          Color(0xFF2B4488),
          Icons.done_all,
        );
    }
  }
}

Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return AppColors.onTrack;
    case TaskPriority.medium:
      return AppColors.priorityMedium;
    case TaskPriority.high:
      return AppColors.overdue;
  }
}

/// Small rounded label, e.g. "3 done".
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppText.pill.copyWith(color: foreground)),
    );
  }
}

/// The SLA badge shown on every task.
class SlaBadge extends StatelessWidget {
  const SlaBadge({super.key, required this.status});

  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(status);
    return StatusPill(
      label: status.label,
      background: style.background,
      foreground: style.foreground,
    );
  }
}
