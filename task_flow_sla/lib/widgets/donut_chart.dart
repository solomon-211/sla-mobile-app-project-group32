import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DonutSegment {
  final int value;
  final Color color;

  const DonutSegment(this.value, this.color);

  @override
  bool operator ==(Object other) =>
      other is DonutSegment && other.value == value && other.color == color;

  @override
  int get hashCode => Object.hash(value, color);
}

/// Ring chart drawn with CustomPaint, with a number and label in the middle.
/// Defaults match the dark dashboard card.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 116,
    this.strokeWidth = 13,
    this.trackColor = AppColors.darkCardAlt,
    this.valueColor = AppColors.paper,
    this.labelColor = AppColors.textMutedDark,
  });

  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;
  final double strokeWidth;

  /// Ring colour when there is no data.
  final Color trackColor;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DonutPainter(segments, strokeWidth, trackColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerValue, style: AppText.sora(26, color: valueColor)),
              Text(
                centerLabel,
                style: AppText.manrope(
                  11,
                  weight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.strokeWidth, this.trackColor);

  final List<DonutSegment> segments;
  final double strokeWidth;
  final Color trackColor;

  /// Small gap between segments, in radians.
  static const _gap = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final visible = segments.where((s) => s.value > 0).toList();
    final total = visible.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) {
      // Empty ring so the chart still has a shape when there are no tasks.
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor);
      return;
    }

    // Start at 12 o'clock and draw each segment clockwise, leaving a small
    // gap between segments when there is more than one.
    final gap = visible.length > 1 ? _gap : 0.0;
    var startAngle = -math.pi / 2;
    for (final segment in visible) {
      final sweep = 2 * math.pi * segment.value / total;
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        math.max(sweep - gap, 0.01),
        false,
        paint..color = segment.color,
      );
      startAngle += sweep;
    }
  }

  /// Only repaint when the numbers or colours actually changed.
  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        !listEquals(oldDelegate.segments, segments);
  }
}
