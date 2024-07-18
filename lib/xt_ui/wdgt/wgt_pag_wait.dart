import 'dart:async';

import 'package:flutter/material.dart';

class WgtPagWait extends StatefulWidget {
  const WgtPagWait({
    super.key,
    this.size = 50,
    this.colorA,
    this.colorB,
    this.colorC,
    this.showCenterSquare = false,
    this.centerOpacity = 0.67,
  });

  final double size;
  final Color? colorA;
  final Color? colorB;
  final Color? colorC;
  final bool showCenterSquare;
  final double centerOpacity;

  @override
  State<WgtPagWait> createState() => _WgtPagWaitState();
}

class _WgtPagWaitState extends State<WgtPagWait> {
  int _currentBlackIndex = 0;
  late Timer _timer;

  final List<int> _squareOrder = [0, 1, 2, 5, 8, 7, 6, 3];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _currentBlackIndex = (_currentBlackIndex + 1) % _squareOrder.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GridView.count(
        crossAxisCount: 3,
        // mainAxisSpacing: 2.0,
        // crossAxisSpacing: 2.0,
        shrinkWrap: true,
        children: List.generate(9, (index) {
          if (index == 4) {
            if (widget.showCenterSquare) {
              return _buildSquare(4,
                  colorSq: widget.colorC ??
                      widget.colorA ??
                      Theme.of(context).colorScheme.secondary,
                  opacity: widget.centerOpacity);
            } else {
              return Container();
            }
          } else {
            return _buildSquare(index);
          }
        }),
      ),
    );
  }

  Widget _buildSquare(int index, {Color? colorSq, double opacity = 0.21}) {
    Color colorA =
        colorSq ?? widget.colorA ?? Theme.of(context).colorScheme.primary;
    Color colorB = colorA.withOpacity(opacity);
    Color color = index == _squareOrder[_currentBlackIndex] ? colorA : colorB;
    double margin = widget.size / 34.0;
    double borderRad = widget.size / 34;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.size / 3.0 - margin * 2.0,
      height: widget.size / 3.0 - margin * 2.0,
      margin: EdgeInsets.all(margin.toDouble()),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRad),
        color: color,
        border: Border.all(color: color),
      ),
    );
  }
}
