import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../xt_ui.dart';

class xtWait extends StatelessWidget {
  xtWait({Key? key, this.color, this.size, this.anim}) : super(key: key);

  Color? color;
  double? size;
  String? anim;

  @override
  Widget build(BuildContext context) {
    Widget wait;
    switch (anim) {
      case 'beat':
        wait = LoadingAnimationWidget.beat(
          color: color ?? xtLightGreen1,
          size: size ?? 21,
        );
        break;
      case 'horizontalRotatingDots':
        wait = LoadingAnimationWidget.horizontalRotatingDots(
          color: color ?? xtLightGreen1,
          size: size ?? 21,
        );
        break;
      default:
        wait = LoadingAnimationWidget.staggeredDotsWave(
          color: color ?? xtLightGreen1,
          size: size ?? 21,
        );
        break;
    }

    return Container(
      child: wait,
    );
  }
}
