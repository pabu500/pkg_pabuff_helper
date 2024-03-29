import 'package:flutter/material.dart';

class xtBox extends StatelessWidget {
  xtBox({Key? key, this.child, this.color, this.padding, this.margin})
      : super(key: key);

  final Widget? child;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      color: color,
      padding: padding,
      margin: margin,
    );
  }
}
