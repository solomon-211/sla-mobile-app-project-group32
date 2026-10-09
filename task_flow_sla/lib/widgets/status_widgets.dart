import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/sla.dart';

/// Colours and icon for one SLA status, shared by badges, cards and charts.
class SlaStyle {
  /// Solid colour for charts, tick bars and icon circles.
  final Color color;

  /// Badge background and text.
  final Color background;
  final Color foreground;

  /// Text colour for this status on dark backgrounds.
  final Color onDark;

  /// Small dot on filter chips and section headers.
  final Color dot;
  final IconData icon;

  const SlaStyle._({
    required this.color,
    required this.background,
    required this.foreground,
    required this.onDark,
    required this.dot,
    required this.icon,
  });

  static SlaStyle of(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return const SlaStyle._(
          color: AppColors.moss,
          background: AppColors.moss,
          foreground: AppColors.onMoss,
          onDark: AppColors.mossLight,
          dot: AppColors.mossDeep,
          icon: Icons.check_rounded,
        );
      case SlaStatus.atRisk:
        return const SlaStyle._(
          color: AppColors.amber,
          background: AppColors.amberBg,
          foreground: AppColors.amberText,
          onDark: AppColors.amberOnDark,
          dot: AppColors.amber,
          icon: Icons.warning_amber_rounded,
        );
      case SlaStatus.overdue:
        return const SlaStyle._(
          color: AppColors.coral,
          background: AppColors.coral,
          foreground: AppColors.onCoral,
          onDark: AppColors.coralText,
          dot: AppColors.coral,
          icon: Icons.schedule_rounded,
        );
      case SlaStatus.completed:
        return const SlaStyle._(
          color: AppColors.paper,
          background: AppColors.doneBg,
          foreground: AppColors.doneText,
          onDark: AppColors.textSoftDark,
          dot: AppColors.doneDot,
          icon: Icons.done_all_rounded,
        );
    }
  }
}

Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return AppColors.mossDeep;
    case TaskPriority.medium:
      return AppColors.amber;
    case TaskPriority.high:
      return AppColors.coral;
  }
}

/// Small fully rounded label, e.g. "3 done".
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.dot,
  });

  final String label;
  final Color background;
  final Color foreground;

  /// Optional leading dot, e.g. on the "Signed in" pill.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            CircleAvatar(radius: 3, backgroundColor: dot),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: AppText.pill(color: foreground),
          ),
        ],
      ),
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
