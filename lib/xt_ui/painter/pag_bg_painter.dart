import 'package:flutter/material.dart';

class NeoDotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5) // Adjust color and opacity
      ..style = PaintingStyle.fill;

    final dotRadius = 1.5; // Adjust the dot size
    final spacing = 15.0; // Adjust the spacing between dots

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
