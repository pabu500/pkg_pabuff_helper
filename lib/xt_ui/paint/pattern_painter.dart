import 'dart:math';
import 'package:flutter/material.dart';

class PatternPainter extends CustomPainter {
  const PatternPainter({
    Key? key,
    this.pattern = 'diagonal',
    this.color = Colors.black,
    this.spacing = 10,
    this.backgroundColor = Colors.white,
    // this.width,
    // this.height,
  });
  final String pattern;
  final Color color;
  final double spacing;
  final Color backgroundColor;
  // final double? width;
  // final double? height;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);

    final paint = Paint()
      ..color = color // Set the color of the pattern
      ..style = PaintingStyle.stroke; // Set the painting style to stroke

    // Define the spacing between the lines
    double spacing = this.spacing;

    if (pattern == 'diagonal') {
      // Draw diagonal lines across the canvas
      for (double i = 0; i < width + height; i += spacing * sqrt(2)) {
        canvas.drawLine(
          Offset(i <= height ? 0 : (i - height), i <= height ? i : height),
          Offset(i <= width ? i : width, i <= width ? 0 : i - width),
          paint,
        );
      }
    } else if (pattern == 'rDiagonal') {
      // Draw diagonal lines in reverse direction
      for (double i = width + height; i > 0; i -= spacing * sqrt(2)) {
        canvas.drawLine(
          Offset(i >= height ? i - height : 0, i >= height ? 0 : height - i),
          Offset(
              i >= width ? width : i, i >= width ? height + width - i : height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
