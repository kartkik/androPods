import 'package:flutter/material.dart';
import 'dart:math';

class BatteryProgressPainter extends CustomPainter {
  final double progress; // Value between 0.0 and 1.0

  BatteryProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Paint progressPaint = Paint()
      ..color = progress > 0.5 ? Colors.green : Colors.red
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startAngle = 5 * pi / 6; // Start from a slight left tilt
    double sweepAngle =
        (4 * pi / 3) * progress; // Increase to 240 degrees (4π/3 radians)

    // Define the arc's bounding box
    Rect arcRect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: size.width / 2,
    );

    // Draw the background arc
    canvas.drawArc(
      arcRect,
      startAngle,
      4 * pi / 3, // 240 degrees (More than a semi-circle)
      false,
      backgroundPaint,
    );

    // Draw the progress arc
    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(BatteryProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
