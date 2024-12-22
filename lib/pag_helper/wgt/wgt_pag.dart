import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtPaG extends StatefulWidget {
  const WgtPaG({
    super.key,
    this.size = 35,
    this.colorA,
    this.colorB,
    this.colorC,
    this.showLabel = true,
    this.conextLabel = 'Services',
    this.showSquareBorder = true,
  });

  final double size;
  final Color? colorA;
  final Color? colorB;
  final Color? colorC;
  final bool showLabel;
  final String conextLabel;
  final bool showSquareBorder;

  @override
  State<WgtPaG> createState() => _WgtPaGState();
}

class _WgtPaGState extends State<WgtPaG> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        horizontalSpaceSmall,
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: GridView.count(
            crossAxisCount: 3,
            // mainAxisSpacing: 2.0,
            // crossAxisSpacing: 2.0,
            shrinkWrap: true,
            children: List.generate(9, (index) {
              if (index == 4) {
                return _buildSquare(4,
                    colorSq: widget.colorC ??
                        widget.colorA ??
                        Theme.of(context).colorScheme.primary.withOpacity(0.7));
              } else {
                return _buildSquare(index);
              }
            }),
          ),
        ),
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.colorB ??
                      Theme.of(context).hintColor.withOpacity(0.95),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                widget.conextLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.colorB ?? Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSquare(int index, {Color? colorSq}) {
    Color color = colorSq ??
        widget.colorA ??
        Theme.of(context).colorScheme.primary.withOpacity(0.21);
    double margin = widget.size / 21.0;
    double borderRad = widget.size / 34;
    return Container(
      width: widget.size / 3.0 - margin * 2.0,
      height: widget.size / 3.0 - margin * 2.0,
      margin: EdgeInsets.all(margin.toDouble()),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRad),
        color: color,
        border: Border.all(
            color: widget.showSquareBorder ? color : Colors.transparent,
            width: 1),
      ),
    );
  }
}
