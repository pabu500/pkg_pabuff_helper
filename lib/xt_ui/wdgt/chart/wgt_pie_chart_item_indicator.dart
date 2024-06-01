import 'package:flutter/material.dart';

class WgtPieChartItemIndicator extends StatefulWidget {
  const WgtPieChartItemIndicator(
      {super.key,
      required this.displayLabel,
      this.size,
      this.color,
      this.isSquare,
      this.suffix});
  // final Color color;
  final Widget displayLabel;
  final bool? isSquare;
  final double? size;
  final Color? color;
  final Widget? suffix;

  @override
  State<WgtPieChartItemIndicator> createState() =>
      _WgtPieChartItemIndicatorState();
}

class _WgtPieChartItemIndicatorState extends State<WgtPieChartItemIndicator> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: widget.isSquare == null
                ? BoxShape.rectangle
                : widget.isSquare!
                    ? BoxShape.rectangle
                    : BoxShape.circle,
            color: widget.color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        widget.displayLabel,
        widget.suffix ?? Container(),
      ],
    );
  }
}
