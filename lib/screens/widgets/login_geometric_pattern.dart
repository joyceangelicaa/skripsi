import 'dart:math';
import 'package:flutter/material.dart';

class LoginGeometricPattern extends StatelessWidget {
  const LoginGeometricPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GeometricPatternPainter(),
      size: Size.infinite,
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final gold = const Color(0xFFD4A017);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 18; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 90 + 20;
      final opacity = random.nextDouble() * 0.12 + 0.03;

      strokePaint.color = gold.withValues(alpha: opacity);
      strokePaint.strokeWidth = random.nextDouble() * 1.5 + 0.5;
      strokePaint.style = random.nextBool() ? PaintingStyle.stroke : PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, strokePaint);
    }

    strokePaint.style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final x2 = random.nextDouble() * size.width;
      final y2 = random.nextDouble() * size.height;
      strokePaint.color = gold.withValues(alpha: random.nextDouble() * 0.08 + 0.02);
      strokePaint.strokeWidth = random.nextDouble() * 1.2 + 0.3;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), strokePaint);
    }

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final side = random.nextDouble() * 70 + 25;
      final angleOffset = random.nextDouble() * pi * 2;

      for (int j = 0; j < 3; j++) {
        final angle = angleOffset + (j * 2 * pi / 3);
        final px = cx + cos(angle) * side;
        final py = cy + sin(angle) * side;
        if (j == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();

      strokePaint.color = gold.withValues(alpha: random.nextDouble() * 0.08 + 0.02);
      strokePaint.style = PaintingStyle.stroke;
      strokePaint.strokeWidth = random.nextDouble() * 1.0 + 0.5;
      canvas.drawPath(path, strokePaint);
    }

    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      strokePaint.color = gold.withValues(alpha: random.nextDouble() * 0.15 + 0.05);
      strokePaint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
