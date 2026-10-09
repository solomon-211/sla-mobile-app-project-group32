import 'package:flutter/material.dart';

/// The ease-out curve the mockups use for entrance animations.
const _entranceCurve = Cubic(0.2, 0.8, 0.2, 1);

/// Fades a widget in while it slides up 24px, after [delay].
///
/// The delay is built into the animation (no Timer), so nothing is left
/// pending if the screen closes early. Plays instantly when the system asks
/// for reduced motion.
class SlideUpIn extends StatefulWidget {
  const SlideUpIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.distance = 24,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double distance;

  @override
  State<SlideUpIn> createState() => _SlideUpInState();
}

class _SlideUpInState extends State<SlideUpIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(_delayShare, 1, curve: _entranceCurve),
  );

  double get _delayShare {
    final total = (widget.delay + widget.duration).inMicroseconds;
    return total == 0 ? 0 : widget.delay.inMicroseconds / total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.distance * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Reveals text by sliding it up from behind a mask (the "rise" effect on
/// screen titles), after [delay].
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(_delayShare, 1, curve: _entranceCurve),
  );

  double get _delayShare {
    final total = (widget.delay + widget.duration).inMicroseconds;
    return total == 0 ? 0 : widget.delay.inMicroseconds / total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1.1 * (1 - _progress.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
