import 'package:flutter/material.dart';

class NeoDotPatternPainter extends CustomPainter {
  const NeoDotPatternPainter({
    Key? key,
    this.color,
  });

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Colors.grey.withAlpha(130) // Adjust color and opacity
      ..style = PaintingStyle.fill;

    const dotRadius = 1.0; // Adjust the dot size
    const spacing = 21.0; // Adjust the spacing between dots

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
