import 'dart:math';
import 'package:flutter/material.dart';

class PatternPainter extends CustomPainter {
  const PatternPainter({
    Key? key,
    this.pattern = 'solid',
    this.color = Colors.black,
    this.spacing = 8,
    this.width,
    this.height,
  });
  final String pattern;
  final Color color;
  final double spacing;
  final double? width;
  final double? height;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color // Set the color of the pattern
      ..style = PaintingStyle.stroke; // Set the painting style to stroke

    // Define the spacing between the lines
    double spacing = this.spacing;

    if (pattern == 'diagonal') {
      // Draw diagonal lines across the canvas
      for (double i = 0;
          i < (width ?? size.width) + (height ?? size.height);
          i += spacing * sqrt(2)) {
        canvas.drawLine(
          Offset(0, i),
          Offset((width ?? size.width), i - (width ?? size.width)),
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
