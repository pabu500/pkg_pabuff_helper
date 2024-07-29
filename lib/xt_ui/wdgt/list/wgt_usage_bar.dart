import 'package:buff_helper/util/xt_util.dart';
import 'package:flutter/material.dart';

class WgtUsageBar extends StatelessWidget {
  const WgtUsageBar({
    super.key,
    required this.balance,
    required this.total,
    required this.totalWidth,
    this.usageWidth,
    this.usageColor,
    this.totalColor,
    this.usageTextStyle,
    this.totalTextStyle,
    this.usageHeight,
    this.totalHeight,
    this.usageLoadingAnim,
    this.totalLoadingAnim,
    this.spaceInBetween = 10,
  });

  final double balance;
  final double total;
  final Color? usageColor;
  final Color? totalColor;
  final TextStyle? usageTextStyle;
  final TextStyle? totalTextStyle;
  final double? usageWidth;
  final double? totalWidth;
  final double? usageHeight;
  final double? totalHeight;
  final Widget? usageLoadingAnim;
  final Widget? totalLoadingAnim;
  final double spaceInBetween;

  @override
  Widget build(BuildContext context) {
    double balPercentage = balance / total;
    double usageWidth = totalWidth! * balPercentage;
    Color usageColor = getBalPercentageColor(balPercentage);

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Card(
              color: Colors.blueAccent.withOpacity(0.3),
              child: SizedBox(
                  width: totalWidth, height: totalHeight, child: Container())),
          Card(
            color: usageColor,
            child: SizedBox(
              width: usageWidth,
              height: totalHeight,
              child: Container(),
            ),
          ),
          Center(
              child: Text(balance.toStringAsFixed(3), style: usageTextStyle)),
        ],
      ),
    );
  }
}
