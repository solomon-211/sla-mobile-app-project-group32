import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 46px round icon button used for back, menu, sort and "more" actions.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.borderColor,
    this.size = 46,
    this.iconSize = 20,
  });

  final IconData icon;

  /// Read by screen readers and shown on long press.
  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
      ),
    );
  }
}
