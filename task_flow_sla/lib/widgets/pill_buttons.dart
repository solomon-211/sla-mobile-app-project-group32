import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Main call-to-action: dark pill with the label on the left and a moss
/// circle with an arrow on the right.
///
/// Animations: the button scales to 0.96 while pressed, and the arrow nudges
/// 5px to the right every 2.4 seconds to invite a tap.
class PrimaryPillButton extends StatefulWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
    this.nudge = true,
    this.height = 64,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData icon;

  /// Shows a spinner in the circle and ignores taps.
  final bool loading;

  /// Whether the icon nudges sideways (off for non-arrow icons).
  final bool nudge;
  final double height;

  @override
  State<PrimaryPillButton> createState() => _PrimaryPillButtonState();
}

class _PrimaryPillButtonState extends State<PrimaryPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// 0 for most of the cycle, then +5px, a small -1px bounce, back to 0.
  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 70),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 5.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 5.0,
        end: -1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 10,
    ),
  ]).animate(_nudge);

  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncNudge();
  }

  @override
  void didUpdateWidget(PrimaryPillButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNudge();
  }

  /// Runs the nudge only when it is wanted and the user has not asked the
  /// system to reduce motion.
  void _syncNudge() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final run = widget.nudge && _enabled && !reduceMotion;
    if (run && !_nudge.isAnimating) {
      _nudge.repeat();
    } else if (!run && _nudge.isAnimating) {
      _nudge
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: widget.onPressed == null ? 0.5 : 1,
          duration: const Duration(milliseconds: 200),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x382B2E2D),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: AppColors.ink,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _enabled ? widget.onPressed : null,
                onHighlightChanged: (down) => setState(() => _pressed = down),
                child: SizedBox(
                  height: widget.height,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.button(),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.moss,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: widget.loading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.onMoss,
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _offset,
                                  builder: (context, child) =>
                                      Transform.translate(
                                        offset: Offset(_offset.value, 0),
                                        child: child,
                                      ),
                                  child: Icon(
                                    widget.icon,
                                    size: 22,
                                    color: AppColors.onMoss,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action: outlined pill, 56 to 64px tall.
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.ink,
    this.background = Colors.transparent,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Border, text and icon colour.
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: background,
          side: BorderSide(color: color, width: 1.5),
          minimumSize: Size.fromHeight(height),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.manrope(
                  15,
                  weight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
