import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance.dart';
import '../widgets/pill_buttons.dart';

/// Landing: a short carousel showing what the app does, then
/// "Get started" (Register) or "I already have an account" (Sign In).
///
/// Purely visual: the slides use sample content and read no data.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _slideCount = 3;
  static const _autoplayEvery = Duration(milliseconds: 3200);

  /// Autoplay waits this long after the user last touched the carousel.
  static const _pauseAfterTouch = Duration(seconds: 4);

  final _carousel = CarouselController();
  Timer? _autoplay;
  DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _autoplay = Timer.periodic(_autoplayEvery, (_) => _advance());
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _carousel.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted || !_carousel.hasClients) return;
    if (MediaQuery.of(context).disableAnimations) return;
    if (DateTime.now().difference(_lastTouch) < _pauseAfterTouch) return;
    _goTo((_current + 1) % _slideCount);
  }

  void _goTo(int index) {
    _carousel.animateToItem(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Any drag on the carousel pauses autoplay.
  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _lastTouch = DateTime.now();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildTop(), _buildButtons()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 36),
        SlideUpIn(
          delay: const Duration(milliseconds: 150),
          duration: const Duration(milliseconds: 700),
          distance: 28,
          child: SizedBox(
            height: 384,
            child: Semantics(
              label: 'What SprintTrack does, slide ${_current + 1} of 3',
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: CarouselView(
                  controller: _carousel,
                  itemExtent: 280,
                  shrinkExtent: 240,
                  itemSnapping: true,
                  enableSplash: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  onIndexChanged: (index) => setState(() => _current = index),
                  children: const [_PhotoSlide(), _ListSlide(), _OnTimeSlide()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SlideUpIn(
          delay: const Duration(milliseconds: 250),
          child: _buildDots(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, line) in [
                "Organize your team's",
                'project tasks',
                'better today!',
              ].indexed)
                RiseIn(
                  delay: Duration(milliseconds: 350 + index * 100),
                  child: Text(
                    line,
                    style: AppText.sora(
                      32,
                      height: 38,
                      letterSpacing: -1.2,
                      color: index == 2 ? AppColors.mossDeep : AppColors.ink,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SlideUpIn(
                delay: const Duration(milliseconds: 700),
                child: Text(
                  'Assign work, track every deadline and spot tasks at risk '
                  'before they slip.',
                  style: AppText.manrope(
                    15,
                    color: AppColors.textMuted,
                    height: 23,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < _slideCount; index++)
          Semantics(
            button: true,
            selected: index == _current,
            label: 'Show slide ${index + 1}',
            child: InkResponse(
              onTap: () {
                _lastTouch = DateTime.now();
                _goTo(index);
              },
              radius: 22,
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: const Cubic(0.65, 0, 0.35, 1),
                      width: index == _current ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _current
                            ? AppColors.ink
                            : AppColors.textMutedDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SlideUpIn(
            delay: const Duration(milliseconds: 850),
            child: PrimaryPillButton(
              label: 'Get started',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
            ),
          ),
          const SizedBox(height: 10),
          SlideUpIn(
            delay: const Duration(milliseconds: 950),
            child: OutlinePillButton(
              label: 'I already have an account',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.signIn),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase label at the top of each slide ("BEFORE", "AFTER").
Widget _eyebrow(String text, Color color) {
  return Text(
    text.toUpperCase(),
    style: AppText.manrope(
      11,
      weight: FontWeight.w800,
      color: color,
      letterSpacing: 1,
    ),
  );
}

/// Slide 1: a messy desk, "before" the app.
class _PhotoSlide extends StatelessWidget {
  const _PhotoSlide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // TODO: replace with licensed image
        Image.asset(
          'assets/images/sticky-desk.png',
          fit: BoxFit.cover,
          semanticLabel:
              'A desk buried under sticky notes, papers and a laptop',
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow('Before', AppColors.coralText),
                const SizedBox(height: 2),
                Text(
                  'Tasks on sticky notes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sora(17, color: AppColors.paper),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Slide 2: every task in one list.
class _ListSlide extends StatelessWidget {
  const _ListSlide();

  static const _rows = [
    (
      'BO',
      'Fix login token refresh',
      AppColors.paper,
      AppColors.ink,
      AppColors.coral,
    ),
    (
      'AK',
      'Write API error states',
      AppColors.moss,
      AppColors.onMoss,
      AppColors.amber,
    ),
    (
      'DA',
      'Set up CI for Android',
      AppColors.dotMuted,
      AppColors.ink,
      AppColors.moss,
    ),
    (
      'CM',
      'Design onboarding screens',
      AppColors.ground,
      AppColors.ink,
      AppColors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('After', AppColors.mossLight),
          const SizedBox(height: 10),
          Text(
            'Every task in one place',
            maxLines: 2,
            style: AppText.sora(20, color: AppColors.paper, height: 25),
          ),
          const SizedBox(height: 16),
          for (final (index, (initials, title, avatarBg, avatarFg, dot))
              in _rows.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                // The last row fades out to suggest the list continues.
                opacity: index == _rows.length - 1 ? 0.6 : 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardAlt,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: avatarBg,
                        child: Text(
                          initials,
                          style: AppText.manrope(
                            11,
                            weight: FontWeight.w800,
                            color: avatarFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.manrope(
                            13,
                            weight: FontWeight.w700,
                            color: AppColors.paper,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(radius: 5, backgroundColor: dot),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Slide 3: knowing what is at risk before it is late.
class _OnTimeSlide extends StatelessWidget {
  const _OnTimeSlide();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.moss,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eyebrow('On time', AppColors.onMoss),
              const SizedBox(height: 6),
              Text(
                "Know what's at risk before it's late",
                maxLines: 3,
                style: AppText.sora(20, color: AppColors.onMoss, height: 25),
              ),
            ],
          ),
          Center(
            child: SizedBox.square(
              dimension: 140,
              child: CustomPaint(
                painter: _RingPainter(0.72),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '62%',
                        style: AppText.sora(30, color: AppColors.onMoss),
                      ),
                      Text(
                        'sprint done',
                        style: AppText.manrope(
                          12,
                          weight: FontWeight.w700,
                          color: AppColors.onMoss,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('5 on track', AppColors.onMoss, AppColors.mossLight),
              _chip('2 at risk', AppColors.amberBg, AppColors.amberText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppText.pill(color: foreground)),
    );
  }
}

/// Progress ring with rounded ends, used on the "On time" slide.
class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      paint..color = AppColors.onMoss.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint
        ..color = AppColors.onMoss
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
