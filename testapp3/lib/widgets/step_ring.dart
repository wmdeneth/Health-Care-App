import 'dart:math';

import 'package:flutter/material.dart';

class StepRing extends StatelessWidget {
  final int steps;
  final int goal;

  const StepRing({super.key, required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    final ratio = (steps / goal).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _SemiRingPainter(progress: value),
          child: SizedBox(
            height: 180,
            width: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$steps',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of $goal steps',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SemiRingPainter extends CustomPainter {
  final double progress;

  _SemiRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    const startAngle = pi;
    const sweepAngle = pi;

    final bgPaint =
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    final fgPaint =
        Paint()
          ..shader = const SweepGradient(
            colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _SemiRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
