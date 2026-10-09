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
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 110,
    this.strokeWidth = 16,
  });

  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DonutPainter(segments, strokeWidth),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerValue, style: AppText.heading),
              Text(
                centerLabel,
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.strokeWidth);

  final List<DonutSegment> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final total = segments.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) {
      // Empty ring so the chart still has a shape when there are no tasks.
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = AppColors.border);
      return;
    }

    // Start at 12 o'clock and draw each segment clockwise.
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweep = 2 * math.pi * segment.value / total;
      canvas.drawArc(rect, startAngle, sweep, false, paint..color = segment.color);
      startAngle += sweep;
    }
  }

  /// Only repaint when the numbers or colours actually changed.
  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        !listEquals(oldDelegate.segments, segments);
  }
}
